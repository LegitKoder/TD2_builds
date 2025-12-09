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
  FMX.DialogService.Async, FMX.TabControl, FMX.SearchBox;

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
    Edit1: TEdit;
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
    FGearSlotIndex: Integer;
    FGeneratedBuilds: TList<TGearLoadout>;
    FPieceSets: TList<TPieceSet>;
    FEquippedGearPieces: TArray<TGearPiece>;
    FGearSlotPlaceholders: array[0..5] of TBitmap;
    FAttributeInfos: TList<TAttributeCatalogEntry>;
    FSelectedAttributeIDs: TList<string>;
    FEquippedSkills: array [TSkillSlot] of TEquippedSkill;
    FSelectedSpecialization: Game.Types.TSpecialization;
    FSpecializations: TDictionary<string, Game.Types.TSpecialization>;
    FWeaponExpertiseLevels: array [TWeaponSlot] of Integer;
    FWeaponSelectedTalentIDs: array [TWeaponSlot] of Integer;
    FSelectedWeapon: array [Game.Types.TWeaponSlot] of TWeapon;
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
    // procedure UpdateGearSlotUI(AItemType: TItemType; const AGearPiece: TGearPiece);
    procedure UpdateGearSlotUI(const GearPiece: TGearPiece; SlotIndex: Integer);
    procedure UpdateSkillUI(ASlot: TSkillSlot;
      const ASkillVariant: TSkillVariant);
    procedure RefreshAllStats;
    procedure RefreshSkillStatsUI;
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
    property GearSlotIndex: Integer read FGearSlotIndex write FGearSlotIndex;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure FreeSerializableLoadout(var ALoadout: TSerializableLoadout);
var
  Weapon: TSerializableWeapon;
  LValues: TArray<TSerializableWeapon>;
  I: Integer;
begin
  if Assigned(ALoadout.Weapons) then
  begin
    LValues := ALoadout.Weapons.Values.ToArray;
    for I := 0 to High(LValues) do
    begin
      Weapon := LValues[I];
      if Assigned(Weapon.EquippedModIDs) then
        Weapon.EquippedModIDs.Free;
    end;
    ALoadout.Weapons.Free;
    ALoadout.Weapons := nil;
  end;

  if Assigned(ALoadout.GearPieces) then
  begin
    ALoadout.GearPieces.Free;
    ALoadout.GearPieces := nil;
  end;

  if Assigned(ALoadout.Skills) then
  begin
    ALoadout.Skills.Free;
    ALoadout.Skills := nil;
  end;

  SetLength(ALoadout.ActivatedSpecBonuses, 0);
  ALoadout.SpecializationName := '';
  ALoadout.Name := '';
end;

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
var
  GearPiece: TGearPiece;
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FEquippedGearPieces) do
  begin
    GearPiece := FEquippedGearPieces[I];
    if GearPiece.SetType = stExoticSet then
      Exit(True);
  end;
end;

function TMainForm.CanEquipGearPiece(const AGearPiece: TGearPiece): Boolean;
var
  CurrentlyEquippedExoticInThisSlot: Boolean;
