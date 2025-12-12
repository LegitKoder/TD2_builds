unit Utils;

interface

uses
  System.SysUtils, System.IOUtils, FMX.Graphics, Game.Types, System.TypInfo,
  System.Generics.Collections;

type
  TUtils = class
  protected
    class function GetAssetsPath: string; static;
    class function GetOutputPath: string; static;
    class var FBitmapCache: TObjectDictionary<string, TBitmap>;
  public
    class property AssetsPath: string read GetAssetsPath;
    class property OutputPath: string read GetOutputPath;
    class function FormatDamageValue(Value: Double): string; static;
    class function BitmapFromPath(const APath: string): TBitmap; static;
  end;

function RemoveAttributeSuffix(const ID: string): string;
function GetMaxGearModValue(AEffectType: TGearModEffectType): Double;
function GetCompatibleModEffects(ASlotType: TGearModType)
  : TArray<TGearModEffectType>;
function GetGearItemDefaultModSlotType(AItemType: TItemType;
  const ASetName: string = ''): TGearModType;
function GearModEffectTypeToString(AEffectType: TGearModEffectType): string;
function StrToGearModEffectType(const AEffectStr: string): TGearModEffectType;
function GearSlotModTypeToString(ASlotType: TGearModType): string;

function MinorAttributeTypeForDetails(Details: TMinorAttributeType)
  : TMinorAttributeCat;
function ItemTypeToStr(ItemType: TItemType): string;
function MinorAttributeDetailsToString(Details: TMinorAttributeType): string;
function GearModAttributeTypeToGearModType(Details: TGearModEffectType)
  : TGearModType;

function StrToMinorAttributeCat(const AttrTypeStr: string): TMinorAttributeCat;
function StrToMinorAttributeType(const MinorAttrStr: string)
  : TMinorAttributeType;
function StrToItemType(const ItemTypeStr: string): TItemType;
function CoreAttrIDToEnum(const ID: string): TCoreAttributeType;

implementation

class function TUtils.GetAssetsPath: string;
begin
{$IFDEF MSWINDOWS}
{$IFDEF DEBUG}
  Result := TPath.GetFullPath('..\..\Assets\');
{$ELSE}
  // Get the directory where the EXE is running, then combine with "Assets"
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Assets\');
{$ENDIF}
{$ELSEIF DEFINED(IOS) or DEFINED(ANDROID)}
  Result := TPath.GetDocumentsPath;
{$ELSEIF defined(MACOS)}
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), '..', 'Resources',
    'Assets');
{$ELSE}
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Assets');
{$ENDIF}
  // if (Result <> '') and not Result.EndsWith(PathDelim) then
  // Result := Result + PathDelim;
end;

class function TUtils.GetOutputPath: string;
begin
{$IFDEF MSWINDOWS}
  Result := ExtractFilePath(ParamStr(0));
  if (Result <> '') and not Result.EndsWith(PathDelim) then
    Result := Result + PathDelim;
{$ELSEIF DEFINED(MACOS) and NOT DEFINED(IOS)}
  Result := TPath.GetTempPath;
  if (Result <> '') and not Result.EndsWith(PathDelim) then
    Result := Result + PathDelim;
{$ELSE}
  Result := GetAssetsPath;
{$ENDIF}
end;

class function TUtils.FormatDamageValue(Value: Double): string;
begin
  if Value >= 1E6 then
    Result := FormatFloat('0.0M', Value / 1E6)
  else if Value >= 1E3 then
    Result := FormatFloat('0.0K', Value / 1E3)
  else
    Result := FormatFloat('0', Value);
end;

class function TUtils.BitmapFromPath(const APath: string): TBitmap;
var
  Bmp: TBitmap;
  FullPath: string;
begin
  if TPath.IsRelativePath(APath) then
    FullPath := TPath.Combine(AssetsPath, APath)
  else
    FullPath := APath;

  if not FBitmapCache.TryGetValue(APath, Result) then
  begin
    Bmp := nil;
    if (FullPath <> '') and FileExists(FullPath) then
    begin
      Bmp := TBitmap.Create;
      try
        Bmp.LoadFromFile(FullPath);
      except
        Bmp.Free;
        Bmp := nil;
      end;
    end;
    FBitmapCache.Add(APath, Bmp); // nil is OK, avoids re-load
    Result := Bmp;
  end;
end;

