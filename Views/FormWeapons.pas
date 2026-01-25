unit FormWeapons;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Rtti,
  System.Variants, FMX.DialogService,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.ListBox, System.ImageList,
  FMX.ImgList, FMX.Edit, FMX.EditBox, FMX.SpinBox, System.Skia, FMX.Skia,
  FMX.Objects, System.JSON.Types, System.JSON.Builders, System.JSON.Readers,
  System.IOUtils,
  System.Generics.Collections, System.TypInfo, Utils, Game.Types,
  CalcEngine, Game.JsonIterator;

type
  TWeaponChangedEvent = procedure(Sender: TObject; const NewWeapon: TWeapon)
    of object;

  TFormCw = class(TForm)
    FootBar: TToolBar;
    OK: TSpeedButton;
    Cancel: TSpeedButton;
    FlowLayout1: TFlowLayout;
    Layout_Left: TLayout;
    Weapons: TGroupBox;
    Exo_weapons: TListBox;
    Splitter1: TSplitter;
    Layout_Right: TLayout;
    ImageListWeapons: TImageList;
    CoreAtt1: TSpinBox;
    CoreAtt2: TSpinBox;
    Wepaons_Mods: TGroupBox;
    Layout_CoreAttr: TLayout;
    SkLabel_Core: TSkLabel;
    Layout_MinorAttr: TLayout;
    SkLabel_Minor: TSkLabel;
    Layout_Base_: TLayout;
    Layout_Base: TLayout;
    Named_weapons: TListBox;
    Reg_weapons: TListBox;
    GridPanelLayout1: TGridPanelLayout;
    Exo: TLabel;
    Named: TLabel;
    HighEnd: TLabel;
    Layout_ExpT: TLayout;
    SkLabel_ExpT: TSkLabel;
    SpinBox_Exp: TSpinBox;
    SkLabel_wp: TSkLabel;
    SkSvg_core2: TSkSvg;
    SkLabel_core2: TSkLabel;
    SkLabel_core1: TSkLabel;
    SkSvg_core1: TSkSvg;
    Layout3: TLayout;
    ComboBox_minor: TComboBox;
    SkLabel1: TSkLabel;
    SkSvg_minor: TSkSvg;
    Att_3: TSpinBox;
    Layout_expValue: TLayout;
    SkSvg1: TSkSvg;
    Layout_wph: TLayout;
    Layout_wp_acc: TLayout;
    Wp_Stab: TSkLabel;
    Layout_wp_stab: TLayout;
    Wp_Acc: TSkLabel;
    SkLabel4: TSkLabel;
    Layout_container: TLayout;
    ProgressBar_Acc: TProgressBar;
    ProgressBar_Stab: TProgressBar;
    Layout_wp_rld: TLayout;
    Wp_reload: TSkLabel;
    Wp_reload_sec: TSkLabel;
    Layout_mods: TLayout;
    SkLabel_mods: TSkLabel;
    Optics_Mods: TComboBox;
    Magazine_Mods: TComboBox;
    Underbarel_Mods: TComboBox;
    Muzzle_Mods: TComboBox;
    Image_optic: TImage;
    Layout_Talents: TLayout;
    SkLabel_talent: TSkLabel;
    TalentsBox: TComboBox;
    ImgTalent: TImage;
    TalentsDesc: TText;
    Layout1_CoreStats: TLayout;
    SkLabel_CoreStats: TSkLabel;
    Layout_StatsValues: TLayout;
    SkLabel_TotalDmg: TSkLabel;
    SkLabel_RPM: TSkLabel;
    SkLabel5: TSkLabel;
    GridPanelLayout2: TGridPanelLayout;
    SkLabel_TDmgValue: TSkLabel;
    SkLabel_RPMValue: TSkLabel;
    SkLabel_MagValue: TSkLabel;
    GridPanelLayout3: TGridPanelLayout;
    GridPanelLayout4: TGridPanelLayout;
    SkLabel2: TSkLabel;
    SkLabel3: TSkLabel;
    SkLabel6: TSkLabel;
    SkLabel7: TSkLabel;
    Image_mag: TImage;
    Image_muzzle: TImage;
    Image_underbarrel: TImage;
    Desc: TLayout;
    DmgLyt: TLayout;
    SkLabel_BurstDPS: TSkLabel;
    SkLabel_SustainDPS: TSkLabel;
    Layout1: TLayout;
    Weapon_CHC: TSkLabel;
    Weapon_CHD: TSkLabel;
    GridPanelLayout5: TGridPanelLayout;
    Layout_wp_range: TLayout;
    SkLabel_OptimalRange: TSkLabel;
    procedure FormCreate(Sender: TObject);
    procedure OKClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure WeaponListChange(Sender:TObject);
    procedure ModComboChange(Sender:TObject);
    procedure TalentChange(Sender:TObject);
    procedure SpinBoxExpChange(Sender:TObject);
    procedure ComboBox_minorChange(Sender: TObject);
  private
    { Private declarations }
    FSelectedWeapon: TWeapon;
    FOnWeaponChanged: TWeaponChangedEvent;
    FFilterFamilies: TArray<TWeaponFamily>;
    // effet cumulés des quatre mods
    FModBonusEffects: TModEffectsArray;
    FModDrawbackEffects: TModEffectsArray;
    //
    procedure UpdateExpertiseLabel;
    procedure EnsureListBoxHeader(ListBox: TListBox; Category: String);
//    procedure EnsureListBoxHeader(const LB: TListBox; const Caption: string);
    procedure FillWeaponLists;          // premier remplissage
    procedure SetSelectedWeaponID(ID:Integer);
    procedure SetFilterFamilies(const AFamilies: TArray<TWeaponFamily>);
    procedure FillModsForWeapon(const W:TWeapon);
    procedure FillTalentsForWeapon(const W:TWeapon);

    procedure ShowAttribute(const Lbl:TSkLabel; const AName:string;
                                const AValue:Double);
    function FindModByID(ID:Integer):TWeaponMod;
    function IsModTypeCompatible(const ModTypeToTest: string; const AllowedTypes: TArray<string>): Boolean;
    procedure DisplaySingleModStatsInUI(const TargetLabel: TSkLabel; ModID: Integer);
    procedure RecalcDerivedValues;
  public
    { Public declarations }
    procedure LoadExistingWeaponState(const AWeapon: TWeapon; AExpertiseLevel: Integer);
    property SelectedWeapon : TWeapon read FSelectedWeapon;
    //
    property OnWeaponChanged : TWeaponChangedEvent read FOnWeaponChanged write FOnWeaponChanged;
    property FilterFamilies : TArray<TWeaponFamily> read FFilterFamilies write SetFilterFamilies;
  end;

