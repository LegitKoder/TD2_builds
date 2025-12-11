unit Controllers.MainController;

interface

uses
  System.SysUtils, System.Generics.Collections, System.TypInfo, Math,
  Game.Types, Game.JsonIterator, CalcEngine, LoadoutManager,
  System.Classes;

type
  TMainController = class
  private
    FDataIterator: TDataJsonIterator;
    FEquippedGearPieces: TArray<TGearPiece>;
    FSelectedWeapon: array[TWeaponSlot] of TWeapon;
    FWeaponExpertiseLevels: array[TWeaponSlot] of Integer;
    FWeaponSelectedTalentIDs: array[TWeaponSlot] of Integer;
    FSelectedSpecialization: TSpecialization;
    FSavedLoadouts: TObjectDictionary<string, TSerializableLoadout>;
    FEquippedSkills: array[TSkillSlot] of TEquippedSkill;

    // Helper to calculate and refresh stats
    function CalculateLoadoutPerformance(out DamageResult: TFullDamageCalcResult;
      out AggregatedStats: TLoadoutAggregatedStats_Display): Boolean;

  public
    constructor Create(ADataIterator: TDataJsonIterator);
    destructor Destroy; override;

    // Loadout Management
    procedure LoadLoadouts;
    procedure SaveLoadout(const AName: string);
    procedure DeleteLoadout(const AName: string);
    procedure ApplyLoadout(const AName: string);
    function GetCurrentLoadoutAsSerializable(const AName: string): TSerializableLoadout;

    // Gear Logic
    procedure EquipGearPiece(SlotIndex: Integer; const Piece: TGearPiece);
    function GetEquippedGearPiece(SlotIndex: Integer): TGearPiece;

    // Weapon Logic
    procedure EquipWeapon(Slot: TWeaponSlot; const Weapon: TWeapon; ExpertiseLevel, TalentID: Integer);
    function GetEquippedWeapon(Slot: TWeaponSlot): TWeapon;

    // Calculation
    procedure RefreshStats(
      const OnStatsCalculated: TProc<TFullDamageCalcResult, TLoadoutAggregatedStats_Display, TPlayerAggregatedStats>);

    property SavedLoadouts: TObjectDictionary<string, TSerializableLoadout> read FSavedLoadouts;
  end;

implementation

{ TMainController }

constructor TMainController.Create(ADataIterator: TDataJsonIterator);
begin
  FDataIterator := ADataIterator;
  SetLength(FEquippedGearPieces, 6);
  // Initialize defaults
  for var i := 0 to 5 do FEquippedGearPieces[i] := Default(TGearPiece);
  for var Slot := Low(TWeaponSlot) to High(TWeaponSlot) do FSelectedWeapon[Slot] := Default(TWeapon);

  FSavedLoadouts := TObjectDictionary<string, TSerializableLoadout>.Create([doOwnsValues]);
end;

destructor TMainController.Destroy;
begin
  FSavedLoadouts.Free;
  inherited;
end;

procedure TMainController.LoadLoadouts;
var
  Loaded: TDictionary<string, TSerializableLoadout>;
begin
  FSavedLoadouts.Clear;
  Loaded := TLoadoutManager.LoadLoadouts;
  if Loaded <> nil then
  begin
    for var Pair in Loaded do
      FSavedLoadouts.Add(Pair.Key, Pair.Value);
    // TLoadoutManager.LoadLoadouts returns a standard TDictionary.
    // We transferred ownership to FSavedLoadouts (TObjectDictionary).
    // So we should free the container but NOT the values from the source dictionary?
    // Wait, TLoadoutManager.LoadLoadouts creates TSerializableLoadout objects.
    // If we just .Add them to TObjectDictionary([doOwnsValues]), it takes ownership.
    // But Loaded (the source dictionary) still holds references.
    // We should free Loaded (the dictionary shell) but prevent it from freeing values if it owned them.
    // TLoadoutManager.LoadLoadouts returns TDictionary (not ObjectDictionary usually), so it doesn't own values by default.
    Loaded.Free;
  end;
end;

function TMainController.GetCurrentLoadoutAsSerializable(const AName: string): TSerializableLoadout;
var
  LGearPiece: TGearPiece;
  LWeapon: TWeapon;
  LItemType: TItemType;
  LWeaponSlot: TWeaponSlot;
  SGearPiece: TSerializableGearPiece;
  i: Integer;
