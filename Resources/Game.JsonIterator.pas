unit Game.JsonIterator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Rtti, System.StrUtils,
  System.JSON, System.JSON.Types, System.JSON.Readers, System.JSON.Builders,
  System.Generics.Collections, System.Generics.Defaults, System.TypInfo, System.Variants,
  FMX.DialogService, FMX.Dialogs, Winapi.Windows, FMX.Graphics, FMX.MultiResBitmap,
  {units}
  Game.Player, Game.Types, Utils, System.ImageList, FMX.ImgList;

type
  // Callback for asynchronous processing.
  TProcessPieceSetCallback = reference to procedure(const APieceSet: TPieceSet);
  TProcessCoreAttrCallback = reference to procedure(const ACoreAttrDef
    : TCoreAttributeDefinition);

  TDataJsonIterator = class(TDataModule)
  published
    ImageList_GTalents: TImageList;
  private
    { Private declarations }
    FWeapons: TDictionary<Integer, TWeapon>;
    FWeaponStats: TDictionary<Integer, TWeaponStat>;
    FMods: TDictionary<Integer, TWeaponMod>;
    FTalents: TDictionary<Integer, TWeaponTalent>;
    FGearTalents: TDictionary<string, TDictionary<string, TList<string>>>;
    FGearTalentDefinitions: TDictionary<string, TGearTalentDefinition>;
    FTalentIconCache: TObjectDictionary<string, TBitmap>;
    FTalentImageIndices: TDictionary<string, Integer>;
    FGearModsData: TDictionary<Integer, TGearModDefinition>;
    FAllPieceSetDefinitions: TDictionary<string, TPieceSet>;
    FCoreAttributeDefinitions: TDictionary<string, TCoreAttributeDefinition>;
    FFixedMinorAttributeDefinitions: TDictionary<string, TFixedMinorAttributeDefinition>;
    FSkills: TDictionary<string, TSkillData>;
    FSpecializations: TDictionary<string, TSpecialization>;
    FPlayer: TPlayer; // Instance du joueur

    { low-level helpers }
    function StrToWeaponType(const S: string): TWeaponFamily;
    function StrToRarity(const S: string): TWeaponRarity;
    function StrToModSlot(const S: string): TModSlot;
    function StrToBonusType(const S: string): TBonusType;
    function StrToSetType_Parser(const S: string): TSetType;
    // Renamed for local use
    function StrToItemType_Parser(const S: string): TItemType;
    // Renamed for local use
    function DetermineBonusType_Parser_Local(const AttributeID: string;
      out WeaponType: TWeaponFamily): TSetBonusType; // Added

    procedure LoadWeaponsFromJson(const FileName: string);
    procedure LoadWeaponStats(const FileName: string);
    procedure LoadWeaponModsFromJson(const FileName: string);

    procedure LoadSpecializationsFromJson(const FileName: string);

    procedure LoadTalentsFromJson(const FileName: string);
    procedure LoadGearTalentsFromJson(const FileName: string);

    procedure LoadGearModsFromJson(const FileName: string);
    // procedure LoadGearPieceSetFromJson(const FileName: string);

    procedure LoadSkillsFromJson(const FileName: string);

    procedure LoadPlayerFromJson(const FileName: string);
    // Ajout pour le joueur

    procedure HandleParsingError(const ErrorMessage: string);

    procedure ParseCoreAttributes(var AIterator: TJSONIterator);
    function ParseCoreAttributeObject(var AIterator: TJSONIterator)
      : TCoreAttributeDefinition;
    procedure ParseFixedMinorAttributes(var AIterator: TJSONIterator);
    function ParseFixedMinorAttributeObject(var AIterator: TJSONIterator)
      : TFixedMinorAttributeDefinition;
    procedure ParseSetCategory(var AIterator: TJSONIterator;
      const ACategoryKey: string);
    function ParseSetObject(var AIterator: TJSONIterator; ASetType: TSetType)
      : TPieceSet;
    procedure ParseBonuses(var AIterator: TJSONIterator; var ASet: TPieceSet);
    procedure ParseParts(var AIterator: TJSONIterator; var ASet: TPieceSet);
    function CanonicalBrandName(const Raw: string): string;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure WriteLog(const Lines: TArray<string>;
      const FileName: string = 'debug.log');
    procedure Init(const AssetsPath: string);
    procedure ValidateLinks(out ErrorList: TArray<string>);
    procedure Reload;
    procedure LoadGearPieceSetFromJson(const FileName: string);
    procedure LoadGearPieceSetAsync(const AFileName: string;
      const APieceSetCallback: TProcessPieceSetCallback;
      const ACoreAttrCallback: TProcessCoreAttrCallback);
    // procedure LoadSkillsFromJson(const FileName: string);
    function GetTalentBitmap(const TalentName: string): TBitmap;
    function GetTalentImageIndex(const TalentName: string): Integer;
    function FindImageIndexByName(const AName: string): Integer;
    function GetTalentIconKey(const TalentName: string): string;

    { read-only access }
    property Weapons: TDictionary<Integer, TWeapon> read FWeapons;
    property WeaponStats: TDictionary<Integer, TWeaponStat> read FWeaponStats;
    property Mods: TDictionary<Integer, TWeaponMod> read FMods;
    property Talents: TDictionary<Integer, TWeaponTalent> read FTalents;
    property GearTalents: TDictionary<string, TDictionary<string, TList<string>>> read FGearTalents;
    property GearTalentDefinitions: TDictionary<string, TGearTalentDefinition> read FGearTalentDefinitions;
    property GearModsData: TDictionary<Integer, TGearModDefinition>
      read FGearModsData; // Gear Mods
    property AllPieceSetDefinitions: TDictionary<string, TPieceSet>
      read FAllPieceSetDefinitions;
    property CoreAttributeDefinitions
      : TDictionary<string, TCoreAttributeDefinition>
      read FCoreAttributeDefinitions;
    property FixedMinorAttributeDefinitions: TDictionary<string, TFixedMinorAttributeDefinition>
      read FFixedMinorAttributeDefinitions;
    // property Skills: TDictionary<string, TSkillDefinition> read FSkills;
    property Skills: TDictionary<string, TSkillData> read FSkills;
    property Specializations: TDictionary<string, TSpecialization>
      read FSpecializations;
    property Player: TPlayer read FPlayer;
    function FindGearPiece(const PieceName: string; out Piece: TGearPiece): Boolean;
    function FindFullGearPiece(const PieceName: string; out Piece: TGearPiece): Boolean;
    function CoreAttrIDToEnum(const ID: string): TCoreAttributeType;
  end;

var
  DataJsonIterator: TDataJsonIterator;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}
{$R *.dfm}
{ ─────────── helper ─────────── }

function TDataJsonIterator.StrToWeaponType(const S: string): TWeaponFamily;
begin
  if SameText(S, 'Assault Rifle') then
    Result := wcAR
  else if SameText(S, 'Submachine Gun') then
    Result := wcSMG
  else if SameText(S, 'Shotgun') then
    Result := wcSTG
  else if SameText(S, 'Light Machine Gun') then
    Result := wcLMG
  else if SameText(S, 'Marksman Rifle') then
    Result := wcMMR
  else if SameText(S, 'Rifle') then
    Result := wcRIFLE
  else if SameText(S, 'Pistol') then
    Result := wcPISTOL
  else
    Result := wcUnknown;
end;

function TDataJsonIterator.StrToRarity(const S: string): TWeaponRarity;
begin
  if SameText(S, 'Exotic') then
    Result := wrExotic
  else if SameText(S, 'Named') then
    Result := wrNamed
  else
    Result := wrHighEnd;
end;

function TDataJsonIterator.StrToModSlot(const S: string): TModSlot;
begin
  if SameText(S, 'Optics Rail') then // Ensure this exact string from JSON
    Result := msOptics
  else if SameText(S, 'Magazine') then
    Result := msMagazine
  else if SameText(S, 'Underbarrel') then
    Result := msUnderBarrel
    // Check your enum spelling: msUnderBarrel or msUnderbarrel
  else if SameText(S, 'Muzzle') then
    Result := msMuzzle
  else
  begin
    Result := msMuzzle; // Default or error
  end;
  // Result := msMuzzle;
end;

function TDataJsonIterator.StrToBonusType(const S: string): TBonusType;
begin
  if SameText(S, 'Multiplicative') then
    Result := btMultiplicative
  else if SameText(S, 'Amplified') then
    Result := btAmplified
  else
    Result := btAdditive; // Default to additive
end;

function StrToGearModType(const S: string): TGearModType;
begin
  if SameText(S, 'gsmtOffensive') then
    Result := gsmtOffensive // Updated string and enum value
  else if SameText(S, 'gsmtDefensive') then
    Result := gsmtDefensive // Updated string and enum value
  else if SameText(S, 'gsmtUtility') then
    Result := gsmtUtility // Updated string and enum value
  else if SameText(S, 'gsmtGeneric') then
    Result := gsmtGeneric // Updated string and enum value
  else
    Result := gsmtGeneric; // Default or raise error
end;

function StrToGearModEffectType(const S: string): TGearModEffectType;
begin
  if SameText(S, 'gmetCriticalHitChance') then
    Result := gmetCriticalHitChance // Updated string and enum value
  else if SameText(S, 'gmetCriticalHitDamage') then
    Result := gmetCriticalHitDamage // Updated string and enum value
  else if SameText(S, 'gmetHeadshotDamage') then
    Result := gmetHeadshotDamage // Updated string and enum value
  else if SameText(S, 'gmetProtectionFromElites') then
    Result := gmetProtectionFromElites // Updated string and enum value
  else if SameText(S, 'gmetArmorOnKillFlat') then
    Result := gmetArmorOnKillFlat // Updated string and enum value
  else if SameText(S, 'gmetStatusEffectResistance') then
    Result := gmetStatusEffectResistance // Updated string and enum value
  else if SameText(S, 'gmetPulseResistance') then
    Result := gmetPulseResistance // Updated string and enum value
  else if SameText(S, 'gmetExplosiveResistance') then
    Result := gmetExplosiveResistance // Updated string and enum value
  else if SameText(S, 'gmetIncomingRepairs') then
    Result := gmetIncomingRepairs
    // Corrected original typo and used new enum gmetIncomingRepairs
  else if SameText(S, 'gmetSkillHaste') then
    Result := gmetSkillHaste // Updated string and enum value
  else if SameText(S, 'gmetSkillDuration') then
    Result := gmetSkillDuration // Updated string and enum value
  else if SameText(S, 'gmetRepairSkills') then
    Result := gmetRepairSkills // Updated string and enum value
  else if SameText(S, 'gmetSkillDamage') then
    Result := gmetSkillDamage // Updated string and enum value
  else if SameText(S, 'gmetSkillHealth') then
    Result := gmetSkillHealth // Updated string and enum value
  else
    Result := gmetUnknown; // Default for unrecognized types
  // Consider raising an exception for truly unknown strings if strict parsing is required:
  // else raise EProgrammerNotFound.CreateFmt('Unknown Gear Mod Effect Type string: %s', [S]);
end;

// Helper function to map string to TSetType
function TDataJsonIterator.StrToSetType_Parser(const S: string): TSetType;
begin
  if SameText(S, 'brandSets') then
    Result := stBrandSet
  else if SameText(S, 'gearSets') then
    Result := stGearSet
  else if SameText(S, 'namedSets') then
    Result := stNamedSet
  else if SameText(S, 'exoticSets') then
    Result := stExoticSet
  else if SameText(S, 'improvisedSets') then
    Result := stImprovised
  else
    Result := stImprovised;
end;

// Helper to map string to TItemType
function TDataJsonIterator.StrToItemType_Parser(const S: string): TItemType;
var
  L: string;
begin
  L := LowerCase(S);
  if Copy(L, 1, 4) = 'mask' then
    Result := itMask
  else if Copy(L, 1, 8) = 'backpack' then
    Result := itBackpack
  else if Copy(L, 1, 4) = 'vest' then
    Result := itChest
  else if Copy(L, 1, 5) = 'glove' then
    Result := itGloves
  else if Copy(L, 1, 7) = 'holster' then
    Result := itHolster
  else if Copy(L, 1, 7) = 'kneepad' then
    Result := itKneepads
  else
    Result := itUnknown;
  // Default, or consider raising an error for unknown types
end;

// Helper to determine TSetBonusType based on AttributeID
function TDataJsonIterator.DetermineBonusType_Parser_Local(const AttributeID
  : string; out WeaponType: TWeaponFamily): TSetBonusType;
var
  NormalizedID: string;
  UnderscorePos: Integer;
