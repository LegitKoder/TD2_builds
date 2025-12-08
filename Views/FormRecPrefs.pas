unit FormRecPrefs;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.Controls.Presentation,
  RecommendationEngine, Game.Types, FMX.EditBox, FMX.NumberBox; // Include necessary types

type
  TFrmRecPrefs = class(TForm)
    LayoutRoot: TLayout;
    LabelWeaponFocus: TLabel;
    ComboBoxWeaponFocus: TComboBox;
    LabelOptimizationGoal: TLabel;
    ComboBoxOptimizationGoal: TComboBox;
    LabelSpecificSkill: TLabel;
    EditSpecificSkill: TEdit;
    GroupBoxConstraints: TGroupBox;
    LabelRequiredSets: TLabel;
    ListBoxRequiredSets: TListBox; // Will need custom items or a TStringGrid/TListView for multiple inputs per set
    ButtonAddSet: TButton;
    ButtonRemoveSet: TButton;
    LabelRequiredItems: TLabel;
    ListBoxRequiredItems: TListBox; // Similar to sets
    ButtonAddItem: TButton;
    ButtonRemoveItem: TButton;
    LabelRequiredTalents: TLabel;
    ListBoxRequiredTalents: TListBox; // Similar to sets
    ButtonAddTalent: TButton;
    ButtonRemoveTalent: TButton;
    LabelStatConstraints: TLabel;
    ListBoxStatConstraints: TListBox; // Similar to sets
    ButtonAddStatConstraint: TButton;
    ButtonRemoveStatConstraint: TButton;
    LabelAttributeWeights: TLabel;
    ListBoxAttributeWeights: TListBox;
    ButtonAddWeight: TButton;
    ButtonRemoveWeight: TButton;
    LabelMaxExoticGear: TLabel;
    NumberBoxMaxExoticGear: TNumberBox;
    LabelMaxExoticWeapon: TLabel;
    NumberBoxMaxExoticWeapon: TNumberBox;
    LayoutButtons: TLayout;
    ButtonOK: TButton;
    ButtonCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonOKClick(Sender: TObject);
    procedure ComboBoxOptimizationGoalChange(Sender: TObject);
    // Add event handlers for Add/Remove buttons for constraints
    procedure ButtonAddSetClick(Sender: TObject);
    procedure ButtonAddWeightClick(Sender: TObject);
  private
    { Private declarations }
    FUserPreferences: TBuildArchetype;
    procedure PopulateWeaponFocus;
    procedure PopulateOptimizationGoals;
  public
    { Public declarations }
    function GetUserPreferencesAsArchetype: TBuildArchetype;
  end;

var
  FrmRecPrefs: TFrmRecPrefs;

implementation

{$R *.fmx} // Assume an FMX file will be created

uses System.TypInfo;

{ TFrmRecPrefs }

function TFrmRecPrefs.GetUserPreferencesAsArchetype: TBuildArchetype;
var
  LItem: TListBoxItem;
  LParts: TArray<string>;
  LSetName: string;
  LCount, i: Integer;
  LItemType: TItemType;
  LTalent: string;
  LAttrType: TMinorAttributeType;
  LCoreAttr: TCoreAttributeType;
begin
  for i := 0 to ListBoxRequiredSets.Items.Count - 1 do
  begin
    LItem := ListBoxRequiredSets.ListItems[i];
    // Expected format: "Brand Name (3 pcs, BrandSet)"
    // We stored the name in TagString or need to parse carefully.
    // Let's assume simple parsing for now, but robust enough for spaces.
    // Ideally, we should have stored the name in the Item.TagString or an object.
    // But since ButtonAddSetClick just adds text... let's parse from the end.
    var Text := LItem.Text;
    var OpenParen := Pos('(', Text);
    if OpenParen > 0 then
    begin
      LSetName := Trim(Copy(Text, 1, OpenParen - 1));
      var InfoStr := Copy(Text, OpenParen + 1, Length(Text) - OpenParen - 1); // "3 pcs, BrandSet"
      var InfoParts := InfoStr.Split([',']);
      if Length(InfoParts) > 0 then
      begin
        var CountStr := Trim(InfoParts[0]).Split([' '])[0];
        if TryStrToInt(CountStr, LCount) then
        begin
          FUserPreferences.RequiredBrandSets.AddOrSetValue(LSetName, LCount);
        end;
      end;
    end;
  end;

  for i := 0 to ListBoxRequiredTalents.Items.Count - 1 do
  begin
    LItem := ListBoxRequiredTalents.ListItems[i];
    LParts := LItem.Text.Split([':']);
    if Length(LParts) > 1 then
    begin
      LItemType := TItemType(GetEnumValue(TypeInfo(TItemType), 'it' + Trim(LParts[0])));
      LTalent := Trim(LParts[1]);
      FUserPreferences.RequiredTalents.Add(LItemType, LTalent);
    end;
  end;

  for i := 0 to ListBoxStatConstraints.Items.Count - 1 do
  begin
    LItem := ListBoxStatConstraints.ListItems[i];
    LParts := LItem.Text.Split([':']);
    if Length(LParts) > 1 then
    begin
      LItemType := TItemType(GetEnumValue(TypeInfo(TItemType), 'it' + Trim(LParts[0])));
      LAttrType := TMinorAttributeType(GetEnumValue(TypeInfo(TMinorAttributeType), 'mad' + Trim(LParts[1])));
      if not FUserPreferences.RequiredAttributes.ContainsKey(LItemType) then
      begin
        FUserPreferences.RequiredAttributes.Add(LItemType, TArray<TMinorAttributeType>.Create());
      end;
      FUserPreferences.RequiredAttributes[LItemType] := FUserPreferences.RequiredAttributes[LItemType] + [LAttrType];
    end;
  end;

  for i := 0 to ListBoxAttributeWeights.Items.Count - 1 do
  begin
    LItem := ListBoxAttributeWeights.ListItems[i];
    // Expected format: "AttributeName (Weight: 1.5)"
    var Text := LItem.Text;
    var OpenParen := Pos('(', Text);
    if OpenParen > 0 then
    begin
      var AttrName := Trim(Copy(Text, 1, OpenParen - 1));
      var WeightInfo := Copy(Text, OpenParen + 1, Length(Text) - OpenParen - 1); // "Weight: 1.5"
      var WeightParts := WeightInfo.Split([':']);
      if Length(WeightParts) > 1 then
      begin
        var WeightVal: Double;
        if TryStrToFloat(Trim(WeightParts[1]), WeightVal) then
          FUserPreferences.AttributeWeights.AddOrSetValue(AttrName, WeightVal);
      end;
    end;
  end;

  Result := FUserPreferences;
