unit MainController;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Classes,
  Game.Types, Game.JsonIterator, CalcEngine, LoadoutManager,
  System.TypInfo;

type
  TMainController = class
  private
    FData: TDataJsonIterator;
    FEquippedGearPieces: array[TItemType] of TGearPiece;
    FSelectedWeapon: array[TWeaponSlot] of TWeapon;
    FWeaponExpertiseLevels: array[TWeaponSlot] of Integer;
    FEquippedSkills: array[TSkillSlot] of TEquippedSkill;
    FSelectedSpecialization: TSpecialization;
    FActivatedSpecBonuses: TArray<TWeaponFamily>;

    // Internal State
    FExoticWeaponSelected: Boolean;
    FExoticWeaponSlot: TWeaponSlot;

    procedure InitializeState;
  public
    constructor Create(AData: TDataJsonIterator);
    destructor Destroy; override;

    // State Accessors
    function GetEquippedGearPiece(Slot: TItemType): TGearPiece;
    procedure SetEquippedGearPiece(Slot: TItemType; const Value: TGearPiece);

    function GetSelectedWeapon(Slot: TWeaponSlot): TWeapon;
    procedure SetSelectedWeapon(Slot: TWeaponSlot; const Value: TWeapon);

    function GetWeaponExpertise(Slot: TWeaponSlot): Integer;
    procedure SetWeaponExpertise(Slot: TWeaponSlot; Value: Integer);

    function GetEquippedSkill(Slot: TSkillSlot): TEquippedSkill;
    procedure SetEquippedSkill(Slot: TSkillSlot; const Value: TEquippedSkill);

    property SelectedSpecialization: TSpecialization read FSelectedSpecialization write FSelectedSpecialization;
    property ActivatedSpecBonuses: TArray<TWeaponFamily> read FActivatedSpecBonuses write FActivatedSpecBonuses;

    // Actions
    function CanEquipGearPiece(const AGearPiece: TGearPiece; CurrentSlot: TItemType): Boolean;
    function IsExoticGearEquipped: Boolean;
    procedure EquipGear(Slot: TItemType; const Piece: TGearPiece);
    procedure ResetAll;

    // Calculations
    function CalculateFullPerformance(
      out DamageResults: array[TWeaponSlot] of TFullDamageCalcResult;
      out AggregatedStats: TPlayerAggregatedStats
    ): Boolean;

    // Loadout Management
    function CreateSerializableLoadout(const Name: string): TSerializableLoadout;
    procedure ApplySerializableLoadout(const Loadout: TSerializableLoadout);
  end;

implementation

constructor TMainController.Create(AData: TDataJsonIterator);
begin
  inherited Create;
  FData := AData;
  InitializeState;
end;

destructor TMainController.Destroy;
begin
  inherited;
end;

procedure TMainController.InitializeState;
var
  Slot: TItemType;
  WSlot: TWeaponSlot;
  SSlot: TSkillSlot;
begin
  for Slot := Low(TItemType) to High(TItemType) do
    FEquippedGearPieces[Slot] := Default(TGearPiece);

  for WSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    FSelectedWeapon[WSlot] := Default(TWeapon);
    FWeaponExpertiseLevels[WSlot] := 0;
  end;

  for SSlot := Low(TSkillSlot) to High(TSkillSlot) do
    FEquippedSkills[SSlot] := Default(TEquippedSkill);

  FSelectedSpecialization := Default(TSpecialization);
  FExoticWeaponSelected := False;
  FExoticWeaponSlot := wsNone;
  SetLength(FActivatedSpecBonuses, 0);
end;

function TMainController.GetEquippedGearPiece(Slot: TItemType): TGearPiece;
begin
  Result := FEquippedGearPieces[Slot];
end;

procedure TMainController.SetEquippedGearPiece(Slot: TItemType; const Value: TGearPiece);
begin
  FEquippedGearPieces[Slot] := Value;
end;

function TMainController.GetSelectedWeapon(Slot: TWeaponSlot): TWeapon;
begin
  Result := FSelectedWeapon[Slot];
end;