begin
  // Normalize the attribute ID by removing numeric suffixes (_0, _1, etc.)
  NormalizedID := AttributeID;
  UnderscorePos := NormalizedID.LastIndexOf('_');
  if UnderscorePos > 0 then
  begin
    var Suffix := NormalizedID.Substring(UnderscorePos + 1);
    var IsNumericSuffix := True;
    if Suffix.IsEmpty then
      IsNumericSuffix := False
    else
      for var C in Suffix do
      begin
        if not CharInSet(C, ['0'..'9']) then
        begin
          IsNumericSuffix := False;
          Break;
        end;
      end;
    if IsNumericSuffix then
      NormalizedID := NormalizedID.Substring(0, UnderscorePos);
  end;

  WeaponType := wcUnknown;
  if NormalizedID = 'weapon_damage' then
    Result := sbtWeaponDamage
  else if AttributeID = 'assault_rifle_damage' then
  begin
    Result := sbtWeaponTypeDamage;
    WeaponType := wcAR;
  end
  else if AttributeID = 'smg_damage' then
  begin
    Result := sbtWeaponTypeDamage;
    WeaponType := wcSMG;
  end
  else if AttributeID = 'marksman_rifle_damage' then
  begin
    Result := sbtWeaponTypeDamage;
    WeaponType := wcMMR;
  end
  else if AttributeID = 'rifle_damage' then
  begin
    Result := sbtWeaponTypeDamage;
    WeaponType := wcRIFLE;
  end
  else if AttributeID = 'shotgun_damage' then
  begin
    Result := sbtWeaponTypeDamage;
    WeaponType := wcSTG;
  end
  else if AttributeID = 'lmg_damage' then
  begin
    Result := sbtWeaponTypeDamage;
    WeaponType := wcLMG;
  end
  else if AttributeID = 'pistol_damage' then
  begin
    Result := sbtWeaponTypeDamage;
    WeaponType := wcPISTOL;
  end
  else if AttributeID = 'critical_hit_chance' then
    Result := sbtAttribute
  else if AttributeID = 'critical_hit_damage' then
    Result := sbtAttribute
  else if AttributeID = 'headshot_damage' then
    Result := sbtAttribute
  else if (AttributeID = 'damage_to_armor') or (AttributeID = 'damageToArmor') then
    Result := sbtAttribute        // Was sbtMultiplicativeDamage, changed to sbtAttribute for consistency with CalcEngine
  else if (AttributeID = 'damage_to_health') or (AttributeID = 'damageToHealth') then
    Result := sbtAttribute        // Was sbtMultiplicativeDamage
  else if (AttributeID = 'damage_to_targets_out_of_cover') or (AttributeID = 'damageToTargetOutOfCover') then
    Result := sbtAttribute        // Was sbtMultiplicativeDamage
  else if (AttributeID = 'health_damage') or (AttributeID = 'healthDamage') then
    Result := sbtAttribute
  else if AttributeID = 'skill_tier' then
    Result := sbtCoreAttribute
  else if AttributeID = 'armor' then
    Result := sbtCoreAttribute    // Add more specific sbtAttribute types here (e.g. skillHaste, armorRegen etc.)

  // Skill Attributes
  else if (AttributeID = 'skill_haste') or (AttributeID = 'skillHaste') then Result := sbtSkillAttribute
  else if (AttributeID = 'skill_damage') or (AttributeID = 'skillDamage') then Result := sbtSkillAttribute
  else if (AttributeID = 'repair_skills') or (AttributeID = 'repairSkills') then Result := sbtSkillAttribute
  else if (AttributeID = 'status_effects') or (AttributeID = 'statusEffects') then Result := sbtSkillAttribute
  else if (AttributeID = 'skill_duration') or (AttributeID = 'skillDuration') then Result := sbtSkillAttribute
  else if (AttributeID = 'skill_health') or (AttributeID = 'skillHealth') then Result := sbtSkillAttribute
  else if (AttributeID = 'explosive_damage') or (AttributeID = 'explosiveDamage') then Result := sbtSkillAttribute
  else if (AttributeID = 'burn_damage') or (AttributeID = 'burnDamage') then Result := sbtSkillAttribute
  else if (AttributeID = 'burn_duration') or (AttributeID = 'burnDuration') then Result := sbtSkillAttribute

  // Defense Attributes
  else if (AttributeID = 'armor_regen') or (AttributeID = 'armorRegen') then Result := sbtDefenseAttribute
  else if (AttributeID = 'armor_regen_pct') or (AttributeID = 'armorRegenPct') then Result := sbtDefenseAttribute
  else if (AttributeID = 'armor_on_kill') or (AttributeID = 'armorOnKill') then Result := sbtDefenseAttribute
  else if (AttributeID = 'health_on_kill') or (AttributeID = 'healthOnKill') then Result := sbtDefenseAttribute
  else if (AttributeID = 'hazard_protection') or (AttributeID = 'hazardProtection') then Result := sbtDefenseAttribute
  else if (AttributeID = 'health') then Result := sbtDefenseAttribute
  else if (AttributeID = 'total_armor') or (AttributeID = 'totalArmor') then Result := sbtDefenseAttribute
  else if (AttributeID = 'incoming_repairs') or (AttributeID = 'incomingRepairs') then Result := sbtDefenseAttribute

  // Resistances
  else if (AttributeID = 'explosive_resistance') or (AttributeID = 'explosiveResistance') then Result := sbtResistance
  else if (AttributeID = 'protection_from_elites') or (AttributeID = 'protectionFromElites') then Result := sbtResistance
  else if (AttributeID = 'pulse_resistance') or (AttributeID = 'pulseResistance') then Result := sbtResistance
  else if (AttributeID = 'disrupt_resistance') or (AttributeID = 'disruptResistance') then Result := sbtResistance
  else if (AttributeID = 'shock_resistance') or (AttributeID = 'shockResistance') then Result := sbtResistance
  else if (AttributeID = 'burn_resistance') or (AttributeID = 'burnResistance') then Result := sbtResistance

  // Weapon Handling & Misc
  else if (AttributeID = 'accuracy') then Result := sbtAttribute
  else if (AttributeID = 'stability') then Result := sbtAttribute
  else if (AttributeID = 'reload_speed') or (AttributeID = 'reloadSpeed') then Result := sbtAttribute
  else if (AttributeID = 'weapon_handling') or (AttributeID = 'weaponHandling') then Result := sbtAttribute
  else if (AttributeID = 'ammo_capacity') or (AttributeID = 'ammoCapacity') then Result := sbtAttribute
  else if (AttributeID = 'magazine_size') or (AttributeID = 'magazineSize') then Result := sbtAttribute
  else if (AttributeID = 'swap_speed') or (AttributeID = 'swapSpeed') then Result := sbtAttribute
  else if (AttributeID = 'optimal_range') or (AttributeID = 'optimalRange') then Result := sbtAttribute
  else if (AttributeID = 'rate_of_fire') or (AttributeID = 'rateOfFire') then Result := sbtAttribute
  else if (AttributeID = 'increased_threat') or (AttributeID = 'increasedThreat') then Result := sbtAttribute
  else if (AttributeID = 'reduced_threat') or (AttributeID = 'reducedThreat') then Result := sbtAttribute

  else if (AttributeID = 'description') or (Pos('description_', AttributeID) = 1)
  then
    Result := sbtSpecial
  else
    Result := sbtSpecial;         // Default for unmapped complex talents or textual descriptions
end;

{
function StrToSkillCategory(const S: string): TSkillCategory;
begin
  if SameText(S, 'scOffensive') then
    Result := scOffensive
  else if SameText(S, 'scDefensive') then
    Result := scDefensive
  else if SameText(S, 'scCrowdControl') then
    Result := scCrowdControl
  else if SameText(S, 'scSupport') then
    Result := scSupport
  else if SameText(S, 'scHealing') then
    Result := scHealing
  else
    Result := scOffensive; // Default to Offensive
end;
}

// Helper function to convert Core Attribute ID string to enum
function TDataJsonIterator.CoreAttrIDToEnum(const ID: string): TCoreAttributeType;
begin
  if SameText(ID, 'weaponDamage') then Exit(catWeaponDamage)
  else if SameText(ID, 'armor') then Exit(catArmor)
  else if SameText(ID, 'skillTier') then Exit(catSkillTier)
  else Exit(catWeaponDamage); // default/fallback
end;

function TDataJsonIterator.CanonicalBrandName(const Raw: string): string;
var
  LOpenParen, LCloseParen: Integer;
begin
  Result := Trim(Raw);
  if Result = '' then
    Exit;

  // Special hard-coded named items that belong to Walker, Harris & Co.
  if SameText(Result, 'Matador') or SameText(Result, 'Chain Killer') then
  begin
    Result := 'Walker, Harris & Co.';
    Exit;
  end;

  LOpenParen := Pos('(', Result);
  LCloseParen := LastDelimiter(')', Result);
  if (LOpenParen > 0) and (LCloseParen > LOpenParen) then
    Result := Trim(Copy(Result, LOpenParen + 1, LCloseParen - LOpenParen - 1));
end;

function TDataJsonIterator.GetTalentBitmap(const TalentName: string): TBitmap;
var
  Def: TGearTalentDefinition;
  Path: string;
  NormalizedKey: string;
  LBitmapItem: TCustomBitmapItem;
  LSize: TSize;
begin
  if FTalentIconCache.TryGetValue(TalentName, Result) then
    Exit;

  Result := nil;
  if FGearTalentDefinitions.TryGetValue(TalentName.Trim, Def) and (Def.IconFilename <> '') then
  begin
    // ---------------------------------------------------------
    // 1. Hybrid Approach: Key-Based Lookup (Recommended)
    // ---------------------------------------------------------
    // Normalize: remove path, remove extension, lowercase.
    // JSON: "Talents/Gears/Braced.png" -> Key: "braced"
    NormalizedKey := TPath.GetFileNameWithoutExtension(Def.IconFilename).Trim.ToLower;

    // A) Try finding in ImageList first (Fast RAM Cache)
    if Assigned(ImageList_GTalents) then
    begin
      if ImageList_GTalents.BitmapItemByName(NormalizedKey, LBitmapItem, LSize) and Assigned(LBitmapItem) then
      begin
        Result := TBitmap.Create;
        try
          // Create a copy from the ImageList
          Result.Assign(LBitmapItem.Bitmap);
          FTalentIconCache.Add(TalentName, Result);
          Exit;
        except
          Result.Free;
          Result := nil;
        end;
      end;
    end;

    // ---------------------------------------------------------
    // 2. Fallback: Disk Load (Lazy Loading)
    // ---------------------------------------------------------
    // If not in ImageList, try to find it on disk using the Key or original filename
    Path := TPath.Combine(TPath.Combine(TUtils.AssetsPath, 'Talents'), 'Gears');

    // Construct the fallback path. We prioritize the NormalizedKey + .png
    // to align with the standard naming convention.
    var FileToLoad := TPath.Combine(Path, NormalizedKey + '.png');

    if not TFile.Exists(FileToLoad) then
    begin
       // Last resort: try the raw filename from JSON if it differs (e.g. "foo.jpg")
       var RawPath := TPath.Combine(Path, TPath.GetFileName(Def.IconFilename));
       if TFile.Exists(RawPath) then
         FileToLoad := RawPath;
    end;

    if TFile.Exists(FileToLoad) then
    begin
      Result := TBitmap.Create;
      try
        Result.LoadFromFile(FileToLoad);
        FTalentIconCache.Add(TalentName, Result);
      except
        on E: Exception do
        begin
          WriteLog(['Error loading talent icon: ' + FileToLoad + ' - ' + E.Message]);
          Result.Free;
          Result := nil;
        end;
      end;
    end
    else
    begin
      WriteLog(['Warning: Icon file not found for talent "' + TalentName + '" Key: ' + NormalizedKey + ' File: ' + FileToLoad]);
    end;
  end else if not FGearTalentDefinitions.ContainsKey(TalentName) then begin
      WriteLog(['Warning: Talent definition not found for "' + TalentName + '"']);
  end else begin
      WriteLog(['Warning: Icon filename empty for talent "' + TalentName + '"']);
  end;
end;

function TDataJsonIterator.GetTalentImageIndex(const TalentName: string): Integer;
var
  Bmp: TBitmap;
  LSourceItem: TCustomSourceItem;
  Def: TGearTalentDefinition;
  NormalizedKey: string;