begin
  Result := True;

  if (AGearPiece.SetType = stExoticSet) then
  begin
    CurrentlyEquippedExoticInThisSlot := False;
    if (FGearSlotIndex >= Low(FEquippedGearPieces)) and
      (FGearSlotIndex <= High(FEquippedGearPieces)) then
    begin
      CurrentlyEquippedExoticInThisSlot :=
        (FEquippedGearPieces[FGearSlotIndex].SetType = stExoticSet);
    end;

    if IsExoticGearEquipped and not CurrentlyEquippedExoticInThisSlot then
    begin
      TDialogService.ShowMessage
        ('You can only equip one exotic gear piece at a time. Please unequip the other exotic first.');
      Exit(False);
    end;
  end;
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
    FSelectedSpecialization := SelectedSpecRecord;
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
        if Assigned(FSelectedSpecialization.InherentWeaponTypeBonuses) and
          FSelectedSpecialization.InherentWeaponTypeBonuses.ContainsKey(WT) then
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
begin
  Used := 0;
  for WF := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WF)) and WeaponChk(WF).IsChecked then
      Inc(Used);

  for WF := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WF)) then
      WeaponChk(WF).Enabled := ((Used < MAX_SPEC_BONUS) or WeaponChk(WF)
        .IsChecked) and
        (Assigned(FSelectedSpecialization.InherentWeaponTypeBonuses) and
        FSelectedSpecialization.InherentWeaponTypeBonuses.ContainsKey(WF));
  // Ensure spec can actually provide this bonus
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
begin

  if not Assigned(FormCw) then
    Application.CreateForm(TFormCw, FormCw);

  FormCw.FilterFamilies := Allowed;

  if FSelectedWeapon[ASlot].ID <> 0 then
  begin
    FSelectedWeapon[ASlot].ChosenTalentID := FWeaponSelectedTalentIDs[ASlot];
    FormCw.LoadExistingWeaponState(FSelectedWeapon[ASlot], FWeaponExpertiseLevels[ASlot]);
  end
  else
    FormCw.SpinBox_Exp.Value := FWeaponExpertiseLevels[ASlot];

  if FormCw.ShowModal <> mrOk then
    Exit;

  W := FormCw.SelectedWeapon;
  FWeaponSelectedTalentIDs[ASlot] := W.ChosenTalentID;
  OldWeaponRarity := FSelectedWeapon[ASlot].Rarity;  // Store rarity of the weapon being replaced

  // One Exotic Weapon Rule
  if (W.Rarity = wrExotic) and FExoticWeaponSelected and
    (FExoticWeaponSlot <> ASlot) then
  begin
    TDialogService.MessageDialog
      ('Vous ne pouvez équiper qu''Une arme exotique.', TMsgDlgType.mtWarning,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    Exit;
  end;

  FSelectedWeapon[ASlot] := W; // This now includes ChosenTalentID set by FormCw
  FSelectedWeapon[ASlot].ChosenTalentID := FWeaponSelectedTalentIDs[ASlot];
  // mémoriser l’expertise saisie par l’utilisateur pour ce slot
  FWeaponExpertiseLevels[ASlot] := Trunc(FormCw.SpinBox_Exp.Value);
  UpdateWeaponUI(ASlot, W);

  // Update exotic tracking
  // If the newly equipped weapon is exotic:
  if W.Rarity = wrExotic then
  begin
    FExoticWeaponSelected := True;
    FExoticWeaponSlot := ASlot;
  end
  // Else if the weapon that was replaced in THIS slot was the single equipped exotic
  else if (OldWeaponRarity = wrExotic) and (FExoticWeaponSlot = ASlot) then
  begin
    FExoticWeaponSelected := False;
    // FExoticWeaponSlot can remain ASlot, as FExoticWeaponSelected is now false,
    // or set to a value like Game.Types.TWeaponSlot(MaxInt) to indicate no specific slot.
    // For simplicity, just setting FExoticWeaponSelected to False is enough if logic always checks it first.
  end;
  // If another exotic exists in another slot, FExoticWeaponSelected and FExoticWeaponSlot remain pointing to it.
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
  FGearSlotIndex := ord(AGearSlot); { 0-based }
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
    var CurrentTalent := FEquippedGearPieces[FGearSlotIndex].Talent;
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
      FEquippedGearPieces[FGearSlotIndex] := LSelectedPiece;

      // Restore the data transfer logic for icon indices
      FEquippedGearPieces[FGearSlotIndex].SelectedModIconIndex := FormSlots.SelectedModAttributeImageIndex;
      SetLength(FEquippedGearPieces[FGearSlotIndex].SelectedMinorIconIndices, Length(FormSlots.FSelectedMinorAttributeImageIndices));
      for var i := 0 to High(FormSlots.FSelectedMinorAttributeImageIndices) do
        FEquippedGearPieces[FGearSlotIndex].SelectedMinorIconIndices[i] := FormSlots.FSelectedMinorAttributeImageIndices[i];
    end
    else
    begin
      FEquippedGearPieces[FGearSlotIndex] := Default (TGearPiece);
    end;

//    ListBoxSetsChange(nil);
    UpdateGearSlotUI(FEquippedGearPieces[FGearSlotIndex], FGearSlotIndex);
    RefreshAllStats;
  end;
end;

procedure TMainForm.UpdateGearSlotUI(const GearPiece: TGearPiece; SlotIndex: Integer);
var
  TargetComboBox: TComboBox;
  TargetImage: TImage;
  ImgIdx: Integer;
  LBI: TListBoxItem;
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
        Result := 'Fixed: ' + Segment
      else
        Result := Result + ', ' + Segment;
    end;
  end;
begin
  // 1. Determine target UI controls for the slot
  case SlotIndex of
    0: begin TargetComboBox := Slot_gMask; TargetImage := Image_Mask; CoreBtn := M_Core_Atr; Minor1Btn := M_Atr1; Minor2Btn := M_Atr2; ModBtn := M_Mod; end;
    1: begin TargetComboBox := Slot_gBackPack; TargetImage := Image_Back; CoreBtn := B_Core_Atr; Minor1Btn := B_Atr1; Minor2Btn := B_Atr2; ModBtn := B_Mod; end;
    2: begin TargetComboBox := Slot_gVest; TargetImage := Image_Chest; CoreBtn := V_Core_Atr; Minor1Btn := V_Atr1; Minor2Btn := V_Atr2; ModBtn := V_Mod; end;
    3: begin TargetComboBox := Slot_gGlove; TargetImage := Image_Glove; CoreBtn := G_Core_Atr; Minor1Btn := G_Atr1; Minor2Btn := G_Atr2; ModBtn := G_Mod; end;
    4: begin TargetComboBox := Slot_gHolster; TargetImage := Image_Holster; CoreBtn := H_Core_Atr; Minor1Btn := H_Atr1; Minor2Btn := H_Atr2; ModBtn := H_Mod; end;
    5: begin TargetComboBox := Slot_gKneePad; TargetImage := Image_Kneepad; CoreBtn := K_Core_Atr; Minor1Btn := K_Atr1; Minor2Btn := K_Atr2; ModBtn := K_Mod; end;
  else
    Exit;
  end;

  // Cache the placeholder art once so we can restore it when clearing a slot
  if Assigned(TargetImage) and (FGearSlotPlaceholders[SlotIndex] = nil) then
  begin
    FGearSlotPlaceholders[SlotIndex] := TBitmap.Create;
    FGearSlotPlaceholders[SlotIndex].Assign(TargetImage.Bitmap);
  end;

  // 2. Update Gear Piece ComboBox (Icon and Background)
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
      // Déterminer l’index de l’icône dans TIMG_Sets
      ImgIdx := -1;
      if Assigned(DataJsonIterator) and Assigned(DataJsonIterator.AllPieceSetDefinitions) then
      begin
        var PS: TPieceSet;
        if DataJsonIterator.AllPieceSetDefinitions.TryGetValue(GearPiece.SetName, PS) then
          ImgIdx := PS.ImageIndex;
      end;

      // Afficher le logo de marque en grand dans le TImage
      if Assigned(TargetImage) then
      begin
        // Adapter la taille de l'icône à celle du slot
        if (ImgIdx >= 0) and (ImgIdx < TIMG_Sets.Source.Count) then
        begin
          SizeF := TSizeF.Create(TargetImage.Width, TargetImage.Height);
          LogoBitmap := TIMG_Sets.Bitmap(SizeF, ImgIdx); // récupère l’icône à la bonne taille
          try
            TargetImage.Bitmap.Assign(LogoBitmap);       // copie dans l’image de destination
          finally
            // ne pas libérer LogoBitmap explicitement (voir doc):contentReference[oaicite:2]{index=2}
          end;
        end
        else if Assigned(FGearSlotPlaceholders[SlotIndex]) then
          TargetImage.Bitmap.Assign(FGearSlotPlaceholders[SlotIndex]);
        TargetImage.WrapMode := TImageWrapMode.Place;     // conserve les proportions
        TargetImage.Align := TAlignLayout.Contents;         // remplit toute la tuile
        TargetImage.Visible := True;
      end;

      // Ajouter la marque dans le ComboBox (petit pictogramme facultatif)
//      LBI := TListBoxItem.Create(TargetComboBox);
//      LBI.Selectable := False;
//      LBI.Height := TargetComboBox.Height;
//      LBI.ImageIndex := ImgIdx;
//      TargetComboBox.AddObject(LBI);
      TargetComboBox.ItemIndex := 0;
      TargetComboBox.Images := TIMG_Sets;

      // Optionnel : info‑bulle et style en fonction du SetType
      var HintText := GearPiece.Name;
      var FixedHint := BuildFixedMinorText(GearPiece);
      if FixedHint <> '' then
        HintText := HintText + sLineBreak + FixedHint;
      TargetComboBox.Hint := HintText;

      case GearPiece.SetType of
        stBrandSet, stImprovised: TargetComboBox.StyleLookup := 'HighEndSlot';
        stGearSet:  TargetComboBox.StyleLookup := 'GearSetSlot';
        stNamedSet: TargetComboBox.StyleLookup := 'NamedSlot';
        stExoticSet:TargetComboBox.StyleLookup := 'ExoticSlot';
      else
        TargetComboBox.StyleLookup := 'EmptySlot';
      end;
    end;
  finally
    TargetComboBox.EndUpdate;
  end;

  // 3. Update Attribute and Mod Buttons
  // Core Attribute
  if Assigned(CoreBtn) then
  begin
    CoreBtn.ImageIndex := -1;
    CoreBtn.Text := '';
    if not GearPiece.CoreAttribute.ID.IsEmpty then
    begin
      CoreBtn.ImageIndex := ord(GearPiece.CoreAttribute.AttrType);
      CoreBtn.Text := Copy(GetEnumName(TypeInfo(TCoreAttributeType), ord(GearPiece.CoreAttribute.AttrType)), 4, 100);
    end;
  end;

  // Minor Attributes
  var RandomCount := Length(FEquippedGearPieces[SlotIndex].MinorAttributes);
  var RandomIcons := FEquippedGearPieces[SlotIndex].SelectedMinorIconIndices;
  var FixedText := BuildFixedMinorText(FEquippedGearPieces[SlotIndex]);
  var FixedDisplayed := False;

  if Assigned(Minor1Btn) then
  begin
    Minor1Btn.ImageIndex := -1;
    Minor1Btn.Text := '';
    Minor1Btn.Hint := '';
    Minor1Btn.Enabled := RandomCount > 0;
    if (RandomCount > 0) and (Length(RandomIcons) > 0) then
    begin
      Minor1Btn.ImageIndex := RandomIcons[0];
      Minor1Btn.Text :=
        GetEnumName(TypeInfo(TMinorAttributeType),
        ord(FEquippedGearPieces[SlotIndex].MinorAttributes[0].MinorAttribute));
    end
    else if (RandomCount = 0) and (FixedText <> '') then
    begin
      Minor1Btn.Text := FixedText;
      Minor1Btn.Enabled := False;
      Minor1Btn.Hint := FixedText;
      FixedDisplayed := True;
    end;
    if (FixedText <> '') and not FixedDisplayed then
    begin
      Minor1Btn.Hint := FixedText;
      Minor1Btn.ImageIndex := RandomIcons[0];
      Minor1Btn.Text :=
        GetEnumName(TypeInfo(TMinorAttributeType),
        ord(FEquippedGearPieces[SlotIndex].MinorAttributes[0].MinorAttribute));
    end
    else if (RandomCount = 0) and (FixedText <> '') then
    begin
      Minor1Btn.Text := FixedText;
      Minor1Btn.Enabled := False;
      Minor1Btn.Hint := FixedText;
      FixedDisplayed := True;
    end;
    if (FixedText <> '') and not FixedDisplayed then
      Minor1Btn.Hint := FixedText;
  end;

  if Assigned(Minor2Btn) then
  begin
    Minor2Btn.ImageIndex := -1;
    Minor2Btn.Text := '';
    Minor2Btn.Hint := '';
    Minor2Btn.Enabled := RandomCount > 1;
    if (RandomCount > 1) and (Length(RandomIcons) > 1) then
    begin
      Minor2Btn.ImageIndex := RandomIcons[1];
      Minor2Btn.Text :=
        GetEnumName(TypeInfo(TMinorAttributeType),
        ord(FEquippedGearPieces[SlotIndex].MinorAttributes[1].MinorAttribute));
    end
    else if (RandomCount <= 1) and (FixedText <> '') and not FixedDisplayed then
    begin
      Minor2Btn.Text := FixedText;
      Minor2Btn.Enabled := False;
      Minor2Btn.Hint := FixedText;
      FixedDisplayed := True;
    end;
    if FixedText <> '' then
    begin
      Minor2Btn.Hint := FixedText;
      Minor2Btn.ImageIndex := RandomIcons[1];
      Minor2Btn.Text :=
        GetEnumName(TypeInfo(TMinorAttributeType),
        ord(FEquippedGearPieces[SlotIndex].MinorAttributes[1].MinorAttribute));
    end
    else if (RandomCount <= 1) and (FixedText <> '') and not FixedDisplayed then
    begin
      Minor2Btn.Text := FixedText;
      Minor2Btn.Enabled := False;
      Minor2Btn.Hint := FixedText;
      FixedDisplayed := True;
    end;
    if FixedText <> '' then
      Minor2Btn.Hint := FixedText;
  end;

  // Mod Attribute
  if Assigned(ModBtn) then
  begin
    var HasSlot := HasModSlot(FEquippedGearPieces[SlotIndex]);
    ModBtn.Visible := HasSlot;

    if HasSlot then
    begin
      ModBtn.ImageIndex := FEquippedGearPieces[SlotIndex].SelectedModIconIndex;
      if FEquippedGearPieces[SlotIndex].ModAttribute.ModEffect <> gmetUnknown then
        ModBtn.Text := '' // Or display mod name
      else
        ModBtn.Text := '';
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
          FEquippedSkills[ASlot] := LEquippedSkill;

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
      // TargetComboBox.Items.Clear;
      TargetComboBox.StyleLookup := '';
    end
    else
    begin
      // TargetComboBox.Items.Clear;
      // TargetComboBox.Items.Add(ASkillVariant.VariantName);
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

procedure TMainForm.RefreshSkillStatsUI;
var
  LSkillSlot: TSkillSlot;
  LEquippedSkill: TEquippedSkill;
  LPlayerAggregatedStats: CalcEngine.TPlayerAggregatedStats;
  LAggregatedStats: Game.Types.TLoadoutAggregatedStats_Display;
  SkillStats: TDictionary<string, Double>;
  DamageValue, CooldownValue: Double;
begin

  // --- Calculate and Display Stats for Skill 1 ---
  for LSkillSlot := ssPrimary to ssSecondary do
  begin
    LEquippedSkill := FEquippedSkills[LSkillSlot];

    // Check if a skill is equipped by verifying the SkillID is not empty
    if LEquippedSkill.SkillID <> '' then
    begin
      SkillStats := CalcEngine.CalculateSkillPerformance(LEquippedSkill.Variant,
        LPlayerAggregatedStats, LAggregatedStats.TotalSkillTiers_Display, False,
      // IsOvercharged
      False // IsPvp
        );
      try
        // Update the correct UI labels based on the slot
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
        else // LSkillSlot = ssSecondary
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
    // If SkillID is empty, the labels for that slot remain at their default "–" value from step 1.
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
  LInput: TFullLoadoutInput;
  LPlayerAggregatedStats: CalcEngine.TPlayerAggregatedStats;
  LActivatedSpecBonuses: TArray<TWeaponFamily>;
  LWatchBonuses: Game.Types.TWatchBonuses;
  WeaponDisplays: array[TWeaponSlot] of TWeaponDisplay;
  WT: TWeaponFamily;
  WeaponSlot: TWeaponSlot;
  I: Integer;

  procedure CalculateAndDisplayWeapon(const ASlot: TWeaponSlot);
  var
    SlotInput: TFullLoadoutInput;
    SlotDamageResult: CalcEngine.TFullDamageCalcResult;
    SlotAggregatedStats: Game.Types.TLoadoutAggregatedStats_Display;
    SlotWeapon: TWeapon;
    CalculationSucceeded: Boolean;
  begin
    SlotWeapon := FSelectedWeapon[ASlot];
    ResetWeaponDisplay(WeaponDisplays[ASlot]);

    if SlotWeapon.ID = 0 then
      Exit;

    SlotInput := LInput;
    SlotInput.ActiveWeaponConfig := SlotWeapon;
    SlotInput.WeaponExpertiseLevel := FWeaponExpertiseLevels[ASlot];

    CalculationSucceeded := CalcEngine.CalculateCompleteLoadoutPerformance
      (SlotInput, DataJsonIterator.AllPieceSetDefinitions,
      DataJsonIterator.WeaponStats, DataJsonIterator.Mods,
      DataJsonIterator.Talents, SlotDamageResult, SlotAggregatedStats);

    if not CalculationSucceeded then
      Exit;

    UpdateWeaponDisplay(WeaponDisplays[ASlot], SlotDamageResult,
      SlotAggregatedStats);
  end;
begin
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

  WeaponDisplays[Game.Types.wsSecondary].TotalDamageLabel :=
    SecondaryTotalDamageLabel;
  WeaponDisplays[Game.Types.wsSecondary].AwdLabel := SecondaryAwdLabel;
  WeaponDisplays[Game.Types.wsSecondary].SwdLabel := SecondarySwdLabel;
  WeaponDisplays[Game.Types.wsSecondary].BurstDpsLabel :=
    SecondaryBurstDpsLabel;
  WeaponDisplays[Game.Types.wsSecondary].SustainDpsLabel :=
    SecondarySustainDpsLabel;
  WeaponDisplays[Game.Types.wsSecondary].ChcLabel := SecondaryChcLabel;
  WeaponDisplays[Game.Types.wsSecondary].ChdLabel := SecondaryChdLabel;
  WeaponDisplays[Game.Types.wsSecondary].AvgShotLabel :=
    SecondaryAvgShotLabel;

  WeaponDisplays[Game.Types.wsSideArm].TotalDamageLabel :=
    SidearmTotalDamageLabel;
  WeaponDisplays[Game.Types.wsSideArm].AwdLabel := SidearmAwdLabel;
  WeaponDisplays[Game.Types.wsSideArm].SwdLabel := SidearmSwdLabel;
  WeaponDisplays[Game.Types.wsSideArm].BurstDpsLabel :=
    SidearmBurstDpsLabel;
  WeaponDisplays[Game.Types.wsSideArm].SustainDpsLabel :=
    SidearmSustainDpsLabel;
  WeaponDisplays[Game.Types.wsSideArm].ChcLabel := SidearmChcLabel;
  WeaponDisplays[Game.Types.wsSideArm].ChdLabel := SidearmChdLabel;
  WeaponDisplays[Game.Types.wsSideArm].AvgShotLabel := SidearmAvgShotLabel;

  for WeaponSlot := Game.Types.wsPrimary to Game.Types.wsSideArm do
    if WeaponSlot in [Game.Types.wsPrimary, Game.Types.wsSecondary,
    Game.Types.wsSideArm] then
      ResetWeaponDisplay(WeaponDisplays[WeaponSlot]);

  SkLabel_Skill1_Damage.Words[0].Text := 'Damage: -';
  SkLabel_Skill1_Cooldown.Words[0].Text := 'Cooldown: -';
  SkLabel_Skill2_Damage.Words[0].Text := 'Damage: -';
  SkLabel_Skill2_Cooldown.Words[0].Text := 'Cooldown: -';

  FillChar(LInput, SizeOf(TFullLoadoutInput), 0);

  for I := Low(FEquippedGearPieces) to High(FEquippedGearPieces) do
    if FEquippedGearPieces[I].Name <> '' then
      LInput.EquippedGear[TItemType(I)] := FEquippedGearPieces[I];

  LInput.ChosenSpecialization := FSelectedSpecialization;

  SetLength(LActivatedSpecBonuses, 0);
  for WT := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WT)) and WeaponChk(WT).IsChecked then
    begin
      SetLength(LActivatedSpecBonuses, Length(LActivatedSpecBonuses) + 1);
      LActivatedSpecBonuses[High(LActivatedSpecBonuses)] := WT;
    end;
  LInput.ActivatedSpecWeaponTypeBonuses := LActivatedSpecBonuses;

  LWatchBonuses := DefaultWatchBonuses;
  LInput.WatchBonuses := LWatchBonuses;

  if not Assigned(DataJsonIterator) or
    not Assigned(DataJsonIterator.AllPieceSetDefinitions) or
    not Assigned(DataJsonIterator.WeaponStats) or
    not Assigned(DataJsonIterator.Mods) or not Assigned(DataJsonIterator.Talents)
  then
  begin
    ShowMessage
      ('Error: Core data dictionaries not loaded. Cannot calculate stats.');
    Exit;
  end;

  for WeaponSlot := Game.Types.wsPrimary to Game.Types.wsSideArm do
    if WeaponSlot in [Game.Types.wsPrimary, Game.Types.wsSecondary,
    Game.Types.wsSideArm] then
      CalculateAndDisplayWeapon(WeaponSlot);

  LPlayerAggregatedStats := CalcEngine.AggregatePlayerStats(LInput,
    DataJsonIterator.AllPieceSetDefinitions);

  RefreshSkillStatsUI;
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
          FreeSerializableLoadout(LLoadout);
        FSavedLoadouts.Remove(LSelectedName);
        TLoadoutManager.SaveLoadouts(FSavedLoadouts);
        LoadoutList.Items.Delete(LSelected.Index);
        ShowMessage('Loadout deleted.');
      end;
    end);
