unit Game.Types;

interface

uses
  System.SysUtils, {System.Math,} System.Generics.Collections;

{ ────────────  basic enumerations ──────────── }

type
  TWeaponSlot = (wsNone, wsPrimary, wsSecondary, wsSideArm);
  /// weapon families used by TD-2
  TWeaponFamily = (wcUnknown, wcAR, wcSMG, wcLMG, wcSTG, wcMMR, wcRIFLE, wcPISTOL);

  /// in–game rarity colours
  TWeaponRarity = (wrHighEnd, wrNamed, wrExotic);

  TBonusType = (btAdditive, btMultiplicative, btAmplified);

  /// Specialization families used by TD-2
  TSpecialization = class
  private
    FInherentWeaponTypeBonuses: TDictionary<TWeaponFamily, Double>;
    FGeneralBonuses: TDictionary<string, Double>;
  public
    Name: string;
    // Base weapon type bonuses inherent to the specialization (e.g., Gunner inherently gets +15% LMG Dmg).
    // These are the potential bonuses the player can choose from via checkboxes.
    InherentWeaponTypeBonuses: TDictionary<TWeaponFamily, Double>;
    SignatureWeaponName: string; // e.g., "Minigun"
    UniqueSkillVariant: string;  // e.g., "Banshee Pulse"
    UniqueGrenadeType: string;
    IconKey: string;
    LogoKey: string;
    // UniqueWeaponAttachment: TWeaponMod; // Could be complex, maybe just a name/description for now
    UniqueWeaponAttachmentName: string;
    UniqueWeaponAttachmentBonusDesc: string; // Description of what the attachment does
    TacticalLinkDesc: string;
    ArmorKitTalentDesc: string;
    SignatureAmmoTalentDesc: string;
    PartySignatureAmmoTalentDesc: string;
    // Other general bonuses not tied to the selectable weapon type checkboxes (e.g., +10% Skill Haste for Technician)
    // These could be a TDictionary<string, Double> or specific fields if few and fixed.
    GeneralBonuses: TDictionary<string, Double>;

    constructor Create;
    destructor Destroy; override;
  end;

  /// four attachment rails recognised by the game
  TModSlot = (msOptics, msMagazine, msUnderBarrel, msMuzzle);

  { ────────────  helper records ──────────── }

  // --- Effets de mod et talent ---
  TWeaponModEffect = record
    Accuracy           : Double;
    Stability          : Double;
    ReloadTime         : Double;
    CriticalHitChance  : Double;
    CriticalHitDamage  : Double;
    HeadshotDamage     : Double;
    WeaponDamage       : Double;
    RateOfFire         : Double;
    OptimalRange       : Double;
    WeaponHandling     : Double;
    ExtraRounds        : Double;
    MeleeDamage        : Double;
    // ...
  end;

  // --- Core stats d'une arme ---
  TCoreStats = record
    BaseDamage      : Double;
    RPM             : Integer;
    MagazineSize    : Integer;
    HeadShotDamage  : Double;
  end;

  // --- Attributs (pour weapon_stats.json) ---
  TAttribute = record
    &Type   : string;
    Value   : Double;
  end;

  TWeaponStat = record
    ID                : Integer;
    ExpertiseLevel    : Integer;
    CoreAttributes    : TArray<TAttribute>;
    MinorAttributes   : TArray<TAttribute>;
    PvEPvPDifference  : Boolean;
  end;

  // --- Modèle de mod ---
  TWeaponMod = record
    ID        : Integer;
    Name      : string;
    Slot      : TModSlot;
    Type_     : string;            // ex: "Reflex", "ACOG", etc.
    Bonus     : TWeaponModEffect;
    Drawback  : TWeaponModEffect;
  end;

  // --- Modèle de talent ---
  TWeaponTalent = record
    ID          : Integer;
    Name        : string;
    Description : string;
    BonusType   : TBonusType;
    Effect      : TWeaponModEffect;
    Drawback    : TWeaponModEffect;
  end;

  // --- L'arme principale, avec compatibilité, mods, talents, stats ---
  TWeapon = record
    ID              : Integer;
    SubCategory     : string;
    Name            : string;
    WeaponType      : TWeaponFamily;
    Rarity          : TWeaponRarity;
    ImagePath       : string;

    // ---- Compatible mods pour chaque slot ----
    CompatibleMods  : array[TModSlot] of TArray<string>; // Types compatibles par slot

    // ---- Mods équipés (ID du mod sélectionné) ----
    EquippedMods    : array[TModSlot] of Integer; // 0 si rien d'équipé

    // ---- Talents ----
    TalentIDs       : TArray<Integer>; // Plusieurs pour HighEnd
    UniqueTalentID  : Integer;         // Unique pour Exotic/Nommée

    // ---- Statistiques ----
    Core       : TCoreStats;
    SelectedMinorAttributeType: string;
    Handling   : TWeaponModEffect; // WeaponHandling à plat (facilite l’accumulation d’effets)
    StatsID    : Integer; // Lien vers weapon_stats.json
    ChosenTalentID: Integer;
  end;

  { ────────────  Structures for Gear and Character-level Stats ──────────── }

  // Represents the type of mod slot on a gear piece.
  TGearModType = (gsmtOffensive, gsmtDefensive, gsmtUtility, gsmtGeneric); // Renamed from TGearModType for clarity

  // Represents a specific type of attribute/effect that a gear mod can provide.
  TGearModEffectType = (
    gmetUnknown, // Default/unset
    // Offensive
    gmetCriticalHitChance, gmetCriticalHitDamage, gmetHeadshotDamage,
    // Defensive
    gmetProtectionFromElites, gmetArmorOnKillFlat, gmetStatusEffectResistance,
    gmetPulseResistance, gmetIncomingRepairs, gmetExplosiveResistance,
    // Skill
    gmetSkillHaste, gmetSkillDuration, gmetRepairSkills,
    gmetSkillDamage, gmetSkillHealth
    // Add others as they become known, e.g., gmetExplosiveResistance from gear mods if it exists
  );

  // Definition of a single, selectable gear mod (as loaded from a potential gear_mods.json)
  TGearModDefinition = record
    ID: Integer; // Or string if names are unique identifiers
    Name: string;
    ModType: TGearModType;             // Offensive, Defensive, Utility
    AttributeType: TGearModEffectType; // What stat it provides
    AttributeValue: Double;            // The value of the stat (e.g., 6.0 for +6% CHC)
  end;

  // Accumulator for all equipped gear mods
  TGearModEffect = record // Renamed from TGearModEffectsAccumulator for brevity
    // Offensive Gear Mod Stats
    CriticalHitChance: Double;    // Sum of CHC from gear mods
    CriticalHitDamage: Double;    // Sum of CHD from gear mods
    HeadshotDamage: Double;       // Sum of HSD from gear mods
    // Defensive Gear Mod Stats
    ProtectionFromElites: Double;
    ArmorOnKill_Flat: Double;
    StatusEffectResistance: Double;
    PulseResistance: Double;
    IncomingRepairs: Double;
    // Skill Gear Mod Stats
    SkillHaste: Double;
    SkillDuration: Double;
    RepairSkills: Double;
    SkillDamage: Double;        // Added
    SkillHealth: Double;        // Added
    // Ensure all fields from TGearModAttributeType have a corresponding accumulator field here
  end;

   TGearTalentDefinition = record
    Name: string;
    Description: string;
    IconFilename: string;
    // Add other fields like Effect if you want to parse and store them
  end;

  { ────────────  Structures for SHD Watch Stats ──────────── }

  TWatchBonuses = record
    WeaponDamagePct: Double;
    CriticalHitChancePct: Double;
    CriticalHitDamagePct: Double;
    HeadshotDamagePct: Double;
    // Handling
    ReloadSpeedPct: Double;
    AccuracyPct: Double;
    StabilityPct: Double;
    AmmoPct: Double;
    // Defensive
    ArmorPct: Double; // Total Armor %
    HealthPct: Double; // Flat Health
    ExplosiveResistancePct: Double;
    HazardProtectionPct: Double;
    // Skill
    SkillDamagePct: Double;
    SkillHastePct: Double;
    SkillDurationPct: Double;
    RepairSkillsPct: Double;
    // Add other watch bonuses as needed
  end;

  TItemType = (itUnknown, itMask, itBackpack, itChest, itGloves, itHolster, itKneepads);

  TCoreAttributeType = (catWeaponDamage, catArmor, catSkillTier); // For Gear Core Attributes

  TMinorAttributeType = (madArmorRegen, madCriticalHitChance,
    madCriticalHitDamage, madExplosiveResistance, madIncomingRepairs, madHazardProtection,
    madHeadshotDamage, madHealth, madRepairSkills, madSkillDamage,
    madSkillHaste, madStatusEffects, madWeaponHandling);

  TMinorAttributeCat = (matOffensive, matDefensive, matUtility);

  // Catalog entry used by UI to list/filter attributes
  TAttributeCatalogEntry = record
    ID: string;
    DisplayName: string;
    Category: TMinorAttributeCat;
  end;

  TSetBonusType = (sbtWeaponDamage, sbtWeaponTypeDamage, sbtCoreAttribute, sbtAttribute, sbtSkillAttribute, sbtDefenseAttribute, sbtResistance, sbtGearSetBonus, sbtExoticBonus, sbtTalent, sbtSpecial, sbtMultiplicativeDamage);

  TSetType = (stBrandSet, stGearSet, stNamedSet, stExoticSet, stImprovised{, stUnknown});

  TCoreAttributeDefinition = record
    ID: string;       // e.g. "weaponDamage"
    TypeName: string; // e.g. "Weapon Damage"
    Value: Double;    // The MAX value, e.g., 15 for WD, 170000 for Armor
  end;

  TFixedMinorAttributeDefinition = record
    ID: string;       // e.g. "armorOnKill"
    TypeName: string; // e.g. "Armor On Kill"
    Value: Double;    // Fixed value, e.g., 10.0
  end;

  TCoreAttribute = record // Represents an INSTANCE of a core attribute on a gear piece
    ID: string;
    TypeName: string;
    Value: Double;
    AttrType: TCoreAttributeType;
  end;

  TMinorAttribute = record
    AttrType: TMinorAttributeCat;     // Offensive, Defensive, Utility
    MinorAttribute: TMinorAttributeType; // Specific stat enum
    Value: Double;
  end;

  TModAttribute = record // Represents the selected mod's effect on a gear piece
    ModEffect: TGearModEffectType; // Changed field name and type
    Value: Double;
  end;

  TSetBonus = record
    BonusType: TSetBonusType;
    WeaponType: TWeaponFamily; // Only relevant if BonusType is sbtWeaponTypeDamage
    AttributeID: string; // e.g., 'assault_rifle_damage', 'weapon_damage', 'critical_hit_chance'
    Title: string; // Title of the bonus (e.g. "Dead Man's Hand")
    Value: Double;
    ItemsRequired: Integer;
    Description: string; // For special bonuses or talents
  end;

  TPart = record // Part of a TPieceSet, defining a specific item in a set
    GearSlot: TItemType; // e.g., itMask, itBackpack
    Name: string;        // e.g., "Airaldi Holdings Mask"
    CoreAttributeID: string; // e.g., "weaponDamage", "armor", "skillTier" - links to a TCoreAttribute definition
    FixedMinorAttributeIDs: TArray<string>; // References to fixed minor attribute definitions
    MinorAttributeSlotCount: Integer;
    Talent: string;
    ImagePath: string;
  end;

  TPieceSet = record // Represents a Brand Set or Gear Set definition
    Name: string;        // e.g., "Airaldi Holdings"
    SetType: TSetType;   // e.g., stBrandSet
    Bonuses: TArray<TSetBonus>;
    Parts: TArray<TPart>; // Defines the individual pieces that make up this set
    ImageIndex: Integer;
  end;

  TGearPiece = record
    Name: string;                             // The name of the gear piece instance, e.g., "Fenris Chest"
    SetName: string;                          // The name of the brand or gear set it belongs to, e.g., "Fenris Group AB"
    ItemType: TItemType;                      // e.g., itChest
    CoreAttribute: TCoreAttribute;            // The selected/rolled core attribute for this instance
    MinorAttributes: TArray<TMinorAttribute>; // Array of selected/rolled minor attributes for this instance
    FixedMinorAttributes: TArray<TFixedMinorAttributeDefinition>; // Fixed minor attributes (named / exotics)
    ActualModSlotType: TGearModType;      // The type of mod slot this gear piece has
    ModAttribute: TModAttribute;              // The selected/rolled gear mod attribute for this instance (stores ModEffect and Value)
    ModID: Integer;                           // The ID of the equipped mod (0 if none)
    Talent: string;                           // Talent name, if applicable (for named/exotic chests/backpacks)
    Bonuses: TArray<TSetBonus>;               // The set bonuses this piece contributes to (usually from its TPieceSet definition)
    SetType: TSetType;                        // e.g., stBrandSet, stGearSet
    SelectedMinorIconIndices: TArray<Integer>;
    SelectedModIconIndex: Integer;
    MinorAttributeSlotCount: Integer;
  end;

  TGearLoadout = record
    GearPieces: array[TItemType] of TGearPiece; // Mask, Backpack, Chest, Gloves, Holster, Kneepads (0-indexed)
    Weapons: array[TWeaponSlot] of TWeapon;
    // Primary, Secondary, Sidearm; wsNone slot remains unused
    Score: Double;
  end;

  TFullLoadoutInput = record
    ActiveWeaponConfig: TWeapon;
    EquippedGear: array[TItemType] of TGearPiece;
    ChosenSpecialization: Game.Types.TSpecialization; // mais maintenant class* The full definition of the selected spec
    // This array now stores which of the InherentWeaponTypeBonuses are *actually selected* by the user via checkboxes.
    ActivatedSpecWeaponTypeBonuses: TArray<TWeaponFamily>;
    WatchBonuses: TWatchBonuses; // Placeholder
    WeaponExpertiseLevel: Integer;
    IsPvp: Boolean; // Context for PvP vs PvE calculations
    TotalSkillTiers: Integer; // Pre-calculated from gear for convenience
    IsOvercharged: Boolean;   // Flag for overcharge status
  end;

  TLoadoutAggregatedStats_Display = record
    // Aggregated Percentage Bonuses for Display
    TotalWeaponDamage_AWD_Pct_Display: Double; // All Weapon Damage (AWD) from gear, spec, watch
    TotalSpecificWeaponDamage_SWD_Pct_Display: Double; // Specific Weapon Damage (e.g., AR Dmg) from gear, spec, watch
    TotalDamageToArmor_Pct_Display: Double;
    TotalDamageToHealth_Pct_Display: Double;
    TotalDamageToTargetOutOfCover_OOC_Pct_Display: Double;
    TotalSkillTiers_Display: Integer;   // Sum of skill tiers from gear

    // Final Stat Values for Display (after all calculations including weapon's own stats)
    FinalCHC_Pct_Display: Double;       // Range 0.0 to 0.60 typically
    FinalCHD_Pct_Display: Double;       // Total CHD (e.g., 1.25 for +125%)
    FinalHSD_Pct_Display: Double;       // Total HSD (e.g., 1.75 for +175%)

    // Other potential display values
    TotalArmor_Display: Double;         // Sum of base armor + flat armor bonuses + % armor bonuses
    TotalHealth_Display: Double;
    TotalHandling_Accuracy_Pct_Display: Double;
    TotalHandling_Stability_Pct_Display: Double;
    TotalHandling_ReloadSpeed_Pct_Display: Double;
    TotalOptimalRangePct_Display: Double;
    // Add more fields as needed for UI display, e.g., specific resistances, skill haste, etc.
    TotalSkillDamagePct: Double;
    TotalSkillHastePct: Double;
    TotalSkillDurationPct: Double;
    TotalStatusEffectsPct: Double;
    TotalExplosiveDamagePct: Double;
    TotalRepairSkillsPct: Double;
    TotalSkillHealthPct: Double;
    TotalArmorOnKillPct: Double;
    TotalArmorRegenPct: Double;
    TotalAmmoCapacityPct: Double;
    TotalReducedThreatPct: Double;
    TotalShieldHealthPct: Double;
    TotalMeleeDamagePct: Double;
    TotalScannerPulseHastePct: Double;
    // Defensive Stats
    TotalExplosiveResistancePct: Double;
    TotalHazardProtectionPct: Double;
    TotalIncomingRepairsPct: Double;
    TotalProtectionFromElitesPct: Double;
  end;

  { ────────────  Structures for Skills Stats ──────────── }

  TSkillSlot = (ssPrimary, ssSecondary, ssNone);