begin
  // 1. Runtime Cache (Fastest)
  if FTalentImageIndices.TryGetValue(TalentName, Result) then
    Exit;

  Result := -1;

  // 2. Resolve Definition
  if not FGearTalentDefinitions.TryGetValue(TalentName.Trim, Def) then
  begin
    WriteLog(['GetTalentImageIndex: Talent not found in definitions: ' + TalentName]);
    Exit;
  end;

  // 3. Hybrid Key-Based Lookup
  if (Def.IconFilename <> '') and Assigned(ImageList_GTalents) then
  begin
    // Normalize Key: "Talents/Gears/Braced.png" -> "braced"
    NormalizedKey := TPath.GetFileNameWithoutExtension(Def.IconFilename).Trim.ToLower;

    // A) Check if already in ImageList (Design-time or previously loaded)
    // TSourceCollection.IndexOf is case-insensitive
    Result := ImageList_GTalents.Source.IndexOf(NormalizedKey);
    if Result >= 0 then
    begin
      FTalentImageIndices.Add(TalentName, Result);
      Exit;
    end;

    // B) Not found? Load from Disk via GetTalentBitmap (Lazy Load)
    // This handles loading, cache update, and returns the bitmap
    Bmp := GetTalentBitmap(TalentName);

    if Assigned(Bmp) then
    begin
      // Add to ImageList with the Normalized Key so next time IndexOf works
      LSourceItem := ImageList_GTalents.Source.Add;
      LSourceItem.Name := NormalizedKey;
      LSourceItem.MultiResBitmap.Add.Bitmap.Assign(Bmp);

      // Add corresponding Destination item if using ImageList
      // Check if a destination item already exists for this name (unlikely if source wasn't there)
      // We must add a destination so it can be indexed by the UI
      var LDestItem := ImageList_GTalents.Destination.Add;
      var LLayer := LDestItem.Layers.Add;
      LLayer.Name := NormalizedKey;

      Result := LDestItem.Index;
      FTalentImageIndices.Add(TalentName, Result);
    end
    else
      WriteLog(['GetTalentImageIndex: GetTalentBitmap returned nil for ' + TalentName]);
  end
  else
  begin
    if not Assigned(ImageList_GTalents) then WriteLog(['GetTalentImageIndex: ImageList_GTalents is nil!']);
    if Def.IconFilename = '' then WriteLog(['GetTalentImageIndex: IconFilename is empty for ' + TalentName]);
  end;
end;

function TDataJsonIterator.FindImageIndexByName(const AName: string): Integer;
var
  I: Integer;
  LName, LNoExt: string;
begin
  Result := -1;
  if not Assigned(ImageList_GTalents) then
    Exit;

  // match by Source item name, with or without extension, case-insensitive
  for I := 0 to ImageList_GTalents.Source.Count - 1 do
  begin
    LName := ImageList_GTalents.Source[I].Name;
    if SameText(LName, AName) or SameText(LName, AName + '.png') then
      Exit(I);

    // Also handle cases where the ImageList item is named with extension
    LNoExt := TPath.GetFileNameWithoutExtension(LName);
    if SameText(LNoExt, AName) then
      Exit(I);
  end;
end;

function TDataJsonIterator.GetTalentIconKey(const TalentName: string): string;
var
  Def: TGearTalentDefinition;
begin
  Result := '';
  if FGearTalentDefinitions.TryGetValue(TalentName.Trim, Def) then
    Result := Def.IconFilename.Trim.ToLower;
end;

constructor TDataJsonIterator.Create(AOwner: TComponent);
var
  LogFile: TFileStream;
  Errors: TArray<string>;
begin
  inherited;
  if not Assigned(ImageList_GTalents) then
    ImageList_GTalents := TImageList.Create(Self);

  FWeapons := TDictionary<Integer, TWeapon>.Create;
  FWeaponStats := TDictionary<Integer, TWeaponStat>.Create;
  FMods := TDictionary<Integer, TWeaponMod>.Create;
  FTalents := TDictionary<Integer, TWeaponTalent>.Create;
  FGearTalents := TDictionary<string, TDictionary<string, TList<string>>>.Create(TStringComparer.Ordinal);
  FGearTalentDefinitions := TDictionary<string, TGearTalentDefinition>.Create(TStringComparer.Ordinal);
  FTalentIconCache := TObjectDictionary<string, TBitmap>.Create([doOwnsValues], TStringComparer.Ordinal);
  FTalentImageIndices := TDictionary<string, Integer>.Create(TStringComparer.Ordinal);
  FGearModsData := TDictionary<Integer, TGearModDefinition>.Create;
  // Create GearMods dictionary
  FAllPieceSetDefinitions := TDictionary<string, TPieceSet>.Create;
  FCoreAttributeDefinitions :=
    TDictionary<string, TCoreAttributeDefinition>.Create;
  FFixedMinorAttributeDefinitions :=
    TDictionary<string, TFixedMinorAttributeDefinition>.Create;

//  if Assigned(FSkills) then
//    FSkills.Clear
//  else
    FSkills := TDictionary<string, TSkillData>.Create;

  FSpecializations := TDictionary<string, TSpecialization>.Create;
  FPlayer := TPlayer.Create; // Créer l'instance du joueur

  // chargement + validation
  Init(TUtils.AssetsPath);

  ValidateLinks(Errors);
  if Length(Errors) > 0 then
  begin
    TDialogService.ShowMessage('ERREURS dans les JSON :' + sLineBreak +
      string.Join(sLineBreak, Errors));
    WriteLog(Errors);
  end;
end;

destructor TDataJsonIterator.Destroy;
begin
  FWeapons.Free;
  FWeaponStats.Free;
  FMods.Free;
  FTalents.Free;

  if Assigned(FGearTalents) then
  begin
    for var SlotDict in FGearTalents.Values do
    begin
      for var List in SlotDict.Values do
        List.Free;
      SlotDict.Free;
    end;
    FGearTalents.Free;
  end;
  FGearTalentDefinitions.Free;
  FTalentIconCache.Free;
  FTalentImageIndices.Free;
  FGearModsData.Free;
  FAllPieceSetDefinitions.Free;
  FCoreAttributeDefinitions.Free;
  FFixedMinorAttributeDefinitions.Free;
  FSkills.Free;
  for var Spec in FSpecializations.Values do
    Spec.Free;
  FSpecializations.Free;
  FPlayer.Free;
  inherited;
end;

procedure TDataJsonIterator.HandleParsingError(const ErrorMessage: string);
begin
  TDialogService.ShowMessage('An error occurred while loading data: ' +
    ErrorMessage +
    '. Please ensure the data files are correct or contact support.');
end;

procedure TDataJsonIterator.WriteLog(const Lines: TArray<string>;
  const FileName: string = 'debug.log');
var
  Log: TStringList;
  I: Integer;
  S: string;
begin
  Log := TStringList.Create;
  try
    if FileExists(FileName) then
      Log.LoadFromFile(FileName, TEncoding.UTF8);
    Log.Add('[' + DateTimeToStr(Now) + ']');
    for I := 0 to High(Lines) do
    begin
      S := Lines[I];
      Log.Add(S);
    end;
    Log.Add(''); // blank line for spacing
    Log.SaveToFile(FileName, TEncoding.UTF8);
  finally
    Log.Free;
  end;
end;

procedure TDataJsonIterator.Reload;
var
  Errs: TArray<string>;
begin
  // vider les dicos
  FWeapons.Clear;
  FWeaponStats.Clear;
  FMods.Clear;
  FTalents.Clear;

  if Assigned(FGearTalents) then
  begin
    for var SlotDict in FGearTalents.Values do
    begin
      for var List in SlotDict.Values do
        List.Free;
      SlotDict.Free;
    end;
    FGearTalents.Clear;
  end;
  FGearTalentDefinitions.Clear;
  FTalentIconCache.Clear;
  FTalentImageIndices.Clear;
  if Assigned(ImageList_GTalents) then
    ImageList_GTalents.Source.Clear;
  FGearModsData.Clear;
  FAllPieceSetDefinitions.Clear;
  FCoreAttributeDefinitions.Clear;
  FFixedMinorAttributeDefinitions.Clear;
  FSkills.Clear;

  for var Spec in FSpecializations.Values do
    Spec.Free;
  FSpecializations.Clear;

  // recharger
  Init(TUtils.AssetsPath);
  ValidateLinks(Errs);
  if Length(Errs) > 0 then
    TDialogService.ShowMessage('ERREURS après reload :'#13#10 +
      string.Join(sLineBreak, Errs));
  WriteLog(Errs);
end;

// --- Implementation of the TJSONIterator-based Helper Functions ---
function TDataJsonIterator.ParseCoreAttributeObject(var AIterator
  : TJSONIterator): TCoreAttributeDefinition;
begin
  Result := Default (TCoreAttributeDefinition);
  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndObject) do
  begin
    if SameText(AIterator.Key, 'id') then
      Result.ID := AIterator.AsString
    else if SameText(AIterator.Key, 'type') then
      Result.TypeName := AIterator.AsString
    else if SameText(AIterator.Key, 'value') then
      Result.Value := AIterator.AsDouble;
  end;
  AIterator.Return;
end;

procedure TDataJsonIterator.ParseCoreAttributes(var AIterator: TJSONIterator);
var
  LCoreDef: TCoreAttributeDefinition;
begin
  if AIterator.&Type <> TJsonToken.StartArray then
  begin
    WriteLog(['Warning: "coreAttributes" is not an array. Ignored.']);
    Exit;
  end;

  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndArray) do
  begin
    if AIterator.&Type = TJsonToken.StartObject then
    begin
      LCoreDef := Default (TCoreAttributeDefinition);
      AIterator.Recurse;
      while AIterator.Next and (AIterator.&Type <> TJsonToken.EndObject) do
      begin
        if SameText(AIterator.Key, 'id') then
          LCoreDef.ID := AIterator.AsString
        else if SameText(AIterator.Key, 'type') then
          LCoreDef.TypeName := AIterator.AsString
        else if SameText(AIterator.Key, 'value') then
          LCoreDef.Value := AIterator.AsDouble;
      end;
      AIterator.Return;

      if not LCoreDef.ID.IsEmpty then
        FCoreAttributeDefinitions.AddOrSetValue(LCoreDef.ID, LCoreDef);
    end;
  end;

  AIterator.Return;
end;

function TDataJsonIterator.ParseFixedMinorAttributeObject(var AIterator: TJSONIterator): TFixedMinorAttributeDefinition;
begin
  Result := Default(TFixedMinorAttributeDefinition);
  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndObject) do
  begin
    if SameText(AIterator.Key, 'id') then
      Result.ID := AIterator.AsString
    else if SameText(AIterator.Key, 'type') then
      Result.TypeName := AIterator.AsString
    else if SameText(AIterator.Key, 'value') then
      Result.Value := AIterator.AsDouble;
  end;
  AIterator.Return;
end;

procedure TDataJsonIterator.ParseFixedMinorAttributes(var AIterator: TJSONIterator);
var
  LDef: TFixedMinorAttributeDefinition;
begin
  if AIterator.&Type <> TJsonToken.StartArray then
  begin
    WriteLog(['Warning: "fixedMinorAttributes" is not an array. Ignored.']);
    Exit;
  end;

  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndArray) do
  begin
    if AIterator.&Type = TJsonToken.StartObject then
    begin
      LDef := ParseFixedMinorAttributeObject(AIterator);
      if not LDef.ID.IsEmpty then
        FFixedMinorAttributeDefinitions.AddOrSetValue(LDef.ID, LDef);
    end;
  end;
  AIterator.Return;
end;

procedure TDataJsonIterator.ParseSetCategory(var AIterator: TJSONIterator;
  const ACategoryKey: string);
var
  LSet: TPieceSet;
  LFinalKey: string;
begin
  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndArray) do
  begin
    if AIterator.&Type = TJsonToken.StartObject then
    begin
      LSet := ParseSetObject(AIterator, StrToSetType_Parser(ACategoryKey));

      // Apply Naming Logic for Named Sets
      LFinalKey := LSet.Name;
      if (LSet.SetType = stNamedSet) and (Length(LSet.Parts) > 0) then
      begin
        // e.g., "The Hollow Man (Yaahl Gear)"
        LFinalKey := Format('%s (%s)', [LSet.Parts[0].Name, LSet.Name]);
        // Also update the piece's own name for consistency, as it's now the primary identifier
        LSet.Name := LFinalKey;
      end;

      if not LFinalKey.IsEmpty then
        FAllPieceSetDefinitions.AddOrSetValue(LFinalKey, LSet)
      else
        WriteLog(['Warning: Found unnamed piece set in category: ' +
          ACategoryKey]);
    end;
  end;
  AIterator.Return;
end;

function TDataJsonIterator.ParseSetObject(var AIterator: TJSONIterator;
  ASetType: TSetType): TPieceSet;
begin
  Result := Default (TPieceSet);
  Result.SetType := ASetType;
  SetLength(Result.Bonuses, 0);
  SetLength(Result.Parts, 0);

  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndObject) do
  begin
    if SameText(AIterator.Key, 'name') then
      Result.Name := AIterator.AsString
    else if SameText(AIterator.Key, 'imageIndex') then
      Result.ImageIndex := AIterator.AsInteger
    else if (SameText(AIterator.Key, 'bonuses') or SameText(AIterator.Key,
      'setBonuses')) and (AIterator.&Type = TJsonToken.StartArray) then
      ParseBonuses(AIterator, Result)
    else if SameText(AIterator.Key, 'parts') and
      (AIterator.&Type = TJsonToken.StartObject) then
      ParseParts(AIterator, Result);
  end;
  AIterator.Return;
