unit BuildGenerator;

interface

uses
  System.SysUtils, System.Generics.Defaults, System.Generics.Collections,
  System.StrUtils, System.Character, Game.Types, RecommendationEngine,
  Game.JsonIterator, CalcEngine,
  Game.AttributeMapper;         // pour TPlayerAggregatedStats et les calculs


type
  TScoreContext = record
    DynamicStats: TDictionary<string, Double>;
    AggStats: TPlayerAggregatedStats;
    DispStats: TLoadoutAggregatedStats_Display;
  end;

  TBuildGenerator = class
  private
    FDataIterator: TDataJsonIterator;
    FRecommendationEngine: TRecommendationEngine;
  public
    constructor Create(ADataIterator: TDataJsonIterator);
    destructor Destroy; override;
    function GenerateBuilds(const AArchetype: TBuildArchetype;
      const Weights: TDictionary<string, Double> = nil): TList<TGearLoadout>; overload;
  end;

implementation

{ TBuildGenerator }

constructor TBuildGenerator.Create(ADataIterator: TDataJsonIterator);
begin
  FDataIterator := ADataIterator;
  FRecommendationEngine := TRecommendationEngine.Create(FDataIterator);
end;

destructor TBuildGenerator.Destroy;
begin
  FRecommendationEngine.Free;
  inherited;
end;

function AttrDisplayName(const AttrId: string): string;
begin
  Result := AttrId;
  var NormAttr := NormalizeAttrId(AttrId);
  for var Entry in GetAttributeCatalog do
    if NormalizeAttrId(Entry.ID) = NormAttr then
      Exit(Entry.DisplayName);
end;

function DisplayNameForWeight(const WeightKey: string): string;
var
  AttrID: TAttributeID;
  Mapped: string;
begin
  if TAttributeMapper.TryParse(WeightKey, AttrID) then
  begin
    Mapped := TAttributeMapper.DisplayName(AttrID);
    if Mapped <> '' then
      Exit(Mapped);
  end;
  Result := AttrDisplayName(WeightKey);
end;

function TryGetStatValue(const Stats: TDictionary<string, Double>;
  AttrID: TAttributeID; out Value: Double): Boolean;
var
  V: Double;
  function TryGet(const Key: string; out OutVal: Double): Boolean;
  begin
    if (Stats <> nil) and Stats.TryGetValue(Key, OutVal) then
      Exit(True);
    OutVal := 0;
    Result := False;
  end;
  function TryGetSum(const Keys: array of string; out OutVal: Double): Boolean;
  begin
    OutVal := 0;
    Result := False;
    for var Key in Keys do
      if TryGet(Key, V) then
      begin
        OutVal := OutVal + V;
        Result := True;
      end;
  end;
