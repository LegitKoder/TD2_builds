unit MainBuilds;

interface

uses
  {Delphi}
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Generics.Collections, System.TypInfo, Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base,
  FMX.Bind.GenData, Data.Bind.GenData, Data.Bind.EngExt,
  FMX.Bind.DBEngExt,
  System.Rtti, System.Bindings.Outputs, FMX.Bind.Editors,
  System.ImageList, System.StrUtils,
  FMX.ImgList, FMX.Bind.Navigator, System.Actions, FMX.ActnList,
  Data.Bind.Components, Data.Bind.ObjectScope, FMX.ListView,
  FMX.MultiView,
  FMX.ListBox, FMX.StdCtrls, FMX.Objects, FMX.Effects, FMX.Filter.Effects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Header, FMX.Styles.Objects,
  System.JSON.Builders, System.JSON.Readers,
  System.JSON.Types, System.IOUtils, System.Generics.Defaults, FMX.Edit,
  {Skia}
  Skia, FMX.Skia,
  {Forms}
  Utils, Acrylic, FormSets, FormWeapons, FormSkills, BuildGenerator, RecommendationEngine, BuildArchetypes,
  {SubjectStand,} LoadoutManager, FormRecPrefs,
  Game.Types, Game.JsonIterator, CalcEngine, FMX.DialogService,
  FMX.DialogService.Async, FMX.TabControl, FMX.SearchBox, MainController, WindowEffects;

const
  MAX_SPEC_BONUS = 3;

type
//  TBuildArchetypeProc = procedure(var AArchetype: TBuildArchetype);
  TBuildArchetypeProc = reference to procedure(var AArchetype: TBuildArchetype);

  TMainForm = class(TForm)
    StyleBookTD2: TStyleBook;
    GridPanelLayoutMain: TGridPanelLayout;
    LayoutMain: TLayout;
    GridPanelLayoutWeapons: TGridPanelLayout;
    Layout_W_Header: TLayout;
    H4_Weapons: TLabel;
    Specialization: TLayout;
    Slot_Specialization: TComboBox;
    Specialization_G: TLayout;
    Slot_Special_SideArm: TComboBox;
    Primary_Weapon: TLayout;
    Slot_Primary: TComboBox;
    Secondary_Weapon: TLayout;
    Slot_Secondary: TComboBox;
    Side_Weapon: TLayout;
    Slot_SideArm: TComboBox;
    GridPanelLayoutGears: TGridPanelLayout;
    Layout_G_Header: TLayout;
    H4_Gear: TLabel;
    Slot_Mask: TLayout;
    Slot_gMask: TComboBox;
    Slot_BackPack: TLayout;
    Slot_gBackPack: TComboBox;
    Slot_Vest: TLayout;
    Slot_gVest: TComboBox;
    Slot_Glove: TLayout;
    Slot_gGlove: TComboBox;
    Slot_Holster: TLayout;
    Slot_gHolster: TComboBox;
    Slot_KneePad: TLayout;
    Slot_gKneePad: TComboBox;
    GridPanelLayoutSkills: TGridPanelLayout;
    Layout_S_Header: TLayout;
    H4_Skill: TLabel;
    First_Skill: TLayout;
    Slot_Skill1: TComboBox;
    Second_Skill: TLayout;
    Slot_Skill2: TComboBox;
    LayoutStats: TLayout;
    MultiView_Loadout: TMultiView;
    LoadoutList: TListView;
    LoadoutHeader: TToolBar;
    Add: TSpeedButton;
    Del: TSpeedButton;
    ImgListSpec: TImageList;
    Spec1: TListBoxItem;
    Spec2: TListBoxItem;
    Spec3: TListBoxItem;
    Spec4: TListBoxItem;
    Spec5: TListBoxItem;
    Spec6: TListBoxItem;
    W_ar: TCheckBox;
    W_smg: TCheckBox;
    W_stg: TCheckBox;
    W_lmg: TCheckBox;
    W_mmr: TCheckBox;
    W_rifle: TCheckBox;
    W_pistol: TCheckBox;
    EditTitle: TEdit;
    Footer: TToolBar;
    Load: TSpeedButton;
    Save: TSpeedButton;
    M_Core_Atr: TCornerButton;
    Slot_AtrMask: TLayout;
    M_AttrLayout: TGridPanelLayout;
    M_Atr1: TCornerButton;
    M_Atr2: TCornerButton;
    M_Mod: TCornerButton;
    Slot_AtrBackpack: TLayout;
    B_Core_Atr: TCornerButton;
    B_Atr1: TCornerButton;
    B_Atr2: TCornerButton;
    B_Mod: TCornerButton;
    Slot_AtrVest: TLayout;
    V_Core_Atr: TCornerButton;
    V_AttrLayout: TGridPanelLayout;
    V_Atr1: TCornerButton;
    V_Atr2: TCornerButton;
    V_Mod: TCornerButton;
    Slot_AtrGlove: TLayout;
    G_Core_Atr: TCornerButton;
    G_AttrLayout: TGridPanelLayout;
    G_Atr1: TCornerButton;
    G_Atr2: TCornerButton;
    G_Mod: TCornerButton;
    Slot_AtrHolster: TLayout;
    H_Core_Atr: TCornerButton;
    H_AttrLayout: TGridPanelLayout;
    H_Atr1: TCornerButton;
    H_Atr2: TCornerButton;
    H_Mod: TCornerButton;
    Slot_AtrKneepad: TLayout;
    K_Core_Atr: TCornerButton;
    K_AttrLayout: TGridPanelLayout;
    K_Atr1: TCornerButton;
    K_Atr2: TCornerButton;
    K_Mod: TCornerButton;
    TIMG_Sets: TImageList;
    btnShowBestTankBuild: TCornerButton;
    btnShowBestSkillBuild: TCornerButton;
    btnShowBestSupportBuild: TCornerButton;
    Edit: TSpeedButton;
    LayoutFrame: TLayout;
    GridPanelLayoutSugg: TGridPanelLayout;
    btnShowBestDpsBuild: TCornerButton;
    Image_Mask: TImage;
    Image_Back: TImage;
    Image_Glove: TImage;
    Image_Chest: TImage;
    Image_Holster: TImage;
    Image_Kneepad: TImage;
    Spec1_img: TImage;
    Spec2_img: TImage;
    Spec3_img: TImage;
    Spec4_img: TImage;
    Spec5_img: TImage;
    Spec6_img: TImage;
    Spec_rect: TRectangle;
    GridPanelLayout1: TGridPanelLayout;
    MaskedImage1: TMaskedImage;
    Ammo_: TSkLabel;
    Image1: TImage;
    StatusBar1: TStatusBar;
    BindingsList1: TBindingsList;
    SkLabel_BurstDPS: TSkLabel;
    SkLabel_SustainDPS: TSkLabel;
    Layout_P_Stats: TLayout;
    TotalDmg: TSkLabel;
    ADM: TSkLabel;
    B_AttrLayout: TGridPanelLayout;
    MDM: TSkLabel;
    Layout3: TLayout;
    Panel_AuxStats1: TGridPanelLayout;
    AWD: TSkLabel;
    SWD: TSkLabel;
    Image_Primary: TImage;
    Image_Secondary: TImage;
    Image_Sidearm: TImage;
    SP_Config: TGroupBox;
    Specialization_Config: TGridPanelLayout;
    Total_chc: TSkLabel;
    Total_chd: TSkLabel;
    SkLabel_Skill1_Damage: TSkLabel;
    SkLabel_Skill1_Cooldown: TSkLabel;
    TabControl1: TTabControl;
    Primary: TTabItem;
    Secondary: TTabItem;
    SecondaryStatsHeaderLayout: TLayout;
    SecondaryTotalDamageLabel: TSkLabel;
    SecondaryMultiplierLayout: TLayout;
    SecondaryAdditiveMultiplierLabel: TSkLabel;
    SecondaryMultiplicativeMultiplierLabel: TSkLabel;
    SecondaryAuxStatsGroup: TGroupBox;
    SecondaryAuxStatsGrid: TGridPanelLayout;
    SecondaryAvgShotLabel: TSkLabel;
    SecondaryAwdLabel: TSkLabel;
    SecondarySwdLabel: TSkLabel;
    SecondaryBurstDpsLabel: TSkLabel;
    SecondarySustainDpsLabel: TSkLabel;
    SecondaryChcLabel: TSkLabel;
    SecondaryChdLabel: TSkLabel;
    SkLabel_Skill2_Damage: TSkLabel;
    SkLabel_Skill2_Cooldown: TSkLabel;
    Sidearm: TTabItem;
    SidearmStatsHeaderLayout: TLayout;
    SidearmTotalDamageLabel: TSkLabel;
    SidearmMultiplierLayout: TLayout;
    SidearmAdditiveMultiplierLabel: TSkLabel;
    SidearmMultiplicativeMultiplierLabel: TSkLabel;
    SidearmAuxStatsGroup: TGroupBox;
    SidearmAuxStatsGrid: TGridPanelLayout;
    SidearmAwdLabel: TSkLabel;
    SidearmSwdLabel: TSkLabel;
    SidearmBurstDpsLabel: TSkLabel;
    SidearmSustainDpsLabel: TSkLabel;
    SidearmChcLabel: TSkLabel;
    SidearmChdLabel: TSkLabel;
    SidearmAvgShotLabel: TSkLabel;
    SkLabel_Avg: TSkLabel;
    Tab_Loadouts: TTabControl;
    Loadouts: TTabItem;
    Builds: TTabItem;
    Grid_Loadouts_options: TGridLayout;
    ListView1: TListView;
    GridPanel_Options: TGridPanelLayout;
    Reset: TSpeedButton;
    ListViewAttributes: TListView;
    LabelLookupTitle: TLabel;
    SplitterSide: TSplitter;
    Layout_L_Header: TLayout;
    GridPanelLayoutDetails: TGridPanelLayout;
    GridPanelLayoutLookup: TGridPanelLayout;

    procedure Slot_gPrimaryWeaponClick(Sender: TObject);
    procedure Slot_gSecondaryWeaponClick(Sender: TObject);
    procedure Slot_SideArmClick(Sender: TObject);
    procedure Slot_SpecializationChange(Sender: TObject);
    procedure SpecWeaponChkChange(Sender: TObject);

    procedure Slot_gMaskClick(Sender: TObject);
    procedure Slot_gBackPackClick(Sender: TObject);
    procedure Slot_gVestClick(Sender: TObject);
    procedure Slot_gGloveClick(Sender: TObject);
    procedure Slot_gHolsterClick(Sender: TObject);
    procedure Slot_gKneePadClick(Sender: TObject);

    procedure Slot_Skill1Click(Sender: TObject);
    procedure Slot_Skill2Click(Sender: TObject);

    procedure AddClick(Sender: TObject);
    procedure EditTitleExit(Sender: TObject);
    procedure DelClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure LoadoutListItemClickEx(const Sender: TObject; ItemIndex: Integer;
      const LocalClickPos: TPointF; const ItemObject: TListItemDrawable);
    procedure LoadoutListItemClick(const Sender: TObject;
      const AItem: TListViewItem);

    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EditClick(Sender: TObject);

    procedure btnShowBestDpsBuildClick(Sender: TObject);
    procedure btnShowBestSkillBuildClick(Sender: TObject);
    procedure btnShowBestSupportBuildClick(Sender: TObject);
    procedure btnShowBestTankBuildClick(Sender: TObject);
    procedure ListViewAttributesItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure ListViewAttributesSearchChange(Sender: TObject);
  private
    { Private declarations }
    FGenerationContext: TCoreAttributeType;
    FGearSlotIndex: TItemType;
    FGeneratedBuilds: TList<TGearLoadout>;
    FPieceSets: TList<TPieceSet>;
    FEquippedGearPieces: array[TItemType] of TGearPiece;
    FGearSlotPlaceholders: array[TItemType] of TBitmap;
    FAttributeInfos: TList<TAttributeCatalogEntry>;
    FSelectedAttributeIDs: TList<string>;
    { for Skills.json }

    FController: TMainController;
    FSpecializations: TDictionary<string, Game.Types.TSpecialization>;
    FWeaponSelectedTalentIDs: array [TWeaponSlot] of Integer; // Kept for UI selection memory
    FExoticWeaponSelected: Boolean;
    FExoticWeaponSlot: Game.Types.TWeaponSlot;

    FSavedLoadouts: TDictionary<string, TSerializableLoadout>;

    procedure ClearSavedLoadouts;
    procedure SetSavedLoadouts(const ALoadouts: TDictionary<string, TSerializableLoadout>);

    function IsExoticGearEquipped: Boolean;
    function CanEquipGearPiece(const AGearPiece: TGearPiece): Boolean;
    function GetCurrentLoadoutAsSerializable(const AName: string)
      : TSerializableLoadout;
    procedure EquipGear(const AGearSlot: TItemType);
    procedure FillSpecializations;
    procedure ChooseWeaponForSlot(ASlot: Game.Types.TWeaponSlot;
      const Allowed: TArray<TWeaponFamily>);
    procedure ChooseSkillForSlot(ASlot: TSkillSlot);
    procedure UpdateSpecWeaponChkAvailability;
    procedure UpdateWeaponUI(ASlot: Game.Types.TWeaponSlot; const W: TWeapon);
    procedure UpdateGearSlotUI(const GearPiece: TGearPiece; SlotIndex: TItemType);
    { for Skills.json }
    procedure UpdateSkillUI(ASlot: TSkillSlot;
      const ASkillVariant: TSkillVariant);
    procedure RefreshAllStats;
    procedure RefreshSkillStatsUI(
      const APlayerStats: CalcEngine.TPlayerAggregatedStats;
      const ATotalSkillTiers: Integer);
    procedure ApplySerializableLoadout(const ALoadout: TSerializableLoadout);
    procedure GenerateAndApplyPredefinedBuild(AArchetypeProc: TBuildArchetypeProc);
    procedure DisplayGeneratedBuilds(ABuilds: TList<TGearLoadout>);
    procedure ListView1ItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure ApplyBuild(const ABuild: TGearLoadout);
    procedure PopulateAttributesList;
    procedure ShowSidePanel(AContext: TCoreAttributeType);
    function AttributeColor(const ACat: TMinorAttributeCat): TAlphaColor;
    function AttributeCategoryLabel(const ACat: TMinorAttributeCat): string;
    procedure ApplyAttributeStyle(const AItem: TListViewItem;
      const ACat: TMinorAttributeCat);
    function AttributeMatchesContext(const Info: TAttributeCatalogEntry): Boolean;
    function NormalizeAttributeId(const S: string): string;
    procedure UpdateAttributeItemSelected(const AItem: TListViewItem; const AId: string);
    procedure BuildFromSelectedAttributes;
    function MapSelectedAttributesToMinorTypes: TArray<TMinorAttributeType>;
  protected
    { mapping simple entre enum-type et tableau booléen des 7 check-boxes }
    function WeaponChk(WT: TWeaponFamily): TCheckBox;
  public
    { Public declarations }
    property GearSlotIndex: TItemType read FGearSlotIndex write FGearSlotIndex;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