end;

procedure TDataJsonIterator.ParseBonuses(var AIterator: TJSONIterator;
  var ASet: TPieceSet);
var
  LBonus: TSetBonus;
  LBonusAttrID: string;
  LBonusValue: Variant;
  LWpnFam: TWeaponFamily;
begin
  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndArray) do
  begin
    if AIterator.&Type = TJsonToken.StartObject then
    begin
      LBonus := Default (TSetBonus);
      LBonusAttrID := '';
      LBonusValue := Null;
      AIterator.Recurse;
      while AIterator.Next and (AIterator.&Type <> TJsonToken.EndObject) do
      begin
        if SameText(AIterator.Key, 'itemsRequired') then
          LBonus.ItemsRequired := AIterator.AsInteger
        else if SameText(AIterator.Key, 'attribute') then
          LBonusAttrID := AIterator.AsString
        else if SameText(AIterator.Key, 'value') then
          LBonusValue := AIterator.AsVariant
        else if not(SameText(AIterator.Key, 'title') or SameText(AIterator.Key,
          'description')) then
        begin
          LBonusAttrID := AIterator.Key;
          LBonusValue := AIterator.AsVariant;
        end;
      end;
      AIterator.Return;

      LBonus.AttributeID := LBonusAttrID;
      if VarIsNumeric(LBonusValue) then
        LBonus.Value := LBonusValue
      else
        LBonus.Description := VarToStr(LBonusValue);
      LBonus.BonusType := DetermineBonusType_Parser_Local(LBonusAttrID,
        LWpnFam);
      LBonus.WeaponType := LWpnFam;
      ASet.Bonuses := ASet.Bonuses + [LBonus];
    end;
  end;
  AIterator.Return;
end;

procedure TDataJsonIterator.ParseParts(var AIterator: TJSONIterator;
  var ASet: TPieceSet);
var
  LPart: TPart;
begin
  AIterator.Recurse;
  while AIterator.Next and (AIterator.&Type <> TJsonToken.EndObject) do
  begin
    LPart := Default (TPart);
    LPart.GearSlot := StrToItemType_Parser(AIterator.Key);
    LPart.MinorAttributeSlotCount := 2; // Default for standard gear

    if AIterator.&Type = TJsonToken.StartObject then
    begin
      AIterator.Recurse;
      while AIterator.Next and (AIterator.&Type <> TJsonToken.EndObject) do
      begin
        if SameText(AIterator.Key, 'name') then
          LPart.Name := AIterator.AsString
        else if SameText(AIterator.Key, 'coreAttribute') then
          LPart.CoreAttributeID := AIterator.AsString
        else if SameText(AIterator.Key, 'minorAttributeSlotCount') then
           LPart.MinorAttributeSlotCount := AIterator.AsInteger
        else if SameText(AIterator.Key, 'fixedMinorAttributes') and (AIterator.&Type = TJsonToken.StartArray) then
        begin
          var LIds: TArray<string>;
          SetLength(LIds, 0);
          AIterator.Recurse;
          while AIterator.Next and (AIterator.&Type <> TJsonToken.EndArray) do
          begin
            if AIterator.&Type = TJsonToken.String then
              LIds := LIds + [AIterator.AsString];
          end;
          AIterator.Return;
          LPart.FixedMinorAttributeIDs := LIds;
        end
        else if SameText(AIterator.Key, 'talent') then
        begin
          if AIterator.&Type = TJsonToken.String then
          begin
            LPart.Talent := AIterator.AsString;
          end
          else if AIterator.&Type = TJsonToken.StartArray then
          begin
            AIterator.Recurse; // Enter the array
            // Read the first talent if it exists
            if AIterator.Next and (AIterator.&Type = TJsonToken.String) then
            begin
              LPart.Talent := AIterator.AsString;
            end;
            // Consume the rest of the array to avoid errors
            while AIterator.Next and (AIterator.&Type <> TJsonToken.EndArray) do
            begin
              // Skip remaining elements
            end;
            AIterator.Return; // Exit the array
          end;
        end
      end;
      AIterator.Return;
      ASet.Parts := ASet.Parts + [LPart];
    end
    else
      WriteLog([Format
        ('Warning: Part data for \"%s\" is malformed in set \"%s\".',
        [AIterator.Key, ASet.Name])]);
  end;
  AIterator.Return;
end;

{ ─────────── public entry ─────────── }

procedure TDataJsonIterator.Init(const AssetsPath: string);
begin
  LoadWeaponsFromJson(TPath.Combine(TUtils.AssetsPath, 'Weapons.json'));
  LoadWeaponStats(TPath.Combine(TUtils.AssetsPath, 'Weapon_stats.json'));
  LoadWeaponModsFromJson(TPath.Combine(TUtils.AssetsPath, 'Weapon_mods.json'));
  LoadTalentsFromJson(TPath.Combine(TUtils.AssetsPath, 'Weapon_talents.json'));
  LoadGearTalentsFromJson(TPath.Combine(TUtils.AssetsPath, 'Talents.json'));
  LoadGearModsFromJson(TPath.Combine(TUtils.AssetsPath, 'Gear_mods.json'));
  LoadGearPieceSetFromJson(TPath.Combine(TUtils.AssetsPath, 'Brands.json'));
  LoadSkillsFromJson(TPath.Combine(TUtils.AssetsPath, 'Skills.json'));
  LoadSpecializationsFromJson(TPath.Combine(TUtils.AssetsPath,
    'Specializations.json'));
  LoadPlayerFromJson(TPath.Combine(TUtils.AssetsPath, 'Player.json'));
end;

{ ─────────── 1/8  – Specializations.json ─────────── }
procedure TDataJsonIterator.LoadSpecializationsFromJson(const FileName: string);
var
  LSR: TStringReader;
  JR: TJsonTextReader;
  It: TJSONIterator;
  LJsonText: string;
  CurrentSpec: TSpecialization;
  BonusesDict: TDictionary<TWeaponFamily, Double>;
  GeneralBonusesDict: TDictionary<string, Double>;
begin
  FSpecializations.Clear;

  try
    try
      LJsonText := TFile.ReadAllText(FileName, TEncoding.UTF8);
      if LJsonText.IsEmpty then
      begin
        HandleParsingError('Specializations JSON file is empty: ' + FileName);
        Exit;
      end;

      LSR := TStringReader.Create(LJsonText);
      JR := TJsonTextReader.Create(LSR);
      It := TJSONIterator.Create(JR);

      if It.Next and (It.&Type in [TJsonToken.StartArray,
        TJsonToken.StartObject]) then
      begin
        while It.Next do
        begin
          if It.&Type = TJsonToken.EndArray then
            Break;
          if It.&Type = TJsonToken.StartObject then
          begin
            CurrentSpec := TSpecialization.Create;
            BonusesDict := TDictionary<TWeaponFamily, Double>.Create;
            GeneralBonusesDict := TDictionary<string, Double>.Create;

            It.Recurse;
            while It.Next do
            begin
              if SameText(It.Key, 'name') then
                CurrentSpec.Name := It.AsString
              else if SameText(It.Key, 'signature_weapon') then
                CurrentSpec.SignatureWeaponName := It.AsString
              else if SameText(It.Key, 'image_path') then
                CurrentSpec.image_path := It.AsString
              else if SameText(It.Key, 'unique_skill_variant') then
                CurrentSpec.UniqueSkillVariant := It.AsString
              else if SameText(It.Key, 'inherent_weapon_type_bonuses') and
                (It.&Type = TJsonToken.StartObject) then
              begin
                It.Recurse;
                while It.Next do
                begin
                  BonusesDict.Add(StrToWeaponType(It.Key), It.AsDouble);
                end;
                It.Return;
              end
              else if SameText(It.Key, 'general_bonuses') and
                (It.&Type = TJsonToken.StartObject) then
              begin
                It.Recurse;
                while It.Next do
                begin
                  GeneralBonusesDict.Add(It.Key, It.AsDouble);
                end;
                It.Return;
              end;
            end;
            It.Return;

            CurrentSpec.InherentWeaponTypeBonuses := BonusesDict;
            CurrentSpec.GeneralBonuses := GeneralBonusesDict;

            if not CurrentSpec.Name.IsEmpty then
            begin
              FSpecializations.AddOrSetValue(CurrentSpec.Name, CurrentSpec);
              CurrentSpec := nil;
            end
            else
            begin
              WriteLog(['Skipped invalid specialization data. Name is empty.']);
              CurrentSpec.Free;
              CurrentSpec := nil;
            end;
          end;
        end;
      end;
    finally
      FreeAndNil(It);
      FreeAndNil(JR);
      FreeAndNil(LSR);
//      FreeAndNil(CurrentSpec);
    end;
  except
    on E: Exception do
    begin
      HandleParsingError('Exception in LoadSpecializationsFromJson: ' +
        E.Message);
      if Assigned(It) then
        FreeAndNil(It);
      if Assigned(JR) then
        FreeAndNil(JR);
      if Assigned(LSR) then
        FreeAndNil(LSR);
    end;
  end;
end;

{ ─────────── 2/8  – Weapons.json ─────────── }

procedure TDataJsonIterator.LoadWeaponsFromJson(const FileName: string);
var
  Reader: TJsonTextReader;
  It: TJSONIterator;
  SR: TStringReader;
  WeaponFamily: TWeaponFamily;
  ModelName: string;
  W: TWeapon;
  CurrentSlot: TModSlot;
  ModelTalentIDs: TArray<Integer>;
begin
  SR := TStringReader.Create(TFile.ReadAllText(FileName, TEncoding.UTF8));
  Reader := TJsonTextReader.Create(SR);
  It := TJSONIterator.Create(Reader);

  W.SelectedMinorAttributeType := '';

  try
    while It.Next do
      if (It.Key = 'categories') then
      begin
        if It.&Type = TJsonToken.PropertyName then // sauter sur l’{ du bloc
          It.Next;
        It.Recurse; // Enter categories
        while It.Next do
        begin
          if (It.&Type = TJsonToken.StartObject) then
          begin
            WeaponFamily := StrToWeaponType(It.Key);
            It.Recurse;
            ModelTalentIDs := [];
            while It.Next do
            begin
              // Model-level talent_id (to be inherited by all weapons in this model)
              if (It.Key = 'talent_id') and (It.&Type = TJsonToken.StartArray)
              then
              begin
                SetLength(ModelTalentIDs, 0);
                It.Recurse;
                while It.Next do
                  ModelTalentIDs := ModelTalentIDs + [It.AsInteger];
                It.Return;
                Continue;
              end;

              // Each model (e.g., "ACR", "AK47", etc.)
              if (It.&Type = TJsonToken.StartArray) and (It.Key <> '') then
              begin
                ModelName := It.Key;
                It.Recurse;
                while It.Next do
                begin
                  if (It.&Type = TJsonToken.StartObject) then
                  begin
                    W := Default (TWeapon);
                    W.WeaponType := WeaponFamily;
                    W.SubCategory := ModelName;
                    // Initialize arrays/dicts
                    SetLength(W.TalentIDs, 0);
                    for CurrentSlot := Low(TModSlot) to High(TModSlot) do
                      W.CompatibleMods[CurrentSlot] := [];

                    // Inherit model-level talents by default
                    if Length(ModelTalentIDs) > 0 then
                      W.TalentIDs := Copy(ModelTalentIDs, 0,
                        Length(ModelTalentIDs));

                    It.Recurse;
                    while It.Next do
                    begin
                      if It.Key = 'name' then
                        W.Name := It.AsString
                      else if It.Key = 'rarity' then
                        W.Rarity := StrToRarity(It.AsString)
                      else if It.Key = 'stats_id' then
                        W.StatsID := It.AsInteger
                      else if It.Key = 'image_path' then
                        W.ImagePath := It.AsString
                      else if It.Key = 'uTalent_id' then
                        W.UniqueTalentID := It.AsInteger
                      else if It.Key = 'core_stats' then
                      begin
                        It.Recurse;
                        while It.Next do
                        begin
                          if It.Key = 'base_damage' then
                            W.Core.BaseDamage := It.AsDouble
                          else if It.Key = 'rpm' then
                            W.Core.RPM := It.AsInteger
                          else if It.Key = 'magazine_size' then
                            W.Core.MagazineSize := It.AsInteger
                          else if It.Key = 'headshot_damage' then
                            W.Core.HeadshotDamage := It.AsDouble;
                        end;
                        It.Return;
                      end
                      else if It.Key = 'weapon_handling' then
                      begin
                        It.Recurse;
                        while It.Next do
                        begin
                          if It.Key = 'accuracy' then
                            W.Handling.Accuracy := It.AsDouble
                          else if It.Key = 'stability' then
                            W.Handling.Stability := It.AsDouble
                          else if It.Key = 'reload_time' then
                            W.Handling.ReloadTime := It.AsDouble
                          else if It.Key = 'optimal_range' then
                            W.Handling.OptimalRange := It.AsDouble;
                        end;
                        It.Return;
                      end
                      else if It.Key = 'mods' then
                      begin
                        It.Recurse;
                        while It.Next do
                        begin
                          CurrentSlot := StrToModSlot(It.Key);
                          It.Recurse;
                          while It.Next do
                            W.CompatibleMods[CurrentSlot] :=
                              W.CompatibleMods[CurrentSlot] + [It.AsString];
                          It.Return;
                        end;
                        It.Return;
                      end
                      else if It.Key = 'talent_id' then
                      begin
                        // Weapon-level talents override model-level
                        SetLength(W.TalentIDs, 0);
                        It.Recurse;
                        while It.Next do
                          W.TalentIDs := W.TalentIDs + [It.AsInteger];
                        It.Return;
                      end;
                    end;
                    // Generate a simple ID if not set
                    if W.ID = 0 then
                      W.ID := FWeapons.Count + 1;
                    FWeapons.AddOrSetValue(W.ID, W);
                    It.Return;
                  end;
                end;
                It.Return;
              end;
            end;
            It.Return;
          end;
        end;
        It.Return;
      end;
  finally
    It.Free;
    Reader.Free;
    SR.Free;
  end;