end;

procedure TMainForm.ApplySerializableLoadout(const ALoadout: TSerializableLoadout);
var
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
      catWeaponDamage:
        Result := 'weaponDamage';
      catArmor:
        Result := 'armor';
      catSkillTier:
        Result := 'skillTier';
    else
      Result := '';
    end;
  end;

  function CoreAttrDisplayName(const AttrID: string): string;
  var
    CoreDef: TCoreAttributeDefinition;
  begin
    Result := '';
    if Assigned(DataJsonIterator) and
       Assigned(DataJsonIterator.CoreAttributeDefinitions) and
       DataJsonIterator.CoreAttributeDefinitions.TryGetValue(AttrID, CoreDef) then
      Exit(CoreDef.TypeName);

    if SameText(AttrID, 'weaponDamage') then
      Result := 'Weapon Damage'
    else if SameText(AttrID, 'armor') then
      Result := 'Armor'
    else if SameText(AttrID, 'skillTier') then
      Result := 'Skill Tier';
  end;
begin
  // Clear current loadout
  for var il := Low(FEquippedGearPieces) to High(FEquippedGearPieces) do
    FEquippedGearPieces[il] := Default(TGearPiece);
  for LWeaponSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    FSelectedWeapon[LWeaponSlot] := Default(TWeapon);
    FWeaponSelectedTalentIDs[LWeaponSlot] := 0;
  end;

  // Apply Gear
  for LItemType in ALoadout.GearPieces.Keys do
  begin
    var SGearPiece := ALoadout.GearPieces[LItemType];
    var Found := False;

    // 1) Prefer set + name (exact part in the right set)
    if (SGearPiece.SetName <> '') and Assigned(DataJsonIterator)
       and Assigned(DataJsonIterator.AllPieceSetDefinitions) then
    begin
      var PS: TPieceSet;
      if DataJsonIterator.AllPieceSetDefinitions.TryGetValue(SGearPiece.SetName, PS) then
        for var Part in PS.Parts do
          if SameText(Part.Name, SGearPiece.PieceName) then
          begin
            LGearPiece := Default(TGearPiece);
            LGearPiece.Name := Part.Name;
            LGearPiece.SetName := PS.Name;
            LGearPiece.ItemType := Part.GearSlot;
            LGearPiece.CoreAttribute.ID := Part.CoreAttributeID;
            LGearPiece.CoreAttribute.AttrType := CoreAttrIDToEnum(Part.CoreAttributeID);
            LGearPiece.SetType := PS.SetType;
            LGearPiece.Bonuses := PS.Bonuses;
            SetLength(LGearPiece.FixedMinorAttributes, 0);
            if (Length(Part.FixedMinorAttributeIDs) > 0) and
               Assigned(DataJsonIterator) and
               Assigned(DataJsonIterator.FixedMinorAttributeDefinitions) then
            begin
              for var FixedId in Part.FixedMinorAttributeIDs do
                if DataJsonIterator.FixedMinorAttributeDefinitions.TryGetValue(FixedId, FixedDef) then
                begin
                  var Len := Length(LGearPiece.FixedMinorAttributes);
                  SetLength(LGearPiece.FixedMinorAttributes, Len + 1);
                  LGearPiece.FixedMinorAttributes[Len] := FixedDef;
                end;
            end;
            SetLength(LGearPiece.FixedMinorAttributes, 0);
            if (Length(Part.FixedMinorAttributeIDs) > 0) and
               Assigned(DataJsonIterator) and
               Assigned(DataJsonIterator.FixedMinorAttributeDefinitions) then
            begin
              for var FixedId in Part.FixedMinorAttributeIDs do
                if DataJsonIterator.FixedMinorAttributeDefinitions.TryGetValue(FixedId, FixedDef) then
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

    // 2) Fallback: global by name (handles Named/Exotic too)
    if not Found then
      Found := DataJsonIterator.FindFullGearPiece(SGearPiece.PieceName, LGearPiece);

    if not Found then
    begin
      FEquippedGearPieces[Ord(LItemType)] := Default(TGearPiece);
      Continue; // go to next slot
    end;

    // From here down, keep your existing "restore saved fields":
    if SGearPiece.CoreAttributeTypeStr <> '' then
    begin
      try
        var OrdValue := GetEnumValue(TypeInfo(TCoreAttributeType),
          SGearPiece.CoreAttributeTypeStr);
        if OrdValue >= 0 then
        begin
          LGearPiece.CoreAttribute.AttrType :=
            TCoreAttributeType(OrdValue);
          LGearPiece.CoreAttribute.ID :=
            CoreAttrIdFromEnum(LGearPiece.CoreAttribute.AttrType);
          if LGearPiece.CoreAttribute.ID <> '' then
            LGearPiece.CoreAttribute.TypeName :=
              CoreAttrDisplayName(LGearPiece.CoreAttribute.ID);
        end;
      except
        on E: EIntError do
          ; // Ignore invalid enum names and keep defaults
      end;
    end;

    LGearPiece.CoreAttribute.Value := SGearPiece.CoreAttributeValue;

    // Minor attributes
    SetLength(LGearPiece.MinorAttributes, Length(SGearPiece.MinorAttributeTypeStrs));
    for var ic := 0 to High(SGearPiece.MinorAttributeTypeStrs) do
    begin
      LGearPiece.MinorAttributes[ic].MinorAttribute :=
        TMinorAttributeType(GetEnumValue(TypeInfo(TMinorAttributeType),
        SGearPiece.MinorAttributeTypeStrs[ic]));
      LGearPiece.MinorAttributes[ic].AttrType :=
        MinorAttributeTypeForDetails(LGearPiece.MinorAttributes[ic].MinorAttribute);

      if (Length(SGearPiece.MinorAttributeValues) > ic) and (SGearPiece.MinorAttributeValues[ic] > 0) then
        LGearPiece.MinorAttributes[ic].Value := SGearPiece.MinorAttributeValues[ic]
      else
        LGearPiece.MinorAttributes[ic].Value :=
          GetDefaultMinorAttributeValue(LGearPiece.MinorAttributes[ic].MinorAttribute);
    end;

    // Icons
    if Length(SGearPiece.FixedMinorAttributeIDs) > 0 then
    begin
      SetLength(LGearPiece.FixedMinorAttributes, 0);
      if Assigned(DataJsonIterator) and
         Assigned(DataJsonIterator.FixedMinorAttributeDefinitions) then
        for var FixedId in SGearPiece.FixedMinorAttributeIDs do
          if DataJsonIterator.FixedMinorAttributeDefinitions.TryGetValue(FixedId, FixedDef) then
          begin
            var Len := Length(LGearPiece.FixedMinorAttributes);
            SetLength(LGearPiece.FixedMinorAttributes, Len + 1);
            LGearPiece.FixedMinorAttributes[Len] := FixedDef;
          end;
    end;

    if Length(SGearPiece.FixedMinorAttributeIDs) > 0 then
    begin
      SetLength(LGearPiece.FixedMinorAttributes, 0);
      if Assigned(DataJsonIterator) and
         Assigned(DataJsonIterator.FixedMinorAttributeDefinitions) then
        for var FixedId in SGearPiece.FixedMinorAttributeIDs do
          if DataJsonIterator.FixedMinorAttributeDefinitions.TryGetValue(FixedId, FixedDef) then
          begin
            var Len := Length(LGearPiece.FixedMinorAttributes);
            SetLength(LGearPiece.FixedMinorAttributes, Len + 1);
            LGearPiece.FixedMinorAttributes[Len] := FixedDef;
          end;
    end;

    LGearPiece.SelectedMinorIconIndices := SGearPiece.MinorIconIndices;
    LGearPiece.SelectedModIconIndex := SGearPiece.ModIconIndex;

    // Talent
    LGearPiece.Talent := SGearPiece.TalentName;

    // Mod attribute (if any)
    if SGearPiece.ModID <> 0 then
    begin
      if (DataJsonIterator.GearModsData <> nil) and
         DataJsonIterator.GearModsData.TryGetValue(SGearPiece.ModID, ModDef) then
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
    end
    else
    begin
      LGearPiece.ModAttribute.ModEffect := gmetUnknown;
      LGearPiece.ModAttribute.Value := 0;
      LGearPiece.ModID := 0;
    end;

    FEquippedGearPieces[Ord(LItemType)] := LGearPiece;
  end;

  // Apply Weapons
  for LWeaponSlot in ALoadout.Weapons.Keys do
  begin
    var SWeapon := ALoadout.Weapons[LWeaponSlot];
    if DataJsonIterator.Weapons.TryGetValue(SWeapon.WeaponID, LWeapon) then
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

  // Apply Specialization
  if FSpecializations.TryGetValue(ALoadout.SpecializationName, FSelectedSpecialization) then
  begin
    Slot_Specialization.ItemIndex := Slot_Specialization.Items.IndexOf(ALoadout.SpecializationName);
    for var WT := Low(TWeaponFamily) to High(TWeaponFamily) do
      if Assigned(WeaponChk(WT)) then
        WeaponChk(WT).IsChecked := StringInArray(WT, ALoadout.ActivatedSpecBonuses);
    UpdateSpecWeaponChkAvailability;
  end;

  // Apply Skills
  for var LSkillSlot in ALoadout.Skills.Keys do
  begin
    var SSkill := ALoadout.Skills[LSkillSlot];
    var LSkillData: TSkillData;
    if DataJsonIterator.Skills.TryGetValue(SSkill.SkillID, LSkillData) then
    begin
      for var LVariant in LSkillData.Variants do
      begin
        if LVariant.VariantName = SSkill.VariantName then
        begin
          FEquippedSkills[LSkillSlot].SkillID := SSkill.SkillID;
          FEquippedSkills[LSkillSlot].Variant := LVariant;
          Break;
        end;
      end;
    end;
  end;

  // --- UI REFRESH ---
  for LWeaponSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
    UpdateWeaponUI(LWeaponSlot, FSelectedWeapon[LWeaponSlot]);

  for var ig := 0 to High(FEquippedGearPieces) do
    UpdateGearSlotUI(FEquippedGearPieces[ig], ig);

  for var LSkillSlot := Low(TSkillSlot) to High(TSkillSlot) do
    UpdateSkillUI(LSkillSlot, FEquippedSkills[LSkillSlot].Variant);
  RefreshAllStats;