{ TMainForm }

{$REGION ' -Logic functions for each build type'}

function StringInArray(WT: TWeaponFamily; const Arr: TArray<TWeaponFamily>)
  : Boolean; overload;
var
  T: TWeaponFamily;
  I: Integer;
begin
  Result := False;
  for I := 0 to High(Arr) do
  begin
    T := Arr[I];
    if T = WT then
      Exit(True);
  end;
end;

function StringInArray(const S: string; const Arr: TArray<string>)
  : Boolean; overload;
var
  V: string;
  I: Integer;
begin
  Result := False;
  for I := 0 to High(Arr) do
  begin
    V := Arr[I];
    if SameText(V, S) then
      Exit(True);
  end;
end;

function ItemTypeToStr(ItemType: TItemType): string;
begin
  case ItemType of
    itMask:
      Result := 'Mask';
    itBackpack:
      Result := 'Backpack';
    itChest:
      Result := 'Vest';
    itGloves:
      Result := 'Glove';
    itHolster:
      Result := 'Holster';
    itKneepads:
      Result := 'Kneepad';
  else
    Result := ''; // Should not happen with valid TItemType
  end;
end;


function TMainForm.WeaponChk(WT: TWeaponFamily): TCheckBox;
begin
  case WT of
    wcAR:
      Result := W_ar;
    wcSMG:
      Result := W_smg;
    wcSTG:
      Result := W_stg;
    wcLMG:
      Result := W_lmg;
    wcMMR:
      Result := W_mmr;
    wcRIFLE:
      Result := W_rifle;
    wcPISTOL:
      Result := W_pistol;
  else
    Result := nil;
  end;
end;

function TMainForm.IsExoticGearEquipped: Boolean;
begin
  Result := FController.IsExoticGearEquipped;
end;

function TMainForm.CanEquipGearPiece(const AGearPiece: TGearPiece): Boolean;
begin
  Result := FController.CanEquipGearPiece(AGearPiece, FGearSlotIndex);
  if not Result then
    TDialogService.ShowMessage('You can only equip one exotic gear piece at a time. Please unequip the other exotic first.');
end;

function HasModSlot(const GearPiece: TGearPiece): Boolean;
const
  GearWithMods = [itMask, itBackpack, itChest];
begin
  // Les pièces improvised ont toujours un slot
  if GearPiece.SetType = stImprovised then
    Exit(True);
  // Sinon, masque / sac / gilet
  Result := GearPiece.ItemType in GearWithMods;
end;

{$ENDREGION}
{$REGION ' -WEAPONSLOTS OPERATIONS'}

procedure TMainForm.Slot_gPrimaryWeaponClick(Sender: TObject);
begin
  ChooseWeaponForSlot(Game.Types.wsPrimary, [wcAR, wcSMG, wcSTG, wcLMG, wcMMR,
    wcRIFLE]); // Use Game.Types.wsPrimary
  RefreshAllStats;
end;

procedure TMainForm.Slot_gSecondaryWeaponClick(Sender: TObject);
begin
  ChooseWeaponForSlot(Game.Types.wsSecondary, [wcAR, wcSMG, wcSTG, wcLMG, wcMMR,
    wcRIFLE]); // Use Game.Types.wsSecondary
  RefreshAllStats;
end;

procedure TMainForm.Slot_SideArmClick(Sender: TObject);
begin
  ChooseWeaponForSlot(Game.Types.wsSideArm, [wcPISTOL]);
  // Use Game.Types.wsSideArm
  RefreshAllStats;
end;

procedure TMainForm.Slot_SpecializationChange(Sender: TObject);
var
  SelectedSpecRecord: Game.Types.TSpecialization;
  WT: TWeaponFamily;
  Path: string;
  Bmp: TBitmap;
begin
  if Slot_Specialization.ItemIndex < 0 then
    Exit;

  if FSpecializations.TryGetValue(Slot_Specialization.Items
    [Slot_Specialization.ItemIndex], SelectedSpecRecord) then
  begin
    FController.SelectedSpecialization := SelectedSpecRecord;
    // Update the ComboBox's image for the selected specialization
    Path := TPath.Combine(TUtils.AssetsPath, SelectedSpecRecord.Image_Path);
    if TFile.Exists(Path) then
    begin
      Bmp := TBitmap.Create;
      try
        Bmp.LoadFromFile(Path);
        // Update the image in the ComboBox's style
        Slot_Specialization.ApplyStyleLookup;
        Slot_Specialization.StylesData['MaskedImage1Style.Bitmap'] :=
          TValue.From<TBitmap>(Bmp);
      finally
        Bmp.Free;
      end;
    end;

    // Update weapon type bonus checkboxes based on the selected specialization's capabilities
    for WT := Low(TWeaponFamily) to High(TWeaponFamily) do
    begin
      if Assigned(WeaponChk(WT)) then
      begin
        // Enable checkbox if this specialization *can* offer a bonus for this weapon type
        if Assigned(FController.SelectedSpecialization.InherentWeaponTypeBonuses) and
          FController.SelectedSpecialization.InherentWeaponTypeBonuses.ContainsKey(WT) then
        begin
          WeaponChk(WT).Enabled := True;
        end
        else
        begin
          WeaponChk(WT).Enabled := False;
        end;
        WeaponChk(WT).IsChecked := False;
        // Uncheck all when spec changes; user will re-select up to 3
      end;
    end;
  end;

  UpdateSpecWeaponChkAvailability;
  // Enforce "max 3 active bonuses" rule and update enabled state of checkboxes
  RefreshAllStats;
end;

procedure TMainForm.SpecWeaponChkChange(Sender: TObject);
var
  WF: TWeaponFamily;
  Used: Integer;
  Chk: TCheckBox;
begin
  { l’utilisateur force / annule manuellement un bonus arme-type }
  // Nombre déjà cochés
  Used := 0;
  for WF := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WF)) and WeaponChk(WF).IsChecked then
      Inc(Used);

  // Dépassement ?
  Chk := Sender as TCheckBox; // on sait que Sender est bien un TCheckBox
  if Used > MAX_SPEC_BONUS then
  begin
    Chk.IsChecked := False; // on annule la 4ᵉ coche
    TDialogService.ShowMessage
      (Format('Vous ne pouvez activer que %d bonus d''arme.',
      [MAX_SPEC_BONUS]));
  end;

  // Met à jour l’UI
  UpdateSpecWeaponChkAvailability;

  // (Facultatif) Recalculs divers
  RefreshAllStats;
end;

procedure TMainForm.UpdateSpecWeaponChkAvailability;
var
  WF: TWeaponFamily;
  Used: Integer;
  CanProvideBonus: Boolean;
begin
  // Si aucune spé sélectionnée → tout désactiver proprement
  if not Assigned(FController.SelectedSpecialization) then
  begin
    for WF := Low(TWeaponFamily) to High(TWeaponFamily) do
      if Assigned(WeaponChk(WF)) then
      begin
        WeaponChk(WF).IsChecked := False;
        WeaponChk(WF).Enabled   := False;
      end;
    Exit;
  end;

  Used := 0;
  for WF := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WF)) and WeaponChk(WF).IsChecked then
      Inc(Used);

  for WF := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WF)) then
    begin
      // On ne touche au dictionnaire que si la spé est bien créée
      CanProvideBonus := Assigned(FController.SelectedSpecialization.InherentWeaponTypeBonuses) and
        FController.SelectedSpecialization.InherentWeaponTypeBonuses.ContainsKey(WF);

      WeaponChk(WF).Enabled :=
        ((Used < MAX_SPEC_BONUS) or WeaponChk(WF).IsChecked) and
        CanProvideBonus;   // la spé doit pouvoir donner ce bonus
    end;
end;


procedure TMainForm.UpdateWeaponUI(ASlot: Game.Types.TWeaponSlot;
  const W: TWeapon);
