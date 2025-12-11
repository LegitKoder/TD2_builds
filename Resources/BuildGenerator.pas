unit BuildGenerator;

interface

uses
  System.SysUtils, System.Generics.Defaults, System.Generics.Collections,
  System.StrUtils, System.Character, Math, Game.Types, RecommendationEngine,
  Game.JsonIterator, CalcEngine;

type
  TBuildGenerator = class
  private
    FDataIterator: TDataJsonIterator;
    FRecommendationEngine: TRecommendationEngine;

    // Helper to calculate score for a single gear piece
    function CalculatePieceScore(const Piece: TGearPiece;
      const Weights: TDictionary<string, Double>): Double;

    // Helper to calculate score for a set bonus
    function CalculateSetBonusScore(const Bonus: TSetBonus;
      const Weights: TDictionary<string, Double>): Double;

    // Helper to match attribute key with weight keys
    function GetWeightForAttribute(const AttrKey: string;
      const Weights: TDictionary<string, Double>): Double;

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

function NormalizeAttrKey(const S: string): string;
begin
  Result := LowerCase(S.Trim);
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '_', '', [rfReplaceAll]);
  Result := StringReplace(Result, '%', '', [rfReplaceAll]);
end;

function TBuildGenerator.GetWeightForAttribute(const AttrKey: string;
  const Weights: TDictionary<string, Double>): Double;
var
  WKey, NormAttr: string;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count = 0) then Exit;

  NormAttr := NormalizeAttrKey(AttrKey);

  // Iterate through weights and find match using the same logic as ScoreBuild
  for WKey in Weights.Keys do
  begin
    var NormWeightKey := NormalizeAttrKey(WKey);
    // Simple containment check as in ScoreBuild
    if ContainsText(NormWeightKey, NormAttr) or ContainsText(NormAttr, NormWeightKey) then
    begin
      Result := Weights[WKey];
      Exit;
    end;

    // Fallback for specific compound keys used in ScoreBuild
    // e.g. "crit chance" matching "criticalHitChance"
    if (ContainsText(NormAttr, 'crit') and ContainsText(NormAttr, 'chance') and
        ContainsText(NormWeightKey, 'crit') and ContainsText(NormWeightKey, 'chance')) then
    begin
       Result := Weights[WKey];
       Exit;
    end;

     if (ContainsText(NormAttr, 'crit') and ContainsText(NormAttr, 'damage') and
        ContainsText(NormWeightKey, 'crit') and ContainsText(NormWeightKey, 'damage')) then
    begin
       Result := Weights[WKey];
       Exit;
    end;
  end;
end;

function TBuildGenerator.CalculatePieceScore(const Piece: TGearPiece;
  const Weights: TDictionary<string, Double>): Double;
var
  W: Double;
begin
  Result := 0;
  if (Weights = nil) or (Weights.Count = 0) then Exit;

  // 1. Core Attribute
  if Piece.CoreAttribute.ID <> '' then
  begin
    W := GetWeightForAttribute(Piece.CoreAttribute.ID, Weights);
    if W > 0 then
    begin
      // Scaling adjustment:
      // CalcEngine internally treats WD as %, Armor as flat.
      // ScoreBuild adds "DispStats.TotalArmor_Display * Weight".
      // ScoreBuild adds "DispStats.TotalWeaponDamage... * Weight".
      // Previous ScoreBuild logic implicitly assumed weights were calibrated for the displayed values.
      // For fast scoring, we replicate this.
      // WeaponDamage in Piece is e.g. 15.0. In DispStats it's 0.15 (15%).
      // Wait, let's verify CalcEngine logic again.
      // CalcEngine: ADisplayStats.TotalWeaponDamage_AWD_Pct_Display := ... + LValueFraction;
      // LValueFraction = Value / 100.0. So 15.0 -> 0.15.
      // ScoreBuild uses DispStats.TotalWeaponDamage_AWD_Pct_Display.
      // So ScoreBuild sees 0.15 for 15% WD.
      // If we use Piece.CoreAttribute.Value (15.0), we are off by 100x compared to ScoreBuild logic.
      // So we MUST divide by 100 for percentage stats to match ScoreBuild's scale.

      if Piece.CoreAttribute.AttrType = catWeaponDamage then
        Result := Result + (Piece.CoreAttribute.Value / 100.0) * W
      else
        Result := Result + Piece.CoreAttribute.Value * W; // Armor / Skill Tier (flat)
    end;
  end;

  // 2. Minor Attributes
  for var Minor in Piece.MinorAttributes do
  begin
    var ID := MinorAttrEnumToId(Minor.MinorAttribute); // Defined in Game.Types
    W := GetWeightForAttribute(ID, Weights);
    if W > 0 then
    begin
      // Minor attributes are mostly percentages stored as e.g. 6.0
      // CalcEngine divides by 100.
      if Minor.MinorAttribute in [madHealth, madSkillTier] then // Health is typically flat
         Result := Result + Minor.Value * W // Flat addition
      else
         // Percentages
         Result := Result + (Minor.Value / 100.0) * W;
    end;
  end;

  // 3. Fixed Minor Attributes
  for var Fixed in Piece.FixedMinorAttributes do
  begin
     W := GetWeightForAttribute(Fixed.ID, Weights);
     if W > 0 then
     begin
       // Check if flat or pct.
       // Heuristic: if Value > 100, assume flat (like Health ~18000)
       // Exception: ArmorOnKill is sometimes % but small values? Usually %.
       if (Fixed.Value > 100) or SameText(Fixed.ID, 'health') or SameText(Fixed.ID, 'armor') then
         Result := Result + Fixed.Value * W
       else
         Result := Result + (Fixed.Value / 100.0) * W;
     end;
  end;

  // 4. Mod Attribute - Omitted for speed, usually user selected later.