end;

procedure TMainForm.ApplyBuild(const ABuild: TGearLoadout);
var
  I: Integer;
  LWeaponSlot: TWeaponSlot;
begin
  // Apply Gear
  for I := 0 to High(ABuild.GearPieces) do
  begin
    FEquippedGearPieces[I] := ABuild.GearPieces[I];
    UpdateGearSlotUI(FEquippedGearPieces[I], I);
  end;

  // Apply Weapons
  for LWeaponSlot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    if ord(LWeaponSlot) < Length(ABuild.Weapons) then
    begin
      FSelectedWeapon[LWeaponSlot] := ABuild.Weapons[LWeaponSlot];
      UpdateWeaponUI(LWeaponSlot, ABuild.Weapons[LWeaponSlot]);
    end;
  end;

  RefreshAllStats;
end;

procedure TMainForm.btnShowBestDpsBuildClick(Sender: TObject);
begin
//  GenerateAndApplyPredefinedBuild(GetDpsBuildArchetype);
  ShowSidePanel(catWeaponDamage);
end;

procedure TMainForm.btnShowBestTankBuildClick(Sender: TObject);
begin
//  GenerateAndApplyPredefinedBuild(GetTankBuildArchetype);
  ShowSidePanel(catArmor);
end;

procedure TMainForm.btnShowBestSkillBuildClick(Sender: TObject);
begin
//  GenerateAndApplyPredefinedBuild(GetSkillBuildArchetype);
  ShowSidePanel(catSkillTier);