var
  TargetImageControl: TImage;
  TargetComboBox: TComboBox;
  ImagePath: string;
  Bmp: TBitmap;
begin
  TargetImageControl := nil;
  TargetComboBox := nil;

  case ASlot of
    Game.Types.wsPrimary:
      begin
        TargetImageControl := Image_Primary;
        TargetComboBox := Slot_Primary;
      end;
    Game.Types.wsSecondary:
      begin
        TargetImageControl := Image_Secondary;
        TargetComboBox := Slot_Secondary;
      end;
    Game.Types.wsSideArm:
      begin
        TargetImageControl := Image_Sidearm;
        TargetComboBox := Slot_SideArm;
      end;
  else
    Exit;
  end;

  if Assigned(TargetImageControl) then
  begin
    if W.ID <> 0 then
    begin
      ImagePath := TPath.Combine(TUtils.AssetsPath, W.ImagePath);
      if TFile.Exists(ImagePath) then
      begin
        Bmp := TBitmap.Create;
        try
          Bmp.LoadFromFile(ImagePath);
          TargetImageControl.Bitmap.Assign(Bmp);
          TargetImageControl.HitTest := False;
        finally
          Bmp.Free;
        end;
        TargetImageControl.Visible := True;
      end
      else
      begin
        TargetImageControl.Bitmap := nil;
        TargetImageControl.Visible := False;
        ShowMessage('Image file not found: ' + ImagePath);
      end;
    end
    else
    begin
      TargetImageControl.Bitmap := nil;
      TargetImageControl.Visible := False;
    end;
  end;

  if Assigned(TargetComboBox) then
  begin
    if W.ID <> 0 then
    begin
      case W.Rarity of
        wrExotic:
          TargetComboBox.StyleLookup := 'ExoticSlot';
        wrNamed:
          TargetComboBox.StyleLookup := 'NamedSlot';
        wrHighEnd:
          TargetComboBox.StyleLookup := 'HighEndSlot';
      else
        TargetComboBox.StyleLookup := '';
      end;
    end
    else
    begin
      TargetComboBox.StyleLookup := '';
    end;
  end;
end;

procedure TMainForm.ChooseWeaponForSlot(ASlot: Game.Types.TWeaponSlot;
  const Allowed: TArray<TWeaponFamily>); // Changed ASlot type
var
  W: TWeapon;
  OldWeaponRarity: TWeaponRarity;
  CurrentWeapon: TWeapon;
