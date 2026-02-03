unit BuildGenerator;

interface

uses
  System.SysUtils, System.Generics.Defaults, System.Generics.Collections,
  System.StrUtils, System.Character, Game.Types, RecommendationEngine,
  Game.JsonIterator, CalcEngine;         // pour TPlayerAggregatedStats et les calculs


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
/// Calcule un score pour un build en fonction des statistiques dynamiques.
/// Le système est complètement dynamique : on multiplie chaque statistique agrégée par son poids.
/// </summary>
function ScoreBuild(const Ctx: TScoreContext; Weights: TDictionary<string, Double>): Double;
var
  WeightKey, StatKey, NormWeightKey, NormStatKey: string;
  Weight, StatValue: Double;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count = 0) or (Ctx.DynamicStats = nil) then Exit;

  for WeightKey in Weights.Keys do
  begin
    Weight := Weights[WeightKey];
    NormWeightKey := NormalizeAttrId(WeightKey);

    // Recherche de la statistique correspondante (on autorise un match partiel pour plus de flexibilité)
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
        // On ne break pas pour permettre de cumuler si plusieurs clés matchent (ex: skill_damage et skillDamage)
      end;
    end;
  end;
end;

function TBuildGenerator.GenerateBuilds(const AArchetype: TBuildArchetype;
  const Weights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
const
  SCORE_EPS = 1e-6;
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

    // Keep only the best-scoring builds (ties included)
    if Candidates.Count > 0 then
    begin
      var MaxScore := Candidates[0].Score;
      for var idx := Candidates.Count - 1 downto 1 do
        if Abs(Candidates[idx].Score - MaxScore) > SCORE_EPS then
          Candidates.Delete(idx);
    end;
  end;

  Result := Candidates;
end;

end.