//  {
  // --- Structures for Skills ---
  TSkillCategory = (scOffensive, scDefensive, scCrowdControl, scSupport, scHealing);

  TSkillEffectProperty = record // Represents a single property of a skill's effect at a given tier
    Name: string;  // e.g., 'damagePerTick', 'durationSeconds', 'cloudRadiusMeters', 'explosionDamage', 'healAmount'
    Value: Double; // Numeric value
    // Consider adding a ValueType (e.g., vtNumber, vtPercentage, vtBoolean) if values can be non-numeric
    // For now, assuming all relevant effect values are numeric (Double)
  end;

  TSkillEffectTier = record // Represents all effects of a skill variant at a specific tier
    Tier: Integer; // 0-6, or a special value for Overcharge (e.g., 7 or -1)
    Effects: TArray<TSkillEffectProperty>; // Array of specific effects and their values
    // Common properties that might not fit into the Name/Value pair of TSkillEffectProperty,
    // or could be duplicated there for easier access.
    // Example: Cooldown might be here if it varies by tier but isn't a direct "effect" like damage.
  end;

  TSkillVariant = record
    VariantName: string; // e.g., "Base", "Stinger", "Restorer"
    V_ImagePath: string;
    Description: string; // Optional: Specific description for this variant
    Categories: TArray<TSkillCategory>;
    EffectsByTier: TArray<TSkillEffectTier>;
    BaseCooldownSeconds: Double;
    // Other variant-specific properties like base charges, etc.
  end;

  TSkillData = record
    SkillID: string; // Unique identifier, e.g., "oxidizer", "sticky_bomb_explosive"
    SkillName: string; // User-friendly name, e.g., "Oxidizer", "Explosive Sticky Bomb"
    ImagePath: string; // Path to an image for the skill
    Description: string; // General description of the skill
    SkillType: string;   // e.g., "Launcher", "Drone", "Turret", "Hive" - could be an enum later
    Variants: TArray<TSkillVariant>;
  end;

  TEquippedSkill = record
    SkillID: string;
    Variant: TSkillVariant;
  end;

  TPlayerStats = record
    // Attributs principaux
    WeaponDamageBonus: Double; // Bonus de dégâts d'arme provenant des pièces d'équipement
    ArmorBonus: Double;        // Bonus d'armure
    SkillTier: Integer;        // Tier de compétence

    // Attributs secondaires offensifs
    CriticalHitChance: Double;
    CriticalHitDamage: Double;
    HeadshotDamage: Double;

    // Attributs secondaires défensifs
    Health: Double;
    ArmorRegen: Double;
    HazardProtection: Double;
    ExplosiveResistance: Double;
    ProtectionFromElites: Double;

    // Attributs secondaires utilitaires
    SkillDamageBonus: Double;   // Bonus de dégâts de compétence
    SkillHaste: Double;         // Hâte de compétence
    SkillDuration: Double;      // Durée des compétences
    RepairSkills: Double;       // Compétences de réparation
    StatusEffects: Double;      // Effets de statut

    // Autres statistiques
    WeaponHandling: Double;
    IncomingRepairs: Double;
  end;
