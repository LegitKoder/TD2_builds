unit BuildGenerator;

interface

uses
  System.SysUtils, System.Generics.Defaults, System.Generics.Collections,
  Game.Types, RecommendationEngine, Game.JsonIterator, CalcEngine,         // pour TPlayerAggregatedStats et les calculs
  System.StrUtils;

type
  TScoredAttribute = (
    saUnknown,
    // Minor Attributes
    saRepairSkills, saSkillHaste, saSkillDamage, saStatusEffects,
    saCritChance, saCritDamage, saHeadshotDamage,
    saArmorRegen, saExplosiveResistance, saHazardProtection,
    saHealth, saIncomingRepairs, saWeaponHandling,
    // Extra Stats
    saWeaponDamage, saTotalArmor, saArmorOnKill,
    saAccuracy, saStability, saReloadSpeed,
    saGenericResistance
  );

  TBuildGenerator = class
  private
    FDataIterator: TDataJsonIterator;
    FRecommendationEngine: TRecommendationEngine;
    function ParseWeights(const RawWeights: TDictionary<string, Double>): TDictionary<TScoredAttribute, Double>;
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

function TBuildGenerator.ParseWeights(const RawWeights: TDictionary<string, Double>): TDictionary<TScoredAttribute, Double>;
var
  Attr: string;
  NormAttr: string;
  Weight: Double;
begin
  Result := TDictionary<TScoredAttribute, Double>.Create;
  if RawWeights = nil then Exit;

  for Attr in RawWeights.Keys do
  begin
    Weight := RawWeights[Attr];
    NormAttr := LowerCase(StringReplace(Attr, ' ', '', [rfReplaceAll]));

    if ContainsText(NormAttr, 'repairskills') then Result.AddOrSetValue(saRepairSkills, Weight)
    else if ContainsText(NormAttr, 'skillhaste') then Result.AddOrSetValue(saSkillHaste, Weight)
    else if ContainsText(NormAttr, 'skilldamage') then Result.AddOrSetValue(saSkillDamage, Weight)
    else if ContainsText(NormAttr, 'statuseffects') then Result.AddOrSetValue(saStatusEffects, Weight)
    else if ContainsText(NormAttr, 'crit') and ContainsText(NormAttr, 'chance') then Result.AddOrSetValue(saCritChance, Weight)
    else if ContainsText(NormAttr, 'crit') and ContainsText(NormAttr, 'damage') then Result.AddOrSetValue(saCritDamage, Weight)
    else if ContainsText(NormAttr, 'headshot') then Result.AddOrSetValue(saHeadshotDamage, Weight)
    else if ContainsText(NormAttr, 'armorregen') then Result.AddOrSetValue(saArmorRegen, Weight)
    else if ContainsText(NormAttr, 'weapondamage') then Result.AddOrSetValue(saWeaponDamage, Weight)
    else if ContainsText(NormAttr, 'accuracy') then Result.AddOrSetValue(saAccuracy, Weight)
    else if ContainsText(NormAttr, 'stability') then Result.AddOrSetValue(saStability, Weight)
    else if ContainsText(NormAttr, 'reload') then Result.AddOrSetValue(saReloadSpeed, Weight)
    else if ContainsText(NormAttr, 'weaponhandling') then Result.AddOrSetValue(saWeaponHandling, Weight)
    else if ContainsText(NormAttr, 'health') then Result.AddOrSetValue(saHealth, Weight)
    else if ContainsText(NormAttr, 'armoronkill') or ContainsText(NormAttr, 'healthonkill') then Result.AddOrSetValue(saArmorOnKill, Weight)
    else if ContainsText(NormAttr, 'incomingrepair') then Result.AddOrSetValue(saIncomingRepairs, Weight)
    else if ContainsText(NormAttr, 'totalarmor') or ContainsText(NormAttr, 'armor') then Result.AddOrSetValue(saTotalArmor, Weight)
    else if ContainsText(NormAttr, 'explosive') and ContainsText(NormAttr, 'resistance') then Result.AddOrSetValue(saExplosiveResistance, Weight)
    else if ContainsText(NormAttr, 'hazard') then Result.AddOrSetValue(saHazardProtection, Weight)
    else if ContainsText(NormAttr, 'resistance') then Result.AddOrSetValue(saGenericResistance, Weight);
  end;
end;