end;

procedure TFrmRecPrefs.FormCreate(Sender: TObject);
begin
  if not Assigned(FUserPreferences.RequiredBrandSets) then
    FUserPreferences.RequiredBrandSets := TDictionary<string, Integer>.Create;
  if not Assigned(FUserPreferences.RequiredTalents) then
    FUserPreferences.RequiredTalents := TDictionary<TItemType, string>.Create;
  if not Assigned(FUserPreferences.RequiredAttributes) then
    FUserPreferences.RequiredAttributes := TDictionary<TItemType, TArray<TMinorAttributeType>>.Create;
  if not Assigned(FUserPreferences.RequiredCoreAttribute) then
    FUserPreferences.RequiredCoreAttribute := TDictionary<TItemType, TCoreAttributeType>.Create;
  if not Assigned(FUserPreferences.AttributeWeights) then
    FUserPreferences.AttributeWeights := TDictionary<string, Double>.Create;

  PopulateWeaponFocus;
  PopulateOptimizationGoals;
end;

procedure TFrmRecPrefs.PopulateWeaponFocus;
var
  LWeaponFamily: TWeaponFamily;
begin
  ComboBoxWeaponFocus.Clear;
  for LWeaponFamily := Low(TWeaponFamily) to High(TWeaponFamily) do
  begin
    if LWeaponFamily = wcUnknown then Continue; // Skip unknown
    ComboBoxWeaponFocus.Items.Add(GetEnumName(TypeInfo(TWeaponFamily), Ord(LWeaponFamily)).Substring(2)); // Remove 'wc' prefix
  end;
end;

procedure TFrmRecPrefs.PopulateOptimizationGoals;
begin
//
end;

procedure TFrmRecPrefs.ComboBoxOptimizationGoalChange(Sender: TObject);
begin
//  EditSpecificSkill.Visible := TOptimizationGoal(ComboBoxOptimizationGoal.ItemIndex) = ogMaximizeSpecificSkillDamage;
end;

procedure TFrmRecPrefs.ButtonAddSetClick(Sender: TObject);
var
  SetName: string;
  PiecesStr: string;
  Pieces: Integer;
  SetTypeStr: string;
  SetTypeVal: TSetType;
//  NewConstraint: TRequiredSetConstraint;
  ListItem: TListBoxItem;
begin
  // This is a simplified input method. A dedicated sub-form would be better.
  if InputQuery('Add Required Set', 'Set Name:', SetName) and
     InputQuery('Add Required Set', 'Pieces Required:', PiecesStr) and
     TryStrToInt(PiecesStr, Pieces) and (Pieces > 0) and (Pieces <= 6) and
     InputQuery('Add Required Set', 'Set Type (BrandSet, GearSet, NamedSet, ExoticSet):', SetTypeStr) then
  begin
    if SameText(SetTypeStr, 'BrandSet') then SetTypeVal := stBrandSet
    else if SameText(SetTypeStr, 'GearSet') then SetTypeVal := stGearSet
    else if SameText(SetTypeStr, 'NamedSet') then SetTypeVal := stNamedSet
    else if SameText(SetTypeStr, 'ExoticSet') then SetTypeVal := stExoticSet
    else begin ShowMessage('Invalid Set Type.'); Exit; end;

    ListItem := TListBoxItem.Create(ListBoxRequiredSets);
    ListItem.Text := Format('%s (%d pcs, %s)', [SetName, Pieces, SetTypeStr]);
    ListBoxRequiredSets.AddObject(ListItem);
  end;
end;

procedure TFrmRecPrefs.ButtonAddWeightClick(Sender: TObject);
var
  AttrName: string;
  WeightStr: string;
  WeightVal: Double;
  ListItem: TListBoxItem;
begin
  if InputQuery('Add Attribute Weight', 'Attribute Name (e.g. repairSkills, weaponDamage):', AttrName) and
     InputQuery('Add Attribute Weight', 'Weight Value (e.g. 1.5, 2.0):', WeightStr) and
     TryStrToFloat(WeightStr, WeightVal) then
  begin
    ListItem := TListBoxItem.Create(ListBoxAttributeWeights);
    ListItem.Text := Format('%s (Weight: %.1f)', [AttrName, WeightVal]);
    ListBoxAttributeWeights.AddObject(ListItem);
  end;
end;

// TODO: Implement Add/Remove for other constraints (Items, Talents, Stats)
// TODO: Implement loading of existing constraints into ListBoxes when editing

procedure TFrmRecPrefs.ButtonOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
