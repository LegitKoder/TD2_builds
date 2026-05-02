unit FormSets;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Math, System.Generics.Defaults,
  System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListBox, FMX.Edit, FMX.EditBox, FMX.SpinBox, System.TypInfo,
  System.ImageList, FMX.ImgList, FMX.MultiResBitmap, FMX.DialogService, Skia,
  FMX.Skia,
  FMX.SearchBox, Game.Types, Game.JsonIterator, Utils;

type
  //
  TFormSlots = class(TForm)
    ListBoxSets: TListBox;
    Layout1: TLayout;
    Layout2: TLayout;
    Splitter1: TSplitter;
    LayoutAttr: TLayout;
    Group_CoreAttributes: TGroupBox;
    Group_Attributes_Mods: TGroupBox;
    CoreAttributes: TComboBox;
    CoreValues: TSpinBox;
    ImgListCore: TImageList;
    GridPanelLayout1: TGridPanelLayout;
    Base_Core: TSkLabel;
    Base_maxStats: TSkLabel;
    GridPanelLayout2: TGridPanelLayout;
    ListBoxMinorAttributes: TListBox;
    ListBoxFixedMinorAttributes: TListBox;
    ListBoxModAttributes: TListBox;
    StyleBookSlots: TStyleBook;
    Cancel: TSpeedButton;
    Ok: TSpeedButton;
    SearchBox: TSearchBox;
    LayoutTalents: TLayout;
    Talents: TGroupBox;
    ListBoxTalents: TListBox;
    GroupBox1: TGroupBox;
    procedure OkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListBoxMinorAttributesClick(Sender: TObject);
    procedure ListBoxModAttributesClick(Sender: TObject);
    procedure CoreAttributesChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBoxSetsItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
  private
    { Private declarations }
    FGearSlot: TItemType;
    FRemainingRollableSlots: Integer;
    FSelectedCoreAttributeImageIndex: Integer;
    FSelectedModAttributeImageIndex: Integer;
    FCoreAttributes: TList<TCoreAttribute>;
    FSelectedGearPiece: TGearPiece;
    FPieceSets: TList<TPieceSet>;
    FRollableMinorLimit: Integer;
    FData: TDataJsonIterator;
    procedure UpdateMinorAttributeList;
    procedure PopulateCoreAttributes;
    function GetSelectedMinorAttributeImageIndex(Index: Integer): Integer;
    procedure PopulateMinorAttributes;
    procedure PopulateMods;
    function FindPieceSetByNameAndType(const SetName: string; SetType: TSetType;
      out PieceSet: TPieceSet): Boolean;
    function GetCoreAttributeByID(const CoreAttrID: string): TCoreAttribute;
    // function GetMaxCoreAttributeValue(const CoreAttrID: string; GearSlot: TItemType): Double;
    function GetMaxCoreAttributeValue(const CoreAttrID: string): Double;
    function AreModsAvailable(GearPiece: TGearPiece): Boolean;
    procedure UpdateModAvailability;
    // btnMinor3: TCornerButton; // Removed phantom reference
    function GetCoreAttributeTypeByID(const CoreAttrID: string)
      : TCoreAttributeType;
    procedure ResetMinorAttributeSelections;
    procedure LockMinorAttributeInList(const MinorAttr: TMinorAttributeType);
    function TryMapFixedMinorToEnum(const FixedID: string;
      out MinorType: TMinorAttributeType): Boolean;
    function FormatFixedMinorAttribute(const Attr
      : TFixedMinorAttributeDefinition): string;
    procedure ConfigureFixedMinorColumnVisibility(const HasFixed: Boolean);
    procedure ApplyFixedMinorAttributes(const APart: TPart);
    procedure SetGearSlot(const Value: TItemType);
    procedure ItemApplyStyleLookup(Sender: TObject);
  public
    { Public declarations }
    FSelectedMinorAttributeImageIndices: array of Integer;
//    function AreModsAvailable(GearPiece: TGearPiece): Boolean;
    procedure PopulateBrands(const AData: TDataJsonIterator);
    procedure PopulateTalents(const AData: TDataJsonIterator);

    property GearSlot: TItemType read FGearSlot write SetGearSlot;
    procedure SetCoreAttributeType(const AType: string);
    procedure SetCoreAttributeValue(const AValue: Double);
    property SelectedCoreAttributeImageIndex: Integer
      read FSelectedCoreAttributeImageIndex;
    property SelectedMinorAttributeImageIndex[Index: Integer]: Integer
      read GetSelectedMinorAttributeImageIndex;
    property SelectedModAttributeImageIndex: Integer
      read FSelectedModAttributeImageIndex;
    property SelectedGearPiece: TGearPiece read FSelectedGearPiece;
    property PieceSets: TList<TPieceSet> read FPieceSets write FPieceSets;
  end;

var
  FormSlots: TFormSlots;

implementation

uses
  System.JSON.Readers, System.JSON.Builders, System.IOUtils, System.JSON.Types,
  System.Rtti;

{$R *.fmx}
{$REGION 'FUNCTIONS'}

function GetAssetsPath: string;
begin
  Result := TUtils.AssetsPath;
end;

function TFormSlots.GetSelectedMinorAttributeImageIndex(Index: Integer)
  : Integer;
begin
  if (Index >= 0) and (Index < Length(FSelectedMinorAttributeImageIndices)) then
    Result := FSelectedMinorAttributeImageIndices[Index]
  else
    Result := -1;
end;

function TFormSlots.FindPieceSetByNameAndType(const SetName: string;
  SetType: TSetType; out PieceSet: TPieceSet): Boolean;
var
  PS: TPieceSet;
  i: Integer;
begin
  Result := False;
  for i := 0 to FPieceSets.Count - 1 do
  begin
    PS := FPieceSets[i];
    if (PS.Name = SetName) and (PS.SetType = SetType) then
    begin
      PieceSet := PS;
      Exit(True);
    end;
  end;
end;

function TFormSlots.AreModsAvailable(GearPiece: TGearPiece): Boolean;
const
  GearWithSlots = [itMask, itBackpack, itChest]; // only these ever get a slot
  // Specific pieces whose mod slot is locked (add more if needed)
  LockedMods: array [0 .. 0] of string = ('Claws Out'); // example chest exotic
var
  PieceName: string;
  i: Integer;
begin
  PieceName := GearPiece.Name.ToLower;
  // 1) items whose mod slot is always locked
  for i := 0 to High(LockedMods) do
    if PieceName = LockedMods[i].ToLower then
      Exit(False);

  // 2) improvised gear always mod-able
  if GearPiece.SetType = stImprovised then
    Exit(True);

  // 3) Si certains exotiques ou marques rares disposent d’un slot de mod malgré leur type (gants, holster ou genouillère)
  if SameText(PieceName, 'GOLAN X9' { exemple fictif }) then
    Exit(True);

  // 4) normal rule
  Result := (GearPiece.ItemType in GearWithSlots);
end;

function TFormSlots.GetMaxCoreAttributeValue(const CoreAttrID: string): Double;
var
  CoreAttr: TCoreAttribute;
  i: Integer;