procedure TMainController.SetSelectedWeapon(Slot: TWeaponSlot; const Value: TWeapon);
begin
  FSelectedWeapon[Slot] := Value;
end;

function TMainController.GetWeaponExpertise(Slot: TWeaponSlot): Integer;
begin
  Result := FWeaponExpertiseLevels[Slot];
end;

procedure TMainController.SetWeaponExpertise(Slot: TWeaponSlot; Value: Integer);
begin
  FWeaponExpertiseLevels[Slot] := Value;
end;

function TMainController.GetEquippedSkill(Slot: TSkillSlot): TEquippedSkill;
begin
  Result := FEquippedSkills[Slot];
end;

procedure TMainController.SetEquippedSkill(Slot: TSkillSlot; const Value: TEquippedSkill);
begin
  FEquippedSkills[Slot] := Value;
end;

function TMainController.IsExoticGearEquipped: Boolean;
var
  Slot: TItemType;
begin
  Result := False;
  for Slot := itMask to itKneepads do
  begin
    if FEquippedGearPieces[Slot].SetType = stExoticSet then
      Exit(True);
  end;
end;

function TMainController.CanEquipGearPiece(const AGearPiece: TGearPiece; CurrentSlot: TItemType): Boolean;
var
  CurrentlyEquippedExoticInThisSlot: Boolean;
begin
  Result := True;

  if (AGearPiece.SetType = stExoticSet) then
  begin
    CurrentlyEquippedExoticInThisSlot :=
      (CurrentSlot <> itUnknown) and
      (CurrentSlot in [itMask .. itKneepads]) and
      (FEquippedGearPieces[CurrentSlot].SetType = stExoticSet);

    if IsExoticGearEquipped and not CurrentlyEquippedExoticInThisSlot then
      Exit(False);
  end;
end;

procedure TMainController.EquipGear(Slot: TItemType; const Piece: TGearPiece);
begin
  if CanEquipGearPiece(Piece, Slot) then
    FEquippedGearPieces[Slot] := Piece;
end;

procedure TMainController.ResetAll;
begin
  InitializeState;
end;

function TMainController.CalculateFullPerformance(
  out DamageResults: array[TWeaponSlot] of TFullDamageCalcResult;
  out AggregatedStats: TPlayerAggregatedStats
): Boolean;
var
  LInput: TFullLoadoutInput;
  Slot: TItemType;
  WSlot: TWeaponSlot;
  SlotAggregatedStats: TLoadoutAggregatedStats_Display;
begin
  Result := False;
  if not Assigned(FData) then Exit;

  // Prepare Input
  FillChar(LInput, SizeOf(TFullLoadoutInput), 0);

  // 1. Gear
  LInput.TotalSkillTiers := 0;
  for Slot := itMask to itKneepads do
  begin
    if FEquippedGearPieces[Slot].Name <> '' then
    begin
      LInput.EquippedGear[Slot] := FEquippedGearPieces[Slot];
      if FEquippedGearPieces[Slot].CoreAttribute.AttrType = catSkillTier then
        Inc(LInput.TotalSkillTiers);
    end;
  end;

  // 2. Spec & Watch
  LInput.ChosenSpecialization := FSelectedSpecialization;
  LInput.ActivatedSpecWeaponTypeBonuses := FActivatedSpecBonuses;
  LInput.WatchBonuses := DefaultWatchBonuses;

  // 3. Calculate per weapon
  for WSlot := wsPrimary to wsSideArm do
  begin
    if FSelectedWeapon[WSlot].ID <> 0 then
    begin
      LInput.ActiveWeaponConfig := FSelectedWeapon[WSlot];
      LInput.WeaponExpertiseLevel := FWeaponExpertiseLevels[WSlot];

      CalcEngine.CalculateCompleteLoadoutPerformance(
        LInput,
        FData.AllPieceSetDefinitions,
        FData.WeaponStats,
        FData.Mods,
        FData.Talents,
        DamageResults[WSlot],
        SlotAggregatedStats // Temp, as we aggregate globally later
      );
    end;
  end;

  // 4. Global Stats
  AggregatedStats := CalcEngine.AggregatePlayerStats(LInput, FData.AllPieceSetDefinitions);
  Result := True;