var
  FormCw: TFormCw;

implementation

{$R *.fmx}

uses
  StrUtils, System.Math;

{ TWeapon }

{$REGION' Helpers'}

function WeaponFamilyToString(WF: TWeaponFamily): string;
begin
  case WF of
    wcAR     : Result := 'Assault Rifle';
    wcSMG    : Result := 'Submachine Gun';
    wcLMG    : Result := 'Light Machine Gun';
    wcSTG    : Result := 'Shotgun';
    wcMMR    : Result := 'Marksman Rifle';
    wcRIFLE  : Result := 'Rifle';
    wcPISTOL : Result := 'Pistol';
  else
    Result := 'Unknown';
  end;
end;

function ModSlotToString(S:TModSlot):string;
begin
  Result := GetEnumName(TypeInfo(TModSlot),Ord(S));
end;

function TFormCw.IsModTypeCompatible(const ModTypeToTest: string; const AllowedTypes: TArray<string>): Boolean;
var
  S: string;
begin
  Result := False;
  if Length(AllowedTypes) = 0 then // If the weapon defines no allowed types for this slot
    Exit(False);
  for S in AllowedTypes do
  begin
    if SameText(S, ModTypeToTest) then // Use System.SysUtils.SameText
    begin
      Result := True;
      Exit;
    end;
  end;
end;

{$ENDREGION}

{$REGION' Parsers'}

{ ════════════════════════════════════════════════════════════════════ }
{  1/ Liste des armes                                                  }
{ ════════════════════════════════════════════════════════════════════ }

procedure TFormCw.EnsureListBoxHeader(ListBox: TListBox; Category: String);
//procedure TFormCw.EnsureListBoxHeader(const LB: TListBox; const Caption: string);
var
//  LastItem: TListBoxItem;
  Header: TListBoxGroupHeader;
  i: Integer;
begin
  for i := 0 to ListBox.Items.Count - 1 do
    if (ListBox.ListItems[i] is TListBoxGroupHeader) and
      ((ListBox.ListItems[i] as TListBoxGroupHeader).Text = Category) then
      Exit;

  Header := TListBoxGroupHeader.Create(ListBox);
  Header.Text := UpperCase(Category);
  Header.StyledSettings := Header.StyledSettings - [TStyledSetting.Size];
  Header.TextSettings.Font.Size := 10;
  Header.Parent := ListBox;
  //  ── Pas d’entête si le dernier item EXISTANT est déjà le bon header ──
//  {─ 1/ Le dernier élément est-il déjà le bon header ? ─}
//  if LB.Count > 0 then
//  begin
//    LastItem := LB.ItemByIndex(LB.Count - 1);   // ✅
//
//    if  (LastItem is TListBoxGroupHeader)
//    and SameText(LastItem.Text, Caption) then
//      Exit;                                     // rien à faire
//  end;
//
//  {─ 2/ Sinon on ajoute un nouveau header ─}
//  var H := TListBoxGroupHeader.Create(LB);    // Owner = LB
//  H.Text := Caption.ToUpper;
//  H.Selectable := False;
//
//  H.StyledSettings := H.StyledSettings - [TStyledSetting.Size];
//  H.TextSettings.Font.Size := 11;
//
//  LB.AddObject(H);
end;

procedure TFormCw.FillWeaponLists;
var
  W : TWeapon;
  Item : TListBoxItem;
  LastExoCat, LastNamedCat, LastRegCat: string;

  function FamilyAllowed(WF: TWeaponFamily): Boolean;
  var
    F: TWeaponFamily;
  begin
    if Length(FFilterFamilies) = 0 then
      Exit(True);
    for F in FFilterFamilies do
      if F = WF then Exit(True);
    Result := False;
  end;
begin
  Exo_weapons.Clear;
  Named_weapons.Clear;
  Reg_weapons.Clear;

  Exo_weapons.BeginUpdate;
  Named_weapons.BeginUpdate;
  Reg_weapons.BeginUpdate;
  try
    LastExoCat := '';
    LastNamedCat := '';
    LastRegCat := '';
    for W in DataJsonIterator.Weapons.Values do
    begin
      if not FamilyAllowed(W.WeaponType) then
        Continue;

      case W.Rarity of
        wrExotic:
          begin
            if LastExoCat <> WeaponFamilyToString(W.WeaponType) then
            begin
              EnsureListBoxHeader(Exo_weapons, WeaponFamilyToString(W.WeaponType));
              LastExoCat := WeaponFamilyToString(W.WeaponType);
            end;
            Item := TListBoxItem.Create(nil);
            Item.Text := Format('%s (%s)', [W.Name, W.SubCategory]);
            Item.ImageIndex := -1;
            Item.Tag  := W.ID;
            Exo_weapons.AddObject(Item);
          end;
        wrNamed:
          begin
            if LastNamedCat <> WeaponFamilyToString(W.WeaponType) then
            begin
              EnsureListBoxHeader(Named_weapons, WeaponFamilyToString(W.WeaponType));
              LastNamedCat := WeaponFamilyToString(W.WeaponType);
            end;
            Item := TListBoxItem.Create(nil);
            Item.Text := Format('%s (%s)', [W.Name, W.SubCategory]);
            Item.ImageIndex := -1;
            Item.Tag  := W.ID;
            Named_weapons.AddObject(Item);
          end;
        wrHighEnd:
          begin
            if LastRegCat <> WeaponFamilyToString(W.WeaponType) then
            begin
              EnsureListBoxHeader(Reg_weapons, WeaponFamilyToString(W.WeaponType));
              LastRegCat := WeaponFamilyToString(W.WeaponType);
            end;
            Item := TListBoxItem.Create(nil);
            Item.Text := Format('%s (%s)', [W.Name, W.SubCategory]);
            Item.ImageIndex := -1;
            Item.Tag  := W.ID;
            Reg_weapons.AddObject(Item);
          end;
      end;
    end;
  finally
    Reg_weapons.EndUpdate;
    Named_weapons.EndUpdate;
    Exo_weapons.EndUpdate;
  end;
end;

