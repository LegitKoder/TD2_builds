unit BuildGenerator;

interface

uses
  System.SysUtils, System.Generics.Defaults, System.Generics.Collections,
  System.StrUtils, System.Character, Game.Types, RecommendationEngine,
  Game.JsonIterator, CalcEngine;         // pour TPlayerAggregatedStats et les calculs


type
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

/// Normalise une clé d'attribut pour le scoring
///  - lower case
///  - suppression des espaces, '_' et '%'
///  - ex: "Critical Hit Damage", "critical_hit_damage%", "CRIT Hit DMG"
///    => "criticalhitdamage"
function NormalizeAttrKey(const S: string): string;
begin
  Result := LowerCase(S.Trim);
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '_', '', [rfReplaceAll]);
  Result := StringReplace(Result, '%', '', [rfReplaceAll]);
end;

/// <summary>
/// Calculates a score for a build based on aggregated stats and a target attribute.
/// The score is the direct value of the single target attribute.
/// </summary>
function ScoreBuild(const AggStats: TPlayerAggregatedStats; const DispStats: TLoadoutAggregatedStats_Display; Weights: TDictionary<string, Double>): Double;
var
  Attr, NormAttr: string;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count <> 1) then Exit;

  Attr := Weights.Keys.First;
  NormAttr := NormalizeAttrKey(Attr);

  // The logic is simplified to score based on the single selected attribute.
  // The 'Weight' is assumed to be 1.0 for the direct score calculation.
  if SameText(NormAttr, C_ATTR_REPAIR_SKILLS) then
    Result := AggStats.TotalRepairSkills
  else if SameText(NormAttr, C_ATTR_SKILL_HASTE) then
    Result := AggStats.TotalSkillHaste
  else if SameText(NormAttr, C_ATTR_SKILL_DAMAGE) then
    Result := AggStats.TotalSkillDamage
  else if SameText(NormAttr, C_ATTR_STATUS_EFFECTS) then
    Result := AggStats.TotalStatusEffects
  else if SameText(NormAttr, C_ATTR_CRITICAL_HIT_CHANCE) then
    Result := DispStats.FinalCHC_Pct_Display
  else if SameText(NormAttr, C_ATTR_CRITICAL_HIT_DAMAGE) then
    Result := DispStats.FinalCHD_Pct_Display
  else if SameText(NormAttr, C_ATTR_HEADSHOT_DAMAGE) then
    Result := DispStats.FinalHSD_Pct_Display
  else if SameText(NormAttr, C_ATTR_ARMOR_REGEN) then
    Result := DispStats.TotalArmorRegenPct
  else if SameText(NormAttr, C_ATTR_ARMOR_ON_KILL) then
    Result := DispStats.TotalArmorOnKillPct
  else if SameText(NormAttr, C_ATTR_TOTAL_ARMOR) then
    Result := DispStats.TotalArmor_Display
  else if SameText(NormAttr, C_ATTR_HEALTH) then
    Result := DispStats.TotalHealth_Display
  else if SameText(NormAttr, C_ATTR_INCOMING_REPAIRS) then
    Result := DispStats.TotalIncomingRepairsPct
  else if SameText(NormAttr, C_ATTR_WEAPON_DAMAGE) then
    Result := DispStats.TotalWeaponDamage_AWD_Pct_Display
  else if SameText(NormAttr, C_ATTR_ACCURACY) then
    Result := DispStats.TotalHandling_Accuracy_Pct_Display
  else if SameText(NormAttr, C_ATTR_STABILITY) then
    Result := DispStats.TotalHandling_Stability_Pct_Display
  else if SameText(NormAttr, C_ATTR_RELOAD_SPEED) then
    Result := DispStats.TotalHandling_ReloadSpeed_Pct_Display
  else if SameText(NormAttr, C_ATTR_WEAPON_HANDLING) then
    Result := (DispStats.TotalHandling_Accuracy_Pct_Display +
               DispStats.TotalHandling_Stability_Pct_Display +
               DispStats.TotalHandling_ReloadSpeed_Pct_Display)
  else if SameText(NormAttr, C_ATTR_EXPLOSIVE_RESISTANCE) then
    Result := DispStats.TotalExplosiveResistancePct
  else if SameText(NormAttr, C_ATTR_HAZARD_PROTECTION) then
    Result := DispStats.TotalHazardProtectionPct;
end;

function TBuildGenerator.GenerateBuilds(const AArchetype: TBuildArchetype;
  const Weights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
var
  Candidates : TList<TGearLoadout>;
  LAttributeID: string;
begin
  LAttributeID := '';
  if (Weights <> nil) and (Weights.Count = 1) then
  begin
    // If there's exactly one weight, we assume it's our target attribute for generation
    LAttributeID := Weights.Keys.First;
  end;

  // on génère d’abord tous les builds via le moteur de recommandation
  Candidates := FRecommendationEngine.GenerateBuilds(AArchetype, Weights, LAttributeID);

  if (Weights <> nil) and (Weights.Count > 0) and (Candidates <> nil) then
  begin
    // Calculer le score pour chaque build candidat
    for var i := 0 to Candidates.Count - 1 do
    begin
      var LBuild := Candidates[i];
      var Input: TFullLoadoutInput;
      var TmpResult: TFullDamageCalcResult;
      var AggDisp: TLoadoutAggregatedStats_Display;
      var Stats: TPlayerAggregatedStats;

      FillChar(Input, SizeOf(Input), 0);
      for var j := Low(LBuild.GearPieces) to High(LBuild.GearPieces) do
        if LBuild.GearPieces[j].Name <> '' then
          Input.EquippedGear[TItemType(j)] := LBuild.GearPieces[j];

      CalcEngine.CalculateCompleteLoadoutPerformance(
        Input,
        FDataIterator.AllPieceSetDefinitions, FDataIterator.WeaponStats,
        FDataIterator.Mods, FDataIterator.Talents, TmpResult, AggDisp);

      Stats := CalcEngine.AggregatePlayerStats(Input, FDataIterator.AllPieceSetDefinitions);

      LBuild.Score := ScoreBuild(Stats, AggDisp, Weights);
      Candidates[i] := LBuild; // Update record in list
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