end;

{ ─────────── 3/8  – weapon_stats.json ─────────── }

procedure TDataJsonIterator.LoadWeaponStats(const FileName: string);
var
  It: TJSONIterator;
  JR: TJsonTextReader;
  SR: TStringReader;
  WS: TWeaponStat;
  CurrAttr: TAttribute;
begin
  try
    SR := TStringReader.Create(TFile.ReadAllText(FileName, TEncoding.UTF8));
    // ShowMessage('LoadWeaponStats: Reading file: ' + FileName + '. Size: ' + IntToStr(Length(TFile.ReadAllText(FileName, TEncoding.UTF8))) + ' chars.');
  except
    on E: Exception do
    begin
      HandleParsingError('Error reading JSON file: ' + E.Message);
      Exit;
    end;
  end;

  JR := TJsonTextReader.Create(SR);
  It := TJSONIterator.Create(JR);
  try
    while It.Next do
    begin
      if (It.Key = 'weapon_stats') and (It.&Type = TJsonToken.StartArray) then
      begin
        // ShowMessage('Found "weapon_stats" array. Recursing into array...');
        It.Recurse; // Enter the "weapon_stats" array

        while It.Next do // Loop through each object in the "weapon_stats" array
        begin
          if It.&Type = TJsonToken.StartObject then
          begin
            // ShowMessage('Processing new weapon stat object from array...');
            WS := Default (TWeaponStat);
            SetLength(WS.CoreAttributes, 0);
            SetLength(WS.MinorAttributes, 0);

            It.Recurse; // Enter the weapon stat object
            while It.Next do // Loop through properties of this object
            begin
              if It.Key = 'id' then
                WS.ID := It.AsInteger
              else if It.Key = 'expertise_level' then
                WS.ExpertiseLevel := It.AsInteger
              else if It.Key = 'pve_pvp_difference' then
                WS.PvEPvPDifference := It.AsBoolean
              else if (It.Key = 'attributes') and
                (It.&Type = TJsonToken.StartObject) then
              begin
                // ShowMessage('  Found "attributes" object. Recursing...');
                It.Recurse; // Enter 'attributes' object
                while It.Next do // Iterate "core" and "minor"
                begin
                  if (It.Key = 'core') and (It.&Type = TJsonToken.StartArray)
                  then
                  begin
                    // ShowMessage('    Found "core" array. Recursing...');
                    It.Recurse; // Enter 'core' array
                    while It.Next do // Iterate each attribute object in 'core'
                    begin
                      if It.&Type = TJsonToken.StartObject then
                      begin
                        CurrAttr := Default (TAttribute);
                        It.Recurse; // Enter attribute object
                        while It.Next do
                        begin
                          if It.Key = 'type' then
                            CurrAttr.&Type := It.AsString
                          else if It.Key = 'value' then
                            CurrAttr.Value := It.AsDouble;
                        end;
                        WS.CoreAttributes := WS.CoreAttributes + [CurrAttr];
                        It.Return; // Exit attribute object
                      end;
                    end;
                    It.Return; // Exit 'core' array
                    // ShowMessage('    Exited "core" array. Core items: ' + IntToStr(Length(WS.CoreAttributes)));
                  end
                  else if (It.Key = 'minor') and
                    (It.&Type = TJsonToken.StartArray) then
                  begin
                    // ShowMessage('    Found "minor" array. Recursing...');
                    It.Recurse; // Enter 'minor' array
                    while It.Next do // Iterate each attribute object in 'minor'
                    begin
                      if It.&Type = TJsonToken.StartObject then
                      begin
                        CurrAttr := Default (TAttribute);
                        It.Recurse; // Enter attribute object
                        while It.Next do
                        begin
                          if It.Key = 'type' then
                            CurrAttr.&Type := It.AsString
                          else if It.Key = 'value' then
                            CurrAttr.Value := It.AsDouble;
                        end;
                        WS.MinorAttributes := WS.MinorAttributes + [CurrAttr];
                        It.Return; // Exit attribute object
                      end;
                    end;
                    It.Return; // Exit 'minor' array
                    // ShowMessage('    Exited "minor" array. Minor items: ' + IntToStr(Length(WS.MinorAttributes)));
                  end;
                end;
                It.Return; // Exit 'attributes' object
                // ShowMessage('  Exited "attributes" object.');
              end;
            end;

            if WS.ID <> 0 then
            begin
              // ShowMessage('LoadWeaponStats: Parsed WS.ID: ' + IntToStr(WS.ID) + ', CoreAtts: ' + IntToStr(Length(WS.CoreAttributes)) + ', MinorAtts: ' + IntToStr(Length(WS.MinorAttributes)));
              // if WS.ID = 1 then ShowMessage('LoadWeaponStats: Specifically parsed ID 1.');
              FWeaponStats.AddOrSetValue(WS.ID, WS);
              // ShowMessage('LoadWeaponStats: Added WS.ID: ' + IntToStr(WS.ID) + ' to FWeaponStats. Count now: ' + IntToStr(FWeaponStats.Count));
            end;
            // else ShowMessage('LoadWeaponStats: Warning - Parsed a weapon stat object with ID 0. Not adding.');
            It.Return; // Exit the weapon stat object
            // ShowMessage('Exited weapon stat object.');
          end;
        end;
        It.Return; // Exit "weapon_stats" array
        // ShowMessage('Exited "weapon_stats" array. Final FWeaponStats count: ' + IntToStr(FWeaponStats.Count));
        Break;
      end;
    end;
  finally
    It.Free;
    JR.Free;
    SR.Free;
  end;
end;

{ ─────────── 4/8  – weapon_mods.json ─────────── }

procedure TDataJsonIterator.LoadWeaponModsFromJson(const FileName: string);
var
  It: TJSONIterator;
  JR: TJsonTextReader;
  SR: TStringReader;
  M: TWeaponMod; // Will be initialized for each mod object

  // Helper to parse "bonus" or "drawback" objects into a TWeaponModEffect record
  procedure ReadEffectStructure(var EffectRecord: TWeaponModEffect;
    CurrentIterator: TJSONIterator);
  begin
    // Expects CurrentIterator to be at the StartObject of the effect structure
    CurrentIterator.Recurse; // Enter effect object (e.g., bonus or drawback)
    while CurrentIterator.Next do
    // Loop through properties of the effect object
    begin
      // Map JSON keys to TWeaponModEffect fields
      // Using SameText for case-insensitive key matching is a good idea
      if SameText(CurrentIterator.Key, 'accuracy') then
        EffectRecord.Accuracy := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'stability') then
        EffectRecord.Stability := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'reload_time') then
        EffectRecord.ReloadTime := CurrentIterator.AsDouble
        // Assuming JSON key is 'reload_time'
      else if SameText(CurrentIterator.Key, 'reload_speed') then
        EffectRecord.ReloadTime := CurrentIterator.AsDouble
        // Alias for ReloadTime
      else if SameText(CurrentIterator.Key, 'critical_hit_chance') then
        EffectRecord.CriticalHitChance := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'critical_hit_damage') then
        EffectRecord.CriticalHitDamage := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'headshot_damage') then
        EffectRecord.HeadshotDamage := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'weapon_damage') then
        EffectRecord.WeaponDamage := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'rate_of_fire') then
        EffectRecord.RateOfFire := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'optimal_range') then
        EffectRecord.OptimalRange := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'weapon_handling') then
        EffectRecord.WeaponHandling := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'extra_rounds') then
        EffectRecord.ExtraRounds := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'melee_damage') then
        EffectRecord.MeleeDamage := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'magazine_size') then
        EffectRecord.ExtraRounds := CurrentIterator.AsDouble;
      // Add any other fields from TWeaponModEffect that are present in your JSON
    end;
    CurrentIterator.Return; // Exit effect object
  end;

begin
  try
    SR := TStringReader.Create(TFile.ReadAllText(FileName, TEncoding.UTF8));
    // ShowMessage('LoadModsFromJson: Reading file: ' + FileName + '. Size: ' + IntToStr(Length(TFile.ReadAllText(FileName, TEncoding.UTF8))) + ' chars.');
  except
    on E: Exception do
    begin
      HandleParsingError('Error reading Mods JSON file: ' + E.Message);
      Exit;
    end;
  end;

  JR := TJsonTextReader.Create(SR);
  It := TJSONIterator.Create(JR);
  try
    while It.Next do // Iterate through the JSON tokens
    begin
      if (It.Key = 'mods') and (It.&Type = TJsonToken.StartArray) then
      begin
        // ShowMessage('Found "mods" array. Recursing into array...');
        It.Recurse; // Enter the "mods" array

        while It.Next do // Loop for each object within the "mods" array
        begin
          if It.&Type = TJsonToken.StartObject then
          begin
            // ShowMessage('  Processing new mod object from array...');
            M := Default (TWeaponMod);
            // Initialize a new TWeaponMod record for each mod
            M.Bonus := Default (TWeaponModEffect);
            // Explicitly initialize nested records
            M.Drawback := Default (TWeaponModEffect);

            It.Recurse; // Enter the mod object
            while It.Next do
            // Loop through properties of the current mod object
            begin
              if It.Key = 'id' then
                M.ID := It.AsInteger
              else if It.Key = 'slot' then
              begin
                M.slot := StrToModSlot(It.AsString);
                // ShowMessage('LoadModsFromJson - Mod ID ' + IntToStr(M.ID) + ': JSON slot string: "' + It.AsString + '", Mapped M.Slot to: ' + ModSlotToString(M.Slot)); // DEBUG
              end
              else if It.Key = 'type' then
                M.Type_ := It.AsString
              else if It.Key = 'name' then
                M.Name := It.AsString
              else if (It.Key = 'bonus') and (It.&Type = TJsonToken.StartObject)
              then
              begin
                // ShowMessage('      Found "bonus" object. Calling ReadEffectStructure...');
                ReadEffectStructure(M.Bonus, It);
              end
              else if (It.Key = 'drawback') and
                (It.&Type = TJsonToken.StartObject) then
              begin
                // ShowMessage('      Found "drawback" object. Calling ReadEffectStructure...');
                ReadEffectStructure(M.Drawback, It);
              end;
            end;

            if M.ID <> 0 then
            begin
              // ShowMessage('  LoadModsFromJson: Parsed Mod ID: ' + IntToStr(M.ID) + ', Name: ' + M.Name);
              FMods.AddOrSetValue(M.ID, M);
              // ShowMessage('  Added Mod ID: ' + IntToStr(M.ID) + ' to FMods. Dict Count: ' + IntToStr(FMods.Count));
            end;
            It.Return; // Exit the mod object
            // ShowMessage('  Exited mod object.');
          end;
        end;
        It.Return; // Exit "mods" array
        // ShowMessage('Exited "mods" array. Final FMods count: ' + IntToStr(FMods.Count));
        Break;
      end;
    end;

  finally
    It.Free;
    JR.Free;
    SR.Free;
  end;
end;