begin
  Value := 0;
  case AttrID of
    atCriticalHitChance:    Result := TryGet('criticalhitchance', Value);
    atCriticalHitDamage:    Result := TryGet('criticalhitdamage', Value);
    atHeadshotDamage:       Result := TryGet('headshotdamage', Value);
    atWeaponDamage:         Result := TryGet('weapondamage', Value);
    atAssaultRifleDamage:   Result := TryGet('assaultrifledamage', Value);
    atSMGDamage:            Result := TryGet('smgdamage', Value);
    atLMGDamage:            Result := TryGet('lmgdamage', Value);
    atShotgunDamage:        Result := TryGet('shotgundamage', Value);
    atRifleDamage:          Result := TryGet('rifledamage', Value);
    atMMRDamage:            Result := TryGetSum(['marksmanrifledamage', 'mmrdamage'], Value);
    atPistolDamage:         Result := TryGet('pistoldamage', Value);
    atDamageToArmor:        Result := TryGet('damagetoarmor', Value);
    atHealthDamage:         Result := TryGetSum(['healthdamage', 'damagetohealth'], Value);
    atDamageOutOfCover:     Result := TryGetSum(['damageoutofcover', 'damagetotargetoutofcover'], Value);
    atHealth:               Result := TryGet('health', Value);
    atArmor:                Result := TryGetSum(['armor', 'totalarmor'], Value);
    atArmorRegen:           Result := TryGetSum(['armorregen', 'armorregenpct'], Value);
    atArmorOnKill:          Result := TryGet('armoronkill', Value);
    atHealthOnKill:         Result := TryGet('healthonkill', Value);
    atHazardProtection:     Result := TryGet('hazardprotection', Value);
    atExplosiveResistance:  Result := TryGet('explosiveresistance', Value);
    atIncomingRepairs:      Result := TryGet('incomingrepairs', Value);
    atSkillTier:            Result := TryGet('skilltier', Value);
    atSkillDamage:          Result := TryGet('skilldamage', Value);
    atSkillHaste:           Result := TryGet('skillhaste', Value);
    atSkillDuration:        Result := TryGet('skillduration', Value);
    atRepairSkills:         Result := TryGet('repairskills', Value);
    atStatusEffects:        Result := TryGet('statuseffects', Value);
    atSkillHealth:          Result := TryGet('skillhealth', Value);
    atExplosiveDamage:      Result := TryGet('explosivedamage', Value);
    atAccuracy:             Result := TryGet('accuracy', Value);
    atStability:            Result := TryGet('stability', Value);
    atReloadSpeed:          Result := TryGet('reloadspeed', Value);
    atOptimalRange:         Result := TryGet('optimalrange', Value);
    atWeaponHandling:
      begin
        Result := TryGet('weaponhandling', Value);
        if not Result then
          Result := TryGetSum(['accuracy', 'stability', 'reloadspeed'], Value);
      end;
    atSwapSpeed:            Result := TryGet('swapspeed', Value);
    atMagazineSize:         Result := TryGet('magazinesize', Value);
    atAmmoCapacity:         Result := TryGet('ammocapacity', Value);
    atRateOfFire:           Result := TryGet('rateoffire', Value);
  else
    Result := False;
  end;
end;

function BuildStatSummary(const Weights: TDictionary<string, Double>;
  const DynamicStats: TDictionary<string, Double>): string;
var
  WeightKeys: TArray<string>;
  WeightKey: string;
  AttrID: TAttributeID;
  Val: Double;
begin
  Result := '';
  if (Weights = nil) or (Weights.Count = 0) or (DynamicStats = nil) then
    Exit;

  WeightKeys := Weights.Keys.ToArray;
  TArray.Sort<string>(WeightKeys, TComparer<string>.Construct(
    function(const L, R: string): Integer
    begin
      Result := CompareText(DisplayNameForWeight(L), DisplayNameForWeight(R));
    end));

  for WeightKey in WeightKeys do
  begin
    if TAttributeMapper.TryParse(WeightKey, AttrID) then
    begin
      if TryGetStatValue(DynamicStats, AttrID, Val) then
      begin
        Result := Result + Format('%s: %.1f, ', [DisplayNameForWeight(WeightKey), Val]);
        Continue;
      end;
    end;
    if DynamicStats.TryGetValue(NormalizeAttrId(WeightKey), Val) then
      Result := Result + Format('%s: %.1f, ', [DisplayNameForWeight(WeightKey), Val]);
  end;

  if Result <> '' then
    SetLength(Result, Length(Result) - 2);
end;

/// <summary>
/// Calcule un score pour un build en fonction des statistiques dynamiques.
/// Le système est complètement dynamique : on multiplie chaque statistique agrégée par son poids.
/// </summary>
function ScoreBuild(const Ctx: TScoreContext; Weights: TDictionary<string, Double>): Double;
var
  WeightKey, StatKey, NormWeightKey, NormStatKey: string;
  Weight, StatValue: Double;
  AttrID: TAttributeID;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count = 0) or (Ctx.DynamicStats = nil) then Exit;

  for WeightKey in Weights.Keys do
  begin
    Weight := Weights[WeightKey];
    if TAttributeMapper.TryParse(WeightKey, AttrID) then
    begin
      if TryGetStatValue(Ctx.DynamicStats, AttrID, StatValue) then
      begin
        Result := Result + (StatValue * Weight);
        Continue;
      end;
      // If the enum mapping didn't yield a value, fall through to legacy lookup.
    end;

    NormWeightKey := NormalizeAttrId(WeightKey);
    if (NormWeightKey <> '') and Ctx.DynamicStats.TryGetValue(NormWeightKey, StatValue) then
    begin
      Result := Result + (StatValue * Weight);
      Continue;
    end;
    if NormWeightKey = '' then
      Continue;

    // Fallback legacy partial matching (only for unknown keys)
    for StatKey in Ctx.DynamicStats.Keys do
    begin
      NormStatKey := NormalizeAttrId(StatKey);
      if (NormStatKey <> '') and
         ((NormStatKey = NormWeightKey) or
          (NormStatKey.Contains(NormWeightKey)) or
          (NormWeightKey.Contains(NormStatKey))) then
      begin
        StatValue := Ctx.DynamicStats[StatKey];
        Result := Result + (StatValue * Weight);
      end;
    end;
  end;