//  }

  { ----------------------------------------------------------------------------- }
  { --- SERIALIZATION STRUCTURES FOR SAVING/LOADING LOADOUTS                  --- }
  { ----------------------------------------------------------------------------- }

  TSerializableGearPiece = record
    PieceName: string;
    CoreAttributeTypeStr: string;
    CoreAttributeValue: Double;
    MinorAttributeTypeStrs: TArray<string>;
    MinorAttributeValues: TArray<Double>; // Persist actual values
    FixedMinorAttributeIDs: TArray<string>;
    MinorIconIndices: TArray<Integer>;   // new field
    ModID: Integer;
    ModAttributeValue: Double;          // Persist custom mod value
    ModAttributeTypeStr: string;        // Persist custom mod type
    ModIconIndex: Integer;               // new field
    TalentName: string;
    SetName: string;
    SetTypeStr: string;
  end;

  TSerializableWeapon = class
  public
    WeaponID: Integer;
    EquippedModIDs: TDictionary<TModSlot, Integer>;
    SelectedTalentID: Integer;
    SelectedMinorAttributeType: string;
    ExpertiseLevel: Integer;

    constructor Create;
    destructor Destroy; override;
  end;

  TSerializableSkill = record
    SkillID: string;
    VariantName: string;
  end;

  TSerializableLoadout = class
  public
    Name: string;
    GearPieces: TDictionary<TItemType, TSerializableGearPiece>;
    Weapons: TDictionary<TWeaponSlot, TSerializableWeapon>;
    Skills: TDictionary<TSkillSlot, TSerializableSkill>;
    SpecializationName: string;
    ActivatedSpecBonuses: TArray<TWeaponFamily>;

    constructor Create;
    destructor Destroy; override;
  end;

