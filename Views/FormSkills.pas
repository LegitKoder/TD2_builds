unit FormSkills;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  System.Generics.Collections, System.TypInfo, System.Rtti, Winapi.Windows,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.DialogService,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.ListBox, System.Skia, FMX.Skia, System.ImageList, FMX.ImgList,
  Game.Types, Game.JsonIterator, FMX.TabControl, FMX.Objects, Utils;

const
  SkillCategoriesArr: array [0 .. 4] of TSkillCategory = (scOffensive,
    scDefensive, scCrowdControl, scSupport, scHealing);

type
  TFormSkill = class(TForm)
    Offensive: TGroupBox;
    Defensive: TGroupBox;
    CrowdControl: TGroupBox;
    SupportSkills: TGroupBox;
    GridPanelLayout1: TGridPanelLayout;
    FootBar: TToolBar;
    FlowLayout1: TFlowLayout;
    OK: TSpeedButton;
    Cancel: TSpeedButton;
    DmgLyt: TLayout;
    Layout1: TLayout;
    Skill_dmg: TSkLabel;
    Skill_haste: TSkLabel;
    ListView_ofsv: TListView;
    ListBox_dfsv: TListBox;
    ListView_cc: TListView;
    ListView_ss: TListView;
    SkillsListBox: TListBox;
    Splitter1: TSplitter;
    VariantsListView: TListView;
    RsrcStyle: TStyleBook;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OKClick(Sender: TObject);
    procedure SkillsListBoxChange(Sender: TObject);
    procedure VariantsListViewItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    { Private declarations }
    // FSkillData: TDictionary<string, TSkillDefinition>; // To hold the skill data passed from MainForm
    // FSelectedVariant: TSkillVariantDefinition;         // The currently selected variant
    FSkillData: TDictionary<string, TSkillData>;
    FSelectedSkill: string; // current skillID
    FSelectedVariant: TSkillVariant;

    // procedure PopulateSkills; // Fills the TreeView with skills and variants
    function VariantHasCategory(const V: TSkillVariant;
      C: TSkillCategory): Boolean;
    procedure EnsureHeader(const CatStr: string;
      const HeaderMap: TDictionary<string, Boolean>; const LView: TListView);
    procedure ClearUI;
  public
    { Public declarations }
    // This property allows the MainForm to pass all skill definitions to this form
    // property SkillData: TDictionary<string, TSkillDefinition> read FSkillData write FSkillData;
    property SkillData: TDictionary<string, TSkillData> read FSkillData
      write FSkillData;

    // This property allows the MainForm to retrieve the final selection
    // property SelectedVariant: TSkillVariantDefinition read FSelectedVariant;
    property SelectedVariant: TSkillVariant read FSelectedVariant;
    procedure PopulateSkills; // Fills the TreeView with skills and variants
    procedure PopulateVariants(const ASkillID: string);
  end;

var
  FormSkill: TFormSkill;

implementation

uses
  System.UIConsts, System.IOUtils;

{$R *.fmx}

procedure TFormSkill.ClearUI;
begin
  SkillsListBox.Clear;
  VariantsListView.Items.Clear;
  FSelectedVariant := Default (TSkillVariant);
end;

function LoadBitmap(const APath: string): TBitmap;
begin
  Result := TUtils.BitmapFromPath(APath);
end;

function CategoryToString(C: TSkillCategory): string;
begin
  case C of
    scOffensive:
      Result := 'Offensive';
    scDefensive:
      Result := 'Defensive';
    scCrowdControl:
      Result := 'Crowd-control';
    scSupport:
      Result := 'Support';
    scHealing:
      Result := 'Heal';
  else
    Result := 'Other';
  end;
end;

function TFormSkill.VariantHasCategory(const V: TSkillVariant;
  C: TSkillCategory): Boolean;
var
  Cat: TSkillCategory;
  I: Integer;
begin
  for I := 0 to High(V.Categories) do
  begin
    Cat := V.Categories[I];
    if Cat = C then
      Exit(True);
  end;
  Result := False;
end;

procedure TFormSkill.EnsureHeader(const CatStr: string;
  const HeaderMap: TDictionary<string, Boolean>; const LView: TListView);
var
  Item: TListViewItem;
begin
  if HeaderMap.ContainsKey(CatStr) then
    Exit;

  Item := LView.Items.Add;
  Item.Purpose := TListItemPurpose.Header;
  Item.Text := CatStr;
  HeaderMap.Add(CatStr, True);
end;