begin
  for i := 0 to FCoreAttributes.Count - 1 do
  begin
    CoreAttr := FCoreAttributes[i];
    if CoreAttr.ID = CoreAttrID then
      Exit(CoreAttr.Value);
  end;
  // If not found, return 0
  Result := 0.0;
end;

function TFormSlots.GetCoreAttributeByID(const CoreAttrID: string)
  : TCoreAttribute;
var
  CoreAttr: TCoreAttribute;
  i: Integer;
begin
  for i := 0 to FCoreAttributes.Count - 1 do
  begin
    CoreAttr := FCoreAttributes[i];
    if CoreAttr.ID = CoreAttrID then
    begin
      Result := CoreAttr;
      Exit(CoreAttr);
    end;
  end;
  // If not found, return a default value
  Result.ID := CoreAttrID;
  Result.TypeName := 'Unknown';
  Result.Value := 0.0;
end;

function TFormSlots.GetCoreAttributeTypeByID(const CoreAttrID: string)
  : TCoreAttributeType;
begin
  if CoreAttrID = 'weaponDamage' then
    Result := catWeaponDamage
  else if CoreAttrID = 'armor' then
    Result := catArmor
  else if CoreAttrID = 'skillTier' then
    Result := catSkillTier
  else
    raise Exception.Create('Unknown Core Attribute ID: ' + CoreAttrID);
end;

function TFormSlots.TryMapFixedMinorToEnum(const FixedID: string;
  out MinorType: TMinorAttributeType): Boolean;
begin
  if SameText(FixedID, 'criticalHitChance') then
    MinorType := madCriticalHitChance
  else if SameText(FixedID, 'criticalHitDamage') then
    MinorType := madCriticalHitDamage
  else if SameText(FixedID, 'headshotDamage') then
    MinorType := madHeadshotDamage
  else if SameText(FixedID, 'weaponHandling') then
    MinorType := madWeaponHandling
  else if SameText(FixedID, 'armorRegen') then
    MinorType := madArmorRegen
  else if SameText(FixedID, 'hazardProtection') then
    MinorType := madHazardProtection
  else if SameText(FixedID, 'health') then
    MinorType := madHealth
  else if SameText(FixedID, 'explosiveResistance') then
    MinorType := madExplosiveResistance
  else if SameText(FixedID, 'incomingRepairs') then
    MinorType := madIncomingRepairs
  else if SameText(FixedID, 'skillHaste') then
    MinorType := madSkillHaste
  else if SameText(FixedID, 'skillDamage') then
    MinorType := madSkillDamage
  else if SameText(FixedID, 'repairSkills') then
    MinorType := madRepairSkills
  else if SameText(FixedID, 'statusEffects') then
    MinorType := madStatusEffects
  else
    Exit(False);
  Result := True;
end;

function TFormSlots.FormatFixedMinorAttribute(const Attr
  : TFixedMinorAttributeDefinition): string;
var
  ValueText: string;
  NameText: string;
begin
  if SameValue(Attr.Value, 0.0) then
    ValueText := ''
  else
    ValueText := '+' + FormatFloat('0.##', Attr.Value) + '% ';

  // Prettify name
  if SameText(Attr.ID, 'meleeDamage') then
    NameText := 'Melee Damage'
  else if SameText(Attr.ID, 'pistolDamage') then
    NameText := 'Pistol Damage'
  else if SameText(Attr.ID, 'damageTOutOfCover') then
    NameText := 'Dmg to Target Out of Cover'
  else if SameText(Attr.ID, 'armorOnKill') then
    NameText := 'Armor on Kill'
  else if SameText(Attr.ID, 'healthDamage') then
    NameText := 'Health Damage'
  else
  begin
    // Fallback: try to map to enum for nice name, otherwise use TypeName or ID
    var EnumType: TMinorAttributeType;
    if TryMapFixedMinorToEnum(Attr.ID, EnumType) then
      NameText := MinorAttributeDetailsToString(EnumType)
    else if Attr.TypeName <> '' then
      NameText := Attr.TypeName
    else
      NameText := Attr.ID;
  end;

  Result := ValueText + NameText;
end;

{$ENDREGION}

procedure TFormSlots.ConfigureFixedMinorColumnVisibility(const HasFixed
  : Boolean);
const
  COL_SINGLE_LIST: array [0 .. 2] of Double = (100.0, 0.0, 0.0);
begin
  // Always give full width to the main listbox, as we now merge fixed attributes into it.
  if GridPanelLayout2.ColumnCollection.Count >= 3 then
  begin
    GridPanelLayout2.ColumnCollection.Items[0].Value := COL_SINGLE_LIST[0];
    GridPanelLayout2.ColumnCollection.Items[1].Value := COL_SINGLE_LIST[1];
    GridPanelLayout2.ColumnCollection.Items[2].Value := COL_SINGLE_LIST[2];
  end;
end;

procedure TFormSlots.ApplyFixedMinorAttributes(const APart: TPart);
var
  FixedID: string;
  Def: TFixedMinorAttributeDefinition;
  DisplayItem: TListBoxItem;
  FixedCount: Integer;
  MaxSlots: Integer;
  FixedDefs: TArray<TFixedMinorAttributeDefinition>;
  FixedHeader: TListBoxGroupHeader;

  procedure AppendFixedDefinitionToMainList(const ADef: TFixedMinorAttributeDefinition);
  var
    Len: Integer;
    Cat: TMinorAttributeCat;
    LowerID: string;
    EnumType: TMinorAttributeType;
  begin
    Len := Length(FixedDefs);
    SetLength(FixedDefs, Len + 1);
    FixedDefs[Len] := ADef;

    DisplayItem := TListBoxItem.Create(ListBoxFixedMinorAttributes);
    DisplayItem.Text := FormatFixedMinorAttribute(ADef) + ' (Fixed)';
    DisplayItem.Tag := -99; // Mark as Fixed Attribute

    // Determine ImageIndex (Category Color)
    Cat := matOffensive; // Default
    if TryMapFixedMinorToEnum(ADef.ID, EnumType) then
      Cat := MinorAttributeTypeForDetails(EnumType)
    else
    begin
      // Guess category for non-standard fixed attributes
      LowerID := ADef.ID.ToLower;
      if LowerID.Contains('damage') then
        Cat := matOffensive
      else if LowerID.Contains('armor') or LowerID.Contains('health') or
         LowerID.Contains('protection') or LowerID.Contains('resistance') or
         LowerID.Contains('incoming') then
        Cat := matDefensive
      else if LowerID.Contains('skill') or LowerID.Contains('repair') or
              LowerID.Contains('haste') or LowerID.Contains('status') then
        Cat := matUtility
      else
        Cat := matOffensive;
    end;

    // Map Category to ImageIndex (3: Off, 4: Def, 5: Util)
    case Cat of
      matOffensive: DisplayItem.ImageIndex := 3;
      matDefensive: DisplayItem.ImageIndex := 4;
      matUtility:   DisplayItem.ImageIndex := 5;
    end;

    // Visual locking
    DisplayItem.HitTest := False;  // Prevent clicking/toggling by user
    DisplayItem.IsSelected := True; // Make it look selected
    DisplayItem.Selectable := False;

    // Insert at the top (index 1 to be under the header if we add one, or 0)
    // We'll add them after the "FIXED ATTRIBUTES" header which we will add at 0.
    ListBoxFIxedMinorAttributes.InsertObject(Len, DisplayItem);
  end;