function GetAttributeCatalog: TArray<TAttributeCatalogEntry>;
function GetDefaultMinorAttributeValue(const AttrType: TMinorAttributeType): Double;
// NEW
function NormalizeAttrId(const S: string): string;
//function AttrIdsMatch(const A, B: string): Boolean;
function MinorAttributeCategory(const Attr: TMinorAttributeType): TMinorAttributeCat;
function MinorAttrEnumToId(const AEnum: TMinorAttributeType): string;

const
  // Valeurs max de la Keener's Watch (niveau 50/50)
  MaxWatchWeaponDamagePct = 10.0;
  MaxWatchCritChancePct = 10.0;
  MaxWatchCritDamagePct = 20.0;
  MaxWatchHeadshotDamagePct = 20.0;
  MaxWatchAccuracyPct = 10.0;
  MaxWatchStabilityPct = 10.0;
  MaxWatchReloadSpeedPct = 10.0;
  MaxWatchAmmoPct = 20.0;
  MaxWatchSkillHastePct = 10.0;
  MaxWatchSkillDamagePct = 10.0;
  MaxWatchSkillDurationPct = 20.0;
  MaxWatchRepairSkillsPct = 10.0;
  MaxWatchExplosiveResistancePct = 10.0;
  MaxWatchHazardProtectionPct = 10.0;
  MaxWatchArmorPct = 10.0;
  MaxWatchHealthPct = 10.0;