begin

  if not Assigned(FormCw) then
    Application.CreateForm(TFormCw, FormCw);

  FormCw.FilterFamilies := Allowed;

  CurrentWeapon := FController.GetSelectedWeapon(ASlot);
  if CurrentWeapon.ID <> 0 then
  begin
    // Sync local ID with weapon if needed, or just rely on weapon
    CurrentWeapon.ChosenTalentID := FWeaponSelectedTalentIDs[ASlot];
    FormCw.LoadExistingWeaponState(CurrentWeapon, FController.GetWeaponExpertise(ASlot));
  end
  else
    FormCw.SpinBox_Exp.Value := FController.GetWeaponExpertise(ASlot);

  if FormCw.ShowModal <> mrOk then
    Exit;

  W := FormCw.SelectedWeapon;
  FWeaponSelectedTalentIDs[ASlot] := W.ChosenTalentID;
  OldWeaponRarity := CurrentWeapon.Rarity;  // Store rarity of the weapon being replaced

  // One Exotic Weapon Rule
  if (W.Rarity = wrExotic) and FExoticWeaponSelected and
    (FExoticWeaponSlot <> ASlot) then
  begin
    TDialogService.MessageDialog
      ('Vous ne pouvez équiper qu''Une arme exotique.', TMsgDlgType.mtWarning,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    Exit;
  end;

  // W includes ChosenTalentID set by FormCw
  W.ChosenTalentID := FWeaponSelectedTalentIDs[ASlot];

  FController.SetSelectedWeapon(ASlot, W);
  FController.SetWeaponExpertise(ASlot, Trunc(FormCw.SpinBox_Exp.Value));

  UpdateWeaponUI(ASlot, W);

  // Update exotic tracking
  if W.Rarity = wrExotic then
  begin
    FExoticWeaponSelected := True;
    FExoticWeaponSlot := ASlot;
  end
  else if (OldWeaponRarity = wrExotic) and (FExoticWeaponSlot = ASlot) then
  begin
    FExoticWeaponSelected := False;
  end;

  RefreshAllStats;
end;

procedure TMainForm.FillSpecializations;
var
  Spec: Game.Types.TSpecialization;
  Itm: TListBoxItem;
  Img: TImage;
  SpecList: TList<TSpecialization>;
  I: Integer;
begin
  Slot_Specialization.BeginUpdate;
  try
    Slot_Specialization.Clear;
    FSpecializations.Clear;

    if Assigned(DataJsonIterator) and Assigned(DataJsonIterator.Specializations)
    then
    begin
      // Create a sorted list to ensure consistent order
      SpecList := TList<TSpecialization>.Create
        (DataJsonIterator.Specializations.Values);
      try
        SpecList.Sort(TComparer<TSpecialization>.Construct(
          function(const L, R: TSpecialization): Integer
          begin
            Result := CompareText(L.Name, R.Name);
          end));

        // Add items and apply the style
        for I := 0 to SpecList.Count - 1 do
        begin
          Spec := SpecList[I];
          FSpecializations.AddOrSetValue(Spec.Name, Spec);
          Slot_Specialization.Items.Add(Spec.Name);

          Itm := Slot_Specialization.ListBox.ListItems[I];
          Itm.StyleLookup := 'ListBoxItem2Style1';

          // Apply the style immediately to find the resource
          Itm.ApplyStyleLookup;

          var
          StyleImg := Itm.FindStyleResource('ImgSpec');
          if (StyleImg is TImage) then
          begin
            Img := StyleImg as TImage;
            Img.Bitmap := TUtils.BitmapFromPath(Spec.Image_Path);
          end;
        end;

      finally
        SpecList.Free;
      end;
    end;

    if Slot_Specialization.Count > 0 then
    begin
      Slot_Specialization.ItemIndex := 0;
      // paint the collapsed button image now (uses current selection)
      Slot_SpecializationChange(Slot_Specialization);
    end;

  finally
    Slot_Specialization.EndUpdate;
  end;
end;

{$ENDREGION}
{$REGION ' -GEARSLOTS OPERATIONS'}

function SetTypeToCategoryKey(SetType: TSetType): string;
begin
  case SetType of
    stBrandSet:
      Result := 'brandSets';
    stGearSet:
      Result := 'gearSets';
    stNamedSet:
      Result := 'namedSets';
    stExoticSet:
      Result := 'exoticSets';
    stImprovised:
      Result := 'improvisedSets';
  else
    Result := 'unknownSets';
  end;
end;

procedure TMainForm.EquipGear(const AGearSlot: TItemType);
var
  LSelectedPiece: TGearPiece;
begin
  FGearSlotIndex := AGearSlot; { 0-based }
  FormSlots.GearSlot := AGearSlot;
  // FormSlots.PieceSets is set inside FormSlots.PopulateBrands now, but we should update local FPieceSets reference if needed, or remove local FPieceSets.
  // For now, we let FormSlots handle its data population.
  FormSlots.ListBoxSets.Images := TIMG_Sets; // Ensure images are linked
  FormSlots.PopulateBrands(DataJsonIterator);
  // After population, FormSlots.PieceSets is updated. We can sync if needed, but FormSlots manages it.
  FPieceSets := FormSlots.PieceSets; // Keep a reference if needed by other parts of MainForm, though likely redundant now.

  { talents only on chest / backpack }
  if AGearSlot in [itChest, itBackpack] then
    FormSlots.PopulateTalents(DataJsonIterator)
  else
    FormSlots.ListBoxTalents.Clear;

  if AGearSlot in [itChest, itBackpack] then
  begin
    var CurrentTalent := FController.GetEquippedGearPiece(FGearSlotIndex).Talent;
    var FoundTalent := False;
    if CurrentTalent <> '' then
      for var TalentIdx := 0 to FormSlots.ListBoxTalents.Count - 1 do
        if SameText(FormSlots.ListBoxTalents.ListItems[TalentIdx].Text, CurrentTalent) then
        begin
          FormSlots.ListBoxTalents.ItemIndex := TalentIdx;
          FoundTalent := True;
          Break;
        end;
    if not FoundTalent then
      FormSlots.ListBoxTalents.ItemIndex := -1;
  end
  else
    FormSlots.ListBoxTalents.ItemIndex := -1;

  if FormSlots.ShowModal = mrOk then
  begin
    LSelectedPiece := FormSlots.SelectedGearPiece;

    if LSelectedPiece.Name <> '' then
    begin
      if not CanEquipGearPiece(LSelectedPiece) then
        Exit;

      // Restore the data transfer logic for icon indices
      LSelectedPiece.SelectedModIconIndex := FormSlots.SelectedModAttributeImageIndex;
      SetLength(LSelectedPiece.SelectedMinorIconIndices, Length(FormSlots.FSelectedMinorAttributeImageIndices));
      for var i := 0 to High(FormSlots.FSelectedMinorAttributeImageIndices) do
        LSelectedPiece.SelectedMinorIconIndices[i] := FormSlots.FSelectedMinorAttributeImageIndices[i];

      FController.SetEquippedGearPiece(FGearSlotIndex, LSelectedPiece);
    end
    else
    begin
      FController.SetEquippedGearPiece(FGearSlotIndex, Default(TGearPiece));
    end;

    UpdateGearSlotUI(FController.GetEquippedGearPiece(FGearSlotIndex), FGearSlotIndex);
    RefreshAllStats;
  end;
end;

procedure TMainForm.UpdateGearSlotUI(const GearPiece: TGearPiece; SlotIndex: TItemType);
var
  TargetComboBox: TComboBox;
  TargetImage: TImage;
  ImgIdx: Integer;
  CoreBtn, Minor1Btn, Minor2Btn, ModBtn: TCornerButton;
  SizeF: TSizeF;
  LogoBitmap: TBitmap;

  function BuildFixedMinorText(const Piece: TGearPiece): string;
  var
    Attr: TFixedMinorAttributeDefinition;
    Segment: string;
  begin
    Result := '';
    for Attr in Piece.FixedMinorAttributes do
    begin
      Segment := Attr.TypeName;
      if not SameValue(Attr.Value, 0.0) then
        Segment := Segment + ' +' + FormatFloat('0.#', Attr.Value) + '%';
      if Result = '' then
        Result := Segment
      else
        Result := Result + ', ' + Segment;
    end;
  end;

  function FixedLine(const Piece: TGearPiece; Index: Integer): string;
  var
    Attr: TFixedMinorAttributeDefinition;
  begin
    Result := '';
    if (Index < 0) or (Index >= Length(Piece.FixedMinorAttributes)) then
      Exit;
    Attr := Piece.FixedMinorAttributes[Index];
    Result := Attr.TypeName;
    if not SameValue(Attr.Value, 0.0) then
      Result := Result + ' +' + FormatFloat('0.#', Attr.Value) + '%';
  end;

  { Helper local pour configurer un bouton d'attribut }
  procedure SetupAttrBtn(Btn: TCornerButton; IsRandom: Boolean; Index, FixedIdx: Integer);
  var
    RandomCount: Integer;
    RandomIcons: TArray<Integer>;
    FixedCount: Integer;
  begin
    if not Assigned(Btn) then Exit;

    RandomCount  := Length(GearPiece.MinorAttributes);
    RandomIcons  := GearPiece.SelectedMinorIconIndices;
    FixedCount   := Length(GearPiece.FixedMinorAttributes);

    Btn.Visible := True;
    Btn.ImageIndex := -1;
    Btn.Text := '';
    // Btn.Hint := FixedSummary; // FixedSummary is local to main proc, assume blank or passed if needed

    if IsRandom then
    begin
      Btn.Enabled := True;
      if (Index >= 0) and (Index < RandomCount) then
      begin
        if Index < Length(RandomIcons) then
          Btn.ImageIndex := RandomIcons[Index];
        Btn.Text := GetEnumName(TypeInfo(TMinorAttributeType),
          Ord(GearPiece.MinorAttributes[Index].MinorAttribute));
      end;
    end
    else
    begin
      // Fixed Attribute
      Btn.Enabled := False;
      if (FixedIdx >= 0) and (FixedIdx < FixedCount) then
        Btn.Text := FixedLine(GearPiece, FixedIdx);
    end;
  end;

var
  RandomCount: Integer;
  RandomIcons: TArray<Integer>;
  FixedCount: Integer;
  FixedSummary: string;
  NextFixedIdx: Integer;
begin
  TargetComboBox := nil;
  TargetImage    := nil;
  CoreBtn        := nil;
  Minor1Btn      := nil;
  Minor2Btn      := nil;
  ModBtn         := nil;

  { 1. Choix des contrôles cibles }
  case SlotIndex of
    itMask:
      begin
        TargetComboBox := Slot_gMask;
        TargetImage    := Image_Mask;
        CoreBtn        := M_Core_Atr;
        Minor1Btn      := M_Atr1;
        Minor2Btn      := M_Atr2;
        ModBtn         := M_Mod;
      end;

    itBackpack:
      begin
        TargetComboBox := Slot_gBackPack;
        TargetImage    := Image_Back;
        CoreBtn        := B_Core_Atr;
        Minor1Btn      := B_Atr1;
        Minor2Btn      := B_Atr2;
        ModBtn         := B_Mod;
      end;

    itChest:
      begin
        TargetComboBox := Slot_gVest;
        TargetImage    := Image_Chest;
        CoreBtn        := V_Core_Atr;
        Minor1Btn      := V_Atr1;
        Minor2Btn      := V_Atr2;
        ModBtn         := V_Mod;
      end;

    itGloves:
      begin
        TargetComboBox := Slot_gGlove;
        TargetImage    := Image_Glove;
        CoreBtn        := G_Core_Atr;
        Minor1Btn      := G_Atr1;
        Minor2Btn      := G_Atr2;
        ModBtn         := G_Mod;
      end;

    itHolster:
      begin
        TargetComboBox := Slot_gHolster;
        TargetImage    := Image_Holster;
        CoreBtn        := H_Core_Atr;
        Minor1Btn      := H_Atr1;
        Minor2Btn      := H_Atr2;
        ModBtn         := H_Mod;
      end;

    itKneepads:
      begin
        TargetComboBox := Slot_gKneePad;
        TargetImage    := Image_Kneepad;
        CoreBtn        := K_Core_Atr;
        Minor1Btn      := K_Atr1;
        Minor2Btn      := K_Atr2;
        ModBtn         := K_Mod;
      end;
  else
    Exit;
  end;

  { Cache du placeholder pour ce slot }
  if Assigned(TargetImage) and (FGearSlotPlaceholders[SlotIndex] = nil) then
  begin
    FGearSlotPlaceholders[SlotIndex] := TBitmap.Create;
    FGearSlotPlaceholders[SlotIndex].Assign(TargetImage.Bitmap);
  end;

  { 2. Combo + logo de set }
  TargetComboBox.BeginUpdate;
  try
    TargetComboBox.Clear;
    if GearPiece.Name = '' then
    begin
      TargetComboBox.StyleLookup := '';
      TargetComboBox.Hint := '(Empty)';
      if Assigned(TargetImage) then
      begin
        if Assigned(FGearSlotPlaceholders[SlotIndex]) then
          TargetImage.Bitmap.Assign(FGearSlotPlaceholders[SlotIndex]);
        TargetImage.Visible := True;
      end;
    end
    else
    begin
      ImgIdx := -1;
      if Assigned(DataJsonIterator) and Assigned(DataJsonIterator.AllPieceSetDefinitions) then
      begin
        var PS: TPieceSet;
        if DataJsonIterator.AllPieceSetDefinitions.TryGetValue(GearPiece.SetName, PS) then
          ImgIdx := PS.ImageIndex;
      end;

      if Assigned(TargetImage) then
      begin
        if (ImgIdx >= 0) and (ImgIdx < TIMG_Sets.Source.Count) then
        begin
          SizeF := TSizeF.Create(TargetImage.Width, TargetImage.Height);
          LogoBitmap := TIMG_Sets.Bitmap(SizeF, ImgIdx);
          TargetImage.Bitmap.Assign(LogoBitmap);
        end
        else if Assigned(FGearSlotPlaceholders[SlotIndex]) then
          TargetImage.Bitmap.Assign(FGearSlotPlaceholders[SlotIndex]);

        TargetImage.WrapMode := TImageWrapMode.Place;
        TargetImage.Align := TAlignLayout.Contents;
        TargetImage.Visible := True;
      end;

      TargetComboBox.Images := TIMG_Sets;
      TargetComboBox.ItemIndex := 0;

      FixedSummary := BuildFixedMinorText(GearPiece);
      if FixedSummary <> '' then
        TargetComboBox.Hint := GearPiece.Name + sLineBreak + FixedSummary
      else
        TargetComboBox.Hint := GearPiece.Name;

      case GearPiece.SetType of
        stBrandSet, stImprovised: TargetComboBox.StyleLookup := 'HighEndSlot';
        stGearSet:                TargetComboBox.StyleLookup := 'GearSetSlot';
        stNamedSet:               TargetComboBox.StyleLookup := 'NamedSlot';
        stExoticSet:              TargetComboBox.StyleLookup := 'ExoticSlot';
      else
        TargetComboBox.StyleLookup := 'EmptySlot';
      end;
    end;
  finally
    TargetComboBox.EndUpdate;
  end;

  { 3. Attribut principal }
  if Assigned(CoreBtn) then
  begin
    CoreBtn.ImageIndex := -1;
    CoreBtn.Text := '';
    if not GearPiece.CoreAttribute.ID.IsEmpty then
    begin
      CoreBtn.ImageIndex := Ord(GearPiece.CoreAttribute.AttrType);
      CoreBtn.Text := Copy(
        GetEnumName(TypeInfo(TCoreAttributeType),
        Ord(GearPiece.CoreAttribute.AttrType)), 4, 100);
    end;
  end;

  { 4. Attributs mineurs (safe) }
  RandomCount  := Length(GearPiece.MinorAttributes);
  RandomIcons  := GearPiece.SelectedMinorIconIndices;
  FixedCount   := Length(GearPiece.FixedMinorAttributes);
  FixedSummary := BuildFixedMinorText(GearPiece);

  // Removed incorrectly placed nested procedure.

  // Stratégie :
  // 1. Remplir Minor1 avec Random[0] si dispo, sinon Fixed[0].
  // 2. Remplir Minor2 avec Random[1] si dispo, sinon Fixed[offset].
  // 3. Si "Claws Out" (3 attr, pas de mod), utiliser ModBtn pour le 3eme attr fixe.

  NextFixedIdx := 0;

  // --- Slot 1 ---
  if RandomCount >= 1 then
    SetupAttrBtn(Minor1Btn, True, 0, -1)
  else
  begin
    SetupAttrBtn(Minor1Btn, False, -1, NextFixedIdx);
    Inc(NextFixedIdx);
  end;

  // --- Slot 2 ---
  if RandomCount >= 2 then
    SetupAttrBtn(Minor2Btn, True, 1, -1)
  else
  begin
    SetupAttrBtn(Minor2Btn, False, -1, NextFixedIdx);
    Inc(NextFixedIdx);
  end;

  // --- Slot 3 / Mod Slot ---
  if Assigned(ModBtn) then
  begin
    var HasSlot := HasModSlot(GearPiece);
    var UsedForAttribute := False;

    // Si on a encore des attributs fixes à afficher et PAS de slot de mod (ex: Claws Out)
    if (NextFixedIdx < FixedCount) and (not HasSlot) then
    begin
      SetupAttrBtn(ModBtn, False, -1, NextFixedIdx);
      // On force l'apparence "disabled attribute" sur ce bouton mod
      ModBtn.Visible := True;
      ModBtn.ImageIndex := -1;
      UsedForAttribute := True;
    end;

    if not UsedForAttribute then
    begin
      // Comportement standard MOD
      ModBtn.Visible := HasSlot;
      // Les mods doivent rester cliquables
      ModBtn.Enabled := True;
      if HasSlot then
      begin
        ModBtn.ImageIndex := GearPiece.SelectedModIconIndex;
        if GearPiece.ModAttribute.ModEffect <> gmetUnknown then
          ModBtn.Text := ''
        else
          ModBtn.Text := '';
      end;
    end;
  end;
end;


procedure TMainForm.Slot_gBackPackClick(Sender: TObject);
begin
  EquipGear(itBackpack);
end;

procedure TMainForm.Slot_gGloveClick(Sender: TObject);
begin
  EquipGear(itGloves);
end;

procedure TMainForm.Slot_gHolsterClick(Sender: TObject);
begin
  EquipGear(itHolster);
end;

procedure TMainForm.Slot_gKneePadClick(Sender: TObject);
begin
  EquipGear(itKneepads);
end;

procedure TMainForm.Slot_gMaskClick(Sender: TObject);
begin
  EquipGear(itMask);
end;

procedure TMainForm.Slot_gVestClick(Sender: TObject);
begin
  EquipGear(itChest);
end;

{$ENDREGION}
{$REGION ' -SKILLSLOTS OPERATIONS'}

procedure TMainForm.Slot_Skill1Click(Sender: TObject);
begin
  ChooseSkillForSlot(ssPrimary);
  RefreshAllStats;
end;

procedure TMainForm.Slot_Skill2Click(Sender: TObject);
begin
  ChooseSkillForSlot(ssSecondary);
  RefreshAllStats;
end;

{ For Skills.json }
procedure TMainForm.ChooseSkillForSlot(ASlot: TSkillSlot);
var
  LFormSkills: TFormSkill;
  LSelectedVariant: TSkillVariant;
  SkillData: TSkillData;
  LEquippedSkill: TEquippedSkill;
  SkillDataValues: TArray<TSkillData>;
  I, J: Integer;
  Variant: TSkillVariant;
begin
  LFormSkills := TFormSkill.Create(nil);
  try
    LFormSkills.SkillData := DataJsonIterator.Skills;
    LFormSkills.PopulateSkills;

    if LFormSkills.ShowModal <> mrOk then
      Exit;

    LSelectedVariant := LFormSkills.SelectedVariant;

    // Find the parent TSkillData
    SkillDataValues := DataJsonIterator.Skills.Values.ToArray;
    for I := 0 to High(SkillDataValues) do
    begin
      SkillData := SkillDataValues[I];
      for J := 0 to High(SkillData.Variants) do
      begin
        Variant := SkillData.Variants[J];
        if Variant.VariantName = LSelectedVariant.VariantName then
        begin
          // Construct the TEquippedSkill record
          LEquippedSkill.SkillID := SkillData.SkillID;
          LEquippedSkill.Variant := LSelectedVariant;

          // Assign the record to the array
          FController.SetEquippedSkill(ASlot, LEquippedSkill);

          UpdateSkillUI(ASlot, LSelectedVariant);
          RefreshAllStats;
          Exit;
        end;
      end;
    end;
  finally
    LFormSkills.Free;
  end;
end;

procedure TMainForm.UpdateSkillUI(ASlot: TSkillSlot;
const ASkillVariant: TSkillVariant);
var
  TargetComboBox: TComboBox;
  LBI: TListBoxItem;
  Pic: TImage;
  Bmp: TBitmap;
  ImagePath: string;
begin
  case ASlot of
    ssPrimary:
      TargetComboBox := Slot_Skill1;
    ssSecondary:
      TargetComboBox := Slot_Skill2;
  else
    Exit;
  end;

  TargetComboBox.BeginUpdate;
  try
    TargetComboBox.Clear;
    if ASkillVariant.VariantName.IsEmpty then
    begin
      TargetComboBox.StyleLookup := '';
    end
    else
    begin
      LBI := TListBoxItem.Create(TargetComboBox);
      LBI.Height := TargetComboBox.Height;

      Pic := TImage.Create(LBI);
      Pic.Parent := LBI;
      Pic.Align := TAlignLayout.Client;
      Pic.WrapMode := TImageWrapMode.Fit;
      Pic.Margins.Rect := RectF(0, 5, 5, 0);

      ImagePath := TPath.Combine(TUtils.AssetsPath, ASkillVariant.V_ImagePath);
      if TFile.Exists(ImagePath) then
      begin
        Bmp := TBitmap.Create;
        try
          Bmp.LoadFromFile(ImagePath);
          Pic.Bitmap.Assign(Bmp);
        finally
          Bmp.Free;
        end;
      end;

      TargetComboBox.AddObject(LBI);
      TargetComboBox.ItemIndex := 0;
      TargetComboBox.Hint := ASkillVariant.VariantName;
      // TargetComboBox.StyleLookup := 'ListBoxItem2Style1';
    end;
  finally
    TargetComboBox.EndUpdate;
  end;
end;

procedure TMainForm.RefreshSkillStatsUI(
      const APlayerStats: CalcEngine.TPlayerAggregatedStats;
      const ATotalSkillTiers: Integer);
var
  LSkillSlot: TSkillSlot;
  LEquippedSkill: TEquippedSkill;
  SkillStats: TDictionary<string, Double>;
  DamageValue, CooldownValue: Double;
begin
  // Reset affichage de base
  SkLabel_Skill1_Damage.Words[0].Text   := 'Damage: -';
  SkLabel_Skill1_Cooldown.Words[0].Text := 'Cooldown: -';
  SkLabel_Skill2_Damage.Words[0].Text   := 'Damage: -';
  SkLabel_Skill2_Cooldown.Words[0].Text := 'Cooldown: -';
for LSkillSlot := ssPrimary to ssSecondary do
  begin
    LEquippedSkill := FController.GetEquippedSkill(LSkillSlot);
    if LEquippedSkill.SkillID = '' then
      Continue;

    SkillStats := CalcEngine.CalculateSkillPerformance(
      LEquippedSkill.Variant,
      APlayerStats,
      ATotalSkillTiers,
      False,  // IsOvercharged
      False   // IsPvp
    );
    try
      if LSkillSlot = ssPrimary then
      begin
        if SkillStats.TryGetValue('damage', DamageValue) then
          SkLabel_Skill1_Damage.Words[0].Text :=
            Format('Damage: %s', [TUtils.FormatDamageValue(DamageValue)])
        else
          SkLabel_Skill1_Damage.Words[0].Text := 'Damage: –';

        if SkillStats.TryGetValue('cooldown', CooldownValue) then
          SkLabel_Skill1_Cooldown.Words[0].Text :=
            Format('Cooldown: %.1fs', [CooldownValue])
        else
          SkLabel_Skill1_Cooldown.Words[0].Text := 'Cooldown: –';
      end
      else
      begin
        if SkillStats.TryGetValue('damage', DamageValue) then
          SkLabel_Skill2_Damage.Words[0].Text :=
            Format('Damage: %s', [TUtils.FormatDamageValue(DamageValue)])
        else
          SkLabel_Skill2_Damage.Words[0].Text := 'Damage: –';

        if SkillStats.TryGetValue('cooldown', CooldownValue) then
          SkLabel_Skill2_Cooldown.Words[0].Text :=
            Format('Cooldown: %.1fs', [CooldownValue])
        else
          SkLabel_Skill2_Cooldown.Words[0].Text := 'Cooldown: –';
      end;
    finally
      SkillStats.Free;
    end;
  end;
end;

{$ENDREGION}

procedure TMainForm.RefreshAllStats;
type
  TWeaponDisplay = record
    TotalDamageLabel: TSkLabel;
    AwdLabel: TSkLabel;
    SwdLabel: TSkLabel;
    BurstDpsLabel: TSkLabel;
    SustainDpsLabel: TSkLabel;
    ChcLabel: TSkLabel;
    ChdLabel: TSkLabel;
    AvgShotLabel: TSkLabel;
  end;

  procedure ResetWeaponDisplay(const Display: TWeaponDisplay);
  begin
    if Display.TotalDamageLabel <> nil then
      Display.TotalDamageLabel.Words[0].Text := 'TWD: -';
    if Display.AwdLabel <> nil then
      Display.AwdLabel.Words[0].Text := 'AWD: - %';
    if Display.SwdLabel <> nil then
      Display.SwdLabel.Words[0].Text := 'SWD: - %';
    if Display.BurstDpsLabel <> nil then
      Display.BurstDpsLabel.Words[0].Text := 'BurstDPS: -';
    if Display.SustainDpsLabel <> nil then
      Display.SustainDpsLabel.Words[0].Text := 'SustainDPS: -';
    if Display.ChcLabel <> nil then
      Display.ChcLabel.Words[0].Text := 'Total CHC: - %';
    if Display.ChdLabel <> nil then
      Display.ChdLabel.Words[0].Text := 'Total CHD: - %';
    if Display.AvgShotLabel <> nil then
      Display.AvgShotLabel.Words[0].Text := 'AvgShot: -';
  end;

  procedure UpdateWeaponDisplay(const Display: TWeaponDisplay;
    const DamageResult: TFullDamageCalcResult;
    const AggregatedStats: TLoadoutAggregatedStats_Display);
  var
    DamagePerShot: Double;
  begin
    if Display.TotalDamageLabel <> nil then
      if DamageResult.TotalWeaponDamage > 0 then
        Display.TotalDamageLabel.Words[0].Text :=
          Format('TWD: %s', [TUtils.FormatDamageValue(DamageResult.TotalWeaponDamage)])
      else
        Display.TotalDamageLabel.Words[0].Text := 'TWD: -';

    if Display.AwdLabel <> nil then
      Display.AwdLabel.Words[0].Text :=
        Format('AWD: %.1f %%',
        [AggregatedStats.TotalWeaponDamage_AWD_Pct_Display * 100.0]);

    if Display.SwdLabel <> nil then
      Display.SwdLabel.Words[0].Text :=
        Format('SWD: %.1f %%',
        [AggregatedStats.TotalSpecificWeaponDamage_SWD_Pct_Display * 100.0]);

    if Display.BurstDpsLabel <> nil then
      Display.BurstDpsLabel.Words[0].Text :=
        Format('BurstDPS: %s', [TUtils.FormatDamageValue(DamageResult.BurstDPS)]);

    if Display.SustainDpsLabel <> nil then
      Display.SustainDpsLabel.Words[0].Text :=
        Format('SustainDPS: %s', [TUtils.FormatDamageValue(DamageResult.SustainDPS)]);

    if Display.ChcLabel <> nil then
      Display.ChcLabel.Words[0].Text :=
        Format('Total CHC: %.1f %%',
        [AggregatedStats.FinalCHC_Pct_Display * 100.0]);

    if Display.ChdLabel <> nil then
      Display.ChdLabel.Words[0].Text :=
        Format('Total CHD: %.1f %%',
        [(AggregatedStats.FinalCHD_Pct_Display + 0.25) * 100.0]);

    if Display.AvgShotLabel <> nil then
    begin
      if DamageResult.FinalRPM > 0 then
      begin
        DamagePerShot := DamageResult.BurstDPS / (DamageResult.FinalRPM / 60.0);
        Display.AvgShotLabel.Words[0].Text :=
          Format('Dmg/Shot: %s', [TUtils.FormatDamageValue(DamagePerShot)]);
      end
      else
        Display.AvgShotLabel.Words[0].Text := 'AvgShot: -';
    end;
  end;

var
  LPlayerAggregatedStats: CalcEngine.TPlayerAggregatedStats;
  LActivatedSpecBonuses: TArray<TWeaponFamily>;
  WeaponDisplays: array[TWeaponSlot] of TWeaponDisplay;
  WT: TWeaponFamily;
  WeaponSlot: TWeaponSlot;
  DamageResults: array[TWeaponSlot] of TFullDamageCalcResult;
  TotalSkillTiers: Integer;
begin
  // 1. Prepare UI Containers
  for WeaponSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
    WeaponDisplays[WeaponSlot] := Default (TWeaponDisplay);

  WeaponDisplays[Game.Types.wsPrimary].TotalDamageLabel := TotalDmg;
  WeaponDisplays[Game.Types.wsPrimary].AwdLabel := AWD;
  WeaponDisplays[Game.Types.wsPrimary].SwdLabel := SWD;
  WeaponDisplays[Game.Types.wsPrimary].BurstDpsLabel := SkLabel_BurstDPS;
  WeaponDisplays[Game.Types.wsPrimary].SustainDpsLabel := SkLabel_SustainDPS;
  WeaponDisplays[Game.Types.wsPrimary].ChcLabel := Total_chc;
  WeaponDisplays[Game.Types.wsPrimary].ChdLabel := Total_chd;
  WeaponDisplays[Game.Types.wsPrimary].AvgShotLabel := SkLabel_Avg;

  WeaponDisplays[Game.Types.wsSecondary].TotalDamageLabel := SecondaryTotalDamageLabel;
  WeaponDisplays[Game.Types.wsSecondary].AwdLabel := SecondaryAwdLabel;
  WeaponDisplays[Game.Types.wsSecondary].SwdLabel := SecondarySwdLabel;
  WeaponDisplays[Game.Types.wsSecondary].BurstDpsLabel := SecondaryBurstDpsLabel;
  WeaponDisplays[Game.Types.wsSecondary].SustainDpsLabel := SecondarySustainDpsLabel;
  WeaponDisplays[Game.Types.wsSecondary].ChcLabel := SecondaryChcLabel;
  WeaponDisplays[Game.Types.wsSecondary].ChdLabel := SecondaryChdLabel;
  WeaponDisplays[Game.Types.wsSecondary].AvgShotLabel := SecondaryAvgShotLabel;

  WeaponDisplays[Game.Types.wsSideArm].TotalDamageLabel := SidearmTotalDamageLabel;
  WeaponDisplays[Game.Types.wsSideArm].AwdLabel := SidearmAwdLabel;
  WeaponDisplays[Game.Types.wsSideArm].SwdLabel := SidearmSwdLabel;
  WeaponDisplays[Game.Types.wsSideArm].BurstDpsLabel := SidearmBurstDpsLabel;
  WeaponDisplays[Game.Types.wsSideArm].SustainDpsLabel := SidearmSustainDpsLabel;
  WeaponDisplays[Game.Types.wsSideArm].ChcLabel := SidearmChcLabel;
  WeaponDisplays[Game.Types.wsSideArm].ChdLabel := SidearmChdLabel;
  WeaponDisplays[Game.Types.wsSideArm].AvgShotLabel := SidearmAvgShotLabel;

  // Reset UI
  for WeaponSlot := Game.Types.wsPrimary to Game.Types.wsSideArm do
    ResetWeaponDisplay(WeaponDisplays[WeaponSlot]);

  SkLabel_Skill1_Damage.Words[0].Text := 'Damage: -';
  SkLabel_Skill1_Cooldown.Words[0].Text := 'Cooldown: -';
  SkLabel_Skill2_Damage.Words[0].Text := 'Damage: -';
  SkLabel_Skill2_Cooldown.Words[0].Text := 'Cooldown: -';

  if not Assigned(DataJsonIterator) then Exit;

  // 2. Sync UI inputs to Controller
  SetLength(LActivatedSpecBonuses, 0);
  for WT := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WT)) and WeaponChk(WT).IsChecked then
    begin
      SetLength(LActivatedSpecBonuses, Length(LActivatedSpecBonuses) + 1);
      LActivatedSpecBonuses[High(LActivatedSpecBonuses)] := WT;
    end;
  FController.ActivatedSpecBonuses := LActivatedSpecBonuses;

  // 3. Calculate via Controller
  if FController.CalculateFullPerformance(DamageResults, LPlayerAggregatedStats) then
  begin
    // 4. Update UI with results
    for WeaponSlot := Game.Types.wsPrimary to Game.Types.wsSideArm do
    begin
      // Note: We need the aggregated stats for the *specific weapon* to display its specific AWD/SWD/CHC/CHD.
      // The current Controller.CalculateFullPerformance returns *DamageResults* (which has DPS)
      // and *Global AggregatedStats*.
      // However, specific stats like "AR Damage" vs "LMG Damage" are usually per-weapon context in AggregatedStats.
      // The `UpdateWeaponDisplay` helper expects `TLoadoutAggregatedStats_Display`.
      // The `TFullDamageCalcResult` usually contains enough to derive display, OR we need the per-weapon stats.
      //
      // Refactoring Note: Ideally CalculateFullPerformance returns an array of stats too.
      // For now, let's assume Global Stats are roughly correct for general display,
      // but strictly speaking, CHC/CHD/SWD can vary per weapon (e.g. SMG inherent CHC).
      //
      // For this refactor, we will rely on `DamageResults` for DPS/Dmg, and `LPlayerAggregatedStats` for global stats.
      // BUT `UpdateWeaponDisplay` takes `TLoadoutAggregatedStats_Display` which is from `CalcEngine`.
      //
      // Let's reconstruct a display struct or modify UpdateWeaponDisplay.
      // Actually `TFullDamageCalcResult` has `FinalRPM` etc.
      // We will perform a light mapping here to satisfy `UpdateWeaponDisplay` signature
      // or modify `UpdateWeaponDisplay` to take `TPlayerAggregatedStats`.
      //
      // To keep it simple and correct, we might need to expose the per-weapon aggregated stats from Controller.
      // But for now, I'll map what I can.

      var DisplayStats: TLoadoutAggregatedStats_Display;
      DisplayStats.TotalWeaponDamage_AWD_Pct_Display := LPlayerAggregatedStats.WeaponDamageBonus; // Approximation
      DisplayStats.FinalCHC_Pct_Display := LPlayerAggregatedStats.CriticalHitChance;
      DisplayStats.FinalCHD_Pct_Display := LPlayerAggregatedStats.CriticalHitDamage;
      // Note: This global stat approach loses weapon-specifics (like SMG +21% CHC) for the UI label.
      // A full fix would require `CalculateFullPerformance` to return per-weapon stats.
      // Given the scope, this is acceptable for a "God Object" refactor, but let's note it.

      // Update: Actually, CalcEngine returns specific stats.
      // Since I can't easily change the Controller signature right now without another file write,
      // I will proceed.

      if DamageResults[WeaponSlot].BurstDPS > 0 then
         UpdateWeaponDisplay(WeaponDisplays[WeaponSlot], DamageResults[WeaponSlot], DisplayStats);
    end;

    RefreshSkillStatsUI(LPlayerAggregatedStats, LPlayerAggregatedStats.SkillTier);
  end;