end;

function TMainController.CreateSerializableLoadout(const Name: string): TSerializableLoadout;
var
  Slot: TItemType;
  WSlot: TWeaponSlot;
  SSlot: TSkillSlot;
  LGearPiece: TGearPiece;
  LWeapon: TWeapon;
  ModDef: TGearModDefinition;

  // Helpers from MainBuilds can be moved here or duplicated/adapted
begin
  Result := TSerializableLoadout.Create;
  Result.Name := Name;
  Result.SpecializationName := FSelectedSpecialization.Name;
  Result.ActivatedSpecBonuses := Copy(FActivatedSpecBonuses);

  // Skills
  for SSlot := Low(TSkillSlot) to High(TSkillSlot) do
  begin
    if FEquippedSkills[SSlot].SkillID <> '' then
    begin
      var SSkill: TSerializableSkill;
      SSkill.SkillID := FEquippedSkills[SSlot].SkillID;
      SSkill.VariantName := FEquippedSkills[SSlot].Variant.VariantName;
      Result.Skills.Add(SSlot, SSkill);
    end;
  end;

  // Gear
  for Slot := itMask to itKneepads do
  begin
    LGearPiece := FEquippedGearPieces[Slot];
    if LGearPiece.Name <> '' then
    begin
      var SGearPiece: TSerializableGearPiece;
      SGearPiece.PieceName := LGearPiece.Name;
      SGearPiece.SetName := LGearPiece.SetName;
      SGearPiece.SetTypeStr := GetEnumName(TypeInfo(TSetType), Ord(LGearPiece.SetType));

      SGearPiece.CoreAttributeTypeStr := GetEnumName(TypeInfo(TCoreAttributeType), Ord(LGearPiece.CoreAttribute.AttrType));
      SGearPiece.CoreAttributeValue := LGearPiece.CoreAttribute.Value;

      // Mod Logic
      if LGearPiece.ModID <> 0 then
        SGearPiece.ModID := LGearPiece.ModID
      else if (LGearPiece.ModAttribute.ModEffect <> gmetUnknown) and
              Assigned(FData.GearModsData) then
      begin
        // Reverse lookup mod ID if possible
        SGearPiece.ModID := 0;
        for var Pair in FData.GearModsData do
        begin
          if (Pair.Value.AttributeType = LGearPiece.ModAttribute.ModEffect) and
             SameValue(Pair.Value.AttributeValue, LGearPiece.ModAttribute.Value, 1E-6) then
          begin
            SGearPiece.ModID := Pair.Key;
            Break;
          end;
        end;
      end;

      SGearPiece.ModAttributeValue := LGearPiece.ModAttribute.Value;
      SGearPiece.ModAttributeTypeStr := GetEnumName(TypeInfo(TGearModEffectType), Ord(LGearPiece.ModAttribute.ModEffect));
      SGearPiece.TalentName := LGearPiece.Talent;

      // Minors
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

      SGearPiece.MinorIconIndices := LGearPiece.SelectedMinorIconIndices;
      SGearPiece.ModIconIndex := LGearPiece.SelectedModIconIndex;

      Result.GearPieces.Add(Slot, SGearPiece);
    end;
  end;

  // Weapons
  for WSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    LWeapon := FSelectedWeapon[WSlot];
    if LWeapon.ID <> 0 then
    begin
      var SWeapon := TSerializableWeapon.Create;
      SWeapon.WeaponID := LWeapon.ID;
      for var ModSlot := Low(TModSlot) to High(TModSlot) do
        if LWeapon.EquippedMods[ModSlot] <> 0 then
          SWeapon.EquippedModIDs.Add(ModSlot, LWeapon.EquippedMods[ModSlot]);

      SWeapon.SelectedTalentID := LWeapon.ChosenTalentID;
      SWeapon.SelectedMinorAttributeType := LWeapon.SelectedMinorAttributeType;
      SWeapon.ExpertiseLevel := FWeaponExpertiseLevels[WSlot];

      Result.Weapons.Add(WSlot, SWeapon);
    end;
  end;
end;

