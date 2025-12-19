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
/// Calcule un score pour un build en fonction des statistiques agrégées et des attributs ciblés.
/// Les poids sont ajustables selon l’importance de chaque attribut.
/// </summary>
function ScoreBuild(const AggStats: TPlayerAggregatedStats; const DispStats: TLoadoutAggregatedStats_Display; Weights: TDictionary<string, Double>): Double;
var
  Attr, NormAttr: string;
  Weight: Double;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count = 0) then Exit;

  for Attr in Weights.Keys do
  begin
    Weight   := Weights[Attr];
    NormAttr := NormalizeAttrKey(Attr);

    // Skills
    if ContainsText(NormAttr, 'repairskills') then
      Result := Result + AggStats.TotalRepairSkills * Weight
    else if ContainsText(NormAttr, 'skillhaste') then
      Result := Result + AggStats.TotalSkillHaste * Weight
    else if ContainsText(NormAttr, 'skilldamage') then
      Result := Result + AggStats.TotalSkillDamage * Weight
    else if ContainsText(NormAttr, 'statuseffects') then
      Result := Result + AggStats.TotalStatusEffects * Weight

    // Crit / HSD
    else if ContainsText(NormAttr, 'crit') and ContainsText(NormAttr, 'chance') then
      Result := Result + DispStats.FinalCHC_Pct_Display * Weight
    else if ContainsText(NormAttr, 'crit') and ContainsText(NormAttr, 'damage') then
      Result := Result + DispStats.FinalCHD_Pct_Display * Weight
    else if ContainsText(NormAttr, 'headshot') then
      Result := Result + DispStats.FinalHSD_Pct_Display * Weight

    // Armor / tank
    else if ContainsText(NormAttr, 'armorregen') then
      Result := Result + DispStats.TotalArmorRegenPct * Weight
    else if ContainsText(NormAttr, 'armoronkill') or
            ContainsText(NormAttr, 'healthonkill') then
      Result := Result + DispStats.TotalArmorOnKillPct * Weight
    else if ContainsText(NormAttr, 'totalarmor') or
            (ContainsText(NormAttr, 'armor') and not ContainsText(NormAttr, 'regen')) then
      Result := Result + DispStats.TotalArmor_Display * Weight
    else if ContainsText(NormAttr, 'health') then
      Result := Result + DispStats.TotalHealth_Display * Weight
    else if ContainsText(NormAttr, 'incomingrepair') then
      Result := Result + DispStats.TotalIncomingRepairsPct * Weight

    // Weapon damage / handling
    else if ContainsText(NormAttr, 'weapondamage') then
      Result := Result + DispStats.TotalWeaponDamage_AWD_Pct_Display * Weight
    else if ContainsText(NormAttr, 'accuracy') then
      Result := Result + DispStats.TotalHandling_Accuracy_Pct_Display * Weight
    else if ContainsText(NormAttr, 'stability') then
      Result := Result + DispStats.TotalHandling_Stability_Pct_Display * Weight
    else if ContainsText(NormAttr, 'reload') then
      Result := Result + DispStats.TotalHandling_ReloadSpeed_Pct_Display * Weight
    else if ContainsText(NormAttr, 'weaponhandling') then
      Result := Result + (DispStats.TotalHandling_Accuracy_Pct_Display +
                          DispStats.TotalHandling_Stability_Pct_Display +
                          DispStats.TotalHandling_ReloadSpeed_Pct_Display) * Weight

    // Résistances génériques
    else if ContainsText(NormAttr, 'explosiveresistance') then
      Result := Result + DispStats.TotalExplosiveResistancePct * Weight
    else if ContainsText(NormAttr, 'hazardprotection') then
      Result := Result + DispStats.TotalHazardProtectionPct * Weight
    else if ContainsText(NormAttr, 'resistance') then
      Result := Result + 1.0 * Weight; // fallback générique
  end;
end;

function TBuildGenerator.GenerateBuilds(const AArchetype: TBuildArchetype;
  const Weights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
var
  Candidates : TList<TGearLoadout>;
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