procedure TFormSkill.FormCreate(Sender: TObject);
begin
  // FSkillData should be assigned by the caller (TMainForm) before showing this form.
  // Initialize FSelectedVariant to an empty record.
  FSelectedVariant := Default (TSkillVariant);

end;

procedure TFormSkill.FormDestroy(Sender: TObject);
begin
  // No specific objects created in this form's logic need freeing, FSkillData is owned by DataJsonIterator.
end;

procedure TFormSkill.OKClick(Sender: TObject);
begin
  // Check if a valid variant has been selected before closing.
  if FSelectedVariant.VariantName <> '' then
  begin
    ModalResult := mrOk;
  end
  else
  begin
    TDialogService.ShowMessage
      ('You must select a skill variant before clicking OK.');
    ModalResult := mrNone; // Keep the dialog open
  end;
end;

procedure TFormSkill.PopulateSkills;
begin
  ClearUI;
  if (FSkillData = nil) or (FSkillData.Count = 0) then
    Exit;

  SkillsListBox.BeginUpdate;
  try
    var LKeys := FSkillData.Keys.ToArray;
    for var i := 0 to High(LKeys) do
    begin
      var PairKey := LKeys[i];
      var PairValue := FSkillData.Items[PairKey];
      var
      Item := TListBoxItem.Create(SkillsListBox);
      Item.Parent := SkillsListBox;
      Item.Text := PairValue.SkillName;
      Item.TagString := PairKey; // SkillID
      Item.StyleLookup := 'ListBoxItem1Style1';
      // <─ your style that owns “glyphstyle”
      Item.Height := 40;
      { ----- put the bitmap into the TGlyph called glyphstyle ----- }
      var LBitmap := LoadBitmap(PairValue.ImagePath);
      if Assigned(LBitmap) then
        Item.StylesData['iconstyle.Bitmap'] := TValue.From<TBitmap>(LBitmap);

      // if you used a TGlyph hooked to an ImageList:
      // Item.StylesData['glyphstyle.ImageIndex'] := YourImageIndex;
      Item.StylesData['Desc'] := PairValue.Description;
    end;
  finally
    SkillsListBox.EndUpdate;
  end;
end;

procedure TFormSkill.PopulateVariants(const ASkillID: string);
var
  Skill: TSkillData;
  Cat: TSkillCategory;
  AddedHdr: Boolean;
  V: TSkillVariant;
  LItem: TListViewItem;
  Idx: integer;
begin
  if not FSkillData.TryGetValue(ASkillID, Skill) then
    Exit;

  // var Skill := FSkillData[ASkillID];
  Idx := 0;
  VariantsListView.BeginUpdate;
  try
    VariantsListView.Items.Clear;
    for var i := 0 to High(SkillCategoriesArr) do
    begin
      Cat := SkillCategoriesArr[i];
      AddedHdr := False;

      for var j := 0 to High(Skill.Variants) do
      begin
        V := Skill.Variants[j];
        if VariantHasCategory(V, Cat) then
        begin
          if not AddedHdr then
          begin
            LItem := VariantsListView.Items.Add;
            LItem.Purpose := TListItemPurpose.Header;
            LItem.Text := CategoryToString(Cat);
            AddedHdr := True;
          end;

          LItem := VariantsListView.Items.Add;
          LItem.Text := V.VariantName;
          LItem.Detail := V.Description;
          LItem.Bitmap := TUtils.BitmapFromPath(V.V_ImagePath);
          LItem.Tag := Idx; // variant index
          LItem.TagString := ASkillID; // and skillID
          Inc(Idx);
        end;

      end;
    end;
  finally
    VariantsListView.EndUpdate;
  end;
end;

procedure TFormSkill.SkillsListBoxChange(Sender: TObject);
var
  LBI: TListBoxItem;
begin
  if (SkillsListBox.ItemIndex < 0) then
  begin
    VariantsListView.Items.Clear;
    Exit;
  end;

  LBI := TListBoxItem(SkillsListBox.ItemByIndex(SkillsListBox.ItemIndex));
  PopulateVariants(LBI.TagString);
  // reset selection
  FSelectedVariant := Default (TSkillVariant);
end;

procedure TFormSkill.VariantsListViewItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  if (AItem = nil) then
    Exit;

  var
  SkillID := AItem.TagString;
  var
  VariantIndex := AItem.Tag;

  if FSkillData.ContainsKey(SkillID) then
  begin
    var
    Arr := FSkillData[SkillID].Variants;
    if (VariantIndex >= 0) and (VariantIndex <= High(Arr)) then
      FSelectedVariant := Arr[VariantIndex];
  end;
end;

end.