function RemoveAttributeSuffix(const ID: string): string;
var
  UnderscorePos: Integer;
  Suffix: string;
  IsNumeric: Boolean;
  C: Char;
begin
  Result := ID;
  UnderscorePos := Result.LastIndexOf('_');
  if UnderscorePos > 0 then
  begin
    Suffix := Result.Substring(UnderscorePos + 1);
    IsNumeric := True;
    if Suffix.IsEmpty then
      IsNumeric := False
    else
      for C in Suffix do
        if not CharInSet(C, ['0'..'9']) then
        begin
          IsNumeric := False;
          Break;
        end;

    if IsNumeric then
      Result := Result.Substring(0, UnderscorePos);
  end;
end;

// --- Implementation of Gear Mod Utility Functions ---

function GetMaxGearModValue(AEffectType: TGearModEffectType): Double;
begin
  // These are the maximum values for gear mods in The Division 2
  case AEffectType of
    gmetCriticalHitChance:
      Result := 6.0;
    gmetCriticalHitDamage:
      Result := 12.0;
    gmetHeadshotDamage:
      Result := 10.0;
    gmetProtectionFromElites:
      Result := 13.0; // Percentage
    gmetArmorOnKillFlat:
      Result := 18935; // Flat value
    gmetStatusEffectResistance:
      Result := 10.0;
    gmetPulseResistance:
      Result := 10.0;
    gmetIncomingRepairs:
      Result := 20.0; // Corrected from gmatIncomingRepairs to use the value
    gmetSkillHaste:
      Result := 12.0;
    gmetSkillDuration:
      Result := 10.0;
    gmetRepairSkills:
      Result := 20.0;
    gmetSkillDamage:
      Result := 10.0; // Example, confirm actual max
    gmetSkillHealth:
      Result := 20.0; // Example, confirm actual max
  else
    Result := 0.0; // Default for unknown or unlisted types
  end;
end;

function GetCompatibleModEffects(ASlotType: TGearModType)
  : TArray<TGearModEffectType>;
begin
  // Define which mod effects can go into which slot type
  case ASlotType of
    gsmtOffensive:
      Result := [gmetCriticalHitChance, gmetCriticalHitDamage,
        gmetHeadshotDamage];
    gsmtDefensive:
      Result := [gmetProtectionFromElites, gmetArmorOnKillFlat,
        gmetStatusEffectResistance, gmetPulseResistance, gmetIncomingRepairs];
      // Corrected reference
    gsmtUtility:
      Result := [gmetSkillHaste, gmetSkillDuration, gmetRepairSkills,
        gmetSkillDamage, gmetSkillHealth];
    gsmtGeneric:
      Result := []; // Or all, depending on design for generic slots
  else
    Result := [];
  end;
end;

function GetGearItemDefaultModSlotType(AItemType: TItemType;
  const ASetName: string = ''): TGearModType;
begin
  // Simplified: Most gear has a predominant mod slot type.
  // This can be expanded for specific named items or brands that differ.
  // Masks: Usually Defensive (Blue) or Utility (Yellow)
  // Backpacks: Usually Utility (Yellow) or Offensive (Red)
  // Chests: Usually Offensive (Red) or Defensive (Blue)
  // Gloves, Holsters, Kneepads: Do not have mod slots in the base game, but if your tool allows, define a default.
  // For now, assuming only Mask, Backpack, Chest have slots by default.
  case AItemType of
    itMask:
      Result := gsmtDefensive; // Example default
    itBackpack:
      Result := gsmtUtility; // Example default
    itChest:
      Result := gsmtOffensive; // Example default
    itGloves, itHolster, itKneepads:
      Result := gsmtGeneric; // Or a specific "no slot" type if defined
  else
    Result := gsmtGeneric; // Default for unknown item types
  end;
  // Add logic for ASetName if specific items override default slot types.
end;