end;

function TBuildGenerator.GenerateBuilds(const AArchetype: TBuildArchetype;
  const Weights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
var
  Candidates : TList<TGearLoadout>;
  Filtered: TList<TGearLoadout>;
  Seen: TDictionary<string, Boolean>;
  SeenPrimarySet: TDictionary<string, Boolean>;
  CanonicalSetDefs: TDictionary<string, TPieceSet>;

  function BuildKey(const B: TGearLoadout): string;
  var
    Counts: TDictionary<string, Integer>;
    Keys: TArray<string>;
    Parts: TArray<string>;
    I: Integer;
    GP: TGearPiece;
    NameKey: string;
    Current: Integer;
  begin
    Counts := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
    try
      for I := Ord(itMask) to Ord(itKneepads) do
      begin
        GP := B.GearPieces[TItemType(I)];
        if GP.SetName <> '' then
          NameKey := LowerCase(GP.SetName)
        else if GP.Name <> '' then
          NameKey := LowerCase(GP.Name)
        else
          NameKey := '';

        if NameKey <> '' then
        begin
          if not Counts.TryGetValue(NameKey, Current) then
            Current := 0;
          Counts.AddOrSetValue(NameKey, Current + 1);
        end;
      end;

      Keys := Counts.Keys.ToArray;
      TArray.Sort<string>(Keys, TComparer<string>.Default);
      SetLength(Parts, Length(Keys));
      for I := 0 to High(Keys) do
        Parts[I] := Keys[I] + ':' + IntToStr(Counts[Keys[I]]);

      Result := string.Join('|', Parts);
    finally
      Counts.Free;
    end;
  end;

  function AttrMatchesWeight(const AttrId: string): Boolean;
  var
    NormAttr, NormKey: string;
    Key: string;
  begin
    Result := False;
    if (Weights = nil) or (Weights.Count = 0) or (AttrId = '') then
      Exit;
    NormAttr := NormalizeAttrId(AttrId);
    if NormAttr = '' then
      Exit;
    for Key in Weights.Keys do
    begin
      NormKey := NormalizeAttrId(Key);
      if (NormKey <> '') and ((NormAttr.Contains(NormKey)) or (NormKey.Contains(NormAttr))) then
        Exit(True);
    end;
  end;

  function WeightForAttr(const AttrId: string): Double;
  var
    NormAttr, NormKey: string;
    Key: string;
  begin
    Result := 0;
    if (Weights = nil) or (Weights.Count = 0) or (AttrId = '') then
      Exit;
    NormAttr := NormalizeAttrId(AttrId);
    if NormAttr = '' then
      Exit;
    for Key in Weights.Keys do
    begin
      NormKey := NormalizeAttrId(Key);
      if (NormKey <> '') and ((NormAttr.Contains(NormKey)) or (NormKey.Contains(NormAttr))) then
        Exit(Weights[Key]);
    end;
  end;

  function PrimaryWeightedSetKey(const B: TGearLoadout): string;
  var
    Counts: TDictionary<string, Integer>;
    Pair: TPair<string, Integer>;
    SetDef: TPieceSet;
    Bonus: TSetBonus;
    BestWeight: Double;
    WeightSum: Double;
  begin
    Result := '';
    if (Weights = nil) or (Weights.Count = 0) or (CanonicalSetDefs = nil) then
      Exit;

    BestWeight := 0;
    Counts := CalcEngine.GetEffectiveSetCounts(B.GearPieces);
    try
      for Pair in Counts do
      begin
        if not CanonicalSetDefs.TryGetValue(Pair.Key, SetDef) then
          Continue;
        WeightSum := 0;
        for Bonus in SetDef.Bonuses do
        begin
          if (Bonus.AttributeID <> '') and (Pair.Value >= Bonus.ItemsRequired) and
             AttrMatchesWeight(Bonus.AttributeID) then
          begin
            var W := WeightForAttr(Bonus.AttributeID);
            if W > 0 then
              WeightSum := WeightSum + (Bonus.Value * W);
          end;
        end;
        if WeightSum > BestWeight then
        begin
          BestWeight := WeightSum;
          Result := Pair.Key;
        end;
      end;
    finally
      Counts.Free;
    end;
  end;
begin
  // on génère d’abord tous les builds via le moteur de recommandation
  Candidates := FRecommendationEngine.GenerateBuilds(AArchetype, Weights);

  if (Weights <> nil) and (Weights.Count > 0) and (Candidates <> nil) then
  begin
    // Calculer le score pour chaque build candidat
    for var i := 0 to Candidates.Count - 1 do
    begin
      var LBuild := Candidates[i];
      var Input: TFullLoadoutInput;
      var LDynamicStats: TDictionary<string, Double>;
      var Ctx: TScoreContext;

      FillChar(Input, SizeOf(Input), 0);
      for var j := Low(LBuild.GearPieces) to High(LBuild.GearPieces) do
        if LBuild.GearPieces[j].Name <> '' then
          Input.EquippedGear[TItemType(j)] := LBuild.GearPieces[j];

      LDynamicStats := CalcEngine.AggregateAllStats(Input, FDataIterator.AllPieceSetDefinitions);
      try
        FillChar(Ctx, SizeOf(Ctx), 0);
        Ctx.DynamicStats := LDynamicStats;
        LBuild.Score := ScoreBuild(Ctx, Weights);
        LBuild.StatSummary := BuildStatSummary(Weights, LDynamicStats);
        Candidates[i] := LBuild; // Update record in list
      finally
        LDynamicStats.Free;
      end;
    end;

    // Trier les builds selon le score pré-calculé (décroissant)
    Candidates.Sort(
      TComparer<TGearLoadout>.Construct(
        function(const L, R: TGearLoadout): Integer
        begin
          if L.Score > R.Score then
            Result := -1
          else if L.Score < R.Score then
            Result := 1
          else
            Result := 0;
        end));
  end;

  // De-duplicate and keep a reasonable top subset to improve variety.
  // If there are no weights, this still trims identical compositions.
  if (Candidates <> nil) and (Candidates.Count > 0) then
  begin
    Filtered := TList<TGearLoadout>.Create;
    Seen := TDictionary<string, Boolean>.Create(TIStringComparer.Ordinal);
    SeenPrimarySet := TDictionary<string, Boolean>.Create(TIStringComparer.Ordinal);
    CanonicalSetDefs := nil;
    try
      if (Weights <> nil) and (Weights.Count > 0) then
      begin
        CanonicalSetDefs := TDictionary<string, TPieceSet>.Create(TIStringComparer.Ordinal);
        for var PS in FDataIterator.AllPieceSetDefinitions.Values do
        begin
          var Key := CalcEngine.CanonicalSetName(PS.Name);
          if Key <> '' then
            CanonicalSetDefs.AddOrSetValue(Key, PS);
        end;
      end;

      // Pass 1: ensure diversity across weighted sets
      if (Weights <> nil) and (Weights.Count > 0) then
        for var B in Candidates do
        begin
          var Key := BuildKey(B);
          if Seen.ContainsKey(Key) then
            Continue;
          var PrimarySet := PrimaryWeightedSetKey(B);
          if (PrimarySet <> '') and not SeenPrimarySet.ContainsKey(PrimarySet) then
          begin
            Seen.Add(Key, True);
            SeenPrimarySet.Add(PrimarySet, True);
            Filtered.Add(B);
          end;
          if Filtered.Count >= 15 then
            Break;
        end;

      // Pass 2: fill remaining with unique compositions
      for var B in Candidates do
      begin
        var Key := BuildKey(B);
        if not Seen.ContainsKey(Key) then
        begin
          Seen.Add(Key, True);
          Filtered.Add(B);
        end;
        if Filtered.Count >= 30 then
          Break;
      end;
    finally
      if Assigned(CanonicalSetDefs) then
        CanonicalSetDefs.Free;
      SeenPrimarySet.Free;
      Seen.Free;
    end;

    Candidates.Free;
    Candidates := Filtered;
  end;

  Result := Candidates;
end;

end.