procedure TFormCw.WeaponListChange(Sender: TObject);
var
  ClickedItem: TListBoxItem;
  ParentListBox: TListBox;
  GrandParent: TFmxObject; // To check Parent.Parent
begin
  if Sender is TListBoxItem then
  begin
    ClickedItem := TListBoxItem(Sender);
    // ShowMessage('Sender is TListBoxItem. Text: "' + ClickedItem.Text + '", Tag: ' + IntToStr(ClickedItem.Tag)); // Keep for debugging

    ParentListBox := nil; // Initialize
    if Assigned(ClickedItem.Parent) then
    begin
      GrandParent := ClickedItem.Parent.Parent; // ListBoxItem -> ListBoxContent -> ListBox
      if Assigned(GrandParent) and (GrandParent is TListBox) then
      begin
        ParentListBox := TListBox(GrandParent);
        // Ensure this item is formally selected in its parent ListBox
        if ParentListBox.ItemIndex <> ClickedItem.Index then
        begin
//          ShowMessage('Updating ParentListBox.ItemIndex to ClickedItem.Index: ' + IntToStr(ClickedItem.Index));
          ParentListBox.ItemIndex := ClickedItem.Index; // Set selection by Index
        end;
      end
      // else
      // begin
        // ShowMessage('Grandparent is not a TListBox or is nil. Grandparent Class: ' + IfThen(Assigned(GrandParent), GrandParent.ClassName, 'nil'));
      // end;
    end;
    // else
    // begin
      // ShowMessage('ClickedItem.Parent is nil.');
    // end;

    if ClickedItem.Tag = 0 then // Or some other default/invalid ID
    begin
//      ShowMessage('Warning: ClickedItem.Tag is 0 or an invalid default. Cannot select weapon.');
      Exit;
    end;

    SetSelectedWeaponID(ClickedItem.Tag);
//  end
//  else
//  begin
//    ShowMessage('WeaponListChange Sender is not TListBoxItem. ClassName: ' + Sender.ClassName + '. Cannot process selection.');
  end;
end;

procedure TFormCw.SetFilterFamilies(const AFamilies: TArray<TWeaponFamily>);
begin
  FFilterFamilies := AFamilies;
  FillWeaponLists;           // reconstruit la liste en appliquant le filtre
end;

procedure TFormCw.ComboBox_minorChange(Sender: TObject);
var
  LWeaponStat: TWeaponStat;
  SelectedAttributeName: string;
  LAttributeValue: Double;
  i: Integer;
  SelectedType: string;
begin
  if FSelectedWeapon.ID = 0 then // No weapon selected
  begin
    SkLabel1.Text := '';
    Att_3.Value := 0;
    Exit;
  end;

  // If placeholder "(Select 3rd Attribute)" or "(No Minor Attributes Available)" is selected (index 0)
  if ComboBox_minor.ItemIndex = 0 then
  begin
    FSelectedWeapon.SelectedMinorAttributeType := ''; // Clear the stored selection
    SkLabel1.Text := '';                              // Clear the displayed attribute name
    Att_3.Value := 0;                                 // Reset the value display
  end
  else if ComboBox_minor.ItemIndex > 0 then // A real minor attribute is selected
  begin
    SelectedType := ComboBox_minor.Items[ComboBox_minor.ItemIndex];
    FSelectedWeapon.SelectedMinorAttributeType := SelectedType; // Store it

    LAttributeValue := 0; // Default if not found (should not happen if populated correctly)
    if DataJsonIterator.WeaponStats.TryGetValue(FSelectedWeapon.StatsID, LWeaponStat) then
    begin
      for i := 0 to Length(LWeaponStat.MinorAttributes) - 1 do
      begin
        if LWeaponStat.MinorAttributes[i].&Type = SelectedType then
        begin
          LAttributeValue := LWeaponStat.MinorAttributes[i].Value;
          Break;
        end;
      end;
    end;
    SkLabel1.Text := SelectedType;          // Display type
    Att_3.Value := LAttributeValue;         // Display value
  end
  else // Should not happen if ItemIndex is always >= 0 after population
  begin
     FSelectedWeapon.SelectedMinorAttributeType := '';
     SkLabel1.Text := '';
     Att_3.Value := 0;
  end;

  RecalcDerivedValues; // Always recalculate after changing the 3rd attribute

end;

{ ════════════════════════════════════════════════════════════════════ }
{  2/ Liste des mods possibles pour l’arme                            }
{ ════════════════════════════════════════════════════════════════════ }

procedure TFormCw.UpdateExpertiseLabel;
begin
  SkLabel_ExpT.Text := Format('Expertise: %.0f%%', [SpinBox_Exp.Value]);
end;

procedure TFormCw.FillModsForWeapon(const W: TWeapon);
var
  Slot: TModSlot;
  CB: TComboBox;
  M: TWeaponMod;
  CompatibleModTypesForSlot: TArray<string>;
  Img: TImage;