function GearModEffectTypeToString(AEffectType: TGearModEffectType): string;
begin
  // Provides user-friendly names for the mod effects
  case AEffectType of
    gmetCriticalHitChance:
      Result := 'Critical Hit Chance';
    gmetCriticalHitDamage:
      Result := 'Critical Hit Damage';
    gmetHeadshotDamage:
      Result := 'Headshot Damage';
    gmetProtectionFromElites:
      Result := 'Protection From Elites';
    gmetArmorOnKillFlat:
      Result := 'Armor On Kill';
    gmetStatusEffectResistance:
      Result := 'Status Effect Resistance';
    gmetPulseResistance:
      Result := 'Pulse Resistance';
    gmetIncomingRepairs:
      Result := 'Incoming Repairs'; // Corrected reference
    gmetSkillHaste:
      Result := 'Skill Haste';
    gmetSkillDuration:
      Result := 'Skill Duration';
    gmetRepairSkills:
      Result := 'Repair Skills';
    gmetSkillDamage:
      Result := 'Skill Damage';
    gmetSkillHealth:
      Result := 'Skill Health';
    gmetUnknown:
      Result := '(No Mod Effect)';
  else
    Result := System.TypInfo.GetEnumName(TypeInfo(TGearModEffectType),
      Ord(AEffectType)); // Fallback
  end;
end;

function StrToGearModEffectType(const AEffectStr: string): TGearModEffectType;
var
  LType: TGearModEffectType;
begin
  for LType := Low(TGearModEffectType) to High(TGearModEffectType) do
  begin
    if SameText(AEffectStr, GearModEffectTypeToString(LType)) or
      SameText(AEffectStr, System.TypInfo.GetEnumName
      (TypeInfo(TGearModEffectType), Ord(LType))) then
    begin
      Result := LType;
      Exit;
    end;
  end;
  Result := gmetUnknown; // Default if no match
  // Consider raising an exception for truly unknown strings if strict parsing is required.
  // raise Exception.CreateFmt('Unknown Gear Mod Effect string: %s', [AEffectStr]);
end;

function GearSlotModTypeToString(ASlotType: TGearModType): string;
begin
  case ASlotType of
    gsmtOffensive:
      Result := 'Offensive Mod Slot';
    gsmtDefensive:
      Result := 'Defensive Mod Slot';
    gsmtUtility:
      Result := 'Utility Mod Slot';
    gsmtGeneric:
      Result := 'Generic Mod Slot';
  else
    Result := 'Unknown Slot Type';
  end;
end;

// --- Implementation of Gear Minor Attribute Utility Functions ---

function StrToMinorAttributeCat(const AttrTypeStr: string): TMinorAttributeCat;
begin
  if SameText(AttrTypeStr, 'Offensive') then
    Result := matOffensive
  else if SameText(AttrTypeStr, 'Defensive') then
    Result := matDefensive
  else if SameText(AttrTypeStr, 'Utility') then
    Result := matUtility
  else
    raise Exception.Create('Invalid Minor Attribute Category string: ' +
      AttrTypeStr);
end;

function StrToMinorAttributeType(const MinorAttrStr: string)
  : TMinorAttributeType;
var
  LType: TMinorAttributeType;
begin
  // Attempt direct enum name match first (case-insensitive)
  for LType := Low(TMinorAttributeType) to High(TMinorAttributeType) do
  begin
    if SameText(MinorAttrStr,
      System.TypInfo.GetEnumName(TypeInfo(TMinorAttributeType), Ord(LType)))
    then
    begin
      Result := LType;
      Exit;
    end;
  end;
  // Fallback to matching user-friendly strings
  // This relies on MinorAttributeDetailsToString being available or replicated here
  // For simplicity, direct string comparisons from original TFormSlots method:
  if SameText(MinorAttrStr, 'Weapon Handling') then
    Result := madWeaponHandling
  else if SameText(MinorAttrStr, 'Critical Hit Chance') then
    Result := madCriticalHitChance
  else if SameText(MinorAttrStr, 'Critical Hit Damage') then
    Result := madCriticalHitDamage
  else if SameText(MinorAttrStr, 'Headshot Damage') then
    Result := madHeadshotDamage
  else if SameText(MinorAttrStr, 'Armor Regeneration') then
    Result := madArmorRegen
  else if SameText(MinorAttrStr, 'Hazard Protection') then
    Result := madHazardProtection
  else if SameText(MinorAttrStr, 'Health') then
    Result := madHealth
  else if SameText(MinorAttrStr, 'Explosive Resistance') then
    Result := madExplosiveResistance
  else if SameText(MinorAttrStr, 'Incoming Repairs') then
    Result := madIncomingRepairs
  else if SameText(MinorAttrStr, 'Skill Haste') then
    Result := madSkillHaste
  else if SameText(MinorAttrStr, 'Skill Damage') then
    Result := madSkillDamage
  else if SameText(MinorAttrStr, 'Repair Skills') then
    Result := madRepairSkills
  else if SameText(MinorAttrStr, 'Status Effects') then
    Result := madStatusEffects
  else
    raise Exception.Create('Invalid Minor Attribute Detail string: ' +
      MinorAttrStr);
