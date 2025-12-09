unit LoadoutManager;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.JSON.Types, System.JSON.Writers, System.JSON.Builders,
  System.JSON.Readers, Game.Types, System.TypInfo;

type
  TLoadoutManager = class
  private
    class function GetSaveFileName: string; static;
  public
    class procedure SaveLoadouts(const ALoadouts
      : TDictionary<string, TSerializableLoadout>); static;
    class function LoadLoadouts
      : TDictionary<string, TSerializableLoadout>; static;
  end;

implementation

uses
  System.IOUtils, System.Rtti;

class function TLoadoutManager.GetSaveFileName: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'TD2Loadouts.json');
end;

class procedure TLoadoutManager.SaveLoadouts(const ALoadouts
  : TDictionary<string, TSerializableLoadout>);
var
  SW: TStringWriter;
  JW: TJsonTextWriter;
  JB: TJSONObjectBuilder;
  RootObj: TJSONCollectionBuilder.TPairs;
  LoadoutsArr: TJSONCollectionBuilder.TElements;
  LoadoutObj: TJSONCollectionBuilder.TPairs;
  WeapObj, GearObj, SkillsObj: TJSONCollectionBuilder.TPairs;
  Loadout: TSerializableLoadout;
  ItemType: TItemType;
  Slot: TWeaponSlot;
  LSkillSlot: TSkillSlot;
  ModSlot: TModSlot;
  Bonus: TWeaponFamily;
  FileName: string;