end;

function TBuildGenerator.CalculateSetBonusScore(const Bonus: TSetBonus;
  const Weights: TDictionary<string, Double>): Double;
var
  W: Double;
begin
  Result := 0;
  W := GetWeightForAttribute(Bonus.AttributeID, Weights);
  if W > 0 then
  begin
     // Bonus.Value is usually e.g. 10.0 for 10%
     // Divide by 100 for percentages
     if (Bonus.Value > 100) then // heuristic for flat
        Result := Result + Bonus.Value * W
     else
        Result := Result + (Bonus.Value / 100.0) * W;
  end;
end;


function TBuildGenerator.GenerateBuilds(const AArchetype: TBuildArchetype;
  const Weights: TDictionary<string, Double> = nil): TList<TGearLoadout>;
var
  Candidates: TList<TGearLoadout>;
  i, j: Integer;
  LBuild: TGearLoadout;
  TotalScore: Double;
  SetCounts: TDictionary<string, Integer>;
  SetName, CanonSetName: string;
  SetDef: TPieceSet;
  Count: Integer;
begin
  // 1. Generate Candidates
  Candidates := FRecommendationEngine.GenerateBuilds(AArchetype, Weights);

  if (Candidates = nil) or (Candidates.Count = 0) then
    Exit(Candidates);

  if (Weights = nil) or (Weights.Count = 0) then
    Exit(Candidates);

  SetCounts := TDictionary<string, Integer>.Create;
  try
    for i := 0 to Candidates.Count - 1 do
    begin
      LBuild := Candidates[i];
      TotalScore := 0;
      SetCounts.Clear;

      // Score Pieces and Count Sets
      for j := 0 to High(LBuild.GearPieces) do
      begin
        if LBuild.GearPieces[j].Name <> '' then
        begin
          // Add piece score
          TotalScore := TotalScore + CalculatePieceScore(LBuild.GearPieces[j], Weights);

          // Track set counts
          SetName := LBuild.GearPieces[j].SetName;
          if SetName <> '' then
          begin
            CanonSetName := CalcEngine.CanonicalSetName(SetName);
            if not SetCounts.TryGetValue(CanonSetName, Count) then
              Count := 0;
            SetCounts.AddOrSetValue(CanonSetName, Count + 1);
          end;
        end;
      end;

      // Score Set Bonuses
      for SetName in SetCounts.Keys do
      begin
        Count := SetCounts[SetName];
        if (Count > 0) and FDataIterator.AllPieceSetDefinitions.TryGetValue(SetName, SetDef) then
        begin
           if (SetDef.SetType = stNamedSet) then
           begin
              // DataJsonIterator maps named items to parent brands usually,
              // so SetDef might already be correct if loaded correctly.
              // Assuming standard brand behavior for now.
           end;

           for var Bonus in SetDef.Bonuses do
           begin
             if Count >= Bonus.ItemsRequired then
             begin
               TotalScore := TotalScore + CalculateSetBonusScore(Bonus, Weights);
             end;
           end;
        end;
      end;

      LBuild.Score := TotalScore;
      Candidates[i] := LBuild;
    end;
  finally
    SetCounts.Free;
  end;

  // Sort by Score
  Candidates.Sort(TComparer<TGearLoadout>.Construct(
    function(const L, R: TGearLoadout): Integer
    begin
      if L.Score > R.Score then Result := -1
      else if L.Score < R.Score then Result := 1
      else Result := 0;
    end));

  Result := Candidates;
end;

end.