end;

function StrToItemType(const ItemTypeStr: string): TItemType;
begin
  if SameText(ItemTypeStr, 'Mask') then
    Result := itMask
  else if SameText(ItemTypeStr, 'Backpack') then
    Result := itBackpack
  else if SameText(ItemTypeStr, 'Vest') then
    Result := itChest // Assuming 'Vest' maps to itChest
  else if SameText(ItemTypeStr, 'Glove') then
    Result := itGloves // Assuming 'Glove' maps to itGloves
  else if SameText(ItemTypeStr, 'Holster') then
    Result := itHolster
  else if SameText(ItemTypeStr, 'Kneepad') then
    Result := itKneepads // Assuming 'Kneepad' maps to itKneepads
  else
    raise Exception.Create('Invalid Item Type string: ' + ItemTypeStr);
end;

function MinorAttributeTypeForDetails(Details: TMinorAttributeType)
  : TMinorAttributeCat;
begin
  Result := matOffensive; // Default, though should always hit a case
  case Details of
    madWeaponHandling, madCriticalHitChance, madCriticalHitDamage,
      madHeadshotDamage:
      Result := matOffensive;
    madArmorRegen, madHazardProtection, madHealth, madExplosiveResistance,
      madIncomingRepairs:
      Result := matDefensive;
    madSkillHaste, madSkillDamage, madRepairSkills, madStatusEffects:
      Result := matUtility;
  end;
end;


function CoreAttrIDToEnum(const ID: string): TCoreAttributeType;
begin
  if SameText(ID, 'weaponDamage') then
    Exit(catWeaponDamage)
  else if SameText(ID, 'armor') then
    Exit(catArmor)
  else if SameText(ID, 'skillTier') then
    Exit(catSkillTier)
  else
    Exit(catWeaponDamage); // default/fallback
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
    Result := 'Unknown Item Type'; // Fallback for safety
  end;
end;

function MinorAttributeDetailsToString(Details: TMinorAttributeType): string;
begin
  case Details of
    madWeaponHandling:
      Result := 'Weapon Handling';
    madCriticalHitChance:
      Result := 'Critical Hit Chance';
    madCriticalHitDamage:
      Result := 'Critical Hit Damage';
    madHeadshotDamage:
      Result := 'Headshot Damage';
    madArmorRegen:
      Result := 'Armor Regeneration';
    madHazardProtection:
      Result := 'Hazard Protection';
    madHealth:
      Result := 'Health';
    madExplosiveResistance:
      Result := 'Explosive Resistance';
    madIncomingRepairs:
      Result := 'Incoming Repairs';
    madSkillHaste:
      Result := 'Skill Haste';
    madSkillDamage:
      Result := 'Skill Damage';
    madRepairSkills:
      Result := 'Repair Skills';
    madStatusEffects:
      Result := 'Status Effects';
  else
    Result := System.TypInfo.GetEnumName(TypeInfo(TMinorAttributeType),
      Ord(Details)); // Fallback
  end;
end;

function GearModAttributeTypeToGearModType(Details: TGearModEffectType)
  : TGearModType;
begin
  case Details of
    gmetCriticalHitChance, gmetCriticalHitDamage, gmetHeadshotDamage:
      Result := gsmtOffensive;
    gmetProtectionFromElites, gmetArmorOnKillFlat, gmetStatusEffectResistance,
      gmetPulseResistance, gmetIncomingRepairs:
    // Corrected: Was gmatIncomingRepairs
      Result := gsmtDefensive;
    gmetSkillHaste, gmetSkillDuration, gmetRepairSkills, gmetSkillDamage,
      gmetSkillHealth:
      Result := gsmtUtility;
  else
    Result := gsmtGeneric; // Default for unclassified or gmetUnknown
  end;
end;

initialization

if (TUtils.FBitmapCache = nil) then
  TUtils.FBitmapCache := TObjectDictionary<string, TBitmap>.Create
    ([doOwnsValues]); // cache owns & frees bitmaps

finalization

if Assigned(TUtils.FBitmapCache) then
  FreeAndNil(TUtils.FBitmapCache);

end.
