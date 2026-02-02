unit RecommendationEngine;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  Game.Types, Game.JsonIterator, System.StrUtils, CalcEngine, System.Math;

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
    constructor Create;
    destructor Destroy; override;
  end;

  TRecommendationEngine = class
  private
    FDataIterator: TDataJsonIterator;
    FGeneratedBuilds: TList<TGearLoadout>;
    FSearchIterations: Integer;
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
end;

destructor TRecommendationEngine.Destroy;
begin
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

  LMaxBuilds := 50;
  if Assigned(AWeights) and (AWeights.Count > 0) then
  begin
    LMaxBuilds := 200;
    // Use the new Set-Based engine for weighted optimization
    GenerateBuildsSetBased(AArchetype, AWeights, LMaxBuilds);
  end;

  // If set-based didn't find enough or we want a fallback/general search
  if FGeneratedBuilds.Count < 10 then
  begin
    LInitialBuild := Default(TGearLoadout);
    LRequiredBrands := CloneBrandRequirements(AArchetype.RequiredBrandSets);
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
  end;

  Result := TList<TGearLoadout>.Create;
  for var Build in FGeneratedBuilds do
    Result.Add(Build);
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

  function AttrMatchesWeight(const AttrId, WeightKey: string): Boolean;
  var
    NormAttr, NormKey: string;
  begin
    Result := False;
    if AttrId = '' then
      Exit;

    NormAttr := NormalizeAttrId(AttrId);
    NormKey := NormalizeAttrId(WeightKey);

    Result := (NormAttr <> '') and
              ((NormAttr.Contains(NormKey)) or (NormKey.Contains(NormAttr)));
  end;

  function GetSetWeight(const SetName: string; const Bonuses: TArray<TSetBonus>): Double;
  var
    SB: TSetBonus;
    Key: string;
    Denom: Integer;
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
          Result := Result + (SB.Value / Denom) * AWeights[Key];
          Break;
        end;
      end;
    end;
    SetWeightCache.AddOrSetValue(SetName, Result);
  end;
begin
  AGearPool := TDictionary<TItemType, TList<TGearPiece>>.Create;
  for LItemType := Low(TItemType) to itKneepads do
    AGearPool.Add(LItemType, TList<TGearPiece>.Create);

  SetWeightCache := TDictionary<string, Double>.Create(TIStringComparer.Ordinal);
  try
    for LBrandSet in FDataIterator.AllPieceSetDefinitions.Values do
    begin
      // Pre-compute the weight of this set once for later sorting
      GetSetWeight(CalcEngine.CanonicalSetName(LBrandSet.Name), LBrandSet.Bonuses);

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

        // Filter by Allowed Brands if specified
        if Assigned(AArchetype.AllowedBrandSets) and (AArchetype.AllowedBrandSets.Count > 0) then
        begin
          if not AArchetype.AllowedBrandSets.Contains(LGearPiece.SetName) then
            Continue;
        end;

        // Strict Filter: Reject items that do not match the required core attribute for this slot
        if Assigned(AArchetype.RequiredCoreAttribute) and
           AArchetype.RequiredCoreAttribute.ContainsKey(LPart.GearSlot) then
        begin
          if LGearPiece.CoreAttribute.AttrType <>
             AArchetype.RequiredCoreAttribute[LPart.GearSlot] then
            Continue;
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

        // Heuristic Beam Search / Optimization:
        // Limit the pool to the top K candidates per slot to prevent combinatorial explosion.
        // We keep more candidates for slots that typically define a build (Chest/Backpack).
        var LLimit := 15;
        if (LItemType = itChest) or (LItemType = itBackpack) then
          LLimit := 25;

        if AGearPool[LItemType].Count > LLimit then
        begin
          // Ensure we don't truncate Exotics that might be important
          var LNewList := TList<TGearPiece>.Create;
          try
            for var i := 0 to AGearPool[LItemType].Count - 1 do
            begin
              var LGear := AGearPool[LItemType][i];
              if (LNewList.Count < LLimit) or (LGear.SetType = stExoticSet) then
                LNewList.Add(LGear);

              if LNewList.Count >= 40 then Break; // Absolute cap
            end;
            AGearPool[LItemType].Clear;
            AGearPool[LItemType].AddRange(LNewList);
          finally
            LNewList.Free;
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

    // Required brands
    if Assigned(AArchetype.RequiredBrandSets) then
      for LBrandName in AArchetype.RequiredBrandSets.Keys do
      begin
        if not LBrandSetCounts.TryGetValue(LBrandName, LCount) then
          LCount := 0;

        // Account for NinjaBike bonus
        if LHasNinjaBike and (LCount > 0) then
          Inc(LCount);

        if (LCount < AArchetype.RequiredBrandSets[LBrandName]) then
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
        if ABuild.GearPieces[LItemType].CoreAttribute.AttrType <>
           AArchetype.RequiredCoreAttribute[LItemType] then
        begin
          Result := False;
          Exit;
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
  LSetDef: TPieceSet;
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
      if FDataIterator.AllPieceSetDefinitions.TryGetValue(LSetName, LSetDef) and
         (LSetDef.SetType = stGearSet) then
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
  LBrandSet: TPieceSet;
  LGearPiece: TGearPiece;
  LSetName: string;
  LGroup: TSetGroup;
  LCoreDef: TCoreAttributeDefinition;
  LFixedDef: TFixedMinorAttributeDefinition;
  LIdx: Integer;
  LMaxExotics: Integer;

  function GetSetWeight(const SetName: string; const Bonuses: TArray<TSetBonus>): Double;
  var
    SB: TSetBonus;
    Key: string;
    Denom: Integer;
    NormAttr, NormKey: string;
  begin
    Result := 0;
    if (AWeights = nil) or (AWeights.Count = 0) then Exit;
    for SB in Bonuses do
    begin
      if SB.AttributeID = '' then Continue;
      NormAttr := NormalizeAttrId(SB.AttributeID);
      for Key in AWeights.Keys do
      begin
        NormKey := NormalizeAttrId(Key);
        if (NormAttr <> '') and ((NormAttr.Contains(NormKey)) or (NormKey.Contains(NormAttr))) then
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
      if (LGroup.SetWeight > 0) or (LGroup.SetType = stExoticSet) or
         SameText(LGroup.SetName, 'NinjaBike Messenger Backpack') then
        LRelevantSets.Add(LGroup);
    end;

    // Sort by weight
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
  begin
    if ABuildsFound >= AMaxBuilds then Exit;

    if Slot > itKneepads then
    begin
      if MeetsBuildRequirements(ACurrentBuild, AArchetype) and IsValidGearSetCombination(ACurrentBuild) then
      begin
        FGeneratedBuilds.Add(ACurrentBuild);
        Inc(ABuildsFound);
      end;
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

        AssignRecursiveInternal(Succ(Slot));

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
        if IsValidGearSetCombination(ACurrentBuild) and MeetsBuildRequirements(ACurrentBuild, AArchetype) then
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

end.