end;

procedure TMainForm.btnShowBestSupportBuildClick(Sender: TObject);
begin
//  GenerateAndApplyPredefinedBuild(GetSupportBuildArchetype);
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
      if (N = 'armor_regen') or (N = 'armor_regen_pct') then AddUnique(madArmorRegen)
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
      else if N = 'weapon_handling' then AddUnique(madWeaponHandling)
      // Map resistance subtypes to Hazard Protection if exact match not found in TMinorAttributeType
      // TMinorAttributeType has: madExplosiveResistance, madHazardProtection.
      // It does NOT have specific Disrupt/Pulse/Shock resistances.
      // Usually, if a user wants "Shock Resistance", they might accept Hazard Protection (which covers all),
      // or we can't enforce it as a minor attribute on standard gear because standard gear only rolls Hazard Protection.
      // Specific resistances usually come from Mods or Brand Bonuses.
      // So we map them to nothing here (relying on Brand weights) OR map to Hazard Protection if appropriate.
      // For now, let's strictly map only what exists on gear minors.
      ;
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
var
  AttrID: string;
  RequiredMinor: TArray<TMinorAttributeType>;
  SlotList: TList<TItemType>;
  ModSlots: TArray<TItemType>;
  AllSlots: TArray<TItemType>;
  i: Integer;

  // Nested function must be declared before begin
  function BuildWithSlots(const Slots: TArray<TItemType>): Boolean;
  begin
    Result := False;
    if Length(Slots) = 0 then Exit;
    GenerateAndApplyPredefinedBuild(
      procedure(var AArchetype: TBuildArchetype)
      begin
        case FGenerationContext of
          catWeaponDamage: GetDpsBuildArchetype(AArchetype);
          catArmor: GetTankBuildArchetype(AArchetype);
          catSkillTier: GetSkillBuildArchetype(AArchetype);
        else
          GetDpsBuildArchetype(AArchetype);
        end;

        // Assign weights based on selected attributes
//        if not Assigned(AArchetype.AttributeWeights) then
//          AArchetype.AttributeWeights := TDictionary<string, Double>.Create;
        AArchetype.AttributeWeights.Clear;
        for var AttrID in FSelectedAttributeIDs do
          AArchetype.AttributeWeights.AddOrSetValue(AttrID, 100.0); // High priority

        // Do NOT clear RequiredCoreAttribute here.
        // If we clear it, we lose the "Tank" (Armor) or "Skill" (SkillTier) requirement set by GetTankBuildArchetype/etc.
        // We want to keep that requirement so we generate a build of the correct archetype.

        // Also do NOT enforce AllowedBrandSets/RequiredBrandSets based on attributes.
        // Strict enforcement often leads to "No builds found" if the brands providing the bonus
        // don't match the Core Attribute (e.g. Red Bonus on Blue Core) or if multiple Gear Sets
        // require too many slots (e.g. HSD on 3 sets = 9 pieces).
        // Instead, we rely on AttributeWeights (set above) to prioritize brands that have the bonus.

        if (Length(RequiredMinor) > 0) and Assigned(AArchetype.RequiredAttributes) then
        begin
          var AttrIdx := 0;
          for var idx := Low(Slots) to High(Slots) do
          begin
            if AttrIdx < Length(RequiredMinor) then
            begin
              var Single: TArray<TMinorAttributeType>;
              SetLength(Single, 1);
              Single[0] := RequiredMinor[AttrIdx];
              AArchetype.RequiredAttributes.AddOrSetValue(Slots[idx], Single);
              Inc(AttrIdx);
            end;
          end;
        end;
      end);
    Result := Assigned(FGeneratedBuilds) and (FGeneratedBuilds.Count > 0);
  end;