begin
  // 1. Reset the list to standard available attributes
  PopulateMinorAttributes;
  ListBoxFixedMinorAttributes.Visible := False; // Ensure the old list is hidden

  ListBoxMinorAttributes.BeginUpdate;
  try
    SetLength(FixedDefs, 0);

    // 2. Resolve Fixed Attributes definitions
    if (Length(APart.FixedMinorAttributeIDs) > 0) and Assigned(DataJsonIterator)
      and Assigned(DataJsonIterator.FixedMinorAttributeDefinitions) then
    begin
      for var Index := 0 to High(APart.FixedMinorAttributeIDs) do
      begin
        FixedID := APart.FixedMinorAttributeIDs[Index];
        if DataJsonIterator.FixedMinorAttributeDefinitions.TryGetValue(FixedID, Def) then
          AppendFixedDefinitionToMainList(Def)
        else
        begin
          Def := Default(TFixedMinorAttributeDefinition);
          Def.ID := FixedID;
          Def.TypeName := FixedID;
          Def.Value := 0.0;
          AppendFixedDefinitionToMainList(Def);
        end;
      end;
    end
    else if (Length(FSelectedGearPiece.FixedMinorAttributes) > 0) then
    begin
      // Fallback if Part didn't have IDs but Piece has definitions (e.g. from existing loadout)
      for Def in FSelectedGearPiece.FixedMinorAttributes do
        AppendFixedDefinitionToMainList(Def);
    end;

    // 3. Add Header if we have fixed attributes
    if Length(FixedDefs) > 0 then
    begin
      FixedHeader := TListBoxGroupHeader.Create(ListBoxMinorAttributes);
      FixedHeader.Text := 'Fixed attribute';
      FixedHeader.Selectable := False;
      ListBoxMinorAttributes.InsertObject(0, FixedHeader);
    end;

  finally
    ListBoxMinorAttributes.EndUpdate;
  end;

  FSelectedGearPiece.FixedMinorAttributes := FixedDefs;
  FixedCount := Length(FSelectedGearPiece.FixedMinorAttributes);

  // Use the slot count defined in the part, default to 2 if 0/missing
  MaxSlots := APart.MinorAttributeSlotCount;
  if MaxSlots = 0 then
    MaxSlots := 2;

  FSelectedGearPiece.MinorAttributeSlotCount := MaxSlots;
  FRollableMinorLimit := Max(MaxSlots - FixedCount, 0);

  // Layout updates
  ConfigureFixedMinorColumnVisibility(False); // Always hide the secondary column now
  ListBoxMinorAttributes.Enabled := True; // Always enabled so we can see/scroll fixed attributes
end;

procedure TFormSlots.ResetMinorAttributeSelections;
var
  I: Integer;
  Item: TListBoxItem;
begin
  ListBoxMinorAttributes.BeginUpdate;
  try
    for I := 0 to ListBoxMinorAttributes.Count - 1 do
    begin
      Item := ListBoxMinorAttributes.ListItems[I];
      if Item = nil then
        Continue;
      if Item is TListBoxGroupHeader then
        Continue;
      Item.IsSelected := False;
      Item.Enabled := True;
    end;
  finally
    ListBoxMinorAttributes.EndUpdate;
  end;
  SetLength(FSelectedMinorAttributeImageIndices, 0);
end;

procedure TFormSlots.LockMinorAttributeInList(const MinorAttr
  : TMinorAttributeType);
var
  DisplayText: string;
  I: Integer;
  Item: TListBoxItem;
begin
  DisplayText := MinorAttributeDetailsToString(MinorAttr);
  for I := 0 to ListBoxMinorAttributes.Count - 1 do
  begin
    Item := ListBoxMinorAttributes.ListItems[I];
    if (Item = nil) or (Item is TListBoxGroupHeader) then
      Continue;
    if SameText(Item.Text, DisplayText) then
    begin
      Item.IsSelected := True;
      Item.Enabled := False;
      Break;
    end;
  end;
end;

procedure TFormSlots.SetGearSlot(const Value: TItemType);
var
  SlotText: string;
begin
  FGearSlot := Value;
  // Reset selection state when switching slot (avoids carrying rollable talent across slots)
  FSelectedGearPiece := Default(TGearPiece);
  FSelectedGearPiece.ItemType := Value;
  SlotText := ItemTypeToStr(Value);
  GroupBox1.Text := 'Sets ' + SlotText;
  Caption := 'Sets ' + SlotText;
end;

procedure TFormSlots.ItemApplyStyleLookup(Sender: TObject);
var
  LItem: TListBoxItem;
  G: TGlyph;
begin
  if not (Sender is TListBoxItem) then Exit;
  LItem := TListBoxItem(Sender);

  // Find Glyph
  G := LItem.FindStyleResource('glyphstyle') as TGlyph;
  if not Assigned(G) then
    G := LItem.FindStyleResource('glyph') as TGlyph;

  if Assigned(G) and Assigned(FData) then
  begin
    G.Images := FData.ImageList_GTalents;
    G.ImageIndex := LItem.ImageIndex;
//    G.AutoHide := False;
    G.Visible := (LItem.ImageIndex >= 0);
    G.HitTest := False;
  end;
end;

procedure TFormSlots.FormCreate(Sender: TObject);
begin
  if Assigned(DataJsonIterator) then
    ListBoxTalents.Images := DataJsonIterator.ImageList_GTalents;
  FCoreAttributes := TList<TCoreAttribute>.Create;
  PopulateCoreAttributes;
  PopulateMinorAttributes;
  PopulateMods;
  FRollableMinorLimit := 2;
  ConfigureFixedMinorColumnVisibility(False);
  ListBoxFixedMinorAttributes.Visible := False;
  Talents.Visible := False;
end;

procedure TFormSlots.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCoreAttributes);
  // FreeAndNil(FPieceSets);
end;

procedure TFormSlots.OkClick(Sender: TObject);
var
  GearPiece: TGearPiece;
  count, idx, i, iq: Integer;
  enumType: TMinorAttributeType;