const
  DefaultWatchBonuses: TWatchBonuses = (
    WeaponDamagePct : MaxWatchWeaponDamagePct;
    CriticalHitChancePct: MaxWatchCritChancePct;
    CriticalHitDamagePct: MaxWatchCritDamagePct;
    HeadshotDamagePct: MaxWatchHeadshotDamagePct;
    ReloadSpeedPct: MaxWatchReloadSpeedPct;
    AccuracyPct: MaxWatchAccuracyPct;
    StabilityPct: MaxWatchStabilityPct;
    AmmoPct: MaxWatchAmmoPct;
    ArmorPct: MaxWatchArmorPct; // bonus % d’armure totale
    HealthPct: MaxWatchHealthPct;
    ExplosiveResistancePct: MaxWatchExplosiveResistancePct;
    HazardProtectionPct: MaxWatchHazardProtectionPct;
    SkillDamagePct: MaxWatchSkillDamagePct;
    SkillHastePct: MaxWatchSkillHastePct;
    SkillDurationPct: MaxWatchSkillDurationPct;
    RepairSkillsPct: MaxWatchRepairSkillsPct);

const
  AttributeCatalogData: array [0 .. 43] of TAttributeCatalogEntry = (
    (ID: 'critical_hit_chance'; DisplayName: 'Critical Hit Chance'; Category: matOffensive),
    (ID: 'critical_hit_damage'; DisplayName: 'Critical Hit Damage'; Category: matOffensive),
    (ID: 'headshot_damage'; DisplayName: 'Headshot Damage'; Category: matOffensive),
    (ID: 'weapon_damage'; DisplayName: 'Weapon Damage'; Category: matOffensive),
    (ID: 'assault_rifle_damage'; DisplayName: 'Assault Rifle Damage'; Category: matOffensive),
    (ID: 'lmg_damage'; DisplayName: 'LMG Damage'; Category: matOffensive),
    (ID: 'shotgun_damage'; DisplayName: 'Shotgun Damage'; Category: matOffensive),
    (ID: 'smg_damage'; DisplayName: 'SMG Damage'; Category: matOffensive),
    (ID: 'rifle_damage'; DisplayName: 'Rifle Damage'; Category: matOffensive),
    (ID: 'mmr_damage'; DisplayName: 'MMR Damage'; Category: matOffensive),
    (ID: 'pistol_damage'; DisplayName: 'Pistol Damage'; Category: matOffensive),
    (ID: 'signature_weapon_damage'; DisplayName: 'Signature Weapon Damage'; Category: matOffensive),
    (ID: 'health_damage'; DisplayName: 'Health Damage'; Category: matOffensive),
    (ID: 'damage_to_armor'; DisplayName: 'Damage to Armor'; Category: matOffensive),
    (ID: 'accuracy'; DisplayName: 'Accuracy'; Category: matOffensive),
    (ID: 'stability'; DisplayName: 'Stability'; Category: matOffensive),
    (ID: 'reload_speed'; DisplayName: 'Reload Speed'; Category: matOffensive),
    (ID: 'weapon_handling'; DisplayName: 'Weapon Handling'; Category: matOffensive),
    (ID: 'ammo_capacity'; DisplayName: 'Ammo Capacity'; Category: matOffensive),
    (ID: 'magazine_size'; DisplayName: 'Magazine Size'; Category: matOffensive),
    (ID: 'rate_of_fire'; DisplayName: 'Rate of Fire'; Category: matOffensive),
    (ID: 'swap_speed'; DisplayName: 'Swap Speed'; Category: matOffensive),
    (ID: 'optimal_range'; DisplayName: 'Optimal Range'; Category: matOffensive),
    (ID: 'skill_tier'; DisplayName: 'Skill Tier'; Category: matUtility),
    (ID: 'skill_haste'; DisplayName: 'Skill Haste'; Category: matUtility),
    (ID: 'skill_damage'; DisplayName: 'Skill Damage'; Category: matUtility),
    (ID: 'repair_skills'; DisplayName: 'Repair Skills'; Category: matUtility),
    (ID: 'skill_duration'; DisplayName: 'Skill Duration'; Category: matUtility),
    (ID: 'status_effects'; DisplayName: 'Status Effects'; Category: matUtility),
    (ID: 'skill_health'; DisplayName: 'Skill Health'; Category: matUtility),
    (ID: 'skill_efficiency'; DisplayName: 'Skill Efficiency'; Category: matUtility),
    (ID: 'explosive_damage'; DisplayName: 'Explosive Damage'; Category: matOffensive),
    (ID: 'shield_health'; DisplayName: 'Shield Health'; Category: matDefensive),
    (ID: 'health'; DisplayName: 'Health'; Category: matDefensive),
    (ID: 'hazard_protection'; DisplayName: 'Hazard Protection'; Category: matDefensive),
    (ID: 'total_armor'; DisplayName: 'Total Armor'; Category: matDefensive),
    (ID: 'explosive_resistance'; DisplayName: 'Explosive Resistance'; Category: matDefensive),
    (ID: 'incoming_repairs'; DisplayName: 'Incoming Repairs'; Category: matDefensive),
    (ID: 'armor_regen_pct'; DisplayName: 'Armor Regen %'; Category: matDefensive),
    (ID: 'armor_on_kill'; DisplayName: 'Armor on Kill'; Category: matDefensive),
    (ID: 'health_on_kill'; DisplayName: 'Health on Kill'; Category: matDefensive),
    (ID: 'disrupt_resistance'; DisplayName: 'Disrupt Resistance'; Category: matDefensive),
    (ID: 'pulse_resistance'; DisplayName: 'Pulse Resistance'; Category: matDefensive),
    (ID: 'shock_resistance'; DisplayName: 'Shock Resistance'; Category: matDefensive));