{ ─────────── 5/8  – weapon_talents.json ─────────── }
procedure TDataJsonIterator.LoadTalentsFromJson(const FileName: string);
var
  It: TJSONIterator;
  JR: TJsonTextReader;
  SR: TStringReader;
  T: TWeaponTalent;

  procedure ReadTalentEffectStructure(var EffectRecord: TWeaponModEffect;
    CurrentIterator: TJSONIterator);
  begin
    CurrentIterator.Recurse;
    // Enter effect object (e.g., "effects" or "drawback")
    while CurrentIterator.Next do
    begin
      // ShowMessage('  Effect Key: ' + CurrentIterator.Key + ', Value: ' + CurrentIterator.CurrentValue.ToString); // DEBUG
      if SameText(CurrentIterator.Key, 'accuracy') then
        EffectRecord.Accuracy := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'stability') then
        EffectRecord.Stability := CurrentIterator.AsDouble

        // ReloadTime in TWeaponModEffect: positive means faster (reduces time)
      else if SameText(CurrentIterator.Key, 'reload_speed_bonus') then
        EffectRecord.ReloadTime := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'reload_time') then
        EffectRecord.ReloadTime := CurrentIterator.AsDouble

      else if SameText(CurrentIterator.Key, 'critical_hit_chance') then
        EffectRecord.CriticalHitChance := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'critical_hit_damage') then
        EffectRecord.CriticalHitDamage := CurrentIterator.AsDouble

      else if SameText(CurrentIterator.Key, 'headshot_damage') then
        EffectRecord.HeadshotDamage := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'headshot_bonus_damage') then
        EffectRecord.HeadshotDamage := CurrentIterator.AsDouble // Alias

        // Consolidate various weapon damage keys
      else if SameText(CurrentIterator.Key, 'weapon_damage') then
        EffectRecord.WeaponDamage := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'weapon_damage_bonus') then
        EffectRecord.WeaponDamage := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'amplified_weapon_damage_bonus')
      then
        EffectRecord.WeaponDamage := CurrentIterator.AsDouble
        // Note: "amplified" often means multiplicative. TWeaponModEffect treats all WeaponDamage as additive to a pool.
        // This is a simplification for now. True amplified would need a separate field or handling in CalcEngine.

      else if SameText(CurrentIterator.Key, 'rate_of_fire') then
        EffectRecord.RateOfFire := CurrentIterator.AsDouble
        // Assuming this is absolute RoF change from talents, not %

      else if SameText(CurrentIterator.Key, 'optimal_range') then
        EffectRecord.OptimalRange := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'weapon_handling') then
        EffectRecord.WeaponHandling := CurrentIterator.AsDouble

      else if SameText(CurrentIterator.Key, 'extra_rounds') then
        EffectRecord.ExtraRounds := CurrentIterator.AsDouble
      else if SameText(CurrentIterator.Key, 'magazine_size') then
        EffectRecord.ExtraRounds := CurrentIterator.AsDouble
        // Simplification: treat "magazine_size" as flat extra rounds.
        // If it's a percentage, TWeaponModEffect needs a new field.
      else if SameText(CurrentIterator.Key, 'melee_damage') then
        EffectRecord.MeleeDamage := CurrentIterator.AsDouble

        // Keys from your JSON that DO NOT map directly to TWeaponModEffect fields:
        // 'armor' (from Brazen)
        // 'max_stacks' (from Fast Hands)
        // 'skill_tier_increase', 'overcharge' (from Future Perfect)
        // 'skill_damage' (from In Sync - TWeaponModEffect has no skill damage field)
        // 'ammo_return_chance' (from Lucky Shot)
        // 'rate_of_fire_top', 'weapon_damage_top', 'rate_of_fire_bottom', 'weapon_damage_bottom' (from Measured)
        // ... and many others, especially for exotic talents.
        // These are ignored by this parser for direct stat application via TWeaponModEffect.
        // Their primary effect is conveyed by the talent's description.
          ; // Add more 'else if' for other direct stat mappings if they exist in JSON and TWeaponModEffect
    end;
    CurrentIterator.Return; // Exit effect object
  end;

begin
  try
    SR := TStringReader.Create(TFile.ReadAllText(FileName, TEncoding.UTF8));
    // ShowMessage('LoadTalentsFromJson: Reading file: ' + FileName + '. Size: ' + IntToStr(Length(TFile.ReadAllText(FileName, TEncoding.UTF8))) + ' chars.');
  except
    on E: Exception do
    begin
      HandleParsingError('Error reading Talents JSON file: ' + E.Message);
      Exit;
    end;
  end;

  JR := TJsonTextReader.Create(SR);
  It := TJSONIterator.Create(JR);
  try
    while It.Next do
    begin
      // Find the start of the "talents" array
      if (It.Key = 'talents') and (It.&Type = TJsonToken.StartArray) then
      begin
        // ShowMessage('Found "talents" array. Recursing into array...');
        It.Recurse; // Enter the "talents" array

        while It.Next do // Loop for each object within the "talents" array
        begin
          if It.&Type = TJsonToken.StartObject then
          begin
            // ShowMessage('  Processing new talent object from array...');
            T := Default (TWeaponTalent);
            // Initialize a new TWeaponTalent record

            It.Recurse; // Enter the talent object
            while It.Next do
            // Loop through properties of the current talent object
            begin
              // ShowMessage('    Talent Prop: Key=' + It.Key + ' Value=' + It.CurrentValue.ToString + ' Type=' + System.TypInfo.GetEnumName(TypeInfo(TJsonToken), Ord(It.&Type)));
              if It.Key = 'id' then
                T.ID := It.AsInteger
              else if It.Key = 'name' then
                T.Name := It.AsString
              else if It.Key = 'description' then
                T.Description := It.AsString
                // Type, Specialization, PvEPvPDifference are not in TWeaponTalent record in Game.Types.pas
                // else if It.Key = 'type' then T.TalentTypeStr := It.AsString // Example if you add it
              else if (It.Key = 'effects') and
                (It.&Type = TJsonToken.StartObject) then // JSON uses "effects"
              begin
                // ShowMessage('      Found "effects" object. Calling ReadTalentEffectStructure...');
                ReadTalentEffectStructure(T.Effect, It);
                // T.Effect is TWeaponModEffect
              end
              else if (It.Key = 'drawback') and
                (It.&Type = TJsonToken.StartObject) then
              // Assuming "drawback" exists and is similar
              begin
                // ShowMessage('      Found "drawback" object. Calling ReadTalentEffectStructure...');
                ReadTalentEffectStructure(T.Drawback, It);
                // T.Drawback is TWeaponModEffect
              end;
            end; // End loop for properties of a talent object

            if T.ID <> 0 then
            begin
              // ShowMessage('  LoadTalentsFromJson: Parsed Talent ID: ' + IntToStr(T.ID) + ', Name: ' + T.Name);
              FTalents.AddOrSetValue(T.ID, T);
              // ShowMessage('  Added Talent ID: ' + IntToStr(T.ID) + ' to FTalents. Dict Count: ' + IntToStr(FTalents.Count));
            end
            else
            begin
              ShowMessage
                ('  LoadTalentsFromJson: Warning - Parsed a talent with ID 0. Not adding.');
            end;
            It.Return; // Exit the talent object
          end; // End if TJsonToken.StartObject (for item in talents array)
        end; // End while loop for items in "talents" array
        It.Return; // Exit "talents" array
        Break; // Assuming "talents" is the main/only top-level key
      end; // End if found "talents" StartArray
    end; // End main while It.Next
  finally
    It.Free;
    JR.Free;
    SR.Free;
  end;
end;

procedure TDataJsonIterator.LoadGearTalentsFromJson(const FileName: string);
var
  It: TJSONIterator;
  JR: TJsonTextReader;
  SR: TStringReader;
  SlotName, CategoryName, TopLevelKey: string;
  SlotDict: TDictionary<string, TList<string>>;
  TalentList: TList<string>;
  TalentDef: TGearTalentDefinition;
begin
  if not FileExists(FileName) then
  begin
    WriteLog(['Gear Talents file not found: ' + FileName]);
    Exit;
  end;

  try
    SR := TStringReader.Create(TFile.ReadAllText(FileName, TEncoding.UTF8));
    JR := TJsonTextReader.Create(SR);
    It := TJSONIterator.Create(JR);

    // Structure: { "talents": { "brandSets": ..., "named": ..., "exotic": ..., "gearSets": ... } }
    if It.Next and (It.Key = 'talents') and (It.&Type = TJsonToken.StartObject) then
    begin
      It.Recurse; // Enter "talents"

      while It.Next do // Iterate TopLevel keys (brandSets, named, exotic, gearSets)
      begin
        if It.&Type = TJsonToken.StartObject then
        begin
          TopLevelKey := It.Key; // e.g. "brandSets"
          It.Recurse; // Enter "brandSets" etc.

          while It.Next do // Iterate Slots (Vest, Backpack)
          begin
            SlotName := It.Key;

            // Case 1: Slot value is an Object (e.g., brandSets -> Vest: { "weapon_dps": [...] })
            if It.&Type = TJsonToken.StartObject then
            begin
              // Only modify FGearTalents (UI list) if we are processing "brandSets"
              if SameText(TopLevelKey, 'brandSets') then
              begin
                if not FGearTalents.TryGetValue(SlotName, SlotDict) then
                begin
                  SlotDict := TDictionary<string, TList<string>>.Create;
                  FGearTalents.Add(SlotName, SlotDict);
                end;

                It.Recurse; // Enter Vest
                while It.Next do // Iterate Categories (weapon_dps, etc)
                begin
                  if It.&Type = TJsonToken.StartArray then
                  begin
                    CategoryName := It.Key; // e.g. "weapon_dps"

                    if not SlotDict.TryGetValue(CategoryName, TalentList) then
                    begin
                      TalentList := TList<string>.Create;
                      SlotDict.Add(CategoryName, TalentList);
                    end;

                    It.Recurse; // Enter Array
                    while It.Next do // Iterate Talent Objects
                    begin
                      if It.&Type = TJsonToken.StartObject then
                      begin
                        TalentDef := Default(TGearTalentDefinition);
                        It.Recurse;
                        while It.Next do
                        begin
                          if It.Key = 'name' then
                            TalentDef.Name := It.AsString.Trim
                          else if It.Key = 'description' then
                            TalentDef.Description := It.AsString
                          else if It.Key = 'icon' then
                            TalentDef.IconFilename := TPath.GetFileNameWithoutExtension(It.AsString).Trim.ToLower;
                        end;
                        It.Return;

                        if TalentDef.Name <> '' then
                        begin
                          TalentList.Add(TalentDef.Name);
                          FGearTalentDefinitions.AddOrSetValue(TalentDef.Name, TalentDef);
                        end;
                      end;
                    end;
                    It.Return; // Exit Array
                  end;
                end;
                It.Return; // Exit Vest
              end
              else
              begin
//                // If it's StartObject but NOT brandSets (unexpected for provided JSON, but safe fallback)
//                It.Recurse;
//                while It.Next do; // Skip content
//                It.Return;

                // Support other top-level groups (gearSets / named / exotic) that also use:
                //   Slot -> Category -> [ {name, description, icon, ...}, ... ]
                It.Recurse; // enter Slot object
                while It.Next do
                begin
                  if It.&Type = TJsonToken.StartArray then
                  begin
                    // Parse the array of talent objects
                    It.Recurse;
                    while It.Next do
                    begin
                      if It.&Type = TJsonToken.StartObject then
                      begin
                        TalentDef := Default(TGearTalentDefinition);
                        It.Recurse;
                        while It.Next do
                        begin
                          if It.Key = 'name' then
                            TalentDef.Name := It.AsString.Trim
                          else if It.Key = 'description' then
                            TalentDef.Description := It.AsString
                          else if It.Key = 'icon' then
                            TalentDef.IconFilename := TPath.GetFileNameWithoutExtension(It.AsString).Trim.ToLower;
                        end;
                        It.Return;

                        if TalentDef.Name <> '' then
                          FGearTalentDefinitions.AddOrSetValue(TalentDef.Name, TalentDef);
                      end;
                    end;
                    It.Return; // exit array
                  end;
                end;
                It.Return; // exit slot object
              end;
            end
            // Case 2: Slot value is an Array (e.g., named -> Vest: [ {...}, ... ])
            else if It.&Type = TJsonToken.StartArray then
            begin
              // Ensure we have a dictionary for this slot (Vest/Backpack)
              if not FGearTalents.TryGetValue(SlotName, SlotDict) then
              begin
                SlotDict := TDictionary<string, TList<string>>.Create;
                FGearTalents.Add(SlotName, SlotDict);
              end;

              // Ensure we have a list for this category (named, exotic, etc.)
              // Using TopLevelKey (e.g., "named", "exotic") as the category name
              if not SlotDict.TryGetValue(TopLevelKey, TalentList) then
              begin
                TalentList := TList<string>.Create;
                SlotDict.Add(TopLevelKey, TalentList);
              end;

              It.Recurse; // Enter Array
              while It.Next do // Iterate Talent Objects
              begin
                if It.&Type = TJsonToken.StartObject then
                begin
                  TalentDef := Default(TGearTalentDefinition);
                  It.Recurse;
                  while It.Next do
                  begin
                    if It.Key = 'name' then
                      TalentDef.Name := It.AsString.Trim
                    else if It.Key = 'description' then
                      TalentDef.Description := It.AsString
                    else if It.Key = 'icon' then
                      TalentDef.IconFilename := TPath.GetFileNameWithoutExtension(It.AsString).Trim.ToLower;
                  end;
                  It.Return;

                  if TalentDef.Name <> '' then
                  begin
                    TalentList.Add(TalentDef.Name);
                    FGearTalentDefinitions.AddOrSetValue(TalentDef.Name, TalentDef);
                  end;
                end;
              end;
              It.Return; // Exit Array
            end;
          end;
          It.Return; // Exit "brandSets" etc.
        end;
      end;
      It.Return; // Exit "talents"
    end;
  finally
    It.Free;
    JR.Free;
    SR.Free;
  end;