begin
  Result := TSerializableLoadout.Create;
  Result.Name := AName;

  // Serialize Skills
  for var LSkillSlot: TSkillSlot := Low(TSkillSlot) to High(TSkillSlot) do
  begin
    if FEquippedSkills[LSkillSlot].SkillID <> '' then
    begin
      var SSkill: TSerializableSkill;
      SSkill.SkillID := FEquippedSkills[LSkillSlot].SkillID;
      SSkill.VariantName := FEquippedSkills[LSkillSlot].Variant.VariantName;
      Result.Skills.Add(LSkillSlot, SSkill);
    end;
  end;

  // Serialize Gear
  for i := 0 to High(FEquippedGearPieces) do
  begin
    LItemType := TItemType(i);
    LGearPiece := FEquippedGearPieces[i];
    if LGearPiece.Name <> '' then
    begin
      SGearPiece.SetName    := LGearPiece.SetName;
      SGearPiece.SetTypeStr := GetEnumName(TypeInfo(TSetType), Ord(LGearPiece.SetType));

      SGearPiece.PieceName := LGearPiece.Name;
      SGearPiece.CoreAttributeTypeStr := GetEnumName(TypeInfo(TCoreAttributeType), Ord(LGearPiece.CoreAttribute.AttrType));
      SGearPiece.CoreAttributeValue := LGearPiece.CoreAttribute.Value;
      if LGearPiece.ModID <> 0 then
        SGearPiece.ModID := LGearPiece.ModID
      else if (LGearPiece.ModAttribute.ModEffect <> gmetUnknown) and
        Assigned(FDataIterator) and Assigned(FDataIterator.GearModsData) then
      begin
        SGearPiece.ModID := 0;
        for var Pair in FDataIterator.GearModsData do
        begin
          if (Pair.Value.AttributeType = LGearPiece.ModAttribute.ModEffect) and
             SameValue(Pair.Value.AttributeValue, LGearPiece.ModAttribute.Value, 1E-6) then
          begin
            SGearPiece.ModID := Pair.Key;
            Break;
          end;
        end;
      end
      else
        SGearPiece.ModID := 0;
      SGearPiece.ModAttributeValue := LGearPiece.ModAttribute.Value;
      SGearPiece.ModAttributeTypeStr := GetEnumName(TypeInfo(TGearModEffectType), Ord(LGearPiece.ModAttribute.ModEffect));
      SGearPiece.TalentName := LGearPiece.Talent;

      SetLength(SGearPiece.MinorAttributeTypeStrs, Length(LGearPiece.MinorAttributes));
      SetLength(SGearPiece.MinorAttributeValues, Length(LGearPiece.MinorAttributes));
      for var j := 0 to High(LGearPiece.MinorAttributes) do
      begin
        SGearPiece.MinorAttributeTypeStrs[j] := GetEnumName(TypeInfo(TMinorAttributeType), Ord(LGearPiece.MinorAttributes[j].MinorAttribute));
        SGearPiece.MinorAttributeValues[j] := LGearPiece.MinorAttributes[j].Value;
      end;
      SetLength(SGearPiece.FixedMinorAttributeIDs, Length(LGearPiece.FixedMinorAttributes));
      for var j := 0 to High(LGearPiece.FixedMinorAttributes) do
        SGearPiece.FixedMinorAttributeIDs[j] := LGearPiece.FixedMinorAttributes[j].ID;

      // New fields for icon indices
      SGearPiece.MinorIconIndices := LGearPiece.SelectedMinorIconIndices;
      SGearPiece.ModIconIndex := LGearPiece.SelectedModIconIndex;
      Result.GearPieces.Add(LItemType, SGearPiece);
    end;
  end;

  // Serialize Weapons
  for LWeaponSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    LWeapon := FSelectedWeapon[LWeaponSlot];
    if LWeapon.ID <> 0 then
    begin
      var SWeapon := TSerializableWeapon.Create;
      SWeapon.WeaponID := LWeapon.ID;

      // Les mods équipés
      for var ModSlot := Low(TModSlot) to High(TModSlot) do
        if LWeapon.EquippedMods[ModSlot] <> 0 then
          SWeapon.EquippedModIDs.Add(ModSlot, LWeapon.EquippedMods[ModSlot]);

      SWeapon.SelectedTalentID := LWeapon.ChosenTalentID;
      SWeapon.SelectedMinorAttributeType := LWeapon.SelectedMinorAttributeType;
      SWeapon.ExpertiseLevel := FWeaponExpertiseLevels[LWeaponSlot];

      Result.Weapons.Add(LWeaponSlot, SWeapon);
    end;
  end;

  // Serialize Specialization
  if Assigned(FSelectedSpecialization) then
     Result.SpecializationName := FSelectedSpecialization.Name
  else
     Result.SpecializationName := '';

  SetLength(Result.ActivatedSpecBonuses, 0);