begin
  // 1) Wire up the writer chain
  SW := TStringWriter.Create;
  JW := TJsonTextWriter.Create(SW);
  try
    // 2) Build JSON
    JB := TJSONObjectBuilder.Create(JW);
    try
      // Start the root object and immediately open "Loadouts":[
      RootObj := JB.BeginObject;
      LoadoutsArr := RootObj.BeginArray('Loadouts');

  var ALoadoutsValues := ALoadouts.Values.ToArray;
  for var I := 0 to High(ALoadoutsValues) do
      begin
    Loadout := ALoadoutsValues[I];
        // Begin one loadout object
        LoadoutObj := LoadoutsArr.BeginObject;

        // Name
        LoadoutObj.Add('Name', Loadout.Name);

        // GearPieces { . }
        GearObj := LoadoutObj.BeginObject('GearPieces');
    var LoadoutGearPiecesKeys := Loadout.GearPieces.Keys.ToArray;
    for var J := 0 to High(LoadoutGearPiecesKeys) do
        begin
      ItemType := LoadoutGearPiecesKeys[J];
          var
          GP := Loadout.GearPieces[ItemType];
          var
          GearPieceObj := GearObj.BeginObject(GetEnumName(TypeInfo(TItemType), Ord(ItemType)));
          GearPieceObj.Add('PieceName', GP.PieceName);
          GearPieceObj.Add('CoreAttributeTypeStr', GP.CoreAttributeTypeStr);
          GearPieceObj.Add('ModID', GP.ModID);
          GearPieceObj.Add('TalentName', GP.TalentName);

          var
          MinorArr := GearPieceObj.BeginArray('MinorAttributeTypeStrs');
      for var K := 0 to High(GP.MinorAttributeTypeStrs) do
      begin
        var s := GP.MinorAttributeTypeStrs[K];
            MinorArr.Add(s);
      end;
          MinorArr.EndArray;

          var
          MinorValArr := GearPieceObj.BeginArray('MinorAttributeValues');
          for var K := 0 to High(GP.MinorAttributeValues) do
          begin
            MinorValArr.Add(GP.MinorAttributeValues[K]);
          end;
          MinorValArr.EndArray;

          var
          FixedArr := GearPieceObj.BeginArray('FixedMinorAttributeIDs');
          for var FixedId in GP.FixedMinorAttributeIDs do
            FixedArr.Add(FixedId);
          FixedArr.EndArray;

          GearPieceObj.Add('ModIconIndex', GP.ModIconIndex);
          GearPieceObj.Add('ModAttributeValue', GP.ModAttributeValue);
          GearPieceObj.Add('ModAttributeTypeStr', GP.ModAttributeTypeStr);

          var
          IconArr := GearPieceObj.BeginArray('MinorIconIndices');
      for var K := 0 to High(GP.MinorIconIndices) do
      begin
        var LIconIndex := GP.MinorIconIndices[K];
            IconArr.Add(LIconIndex);
      end;
          IconArr.EndArray;

          GearPieceObj.EndObject;
        end;
        GearObj.EndObject; // close GearPieces

        // Weapons { . }
        WeapObj := LoadoutObj.BeginObject('Weapons');
    var LoadoutWeaponsKeys := Loadout.Weapons.Keys.ToArray;
    for var J := 0 to High(LoadoutWeaponsKeys) do
        begin
      Slot := LoadoutWeaponsKeys[J];
          var
          WP := Loadout.Weapons[Slot];
          var
          WeaponObj := WeapObj.BeginObject(GetEnumName(TypeInfo(TWeaponSlot), Ord(Slot)));
          WeaponObj.Add('WeaponID', WP.WeaponID);
          WeaponObj.Add('SelectedTalentID', WP.SelectedTalentID);
          WeaponObj.Add('SelectedMinorAttributeType', WP.SelectedMinorAttributeType);
          WeaponObj.Add('ExpertiseLevel', WP.ExpertiseLevel);

          var
          EquippedModsObj := WeaponObj.BeginObject('EquippedModIDs');
      var WPEquippedModIDsKeys := WP.EquippedModIDs.Keys.ToArray;
      for var K := 0 to High(WPEquippedModIDsKeys) do
      begin
        ModSlot := WPEquippedModIDsKeys[K];
            EquippedModsObj.Add(GetEnumName(TypeInfo(TModSlot), Ord(ModSlot)),
              WP.EquippedModIDs[ModSlot]);
      end;
          EquippedModsObj.EndObject; // close EquippedModIDs

          WeaponObj.EndObject; // close this weapon
        end;
        WeapObj.EndObject; // close Weapons

        // Skills { … }
        SkillsObj := LoadoutObj.BeginObject('Skills');
    var LoadoutSkillsKeys := Loadout.Skills.Keys.ToArray;
    for var J := 0 to High(LoadoutSkillsKeys) do
        begin
      LSkillSlot := LoadoutSkillsKeys[J];
          var
          LSkill := Loadout.Skills[LSkillSlot];
          SkillsObj.BeginObject(GetEnumName(TypeInfo(TSkillSlot),
            Ord(LSkillSlot))).Add('SkillID', LSkill.SkillID)
            .Add('VariantName', LSkill.VariantName).EndObject;

          // EquippedModIDs { key: TSkillModSlot -> string }
          // SModsObj := SObj.BeginObject('EquippedModIDs');
          // for SMod in SK.EquippedModIDs.Keys do
          // SModsObj.Add(
          // GetEnumName(TypeInfo(TSkillModSlot), Ord(SMod)),
          // SK.EquippedModIDs[SMod]
          // );
          // SModsObj.EndObject;
          //
          // SObj.EndObject;
        end;
        SkillsObj.EndObject;

        // Spec name + bonus array
        LoadoutObj.Add('SpecializationName', Loadout.SpecializationName);

        var
        BonusArr := LoadoutObj.BeginArray('ActivatedSpecBonuses');
    for var J := 0 to High(Loadout.ActivatedSpecBonuses) do
    begin
      Bonus := Loadout.ActivatedSpecBonuses[J];
          BonusArr.Add(GetEnumName(TypeInfo(TWeaponFamily), Ord(Bonus)));
    end;
        BonusArr.EndArray;

        LoadoutObj.EndObject; // end one Loadout
      end;

      // Close the JSON
      LoadoutsArr.EndArray; // end Loadouts
      RootObj.EndObject; // end root

      JW.Flush;
    finally
      JB.Free;
    end;

    // 3) Persist to disk
    FileName := GetSaveFileName;
    TFile.WriteAllText(FileName, SW.ToString, TEncoding.UTF8);
  finally
    JW.Free;
    SW.Free;
  end;
end;

class function TLoadoutManager.LoadLoadouts
  : TDictionary<string, TSerializableLoadout>;
var
  LFileName: string;
  LJsonText: string;
  LReader: TJsonTextReader;
  LIterator: TJsonIterator;
  LLoadout: TSerializableLoadout;
  LGearPiece: TSerializableGearPiece;
  LWeapon: TSerializableWeapon;
  LItemType: TItemType;
  LWeaponSlot: TWeaponSlot;
  LModSlot: TModSlot;
  LBonus: TWeaponFamily;
  I: Integer;