begin
  GearPiece.CoreAttribute.ID := CoreAttributes.ListItems
    [CoreAttributes.ItemIndex].TagString;
  GearPiece.CoreAttribute.TypeName := CoreAttributes.Items
    [CoreAttributes.ItemIndex];
  GearPiece.CoreAttribute.AttrType := GetCoreAttributeTypeByID
    (CoreAttributes.ListItems[CoreAttributes.ItemIndex].TagString);
  GearPiece.CoreAttribute.Value := CoreValues.Value;
  // Ensure the value is within acceptable range
  if GearPiece.CoreAttribute.Value > CoreValues.Max then
    GearPiece.CoreAttribute.Value := CoreValues.Max;
  if GearPiece.CoreAttribute.Value < CoreValues.Min then
    GearPiece.CoreAttribute.Value := CoreValues.Min;
  // Assign to selected gear piece
  FSelectedGearPiece.CoreAttribute := GearPiece.CoreAttribute;

  SetLength(FSelectedGearPiece.SelectedMinorIconIndices, Length(FSelectedMinorAttributeImageIndices));
  for iq := 0 to High(FSelectedMinorAttributeImageIndices) do
    FSelectedGearPiece.SelectedMinorIconIndices[iq] := FSelectedMinorAttributeImageIndices[iq];

  // 1. Count selected ROLLABLE attributes only
  count := 0;
  for i := 0 to ListBoxMinorAttributes.Count - 1 do
    if ListBoxMinorAttributes.ListItems[i].IsSelected and
       (ListBoxMinorAttributes.ListItems[i].Tag <> -99) then
      Inc(count);

  // 2. Allocate arrays for ROLLABLE attributes
  SetLength(FSelectedGearPiece.MinorAttributes, count);
  SetLength(FSelectedGearPiece.SelectedMinorIconIndices, count);

  // 3. Fill entries
  idx := 0;
  for i := 0 to ListBoxMinorAttributes.Count - 1 do
    if ListBoxMinorAttributes.ListItems[i].IsSelected and
       (ListBoxMinorAttributes.ListItems[i].Tag <> -99) then
    begin
      enumType := StrToMinorAttributeType(ListBoxMinorAttributes.ListItems[i].Text);
      FSelectedGearPiece.MinorAttributes[idx].MinorAttribute := enumType;
      FSelectedGearPiece.MinorAttributes[idx].AttrType      := MinorAttributeTypeForDetails(enumType);
      FSelectedGearPiece.MinorAttributes[idx].Value         := GetDefaultMinorAttributeValue(enumType);
      FSelectedGearPiece.SelectedMinorIconIndices[idx]      := ListBoxMinorAttributes.ListItems[i].ImageIndex;
      Inc(idx);
    end;

  // Persist selected talent (if any). For Brand/Improvised it is rollable;
  // for Named/Exotic/GearSet it is usually fixed but we still capture the selection safely.
  if Assigned(ListBoxTalents) then
  begin
    var SelTalent := '';
    if (ListBoxTalents.ItemIndex >= 0) and (ListBoxTalents.ListItems[ListBoxTalents.ItemIndex] <> nil) and
       (not (ListBoxTalents.ListItems[ListBoxTalents.ItemIndex] is TListBoxGroupHeader)) then
      SelTalent := ListBoxTalents.ListItems[ListBoxTalents.ItemIndex].Text.Trim;

    if SelTalent <> '' then
      FSelectedGearPiece.Talent := SelTalent
    else if FSelectedGearPiece.SetType in [stBrandSet, stImprovised] then
      FSelectedGearPiece.Talent := ''; // rollable talent not selected
  end;

  // Persist mod icon index
  FSelectedGearPiece.SelectedModIconIndex := FSelectedModAttributeImageIndex;
  ModalResult := mrOk;
end;

procedure TFormSlots.PopulateCoreAttributes;
var
  JSONString: string;
  i: Integer;
  ComboBoxItem: TListBoxItem;
  JSONReader: TJSONTextReader;
  LIterator: TJSONIterator;
  Attribute: TCoreAttribute;
begin
  JSONString := TFile.ReadAllText(GetAssetsPath + 'Brands.json',
    TEncoding.UTF8);
  JSONReader := TJSONTextReader.Create(TStringReader.Create(JSONString));
  LIterator := TJSONIterator.Create(JSONReader);
  var
  CObjJSON := LIterator.AsInteger;
  // FCoreAttributes := TList<TCoreAttribute>.Create;

  FCoreAttributes.Clear;
  CoreAttributes.Clear;
  CoreAttributes.BeginUpdate;
  try
    i := 0;
    while True do
    begin
      while LIterator.Next do
      begin
        if LIterator.&Type in [TJsonToken.StartObject, TJsonToken.StartArray]
        then
        begin
          Attribute := Default (TCoreAttribute);
          LIterator.Recurse;
        end
        else if LIterator.Path = 'coreAttributes[' + IntToStr(CObjJSON) + '].id'
        then // Corrected the path to 'id'
        begin
          Attribute.ID := LIterator.AsString;
        end
        else if LIterator.Path = 'coreAttributes[' + IntToStr(CObjJSON) + '].type'
        then // Corrected the path to 'type'
        begin
          Attribute.TypeName := LIterator.AsString;
          ComboBoxItem := TListBoxItem.Create(CoreAttributes);
          ComboBoxItem.Parent := CoreAttributes;
          ComboBoxItem.Text := Attribute.TypeName;
          ComboBoxItem.ImageIndex := i;
          ComboBoxItem.TagString := Attribute.ID;
          ComboBoxItem.Tag := FCoreAttributes.Count - 1;
          Inc(CObjJSON);
          Inc(i);
        end
        else if (LIterator.Depth = 3) and (LIterator.Key = 'value') then
        begin
          Attribute.Value := LIterator.AsDouble;
          // Add to the list
          FCoreAttributes.Add(Attribute);
        end
      end;
      if LIterator.InRecurse then
      begin
        LIterator.Return;
      end
      else
        Break;
    end;
  finally
    CoreAttributes.EndUpdate;
    FreeAndNil(LIterator);
    FreeAndNil(JSONReader);
  end;
end;

procedure TFormSlots.PopulateMinorAttributes;
var
  TmpOff, TmpDef, TmpUt: TList<TListBoxItem>;
  MinorAttr: TMinorAttributeType;
  i: integer;
  function AddHeader(const Caption: string): TListBoxGroupHeader;
  begin
    Result := TListBoxGroupHeader.Create(ListBoxMinorAttributes);
    Result.Parent := ListBoxMinorAttributes;
    Result.Text := Caption;
  end;

begin
  ListBoxMinorAttributes.BeginUpdate;
  try
    ListBoxMinorAttributes.Clear;
    TmpOff := TList<TListBoxItem>.Create;
    TmpDef := TList<TListBoxItem>.Create;
    TmpUt := TList<TListBoxItem>.Create;
    try
      for MinorAttr := Low(TMinorAttributeType) to High(TMinorAttributeType) do
      begin
        var
        Item := TListBoxItem.Create(nil);
        Item.Text := MinorAttributeDetailsToString(MinorAttr);
        Item.ImageIndex := Ord(MinorAttributeTypeForDetails(MinorAttr)
          = matOffensive) * 3 + Ord(MinorAttributeTypeForDetails(MinorAttr)
          = matDefensive) * 4 + Ord(MinorAttributeTypeForDetails(MinorAttr)
          = matUtility) * 5;
        case MinorAttributeTypeForDetails(MinorAttr) of
          matOffensive:
            TmpOff.Add(Item);
          matDefensive:
            TmpDef.Add(Item);
          matUtility:
            TmpUt.Add(Item);
        end;
      end;

      { -- add in groups -- }
      if TmpOff.Count > 0 then
      begin
        AddHeader('Offensive');
        for i := 0 to TmpOff.Count - 1 do
          ListBoxMinorAttributes.AddObject(TmpOff[i]);
      end;
      if TmpDef.Count > 0 then
      begin
        AddHeader('Defensive');
        for i := 0 to TmpDef.Count - 1 do
          ListBoxMinorAttributes.AddObject(TmpDef[i]);
      end;
      if TmpUt.Count > 0 then
      begin
        AddHeader('Utility');
        for i := 0 to TmpUt.Count - 1 do
          ListBoxMinorAttributes.AddObject(TmpUt[i]);
      end;

    finally
      TmpOff.Free;
      TmpDef.Free;
      TmpUt.Free;
    end;
  finally
    ListBoxMinorAttributes.EndUpdate;
  end;