begin
  for Slot := Low(TModSlot) to High(TModSlot) do
  begin
    case Slot of
      msOptics:      begin CB := Optics_Mods;      Img := Image_optic;      end;
      msMagazine:    begin CB := Magazine_Mods;    Img := Image_mag;        end;
      msUnderbarrel: begin CB := Underbarel_Mods;  Img := Image_underbarrel;end;
      msMuzzle:      begin CB := Muzzle_Mods;      Img := Image_muzzle;     end;
    else
      Continue; // Should not happen
    end;

    CB.Clear;
    CB.Items.Add('(none)');
    CB.ItemIndex := 0;     // Default to (none)
    FModBonusEffects[Slot] := Default(TWeaponModEffect);   // Reset effects for this slot
    FModDrawbackEffects[Slot] := Default(TWeaponModEffect); // Reset effects for this slot
    if Assigned(Img) then Img.Bitmap := nil; // Clear associated image

    if W.Rarity = wrExotic then
    begin
      CB.Clear;
      CompatibleModTypesForSlot := W.CompatibleMods[Slot];
      for M in DataJsonIterator.Mods.Values do
        if (M.Slot = Slot) and IsModTypeCompatible(M.Type_, CompatibleModTypesForSlot) then
          CB.Items.AddObject(M.Name, TObject(M.ID));
      if CB.Items.Count > 0 then
      begin
        CB.ItemIndex := 0;
        CB.Enabled := False;
        CB.TabStop := False;
        // Ici on affiche la description/bonus unique dans le label
        var ModID := Integer(CB.Items.Objects[0]);
        case Slot of
          msOptics:      DisplaySingleModStatsInUI(SkLabel2, ModID);
          msMagazine:    DisplaySingleModStatsInUI(SkLabel3, ModID);
          msUnderbarrel: DisplaySingleModStatsInUI(SkLabel6, ModID);
          msMuzzle:      DisplaySingleModStatsInUI(SkLabel7, ModID);
        end;
      end
      else
      begin
        CB.Items.Add('(N/A)');
        CB.ItemIndex := 0;
        CB.Enabled := False;
        CB.TabStop := False;
        case Slot of
          msOptics:      SkLabel2.Text := '';
          msMagazine:    SkLabel3.Text := '';
          msUnderbarrel: SkLabel6.Text := '';
          msMuzzle:      SkLabel7.Text := '';
        end;
      end;
    end
    else // Non-Exotic (High-End, Named)
    begin
      CompatibleModTypesForSlot := W.CompatibleMods[Slot];

      if Length(CompatibleModTypesForSlot) = 0 then // No mod types defined for this weapon's slot
      begin
        CB.Enabled := False;
        CB.Items[0] := '(N/A)'; // Not Applicable
        if CB.CanFocus then CB.TabStop := False;
      end
      else // Compatible mod types ARE defined for this slot
      begin
        CB.Enabled := True;
        if CB.TabStop = False then CB.TabStop := True;
        // Populate with matching mods from the global list
        for M in DataJsonIterator.Mods.Values do
        begin
          if (M.Slot = Slot) and IsModTypeCompatible(M.Type_, CompatibleModTypesForSlot) then
          begin
            CB.Items.AddObject(M.Name, TObject(M.ID));
          end;
        end;
        // If CB.Items.Count is still 1 (only "(none)"), it means no mods in DataJsonIterator.Mods matched the criteria.
        // This could happen if, for example, weapon_mods.json doesn't have any "Iron Sight" mods,
        // even if the weapon allows "Iron Sight".
        if CB.Items.Count = 1 then // Only "(none)" is present
        begin
          // Optionally, you could disable it or leave it enabled with only "(none)"
          CB.Enabled := False; // Uncomment to disable if no actual mods are found
          CB.Items[0] := '(No Mods Avail.)';
        end;
      end;
    end;
  end;
end;

procedure TFormCw.DisplaySingleModStatsInUI(const TargetLabel: TSkLabel; ModID: Integer);
var
  LMod: TWeaponMod;
  DisplayText: string;
  Line: string;
  HasBonuses: Boolean;
  HasDrawbacks: Boolean;

  /// Local helper to format a single effect line
  function FormatEffectLine(const EffectName: string; Value: Double; IsBonus: Boolean): string;
  var
    Prefix: string;
    Suffix: string;
    FormatString: string;
    FormattedValue: string;
  begin
    Result := ''; // Default to empty string
    if SameValue(Value, 0) then Exit;

    Suffix := '%'; // Default to percentage
    Prefix := '';

    // Determine formatting based on effect name for non-percentage values
    if ( SameText(EffectName, 'Extra Rounds') or
         SameText(EffectName, 'Rate of Fire') // Assuming RoF from mods is absolute
       ) then
    begin
      Suffix := '';
      FormattedValue := Format('%.0f', [Value]); // Format as whole number
    end
    else
    begin
      FormattedValue := Format('%.1f', [Abs(Value)]); // Format percentage value (always positive for display magnitude)
    end;

    // Determine prefix based on bonus/drawback and value sign
    if IsBonus then
    begin
      if Value > 0 then Prefix := '+'
      else Prefix := ''; // Negative bonus is still a reduction, sign is in Value
    end
    else // IsDrawback
    begin
      // Assuming drawback values in LMod.Drawback are positive magnitudes of penalty
      if Value > 0 then Prefix := '-'
      else Prefix := '+'; // A negative value in a drawback field means it's actually a bonus
    end;

    // If value was originally negative (for bonuses) or became positive (for drawbacks that are actually bonuses)
    // the Format('%.1f', [Abs(Value)]) already handled the sign for magnitude.
    // The Prefix now correctly indicates gain or loss.
    if (Value < 0) and IsBonus then Prefix := ''; // Value itself is negative, e.g. Stability: -10%
    if (Value < 0) and not IsBonus then Prefix := '+'; // e.g. Drawback Stability: -10% (means +10% stability)


    Result := Format('%s%s %s%s', [Prefix, FormattedValue, Suffix, EffectName]);
    // Example output: "+10.0% Crit Chance", "-5.0% Stability", "+15 Rate of Fire"
  end;