end;

{ ─────────── 6/8  – gear_mods.json ─────────── }
procedure TDataJsonIterator.LoadGearModsFromJson(const FileName: string);
var
  LSR: TStringReader;
  JR: TJsonTextReader;
  It: TJSONIterator;
  GM: TGearModDefinition;
  LJsonText: string;
begin
  LSR := nil;
  JR := nil;
  It := nil; // Initialize for finally block
  try
    try
      LJsonText := TFile.ReadAllText(FileName, TEncoding.UTF8);
      if LJsonText.IsEmpty then
      begin
        HandleParsingError('Gear Mods JSON file is empty: ' + FileName);
        Exit;
      end;

      LSR := TStringReader.Create(LJsonText);
      JR := TJsonTextReader.Create(LSR);
      It := TJSONIterator.Create(JR);

      FGearModsData.Clear;
      // It.Recurse; // Not strictly needed if the loop handles object directly
      // but good for matching StartArray with EndArray

      while It.Next do // This will now iterate over items within the array
      begin
        if It.&Type = TJsonToken.EndArray then
        // Stop if we hit the end of the array
          Break;

        if It.&Type = TJsonToken.StartObject then
        begin
          GM := Default (TGearModDefinition);
          It.Recurse; // enter the object
          while It.Next do
          begin
            if SameText(It.Key, 'ID') then
              GM.ID := It.AsInteger
            else if SameText(It.Key, 'Name') then
              GM.Name := It.AsString
            else if SameText(It.Key, 'ModType') then
              GM.ModType := StrToGearModType(It.AsString)
            else if SameText(It.Key, 'AttributeType') then
              GM.AttributeType := StrToGearModEffectType(It.AsString)
            else if SameText(It.Key, 'AttributeValue') then
              GM.AttributeValue := It.AsDouble;
          end;
          It.Return;
          // leave the object (corresponds to It.Recurse for the object)

          if (GM.ID <> 0) and (GM.Name <> '') then
            FGearModsData.AddOrSetValue(GM.ID, GM)
          else
            WriteLog(['Skipped invalid gear-mod. ID=' + GM.ID.ToString +
              ', Name=' + GM.Name]);
        end;
        // Else: item in array is not an object, could log/skip
      end;
      // No explicit It.Return here if we didn't Recurse into the array initially for the loop,
      // or if the loop terminates on EndArray. If we did Recurse for the array, an It.Return would be needed.
      // The iterator should naturally end after processing all tokens within the StartArray/EndArray scope.

    finally
      FreeAndNil(It);
      FreeAndNil(JR);
      FreeAndNil(LSR);
    end;
  except
    on E: Exception do
    begin
      HandleParsingError('Exception in LoadGearModsFromJson: ' + E.Message);
      if Assigned(It) then
        FreeAndNil(It);
      if Assigned(JR) then
        FreeAndNil(JR);
      if Assigned(LSR) then
        FreeAndNil(LSR);
    end;
  end;
end;

{ ─────────── 7/8  – brands.json (All Piece Sets) ─────────── }
procedure TDataJsonIterator.LoadGearPieceSetFromJson(const FileName: string);
var
  Reader: TJsonTextReader;
  It: TJSONIterator;
  SR: TStringReader;
  PS: TPieceSet;
  SB: TSetBonus;
  Part: TPart;
  WpnFam: TWeaponFamily;
  LCurrentCoreDef: TCoreAttributeDefinition;
  LBonusAttrID: string; // Renamed to avoid confusion
  LBonusValue: Variant;
  CurCat: string;
begin
  FAllPieceSetDefinitions.Clear;

  SR := TStringReader.Create(TFile.ReadAllText(FileName, TEncoding.UTF8));
  Reader := TJsonTextReader.Create(SR);
  It := TJSONIterator.Create(Reader);
  try
    while It.Next do
    begin
      { ──────────────── top-level – skip "coreAttributes" ──────────────── }
      if SameText(It.Key, 'coreAttributes') then
      begin
        if It.&Type = TJsonToken.StartArray then
        begin
          ParseCoreAttributes(It);
        end;
        Continue;
      end
      else if SameText(It.Key, 'fixedMinorAttributes') then
      begin
        if It.&Type = TJsonToken.StartArray then
          ParseFixedMinorAttributes(It);

        Continue;
      end;

      { we are now on the *value* token of a property whose key is brandSets / gearSets / namedSets / exoticSets … }
      if It.&Type <> TJsonToken.StartArray then
        Continue; // defensive

      CurCat := It.Key; // store the category

      // Use the centralized ParseSetCategory which uses ParseSetObject -> ParseParts
      // This ensures consistent parsing including 'talent', 'fixedMinorAttributes', etc.
      ParseSetCategory(It, CurCat);
    end; { while It.Next }
  finally
    It.Free;
    Reader.Free;
    SR.Free;
  end;

  OutputDebugString(PChar('Loaded piece sets: ' +
    FAllPieceSetDefinitions.Count.ToString));
end;

// The Asynchronous loader remains the same as it was already correct.
procedure TDataJsonIterator.LoadGearPieceSetAsync(const AFileName: string;
  const APieceSetCallback: TProcessPieceSetCallback;
  const ACoreAttrCallback: TProcessCoreAttrCallback);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      LSR: TStringReader;
      Reader: TJsonTextReader;
      LIterator: TJSONIterator;
    begin
      try
        LSR := TStringReader.Create(TFile.ReadAllText(AFileName,
          TEncoding.UTF8));
        Reader := TJsonTextReader.Create(LSR);
        LIterator := TJSONIterator.Create(Reader);
      except
        on E: Exception do
        begin
          TThread.Queue(nil,
            procedure
            begin
              HandleParsingError(Format('Async load failed: %s', [E.Message]));
            end);
          Exit;
        end;
      end;

      try
        if LIterator.Next and (LIterator.&Type = TJsonToken.StartObject) then
        begin
          LIterator.Recurse;
          while LIterator.Next and (LIterator.&Type <> TJsonToken.EndObject) do
          begin
            if SameText(LIterator.Key, 'coreAttributes') then
            begin
              // --- This block now parses AND queues the callback ---
              if LIterator.&Type = TJsonToken.StartArray then
              begin
                LIterator.Recurse;
                while LIterator.Next and
                  (LIterator.&Type <> TJsonToken.EndArray) do
                begin
                  if LIterator.&Type = TJsonToken.StartObject then
                  begin
                    // Parse the object into a record directly on this thread
                    var
                    LCoreDef := ParseCoreAttributeObject(LIterator);
                    // New helper
                    // Queue the callback with the RECORD, not a JSON object
                    TThread.Queue(nil,
                      procedure
                      begin
                        ACoreAttrCallback(LCoreDef);
                      end);
                  end;
                end;
                LIterator.Return;
              end;
            end
            else if SameText(LIterator.Key, 'fixedMinorAttributes') then
            begin
              if LIterator.&Type = TJsonToken.StartArray then
                ParseFixedMinorAttributes(LIterator)
              else
                WriteLog(['Warning: \"fixedMinorAttributes\" must be an array. Ignored.']);
            end
            else if LIterator.&Type = TJsonToken.StartArray then
            begin
              // --- This block now parses AND queues the callback ---
              var
              LCategoryKey := LIterator.Key;
              LIterator.Recurse;
              while LIterator.Next and
                (LIterator.&Type <> TJsonToken.EndArray) do
              begin
                if LIterator.&Type = TJsonToken.StartObject then
                begin
                  // Parse the object into a record directly on this thread
                  var
                  LSet := ParseSetObject(LIterator,
                    StrToSetType_Parser(LCategoryKey));
                  // Queue the callback with the RECORD, not a JSON object
                  TThread.Queue(nil,
                    procedure
                    begin
                      APieceSetCallback(LSet);
                    end);
                end;
              end;
              LIterator.Return;
            end;
          end;
          LIterator.Return;
        end;
      finally
        LIterator.Free;
        LSR.Free;
      end;
    end).Start;
end;

{ ─────────── 6/6  – skills.json (All Variant) ─────────── }
procedure TDataJsonIterator.LoadSkillsFromJson(const FileName: string);
var
  RawText: string;
  SR: TStringReader;
  Reader: TJsonTextReader;
  It: TJSONIterator;

  SkillRec: TSkillData;
  VarRec: TSkillVariant;
  TierRec: TSkillEffectTier;
  EffRec: TSkillEffectProperty;

  // --- helpers ---------------------------------------------------------------//
  function StrToSkillCategory(const S: string): TSkillCategory;
  var
    L: string;
  begin
    // normalise once: lower-case and strip leading “sc”
    L := LowerCase(S.Trim);
    if L.StartsWith('sc') then
      L := L.Substring(2); // "scOffensive" → "offensive"

    if (L = 'offensive') or (L = 'damage') or (L = 'dps') then
      Exit(scOffensive);
    if (L = 'defensive') or (L = 'tank') then
      Exit(scDefensive);
    if (L = 'crowdcontrol') or (L = 'cc') then
      Exit(scCrowdControl);
    if (L = 'healing') or (L = 'heal') then
      Exit(scHealing);
    if L = 'support' then
      Exit(scSupport);

    // unknown → default
    Result := scSupport;
  end;

  procedure AddCategory(const S: string; var AArr: TArray<TSkillCategory>);
  var
    C: TSkillCategory;
  begin
    C := StrToSkillCategory(S);
    // avoid duplicates
    for var Existing in AArr do
      if Existing = C then
        Exit;
    AArr := AArr + [C];
  end;

  procedure ResetSkill(out S: TSkillData);
  begin
    S := Default (TSkillData);
    SetLength(S.Variants, 0);
  end;

  procedure ResetVariant(out V: TSkillVariant);
  begin
    V := Default (TSkillVariant);
    SetLength(V.Categories, 0);
    SetLength(V.EffectsByTier, 0);
  end;

  procedure ResetTier(out T: TSkillEffectTier);
  begin
    T := Default (TSkillEffectTier);
    SetLength(T.Effects, 0);
  end;

  procedure ResetEff(out E: TSkillEffectProperty);
  begin
    E := Default (TSkillEffectProperty);
  end;