end;

procedure TMainController.SaveLoadout(const AName: string);
var
  LLoadout: TSerializableLoadout;
begin
  LLoadout := GetCurrentLoadoutAsSerializable(AName);

  // If exists, remove (will trigger free due to TObjectDictionary ownership if we remove?
  // No, Remove frees the value if doOwnsValues is set.
  if FSavedLoadouts.ContainsKey(AName) then
    FSavedLoadouts.Remove(AName);

  FSavedLoadouts.Add(AName, LLoadout);

  // Convert to TDictionary for saving to ensure type compatibility with TLoadoutManager signature
  // or TLoadoutManager needs update.
  // Assuming TLoadoutManager.SaveLoadouts takes TDictionary<string, TSerializableLoadout>.
  // TObjectDictionary inherits from TDictionary, so this should be fine.
  TLoadoutManager.SaveLoadouts(FSavedLoadouts);
end;

procedure TMainController.DeleteLoadout(const AName: string);
begin
  if FSavedLoadouts.ContainsKey(AName) then
  begin
    FSavedLoadouts.Remove(AName); // Frees object
    TLoadoutManager.SaveLoadouts(FSavedLoadouts);
  end;
end;

procedure TMainController.ApplyLoadout(const AName: string);
var
  LLoadout: TSerializableLoadout;
  LGearPiece: TGearPiece;
  LWeapon: TWeapon;
  LItemType: TItemType;
  LWeaponSlot: TWeaponSlot;
  ModDef: TGearModDefinition;
  ModID: Integer;
  FixedDef: TFixedMinorAttributeDefinition;

  function CoreAttrIdFromEnum(const AType: TCoreAttributeType): string;
  begin
    case AType of
      catWeaponDamage: Result := 'weaponDamage';
      catArmor:        Result := 'armor';
      catSkillTier:    Result := 'skillTier';
    else
      Result := '';
    end;
  end;

  function CoreAttrDisplayName(const AttrID: string): string;
  var
    CoreDef: TCoreAttributeDefinition;
  begin
    Result := '';
    if Assigned(FDataIterator) and
       Assigned(FDataIterator.CoreAttributeDefinitions) and
       FDataIterator.CoreAttributeDefinitions.TryGetValue(AttrID, CoreDef) then
      Exit(CoreDef.TypeName);

    if SameText(AttrID, 'weaponDamage') then Result := 'Weapon Damage'
    else if SameText(AttrID, 'armor') then Result := 'Armor'
    else if SameText(AttrID, 'skillTier') then Result := 'Skill Tier';
  end;