implementation

{ TSpecialization }

function GetAttributeCatalog: TArray<TAttributeCatalogEntry>;
var
  I: Integer;
begin
  SetLength(Result, Length(AttributeCatalogData));
  for I := 0 to High(AttributeCatalogData) do
    Result[I] := AttributeCatalogData[I];
end;

function GetDefaultMinorAttributeValue(const AttrType: TMinorAttributeType): Double;
begin
  case AttrType of
    madCriticalHitChance:
      Result := 6.0;
    madCriticalHitDamage:
      Result := 12.0;
    madHeadshotDamage:
      Result := 10.0;
    madWeaponHandling:
      Result := 8.0;
    madArmorRegen:
      Result := 1.0;
    madIncomingRepairs:
      Result := 20.0;
    madExplosiveResistance,
    madHazardProtection,
    madStatusEffects:
      Result := 10.0;
    madRepairSkills:
      Result := 20.0;
    madSkillDamage,
    madSkillHaste:
      Result := 10.0;
    madHealth:
      Result := 20.0;
  else
    Result := 0.0;
  end;
end;

function NormalizeAttrId(const S: string): string;
var
  C: Char;
  L: string;
begin
  // Remove spaces, '_', '-', digits… keep only letters, lower-cased.
  Result := '';
  L := LowerCase(S);
  for C in L do
    if C in ['a'..'z'] then
      Result := Result + C;