begin
  if FSelectedAttributeIDs.Count = 0 then
    Exit;

  // Try to generate builds using selected attribute(s) placed on mod-capable slots first, then fallback.
  RequiredMinor := MapSelectedAttributesToMinorTypes;

  // Build list of mod-capable slots
  SlotList := TList<TItemType>.Create;
  try
    for var Slot := Low(TItemType) to itKneepads do
    begin
      var Dummy: TGearPiece := Default(TGearPiece);
      Dummy.ItemType := Slot;
      if HasModSlot(Dummy) then
        SlotList.Add(Slot);
    end;
    ModSlots := SlotList.ToArray;
    // If no mod-capable slots were found, default to backpack/chest/mask
    if Length(ModSlots) = 0 then
      ModSlots := TArray<TItemType>.Create(itBackpack, itChest, itMask);

    if not BuildWithSlots(ModSlots) then
    begin
      // Fallback: allow any slots if mod-only placement was too strict
      SetLength(AllSlots, Ord(itKneepads) + 1);
      for i := Ord(Low(TItemType)) to Ord(itKneepads) do
        AllSlots[i] := TItemType(i);
      BuildWithSlots(AllSlots);
    end;
  finally
    SlotList.Free;
  end;
end;

procedure TMainForm.ShowSidePanel(AContext: TCoreAttributeType);
begin
  FGenerationContext := AContext;
  GridPanelLayoutLookup.Visible := True;
  PopulateAttributesList;

  case AContext of
    catWeaponDamage: LabelLookupTitle.Text := 'DPS Attributes Lookup';
    catArmor: LabelLookupTitle.Text := 'Tank Attributes Lookup';
    catSkillTier: LabelLookupTitle.Text := 'Skill/Support Attributes Lookup';
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