begin
  if not FSavedLoadouts.TryGetValue(AName, LLoadout) then
    Exit;

  // Clear current
  for var il := 0 to High(FEquippedGearPieces) do
    FEquippedGearPieces[il] := Default(TGearPiece);
  for var ws := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    FSelectedWeapon[ws] := Default(TWeapon);
    FWeaponSelectedTalentIDs[ws] := 0;
  end;

  // Apply Gear
  for LItemType in LLoadout.GearPieces.Keys do
  begin
    var SGearPiece := LLoadout.GearPieces[LItemType];
    var Found := False;

    // 1) Prefer set + name
    if (SGearPiece.SetName <> '') and Assigned(FDataIterator)
       and Assigned(FDataIterator.AllPieceSetDefinitions) then
    begin
      var PS: TPieceSet;
      if FDataIterator.AllPieceSetDefinitions.TryGetValue(SGearPiece.SetName, PS) then
        for var Part in PS.Parts do
          if SameText(Part.Name, SGearPiece.PieceName) then
          begin
            LGearPiece := Default(TGearPiece);
            LGearPiece.Name := Part.Name;
            LGearPiece.SetName := PS.Name;
            LGearPiece.ItemType := Part.GearSlot;
            LGearPiece.CoreAttribute.ID := Part.CoreAttributeID;
            LGearPiece.CoreAttribute.AttrType := FDataIterator.CoreAttrIDToEnum(Part.CoreAttributeID);
            LGearPiece.SetType := PS.SetType;
            LGearPiece.Bonuses := PS.Bonuses;
            SetLength(LGearPiece.FixedMinorAttributes, 0);
            if (Length(Part.FixedMinorAttributeIDs) > 0) and
               Assigned(FDataIterator) and
               Assigned(FDataIterator.FixedMinorAttributeDefinitions) then
            begin
              for var FixedId in Part.FixedMinorAttributeIDs do
                if FDataIterator.FixedMinorAttributeDefinitions.TryGetValue(FixedId, FixedDef) then
                begin
                  var Len := Length(LGearPiece.FixedMinorAttributes);
                  SetLength(LGearPiece.FixedMinorAttributes, Len + 1);
                  LGearPiece.FixedMinorAttributes[Len] := FixedDef;
                end;
            end;
            Found := True;
            Break;
          end;
    end;

    // 2) Fallback: global by name
    if not Found then
      Found := FDataIterator.FindFullGearPiece(SGearPiece.PieceName, LGearPiece);

    if not Found then
    begin
      FEquippedGearPieces[Ord(LItemType)] := Default(TGearPiece);
      Continue;
    end;

    // Restore custom values
    if SGearPiece.CoreAttributeTypeStr <> '' then
    begin
      try
        var OrdValue := GetEnumValue(TypeInfo(TCoreAttributeType), SGearPiece.CoreAttributeTypeStr);
        if OrdValue >= 0 then
        begin
          LGearPiece.CoreAttribute.AttrType := TCoreAttributeType(OrdValue);
          LGearPiece.CoreAttribute.ID := CoreAttrIdFromEnum(LGearPiece.CoreAttribute.AttrType);
          if LGearPiece.CoreAttribute.ID <> '' then
            LGearPiece.CoreAttribute.TypeName := CoreAttrDisplayName(LGearPiece.CoreAttribute.ID);
        end;
      except
      end;
    end;

    LGearPiece.CoreAttribute.Value := SGearPiece.CoreAttributeValue;

    SetLength(LGearPiece.MinorAttributes, Length(SGearPiece.MinorAttributeTypeStrs));
    for var ic := 0 to High(SGearPiece.MinorAttributeTypeStrs) do
    begin
      LGearPiece.MinorAttributes[ic].MinorAttribute :=
        TMinorAttributeType(GetEnumValue(
          TypeInfo(TMinorAttributeType),
          SGearPiece.MinorAttributeTypeStrs[ic]
        ));
      LGearPiece.MinorAttributes[ic].AttrType :=
        MinorAttributeCategory(LGearPiece.MinorAttributes[ic].MinorAttribute);

      if (Length(SGearPiece.MinorAttributeValues) > ic)
         and (SGearPiece.MinorAttributeValues[ic] > 0) then
        LGearPiece.MinorAttributes[ic].Value := SGearPiece.MinorAttributeValues[ic]
      else
        LGearPiece.MinorAttributes[ic].Value := GetDefaultMinorAttributeValue(LGearPiece.MinorAttributes[ic].MinorAttribute);
    end;

    // Mods
    if SGearPiece.ModID <> 0 then
    begin
      if (FDataIterator.GearModsData <> nil) and
         FDataIterator.GearModsData.TryGetValue(SGearPiece.ModID, ModDef) then
      begin
        LGearPiece.ModAttribute.ModEffect := ModDef.AttributeType;
        LGearPiece.ModAttribute.Value := ModDef.AttributeValue;
        LGearPiece.ModID := SGearPiece.ModID;
      end
      else
      begin
        LGearPiece.ModAttribute.ModEffect := gmetUnknown;
        LGearPiece.ModAttribute.Value := 0;
        LGearPiece.ModID := 0;
      end;
    end
    else if (SGearPiece.ModAttributeTypeStr <> '') and (SGearPiece.ModAttributeValue > 0) then
    begin
      try
        LGearPiece.ModAttribute.ModEffect := TGearModEffectType(GetEnumValue(TypeInfo(TGearModEffectType), SGearPiece.ModAttributeTypeStr));
      except
        LGearPiece.ModAttribute.ModEffect := gmetUnknown;
      end;
      LGearPiece.ModAttribute.Value := SGearPiece.ModAttributeValue;
      LGearPiece.ModID := 0;
    end;

    LGearPiece.Talent := SGearPiece.TalentName;
    LGearPiece.SelectedMinorIconIndices := SGearPiece.MinorIconIndices;
    LGearPiece.SelectedModIconIndex := SGearPiece.ModIconIndex;

    FEquippedGearPieces[Ord(LItemType)] := LGearPiece;
  end;

  // Apply Weapons
  for LWeaponSlot in LLoadout.Weapons.Keys do
  begin
    var SWeapon := LLoadout.Weapons[LWeaponSlot];
    if FDataIterator.Weapons.TryGetValue(SWeapon.WeaponID, LWeapon) then
    begin
      FSelectedWeapon[LWeaponSlot] := LWeapon;
      FSelectedWeapon[LWeaponSlot].SelectedMinorAttributeType := SWeapon.SelectedMinorAttributeType;
      FSelectedWeapon[LWeaponSlot].ChosenTalentID := SWeapon.SelectedTalentID;
      FWeaponSelectedTalentIDs[LWeaponSlot] := SWeapon.SelectedTalentID;
      FWeaponExpertiseLevels[LWeaponSlot] := SWeapon.ExpertiseLevel;
      for var ModSlot := Low(TModSlot) to High(TModSlot) do
      begin
        if Assigned(SWeapon.EquippedModIDs) and SWeapon.EquippedModIDs.TryGetValue(ModSlot, ModID) then
          FSelectedWeapon[LWeaponSlot].EquippedMods[ModSlot] := ModID
        else
          FSelectedWeapon[LWeaponSlot].EquippedMods[ModSlot] := 0;
      end;
    end;
  end;

  // Specialization
  if (LLoadout.SpecializationName <> '') and
     FDataIterator.Specializations.TryGetValue(LLoadout.SpecializationName, FSelectedSpecialization) then
  begin
     // Spec loaded
  end;