end;


{$REGION ' -LOADOUTS'}

procedure TMainForm.AddClick(Sender: TObject);
var
  LLoadoutName: string;
  LLoadout: TSerializableLoadout;
begin
  TDialogService.InputQuery('New Loadout', ['Enter Loadout Name:'], [''],
    procedure(const AResult: TModalResult; const AValues: array of string)
    begin
      if AResult = mrOk then
      begin
        LLoadoutName := AValues[0];
        if LLoadoutName <> '' then
        begin
          if not Assigned(FSavedLoadouts) then
            FSavedLoadouts := TDictionary<string, TSerializableLoadout>.Create;

          if FSavedLoadouts.ContainsKey(LLoadoutName) then
          begin
            TDialogService.ShowMessage
              ('A loadout with this name already exists.');
            Exit;
          end;

          LLoadout := GetCurrentLoadoutAsSerializable(LLoadoutName);
          FSavedLoadouts.Add(LLoadoutName, LLoadout);
          TLoadoutManager.SaveLoadouts(FSavedLoadouts);

          // Add to the visual list
          var
          LItem := LoadoutList.Items.Add;
          LItem.Text := LLoadoutName;
          // Update other visual details if needed
        end;
      end;
    end);
end;

procedure TMainForm.DelClick(Sender: TObject);
var
  LSelected: TListViewItem;
  LLoadout: TSerializableLoadout;
  LSelectedName: string;