procedure TMainForm.ListViewAttributesSearchChange(Sender: TObject);
var
  I: Integer;
  LSearch: string;
  SearchBox: TSearchBox;
  List: TListView;
begin
//  LSearch := LowerCase(Trim(SearchBox.Text));
  ListViewAttributes.BeginUpdate;
  try
    List := Sender as TListView;
    for I := 0 to List.Controls.Count - 1 do
    begin
      if List.Controls[I].ClassType = TSearchBox then
      begin
        SearchBox := TSearchBox(List.Controls[I]);
        Break;
      end;
//      ListBoxAttributes.ListItems[I].Visible := (LSearch = '') or (Pos(LSearch, LowerCase(ListBoxAttributes.ListItems[I].Text)) > 0);
    end;
  finally
    ListViewAttributes.EndUpdate;
  end;
end;

procedure TMainForm.ListViewAttributesItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  LSelectedAttr: string;
  LBrandSet: TPieceSet;
  LBonus: TSetBonus;
  LMatch: Boolean;
  LText: string;
  LAllowedBrands: TList<string>;
begin
  if AItem = nil then Exit;
  LSelectedAttr := NormalizeAttributeId(AItem.TagString);
  if LSelectedAttr = '' then
    LSelectedAttr := NormalizeAttributeId(AItem.Text);

  if FSelectedAttributeIDs.Contains(LSelectedAttr) then
    FSelectedAttributeIDs.Remove(LSelectedAttr)
  else
  begin
    if FSelectedAttributeIDs.Count >= 3 then
    begin
      ShowMessage('You can only select up to 3 attributes.');
      AItem.Checked := False;
      AItem.Accessory := TAccessoryType.More;
      Exit;
    end;
    FSelectedAttributeIDs.Add(LSelectedAttr);
  end;

  // Update visual state
  UpdateAttributeItemSelected(AItem, LSelectedAttr);

  // Recompute all items' selected state for consistency
  for var idx := 0 to ListViewAttributes.Items.Count - 1 do
    UpdateAttributeItemSelected(ListViewAttributes.Items[idx], ListViewAttributes.Items[idx].TagString);

  // Regenerate builds based on all selected attributes
  BuildFromSelectedAttributes;
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
      for var B in LBuilds do
      begin
        var Counts := TDictionary<string, Integer>.Create;
        try
          for var GP in B.GearPieces do
          begin
            if GP.SetName <> '' then
            begin
              var c: Integer := 0;
              Counts.TryGetValue(GP.SetName, c);
              Counts.AddOrSetValue(GP.SetName, c + 1);
            end;
          end;
          var HasBreakpoint := False;
          for var Pair in Counts do
          begin
            if Pair.Value >= 2 then
            begin
              HasBreakpoint := True;
              Break;
            end;
          end;
          if HasBreakpoint then
            Filtered.Add(B);
        finally
          Counts.Free;
        end;
      end;
      if (Filtered.Count > 0) then
        LBuilds := Filtered
      else
        Filtered.Free; // fallback to originals if no breakpoint build found
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
  LBuildName: string;
  LGearPiece: TGearPiece;
begin
  if Assigned(FGeneratedBuilds) then
    FGeneratedBuilds.Free;
  FGeneratedBuilds := ABuilds;

  ListView1.Items.Clear;
  ListView1.BeginUpdate;
  try
    for I := 0 to FGeneratedBuilds.Count - 1 do
    begin
      LBuildName := Format('Build %d (Score: %.1f): ', [I + 1, FGeneratedBuilds[I].Score]);
      for LGearPiece in FGeneratedBuilds[I].GearPieces do
      begin
        if LGearPiece.Name <> '' then
          LBuildName := LBuildName + LGearPiece.SetName + ', ';
      end;
      LItem := ListView1.Items.Add;
      LItem.Text := Copy(LBuildName, 1, Length(LBuildName) - 2);
      LItem.Tag := I;
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
var
  LGearPiece: TGearPiece;
  LWeapon: TWeapon;
  LItemType: TItemType;
  LWeaponSlot: TWeaponSlot;
  SGearPiece: TSerializableGearPiece;
  i: Integer;