/// <summary>
/// Calcule un score pour un build en fonction des statistiques agrégées et des attributs ciblés.
/// Les poids sont ajustables selon l’importance de chaque attribut.
/// </summary>
function ScoreBuild(const AggStats: TPlayerAggregatedStats; const DispStats: TLoadoutAggregatedStats_Display; Weights: TDictionary<TScoredAttribute, Double>): Double;
var
  Attr: TScoredAttribute;
  Weight: Double;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count = 0) then Exit;

  for Attr in Weights.Keys do
  begin
    Weight := Weights[Attr];
    case Attr of
      saRepairSkills: Result := Result + AggStats.TotalRepairSkills * Weight;
      saSkillHaste: Result := Result + AggStats.TotalSkillHaste * Weight;
      saSkillDamage: Result := Result + AggStats.TotalSkillDamage * Weight;
      saStatusEffects: Result := Result + AggStats.TotalStatusEffects * Weight;
      saCritChance: Result := Result + DispStats.FinalCHC_Pct_Display * Weight;
      saCritDamage: Result := Result + DispStats.FinalCHD_Pct_Display * Weight;
      saHeadshotDamage: Result := Result + DispStats.FinalHSD_Pct_Display * Weight;
      saArmorRegen: Result := Result + DispStats.TotalArmorRegenPct * Weight;
      saWeaponDamage: Result := Result + DispStats.TotalWeaponDamage_AWD_Pct_Display * Weight;
      saAccuracy: Result := Result + DispStats.TotalHandling_Accuracy_Pct_Display * Weight;
      saStability: Result := Result + DispStats.TotalHandling_Stability_Pct_Display * Weight;
      saReloadSpeed: Result := Result + DispStats.TotalHandling_ReloadSpeed_Pct_Display * Weight;
      saWeaponHandling:
        Result := Result + (DispStats.TotalHandling_Accuracy_Pct_Display +
                            DispStats.TotalHandling_Stability_Pct_Display +
                            DispStats.TotalHandling_ReloadSpeed_Pct_Display) * Weight;
      saHealth: Result := Result + DispStats.TotalHealth_Display * Weight;
      saArmorOnKill: Result := Result + DispStats.TotalArmorOnKillPct * Weight;
      saIncomingRepairs: Result := Result + DispStats.TotalIncomingRepairsPct * Weight;
      saTotalArmor: Result := Result + DispStats.TotalArmor_Display * Weight;
      saExplosiveResistance: Result := Result + DispStats.TotalExplosiveResistancePct * Weight;
      saHazardProtection: Result := Result + DispStats.TotalHazardProtectionPct * Weight;
      saGenericResistance: Result := Result + 1.0 * Weight;
    end;
  end;
end;

function TBuildGenerator.GenerateBuilds(const AArchetype: TBuildArchetype;
  const Weights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
var
  Candidates : TList<TGearLoadout>;
  OptimizedWeights: TDictionary<TScoredAttribute, Double>;
begin
  // on génère d’abord tous les builds via le moteur de recommandation
  Candidates := FRecommendationEngine.GenerateBuilds(AArchetype, Weights);

  if (Weights <> nil) and (Weights.Count > 0) and (Candidates <> nil) then
  begin
    OptimizedWeights := ParseWeights(Weights);
    try
      // Calculer le score pour chaque build candidat
      for var i := 0 to Candidates.Count - 1 do
      begin
        var LBuild := Candidates[i];
        var Input: TFullLoadoutInput;
        var TmpResult: TFullDamageCalcResult;
        var AggDisp: TLoadoutAggregatedStats_Display;
        var Stats: TPlayerAggregatedStats;

        FillChar(Input, SizeOf(Input), 0);
        for var j := 0 to High(LBuild.GearPieces) do
          if LBuild.GearPieces[j].Name <> '' then
            Input.EquippedGear[TItemType(j)] := LBuild.GearPieces[j];

        CalcEngine.CalculateCompleteLoadoutPerformance(
          Input,
          FDataIterator.AllPieceSetDefinitions, FDataIterator.WeaponStats,
          FDataIterator.Mods, FDataIterator.Talents, TmpResult, AggDisp);

        Stats := CalcEngine.AggregatePlayerStats(Input, FDataIterator.AllPieceSetDefinitions);

        LBuild.Score := ScoreBuild(Stats, AggDisp, OptimizedWeights);
        Candidates[i] := LBuild; // Update record in list
      end;
    finally
      OptimizedWeights.Free;
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

  Result := Candidates;
end;

end.