end;

procedure TFormSlots.PopulateMods;
var
  LBG_Offensive, LBG_Defensive, LBG_Utility, LBG_Generic: TListBoxGroupHeader;
  LItem: TListBoxItem;
  LGearModDef: TGearModDefinition;
  ModImageIndex: Integer;
  i: Integer;
  LKeys: TArray<Integer>;

  function GetOrCreateGroupHeader(ModType: TGearModType): TListBoxGroupHeader;
  begin
    Result := nil;
    case ModType of
      gsmtOffensive:
        begin
          if not Assigned(LBG_Offensive) then
          begin
            LBG_Offensive := TListBoxGroupHeader.Create(ListBoxModAttributes);
            LBG_Offensive.Text := 'Offensive Mods';
            ListBoxModAttributes.AddObject(LBG_Offensive);
          end;
          Result := LBG_Offensive;
        end;
      gsmtDefensive:
        begin
          if not Assigned(LBG_Defensive) then
          begin
            LBG_Defensive := TListBoxGroupHeader.Create(ListBoxModAttributes);
            LBG_Defensive.Text := 'Defensive Mods';
            ListBoxModAttributes.AddObject(LBG_Defensive);
          end;
          Result := LBG_Defensive;
        end;
      gsmtUtility:
        begin
          if not Assigned(LBG_Utility) then
          begin
            LBG_Utility := TListBoxGroupHeader.Create(ListBoxModAttributes);
            LBG_Utility.Text := 'Utility Mods';
            ListBoxModAttributes.AddObject(LBG_Utility);
          end;
          Result := LBG_Utility;
        end;
      gsmtGeneric: // Example if you have generic mods/slots
        begin
          if not Assigned(LBG_Generic) then
          begin
            LBG_Generic := TListBoxGroupHeader.Create(ListBoxModAttributes);
            LBG_Generic.Text := 'Generic Mods';
            ListBoxModAttributes.AddObject(LBG_Generic);
          end;
          Result := LBG_Generic;
        end;
    end;
    if Assigned(Result) then // Common properties for headers
    begin
      Result.Selectable := False;
    end;
  end;

begin
  ListBoxModAttributes.Clear;
  ListBoxModAttributes.BeginUpdate;
  try
    LBG_Offensive := nil;
    LBG_Defensive := nil;
    LBG_Utility := nil;
    LBG_Generic := nil;

    if not Assigned(DataJsonIterator) then
      Exit;

    if not Assigned(DataJsonIterator.GearModsData) or
      (DataJsonIterator.GearModsData.Count = 0) then
    begin
      LItem := TListBoxItem.Create(ListBoxModAttributes);
      LItem.Text := '(No Gear Mods Defined)';
      LItem.Parent := ListBoxModAttributes;
      Exit;
    end;

    LKeys := DataJsonIterator.GearModsData.Keys.ToArray;
    for i := 0 to High(LKeys) do
    begin
      LGearModDef := DataJsonIterator.GearModsData[LKeys[i]];
      var
      TargetGroup := GetOrCreateGroupHeader(LGearModDef.ModType);

      LItem := TListBoxItem.Create(ListBoxModAttributes);
      LItem.Text := LGearModDef.Name; // e.g., "+6% Critical Hit Chance Mod"
      LItem.Tag := LGearModDef.ID; // Store ID for lookup on click

      // Assign ImageIndex based on ModType (similar to old logic)
      ModImageIndex := -1; // Default
      case LGearModDef.ModType of
        gsmtOffensive:
          ModImageIndex := 7; // Adjust these indices as per your ImgListCore
        gsmtDefensive:
          ModImageIndex := 8;
        gsmtUtility:
          ModImageIndex := 9;
        gsmtGeneric:
          ModImageIndex := 0; // Example for a generic icon
      end;
      LItem.ImageIndex := ModImageIndex;

      if Assigned(TargetGroup) then
        LItem.Parent := TargetGroup // Add to the group
      else
        LItem.Parent := ListBoxModAttributes; // Fallback, add to list directly
      ListBoxModAttributes.AddObject(LItem);
    end;
  finally
    ListBoxModAttributes.EndUpdate;
  end;
end;

function SetTypeToCategoryKey(SetType: TSetType): string;
begin
  case SetType of
    stBrandSet: Result := 'brandSets';
    stGearSet: Result := 'gearSets';
    stNamedSet: Result := 'namedSets';
    stExoticSet: Result := 'exoticSets';
    stImprovised: Result := 'improvisedSets';
  else
    Result := 'unknownSets';
  end;
end;

procedure TFormSlots.PopulateBrands(const AData: TDataJsonIterator);
const
  CategoryOrder: array [0 .. 4] of TSetType = (stBrandSet, stGearSet,
    stNamedSet, stExoticSet, stImprovised);
var
  GlobalPieceSet: TPieceSet;
  Part: TPart;
  FilteredPieceSetsForSlot: TList<TPieceSet>;
  ListBoxGroupHeader: TListBoxGroupHeader;
  ListBoxItem: TListBoxItem;
  CurrentCategoryKey: string;
  SetTypeEnum: TSetType;
  HeaderMap: TDictionary<string, Boolean>;
  I, J, K, L: Integer;
  GlobalPieceSetValues: TArray<TPieceSet>;