begin
  FSkills.Clear;
  // --- load file text -------------------------------------------------------//
  try
    RawText := TFile.ReadAllText(FileName, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      HandleParsingError('LoadSkillsFromJson: cannot read "' + FileName + '": '
        + E.Message);
      Exit;
    end;
  end;

  SR := TStringReader.Create(RawText);
  Reader := TJsonTextReader.Create(SR);
  It := TJSONIterator.Create(Reader);
  try
    // Top level: array of skill objects
    while It.Next do
    begin
      if It.&Type = TJsonToken.StartArray then
      begin
        It.Recurse;
        Continue;
      end
      else if SameText(It.Key, 'fixedMinorAttributes') then
      begin
        if It.&Type = TJsonToken.StartArray then
          ParseFixedMinorAttributes(It)
        else
          WriteLog(['Warning: \"fixedMinorAttributes\" must be an array. Ignored.']);
        Continue;
      end;

      if It.&Type = TJsonToken.StartObject then
      begin
        ResetSkill(SkillRec);

        // ---- enter skill object ------------------------------------------//
        It.Recurse;
        while It.Next and (It.&Type <> TJsonToken.EndObject) do
        begin
          if It.Key = 'skillId' then
            SkillRec.SkillID := It.AsString
          else if It.Key = 'skillName' then
            SkillRec.SkillName := It.AsString
          else if It.Key = 'imagePath' then
            SkillRec.ImagePath := It.AsString
          else if It.Key = 'description' then
            SkillRec.Description := It.AsString
          else if It.Key = 'skillType' then
            SkillRec.SkillType := It.AsString

            // ----- variants --------------------------------------------------//
          else if (It.Key = 'variants') and (It.&Type = TJsonToken.StartArray)
          then
          begin
            It.Recurse;
            while It.Next and (It.&Type <> TJsonToken.EndArray) do
            begin
              if It.&Type <> TJsonToken.StartObject then
                Continue;

              ResetVariant(VarRec);

              // inside variant object
              It.Recurse;
              while It.Next and (It.&Type <> TJsonToken.EndObject) do
              begin
                if It.Key = 'variantName' then
                  VarRec.VariantName := It.AsString
                else if It.Key = 'description' then
                  VarRec.Description := It.AsString
                else if It.Key = 'v_imagePath' then
                  VarRec.V_ImagePath := It.AsString
                else if It.Key = 'baseCooldownSeconds' then
                  VarRec.BaseCooldownSeconds := It.AsDouble

                  // categories[]
                else if (It.Key = 'categories') and
                  (It.&Type = TJsonToken.StartArray) then
                begin
                  It.Recurse;
                  while It.Next and (It.&Type <> TJsonToken.EndArray) do
                    if It.&Type in [TJsonToken.String, TJsonToken.PropertyName]
                    then
                      AddCategory(It.AsString, VarRec.Categories);
                  It.Return;
                end

                // effectsByTier[]
                else if (It.Key = 'effectsByTier') and
                  (It.&Type = TJsonToken.StartArray) then
                begin
                  It.Recurse;
                  while It.Next and (It.&Type <> TJsonToken.EndArray) do
                  begin
                    if It.&Type <> TJsonToken.StartObject then
                      Continue;

                    ResetTier(TierRec);

                    // inside tier object
                    It.Recurse;
                    while It.Next and (It.&Type <> TJsonToken.EndObject) do
                    begin
                      if It.Key = 'tier' then
                        TierRec.Tier := It.AsInteger
                      else if (It.Key = 'effects') and
                        (It.&Type = TJsonToken.StartArray) then
                      begin
                        It.Recurse;
                        while It.Next and (It.&Type <> TJsonToken.EndArray) do
                        begin
                          if It.&Type <> TJsonToken.StartObject then
                            Continue;

                          ResetEff(EffRec);

                          // inside effect object
                          It.Recurse;
                          while It.Next and
                            (It.&Type <> TJsonToken.EndObject) do
                          begin
                            if It.Key = 'name' then
                              EffRec.Name := It.AsString
                            else if It.Key = 'value' then
                              EffRec.Value := It.AsDouble;
                          end;
                          It.Return; // effect obj

                          TierRec.Effects := TierRec.Effects + [EffRec];
                        end;
                        It.Return; // effects array
                      end;
                    end;
                    It.Return; // tier obj

                    VarRec.EffectsByTier := VarRec.EffectsByTier + [TierRec];
                  end;
                  It.Return; // effectsByTier array
                end;
              end;
              It.Return; // variant object

              SkillRec.Variants := SkillRec.Variants + [VarRec];
            end;
            It.Return; // variants array
          end;
        end;
        It.Return; // skill object

        // Fallback: ensure an ID
        if SkillRec.SkillID = '' then
          SkillRec.SkillID := SkillRec.SkillName.Replace(' ', '_',
            [rfReplaceAll]);

        FSkills.AddOrSetValue(SkillRec.SkillID, SkillRec);
      end; // skill object
    end; // while
  finally
    It.Free;
    Reader.Free;
    SR.Free;
  end;
end;

{ ─────────── 8/8  – Player.json ─────────── }
procedure TDataJsonIterator.LoadPlayerFromJson(const FileName: string);
begin
  if not FileExists(FileName) then
  begin
    HandleParsingError('Player JSON file not found: ' + FileName);
    Exit;
  end;

  try
    FPlayer.LoadFromJSON(FileName);
  except
    on E: Exception do
    begin
      HandleParsingError('Exception in LoadPlayerFromJson: ' + E.Message);
    end;
  end;
end;

{ 🔸🔸🔸  Validation croisée  🔸🔸🔸 }

procedure TDataJsonIterator.ValidateLinks(out ErrorList: TArray<string>);
var
  E: TArray<string>;
  W: TWeapon;
  slot: TModSlot;
  M: TWeaponMod;
  Found: Boolean;
  I, J, K, L: Integer;
  FWeaponsValues: TArray<TWeapon>;
  Tid: Integer;
  ModTypeKey: string;
  FModsValues: TArray<TWeaponMod>;
begin
  SetLength(E, 0);
  // -- Weapon → Stats --
  FWeaponsValues := FWeapons.Values.ToArray;
  for I := 0 to High(FWeaponsValues) do
  begin
    W := FWeaponsValues[I];
    if not FWeaponStats.ContainsKey(W.StatsID) then
      E := E + [Format('Weapon %s: missing stats ID %d', [W.Name, W.StatsID])];
  end;

  // -- Weapon → Talent(s) --
  for I := 0 to High(FWeaponsValues) do
  begin
    W := FWeaponsValues[I];
    if (W.UniqueTalentID <> 0) and (not FTalents.ContainsKey(W.UniqueTalentID))
    then
      E := E + [Format('Weapon %s: missing unique talent %d',
        [W.Name, W.UniqueTalentID])];
    for J := 0 to High(W.TalentIDs) do
    begin
      Tid := W.TalentIDs[J];
      if not FTalents.ContainsKey(Tid) then
        E := E + [Format('Weapon %s: missing talent %d', [W.Name, Tid])];
    end;
  end;

  // -- Mods compatibles existants --
  FModsValues := FMods.Values.ToArray;
  for I := 0 to High(FWeaponsValues) do
  begin
    W := FWeaponsValues[I];
    for slot := Low(TModSlot) to High(TModSlot) do
      for K := 0 to High(W.CompatibleMods[slot]) do
      begin
        ModTypeKey := W.CompatibleMods[slot][K];
        Found := False;
        for L := 0 to High(FModsValues) do
        begin
          M := FModsValues[L];
          if (M.slot = slot) and SameText(M.Type_, ModTypeKey) then
          begin
            Found := True;
            Break;
          end;
        end;

        if not Found then
          E := E + [Format('Weapon %s: no mod of type "%s" for slot %s',
            [W.Name, ModTypeKey, GetEnumName(TypeInfo(TModSlot), Ord(slot))])];
      end;
  end;

  // -- Gear Piece Definitions -> Fixed Minor Attributes --
  var FAllPieceSetDefinitionsValues := FAllPieceSetDefinitions.Values.ToArray;
  var PS: TPieceSet;
  var Part: TPart;
  var FixedID: string;
  for I := 0 to High(FAllPieceSetDefinitionsValues) do
  begin
    PS := FAllPieceSetDefinitionsValues[I];
    for J := 0 to High(PS.Parts) do
    begin
      Part := PS.Parts[J];
      for K := 0 to High(Part.FixedMinorAttributeIDs) do
      begin
        FixedID := Part.FixedMinorAttributeIDs[K];
        if not FFixedMinorAttributeDefinitions.ContainsKey(FixedID) then
          E := E + [Format('PieceSet "%s" Part "%s": missing fixed minor attribute definition "%s"',
            [PS.Name, Part.Name, FixedID])];
      end;
    end;
  end;

  ErrorList := E;
end;

function TDataJsonIterator.FindGearPiece(const PieceName: string; out Piece: TGearPiece): Boolean;
var
  InitialPieceSet: TPieceSet;
  BrandPieceSet: TPieceSet;
  Part: TPart;
  Found: Boolean;
  ParentBrandName: string;

begin
  Result := False;
  Found := False;
  ParentBrandName := '';

  // Directly access the class's own dictionary
  if not Assigned(FAllPieceSetDefinitions) then
    Exit;

  // Pass 1: Find the item's definition to get its properties and identify its parent brand if it's a named item.
  var FAllPieceSetDefinitionsValues := FAllPieceSetDefinitions.Values.ToArray;
  for var I := 0 to High(FAllPieceSetDefinitionsValues) do
  begin
    InitialPieceSet := FAllPieceSetDefinitionsValues[I];
    for var J := 0 to High(InitialPieceSet.Parts) do
    begin
      Part := InitialPieceSet.Parts[J];
      if SameText(Part.Name, PieceName) then
      begin
        // We found the piece. Construct the base record.
        Piece := Default(TGearPiece);
        Piece.Name      := Part.Name;
        Piece.ItemType  := Part.GearSlot;

        Piece.CoreAttribute := Default(TCoreAttribute);
        Piece.CoreAttribute.ID := Part.CoreAttributeID;
        Piece.CoreAttribute.AttrType := CoreAttrIDToEnum(Part.CoreAttributeID);
        Piece.MinorAttributeSlotCount := Part.MinorAttributeSlotCount;

        if Length(Part.FixedMinorAttributeIDs) > 0 then
        begin
          SetLength(Piece.FixedMinorAttributes, 0);
          for var K := 0 to High(Part.FixedMinorAttributeIDs) do
          begin
            var FixedID := Part.FixedMinorAttributeIDs[K];
            var Def: TFixedMinorAttributeDefinition;
            if FFixedMinorAttributeDefinitions.TryGetValue(FixedID, Def) then
            begin
              var Len := Length(Piece.FixedMinorAttributes);
              SetLength(Piece.FixedMinorAttributes, Len + 1);
              Piece.FixedMinorAttributes[Len] := Def;
            end
            else
              WriteLog([Format('Warning: Fixed minor attribute "%s" referenced by %s is not defined.', [FixedID, Part.Name])]);
          end;
        end;

        Piece.SetType   := InitialPieceSet.SetType; // This tells us if it's named, brand, gearset, etc.

        // If it's a named item, the InitialPieceSet.Name is the key to its parent brand.
        // If it's not a named item, its InitialPieceSet is the source of truth for bonuses.
      { if Piece.SetType = stNamedSet then
        begin
          ParentBrandName := InitialPieceSet.Name;
        end
        else
        begin
          // For non-named items, their containing set is the source of truth for bonuses.
          Piece.SetName   := InitialPieceSet.Name;
          Piece.Bonuses   := InitialPieceSet.Bonuses;
        end; }

        if Piece.SetType = stNamedSet then
        begin
          // Extract the underlying brand from "The Hollow Man (Yaahl Gear)"
          ParentBrandName := CanonicalBrandName(InitialPieceSet.Name);
          Piece.SetName   := ParentBrandName; // so set name is always the brand
        end
        else
        begin
          // For pure brand / gear / exotic sets, the set that contains the part
          // is the source of truth.
          Piece.SetName := InitialPieceSet.Name;
          Piece.Bonuses := InitialPieceSet.Bonuses;
        end;

        Found := True;
        Break;
      end;
    end;
    if Found then Break;
  end;

  if not Found then
    Exit; // The piece doesn't exist in any set definition.

  // Pass 2: If it was a named item, look up the parent brand using the stored name to get the correct bonuses.
  if (Piece.SetType = stNamedSet) and (ParentBrandName <> '') then
  begin
    if FAllPieceSetDefinitions.TryGetValue(ParentBrandName, BrandPieceSet) then
    begin
      // We expect the parent to be a BrandSet.
      if BrandPieceSet.SetType = stBrandSet then
      begin
        Piece.SetName := BrandPieceSet.Name;   // Assign the parent brand's name.
        Piece.Bonuses := BrandPieceSet.Bonuses; // CRITICAL: Assign the parent brand's bonuses.
        Result := True;
        Exit;
      end;
    end;
    // If lookup fails, we fall through and will return based on the initial find.
  end;

  // If it wasn't a named item, or the parent lookup failed, we just return the result from Pass 1.
  Result := True;
end;

function TDataJsonIterator.FindFullGearPiece(const PieceName: string; out Piece: TGearPiece): Boolean;
var
  PieceSet: TPieceSet;
  Part: TPart;
begin
  Result := False;
  if not Assigned(DataJsonIterator) or
    not Assigned(DataJsonIterator.AllPieceSetDefinitions) then
    Exit;

  for PieceSet in DataJsonIterator.AllPieceSetDefinitions.Values do
    for Part in PieceSet.Parts do
      if SameText(Part.Name, PieceName) then
      begin
        // On RECONSTRUIT la pièce de base à partir des données du Part et du PieceSet
        Piece := Default (TGearPiece);
        Piece.Name := Part.Name; // Nom unique du gear
        Piece.SetName := PieceSet.Name; // Nom du set
        Piece.ItemType := Part.GearSlot; // Slot (masque, gants…)
        // Remplissage du CoreAttribute (depuis CoreAttributeID dans Part)
        Piece.CoreAttribute := Default (TCoreAttribute);
        Piece.CoreAttribute.ID := Part.CoreAttributeID;
        // Lien vers une définition plus détaillée si besoin
        Piece.CoreAttribute.AttrType := CoreAttrIDToEnum(Part.CoreAttributeID);
        // Les minor attributes, ModAttribute, Talent, Bonus sont "vides" ici, seront remplis lors du restore loadout
        Piece.MinorAttributeSlotCount := Part.MinorAttributeSlotCount;
        Piece.Talent := Part.Talent;
        Piece.SetType := PieceSet.SetType;
        Piece.Bonuses := PieceSet.Bonuses; // Tous les bonus du set
        // Piece.ImageIndex : = PieceSet.ImageIndex; // Si tu utilises ce champ

        Result := True;
        Exit;
      end;
end;

end.