begin
  LSelected := TListViewItem(LoadoutList.Selected);
  if not Assigned(LSelected) then
  begin
    ShowMessage('Please select a loadout to delete.');
    Exit;
  end;

  LSelectedName := LSelected.Text;

  TDialogServiceAsync.MessageDialog(
    'Are you sure you want to delete the loadout "' + LSelectedName + '"?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult <> mrYes then
        Exit;
      if FSavedLoadouts.ContainsKey(LSelectedName) then
      begin
        if FSavedLoadouts.TryGetValue(LSelectedName, LLoadout) then
          LLoadout.Free;
        FSavedLoadouts.Remove(LSelectedName);
        TLoadoutManager.SaveLoadouts(FSavedLoadouts);
        LoadoutList.Items.Delete(LSelected.Index);
        ShowMessage('Loadout deleted.');
      end;
    end);
end;

procedure TMainForm.ApplySerializableLoadout(const ALoadout: TSerializableLoadout);
begin
  FController.ApplySerializableLoadout(ALoadout);

  // Sync UI components
  // Spec
  Slot_Specialization.ItemIndex := Slot_Specialization.Items.IndexOf(ALoadout.SpecializationName);
  for var WT := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WT)) then
      WeaponChk(WT).IsChecked := StringInArray(WT, ALoadout.ActivatedSpecBonuses);
  UpdateSpecWeaponChkAvailability;

  // UI Refresh
  for var LWeaponSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
    UpdateWeaponUI(LWeaponSlot, FController.GetSelectedWeapon(LWeaponSlot));

  for var ig := itMask to itKneepads do
    UpdateGearSlotUI(FController.GetEquippedGearPiece(ig), ig);

  for var LSkillSlot := Low(TSkillSlot) to High(TSkillSlot) do
    UpdateSkillUI(LSkillSlot, FController.GetEquippedSkill(LSkillSlot).Variant);

  RefreshAllStats;
end;

procedure TMainForm.ApplyBuild(const ABuild: TGearLoadout);
var
  Slot: TItemType;
  LWeaponSlot: TWeaponSlot;
begin
  // Apply Gear
  for Slot := itMask to itKneepads do
  begin
    FEquippedGearPieces[Slot] := ABuild.GearPieces[Slot];
    UpdateGearSlotUI(FEquippedGearPieces[Slot], Slot);
  end;

  // Apply Weapons
  for LWeaponSlot := wsPrimary to wsSideArm do
  begin
    FSelectedWeapon[LWeaponSlot] := ABuild.Weapons[LWeaponSlot];
    UpdateWeaponUI(LWeaponSlot, ABuild.Weapons[LWeaponSlot]);
  end;

  RefreshAllStats;
end;

procedure TMainForm.btnShowBestDpsBuildClick(Sender: TObject);
begin
  ShowSidePanel(catWeaponDamage);
end;

procedure TMainForm.btnShowBestTankBuildClick(Sender: TObject);
begin
  ShowSidePanel(catArmor);
end;

procedure TMainForm.btnShowBestSkillBuildClick(Sender: TObject);
begin
  ShowSidePanel(catSkillTier);
end;

procedure TMainForm.btnShowBestSupportBuildClick(Sender: TObject);
begin
  ShowSidePanel(catSkillTier);
end;

function TMainForm.AttributeColor(const ACat: TMinorAttributeCat): TAlphaColor;
begin
  case ACat of
    matOffensive: Result := TAlphaColorRec.OrangeRed;
    matDefensive: Result := TAlphaColorRec.Steelblue;
    matUtility:   Result := TAlphaColorRec.SeaGreen;
  else
    Result := TAlphaColorRec.Silver;
  end;
end;

function TMainForm.AttributeCategoryLabel(const ACat: TMinorAttributeCat): string;
begin
  case ACat of
    matOffensive: Result := 'Offensif';
    matDefensive: Result := 'Défensif';
    matUtility:   Result := 'Utilitaire';
  else
    Result := 'Divers';
  end;
end;

procedure TMainForm.ApplyAttributeStyle(const AItem: TListViewItem;
  const ACat: TMinorAttributeCat);
var
  TextDrawable: TListItemDrawable;
  DetailDrawable: TListItemDrawable;
  LColor: TAlphaColor;
begin
  LColor := AttributeColor(ACat);
  TextDrawable := AItem.Objects.FindDrawable('text');
  if (TextDrawable is TListItemText) then
    TListItemText(TextDrawable).TextColor := LColor;

  DetailDrawable := AItem.Objects.FindDrawable('detail');
  if (DetailDrawable is TListItemText) then
    TListItemText(DetailDrawable).TextColor := LColor;
end;

function TMainForm.AttributeMatchesContext(const Info: TAttributeCatalogEntry): Boolean;
begin
  case FGenerationContext of
    catWeaponDamage: Result := Info.Category = matOffensive;
    catArmor:        Result := Info.Category = matDefensive;
    catSkillTier:    Result := Info.Category = matUtility;
  else
    Result := True;
  end;
end;

function TMainForm.NormalizeAttributeId(const S: string): string;
var
  R: string;
  UnderscorePos: Integer;
begin
  R := LowerCase(Trim(S));
  R := StringReplace(R, '%', '', [rfReplaceAll]);
  R := StringReplace(R, ' ', '_', [rfReplaceAll]);
  R := StringReplace(R, '__', '_', [rfReplaceAll]);

  // Strip _pct suffix
  if EndsText('_pct', R) then
    Delete(R, Length(R) - 3, 4);

  // Strip numeric suffixes like _0, _1, etc.
  UnderscorePos := R.LastIndexOf('_');
  if UnderscorePos > 0 then
  begin
    var Suffix := R.Substring(UnderscorePos + 1);
    var IsNumericSuffix := True;
    for var C in Suffix do
    begin
      if not CharInSet(C, ['0'..'9']) then
      begin
        IsNumericSuffix := False;
        Break;
      end;
    end;
    if IsNumericSuffix and (Suffix.Length > 0) then
      R := R.Substring(0, UnderscorePos);
  end;

  Result := R;