begin
  // Use TMainForm's ImageList or pass it. Assuming TIMG_Sets is globally available or passed.
  // For now, assuming ListBoxSets.Images is set in IDE or by MainForm.
  // MainBuilds sets: FormSlots.ListBoxSets.Images := TIMG_Sets;

  if not Assigned(AData) or not Assigned(AData.AllPieceSetDefinitions) then
  begin
    ShowMessage('Error: Data not loaded.');
    Exit;
  end;

  FilteredPieceSetsForSlot := TList<TPieceSet>.Create;
  ListBoxSets.Clear;
  ListBoxSets.BeginUpdate;
  HeaderMap := TDictionary<string, Boolean>.Create;
  try
    for I := 0 to High(CategoryOrder) do
    begin
      SetTypeEnum := CategoryOrder[I];
      CurrentCategoryKey := SetTypeToCategoryKey(SetTypeEnum);

      var SetsOfCurrentType: TList<TPieceSet> := TList<TPieceSet>.Create;
      try
        GlobalPieceSetValues := AData.AllPieceSetDefinitions.Values.ToArray;
        for J := 0 to High(GlobalPieceSetValues) do
        begin
          GlobalPieceSet := GlobalPieceSetValues[J];
          if GlobalPieceSet.SetType = SetTypeEnum then
            SetsOfCurrentType.Add(GlobalPieceSet);
        end;

        SetsOfCurrentType.Sort(TComparer<TPieceSet>.Construct(
          function(const L, R: TPieceSet): Integer
          begin
            Result := CompareText(L.Name, R.Name);
          end));

        for K := 0 to SetsOfCurrentType.Count - 1 do
        begin
          GlobalPieceSet := SetsOfCurrentType[K];
          var PartsInSlotForThisSet: TArray<TPart>;
          SetLength(PartsInSlotForThisSet, 0);

          for L := 0 to High(GlobalPieceSet.Parts) do
          begin
            Part := GlobalPieceSet.Parts[L];
            if Part.GearSlot = FGearSlot then
            begin
              PartsInSlotForThisSet := PartsInSlotForThisSet + [Part];
            end;
          end;

          if Length(PartsInSlotForThisSet) > 0 then
          begin
            if not HeaderMap.ContainsKey(CurrentCategoryKey) then
            begin
              ListBoxGroupHeader := TListBoxGroupHeader.Create(ListBoxSets);
              ListBoxGroupHeader.Text := UpperCase(CurrentCategoryKey);
              ListBoxSets.AddObject(ListBoxGroupHeader);
              HeaderMap.Add(CurrentCategoryKey, True);
            end;

            var FoundInFiltered: Boolean := False;
            for L := 0 to FilteredPieceSetsForSlot.Count - 1 do
            begin
              if FilteredPieceSetsForSlot[L].Name = GlobalPieceSet.Name then
              begin
                FoundInFiltered := True;
                Break;
              end;
            end;
            if not FoundInFiltered then
              FilteredPieceSetsForSlot.Add(GlobalPieceSet);

            for L := 0 to High(PartsInSlotForThisSet) do
            begin
              Part := PartsInSlotForThisSet[L];
              ListBoxItem := TListBoxItem.Create(ListBoxSets);
              ListBoxItem.Text := Part.Name;
              ListBoxItem.ImageIndex := GlobalPieceSet.ImageIndex;
              ListBoxItem.Tag := ord(GlobalPieceSet.SetType);
              ListBoxItem.TagString := GlobalPieceSet.Name;
              ListBoxSets.AddObject(ListBoxItem);
            end;
          end;
        end;
      finally
        SetsOfCurrentType.Free;
      end;
    end;
  finally
    ListBoxSets.EndUpdate;
    HeaderMap.Free;
  end;

  if Assigned(FPieceSets) then
    FreeAndNil(FPieceSets);
  FPieceSets := FilteredPieceSetsForSlot;
end;

procedure TFormSlots.PopulateTalents(const AData: TDataJsonIterator);
var
  TGroupHeader: TListBoxGroupHeader;
  TItem: TListBoxItem;
  SlotName: string;
  CategoryName, TalentName: string;
  SlotData: TDictionary<string, TList<string>>;
  TalentList: TList<string>;
  ImgIdx: Integer;

  procedure AddTalentItem(const ATalentName: string; IsFixed: Boolean = False);
  var
    LItem: TListBoxItem;
    LIconKey: string;
    LImgIdx: Integer;
    G: TGlyph;
  begin
    LItem := TListBoxItem.Create(ListBoxTalents);
    LItem.StyleLookup := 'ListBoxItemTalent';
    LItem.Text := ATalentName;

//    LIconKey := AData.GetTalentIconKey(ATalentName);    // "braced"
//    LImgIdx  := AData.FindImageIndexByName(LIconKey);   // index in ImageList_GTalents
    LImgIdx := AData.GetTalentImageIndex(ATalentName);
    LItem.ImageIndex := LImgIdx;

    // Assign the OnApplyStyleLookup handler to ensure icons persist after scrolling
    LItem.OnApplyStyleLookup := ItemApplyStyleLookup;

    // IMPORTANT: add to list BEFORE ApplyStyleLookup
    ListBoxTalents.AddObject(LItem);

    // Force style creation so FindStyleResource works
    LItem.ApplyStyleLookup;

    // Depending on your style, the glyph may be named "glyphstyle" or "glyph"
    G := LItem.FindStyleResource('glyphstyle') as TGlyph;
    if not Assigned(G) then
      G := LItem.FindStyleResource('glyph') as TGlyph;

    if Assigned(G) then
    begin
      G.Images := AData.ImageList_GTalents;
      G.ImageIndex := LItem.ImageIndex;
      G.Visible := (LItem.ImageIndex >= 0);
      G.HitTest := False;
    end;

    // Auto-select current talent when browsing rollable lists (Brand/Improvised)
    if (not IsFixed) and (FSelectedGearPiece.Talent <> '') and SameText(ATalentName, FSelectedGearPiece.Talent) then
    begin
      LItem.IsSelected := True;
      ListBoxTalents.ItemIndex := LItem.Index;
    end;

    if IsFixed then
    begin
      LItem.Selectable := True;
      LItem.IsSelected := True;
    end;
  end;


begin
  if not Assigned(AData) or not Assigned(AData.GearTalents) then
    Exit;

  FData := AData;

  // Ensure the listbox knows about the image list before we start
  if (ListBoxTalents.Images = nil) and Assigned(AData) then
    ListBoxTalents.Images := AData.ImageList_GTalents;

  // Map FGearSlot to string key used in Talents.json
  // Keys in JSON: Vest, Backpack, Mask, Glove, Holster, Kneepad (singular)
  case FGearSlot of
    itChest: SlotName := 'Vest';
    itBackpack: SlotName := 'Backpack';
    itMask: SlotName := 'Mask';
    itGloves: SlotName := 'Glove';
    itHolster: SlotName := 'Holster';
    itKneepads: SlotName := 'Kneepad';
  else
    Exit; // Other slots don't have talents
  end;

  ListBoxTalents.Clear;
  ListBoxTalents.BeginUpdate;
  try
    // Logic Refinement:
    // 1. If the piece has a specific fixed talent (e.g. Named, Exotic, Gear Set Chest/Backpack), SHOW IT.
    // 2. Else if it is a Brand Set (and has no specific talent), show the generic talents list.

    if (FSelectedGearPiece.SetType in [stNamedSet, stExoticSet, stGearSet]) and (FSelectedGearPiece.Talent <> '') then
    begin
      // Specific Fixed Talent
      TGroupHeader := TListBoxGroupHeader.Create(ListBoxTalents);
      if FSelectedGearPiece.SetType = stNamedSet then
        TGroupHeader.Text := 'NAMED TALENT'
      else if FSelectedGearPiece.SetType = stExoticSet then
        TGroupHeader.Text := 'EXOTIC TALENT'
      else if FSelectedGearPiece.SetType = stGearSet then
        TGroupHeader.Text := 'GEAR SET TALENT'
      else
        TGroupHeader.Text := 'UNIQUE TALENT'; // Fallback

      TGroupHeader.Selectable := False;
      ListBoxTalents.AddObject(TGroupHeader);

      AddTalentItem(FSelectedGearPiece.Talent, True);
    end
    else if FSelectedGearPiece.SetType in [stBrandSet, stImprovised] then
    begin
      // Generic Brand Set Talents
      // For Brand Sets, we expect generic talents mostly on Vest/Backpack.
      if AData.GearTalents.TryGetValue(SlotName, SlotData) then
      begin
        // Show only Brand Set Categories (exclude 'named', 'exotic', 'gearSets')
        for CategoryName in SlotData.Keys do
        begin
          if (not SameText(CategoryName, 'named')) and
             (not SameText(CategoryName, 'exotic')) and
             (not SameText(CategoryName, 'gearSets')) then
          begin
            TGroupHeader := TListBoxGroupHeader.Create(ListBoxTalents);
            TGroupHeader.Text := UpperCase(CategoryName);
            TGroupHeader.StyledSettings := TGroupHeader.StyledSettings - [TStyledSetting.Size];
            TGroupHeader.TextSettings.Font.Size := 10;
            TGroupHeader.Selectable := False;
            ListBoxTalents.AddObject(TGroupHeader);

            TalentList := SlotData[CategoryName];
            for TalentName in TalentList do
              AddTalentItem(TalentName);
          end;
        end;
      end;
    end;
    // Else: Gear Set/Exotic with NO talent (e.g. Mask, Gloves) -> Empty List. Correct.
  finally
    ListBoxTalents.EndUpdate;
  end;