begin
  Result.Name := AName;
  Result.GearPieces := TDictionary<TItemType, TSerializableGearPiece>.Create;
  Result.Weapons := TDictionary<TWeaponSlot, TSerializableWeapon>.Create;
  Result.Skills := TDictionary<TSkillSlot, TSerializableSkill>.Create;

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
        Assigned(DataJsonIterator) and Assigned(DataJsonIterator.GearModsData) then
      begin
        SGearPiece.ModID := 0;
        for var Pair in DataJsonIterator.GearModsData do
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
      var SWeapon: TSerializableWeapon;
      SWeapon.WeaponID := LWeapon.ID;
      SWeapon.EquippedModIDs := TDictionary<TModSlot, Integer>.Create;
      for var ModSlot := Low(TModSlot) to High(TModSlot) do
        if LWeapon.EquippedMods[ModSlot] <> 0 then
          SWeapon.EquippedModIDs.Add(ModSlot, LWeapon.EquippedMods[ModSlot]);
      SWeapon.SelectedTalentID := LWeapon.ChosenTalentID;
      SWeapon.SelectedMinorAttributeType := LWeapon.SelectedMinorAttributeType;
      SWeapon.ExpertiseLevel := FWeaponExpertiseLevels[LWeaponSlot]; // Assuming no UI for this yet
      Result.Weapons.Add(LWeaponSlot, SWeapon);
    end;
  end;

  // Serialize Specialization
  Result.SpecializationName := FSelectedSpecialization.Name;
  var LActivatedBonuses: TArray<TWeaponFamily>;
  SetLength(LActivatedBonuses, 0);
  for var WT: TWeaponFamily := Low(TWeaponFamily) to High(TWeaponFamily) do
    if Assigned(WeaponChk(WT)) and WeaponChk(WT).IsChecked then
    begin
      SetLength(LActivatedBonuses, Length(LActivatedBonuses) + 1);
      LActivatedBonuses[High(LActivatedBonuses)] := WT;
    end;
  Result.ActivatedSpecBonuses := LActivatedBonuses;
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
  if FSavedLoadouts.TryGetValue(AItem.Text, LLoadout) then
  begin
    ApplySerializableLoadout(LLoadout);
  end;
  MultiView_Loadout.HideMaster;
end;

procedure TMainForm.LoadoutListItemClickEx(const Sender: TObject;
  ItemIndex: Integer; const LocalClickPos: TPointF;
const ItemObject: TListItemDrawable);
begin
  if ItemObject.Name = 'Title' then
  begin
    EditTitle.Text := (ItemObject as TListItemText).Text;
    EditTitle.Position.X := LoadoutList.LocalToAbsolute
      (PointF(0, ItemIndex * LoadoutList.ItemAppearance.ItemHeight)).X +
      LocalClickPos.X;
    EditTitle.Position.Y := LoadoutList.LocalToAbsolute
      (PointF(0, ItemIndex * LoadoutList.ItemAppearance.ItemHeight)).Y +
      LocalClickPos.Y;
    EditTitle.Width := (ItemObject as TListItemText).Width;
    EditTitle.Visible := True;
    EditTitle.SetFocus;
    EditTitle.Tag := ItemIndex;
    // Store the item index in the Tag property
  end
  else
    Exit;
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
    FreeSerializableLoadout(LExisting);
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
  LKey: string;
  LKeys: TArray<string>;
  I: Integer;
begin
  if not Assigned (FSavedLoadouts) then
    Exit;
  LKeys := FSavedLoadouts.Keys.ToArray;
  for I := 0 to High(LKeys) do
  begin
    LKey := LKeys[I];
    LLoadout := FSavedLoadouts.Items[LKey];
    FreeSerializableLoadout(LLoadout);
    FSavedLoadouts.Items[LKey] := LLoadout;
  end;

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
  LLoadoutValues := FSavedLoadouts.Values.ToArray;
  for I := 0 to High(LLoadoutValues) do
  begin
    LLoadout := LLoadoutValues[I];
    var
    LItem := LoadoutList.Items.Add;
    LItem.Text := LLoadout.Name;
    // You can set other details here if your list view supports it
  end;
end;

procedure TMainForm.ResetClick(Sender: TObject);
var
  Slot: TWeaponSlot;
  SkillSlot: TSkillSlot;
  WF: TWeaponFamily;
  I: Integer;
begin
  // Reset weapons (data + UI)
  FExoticWeaponSelected := False;
  FExoticWeaponSlot := wsNone;
  for Slot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    FSelectedWeapon[Slot] := Default(TWeapon);
    FWeaponSelectedTalentIDs[Slot] := 0;
    FWeaponExpertiseLevels[Slot] := 0;
    UpdateWeaponUI(Slot, FSelectedWeapon[Slot]);
  end;

  // Reset gear pieces
  for I := Low(FEquippedGearPieces) to High(FEquippedGearPieces) do
  begin
    FEquippedGearPieces[I] := Default(TGearPiece);
    UpdateGearSlotUI(FEquippedGearPieces[I], I);
  end;

  // Reset skills
  for SkillSlot := ssPrimary to ssSecondary do
  begin
    FEquippedSkills[SkillSlot] := Default(TEquippedSkill);
    UpdateSkillUI(SkillSlot, FEquippedSkills[SkillSlot].Variant);
  end;

  // Reset specialization and weapon-type bonuses
  FSelectedSpecialization := Default(TSpecialization);
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
var
  I: Integer;
begin
  if DataJsonIterator = nil then // première Form seulement
  begin
    DataJsonIterator := TDataJsonIterator.Create(nil);
    DataJsonIterator.Reload; // ↔ charge toutes les ressources
  end;

  SetSavedLoadouts(TLoadoutManager.LoadLoadouts);
  { 1) spécialisation + bonus armes + bonus watch }
  FSpecializations := TDictionary<string, TSpecialization>.Create;
  FillSpecializations;
  Slot_Specialization.ItemIndex := -1;
  for var Slot := Low(TWeaponSlot) to High(TWeaponSlot) do
  begin
    FWeaponExpertiseLevels[Slot] := 0;
    FWeaponSelectedTalentIDs[Slot] := 0;
  end;

  { 2) trois slots armes }
  for var Slot := Low(TWeaponSlot) to High(TWeaponSlot) do
    FSelectedWeapon[Slot] := Default (TWeapon);
  FExoticWeaponSelected := False;
  FExoticWeaponSlot := wsNone;

  // Initialize the GearPieces
  SetLength(FEquippedGearPieces, 6);
  for I := 0 to High(FEquippedGearPieces) do
    FEquippedGearPieces[I] := Default (TGearPiece);
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
  I: Integer;
begin
  ClearSavedLoadouts;

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
  for I := Low(FGearSlotPlaceholders) to High(FGearSlotPlaceholders) do
    FreeAndNil(FGearSlotPlaceholders[I]);
  Inherited;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  // GridPanelLayout1.ColumnCollection := Self.ClientWidth div 200;
  // GridPanelLayout1.Rows := Self.ClientHeight div 200;
end;

end.