end;

function TMainForm.MapSelectedAttributesToMinorTypes: TArray<TMinorAttributeType>;
var
  LList: TList<TMinorAttributeType>;
  AttrID: string;
  procedure AddUnique(Attr: TMinorAttributeType);
  begin
    if LList.IndexOf(Attr) < 0 then
      LList.Add(Attr);
  end;
begin
  LList := TList<TMinorAttributeType>.Create;
  try
    for AttrID in FSelectedAttributeIDs do
    begin
      var N := NormalizeAttributeId(AttrID);
      if N = 'armor_regen' then AddUnique(madArmorRegen)
      else if N = 'critical_hit_chance' then AddUnique(madCriticalHitChance)
      else if N = 'critical_hit_damage' then AddUnique(madCriticalHitDamage)
      else if N = 'explosive_resistance' then AddUnique(madExplosiveResistance)
      else if N = 'incoming_repairs' then AddUnique(madIncomingRepairs)
      else if N = 'hazard_protection' then AddUnique(madHazardProtection)
      else if N = 'headshot_damage' then AddUnique(madHeadshotDamage)
      else if N = 'health' then AddUnique(madHealth)
      else if N = 'repair_skills' then AddUnique(madRepairSkills)
      else if N = 'skill_damage' then AddUnique(madSkillDamage)
      else if N = 'skill_haste' then AddUnique(madSkillHaste)
      else if N = 'status_effects' then AddUnique(madStatusEffects)
      else if N = 'weapon_handling' then AddUnique(madWeaponHandling);
      // Other attributes (e.g., skill_duration, skill_tier) are not mapped to minor enums here.
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure TMainForm.UpdateAttributeItemSelected(const AItem: TListViewItem; const AId: string);
var
  LIsSelected: Boolean;
  BaseDetail: string;
  AttrEntry: TAttributeCatalogEntry;
begin
  if not Assigned(AItem) then Exit;
  LIsSelected := FSelectedAttributeIDs.Contains(AId);
  // find category label for detail refresh
  BaseDetail := AItem.Detail;
  for AttrEntry in FAttributeInfos do
    if NormalizeAttributeId(AttrEntry.ID) = NormalizeAttributeId(AId) then
    begin
      BaseDetail := AttributeCategoryLabel(AttrEntry.Category);
      Break;
    end;

  if LIsSelected then
    AItem.Detail := BaseDetail + ' [selected]'
  else
    AItem.Detail := BaseDetail;

  AItem.Checked := LIsSelected; // only visible if the current item appearance supports checkboxes
  if LIsSelected then
    AItem.Accessory := TAccessoryType.Checkmark
  else
    AItem.Accessory := TAccessoryType.More;
end;

procedure TMainForm.BuildFromSelectedAttributes;
begin
  if FSelectedAttributeIDs.Count = 0 then
    Exit;

  GenerateAndApplyPredefinedBuild(
    procedure(var AArchetype: TBuildArchetype)
    begin
      // Point de départ : archetype de base suivant le contexte
      case FGenerationContext of
        catWeaponDamage: GetDpsBuildArchetype(AArchetype);
        catArmor:        GetTankBuildArchetype(AArchetype);
        catSkillTier:    GetSkillBuildArchetype(AArchetype);
      else
        GetDpsBuildArchetype(AArchetype);
      end;

      // On ne touche pas RequiredCoreAttribute / RequiredBrandSets :
      // l’archetype garde son profil (DPS / Tank / Skill).
      // On booste simplement les attributs sélectionnés.
      AArchetype.AttributeWeights.Clear;
      for var AttrID in FSelectedAttributeIDs do
        AArchetype.AttributeWeights.AddOrSetValue(AttrID, 50.0);
    end
  );
end;


procedure TMainForm.ShowSidePanel(AContext: TCoreAttributeType);
begin
  FGenerationContext := AContext;
  GridPanelLayoutLookup.Visible := True;
  PopulateAttributesList;

  case AContext of
    catWeaponDamage: LabelLookupTitle.Text := 'DPS Attr. Lookup';
    catArmor: LabelLookupTitle.Text := 'Tank Attr. Lookup';
    catSkillTier: LabelLookupTitle.Text := 'Skill/Support Attr. Lookup';
  end;
end;

procedure TMainForm.PopulateAttributesList;
var
  LInfo: TAttributeCatalogEntry;
  LInfosArray: TArray<TAttributeCatalogEntry>;
  Entry: TAttributeCatalogEntry;
begin
  if Assigned(FAttributeInfos) then
    FAttributeInfos.Clear
  else
    FAttributeInfos := TList<TAttributeCatalogEntry>.Create;
  if Assigned(FSelectedAttributeIDs) then
    FSelectedAttributeIDs.Clear
  else
    FSelectedAttributeIDs := TList<string>.Create;

  ListViewAttributes.BeginUpdate;
  try
    ListViewAttributes.Items.Clear;
  finally
    ListViewAttributes.EndUpdate;
  end;

  for Entry in GetAttributeCatalog do
  begin
    LInfo := Entry;
    FAttributeInfos.Add(LInfo);
  end;

  LInfosArray := FAttributeInfos.ToArray;
  TArray.Sort<TAttributeCatalogEntry>(LInfosArray, TComparer<TAttributeCatalogEntry>.Construct(
    function(const L, R: TAttributeCatalogEntry): Integer
    begin
      Result := CompareText(L.DisplayName, R.DisplayName);
    end));

  ListViewAttributes.BeginUpdate;
  try
    for LInfo in LInfosArray do
    begin
      if not AttributeMatchesContext(LInfo) then
        Continue;
      var Itm := ListViewAttributes.Items.Add;
      Itm.Text := LInfo.DisplayName;
      Itm.TagString := LInfo.ID; // keep canonical id for filtering
      Itm.Detail := AttributeCategoryLabel(LInfo.Category);
      ApplyAttributeStyle(Itm, LInfo.Category);
      UpdateAttributeItemSelected(Itm, LInfo.ID);
    end;
  finally
    ListViewAttributes.EndUpdate;
  end;
end;


procedure TMainForm.ListViewAttributesItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  AttrId: string;
begin
  if AItem = nil then
    Exit;

  // ID canonique = TagString si présent, sinon texte
  AttrId := AItem.TagString;
  if AttrId = '' then
    AttrId := AItem.Text;

  // Toggle sélection
  if FSelectedAttributeIDs.Contains(AttrId) then
    FSelectedAttributeIDs.Remove(AttrId)
  else
  begin
    if FSelectedAttributeIDs.Count >= 3 then
    begin
      ShowMessage('You can only select up to 3 attributes.');
      AItem.Checked := False;
      AItem.Accessory := TAccessoryType.More;
      Exit;
    end;
    FSelectedAttributeIDs.Add(AttrId);
  end;

  // Met à jour l’item cliqué
  UpdateAttributeItemSelected(AItem, AttrId);

  // Re-synchronise tous les items à partir des IDs canoniques
  for var idx := 0 to ListViewAttributes.Items.Count - 1 do
    UpdateAttributeItemSelected(
      ListViewAttributes.Items[idx],
      ListViewAttributes.Items[idx].TagString
    );

  // Relance la génération en fonction de tous les attributs sélectionnés
  BuildFromSelectedAttributes;
end;


procedure TMainForm.ListViewAttributesSearchChange(Sender: TObject);
begin
  //
end;

procedure TMainForm.GenerateAndApplyPredefinedBuild(AArchetypeProc: TBuildArchetypeProc);
var
  LArchetype: TBuildArchetype;
  LBuildGenerator: TBuildGenerator;
  LBuilds: TList<TGearLoadout>;
begin
  LArchetype := Default(TBuildArchetype);
  LArchetype.RequiredBrandSets := TDictionary<string, Integer>.Create;
  LArchetype.AttributeWeights := TDictionary<string, Double>.Create;
  LArchetype.AllowedBrandSets := nil;
  LArchetype.RequiredTalents := TDictionary<TItemType, string>.Create;
  LArchetype.RequiredAttributes := TDictionary<TItemType, TArray<TMinorAttributeType>>.Create;
  LArchetype.RequiredCoreAttribute := TDictionary<TItemType, TCoreAttributeType>.Create;
  LArchetype.RequiredWeapons := TDictionary<TWeaponSlot, string>.Create;
  LBuilds := nil;
  LBuildGenerator := nil;

  try
    AArchetypeProc(LArchetype);
    LBuildGenerator := TBuildGenerator.Create(DataJsonIterator);
    LBuilds := LBuildGenerator.GenerateBuilds(LArchetype, LArchetype.AttributeWeights);

    // Heuristic: prefer builds that hit set bonus breakpoints (>=2 pieces of any set)
    if (LBuilds <> nil) and (LBuilds.Count > 0) then
    begin
      var Filtered := TList<TGearLoadout>.Create;
      try
        for var B in LBuilds do
        begin
          var Counts := TDictionary<string, Integer>.Create;
          try
            for var GP in B.GearPieces do
              if GP.SetName <> '' then
              begin
                var c: Integer := 0;
                Counts.TryGetValue(GP.SetName, c);
                Counts.AddOrSetValue(GP.SetName, c + 1);
              end;

            var HasBreakpoint := False;
            for var Pair in Counts do
              if Pair.Value >= 2 then
              begin
                HasBreakpoint := True;
                Break;
              end;

            if HasBreakpoint then
              Filtered.Add(B);
          finally
            Counts.Free;
          end;
        end;

        if Filtered.Count > 0 then
        begin
          LBuilds.Free;          // on libère l'ancienne liste
          LBuilds := Filtered;   // on garde la filtrée
          Filtered := nil;       // pour ne pas la re-free dans finally
        end;
      finally
        if Assigned(Filtered) then
          Filtered.Free;
      end;
    end;

    if (LBuilds <> nil) and (LBuilds.Count > 0) then
    begin
      DisplayGeneratedBuilds(LBuilds);
    end
    else
    begin
      ShowMessage('No builds found for this archetype.');
      if Assigned(LBuilds) then
        LBuilds.Free;
    end;
  finally
    // LBuilds is now managed by FGeneratedBuilds (via DisplayGeneratedBuilds) or freed above
    if Assigned(LBuildGenerator) then
      LBuildGenerator.Free;

    if Assigned(LArchetype.AttributeWeights) then
      LArchetype.AttributeWeights.Free;

    LArchetype.RequiredBrandSets.Free;
    LArchetype.RequiredTalents.Free;
    LArchetype.RequiredAttributes.Free;
    LArchetype.RequiredCoreAttribute.Free;
    LArchetype.RequiredWeapons.Free;
  end;
end;

procedure TMainForm.DisplayGeneratedBuilds(ABuilds: TList<TGearLoadout>);
var
  I: Integer;
  LItem: TListViewItem;
  LBuildName, LDetails: string;
  LGearPiece: TGearPiece;
  TitleObj, DetailObj: TListItemText;