end;

procedure TFormSlots.SetCoreAttributeType(const AType: string);
begin
  Base_Core.Text := AType;
end;

procedure TFormSlots.SetCoreAttributeValue(const AValue: Double);
begin
  Base_maxStats.Text := FloatToStr(AValue);
end;

procedure TFormSlots.ListBoxMinorAttributesClick(Sender: TObject);
var
  i, SelectedRollableCount: Integer;
  LastSelectedItem: TListBoxItem;
begin
  SelectedRollableCount := 0;
  LastSelectedItem := nil;

  // Count only manually selected items, ignoring fixed ones (Tag = -99)
  for i := 0 to ListBoxMinorAttributes.Count - 1 do
  begin
    if ListBoxMinorAttributes.ListItems[i].IsSelected and
       (ListBoxMinorAttributes.ListItems[i].Tag <> -99) then
    begin
      Inc(SelectedRollableCount);
      LastSelectedItem := ListBoxMinorAttributes.ListItems[i];
    end;
  end;

  if SelectedRollableCount > FRemainingRollableSlots then
  begin
    if Assigned(LastSelectedItem) then
      LastSelectedItem.IsSelected := False;
    TDialogService.ShowMessage(Format('You can only select %d minor attributes for this item.', [FRemainingRollableSlots]));
    Dec(SelectedRollableCount); // Adjust count after deselection
  end;

  // Update indices tracking (ignoring fixed attributes for this array)
  SetLength(FSelectedMinorAttributeImageIndices, SelectedRollableCount);
  var currentIdx := 0;
  for i := 0 to ListBoxMinorAttributes.Count - 1 do
  begin
    if ListBoxMinorAttributes.ListItems[i].IsSelected and
       (ListBoxMinorAttributes.ListItems[i].Tag <> -99) then
    begin
      FSelectedMinorAttributeImageIndices[currentIdx] := ListBoxMinorAttributes.ListItems[i].ImageIndex;
      Inc(currentIdx);
    end;
  end;
end;

procedure TFormSlots.ListBoxModAttributesClick(Sender: TObject);
var
  LSelectedItem: TListBoxItem;
  LSelectedModID: Integer;
  LSelectedGearModDef: TGearModDefinition;
begin
  // FSelectedModAttributeImageIndex := ListBoxModAttributes.Selected.ImageIndex;
  LSelectedItem := ListBoxModAttributes.Selected;
  if not Assigned(LSelectedItem) then
  begin
    // Clear the mod attribute if nothing is selected (or handle as needed)
    FSelectedGearPiece.ModAttribute := Default (TModAttribute); // Reset
    FSelectedModAttributeImageIndex := -1;
    FSelectedGearPiece.ModID := 0;
    Exit;
  end;

  LSelectedModID := LSelectedItem.Tag;
  if (LSelectedModID = 0) or (not Assigned(DataJsonIterator)) or
    (not Assigned(DataJsonIterator.GearModsData)) then
  begin
    // Invalid ID or data not loaded
    FSelectedGearPiece.ModAttribute := Default (TModAttribute);
    FSelectedModAttributeImageIndex := -1;
    FSelectedGearPiece.ModID := 0;
    Exit;
  end;

  if DataJsonIterator.GearModsData.TryGetValue(LSelectedModID,
    LSelectedGearModDef) then
  begin
    // Successfully retrieved the selected gear mod definition
    FSelectedGearPiece.ModAttribute.ModEffect := LSelectedGearModDef.AttributeType; // TGearModAttributeType
    FSelectedGearPiece.ModAttribute.Value := LSelectedGearModDef.AttributeValue;
    FSelectedModAttributeImageIndex := LSelectedItem.ImageIndex;
    FSelectedGearPiece.SelectedModIconIndex := LSelectedItem.ImageIndex;
    FSelectedGearPiece.ModID := LSelectedModID;
    // Keep for UI if needed
  end
  else
  begin
    // Mod ID not found in data - should not happen if list is populated correctly
    FSelectedGearPiece.ModAttribute := Default (TModAttribute);
    FSelectedModAttributeImageIndex := -1;
    FSelectedGearPiece.ModID := 0;
    // ShowMessage('Error: Selected gear mod definition not found for ID: ' + IntToStr(LSelectedModID));
  end;
end;

procedure TFormSlots.ListBoxSetsItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
var
  SelectedSetName: string;
  SelectedSetType: TSetType;
  SelectedPieceSet: TPieceSet;
  GearPiece: TGearPiece;
  SelectedPart: TPart;
  i: integer;