begin
  Result := TDictionary<string, TSerializableLoadout>.Create;
  LFileName := GetSaveFileName;

  if not TFile.Exists(LFileName) then
    Exit;

  LJsonText := TFile.ReadAllText(LFileName);
  if LJsonText.IsEmpty then
    Exit;

  LReader := TJsonTextReader.Create(TStringReader.Create(LJsonText));
  try
    LIterator := TJsonIterator.Create(LReader);
    try
      while LIterator.Next do
      begin
        if (LIterator.Key = 'Loadouts') and
          (LIterator.&Type = TJsonToken.StartArray) then
        begin
          LIterator.Recurse;
          while LIterator.Next and (LIterator.&Type <> TJsonToken.EndArray) do
          begin
            if LIterator.&Type = TJsonToken.StartObject then
            begin
              LLoadout := Default (TSerializableLoadout);
              LLoadout.GearPieces :=
                TDictionary<TItemType, TSerializableGearPiece>.Create;
              LLoadout.Weapons :=
                TDictionary<TWeaponSlot, TSerializableWeapon>.Create;
              LLoadout.Skills :=
                TDictionary<TSkillSlot, TSerializableSkill>.Create;
              SetLength(LLoadout.ActivatedSpecBonuses, 0);

              LIterator.Recurse;
              while LIterator.Next and
                (LIterator.&Type <> TJsonToken.EndObject) do
              begin
                if SameText(LIterator.Key, 'Name') then
                  LLoadout.Name := LIterator.AsString
                else if SameText(LIterator.Key, 'SpecializationName') then
                  LLoadout.SpecializationName := LIterator.AsString
                else if (SameText(LIterator.Key, 'Skills')) and
                  (LIterator.&Type = TJsonToken.StartObject) then
                begin
                  LIterator.Recurse;
                  while LIterator.Next and
                    (LIterator.&Type <> TJsonToken.EndObject) do
                  begin
                    var
                    LSkillSlot :=
                      TSkillSlot(GetEnumValue(TypeInfo(TSkillSlot),
                      LIterator.Key));
                    var
                    LSkill := Default (TSerializableSkill);
                    LIterator.Recurse;
                    while LIterator.Next and
                      (LIterator.&Type <> TJsonToken.EndObject) do
                    begin
                      if SameText(LIterator.Key, 'SkillID') then
                        LSkill.SkillID := LIterator.AsString
                      else if SameText(LIterator.Key, 'VariantName') then
                        LSkill.VariantName := LIterator.AsString;
                    end;
                    LIterator.Return;
                    LLoadout.Skills.Add(LSkillSlot, LSkill);
                  end;
                  LIterator.Return;
                end
                else if (SameText(LIterator.Key, 'GearPieces')) and
                  (LIterator.&Type = TJsonToken.StartObject) then
                begin
                  LIterator.Recurse;
                  while LIterator.Next and
                    (LIterator.&Type <> TJsonToken.EndObject) do
                  begin
                    LItemType :=
                      TItemType(GetEnumValue(TypeInfo(TItemType),
                      LIterator.Key));
                    LGearPiece := Default (TSerializableGearPiece);
                    LIterator.Recurse;
                    while LIterator.Next and
                      (LIterator.&Type <> TJsonToken.EndObject) do
                    begin
                      if SameText(LIterator.Key, 'PieceName') then
                        LGearPiece.PieceName := LIterator.AsString
                      else if SameText(LIterator.Key, 'CoreAttributeTypeStr')
                      then
                        LGearPiece.CoreAttributeTypeStr := LIterator.AsString
                      else if SameText(LIterator.Key, 'ModID') then
                        LGearPiece.ModID := LIterator.AsInteger
                      else if SameText(LIterator.Key, 'TalentName') then
                        LGearPiece.TalentName := LIterator.AsString
                      else if (SameText(LIterator.Key, 'MinorAttributeTypeStrs')
                        ) and (LIterator.&Type = TJsonToken.StartArray) then
                      begin
                        SetLength(LGearPiece.MinorAttributeTypeStrs, 0);
                        LIterator.Recurse;
                        while LIterator.Next and
                          (LIterator.&Type <> TJsonToken.EndArray) do
                          LGearPiece.MinorAttributeTypeStrs :=
                            LGearPiece.MinorAttributeTypeStrs +
                            [LIterator.AsString];
                        LIterator.Return;
                      end
                      else if (SameText(LIterator.Key, 'MinorAttributeValues')) and
                        (LIterator.&Type = TJsonToken.StartArray) then
                      begin
                        SetLength(LGearPiece.MinorAttributeValues, 0);
                        LIterator.Recurse;
                        while LIterator.Next and
                          (LIterator.&Type <> TJsonToken.EndArray) do
                          LGearPiece.MinorAttributeValues :=
                            LGearPiece.MinorAttributeValues +
                            [LIterator.AsDouble];
                        LIterator.Return;
                      end
                      else if (SameText(LIterator.Key, 'FixedMinorAttributeIDs')) and
                        (LIterator.&Type = TJsonToken.StartArray) then
                      begin
                        SetLength(LGearPiece.FixedMinorAttributeIDs, 0);
                        LIterator.Recurse;
                        while LIterator.Next and
                          (LIterator.&Type <> TJsonToken.EndArray) do
                          LGearPiece.FixedMinorAttributeIDs :=
                            LGearPiece.FixedMinorAttributeIDs + [LIterator.AsString];
                        LIterator.Return;
                      end
                      else if SameText(LIterator.Key, 'ModIconIndex') then LGearPiece.ModIconIndex := LIterator.AsInteger
                      else if SameText(LIterator.Key, 'ModAttributeValue') then LGearPiece.ModAttributeValue := LIterator.AsDouble
                      else if SameText(LIterator.Key, 'ModAttributeTypeStr') then LGearPiece.ModAttributeTypeStr := LIterator.AsString
                      else if (SameText(LIterator.Key, 'MinorIconIndices')) and (LIterator.&Type = TJsonToken.StartArray) then
                      begin
                         SetLength(LGearPiece.MinorIconIndices, 0);
                         LIterator.Recurse;
                         while LIterator.Next and (LIterator.&Type <> TJsonToken.EndArray) do
                             LGearPiece.MinorIconIndices := LGearPiece.MinorIconIndices + [LIterator.AsInteger];
                         LIterator.Return;
                      end;
                    end;
                    LIterator.Return;
                    LLoadout.GearPieces.Add(LItemType, LGearPiece);
                  end;
                  LIterator.Return;
                end
                else if (SameText(LIterator.Key, 'Weapons')) and
                  (LIterator.&Type = TJsonToken.StartObject) then
                begin
                  LIterator.Recurse;
                  while LIterator.Next and
                    (LIterator.&Type <> TJsonToken.EndObject) do
                  begin
                    LWeaponSlot :=
                      TWeaponSlot(GetEnumValue(TypeInfo(TWeaponSlot),
                      LIterator.Key));
                    LWeapon := Default (TSerializableWeapon);
                    LWeapon.EquippedModIDs :=
                      TDictionary<TModSlot, Integer>.Create;
                    LIterator.Recurse;
                    while LIterator.Next and
                      (LIterator.&Type <> TJsonToken.EndObject) do
                    begin
                      if SameText(LIterator.Key, 'WeaponID') then
                        LWeapon.WeaponID := LIterator.AsInteger
                      else if SameText(LIterator.Key, 'SelectedTalentID') then
                        LWeapon.SelectedTalentID := LIterator.AsInteger
                      else if SameText(LIterator.Key,
                        'SelectedMinorAttributeType') then
                        LWeapon.SelectedMinorAttributeType := LIterator.AsString
                      else if SameText(LIterator.Key, 'ExpertiseLevel') then
                        LWeapon.ExpertiseLevel := LIterator.AsInteger
                      else if (SameText(LIterator.Key, 'EquippedModIDs')) and
                        (LIterator.&Type = TJsonToken.StartObject) then
                      begin
                        LIterator.Recurse;
                        while LIterator.Next and
                          (LIterator.&Type <> TJsonToken.EndObject) do
                        begin
                          LModSlot :=
                            TModSlot(GetEnumValue(TypeInfo(TModSlot),
                            LIterator.Key));
                          LWeapon.EquippedModIDs.Add(LModSlot,
                            LIterator.AsInteger);
                        end;
                        LIterator.Return;
                      end;
                    end;
                    LIterator.Return;
                    LLoadout.Weapons.Add(LWeaponSlot, LWeapon);
                  end;
                  LIterator.Return;
                end
                else if (SameText(LIterator.Key, 'ActivatedSpecBonuses')) and
                  (LIterator.&Type = TJsonToken.StartArray) then
                begin
                  LIterator.Recurse;
                  while LIterator.Next and
                    (LIterator.&Type <> TJsonToken.EndArray) do
                  begin
                    LBonus := TWeaponFamily
                      (GetEnumValue(TypeInfo(TWeaponFamily),
                      LIterator.AsString));
                    LLoadout.ActivatedSpecBonuses :=
                      LLoadout.ActivatedSpecBonuses + [LBonus];
                  end;
                  LIterator.Return;
                end;
              end;
              LIterator.Return;
              Result.Add(LLoadout.Name, LLoadout);
            end;
          end;
          LIterator.Return;
        end;
      end;
    finally
      LIterator.Free;
    end;
  finally
    LReader.Free;
  end;
end;

end.