end;

procedure TMainController.EquipGearPiece(SlotIndex: Integer; const Piece: TGearPiece);
begin
  if (SlotIndex >= Low(FEquippedGearPieces)) and (SlotIndex <= High(FEquippedGearPieces)) then
    FEquippedGearPieces[SlotIndex] := Piece;
end;

function TMainController.GetEquippedGearPiece(SlotIndex: Integer): TGearPiece;
begin
  if (SlotIndex >= Low(FEquippedGearPieces)) and (SlotIndex <= High(FEquippedGearPieces)) then
    Result := FEquippedGearPieces[SlotIndex]
  else
    Result := Default(TGearPiece);
end;

procedure TMainController.EquipWeapon(Slot: TWeaponSlot; const Weapon: TWeapon; ExpertiseLevel, TalentID: Integer);
begin
  FSelectedWeapon[Slot] := Weapon;
  FWeaponExpertiseLevels[Slot] := ExpertiseLevel;
  FWeaponSelectedTalentIDs[Slot] := TalentID;
  // Also update weapon's internal chosen talent ID if needed for CalcEngine
  FSelectedWeapon[Slot].ChosenTalentID := TalentID;
end;

function TMainController.GetEquippedWeapon(Slot: TWeaponSlot): TWeapon;
begin
  Result := FSelectedWeapon[Slot];
end;

function TMainController.CalculateLoadoutPerformance(out DamageResult: TFullDamageCalcResult;
  out AggregatedStats: TLoadoutAggregatedStats_Display): Boolean;
var
  Input: TFullLoadoutInput;
  i: Integer;
begin
  FillChar(Input, SizeOf(Input), 0);

  // Fill Input from Controller State
  for i := 0 to High(FEquippedGearPieces) do
    if FEquippedGearPieces[i].Name <> '' then
      Input.EquippedGear[TItemType(i)] := FEquippedGearPieces[i];

  Input.ActiveWeaponConfig := FSelectedWeapon[wsPrimary]; // Default to primary for general stat view
  if Input.ActiveWeaponConfig.ID = 0 then
     Input.ActiveWeaponConfig := FSelectedWeapon[wsSecondary];

  Input.ChosenSpecialization := FSelectedSpecialization;
  // ... fill other inputs ...

  Result := CalcEngine.CalculateCompleteLoadoutPerformance(
    Input,
    FDataIterator.AllPieceSetDefinitions,
    FDataIterator.WeaponStats,
    FDataIterator.Mods,
    FDataIterator.Talents,
    DamageResult,
    AggregatedStats
  );
end;

procedure TMainController.RefreshStats(const OnStatsCalculated: TProc<TFullDamageCalcResult, TLoadoutAggregatedStats_Display, TPlayerAggregatedStats>);
var
  DamageResult: TFullDamageCalcResult;
  AggregatedStats: TLoadoutAggregatedStats_Display;
  PlayerStats: TPlayerAggregatedStats;
  Input: TFullLoadoutInput;
begin
  // Prepare Input (simplified)
  FillChar(Input, SizeOf(Input), 0);
  for var i := 0 to High(FEquippedGearPieces) do
    if FEquippedGearPieces[i].Name <> '' then
      Input.EquippedGear[TItemType(i)] := FEquippedGearPieces[i];

  if CalculateLoadoutPerformance(DamageResult, AggregatedStats) then
  begin
    PlayerStats := CalcEngine.AggregatePlayerStats(Input, FDataIterator.AllPieceSetDefinitions);
    if Assigned(OnStatsCalculated) then
      OnStatsCalculated(DamageResult, AggregatedStats, PlayerStats);
  end;
end;

end.