begin
  // Check if the item is a group header
  if Item is TListBoxGroupHeader then
    Exit;
  // Get the set name from the item's TagString
  SelectedSetName := Item.TagString;
  SelectedSetType := TSetType(Item.Tag);

  // Find the corresponding PieceSet
  if not FindPieceSetByNameAndType(SelectedSetName, SelectedSetType,
    SelectedPieceSet) then
  begin
    ShowMessage('Error: Set not found.');
    Exit;
  end;

  // Since we only stored parts for the specified GearSlot, we can directly get the first part
  if Length(SelectedPieceSet.Parts) > 0 then
    SelectedPart := SelectedPieceSet.Parts[0]
  else
  begin
    // Fallback: If strict match failed, try finding by name only (ignoring Tag mismatch)
    var FoundAny: Boolean := False;
    for i := 0 to FPieceSets.Count - 1 do
    begin
      if SameText(FPieceSets[i].Name, SelectedSetName) then
      begin
        SelectedPieceSet := FPieceSets[i];
        FoundAny := True;
        Break;
      end;
    end;

    if not FoundAny then
    begin
      ShowMessage('Error: Set not found: ' + SelectedSetName);
      Exit;
    end;
  end;

  // Find the corresponding Part within the PieceSet
  for i := 0 to High(SelectedPieceSet.Parts) do
  begin
    SelectedPart := SelectedPieceSet.Parts[i];
    SelectedPart := SelectedPieceSet.Parts[i];
    if (SelectedPart.Name = Item.Text) and (SelectedPart.GearSlot = FGearSlot)
    then
    begin
      // Create and populate the TGearPiece
      GearPiece.Name := SelectedPart.Name;
      GearPiece.SetName := SelectedPieceSet.Name;
      GearPiece.ItemType := FGearSlot;
      // Map CoreAttributeID to TCoreAttribute
      GearPiece.CoreAttribute := GetCoreAttributeByID
        (SelectedPart.CoreAttributeID);
      GearPiece.SetType := SelectedPieceSet.SetType;
      GearPiece.Bonuses := SelectedPieceSet.Bonuses;
      GearPiece.MinorAttributeSlotCount := SelectedPart.MinorAttributeSlotCount;
      // CRITICAL FIX: Assign the talent from the Part definition
      GearPiece.Talent := SelectedPart.Talent;
      SetLength(GearPiece.FixedMinorAttributes, 0);
      if DataJsonIterator <> nil then
        for var j := 0 to High(SelectedPart.FixedMinorAttributeIDs) do
        begin
          var FixedID := SelectedPart.FixedMinorAttributeIDs[j];
          var Def: TFixedMinorAttributeDefinition;
          if DataJsonIterator.FixedMinorAttributeDefinitions.TryGetValue(FixedID, Def) then
          begin
            var Len := Length(GearPiece.FixedMinorAttributes);
            SetLength(GearPiece.FixedMinorAttributes, Len + 1);
            GearPiece.FixedMinorAttributes[Len] := Def;
          end;
        end;
      FSelectedGearPiece := GearPiece;

      // Update the CoreAttributes ComboBox selection
      for var li := 0 to CoreAttributes.Items.Count - 1 do
      begin
        if CoreAttributes.ListItems[li].TagString = GearPiece.CoreAttribute.ID
        then
        begin
          CoreAttributes.ItemIndex := li;
          Break;
        end;
      end;

      // Trigger the CoreAttributesChange event to update UI elements
      CoreAttributesChange(CoreAttributes);

      // Store the selected gear piece
      FSelectedGearPiece := GearPiece;

      // CRITICAL FIX: Refresh the talents list based on the new selection
      if Assigned(DataJsonIterator) then
        PopulateTalents(DataJsonIterator);

      // Update Talent Visibility logic
      // Show talents if list is not empty (covers Brand Sets on Vest/Backpack AND Named/Set items with unique talents anywhere)
      Talents.Visible := (ListBoxTalents.Count > 0);

      if not Talents.Visible then
        ListBoxTalents.ClearSelection
      else if (FSelectedGearPiece.Talent <> '') and (ListBoxTalents.Count > 0) then
      begin
         // If a specific talent exists, it should be selected by default (PopulateTalents handles selection for Fixed items, but double check)
         // PopulateTalents already sets IsSelected=True for Fixed talents.
      end;

      // Apply and display any fixed minor attributes defined for this part
      ApplyFixedMinorAttributes(SelectedPart);
      UpdateMinorAttributeList;

      // Determine and store the ActualModSlotType for this gear piece
      FSelectedGearPiece.ActualModSlotType := GetGearItemDefaultModSlotType
        (FSelectedGearPiece.ItemType, FSelectedGearPiece.SetName);

      // Clear any previously selected mod for this gear piece
      FSelectedGearPiece.ModAttribute := Default (TModAttribute);

      // Reset to empty/default
      FSelectedModAttributeImageIndex := -1; // Reset image index

      // Update Mod Availability (which might also call PopulateMods or enable/disable ListBoxModAttributes)
      UpdateModAvailability;
      // This should make ListBoxModAttributes visible/enabled if mods are possible

      // Explicitly populate mods for the new piece's slot type
      PopulateMods; // This will now use FSelectedGearPiece.ActualModSlotType

      // Exit after finding the matching part
      Exit;
    end;
  end;

  ShowMessage('Error: Gear piece not found.');

end;

procedure TFormSlots.CoreAttributesChange(Sender: TObject);
var
  SelectedIndex: Integer;
  AttributeID: string;
  MaxValue: Double;
begin
  SelectedIndex := CoreAttributes.ItemIndex;
  if SelectedIndex >= 0 then
  begin
    // Get the Attribute ID from the TagString
    AttributeID := CoreAttributes.ListItems[SelectedIndex].TagString;
    // Get the maximum value using GetMaxCoreAttributeValue
    MaxValue := GetMaxCoreAttributeValue(AttributeID);

    // Update the CoreValues SpinBox
    CoreValues.Max := MaxValue;
    // Optionally set the SpinBox value to the max
    CoreValues.Value := CoreValues.Max;
    // Update labels
    SetCoreAttributeType(CoreAttributes.ListItems[SelectedIndex].Text);
    SetCoreAttributeValue(MaxValue);
    // Update selected core attribute image index
    FSelectedCoreAttributeImageIndex := CoreAttributes.ListItems[SelectedIndex]
      .ImageIndex;
  end;
end;

procedure TFormSlots.UpdateModAvailability;
var
  CanUseMods: Boolean;
begin
  CanUseMods := AreModsAvailable(FSelectedGearPiece);

  ListBoxModAttributes.Visible := CanUseMods;
  ListBoxModAttributes.Enabled := CanUseMods;

  if not CanUseMods then
    ListBoxModAttributes.ItemIndex := -1; // clear any previous choice
end;

procedure TFormSlots.UpdateMinorAttributeList;
var
  ListItem: TListBoxItem;
  i: Integer;
begin
  FRemainingRollableSlots := FSelectedGearPiece.MinorAttributeSlotCount - Length(FSelectedGearPiece.FixedMinorAttributes);

  if FRemainingRollableSlots > 0 then
    Group_Attributes_Mods.Text := Format('Minor Attributes (Pick %d)', [FRemainingRollableSlots])
  else
    Group_Attributes_Mods.Text := 'Minor Attributes (Fixed)';

  // Only clear selection of rollable items. Keep Fixed items (Tag = -99) selected.
  for i := 0 to ListBoxMinorAttributes.Count - 1 do
  begin
    ListItem := ListBoxMinorAttributes.ListItems[i];
    if ListItem.Tag <> -99 then
      ListItem.IsSelected := False
    else
      ListItem.IsSelected := True; // Ensure fixed stay selected
  end;

  // Do NOT disable the listbox if slots are 0, because we still want to see the Fixed Attributes
  // We just rely on FRemainingRollableSlots in OnClick to prevent adding more.
  ListBoxMinorAttributes.Enabled := True;
end;

end.