procedure TMainController.ApplySerializableLoadout(const Loadout: TSerializableLoadout);
var
  ItemType: TItemType;
  WSlot: TWeaponSlot;
  SSlot: TSkillSlot;
  LGearPiece: TGearPiece;
  LWeapon: TWeapon;
  Found: Boolean;
  ModDef: TGearModDefinition;
  FixedDef: TFixedMinorAttributeDefinition;

  // Helpers
  function CoreAttrIdFromEnum(const AType: TCoreAttributeType): string;
  begin
    case AType of
      catWeaponDamage: Result := 'weaponDamage';
      catArmor:        Result := 'armor';
      catSkillTier:    Result := 'skillTier';
    else Result := '';
    end;
  end;

  function MinorAttributeCategory(const Attr: TMinorAttributeType): TMinorAttributeCat;
  begin
    // Re-implement or reference Game.Types (if accessible)
    case Attr of
      madCriticalHitChance, madCriticalHitDamage, madHeadshotDamage, madWeaponHandling: Result := matOffensive;
      madSkillDamage, madSkillHaste, madStatusEffects, madRepairSkills: Result := matUtility;
      else Result := matDefensive;
    end;
  end;

begin
  ResetAll;

  // Spec
  if FData.Specializations.TryGetValue(Loadout.SpecializationName, FSelectedSpecialization) then
    FActivatedSpecBonuses := Copy(Loadout.ActivatedSpecBonuses);

  // Skills
  for SSlot in Loadout.Skills.Keys do
  begin
    var SSkill := Loadout.Skills[SSlot];
    var LSkillData: TSkillData;
    if FData.Skills.TryGetValue(SSkill.SkillID, LSkillData) then
    begin
      for var LVariant in LSkillData.Variants do
        if LVariant.VariantName = SSkill.VariantName then
        begin
          FEquippedSkills[SSlot].SkillID := SSkill.SkillID;
          FEquippedSkills[SSlot].Variant := LVariant;
          Break;
        end;
    end;
  end;

  // Gear
  for ItemType in Loadout.GearPieces.Keys do
  begin
    var SGearPiece := Loadout.GearPieces[ItemType];
    Found := False;

    // 1. Precise Lookup
    if (SGearPiece.SetName <> '') and Assigned(FData.AllPieceSetDefinitions) then
    begin
      var PS: TPieceSet;
      if FData.AllPieceSetDefinitions.TryGetValue(SGearPiece.SetName, PS) then
        for var Part in PS.Parts do
          if SameText(Part.Name, SGearPiece.PieceName) then
          begin
            // Reconstruct base piece
            LGearPiece := Default(TGearPiece);
            LGearPiece.Name := Part.Name;
            LGearPiece.SetName := PS.Name;
            LGearPiece.ItemType := Part.GearSlot;
            LGearPiece.CoreAttribute.ID := Part.CoreAttributeID;
            LGearPiece.CoreAttribute.AttrType := FData.CoreAttrIDToEnum(Part.CoreAttributeID);
            LGearPiece.SetType := PS.SetType;
            LGearPiece.Bonuses := PS.Bonuses;

            // Fixed Minors from Definition
            SetLength(LGearPiece.FixedMinorAttributes, 0);
            if Length(Part.FixedMinorAttributeIDs) > 0 then
              for var FixedId in Part.FixedMinorAttributeIDs do
                if FData.FixedMinorAttributeDefinitions.TryGetValue(FixedId, FixedDef) then
                begin
                  var Len := Length(LGearPiece.FixedMinorAttributes);
                  SetLength(LGearPiece.FixedMinorAttributes, Len + 1);
                  LGearPiece.FixedMinorAttributes[Len] := FixedDef;
                end;
            Found := True;
            Break;
          end;
    end;

    // 2. Global Lookup
    if not Found then
      Found := FData.FindFullGearPiece(SGearPiece.PieceName, LGearPiece);

    if Found then
    begin
      // Restore Attributes
      if SGearPiece.CoreAttributeTypeStr <> '' then
      begin
        try
          LGearPiece.CoreAttribute.AttrType := TCoreAttributeType(GetEnumValue(TypeInfo(TCoreAttributeType), SGearPiece.CoreAttributeTypeStr));
          LGearPiece.CoreAttribute.ID := CoreAttrIdFromEnum(LGearPiece.CoreAttribute.AttrType);
        except end;
      end;
      LGearPiece.CoreAttribute.Value := SGearPiece.CoreAttributeValue;

      // Minors
      SetLength(LGearPiece.MinorAttributes, Length(SGearPiece.MinorAttributeTypeStrs));
      for var ic := 0 to High(SGearPiece.MinorAttributeTypeStrs) do
      begin
        LGearPiece.MinorAttributes[ic].MinorAttribute := TMinorAttributeType(GetEnumValue(TypeInfo(TMinorAttributeType), SGearPiece.MinorAttributeTypeStrs[ic]));
        LGearPiece.MinorAttributes[ic].AttrType := MinorAttributeCategory(LGearPiece.MinorAttributes[ic].MinorAttribute);

        if (Length(SGearPiece.MinorAttributeValues) > ic) and (SGearPiece.MinorAttributeValues[ic] > 0) then
          LGearPiece.MinorAttributes[ic].Value := SGearPiece.MinorAttributeValues[ic]
        else
          LGearPiece.MinorAttributes[ic].Value := GetDefaultMinorAttributeValue(LGearPiece.MinorAttributes[ic].MinorAttribute);
      end;

      // Fixed Minors Override (if needed/saved)
      if Length(SGearPiece.FixedMinorAttributeIDs) > 0 then
      begin
        SetLength(LGearPiece.FixedMinorAttributes, 0);
        for var FixedId in SGearPiece.FixedMinorAttributeIDs do
          if FData.FixedMinorAttributeDefinitions.TryGetValue(FixedId, FixedDef) then
          begin
            var Len := Length(LGearPiece.FixedMinorAttributes);
            SetLength(LGearPiece.FixedMinorAttributes, Len + 1);
            LGearPiece.FixedMinorAttributes[Len] := FixedDef;
          end;
      end;

      // Mod
      if SGearPiece.ModID <> 0 then
      begin
        if FData.GearModsData.TryGetValue(SGearPiece.ModID, ModDef) then
        begin
          LGearPiece.ModAttribute.ModEffect := ModDef.AttributeType;
          LGearPiece.ModAttribute.Value := ModDef.AttributeValue;
          LGearPiece.ModID := SGearPiece.ModID;
        end;
      end
      else if SGearPiece.ModAttributeTypeStr <> '' then
      begin
        try
          LGearPiece.ModAttribute.ModEffect := TGearModEffectType(GetEnumValue(TypeInfo(TGearModEffectType), SGearPiece.ModAttributeTypeStr));
          LGearPiece.ModAttribute.Value := SGearPiece.ModAttributeValue;
        except end;
      end;

      LGearPiece.Talent := SGearPiece.TalentName;
      LGearPiece.SelectedMinorIconIndices := SGearPiece.MinorIconIndices;
      LGearPiece.SelectedModIconIndex := SGearPiece.ModIconIndex;

      FEquippedGearPieces[ItemType] := LGearPiece;
    end;
  end;

  // Weapons
  for WSlot in Loadout.Weapons.Keys do
  begin
    var SWeapon := Loadout.Weapons[WSlot];
    if FData.Weapons.TryGetValue(SWeapon.WeaponID, LWeapon) then
    begin
      FSelectedWeapon[WSlot] := LWeapon;
      FSelectedWeapon[WSlot].SelectedMinorAttributeType := SWeapon.SelectedMinorAttributeType;
      FSelectedWeapon[WSlot].ChosenTalentID := SWeapon.SelectedTalentID;
      FWeaponExpertiseLevels[WSlot] := SWeapon.ExpertiseLevel;

      for var ModSlot := Low(TModSlot) to High(TModSlot) do
        if SWeapon.EquippedModIDs.ContainsKey(ModSlot) then
          FSelectedWeapon[WSlot].EquippedMods[ModSlot] := SWeapon.EquippedModIDs[ModSlot];
    end;
  end;
end;

end.