end;

//function NormalizeAttrId(const S: string): string;
//var
//  Tmp: string;
//begin
//  // Lowercase + remove spaces, underscores and hyphens
//  Tmp := LowerCase(S);
//  Tmp := StringReplace(Tmp, ' ', '', [rfReplaceAll]);
//  Tmp := StringReplace(Tmp, '_', '', [rfReplaceAll]);
//  Tmp := StringReplace(Tmp, '-', '', [rfReplaceAll]);
//
//  // Strip trailing digits (handles armorRegen0, statusEffects1, etc.)
//  while (Tmp <> '') and CharInSet(Tmp[Length(Tmp)], ['0'..'9']) do
//    Delete(Tmp, Length(Tmp), 1);
//
//  Result := Tmp;
//end;

//function AttrIdsMatch(const A, B: string): Boolean;
//begin
//  Result := (NormalizeAttrId(A) = NormalizeAttrId(B));
//end;

function MinorAttributeCategory(const Attr: TMinorAttributeType): TMinorAttributeCat;
begin
  case Attr of
    // Offensive minors
    madCriticalHitChance,
    madCriticalHitDamage,
    madHeadshotDamage,
    madWeaponHandling:
      Result := matOffensive;

    // Utility minors
    madSkillDamage,
    madSkillHaste,
    madStatusEffects,
    madRepairSkills:
      Result := matUtility;

  else
    // Everything else is defensive by default
    Result := matDefensive;
  end;
