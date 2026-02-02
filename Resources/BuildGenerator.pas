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
/// Calcule un score pour un build en fonction des statistiques dynamiques.
/// Le système est complètement dynamique : on multiplie chaque statistique agrégée par son poids.
/// </summary>
function ScoreBuild(const ADynamicStats: TDictionary<string, Double>; Weights: TDictionary<string, Double>): Double;
var
  WeightKey, StatKey, NormWeightKey, NormStatKey: string;
  Weight, StatValue: Double;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count = 0) or (ADynamicStats = nil) then Exit;

  for WeightKey in Weights.Keys do
  begin
    Weight := Weights[WeightKey];
    NormWeightKey := NormalizeAttrKey(WeightKey);

    // Recherche de la statistique correspondante (on autorise un match partiel pour plus de flexibilité)
    for StatKey in ADynamicStats.Keys do
    begin
      NormStatKey := NormalizeAttrKey(StatKey);
      if (NormStatKey = NormWeightKey) or
         (NormStatKey.Contains(NormWeightKey)) or
         (NormWeightKey.Contains(NormStatKey)) then
      begin
        StatValue := ADynamicStats[StatKey];
        Result := Result + (StatValue * Weight);
        // On ne break pas pour permettre de cumuler si plusieurs clés matchent (ex: skill_damage et skillDamage)
      end;
    end;
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
      var LDynamicStats: TDictionary<string, Double>;

      FillChar(Input, SizeOf(Input), 0);
      for var j := Low(LBuild.GearPieces) to High(LBuild.GearPieces) do
        if LBuild.GearPieces[j].Name <> '' then
          Input.EquippedGear[TItemType(j)] := LBuild.GearPieces[j];

      LDynamicStats := CalcEngine.AggregateAllStats(Input, FDataIterator.AllPieceSetDefinitions);
      try
        LBuild.Score := ScoreBuild(LDynamicStats, Weights);
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

  Result := Candidates;
end;

end.