begin
  if not Assigned(TargetLabel) then Exit;
  TargetLabel.Text := ''; // Clear previous

  if ModID = 0 then // No mod selected or "(none)"
  begin
    // TargetLabel.Text := '(No mod selected)'; // Or leave blank
    Exit;
  end;

  if not DataJsonIterator.Mods.TryGetValue(ModID, LMod) then
  begin
    TargetLabel.Text := '(Mod details not found)';
    Exit;
  end;

  DisplayText := 'Mod: ' + LMod.Name; // Start with the mod's name
  HasBonuses := False;
  HasDrawbacks := False;

  // --- Process Bonus Effects ---
  var TempBonusText := '';
  Line := FormatEffectLine('Accuracy', LMod.Bonus.Accuracy, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Stability', LMod.Bonus.Stability, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Reload Speed', LMod.Bonus.ReloadTime, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Crit Chance', LMod.Bonus.CriticalHitChance, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Crit Damage', LMod.Bonus.CriticalHitDamage, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Headshot Dmg', LMod.Bonus.HeadshotDamage, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Weapon Dmg', LMod.Bonus.WeaponDamage, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Rate of Fire', LMod.Bonus.RateOfFire, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Optimal Range', LMod.Bonus.OptimalRange, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Weapon Handling', LMod.Bonus.WeaponHandling, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Extra Rounds', LMod.Bonus.ExtraRounds, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;
  Line := FormatEffectLine('Melee Damage', LMod.Bonus.MeleeDamage, True); if Line <> '' then begin TempBonusText := TempBonusText + sLineBreak + Line; HasBonuses := True; end;

  if HasBonuses then DisplayText := DisplayText + TempBonusText;

  // --- Process Drawback Effects ---
  // Assuming values in LMod.Drawback are positive numbers representing the penalty magnitude
  var TempDrawbackText := '';
  Line := FormatEffectLine('Accuracy', LMod.Drawback.Accuracy, False); if Line <> '' then begin TempDrawbackText := TempDrawbackText + sLineBreak + Line; HasDrawbacks := True; end;
  Line := FormatEffectLine('Stability', LMod.Drawback.Stability, False); if Line <> '' then begin TempDrawbackText := TempDrawbackText + sLineBreak + Line; HasDrawbacks := True; end;
  Line := FormatEffectLine('Reload Speed', LMod.Drawback.ReloadTime, False); if Line <> '' then begin TempDrawbackText := TempDrawbackText + sLineBreak + Line; HasDrawbacks := True; end;
  Line := FormatEffectLine('Crit Chance', LMod.Drawback.CriticalHitChance, False); if Line <> '' then begin TempDrawbackText := TempDrawbackText + sLineBreak + Line; HasDrawbacks := True; end;
  Line := FormatEffectLine('Crit Damage', LMod.Drawback.CriticalHitDamage, False); if Line <> '' then begin TempDrawbackText := TempDrawbackText + sLineBreak + Line; HasDrawbacks := True; end;
  // ... continue for all relevant fields ...

  if HasDrawbacks then
  begin
    if HasBonuses then DisplayText := DisplayText + sLineBreak; // Add a separator
    // DisplayText := DisplayText + '--Drawbacks--'; // Optional header
    DisplayText := DisplayText + TempDrawbackText;
  end;

  TargetLabel.Text := DisplayText;
end;

{ ════════════════════════════════════════════════════════════════════ }
{  3/ Talents                                                         }
{ ════════════════════════════════════════════════════════════════════ }

procedure TFormCw.FillTalentsForWeapon(const W:TWeapon);
var
  Tid : Integer;
  Tlt : TWeaponTalent;
begin
  TalentsBox.Items.Clear;
  TalentsDesc.Text := '';
  FSelectedWeapon.ChosenTalentID := 0; // Initialize/reset

  if (W.UniqueTalentID<>0) and
     DataJsonIterator.Talents.TryGetValue(W.UniqueTalentID, Tlt) then
  begin
    TalentsBox.Items.AddObject(Tlt.Name, TObject(Tlt.ID));
    TalentsBox.ItemIndex := 0;
    TalentsBox.Enabled   := False;
    TalentsDesc.Text     := Tlt.Description;
    FSelectedWeapon.ChosenTalentID := Tlt.ID; // Store unique talent ID
  end
  else
  begin
    TalentsBox.Enabled := True;
    // Add a "(none)" or "(Select Talent)" option as the first item for non-exotics
    TalentsBox.Items.AddObject('(Select Talent)', TObject(0)); // TagObject 0 for no talent

    for Tid in W.TalentIDs do
    begin
      if DataJsonIterator.Talents.TryGetValue(Tid, Tlt) then
        TalentsBox.Items.AddObject(Tlt.Name, TObject(Tlt.ID));
    end;

    // If there are actual talents (more than just "(Select Talent)"), select "(Select Talent)" by default.
    // Otherwise, if only "(Select Talent)" is there (no actual talents for this HighEnd),
    // ItemIndex can remain 0, and it will effectively be "no talent".
    if TalentsBox.Items.Count > 1 then // More than just the placeholder
      TalentsBox.ItemIndex := 0 // Default to "(Select Talent)"
    else if TalentsBox.Items.Count = 1 then // Only "(Select Talent)"
      TalentsBox.ItemIndex := 0
    else
      TalentsBox.ItemIndex := -1;

    // FSelectedWeapon.ChosenTalentID remains 0 here, will be set by TalentChange if user selects one.
  end;
end;

procedure TFormCw.TalentChange(Sender:TObject);
var
  ID : Integer;
  Tlt: TWeaponTalent;
begin
  FSelectedWeapon.ChosenTalentID := 0; // Default to no talent selected

  if TalentsBox.ItemIndex < 0 then // Should not happen if "(none)" is not an option or is handled
    TalentsDesc.Text := ''
  else if (TalentsBox.Items.Count > 0) and (Assigned(TalentsBox.Selected)) then // An item is selected
  begin
    // Check if the selected item has a valid TagObject (talent ID)
    // This handles cases where the first item might be a placeholder like "(Select Talent)" without a TagObject
    if TalentsBox.Selected.TagObject <> nil then
    begin
      ID := Integer(TalentsBox.Selected.TagObject);
      if ID <> 0 then // Ensure it's a valid talent ID
      begin
        if DataJsonIterator.Talents.TryGetValue(ID, Tlt) then
        begin
          TalentsDesc.Text := Tlt.Description;
          FSelectedWeapon.ChosenTalentID := ID; // Store the chosen talent ID
        end
        else // Talent ID not found in data (should ideally not happen if list is populated correctly)
        begin
          TalentsDesc.Text := '(Talent details not found)';
        end;
      end
      else // TagObject was 0 or nil, implying a placeholder or "(none)"
      begin
         TalentsDesc.Text := '';
      end;
    end
    else // No TagObject, likely a placeholder without an ID
    begin
        TalentsDesc.Text := '';
    end;
  end
  else // No item selected or empty list
  begin
    TalentsDesc.Text := '';
  end;
  RecalcDerivedValues;
end;

{ ════════════════════════════════════════════════════════════════════ }
{  4/ Sélection d’un mod                                              }
{ ════════════════════════════════════════════════════════════════════ }

procedure TFormCw.ModComboChange(Sender:TObject);
var
  CB  : TComboBox;
  Slot: TModSlot;
  ModID: Integer; // Renamed from ID for clarity
  TargetLabel: TSkLabel;
  // TargetImage: TImage; // Removed for now as mod images are not used
begin
  CB := Sender as TComboBox;

  // Determine slot and target UI elements
  if      CB = Optics_Mods      then begin Slot := msOptics;      TargetLabel := SkLabel2; end
  else if CB = Magazine_Mods    then begin Slot := msMagazine;    TargetLabel := SkLabel3; end
  else if CB = Underbarel_Mods then begin Slot := msUnderbarrel; TargetLabel := SkLabel6; end // Corrected name from Underbarel_Mods
  else if CB = Muzzle_Mods      then begin Slot := msMuzzle;      TargetLabel := SkLabel7; end
  else
  begin
    // Should not happen if event is only assigned to the four mod combo boxes
    // ShowMessage('ModComboChange called by unknown sender: ' + Sender.ClassName);
    Exit;
  end;

  if CB.ItemIndex < 0 then // No item selected (should ideally not happen with a (none) default)
  begin
    ModID := 0; // Treat as no mod
    FModBonusEffects[Slot] := Default(TWeaponModEffect);
    FModDrawbackEffects[Slot] := Default(TWeaponModEffect);
  end
  else if CB.ItemIndex = 0 then // "(none)" is selected
  begin
    ModID := 0;
    FModBonusEffects[Slot] := Default(TWeaponModEffect);
    FModDrawbackEffects[Slot] := Default(TWeaponModEffect);
  end
  else // A specific mod is selected
  begin
    ModID := Integer(CB.Items.Objects[CB.ItemIndex]);
    var LMod := FindModByID(ModID); // FindModByID should raise an exception if not found
    FModBonusEffects[Slot] := LMod.Bonus;
    FModDrawbackEffects[Slot] := LMod.Drawback;
  end;

  DisplaySingleModStatsInUI(TargetLabel, ModID); // Display details of selected mod (or clear if none)
  RecalcDerivedValues; // Recalculate overall weapon stats
end;

function TFormCw.FindModByID(ID:Integer):TWeaponMod;
begin
  if not DataJsonIterator.Mods.TryGetValue(ID,Result) then
    raise EArgumentException.CreateFmt('Unknown mod id %d',[ID]);
end;

procedure TFormCw.ShowAttribute(const Lbl:TSkLabel; const AName:string;
                                const AValue:Double);
begin
  if SameValue(AValue,0) then
    Lbl.Text := ''
  else if AValue>0 then
    Lbl.Text := Format('+%.1f %% %s', [AValue, AName])
  else
    Lbl.Text := Format('%.1f %% %s',  [AValue, AName]); // valeur négative
end;

{$ENDREGION}

procedure TFormCw.SetSelectedWeaponID(ID: Integer);
var
  LWeaponStat: TWeaponStat;
  LAttribute: TAttribute;  // for minor
  idx: Integer;
begin
//  ShowMessage('SetSelectedWeaponID called with ID: ' + IntToStr(ID)); // DEBUG 1

  // 1. Fetch the basic TWeapon record
  if not DataJsonIterator.Weapons.TryGetValue(ID, FSelectedWeapon) then
  begin
    // Clear UI fields when weapon not found
    SkLabel_TDmgValue.Text := 'N/A';
    SkLabel_RPMValue.Text := 'N/A';
    SkLabel_MagValue.Text := 'N/A';
    Wp_Acc.Text := '0'; ProgressBar_Acc.Value := 0;
    Wp_Stab.Text := '0'; ProgressBar_Stab.Value := 0;
    Wp_reload.Text := '0.0';
    if Assigned(SkLabel_OptimalRange) then SkLabel_OptimalRange.Text := 'Optimal Range: N/A';
    SkLabel_core1.Text := 'Core Stats N/A';
    CoreAtt1.Value := 0; // Reset SpinBox
    SkLabel_core2.Text := '';
    CoreAtt2.Value := 0; // Reset SpinBox
    ComboBox_minor.Clear;
    Att_3.Value := 0;    // Reset SpinBox
    SkLabel1.Text := 'Minor Stats N/A';
    TalentsBox.Clear; TalentsDesc.Text := '';
    Optics_Mods.Clear; Magazine_Mods.Clear; Underbarel_Mods.Clear; Muzzle_Mods.Clear;
    Optics_Mods.Items.Add('(none)'); Optics_Mods.ItemIndex := 0;
    Magazine_Mods.Items.Add('(none)'); Magazine_Mods.ItemIndex := 0;
    Underbarel_Mods.Items.Add('(none)'); Underbarel_Mods.ItemIndex := 0;
    Muzzle_Mods.Items.Add('(none)'); Muzzle_Mods.ItemIndex := 0;
    SkLabel_BurstDPS.Text   := '0';
    SkLabel_SustainDPS.Text := '0';
    Weapon_CHC.Text := 'CHC 0.0%';
    Weapon_CHD.Text := 'CHD 0.0%';
    Exit;
  end;

  // 2. Populate UI with FSelectedWeapon's direct data
  // Your existing code for SkLabel_TDmgValue, RPM, MagValue, Handling, etc.
  // SkLabel_TDmgValue.Text := Format('%s (%s)', [{TUtils.FormatDamageValue(FSelectedWeapon.TotalWeaponDamage)} '-', TUtils.FormatDamageValue(FSelectedWeapon.Core.BaseDamage)]);
  // The above line for TDmgValue refers to FSelectedWeapon.TotalWeaponDamage which might be from an older design.
  // Let's ensure it uses the direct base damage for now, consistent with my previous suggestions:
  SkLabel_TDmgValue.Text := FloatToStr(FSelectedWeapon.Core.BaseDamage);
  SkLabel_RPMValue.Text := FSelectedWeapon.Core.RPM.ToString;
  SkLabel_MagValue.Text := FSelectedWeapon.Core.MagazineSize.ToString;

  Wp_Acc.Text := Format('%.0f', [FSelectedWeapon.Handling.Accuracy]);
  ProgressBar_Acc.Value := FSelectedWeapon.Handling.Accuracy;
  Wp_Stab.Text := Format('%.0f', [FSelectedWeapon.Handling.Stability]);
  ProgressBar_Stab.Value := FSelectedWeapon.Handling.Stability;
  Wp_reload_sec.Text := Format('%0.1f sec', [FSelectedWeapon.Handling.ReloadTime]);
  // Optimal Range display (assuming SkLabel_OptimalRange or dynamic addition)
  if Assigned(SkLabel_OptimalRange) then
    SkLabel_OptimalRange.Text := Format('Optimal Range: %.0f m', [FSelectedWeapon.Handling.OptimalRange]);

  // 3. Fetch and Display Core & Minor Attributes
  if DataJsonIterator.WeaponStats.TryGetValue(FSelectedWeapon.StatsID, LWeaponStat) then
  begin
    // Core Attributes display
    if Length(LWeaponStat.CoreAttributes) > 0 then
    begin
      SkLabel_core1.Text := LWeaponStat.CoreAttributes[0].&Type; // Display type in label
      CoreAtt1.Value := LWeaponStat.CoreAttributes[0].Value;     // Display value in SpinBox
    end
    else
    begin
      SkLabel_core1.Text := '';
      CoreAtt1.Value := 0;
    end;

    if Length(LWeaponStat.CoreAttributes) > 1 then
    begin
      SkLabel_core2.Text := LWeaponStat.CoreAttributes[1].&Type; // Display type in label
      CoreAtt2.Value := LWeaponStat.CoreAttributes[1].Value;     // Display value in SpinBox
    end
    else
    begin
      SkLabel_core2.Text := '';
      CoreAtt2.Value := 0;
    end;

    // Minor Attributes - Setup ComboBox_minor
    ComboBox_minor.Clear;
    ComboBox_minor.Items.Add('(Select 3rd Attribute)'); // Placeholder item at index 0
//    ComboBox_minor.Enabled := True; // Enable by default

    if Length(LWeaponStat.MinorAttributes) > 0 then
    begin
      for LAttribute in LWeaponStat.MinorAttributes do
        ComboBox_minor.Items.Add(LAttribute.&Type); // Populate with available minor attribute types
//        Att_3.Value := LAttribute.Value;
      // If FSelectedWeapon.SelectedMinorAttributeType is not empty and exists in the list, select it.
      // Otherwise, default to the placeholder.
      idx := -1; // Initialize idx
      if FSelectedWeapon.SelectedMinorAttributeType <> '' then
        idx := ComboBox_minor.Items.IndexOf(FSelectedWeapon.SelectedMinorAttributeType);

      if idx > 0 then // Found the stored type, and it's not the placeholder
        ComboBox_minor.ItemIndex := idx
      else
        ComboBox_minor.ItemIndex := 0; // Default to "(Select 3rd Attribute)"
    end
    else // No minor attributes defined for this weapon type
    begin
        ComboBox_minor.Items[0] := '(Not Available)'; // Change placeholder
        ComboBox_minor.ItemIndex := 0;
        ComboBox_minor.Enabled := False;
    end;

    ComboBox_minorChange(ComboBox_minor); // Update SkLabel1 and Att_3 based on current selection

  end
  else // WeaponStat not found
  begin
    SkLabel_core1.Text := '1Core Stat N/A';
    CoreAtt1.Value := 0;
    SkLabel_core2.Text := '2Core Stat N/A';
    CoreAtt2.Value := 0;
    ComboBox_minor.Clear;
    ComboBox_minor.Items.Add('(Attribute N/A)');
    ComboBox_minor.ItemIndex := 0;
    ComboBox_minor.Enabled := False;
    Att_3.Value := 0;
    SkLabel1.Text := '';
  end;

  // 4. Populate Mod Slots and Talents
  FillModsForWeapon(FSelectedWeapon);
  FillTalentsForWeapon(FSelectedWeapon);

  // 5. Perform Initial Calculation
  RecalcDerivedValues;

  // 6. Notify
  if Assigned(FOnWeaponChanged) then
    FOnWeaponChanged(Self, FSelectedWeapon);
end;

procedure TFormCw.SpinBoxExpChange(Sender:TObject);
begin
  UpdateExpertiseLabel;
  RecalcDerivedValues;
end;

procedure TFormCw.RecalcDerivedValues;
var
  LWeaponStat: TWeaponStat;
  LTalent: TWeaponTalent;
  LTalentID: Integer;
  CalcResult: TFullDamageCalcResult; // From CalcEngine
begin
  if FSelectedWeapon.ID = 0 then
  begin
    SkLabel_BurstDPS.Text := '0';
    SkLabel_SustainDPS.Text := '0';
    Weapon_CHC.Text := 'Weapon CHC: 0.0%';
    Weapon_CHD.Text := 'Weapon CHD Bonus: 0.0%';
    Wp_Acc.Text := '0'; ProgressBar_Acc.Value := 0;
    Wp_Stab.Text := '0'; ProgressBar_Stab.Value := 0;
    if Assigned(SkLabel_OptimalRange) then SkLabel_OptimalRange.Text := 'Optimal Range: 0 m';
    Wp_reload.Text := '0.0 sec';
    SkLabel_RPMValue.Text := '0'; // Display base or calculated RPM
    SkLabel_MagValue.Text := '0'; // Display base or calculated MagSize
    Exit;
  end;

  // Fetch LWeaponStat
  if not DataJsonIterator.WeaponStats.TryGetValue(FSelectedWeapon.StatsID, LWeaponStat) then
  begin
    // Handle error: Weapon archetype stats not found, clear display or show error
    SkLabel_BurstDPS.Text := 'Burst N/A';
    SkLabel_SustainDPS.Text := 'Sustain N/A';
    Weapon_CHC.Text := 'Weapon CHC: N/A';
    Weapon_CHD.Text := 'Weapon CHD: N/A';
    Exit;
  end;

  // Fetch Selected Talent
  LTalentID := 0;
//  if FSelectedWeapon.UniqueTalentID <> 0 then
//    LTalentID := FSelectedWeapon.UniqueTalentID
//  else if (TalentsBox.Items.Count > 0) and (TalentsBox.ItemIndex >= 0) and (TalentsBox.Selected <> nil) then
//    LTalentID := Integer(TalentsBox.Selected.TagObject);

  if FSelectedWeapon.UniqueTalentID <> 0 then
    LTalentID := FSelectedWeapon.UniqueTalentID
  else if (TalentsBox.Items.Count > 0) and (TalentsBox.ItemIndex >= 0) then
  begin
    if Assigned(TalentsBox.Selected) and (TalentsBox.Selected.TagObject <> nil) then
        LTalentID := Integer(TalentsBox.Selected.TagObject)
    else if (TalentsBox.ItemIndex > 0) and (TalentsBox.Items.Objects[TalentsBox.ItemIndex] <> nil) then
        LTalentID := Integer(TalentsBox.Items.Objects[TalentsBox.ItemIndex]);
  end;

  if (LTalentID = 0) or (not DataJsonIterator.Talents.TryGetValue(LTalentID, LTalent)) then
  begin
    LTalent := Default(TWeaponTalent); // No talent or talent not found, use default empty talent
    LTalent.Effect := Default(TWeaponModEffect);
    LTalent.Drawback := Default(TWeaponModEffect);
  end;

  // Call the calculation engine
  CalcResult := CalcEngine.CalculateWeaponPerformance(
    FSelectedWeapon,
    LWeaponStat,
    FSelectedWeapon.SelectedMinorAttributeType, // This is now set by ComboBox_minorChange
    FModBonusEffects,
    FModDrawbackEffects,
    LTalent,
    SpinBox_Exp.Value
  );

  // Update UI from CalcResult
  SkLabel_BurstDPS.Text   := TUtils.FormatDamageValue(CalcResult.BurstDPS);
  SkLabel_SustainDPS.Text := TUtils.FormatDamageValue(CalcResult.SustainDPS);
  Weapon_CHC.Text := Format('CHC %.1f%%', [CalcResult.FinalCHC * 100.0]);
  Weapon_CHD.Text := Format('CHD %.1f%%', [CalcResult.FinalCHD * 100.0]);

  // Update Handling stats display with final calculated values
  Wp_Acc.Text := Format('Acc %.0f', [CalcResult.FinalAccuracy]);
  ProgressBar_Acc.Value := CalcResult.FinalAccuracy; // Ensure ProgressBar max value is appropriate
  Wp_Stab.Text := Format('Stab %.0f', [CalcResult.FinalStability]);
  ProgressBar_Stab.Value := CalcResult.FinalStability; // Ensure ProgressBar max value is appropriate
  if Assigned(SkLabel_OptimalRange) then
    SkLabel_OptimalRange.Text := Format('Optimal Range: %.0f m', [CalcResult.FinalOptimalRange]);

  // Update RPM, Magazine, Reload Time with final calculated values
  SkLabel_RPMValue.Text := Round(CalcResult.FinalRPM).ToString;
  SkLabel_MagValue.Text := Round(CalcResult.FinalMagazine).ToString;
  Wp_reload_sec.Text := Format('%.1f sec', [CalcResult.FinalReloadSec]);
end;

procedure TFormCw.LoadExistingWeaponState(const AWeapon: TWeapon; AExpertiseLevel: Integer);
var
  SavedMods: array[TModSlot] of Integer;
  SavedMinorType: string;
  SavedTalentID: Integer;
  MinorIndex: Integer;
  Slot: TModSlot;
  TargetIndex: Integer;
  CB: TComboBox;
  LOnChange: TNotifyEvent;
  I: Integer;
  LTalent: TWeaponTalent;
begin
  if AWeapon.ID = 0 then
    Exit;

  for Slot := Low(TModSlot) to High(TModSlot) do
    SavedMods[Slot] := AWeapon.EquippedMods[Slot];
  SavedMinorType := AWeapon.SelectedMinorAttributeType;
  SavedTalentID := AWeapon.ChosenTalentID;

  SetSelectedWeaponID(AWeapon.ID);

  SpinBox_Exp.Value := AExpertiseLevel;

  FSelectedWeapon.SelectedMinorAttributeType := SavedMinorType;
  FSelectedWeapon.ChosenTalentID := SavedTalentID;

  for Slot := Low(TModSlot) to High(TModSlot) do
    FSelectedWeapon.EquippedMods[Slot] := SavedMods[Slot];

  FillModsForWeapon(FSelectedWeapon);

  for Slot := Low(TModSlot) to High(TModSlot) do
  begin
    case Slot of
      msOptics: CB := Optics_Mods;
      msMagazine: CB := Magazine_Mods;
      msUnderBarrel: CB := Underbarel_Mods;
      msMuzzle: CB := Muzzle_Mods;
    else
      CB := nil;
    end;
    if not Assigned(CB) then
      Continue;

    TargetIndex := 0;
    if SavedMods[Slot] <> 0 then
      for I := 0 to CB.Items.Count - 1 do
        if Assigned(CB.Items.Objects[I]) and
          (NativeInt(CB.Items.Objects[I]) = SavedMods[Slot]) then
        begin
          TargetIndex := I;
          Break;
        end;

    LOnChange := CB.OnChange;
    CB.OnChange := nil;
    try
      CB.ItemIndex := TargetIndex;
    finally
      CB.OnChange := LOnChange;
    end;

    ModComboChange(CB);
  end;

  FillTalentsForWeapon(FSelectedWeapon);

  if TalentsBox.Items.Count > 0 then
  begin
    TargetIndex := TalentsBox.ItemIndex;
    if SavedTalentID <> 0 then
    begin
      for I := 0 to TalentsBox.Items.Count - 1 do
        if NativeInt(TalentsBox.Items.Objects[I]) = SavedTalentID then
        begin
          TargetIndex := I;
          Break;
        end;

      if (SavedTalentID <> 0) and
         ((TargetIndex < 0) or (NativeInt(TalentsBox.Items.Objects[TargetIndex]) <> SavedTalentID)) and
         DataJsonIterator.Talents.TryGetValue(SavedTalentID, LTalent) then
      begin
        TalentsBox.Items.AddObject(LTalent.Name, TObject(SavedTalentID));
        TargetIndex := TalentsBox.Items.Count - 1;
      end;
    end;

    LOnChange := TalentsBox.OnChange;
    TalentsBox.OnChange := nil;
    try
      TalentsBox.ItemIndex := TargetIndex;
    finally
      TalentsBox.OnChange := LOnChange;
    end;

    if (SavedTalentID <> 0) and (TargetIndex >= 0) then
    begin
      FSelectedWeapon.ChosenTalentID := SavedTalentID;
      TalentChange(TalentsBox);
    end
    else
    begin
      FSelectedWeapon.ChosenTalentID := 0;
      TalentsDesc.Text := '';
    end;
  end;

  if SavedMinorType <> '' then
  begin
    MinorIndex := ComboBox_minor.Items.IndexOf(SavedMinorType);
    if MinorIndex > 0 then
    begin
      ComboBox_minor.ItemIndex := MinorIndex;
      ComboBox_minorChange(ComboBox_minor);
    end;
  end
  else
    ComboBox_minor.ItemIndex := 0;

  RecalcDerivedValues;
end;

{ TFormCw }

procedure TFormCw.CancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFormCw.OKClick(Sender: TObject);
begin
//  if FSelectedWeapon.ID=0 then
//  begin
//    TDialogService.MessageDialog('Pick a weapon first.', TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
//    ModalResult := mrNone;
//  end
//  else
    ModalResult := mrOk;
end;

procedure TFormCw.FormCreate(Sender: TObject);
begin
//  if not Assigned(DataJsonIterator) then
//  begin
//    DataJsonIterator := TDataJSONIterator.Create(nil);
//    DataJsonIterator.Init(TUtils.AssetsPath);
//  end;

  // 1) Peupler les trois ListBox
  FillWeaponLists;
  UpdateExpertiseLabel;
end;

end.