end;

function MinorAttrEnumToId(const AEnum: TMinorAttributeType): string;
begin
  // Canonical "minor attribute id" for mapping vs JSON.
  // These are camelCase; we always compare via NormalizeAttrId(...) anyway.
  case AEnum of
    madArmorRegen:          Result := 'armorRegen';
    madCriticalHitChance:   Result := 'criticalHitChance';
    madCriticalHitDamage:   Result := 'criticalHitDamage';
    madExplosiveResistance: Result := 'explosiveResistance';
    madIncomingRepairs:     Result := 'incomingRepairs';
    madHazardProtection:    Result := 'hazardProtection';
    madHeadshotDamage:      Result := 'headshotDamage';
    madHealth:              Result := 'health';
    madRepairSkills:        Result := 'repairSkills';
    madSkillDamage:         Result := 'skillDamage';
    madSkillHaste:          Result := 'skillHaste';
    madStatusEffects:       Result := 'statusEffects';
    madWeaponHandling:      Result := 'weaponHandling';
  else
    Result := '';
  end;
end;

{ TSpecialization }
constructor TSpecialization.Create;
begin
  inherited;
  FInherentWeaponTypeBonuses := TDictionary<TWeaponFamily, Double>.Create;
  FGeneralBonuses            := TDictionary<string, Double>.Create;
  InherentWeaponTypeBonuses := FInherentWeaponTypeBonuses;
  GeneralBonuses            := FGeneralBonuses;
end;

destructor TSpecialization.Destroy;
begin
  FGeneralBonuses.Free;
  FInherentWeaponTypeBonuses.Free;
  inherited;
end;

constructor TSerializableWeapon.Create;
begin
  inherited Create;
  EquippedModIDs := TDictionary<TModSlot, Integer>.Create;
end;

destructor TSerializableWeapon.Destroy;
begin
  EquippedModIDs.Free;
  inherited Destroy;
end;

constructor TSerializableLoadout.Create;
begin
  inherited Create;
  GearPieces := TDictionary<TItemType, TSerializableGearPiece>.Create;
  Weapons   := TDictionary<TWeaponSlot, TSerializableWeapon>.Create;
  Skills    := TDictionary<TSkillSlot, TSerializableSkill>.Create;
  SetLength(ActivatedSpecBonuses, 0);
end;

destructor TSerializableLoadout.Destroy;
var
  W: TSerializableWeapon;
begin
  for W in Weapons.Values do
    W.Free;
  Weapons.Free;
  Skills.Free;
  GearPieces.Free;
  inherited Destroy;
end;

end.
