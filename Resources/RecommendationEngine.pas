unit RecommendationEngine;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  Game.Types, Game.JsonIterator, System.StrUtils, CalcEngine, System.Math,
  Game.AttributeMapper;

type
  TBuildArchetype = record
    RequiredBrandSets: TDictionary<string, Integer>;
    RequiredTalents: TDictionary<TItemType, string>;
    RequiredAttributes: TDictionary<TItemType, TArray<TMinorAttributeType>>;
    RequiredCoreAttribute: TDictionary<TItemType, TCoreAttributeType>;
    RequiredSkills: TArray<string>;
    RequiredSpecialization: string;
    RequiredWeapons: TDictionary<TWeaponSlot, string>;
    RequiredWeaponTalents: TArray<string>;
    RequiredExotics: TArray<string>;
    AllowedBrandSets: TList<string>;
    AttributeWeights: TDictionary<string, Double>;
  end;

  TSetGroup = class
    SetName: string;
    SetType: TSetType;
    SetWeight: Double;
    Pieces: TDictionary<TItemType, TGearPiece>;
    HasDesiredBonus: Boolean;
    MinDesiredPieces: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TRecommendationEngine = class
  private
    FDataIterator: TDataJsonIterator;
    FGeneratedBuilds: TList<TGearLoadout>;
    FSearchIterations: Integer;
    FCanonicalRequiredBrands: TDictionary<string, Integer>;
    FCanonicalAllowedBrands: TDictionary<string, Boolean>;
    FCanonicalSetTypes: TDictionary<string, TSetType>;
    FSetBonusRequirements: TDictionary<string, Integer>;
    procedure PreFilterGear(const AArchetype: TBuildArchetype;
      out AGearPool: TDictionary<TItemType, TList<TGearPiece>>;
      const AWeights: TDictionary<string, Double> = nil);
    function MeetsBuildRequirements(const ABuild: TGearLoadout; const AArchetype: TBuildArchetype): Boolean;
    function GetRequiredTalent(const AItemType: TItemType; const AArchetype: TBuildArchetype): string;
    function IsExoticWeapon(const AWeaponName: string): Boolean;
    function IsValidGearSetCombination(const ABuild: TGearLoadout): Boolean;
    function PotentialGearSetIssues(const ABrandCounts: TDictionary<string, Integer>; RemainingSlots: Integer): Boolean;
    procedure GenerateBuildsRecursive(var ACurrentBuild: TGearLoadout;
      ACurrentSlot: TItemType; const AArchetype: TBuildArchetype;
      const AGearPool: TDictionary<TItemType, TList<TGearPiece>>;
      const ARequiredBrands: TDictionary<string, Integer>;
      const ABrandCounts: TDictionary<string, Integer>;
      const AMaxBuilds: Integer;
      AHasNinjaBike: Boolean);
    function FindBestAttributesForPiece(var AGearPiece: TGearPiece; const AArchetype: TBuildArchetype): Boolean;
    procedure BuildCanonicalBrandData(const AArchetype: TBuildArchetype);
    procedure ClearCanonicalBrandData;
    function IsRequiredSet(const SetName: string): Boolean;
    function IsAllowedSet(const SetName: string): Boolean;
    function MeetsExactBonusRequirements(const ABrandCounts: TDictionary<string, Integer>): Boolean;

    // Set-Based Combination Engine
    procedure GenerateBuildsSetBased(const AArchetype: TBuildArchetype;
      const AWeights: TDictionary<string, Double>; const AMaxBuilds: Integer);
    procedure AssignPiecesRecursive(var ACurrentBuild: TGearLoadout;
      ACurrentSlot: TItemType; const AComposition: TList<TSetGroup>;
      const AArchetype: TBuildArchetype; var ABuildsFound: Integer;
      const AMaxBuilds: Integer; AHasNinjaBike: Boolean);
  public
    constructor Create(ADataIterator: TDataJsonIterator);
    destructor Destroy; override;
    function GenerateBuilds(const AArchetype: TBuildArchetype;
      const AWeights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
  end;

implementation

function CloneBrandRequirements(const Source: TDictionary<string, Integer>)
  : TDictionary<string, Integer>;
var
  Pair: TPair<string, Integer>;
begin
  if (Source = nil) or (Source.Count = 0) then
    Exit(nil);

  Result := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  for Pair in Source do
    Result.AddOrSetValue(Pair.Key, Pair.Value);
end;

function BrandRequirementsStillPossible(
  const Counts, Required: TDictionary<string, Integer>;
  RemainingSlots: Integer; AHasNinjaBike: Boolean): Boolean;
var
  Pair: TPair<string, Integer>;
  Current: Integer;
  Effective: Integer;
begin
  if (Required = nil) or (Required.Count = 0) then
    Exit(True);

  for Pair in Required do
  begin
    if not Assigned(Counts) or not Counts.TryGetValue(Pair.Key, Current) then
      Current := 0;

    Effective := Current;
    if AHasNinjaBike and (Effective > 0) then Inc(Effective);

    if Effective + RemainingSlots < Pair.Value then
      Exit(False);
  end;
  Result := True;
end;

function StrToCoreAttributeType(const AId: string): TCoreAttributeType;
begin
  if SameText(AId, 'armor') then
    Result := catArmor
  else if SameText(AId, 'skillTier') then
    Result := catSkillTier
  else
    Result := catWeaponDamage;
end;

function GetMaxPieceCount(ASetType: TSetType): Integer;
begin
  case ASetType of
    stBrandSet: Result := 3;
    stGearSet: Result := 4;
    stExoticSet: Result := 1;
    stImprovised: Result := 6;
    stNamedSet: Result := 3; // Treat as Brand Set limit generally
  else
    Result := 6;
  end;
end;

{ TSetGroup }

constructor TSetGroup.Create;
begin
  Pieces := TDictionary<TItemType, TGearPiece>.Create;
  HasDesiredBonus := False;
  MinDesiredPieces := 0;
end;

destructor TSetGroup.Destroy;
begin
  Pieces.Free;
  inherited;
end;

{ TRecommendationEngine }

constructor TRecommendationEngine.Create(ADataIterator: TDataJsonIterator);
begin
  FDataIterator := ADataIterator;
  FGeneratedBuilds := TList<TGearLoadout>.Create;
  FCanonicalRequiredBrands := nil;
  FCanonicalAllowedBrands := nil;
  FCanonicalSetTypes := nil;
  FSetBonusRequirements := nil;
end;

destructor TRecommendationEngine.Destroy;
begin
  ClearCanonicalBrandData;
  FGeneratedBuilds.Free;
  inherited;
end;

function TRecommendationEngine.GenerateBuilds(const AArchetype: TBuildArchetype;
  const AWeights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
var
  LInitialBuild: TGearLoadout;
  LGearPool: TDictionary<TItemType, TList<TGearPiece>>;
  LBrandCounts: TDictionary<string, Integer>;
  LRequiredBrands: TDictionary<string, Integer>;
  LMaxBuilds: Integer;
begin
  FGeneratedBuilds.Clear;
  FSearchIterations := 0;
  BuildCanonicalBrandData(AArchetype);

  LMaxBuilds := 50;
  if Assigned(AWeights) and (AWeights.Count > 0) then
    LMaxBuilds := 500;

  // Use the recursive generator for reliability with weighted attributes
  LInitialBuild := Default(TGearLoadout);
  LRequiredBrands := CloneBrandRequirements(FCanonicalRequiredBrands);
  LBrandCounts := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  PreFilterGear(AArchetype, LGearPool, AWeights);
  try
    GenerateBuildsRecursive(LInitialBuild, itMask, AArchetype, LGearPool,
      LRequiredBrands, LBrandCounts, LMaxBuilds, False);
  finally
    for var LItemType in LGearPool.Keys do
      LGearPool[LItemType].Free;
    LGearPool.Free;
    LBrandCounts.Free;
    LRequiredBrands.Free;
  end;

  Result := TList<TGearLoadout>.Create;
  for var Build in FGeneratedBuilds do
    Result.Add(Build);

  ClearCanonicalBrandData;
end;

procedure TRecommendationEngine.PreFilterGear(const AArchetype: TBuildArchetype;
  out AGearPool: TDictionary<TItemType, TList<TGearPiece>>;
  const AWeights: TDictionary<string, Double> = nil);
var
  LGearPiece: TGearPiece;
  LBrandSet: TPieceSet;
  LRequiredTalent: string;
  LItemType: TItemType;
  LCoreDef: TCoreAttributeDefinition;
  LFixedDef: TFixedMinorAttributeDefinition;
  LIdx: Integer;
  SetWeightCache: TDictionary<string, Double>;
  HasWeightedSets: Boolean;
  LNewList : TList<TGearPiece>;
  LCanonicalSetName: string;
  LHighestRelevantBonus: Integer;

  function AttrMatchesWeight(const AttrId, WeightKey: string): Boolean;
  var
    AttrEnum, WeightEnum: TAttributeID;
    NormAttr, NormKey: string;
  begin
    Result := False;
    if (AttrId = '') or (WeightKey = '') then
      Exit;

    if TAttributeMapper.TryParse(AttrId, AttrEnum) and
       TAttributeMapper.TryParse(WeightKey, WeightEnum) then
      Exit(AttrEnum = WeightEnum);

    NormAttr := NormalizeAttrId(AttrId);
    NormKey := NormalizeAttrId(WeightKey);
    if (NormAttr = '') or (NormKey = '') then
      Exit(False);

    Result := (NormAttr.Contains(NormKey)) or (NormKey.Contains(NormAttr));
  end;

  function SetHasTargetBonus(const SetDef: TPieceSet): Boolean;
  var
    Bonus: TSetBonus;
    Key: string;
    Part: TPart;
    FixedAttrID: string;
  begin
    Result := False;

    if (AWeights = nil) or (AWeights.Count = 0) then
      Exit(True);

    for Bonus in SetDef.Bonuses do
    begin
      if Bonus.AttributeID = '' then
        Continue;
      for Key in AWeights.Keys do
        if AttrMatchesWeight(Bonus.AttributeID, Key) then
          Exit(True);
    end;

    for Part in SetDef.Parts do
      for FixedAttrID in Part.FixedMinorAttributeIDs do
        for Key in AWeights.Keys do
          if AttrMatchesWeight(FixedAttrID, Key) then
            Exit(True);
  end;

  function GetHighestRelevantBonusRequirement(const SetDef: TPieceSet): Integer;
  var
    Bonus: TSetBonus;
    Key: string;
  begin
    Result := 0;
    if (AWeights = nil) or (AWeights.Count = 0) then
      Exit;

    for Bonus in SetDef.Bonuses do
    begin
      if Bonus.AttributeID = '' then
        Continue;
      for Key in AWeights.Keys do
        if AttrMatchesWeight(Bonus.AttributeID, Key) then
        begin
          var Required := Bonus.ItemsRequired;
          if Required <= 0 then
            Required := 1;
          if Required > Result then
            Result := Required;
          Break;
        end;
    end;
  end;

  function CanPieceRollAttribute(const APiece: TGearPiece; const AAttrID: string): Boolean;
  var
    NormAttr: string;
    Category: TMinorAttributeCat;
    Fixed: TFixedMinorAttributeDefinition;
    CoreType: TCoreAttributeType;
  begin
    Result := False;
    NormAttr := NormalizeAttrId(AAttrID);
    if NormAttr = '' then
      Exit;

    for Fixed in APiece.FixedMinorAttributes do
    begin
      var NormFixed := NormalizeAttrId(Fixed.ID);
      if (NormFixed = NormAttr) or NormFixed.Contains(NormAttr) or NormAttr.Contains(NormFixed) then
        Exit(True);
    end;

    if APiece.SetType = stExoticSet then
      Exit(False);

    if ContainsText(NormAttr, 'crit') or
       ContainsText(NormAttr, 'headshot') or
       ContainsText(NormAttr, 'weaponhandling') or
       ContainsText(NormAttr, 'handling') then
      Category := matOffensive
    else if ContainsText(NormAttr, 'skill') or
            ContainsText(NormAttr, 'status') or
            ContainsText(NormAttr, 'repair') or
            ContainsText(NormAttr, 'haste') or
            ContainsText(NormAttr, 'duration') then
      Category := matUtility
    else
      Category := matDefensive;

    if Assigned(AArchetype.RequiredCoreAttribute) and
       AArchetype.RequiredCoreAttribute.TryGetValue(APiece.ItemType, CoreType) then
    begin
      // use required core if specified
    end
    else
      CoreType := APiece.CoreAttribute.AttrType;

    case CoreType of
      catWeaponDamage: Result := (Category = matOffensive);
      catArmor:        Result := (Category = matDefensive);
      catSkillTier:    Result := (Category = matUtility);
    end;
  end;

  function CoreTypeToId(const CoreType: TCoreAttributeType): string;
  begin
    case CoreType of
      catWeaponDamage: Result := 'weaponDamage';
      catArmor:        Result := 'armor';
      catSkillTier:    Result := 'skillTier';
    else
      Result := '';
    end;
  end;

  function GetSetWeight(const SetName: string; const Bonuses: TArray<TSetBonus>;
    const APiece: TGearPiece): Double;
  var
    SB: TSetBonus;
    Key: string;
    Denom: Integer;
    BonusWeight: Double;
  begin
    Result := 0;
    if (AWeights = nil) or (AWeights.Count = 0) then
      Exit;

    if SetWeightCache.TryGetValue(SetName, Result) then
      Exit;

    for SB in Bonuses do
    begin
      if SB.AttributeID = '' then
        Continue;
      for Key in AWeights.Keys do
      begin
        if AttrMatchesWeight(SB.AttributeID, Key) then
        begin
          Denom := SB.ItemsRequired;
          if Denom <= 0 then
            Denom := 1;
          BonusWeight := (SB.Value / Denom) * AWeights[Key];
          if Denom >= 3 then
            BonusWeight := BonusWeight * 0.3
          else if Denom >= 2 then
            BonusWeight := BonusWeight * 0.6;
          Result := Result + BonusWeight;
          Break;
        end;
      end;
    end;
    // Add bonus weight if piece can roll the requested attribute
    var RollableBonus: Double := 0;
    for Key in AWeights.Keys do
      if CanPieceRollAttribute(APiece, Key) then
        RollableBonus := RollableBonus + (AWeights[Key] * 0.25);
    Result := Result + RollableBonus;
    if Result > 0 then
      HasWeightedSets := True;
    SetWeightCache.AddOrSetValue(SetName, Result);
  end;

  function HasPiece(const APiece: TGearPiece): Boolean;
  begin
    if not Assigned(LNewList) then
      Exit(False);
    for var Existing in LNewList do
      if (SameText(Existing.Name, APiece.Name)) and (Existing.ItemType = APiece.ItemType) then
        Exit(True);
    Result := False;
  end;
begin
  AGearPool := TDictionary<TItemType, TList<TGearPiece>>.Create;
  for LItemType := Low(TItemType) to itKneepads do
    AGearPool.Add(LItemType, TList<TGearPiece>.Create);

  SetWeightCache := TDictionary<string, Double>.Create(TIStringComparer.Ordinal);
  HasWeightedSets := False;

  if Assigned(FSetBonusRequirements) then
    FreeAndNil(FSetBonusRequirements);
  FSetBonusRequirements := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  try
    for LBrandSet in FDataIterator.AllPieceSetDefinitions.Values do
    begin
      // CRITICAL FIX: If user selected specific attributes, ONLY keep sets that offer those bonuses
      // This prevents generating builds with useless pieces
      if not SetHasTargetBonus(LBrandSet) then
        Continue;

      LCanonicalSetName := CalcEngine.CanonicalSetName(LBrandSet.Name);
      LHighestRelevantBonus := GetHighestRelevantBonusRequirement(LBrandSet);
      if (LHighestRelevantBonus > 0) and (LCanonicalSetName <> '') then
        FSetBonusRequirements.AddOrSetValue(LCanonicalSetName, LHighestRelevantBonus);

      for var LPart in LBrandSet.Parts do
      begin
        FillChar(LGearPiece, SizeOf(LGearPiece), 0);
        LGearPiece.SetName := CalcEngine.CanonicalSetName(LBrandSet.Name);
        LGearPiece.Name := LPart.Name;
        LGearPiece.ItemType := LPart.GearSlot;
        LGearPiece.SetType := LBrandSet.SetType;
        LGearPiece.Talent := LPart.Talent;
        LGearPiece.Bonuses := Copy(LBrandSet.Bonuses, 0, Length(LBrandSet.Bonuses));
        LGearPiece.MinorAttributeSlotCount := LPart.MinorAttributeSlotCount;

        if (LPart.CoreAttributeID <> '') and
          Assigned(FDataIterator.CoreAttributeDefinitions) and
          FDataIterator.CoreAttributeDefinitions.TryGetValue(LPart.CoreAttributeID,
          LCoreDef) then
        begin
          LGearPiece.CoreAttribute.ID := LCoreDef.ID;
          LGearPiece.CoreAttribute.TypeName := LCoreDef.TypeName;
          LGearPiece.CoreAttribute.Value := LCoreDef.Value;
          LGearPiece.CoreAttribute.AttrType := StrToCoreAttributeType(LCoreDef.ID);
        end;

        // Filter by Allowed Brands if specified (canonicalized)
        if not IsAllowedSet(LGearPiece.SetName) then
          Continue;

        // Flexible Filter + Automatic Recalibration Tracking
        // Exotics: Core locked -> must match required core.
        // Brand/Gear sets: Core recalibratable -> track recalibration and use target core.
        if Assigned(AArchetype.RequiredCoreAttribute) and
           AArchetype.RequiredCoreAttribute.ContainsKey(LPart.GearSlot) then
        begin
          var RequiredCore := AArchetype.RequiredCoreAttribute[LPart.GearSlot];
          var OriginalCore := LGearPiece.CoreAttribute.AttrType;

          if LGearPiece.SetType = stExoticSet then
          begin
            if OriginalCore <> RequiredCore then
              Continue;
            LGearPiece.RequiresRecalibration := False;
            LGearPiece.OriginalCoreType := OriginalCore;
            LGearPiece.RecalibratedCoreType := OriginalCore;
          end
          else
          begin
            LGearPiece.OriginalCoreType := OriginalCore;
            LGearPiece.RecalibratedCoreType := RequiredCore;
            LGearPiece.RequiresRecalibration := (OriginalCore <> RequiredCore);

            var RequiredId := CoreTypeToId(RequiredCore);
            if (RequiredId <> '') and Assigned(FDataIterator.CoreAttributeDefinitions) and
               FDataIterator.CoreAttributeDefinitions.TryGetValue(RequiredId, LCoreDef) then
            begin
              LGearPiece.CoreAttribute.ID := LCoreDef.ID;
              LGearPiece.CoreAttribute.TypeName := LCoreDef.TypeName;
              LGearPiece.CoreAttribute.Value := LCoreDef.Value;
              LGearPiece.CoreAttribute.AttrType := RequiredCore;
            end
            else
              LGearPiece.CoreAttribute.AttrType := RequiredCore;
          end;
        end
        else
        begin
          LGearPiece.RequiresRecalibration := False;
          LGearPiece.OriginalCoreType := LGearPiece.CoreAttribute.AttrType;
          LGearPiece.RecalibratedCoreType := LGearPiece.CoreAttribute.AttrType;
        end;

        if Length(LPart.FixedMinorAttributeIDs) > 0 then
        begin
          SetLength(LGearPiece.FixedMinorAttributes,
            Length(LPart.FixedMinorAttributeIDs));
          for LIdx := 0 to High(LPart.FixedMinorAttributeIDs) do
          if Assigned(FDataIterator.FixedMinorAttributeDefinitions) and
              FDataIterator.FixedMinorAttributeDefinitions.TryGetValue
              (LPart.FixedMinorAttributeIDs[LIdx], LFixedDef) then
              LGearPiece.FixedMinorAttributes[LIdx] := LFixedDef;
        end;

        // Compute set weight with piece info (considers set bonuses + rollable attributes)
        GetSetWeight(LGearPiece.SetName, LBrandSet.Bonuses, LGearPiece);

        if LBrandSet.SetType = stNamedSet then
        begin
          if (Length(LBrandSet.Bonuses) > 0) and
            (LBrandSet.Bonuses[0].BonusType = sbtTalent) then
          begin
            LGearPiece.Talent := LBrandSet.Bonuses[0].Description;
          end;
        end;

        LRequiredTalent := GetRequiredTalent(LPart.GearSlot, AArchetype);
        if (LRequiredTalent = '') or (LGearPiece.Talent = LRequiredTalent) then
        begin
          if FindBestAttributesForPiece(LGearPiece, AArchetype) then
          begin
            AGearPool[LPart.GearSlot].Add(LGearPiece);
          end;
        end;
      end;
    end;

    // Sort each slot list to prioritize sets whose bonuses match weighted attributes
    if Assigned(AWeights) and (AWeights.Count > 0) then
      for LItemType := Low(TItemType) to itKneepads do
      begin
        if HasWeightedSets then
        begin
          AGearPool[LItemType].Sort(
            TComparer<TGearPiece>.Construct(
              function(const L, R: TGearPiece): Integer
              var
                WL, WR: Double;
              begin
                if not SetWeightCache.TryGetValue(L.SetName, WL) then
                  WL := 0;
                if not SetWeightCache.TryGetValue(R.SetName, WR) then
                  WR := 0;
                if WL > WR then
                  Result := -1
                else if WL < WR then
                  Result := 1
                else
                  Result := 0;
              end));
        end
        else
        begin
          // No set bonus matches the weights (e.g., rollable minors).
          // Prefer brand sets over gear sets so we don't prune out valid mixes.
          AGearPool[LItemType].Sort(
            TComparer<TGearPiece>.Construct(
              function(const L, R: TGearPiece): Integer
              var
                LKey, RKey: Integer;
              begin
                case L.SetType of
                  stBrandSet, stNamedSet: LKey := 0;
                  stGearSet: LKey := 1;
                  stExoticSet: LKey := 2;
                else
                  LKey := 3;
                end;

                case R.SetType of
                  stBrandSet, stNamedSet: RKey := 0;
                  stGearSet: RKey := 1;
                  stExoticSet: RKey := 2;
                else
                  RKey := 3;
                end;

                if LKey < RKey then
                  Result := -1
                else if LKey > RKey then
                  Result := 1
                else
                  Result := 0;
              end));
        end;

        // Heuristic Beam Search / Optimization:
        // Limit the pool to the top K candidates per slot to prevent combinatorial explosion.
        // We keep more candidates for slots that typically define a build (Chest/Backpack).
        var LLimit := 15;
        if (LItemType = itChest) or (LItemType = itBackpack) then
          LLimit := 25;
        if Assigned(AWeights) and (AWeights.Count <= 3) then
          Inc(LLimit, 20); // allow more variety for attribute lookup

        if AGearPool[LItemType].Count > LLimit then
        begin
          try
            LNewList := TList<TGearPiece>.Create;
            // 1) Keep all pieces from sets that actually match the weights
            for var i := 0 to AGearPool[LItemType].Count - 1 do
            begin
              var LGear := AGearPool[LItemType][i];
              var W: Double := 0;
              if SetWeightCache.TryGetValue(LGear.SetName, W) and (W > 0) and not HasPiece(LGear) then
                LNewList.Add(LGear);
            end;

            // 2) Fill up to limit (or include Exotics)
            for var i := 0 to AGearPool[LItemType].Count - 1 do
            begin
              var LGear := AGearPool[LItemType][i];
              if ((LNewList.Count < LLimit) or (LGear.SetType = stExoticSet)) and not HasPiece(LGear) then
                LNewList.Add(LGear);

              if LNewList.Count >= 80 then Break; // Absolute cap
            end;

            AGearPool[LItemType].Clear;
            AGearPool[LItemType].AddRange(LNewList);
          finally
            LNewList.Free;
            LNewList := nil;
          end;
        end;
      end;
  finally
    SetWeightCache.Free;
  end;
end;

function TRecommendationEngine.MeetsBuildRequirements(const ABuild: TGearLoadout; const AArchetype: TBuildArchetype): Boolean;
var
  LBrandSetCounts: TDictionary<string, Integer>;
  LGearPiece: TGearPiece;
  LCount: Integer;
  LBrandName: string;
  LExoticCount: Integer;
  LHasNinjaBike: Boolean;
begin
  LBrandSetCounts := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  try
    LHasNinjaBike := False;
    for LGearPiece in ABuild.GearPieces do
    begin
      if SameText(LGearPiece.Name, 'NinjaBike Messenger Backpack') then
        LHasNinjaBike := True;

      if LGearPiece.SetName <> '' then
      begin
        LBrandName := CalcEngine.CanonicalSetName(LGearPiece.SetName);
        if LBrandName <> '' then
        begin
          LBrandSetCounts.TryGetValue(LBrandName, LCount);
          LBrandSetCounts.AddOrSetValue(LBrandName, LCount + 1);
        end;
      end;
    end;

    // Required brands (canonicalized)
    if Assigned(FCanonicalRequiredBrands) then
      for LBrandName in FCanonicalRequiredBrands.Keys do
      begin
        if not LBrandSetCounts.TryGetValue(LBrandName, LCount) then
          LCount := 0;

        // Account for NinjaBike bonus
        if LHasNinjaBike and (LCount > 0) then
          Inc(LCount);

        if (LCount < FCanonicalRequiredBrands[LBrandName]) then
        begin
          Result := False;
          Exit;
        end;
      end;

    // Required talents per slot
    if Assigned(AArchetype.RequiredTalents) then
      for var LItemType in AArchetype.RequiredTalents.Keys do
      begin
        if (LItemType > itKneepads) then
          Continue;
        if ABuild.GearPieces[LItemType].Talent <>
           AArchetype.RequiredTalents[LItemType] then
        begin
          Result := False;
          Exit;
        end;
      end;

    LExoticCount := 0;
    for LGearPiece in ABuild.GearPieces do
    begin
      if LGearPiece.SetType = stExoticSet then
      begin
        Inc(LExoticCount);
      end;
    end;
    for var LWeapon in ABuild.Weapons do
    begin
      if IsExoticWeapon(LWeapon.Name) then
      begin
        Inc(LExoticCount);
      end;
    end;
    if LExoticCount > 1 then
    begin
      Result := False;
      Exit;
    end;

    // Required core attributes per slot
    if Assigned(AArchetype.RequiredCoreAttribute) then
      for var LItemType in AArchetype.RequiredCoreAttribute.Keys do
      begin
        if (LItemType > itKneepads) then
          Continue;
        if ABuild.GearPieces[LItemType].SetType = stExoticSet then
        begin
          if ABuild.GearPieces[LItemType].CoreAttribute.AttrType <>
             AArchetype.RequiredCoreAttribute[LItemType] then
          begin
            Result := False;
            Exit;
          end;
        end;
      end;

  finally
    LBrandSetCounts.Free;
  end;

  Result := True;
end;

function TRecommendationEngine.GetRequiredTalent(const AItemType: TItemType; const AArchetype: TBuildArchetype): string;
begin
  if AArchetype.RequiredTalents.ContainsKey(AItemType) then
    Result := AArchetype.RequiredTalents[AItemType]
  else
    Result := '';
end;

function TRecommendationEngine.IsExoticWeapon(const AWeaponName: string): Boolean;
begin
  for var LWeapon in FDataIterator.Weapons.Values do
  begin
    if (LWeapon.Name = AWeaponName) and (LWeapon.Rarity = wrExotic) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TRecommendationEngine.IsValidGearSetCombination(const ABuild: TGearLoadout): Boolean;
var
  LGearSetCounts: TDictionary<string, Integer>;
  LHasNinjaBike: Boolean;
  LGearPiece: TGearPiece;
  LCount: Integer;
begin
  Result := True;
  LGearSetCounts := TDictionary<string, Integer>.Create;
  try
    LHasNinjaBike := False;
    for LGearPiece in ABuild.GearPieces do
    begin
      if SameText(LGearPiece.Name, 'NinjaBike Messenger Backpack') then
        LHasNinjaBike := True;

      if LGearPiece.SetType = stGearSet then
      begin
        LGearSetCounts.TryGetValue(LGearPiece.SetName, LCount);
        LGearSetCounts.AddOrSetValue(LGearPiece.SetName, LCount + 1);
      end;
    end;

    if LHasNinjaBike then
      Exit;

    for LCount in LGearSetCounts.Values do
    begin
      if LCount = 1 then
      begin
        Result := False;
        Exit;
      end;
    end;
  finally
    LGearSetCounts.Free;
  end;
end;

function TRecommendationEngine.PotentialGearSetIssues(const ABrandCounts: TDictionary<string, Integer>; RemainingSlots: Integer): Boolean;
var
  LSetName: string;
  LCount: Integer;
  LSetType: TSetType;
  LNeededSlots: Integer;
begin
  // Checks if we have "orphaned" Gear Set pieces (count=1) that cannot be satisfied
  // by the remaining slots (assuming min 2 pieces for Gear Sets).
  Result := False;
  LNeededSlots := 0;

  for LSetName in ABrandCounts.Keys do
  begin
    LCount := ABrandCounts[LSetName];
    // If we have exactly 1 piece, we need at least 1 more to make it valid
    // (unless we have NinjaBike, but let's assume strict logic for now or update if needed).
    // Note: We need to know if LSetName corresponds to a Gear Set (stGearSet).
    if (LCount = 1) then
    begin
      if Assigned(FCanonicalSetTypes) and
         FCanonicalSetTypes.TryGetValue(LSetName, LSetType) and
         (LSetType = stGearSet) then
      begin
        Inc(LNeededSlots);
      end;
    end;
  end;

  if LNeededSlots > RemainingSlots then
    Result := True;
end;

function TRecommendationEngine.FindBestAttributesForPiece(var AGearPiece: TGearPiece; const AArchetype: TBuildArchetype): Boolean;
var
  LRequiredAttributes: TArray<TMinorAttributeType>;
  LMinorAttribute: TMinorAttribute;
  LIndex: Integer;
  LMaxSlots: Integer;
  LNeeded: TList<TMinorAttributeType>;
  LFixed: TFixedMinorAttributeDefinition;
  LFOUND: Boolean;
begin
  Result := True;
  if (AArchetype.RequiredAttributes = nil) or
    (not AArchetype.RequiredAttributes.TryGetValue(AGearPiece.ItemType, LRequiredAttributes)) then
    Exit;

  LNeeded := TList<TMinorAttributeType>.Create;
  try
    // Add all required
    for var Req in LRequiredAttributes do
      LNeeded.Add(Req);

    // Remove required attrs that are already satisfied by fixed minors
    if Length(AGearPiece.FixedMinorAttributes) > 0 then
    begin
      for LFixed in AGearPiece.FixedMinorAttributes do
      begin
        for LIndex := LNeeded.Count - 1 downto 0 do
        begin
          if NormalizeAttrId(LFixed.ID) =
             NormalizeAttrId(MinorAttrEnumToId(LNeeded[LIndex])) then
          begin
            LNeeded.Delete(LIndex);
            Break; // one fixed attr covers one required attr
          end;
        end;
      end;
    end;

    LMaxSlots := AGearPiece.MinorAttributeSlotCount;

    // Check if remaining needed attributes fit in slots
    if LNeeded.Count > LMaxSlots then
      Exit(False);

    // Assign remaining needed attributes to slots
    // If fewer needed than slots, we only assign the needed ones.
    // The recursive generation or UI defaults will handle the rest or leave them open.
    // However, the function returns TGearPiece which is used for generation.
    // If we only fill 1 of 2 slots, the second remains default (or empty).
    SetLength(AGearPiece.MinorAttributes, LNeeded.Count);
    for LIndex := 0 to LNeeded.Count - 1 do
    begin
      LMinorAttribute.MinorAttribute := LNeeded[LIndex];
      LMinorAttribute.AttrType := MinorAttributeCategory(LMinorAttribute.MinorAttribute);
      LMinorAttribute.Value := GetDefaultMinorAttributeValue(LMinorAttribute.MinorAttribute);
      AGearPiece.MinorAttributes[LIndex] := LMinorAttribute;
    end;
  finally
    LNeeded.Free;
  end;
end;

procedure TRecommendationEngine.GenerateBuildsSetBased(const AArchetype: TBuildArchetype;
  const AWeights: TDictionary<string, Double>; const AMaxBuilds: Integer);
var
  LSets: TObjectDictionary<string, TSetGroup>;
  LRelevantSets: TList<TSetGroup>;
  LDesiredSets: TList<TSetGroup>;
  LOtherSets: TList<TSetGroup>;
  LBrandSet: TPieceSet;
  LGearPiece: TGearPiece;
  LSetName: string;
  LGroup: TSetGroup;
  LCoreDef: TCoreAttributeDefinition;
  LFixedDef: TFixedMinorAttributeDefinition;
  LIdx: Integer;
  LMinRelevant: Integer;

  function AttrMatchesWeight(const AttrId, WeightKey: string): Boolean;
  var
    AttrEnum, WeightEnum: TAttributeID;
    NormAttr, NormKey: string;
  begin
    Result := False;
    if (AttrId = '') or (WeightKey = '') then
      Exit;
    if TAttributeMapper.TryParse(AttrId, AttrEnum) and
       TAttributeMapper.TryParse(WeightKey, WeightEnum) then
      Exit(AttrEnum = WeightEnum);

    NormAttr := NormalizeAttrId(AttrId);
    NormKey := NormalizeAttrId(WeightKey);
    if (NormAttr = '') or (NormKey = '') then
      Exit(False);
    Result := (NormAttr.Contains(NormKey)) or (NormKey.Contains(NormAttr));
  end;

  function GetSetWeight(const SetName: string; const Bonuses: TArray<TSetBonus>): Double;
  var
    SB: TSetBonus;
    Key: string;
    Denom: Integer;
  begin
    Result := 0;
    if (AWeights = nil) or (AWeights.Count = 0) then Exit;
    for SB in Bonuses do
    begin
      if SB.AttributeID = '' then Continue;
      for Key in AWeights.Keys do
      begin
        if AttrMatchesWeight(SB.AttributeID, Key) then
        begin
          Denom := SB.ItemsRequired;
          if Denom <= 0 then Denom := 1;
          Result := Result + (SB.Value / Denom) * AWeights[Key];
        end;
      end;
    end;
  end;

  procedure FindCompositionsRecursive(AStartIndex: Integer; ARemainingSlots: Integer;
    ACurrentComposition: TList<TSetGroup>; AExoticCount: Integer; AHasNinja: Boolean);
  var
    i, LCount, LNeededSlots: Integer;
    LSet: TSetGroup;
    LNewNinja: Boolean;
  begin
    if ARemainingSlots = 0 then
    begin
      // Valid composition found, now assign to slots
      var LBuild := Default(TGearLoadout);
      var LFoundInAssign := 0;
      AssignPiecesRecursive(LBuild, itMask, ACurrentComposition, AArchetype, LFoundInAssign, AMaxBuilds, AHasNinja);
      Exit;
    end;

    if FSearchIterations > 100000 then Exit;
    Inc(FSearchIterations);

    for i := AStartIndex to LRelevantSets.Count - 1 do
    begin
      LSet := LRelevantSets[i];
      LNewNinja := AHasNinja or SameText(LSet.SetName, 'NinjaBike Messenger Backpack');

      // piece count check
      // Try 1, 2, 3 (or 4 for GearSets) pieces of this set
      var LMax := GetMaxPieceCount(LSet.SetType);

      for LCount := 1 to Min(ARemainingSlots, LMax) do
      begin
        if (LSet.SetType = stExoticSet) and (AExoticCount > 0) then Break;

        for var j := 1 to LCount do ACurrentComposition.Add(LSet);
        FindCompositionsRecursive(i + 1, ARemainingSlots - LCount, ACurrentComposition,
          AExoticCount + IfThen(LSet.SetType = stExoticSet, 1, 0), LNewNinja);
        for var j := 1 to LCount do ACurrentComposition.Delete(ACurrentComposition.Count - 1);
      end;
    end;
  end;

begin
  LSets := TObjectDictionary<string, TSetGroup>.Create([doOwnsValues]);
  LRelevantSets := TList<TSetGroup>.Create;
  LDesiredSets := TList<TSetGroup>.Create;
  LOtherSets := TList<TSetGroup>.Create;
  LMinRelevant := 12;
  try
    // 1. Group pieces and calculate weights
    for LBrandSet in FDataIterator.AllPieceSetDefinitions.Values do
    begin
      LSetName := CalcEngine.CanonicalSetName(LBrandSet.Name);
      if not LSets.TryGetValue(LSetName, LGroup) then
      begin
        LGroup := TSetGroup.Create;
        LGroup.SetName := LSetName;
        LGroup.SetType := LBrandSet.SetType;
        LGroup.SetWeight := GetSetWeight(LSetName, LBrandSet.Bonuses);
        if (AWeights <> nil) and (AWeights.Count > 0) then
        begin
          for var SB in LBrandSet.Bonuses do
            for var Key in AWeights.Keys do
              if AttrMatchesWeight(SB.AttributeID, Key) then
              begin
                LGroup.HasDesiredBonus := True;
                var Required := SB.ItemsRequired;
                if Required <= 0 then
                  Required := 1;
                if (LGroup.MinDesiredPieces = 0) or (Required < LGroup.MinDesiredPieces) then
                  LGroup.MinDesiredPieces := Required;
                Break;
              end;
        end;
        LSets.Add(LSetName, LGroup);
      end;

      for var LPart in LBrandSet.Parts do
      begin
        FillChar(LGearPiece, SizeOf(LGearPiece), 0);
        LGearPiece.SetName := LSetName;
        LGearPiece.Name := LPart.Name;
        LGearPiece.ItemType := LPart.GearSlot;
        LGearPiece.SetType := LBrandSet.SetType;
        LGearPiece.Talent := LPart.Talent;
        LGearPiece.Bonuses := Copy(LBrandSet.Bonuses, 0, Length(LBrandSet.Bonuses));
        LGearPiece.MinorAttributeSlotCount := LPart.MinorAttributeSlotCount;

        if (LPart.CoreAttributeID <> '') and Assigned(FDataIterator.CoreAttributeDefinitions) and
          FDataIterator.CoreAttributeDefinitions.TryGetValue(LPart.CoreAttributeID, LCoreDef) then
        begin
          LGearPiece.CoreAttribute.ID := LCoreDef.ID;
          LGearPiece.CoreAttribute.TypeName := LCoreDef.TypeName;
          LGearPiece.CoreAttribute.Value := LCoreDef.Value;
          LGearPiece.CoreAttribute.AttrType := StrToCoreAttributeType(LCoreDef.ID);
        end;

        if Length(LPart.FixedMinorAttributeIDs) > 0 then
        begin
          SetLength(LGearPiece.FixedMinorAttributes, Length(LPart.FixedMinorAttributeIDs));
          for LIdx := 0 to High(LPart.FixedMinorAttributeIDs) do
            if Assigned(FDataIterator.FixedMinorAttributeDefinitions) and
               FDataIterator.FixedMinorAttributeDefinitions.TryGetValue(LPart.FixedMinorAttributeIDs[LIdx], LFixedDef) then
              LGearPiece.FixedMinorAttributes[LIdx] := LFixedDef;
          if (AWeights <> nil) and (AWeights.Count > 0) then
            for LIdx := 0 to High(LGearPiece.FixedMinorAttributes) do
              for var Key in AWeights.Keys do
                if AttrMatchesWeight(LGearPiece.FixedMinorAttributes[LIdx].ID, Key) then
                begin
                  LGroup.HasDesiredBonus := True;
                  if (LGroup.MinDesiredPieces = 0) or (1 < LGroup.MinDesiredPieces) then
                    LGroup.MinDesiredPieces := 1;
                  Break;
                end;
        end;

        if (LBrandSet.SetType = stNamedSet) and (Length(LBrandSet.Bonuses) > 0) and (LBrandSet.Bonuses[0].BonusType = sbtTalent) then
           LGearPiece.Talent := LBrandSet.Bonuses[0].Description;

        if FindBestAttributesForPiece(LGearPiece, AArchetype) then
        begin
          // Prioritize Named/Exotic pieces for the same slot
          var Existing: TGearPiece;
          var ShouldReplace := not LGroup.Pieces.TryGetValue(LGearPiece.ItemType, Existing);
          if not ShouldReplace then
            // Replace standard brand with named/exotic if found
            ShouldReplace := (LGearPiece.SetType in [stNamedSet, stExoticSet]) and
                           (Existing.SetType = stBrandSet);

          if ShouldReplace then
             LGroup.Pieces.AddOrSetValue(LGearPiece.ItemType, LGearPiece);
        end;
      end;
    end;

    // 2. Filter relevant sets
    for LGroup in LSets.Values do
    begin
      if not IsAllowedSet(LGroup.SetName) then
        Continue;

      if IsRequiredSet(LGroup.SetName) or
         LGroup.HasDesiredBonus or (LGroup.SetWeight > 0) or (LGroup.SetType = stExoticSet) or
         SameText(LGroup.SetName, 'NinjaBike Messenger Backpack') then
        LDesiredSets.Add(LGroup)
      else
        LOtherSets.Add(LGroup);
    end;

    // Sort by weight
    LDesiredSets.Sort(TComparer<TSetGroup>.Construct(
      function(const L, R: TSetGroup): Integer
      begin
        Result := CompareValue(R.SetWeight, L.SetWeight);
      end));

    LOtherSets.Sort(TComparer<TSetGroup>.Construct(
      function(const L, R: TSetGroup): Integer
      begin
        Result := CompareValue(R.SetWeight, L.SetWeight);
      end));

    // Build the relevant list: desired first, then fillers
    LRelevantSets.AddRange(LDesiredSets);
    for var LFill in LOtherSets do
    begin
      if (LRelevantSets.Count >= LMinRelevant) or (LRelevantSets.Count >= 30) then
        Break;
      LRelevantSets.Add(LFill);
    end;

    // Sort by weight after merge
    LRelevantSets.Sort(TComparer<TSetGroup>.Construct(
      function(const L, R: TSetGroup): Integer
      begin
        Result := CompareValue(R.SetWeight, L.SetWeight);
      end));

    // Limit to top 30 sets to keep combinations manageable
    if LRelevantSets.Count > 30 then LRelevantSets.Count := 30;

    // 3. Find Combinations
    var LComp := TList<TSetGroup>.Create;
    try
      FindCompositionsRecursive(0, 6, LComp, 0, False);
    finally
      LComp.Free;
    end;

  finally
    LOtherSets.Free;
    LDesiredSets.Free;
    LRelevantSets.Free;
    LSets.Free;
  end;
end;

procedure TRecommendationEngine.AssignPiecesRecursive(var ACurrentBuild: TGearLoadout;
  ACurrentSlot: TItemType; const AComposition: TList<TSetGroup>;
  const AArchetype: TBuildArchetype; var ABuildsFound: Integer;
  const AMaxBuilds: Integer; AHasNinjaBike: Boolean);
type
  TSetOccurence = record
    Grp: TSetGroup;
    Count: Integer;
  end;
var
  LOccurrences: TList<TSetOccurence>;
  LSetCounts: TDictionary<string, Integer>;
  LGrp: TSetGroup;
  LOcc: TSetOccurence;

  procedure AssignRecursiveInternal(Slot: TItemType);
  var
    idx: Integer;
    Occ: TSetOccurence;
    NextSlot: TItemType;
  begin
    if ABuildsFound >= AMaxBuilds then Exit;

    if Slot = itUnknown then
    begin
      AssignRecursiveInternal(itMask);
      Exit;
    end;

    for idx := 0 to LOccurrences.Count - 1 do
    begin
      Occ := LOccurrences[idx];
      if (Occ.Count > 0) and Occ.Grp.Pieces.ContainsKey(Slot) then
      begin
        ACurrentBuild.GearPieces[Slot] := Occ.Grp.Pieces[Slot];

        // Use local copy to avoid modifying original during recursion
        Occ.Count := Occ.Count - 1;
        LOccurrences[idx] := Occ;

        if Slot < itKneepads then
        begin
          NextSlot := Succ(Slot);
          AssignRecursiveInternal(NextSlot);
        end
        else
        begin
          // Reached the end (itKneepads)
          if MeetsBuildRequirements(ACurrentBuild, AArchetype) and IsValidGearSetCombination(ACurrentBuild) then
          begin
            FGeneratedBuilds.Add(ACurrentBuild);
            Inc(ABuildsFound);
          end;
        end;

        // Backtrack
        Occ.Count := Occ.Count + 1;
        LOccurrences[idx] := Occ;

        if ABuildsFound >= AMaxBuilds then Exit;
      end;
    end;
  end;

begin
  LOccurrences := TList<TSetOccurence>.Create;
  LSetCounts := TDictionary<string, Integer>.Create;
  try
    for LGrp in AComposition do
    begin
       if LSetCounts.ContainsKey(LGrp.SetName) then
         LSetCounts[LGrp.SetName] := LSetCounts[LGrp.SetName] + 1
       else
         LSetCounts.Add(LGrp.SetName, 1);
    end;

    for LGrp in AComposition do
    begin
       var Found := False;
       for LOcc in LOccurrences do if LOcc.Grp = LGrp then begin Found := True; Break; end;
       if not Found then
       begin
         LOcc.Grp := LGrp;
         LOcc.Count := LSetCounts[LGrp.SetName];
         LOccurrences.Add(LOcc);
       end;
    end;

    AssignRecursiveInternal(itMask);
  finally
    LSetCounts.Free;
    LOccurrences.Free;
  end;
end;

procedure TRecommendationEngine.GenerateBuildsRecursive(
  var ACurrentBuild: TGearLoadout; ACurrentSlot: TItemType;
  const AArchetype: TBuildArchetype;
  const AGearPool: TDictionary<TItemType, TList<TGearPiece>>;
  const ARequiredBrands: TDictionary<string, Integer>;
  const ABrandCounts: TDictionary<string, Integer>;
  const AMaxBuilds: Integer;
  AHasNinjaBike: Boolean);
var
  LGearPiece: TGearPiece;
  LNextSlot: TItemType;
  LCount: Integer;
  LEffectiveCount: Integer;
  LRemainingSlots: Integer;
  LBrandKey: string;
  LNewNinjaBike: Boolean;
begin
  if FGeneratedBuilds.Count >= AMaxBuilds then
    Exit;

  // Safety brake against infinite loops/massive combinations
  Inc(FSearchIterations);
  if FSearchIterations > 500000 then
    Exit;

  // Défensif : on ne traite que les slots d'équipement réels
  if (ACurrentSlot < itMask) or (ACurrentSlot > itKneepads) then
    Exit;

  if not AGearPool.ContainsKey(ACurrentSlot) then
    Exit;

  for LGearPiece in AGearPool[ACurrentSlot] do
  begin
    if FGeneratedBuilds.Count >= AMaxBuilds then
      Exit;

    LBrandKey := LGearPiece.SetName;
    if not ABrandCounts.TryGetValue(LBrandKey, LCount) then
      LCount := 0;

    // NinjaBike check
    LNewNinjaBike := AHasNinjaBike or SameText(LGearPiece.Name, 'NinjaBike Messenger Backpack');

    // Piece limit check (Brand=3, GearSet=4)
    LEffectiveCount := LCount;
    if LNewNinjaBike and (LEffectiveCount > 0) then Inc(LEffectiveCount);

    if LEffectiveCount >= GetMaxPieceCount(LGearPiece.SetType) then
      Continue;

    // Exotic check (only one gear exotic)
    if (LGearPiece.SetType = stExoticSet) then
    begin
       var LAlreadyHasExotic := False;
       for var i := itMask to Pred(ACurrentSlot) do
         if ACurrentBuild.GearPieces[i].SetType = stExoticSet then
         begin
           LAlreadyHasExotic := True;
           Break;
         end;
       if LAlreadyHasExotic then Continue;
    end;

    ACurrentBuild.GearPieces[ACurrentSlot] := LGearPiece;
    ABrandCounts.AddOrSetValue(LBrandKey, LCount + 1);

    LRemainingSlots := Ord(itKneepads) - Ord(ACurrentSlot);

    // Pruning
    if BrandRequirementsStillPossible(ABrandCounts, ARequiredBrands, LRemainingSlots, LNewNinjaBike) then
    begin
      if ACurrentSlot < itKneepads then
      begin
        LNextSlot := Succ(ACurrentSlot);
        GenerateBuildsRecursive(ACurrentBuild, LNextSlot, AArchetype,
          AGearPool, ARequiredBrands, ABrandCounts, AMaxBuilds, LNewNinjaBike);
      end
      else
      begin
        if IsValidGearSetCombination(ACurrentBuild) and
           MeetsBuildRequirements(ACurrentBuild, AArchetype) and
           MeetsExactBonusRequirements(ABrandCounts) then
        begin
          FGeneratedBuilds.Add(ACurrentBuild);
        end;
      end;
    end;

    if ABrandCounts.TryGetValue(LBrandKey, LCount) then
    begin
      if LCount <= 1 then
        ABrandCounts.Remove(LBrandKey)
      else
        ABrandCounts.AddOrSetValue(LBrandKey, LCount - 1);
    end;
  end;
end;

procedure TRecommendationEngine.BuildCanonicalBrandData(const AArchetype: TBuildArchetype);
begin
  ClearCanonicalBrandData;

  if Assigned(AArchetype.RequiredBrandSets) then
  begin
    FCanonicalRequiredBrands := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
    for var Pair in AArchetype.RequiredBrandSets do
    begin
      var Key := CalcEngine.CanonicalSetName(Pair.Key);
      if Key <> '' then
        FCanonicalRequiredBrands.AddOrSetValue(Key, Pair.Value);
    end;
  end;

  if Assigned(AArchetype.AllowedBrandSets) and (AArchetype.AllowedBrandSets.Count > 0) then
  begin
    FCanonicalAllowedBrands := TDictionary<string, Boolean>.Create(TIStringComparer.Ordinal);
    for var Name in AArchetype.AllowedBrandSets do
    begin
      var Key := CalcEngine.CanonicalSetName(Name);
      if Key <> '' then
        FCanonicalAllowedBrands.AddOrSetValue(Key, True);
    end;
  end;

  FCanonicalSetTypes := TDictionary<string, TSetType>.Create(TIStringComparer.Ordinal);
  for var LBrandSet in FDataIterator.AllPieceSetDefinitions.Values do
  begin
    var Key := CalcEngine.CanonicalSetName(LBrandSet.Name);
    if Key <> '' then
      FCanonicalSetTypes.AddOrSetValue(Key, LBrandSet.SetType);
  end;
end;

procedure TRecommendationEngine.ClearCanonicalBrandData;
begin
  if Assigned(FCanonicalRequiredBrands) then
    FreeAndNil(FCanonicalRequiredBrands);
  if Assigned(FCanonicalAllowedBrands) then
    FreeAndNil(FCanonicalAllowedBrands);
  if Assigned(FCanonicalSetTypes) then
    FreeAndNil(FCanonicalSetTypes);
  if Assigned(FSetBonusRequirements) then
    FreeAndNil(FSetBonusRequirements);
end;

function TRecommendationEngine.IsRequiredSet(const SetName: string): Boolean;
var
  Key: string;
begin
  Result := False;
  if not Assigned(FCanonicalRequiredBrands) then
    Exit;
  Key := CalcEngine.CanonicalSetName(SetName);
  if Key = '' then
    Exit;
  Result := FCanonicalRequiredBrands.ContainsKey(Key);
end;

function TRecommendationEngine.IsAllowedSet(const SetName: string): Boolean;
var
  Key: string;
begin
  if (not Assigned(FCanonicalAllowedBrands)) or (FCanonicalAllowedBrands.Count = 0) then
    Exit(True);
  if IsRequiredSet(SetName) then
    Exit(True);
  Key := CalcEngine.CanonicalSetName(SetName);
  if Key = '' then
    Exit(False);
  Result := FCanonicalAllowedBrands.ContainsKey(Key);
end;

function TRecommendationEngine.MeetsExactBonusRequirements(
  const ABrandCounts: TDictionary<string, Integer>): Boolean;
var
  SetName: string;
  ActualCount: Integer;
  RequiredCount: Integer;
begin
  Result := True;
  if not Assigned(FSetBonusRequirements) or (FSetBonusRequirements.Count = 0) then
    Exit;

  for SetName in ABrandCounts.Keys do
  begin
    ActualCount := ABrandCounts[SetName];
    if FSetBonusRequirements.TryGetValue(SetName, RequiredCount) then
    begin
      if ActualCount <> RequiredCount then
        Exit(False);
    end;
  end;
end;

end.