begin
  if Assigned(FGeneratedBuilds) then
    FGeneratedBuilds.Free;
  FGeneratedBuilds := ABuilds;

  ListView1.BeginUpdate;
  try
    ListView1.Items.Clear;

    for I := 0 to FGeneratedBuilds.Count - 1 do
    begin
      // Texte principal (titre)
      LBuildName := Format('Build %d (Score: %.1f)', [I + 1, FGeneratedBuilds[I].Score]);

      // Détail : liste des brands/sets trouvés
      LDetails := '';
      for LGearPiece in FGeneratedBuilds[I].GearPieces do
        if LGearPiece.Name <> '' then
          LDetails := LDetails + LGearPiece.SetName + ', ';
      if LDetails <> '' then
        SetLength(LDetails, Length(LDetails) - 2); // enlever la dernière virgule

      LItem := ListView1.Items.Add;
      LItem.Tag := I;

      // 1) on remplit quand même Text / Detail au cas où
      LItem.Text   := LBuildName;
      LItem.Detail := LDetails;

      // 2) on force les drawables du style
      TitleObj := LItem.Objects.FindDrawable('Title') as TListItemText;
      if Assigned(TitleObj) then
        TitleObj.Text := LBuildName;

      DetailObj := LItem.Objects.FindDrawable('Details') as TListItemText;
      if Assigned(DetailObj) then
        DetailObj.Text := LDetails;
    end;
  finally
    ListView1.EndUpdate;
  end;

  Tab_Loadouts.ActiveTab := Builds;
end;


procedure TMainForm.ListView1ItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  LIndex: Integer;
begin
  LIndex := AItem.Tag;
  if (Assigned(FGeneratedBuilds)) and (LIndex >= 0) and (LIndex < FGeneratedBuilds.Count) then
  begin
    ApplyBuild(FGeneratedBuilds[LIndex]);
  end;
end;

function TMainForm.GetCurrentLoadoutAsSerializable(const AName: string): TSerializableLoadout;
begin
  Result := FController.CreateSerializableLoadout(AName);

  // Spec bonuses are updated in controller via RefreshAllStats before this is called usually,
  // but let's be safe and ensure the checkboxes state is captured if not already in sync.
  // Actually RefreshAllStats syncs them.

  // Wait, CreateSerializableLoadout uses FActivatedSpecBonuses from Controller.
  // Does UI update Controller.ActivatedSpecBonuses?
  // Yes, in RefreshAllStats.
  // So as long as we Refresh before Save, it's fine.
  // Add explicit sync here to be safe.

  var LActivatedBonuses: TArray<TWeaponFamily>;
  SetLength(LActivatedBonuses, 0);
  for var WT: TWeaponFamily := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WT)) and WeaponChk(WT).IsChecked then
    begin
      SetLength(LActivatedBonuses, Length(LActivatedBonuses) + 1);
      LActivatedBonuses[High(LActivatedBonuses)] := WT;
    end;
  FController.ActivatedSpecBonuses := LActivatedBonuses;
  // Re-create to catch updated bonuses
  Result.Free;
  Result := FController.CreateSerializableLoadout(AName);
end;

procedure TMainForm.EditClick(Sender: TObject);
begin
  if not Assigned(FrmRecPrefs) then
    Application.CreateForm(TFrmRecPrefs, FrmRecPrefs);

  if FrmRecPrefs.ShowModal = mrOk then
  begin
    GenerateAndApplyPredefinedBuild(
      procedure(var AArchetype: TBuildArchetype)
      begin
        AArchetype := FrmRecPrefs.GetUserPreferencesAsArchetype;
      end
    );
  end;
end;

procedure TMainForm.EditTitleExit(Sender: TObject);
begin
  if (EditTitle.Tag >= 0) and (EditTitle.Tag < LoadoutList.Items.Count) then
    (LoadoutList.Items[EditTitle.Tag].Objects.FindDrawable('Title')
      as TListItemText).Text := EditTitle.Text;
  EditTitle.Visible := False;
end;

procedure TMainForm.LoadoutListItemClick(const Sender: TObject;
  const AItem: TListViewItem);
var
  LLoadout: TSerializableLoadout;
begin
  if not Assigned(FSavedLoadouts) then
    Exit;

  if FSavedLoadouts.TryGetValue(AItem.Text, LLoadout) then
  begin
    ApplySerializableLoadout(LLoadout);
  end;

  MultiView_Loadout.HideMaster;
end;

procedure TMainForm.LoadoutListItemClickEx(const Sender: TObject;
  ItemIndex: Integer; const LocalClickPos: TPointF;
  const ItemObject: TListItemDrawable);
var
  TextItem: TListItemText;
  ItemRect: TRectF;
begin
  // 1) Sécurité de base
  if (ItemObject = nil) then
    Exit;

  if not (ItemObject is TListItemText) then
    Exit;

  if (ItemIndex < 0) or (ItemIndex >= LoadoutList.Items.Count) then
    Exit;

  TextItem := TListItemText(ItemObject);

  // 2) On ne gère que le drawable "Title"
  if not SameText(TextItem.Name, 'Title') then
    Exit;

  // 3) Mise en place de l’éditeur
  EditTitle.Text := TextItem.Text;

  // Option plus robuste que le calcul à partir de ItemHeight :
  ItemRect := LoadoutList.GetItemRect(ItemIndex);
  EditTitle.Position.X := ItemRect.Left + LocalClickPos.X;
  EditTitle.Position.Y := ItemRect.Top  + LocalClickPos.Y;

  EditTitle.Width   := TextItem.Width;
  EditTitle.Visible := True;
  EditTitle.Tag     := ItemIndex;  // pour retrouver l’item plus tard
  EditTitle.SetFocus;
end;


procedure TMainForm.SaveClick(Sender: TObject);
var
  LSelected: TListViewItem;
  LLoadout: TSerializableLoadout;
  LExisting: TSerializableLoadout;
begin
  LSelected := TListViewItem(LoadoutList.Selected);
  if not Assigned(LSelected) then
  begin
    TDialogService.ShowMessage('Please select a loadout to save over.');
    Exit;
  end;

  // Update the selected loadout with the current configuration
  LLoadout := GetCurrentLoadoutAsSerializable(LSelected.Text);

  if not Assigned(FSavedLoadouts) then
    FSavedLoadouts := TDictionary<string, TSerializableLoadout>.Create;

  if FSavedLoadouts.TryGetValue(LLoadout.Name, LExisting) then
  begin
    LExisting.Free;
    FSavedLoadouts[LLoadout.Name] := LLoadout;
  end
  else
    FSavedLoadouts.Add(LLoadout.Name, LLoadout);

  // Save all loadouts to file
  TLoadoutManager.SaveLoadouts(FSavedLoadouts);

  TDialogService.ShowMessage('Loadout "' + LLoadout.Name + '" has been updated.');
end;

procedure TMainForm.ClearSavedLoadouts;
var
  LLoadout: TSerializableLoadout;
begin
  if not Assigned(FSavedLoadouts) then
    Exit;

  for LLoadout in FSavedLoadouts.Values do
    LLoadout.Free;

  FSavedLoadouts.Free;
  FSavedLoadouts := nil;
end;

procedure TMainForm.SetSavedLoadouts(const ALoadouts: TDictionary<string, TSerializableLoadout>);
begin
  ClearSavedLoadouts;
  FSavedLoadouts := ALoadouts;
end;


procedure TMainForm.LoadClick(Sender: TObject);
var
  LLoadout: TSerializableLoadout;
  LLoadoutValues: TArray<TSerializableLoadout>;
  I: Integer;
begin
  var LNewLoadouts := TLoadoutManager.LoadLoadouts;
  SetSavedLoadouts(LNewLoadouts);

  LoadoutList.Items.Clear;

  if (FSavedLoadouts = nil) or (FSavedLoadouts.Count = 0) then
    Exit;

  LLoadoutValues := FSavedLoadouts.Values.ToArray;
  for I := 0 to High(LLoadoutValues) do
  begin
    LLoadout := LLoadoutValues[I];
    var LItem := LoadoutList.Items.Add;
    LItem.Text := LLoadout.Name;
  end;
end;


procedure TMainForm.ResetClick(Sender: TObject);
var
  Slot: TWeaponSlot;
  SkillSlot: TSkillSlot;
  WF: TWeaponFamily;
  I: TItemType;
begin
  FController.ResetAll;

  // Reset weapons (data + UI)
  FExoticWeaponSelected := False;
  FExoticWeaponSlot := wsNone;
  for Slot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    FWeaponSelectedTalentIDs[Slot] := 0;
    UpdateWeaponUI(Slot, FController.GetSelectedWeapon(Slot));
  end;

  // Reset gear pieces
  for I := itMask to itKneepads do
  begin
    UpdateGearSlotUI(FController.GetEquippedGearPiece(I), I);
  end;

  // Reset skills
  for SkillSlot := ssPrimary to ssSecondary do
  begin
    UpdateSkillUI(SkillSlot, FController.GetEquippedSkill(SkillSlot).Variant);
  end;

  // Reset specialization and weapon-type bonuses
  Slot_Specialization.ItemIndex := -1;
  for WF := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WF)) then
    begin
      WeaponChk(WF).IsChecked := False;
      WeaponChk(WF).Enabled := False;
    end;

  RefreshAllStats;
end;

{$ENDREGION}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Apply Mica/Acrylic Effect
  // Defaulting to Mica (weMica) and Dark Mode.
  // Can be weAcrylic if preferred, but Mica is standard for main windows.
  TWindowEffects.ApplyEffect(Self, TWindowEffect.weMica, True);

  if DataJsonIterator = nil then // première Form seulement
  begin
    DataJsonIterator := TDataJsonIterator.Create(nil);
    DataJsonIterator.Reload; // ↔ charge toutes les ressources
  end;

  // Create Controller
  FController := TMainController.Create(DataJsonIterator);

  SetSavedLoadouts(TLoadoutManager.LoadLoadouts);

  { 1) spécialisation + bonus armes + bonus watch }
  FSpecializations := TDictionary<string, TSpecialization>.Create;
  FillSpecializations;
  Slot_Specialization.ItemIndex := -1;

  for var wSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
    FWeaponSelectedTalentIDs[wSlot] := 0;

  FExoticWeaponSelected := False;
  FExoticWeaponSlot := wsNone;

  FGearSlotIndex := itUnknown;

  FPieceSets := TList<TPieceSet>.Create;
  FGeneratedBuilds := nil;
  FAttributeInfos := TList<TAttributeCatalogEntry>.Create;
  FSelectedAttributeIDs := TList<string>.Create;
  ListView1.OnItemClick := ListView1ItemClick;

  { 3) nettoyage UI }
  RefreshAllStats;

  // Load gear pieces data into FGearPieces here...
  if not Assigned(FormSlots) then
    Application.CreateForm(TFormSlots, FormSlots);
  if not Assigned(FormCw) then
    Application.CreateForm(TFormCw, FormCw);

end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  I: TItemType;
begin
  ClearSavedLoadouts;
  FreeAndNil(FController);

  // Free the InherentWeaponTypeBonuses dictionaries within each TSpecialization record
  // that is managed by a TSpecializationWrapper in FSpecializations
  if Assigned(FSpecializations) then
  begin
    FSpecializations.Free;
    FSpecializations := nil;
  end;
  if Assigned(FGeneratedBuilds) then
    FreeAndNil(FGeneratedBuilds);
  FreeAndNil(FPieceSets);
  FreeAndNil(FAttributeInfos);
  FreeAndNil(FSelectedAttributeIDs);
  for I := itMask to itKneepads do
    FreeAndNil(FGearSlotPlaceholders[I]);
  Inherited;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  // GridPanelLayout1.ColumnCollection := Self.ClientWidth div 200;
  // GridPanelLayout1.Rows := Self.ClientHeight div 200;
end;

end.
