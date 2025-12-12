unit CalcEngine;

interface

uses
  System.SysUtils, System.TypInfo, System.Generics.Collections, Game.Types,
  Math, Game.JsonIterator, Utils;

const
  BASE_CHD  = 0.25; // 25%
  CAP_CHC   = 0.60; // 60%

type
  { every additive pool will carry its own little list of sources }
  TBreakList = TDictionary<string, Double>;

  TDamagePools = record
    BaseDamage: Double; // raw + expertise
    RPM: Double;
    Magazine: Double;
    ReloadSec: Double;

    AWD: Double;
    SWD: Double;
    TlWD: Double;
    CHC: Double; // CHC
    CHD: Double; // CHD
    HeadDmg: Double; // HSD
    ArmorHealth: Double; // DTA/DTH (only one active when you call)
    OOC: Double; // DTTOOC
    Amplifiers: Double; // Spotter / Intimidate / �

    { break-downs (key = source label, value = pct as fraction) }
    B_AWD: TBreakList;
    B_SWD: TBreakList;
    B_TlWD: TBreakList;
    B_CritHead: TBreakList;
    B_AH: TBreakList;
    B_OOC: TBreakList;
    B_Amp: TBreakList;
  end;

  TDamageResult = record
    Body: Double;
    BodyCrit: Double;
    Head: Double;
    HeadCrit: Double;
    AvgShot: Double;
    BurstDPS: Double;
    SustainDPS: Double;
  end;

  // Define array types for mod effects to be used in parameters
  TModEffectsArray = array [TModSlot] of TWeaponModEffect;
  // **** NEW TYPE DEFINITION ****

  TFullDamageCalcResult = record // Might expand TDamageResult or be new
    TotalWeaponDamage: Double;
    BurstDPS: Double;
    SustainDPS: Double;
    FinalCHC: Double;     // Range 0.0 to 0.60
    FinalCHD: Double;     // Represents total CHD (e.g., 1.25 for +125% total CHD from a base of 0.25)
    FinalHSD: Double;     // Represents total HSD (e.g., 1.75 for +175% total HSD from a base of weapon's HSD)
    FinalRPM: Double;
    FinalMagazine: Double;
    FinalReloadSec: Double;
    FinalAccuracy: Double;
    FinalStability: Double;
    FinalOptimalRange: Double;
  end;

  TPlayerAggregatedStats = record
    TotalSkillDamage: Double;
    TotalSkillHaste: Double;
    TotalSkillDuration: Double;
    TotalSkillHealth: Double;
    TotalStatusEffects: Double;
    TotalExplosiveDamage: Double;
    TotalRepairSkills: Double;
    // Add other aggregated stats as needed, e.g., DTA, DTOC
  end;

function NewPool: TDamagePools; // helper
function ComputeDamage(const P: TDamagePools): TDamageResult;
function CanonicalSetName(const Raw: string): string;

// convenience wrappers � sums the dictionaries into one number
function Sum(const List: TBreakList): Double;

function CalculateWeaponPerformance(const BaseWeapon: TWeapon;
  const WeaponArchetypeStats: TWeaponStat;
  const Selected3rdAttributeType: string; const ModBonuses: TModEffectsArray;
  const ModDrawbacks: TModEffectsArray; const SelectedTalent: TWeaponTalent;
  ExpertiseBonusPct: Double): TFullDamageCalcResult;

function CalculateCompleteLoadoutPerformance(const LoadoutInput
  : TFullLoadoutInput; const AllPieceSetDefinitions
  : TDictionary<string, TPieceSet>;
  const AllWeaponStats: TDictionary<Integer, TWeaponStat>;
  const AllWeaponMods: TDictionary<Integer, TWeaponMod>;
  const AllWeaponTalents: TDictionary<Integer, TWeaponTalent>;
  out FullDamageResult: TFullDamageCalcResult;
  out AggregatedDisplayStats: TLoadoutAggregatedStats_Display): Boolean;

function AggregatePlayerStats(const APlayerLoadout: TFullLoadoutInput;
  const AAllPieceSetDefinitions: TDictionary<string, TPieceSet>)
  : TPlayerAggregatedStats;

function CalculateSkillPerformance(const ASkillVariant: TSkillVariant;
  const APlayerStats: TPlayerAggregatedStats; const ASkillTier: Integer;
  const AIsOvercharged: Boolean; const AIsPvp: Boolean)
  : TDictionary<string, Double>;

procedure AddPct(List: TBreakList; const Name: string; Value: Double); // helper

procedure ApplyStatAttribute(const Attr: TAttribute; const SourcePrefix: string;
  var APools: TDamagePools; var FinalAcc, FinalStab, FinalOptRange: Double);

procedure ApplyModOrTalentEffect(const SourceName: string;
  const Effect: TWeaponModEffect; IsDrawback: Boolean; var APools: TDamagePools;
  var FinalAcc, FinalStab, FinalOptRange: Double);

implementation


function CanonicalSetName(const Raw: string): string;
var
  LOpenParen, LCloseParen: Integer;
  LBrandName: string;
begin
  Result := Trim(Raw);
  if Result = '' then
    Exit;

  if SameText(Result, 'Matador') or SameText(Result, 'Chain Killer') then
    Exit('Walker, Harris & Co.');

  LOpenParen := Pos('(', Result);
  if LOpenParen = 0 then
    Exit;

  LCloseParen := LastDelimiter(')', Result);
  if (LCloseParen <= LOpenParen) then
    Exit;

  LBrandName := Trim(Copy(Result, LOpenParen + 1,
    LCloseParen - LOpenParen - 1));
  if LBrandName <> '' then
    Exit(LBrandName);
end;

// Forward declaration if ApplyGearPieceBonuses is used by a function declared before it in the interface
// procedure ApplyGearPieceBonuses(const AGearPiece: TGearPiece; var APools: TDamagePools; var ADisplayStats: TLoadoutAggregatedStats_Display); // Not needed if only called by CalculateCompleteLoadoutPerformance

procedure ApplyGearPieceBonuses(const AGearPiece: TGearPiece;
  const AGearPieceName: string; var APools: TDamagePools;
  var ADisplayStats: TLoadoutAggregatedStats_Display);
var
  LMinorAttr: TMinorAttribute;
  LFixedAttr: TFixedMinorAttributeDefinition;
  LValueFraction: Double; // For percentage-based attributes
  LSourcePrefix: string;
  I: Integer;
begin
  LSourcePrefix := AGearPieceName + ': ';

  // --- 1. Core Attribute ---
  if AGearPiece.CoreAttribute.ID <> '' then
  // Check if a core attribute is assigned
  begin
    LValueFraction := AGearPiece.CoreAttribute.Value / 100.0;
    // Assuming core weapon damage is %

    case AGearPiece.CoreAttribute.AttrType of
      catWeaponDamage: // Typically +15% Weapon Damage
        begin
          AddPct(APools.B_AWD, LSourcePrefix +
            AGearPiece.CoreAttribute.TypeName, LValueFraction);
          ADisplayStats.TotalWeaponDamage_AWD_Pct_Display :=
            ADisplayStats.TotalWeaponDamage_AWD_Pct_Display + LValueFraction;
        end;
      catArmor:
        begin
          // Armor contributes to survivability, not directly to TDamagePools for DPS.
          // It would be part of a separate EHP calculation.
          // For display stats, we might accumulate total armor.
          ADisplayStats.TotalArmor_Display := ADisplayStats.TotalArmor_Display +
            AGearPiece.CoreAttribute.Value;
          // Assuming Value is the flat armor amount
        end;
      catSkillTier:
        begin
          // Skill Tier contributes to skill effectiveness, not directly to TDamagePools for weapon DPS.
          ADisplayStats.TotalSkillTiers_Display :=
            ADisplayStats.TotalSkillTiers_Display +
            Round(AGearPiece.CoreAttribute.Value);
          // Skill Tier is usually a whole number
        end;
    end;

  end;

  // --- 2. Minor Attributes ---
  for I := 0 to High(AGearPiece.MinorAttributes) do
  begin
    LMinorAttr := AGearPiece.MinorAttributes[I];
    LValueFraction := LMinorAttr.Value / 100.0;
    // Most minor attributes are percentages

    case LMinorAttr.MinorAttribute of
      // Offensive Minors
      madCriticalHitChance:
        begin
          APools.CHC := APools.CHC + LValueFraction;
          ADisplayStats.FinalCHC_Pct_Display :=
            ADisplayStats.FinalCHC_Pct_Display + LValueFraction;
        end;
      madCriticalHitDamage:
        begin
          AddPct(APools.B_CritHead, LSourcePrefix + 'Minor CHD',
            LValueFraction);
          ADisplayStats.FinalCHD_Pct_Display :=
            ADisplayStats.FinalCHD_Pct_Display + LValueFraction;
        end;
      madHeadshotDamage:
        begin
          APools.HeadDmg := APools.HeadDmg + LValueFraction;
          // HSD is additive to the weapon's base HSD multiplier
          ADisplayStats.FinalHSD_Pct_Display :=
            ADisplayStats.FinalHSD_Pct_Display + LValueFraction;
        end;
      madWeaponHandling:
      // Weapon Handling can be Accuracy, Stability, Reload Speed, Swap Speed. Assume it's split or applied generally.
        begin
          // For simplicity, let's assume it gives a small bonus to accuracy, stability, and reload speed for display.
          // The actual game mechanics might be more complex or specific.
          // This part needs careful mapping if "Weapon Handling" gives specific percentages to underlying stats.
          // For now, let's add to display stats directly.
          ADisplayStats.TotalHandling_Accuracy_Pct_Display :=
            ADisplayStats.TotalHandling_Accuracy_Pct_Display +
            (LValueFraction / 3); // Example: split effect
          ADisplayStats.TotalHandling_Stability_Pct_Display :=
            ADisplayStats.TotalHandling_Stability_Pct_Display +
            (LValueFraction / 3);
          ADisplayStats.TotalHandling_ReloadSpeed_Pct_Display :=
            ADisplayStats.TotalHandling_ReloadSpeed_Pct_Display +
            (LValueFraction / 3);
          // Note: TDamagePools does not have direct fields for Acc/Stab. These are handled by CalculateWeaponPerformance.
          // If gear directly affects these for the *overall* loadout, TDamagePools might need expansion or this logic needs to feed into weapon calcs.
        end;

      // Defensive Minors (mostly for display or EHP, not direct DPS pools)
      madArmorRegen:
        ADisplayStats.TotalArmorRegenPct := ADisplayStats.TotalArmorRegenPct + LMinorAttr.Value;
      madExplosiveResistance:
        ADisplayStats.TotalExplosiveResistancePct := ADisplayStats.TotalExplosiveResistancePct + LMinorAttr.Value;
      madHazardProtection:
        ADisplayStats.TotalHazardProtectionPct := ADisplayStats.TotalHazardProtectionPct + LMinorAttr.Value;
      madHealth:
        begin
          ADisplayStats.TotalHealth_Display := ADisplayStats.TotalHealth_Display
            + LMinorAttr.Value;
          // Assuming Health is a flat value from minor attributes
        end;
      madIncomingRepairs:
        ADisplayStats.TotalIncomingRepairsPct := ADisplayStats.TotalIncomingRepairsPct + LMinorAttr.Value;

      // Utility Minors (mostly for skill builds or specific display stats)
      madRepairSkills:
        ADisplayStats.TotalRepairSkillsPct := ADisplayStats.TotalRepairSkillsPct + LMinorAttr.Value;
      madSkillDamage:
        ;
      madSkillHaste:
        ;
      madStatusEffects:
        ;
    else
      // Handle unknown or other minor attributes if necessary
    end;
  end;

  // --- 2b. Fixed Minor Attributes (named/exotic gear) ---
  for LFixedAttr in AGearPiece.FixedMinorAttributes do
  begin
    if LFixedAttr.ID.IsEmpty then
      Continue;

    LValueFraction := LFixedAttr.Value / 100.0;
    var LNormalizedID := RemoveAttributeSuffix(LFixedAttr.ID);

    if SameText(LNormalizedID, 'weaponDamage') then
    begin
      AddPct(APools.B_AWD, LSourcePrefix + 'Fixed ' + LFixedAttr.TypeName,
        LValueFraction);
      ADisplayStats.TotalWeaponDamage_AWD_Pct_Display :=
        ADisplayStats.TotalWeaponDamage_AWD_Pct_Display + LValueFraction;
    end
    else if SameText(LNormalizedID, 'damageToArmor') then
    begin
      AddPct(APools.B_AH, LSourcePrefix + 'Fixed ' + LFixedAttr.TypeName,
        LValueFraction);
      ADisplayStats.TotalDamageToArmor_Pct_Display :=
        ADisplayStats.TotalDamageToArmor_Pct_Display + LValueFraction;
    end
    else if SameText(LNormalizedID, 'healthDamage') then
    begin
      AddPct(APools.B_AH, LSourcePrefix + 'Fixed ' + LFixedAttr.TypeName,
        LValueFraction);
      ADisplayStats.TotalDamageToHealth_Pct_Display :=
        ADisplayStats.TotalDamageToHealth_Pct_Display + LValueFraction;
    end
    else if SameText(LNormalizedID, 'damageOutOfCover') then
    begin
      AddPct(APools.B_OOC, LSourcePrefix + 'Fixed ' + LFixedAttr.TypeName,
        LValueFraction);
      ADisplayStats.TotalDamageToTargetOutOfCover_OOC_Pct_Display :=
        ADisplayStats.TotalDamageToTargetOutOfCover_OOC_Pct_Display +
        LValueFraction;
    end
    else if SameText(LNormalizedID, 'headshotDamage') then
    begin
      APools.HeadDmg := APools.HeadDmg + LValueFraction;
      ADisplayStats.FinalHSD_Pct_Display :=
        ADisplayStats.FinalHSD_Pct_Display + LValueFraction;
    end
    else if SameText(LNormalizedID, 'weaponHandling') then
    begin
      ADisplayStats.TotalHandling_Accuracy_Pct_Display :=
        ADisplayStats.TotalHandling_Accuracy_Pct_Display + (LValueFraction / 3);
      ADisplayStats.TotalHandling_Stability_Pct_Display :=
        ADisplayStats.TotalHandling_Stability_Pct_Display + (LValueFraction / 3);
      ADisplayStats.TotalHandling_ReloadSpeed_Pct_Display :=
        ADisplayStats.TotalHandling_ReloadSpeed_Pct_Display +
        (LValueFraction / 3);
    end
    else if SameText(LNormalizedID, 'accuracy') then
    begin
      ADisplayStats.TotalHandling_Accuracy_Pct_Display :=
        ADisplayStats.TotalHandling_Accuracy_Pct_Display + LValueFraction;
    end
    else if SameText(LNormalizedID, 'optimalRange') then
    begin
      ADisplayStats.TotalOptimalRangePct_Display :=
        ADisplayStats.TotalOptimalRangePct_Display + LValueFraction;
    end
    else if SameText(LNormalizedID, 'statusEffects') then
      ADisplayStats.TotalStatusEffectsPct :=
        ADisplayStats.TotalStatusEffectsPct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'skillHealth') then
      ADisplayStats.TotalSkillHealthPct :=
        ADisplayStats.TotalSkillHealthPct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'armorOnKill') then
      ADisplayStats.TotalArmorOnKillPct :=
        ADisplayStats.TotalArmorOnKillPct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'armorRegen') then
      ADisplayStats.TotalArmorRegenPct :=
        ADisplayStats.TotalArmorRegenPct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'ammoCapacity') then
      ADisplayStats.TotalAmmoCapacityPct :=
        ADisplayStats.TotalAmmoCapacityPct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'reducedThreat') then
      ADisplayStats.TotalReducedThreatPct :=
        ADisplayStats.TotalReducedThreatPct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'shieldHealth') then
      ADisplayStats.TotalShieldHealthPct :=
        ADisplayStats.TotalShieldHealthPct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'meleeDamage') then
      ADisplayStats.TotalMeleeDamagePct :=
        ADisplayStats.TotalMeleeDamagePct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'scannerPulseHaste') then
      ADisplayStats.TotalScannerPulseHastePct :=
        ADisplayStats.TotalScannerPulseHastePct + LFixedAttr.Value
    else if SameText(LNormalizedID, 'pistolDamage') then
    begin
      AddPct(APools.B_SWD, LSourcePrefix + 'Fixed ' + LFixedAttr.TypeName,
        LValueFraction);
      ADisplayStats.TotalSpecificWeaponDamage_SWD_Pct_Display :=
        ADisplayStats.TotalSpecificWeaponDamage_SWD_Pct_Display +
        LValueFraction;
    end;
  end;

  // --- 3. Mod Attribute (from Gear Mod Slot) ---
  if AGearPiece.ModAttribute.ModEffect <> gmetUnknown then
  // Check if a mod is slotted and has an effect
  begin
    LValueFraction := AGearPiece.ModAttribute.Value / 100.0;
    // Gear mods are typically percentages

    case AGearPiece.ModAttribute.ModEffect of
      // Offensive Mods
      gmetCriticalHitChance:
        begin
          APools.CHC := APools.CHC + LValueFraction;
          ADisplayStats.FinalCHC_Pct_Display :=
            ADisplayStats.FinalCHC_Pct_Display + LValueFraction;
        end;
      gmetCriticalHitDamage:
        begin
          AddPct(APools.B_CritHead, LSourcePrefix + 'Mod CHD', LValueFraction);
          ADisplayStats.FinalCHD_Pct_Display :=
            ADisplayStats.FinalCHD_Pct_Display + LValueFraction;
        end;
      gmetHeadshotDamage:
        begin
          APools.HeadDmg := APools.HeadDmg + LValueFraction;
          ADisplayStats.FinalHSD_Pct_Display :=
            ADisplayStats.FinalHSD_Pct_Display + LValueFraction;
        end;

      // Defensive Mods (examples, expand as needed)
      gmetProtectionFromElites:
        ADisplayStats.TotalProtectionFromElitesPct := ADisplayStats.TotalProtectionFromElitesPct + LValueFraction * 100;
      gmetExplosiveResistance:
        ADisplayStats.TotalExplosiveResistancePct := ADisplayStats.TotalExplosiveResistancePct + LValueFraction * 100;

      // Skill Mods (examples, expand as needed)
      gmetSkillHaste:
        ADisplayStats.TotalSkillHastePct := ADisplayStats.TotalSkillHastePct + LValueFraction * 100;
      gmetSkillDamage:
        ADisplayStats.TotalSkillDamagePct := ADisplayStats.TotalSkillDamagePct + LValueFraction * 100;
      gmetRepairSkills:
        ADisplayStats.TotalRepairSkillsPct := ADisplayStats.TotalRepairSkillsPct + LValueFraction * 100;
      gmetIncomingRepairs:
        ADisplayStats.TotalIncomingRepairsPct := ADisplayStats.TotalIncomingRepairsPct + LValueFraction * 100;
      gmetArmorOnKillFlat:
        ADisplayStats.TotalArmorOnKillPct := ADisplayStats.TotalArmorOnKillPct + LValueFraction * 100; // Assuming value is pct, usually is
      gmetStatusEffectResistance:
        ADisplayStats.TotalHazardProtectionPct := ADisplayStats.TotalHazardProtectionPct + LValueFraction * 100;
      gmetPulseResistance:
        ; // Specific
      gmetSkillDuration:
        ADisplayStats.TotalSkillDurationPct := ADisplayStats.TotalSkillDurationPct + LValueFraction * 100;
      gmetSkillHealth:
        ADisplayStats.TotalSkillHealthPct := ADisplayStats.TotalSkillHealthPct + LValueFraction * 100;
    else
      // Handle other TGearModEffectType values if they impact general weapon DPS or display stats
    end;
  end;

  // Note: Gear Talents are not handled here. They are typically more complex and conditional,
  // and might be better handled at a higher level in CalculateCompleteLoadoutPerformance
  // or by directly adding to APools.B_Amp or other specific pools if they provide direct % damage.
end;

procedure ApplySetBonuses(const AEquippedGear: array of TGearPiece;
  const AAllPieceSetDefinitions: TDictionary<string, TPieceSet>;
  const AActiveWeaponType: TWeaponFamily;
  // Needed for weapon-specific set bonuses
  var APools: TDamagePools; var ADisplayStats: TLoadoutAggregatedStats_Display);
var
  EquippedSetCounts: TDictionary<string, Integer>;
  LGearPiece: TGearPiece;
  LSetName: string;
  LCount: Integer;
  LPieceSet: TPieceSet;
  LSetBonus: TSetBonus;
  LValueFraction: Double;
  LSourcePrefix: string;
  I, J, K: Integer;
  EquippedSetCountsKeys: TArray<string>;
  AAllPieceSetDefinitionsValues: TArray<TPieceSet>;
  PS: TPieceSet;
begin
  EquippedSetCounts := TDictionary<string, Integer>.Create;
  try
    // 1. Count equipped pieces for each set
    for I := 0 to High(AEquippedGear) do
    begin
      LGearPiece := AEquippedGear[I];
      if LGearPiece.SetName <> '' then // Ensure the gear piece belongs to a set
      begin
        var Key := CanonicalSetName(LGearPiece.SetName);
        EquippedSetCounts.TryGetValue(Key, LCount);
        EquippedSetCounts.AddOrSetValue(Key, LCount + 1);
      end;
    end;

    // 2. Iterate through all known set definitions and apply bonuses if criteria met
    {for LSetName in AAllPieceSetDefinitions.Keys do}
    EquippedSetCountsKeys := EquippedSetCounts.Keys.ToArray;
    for I := 0 to High(EquippedSetCountsKeys) do
    begin
      LSetName := EquippedSetCountsKeys[I];
      LCount := EquippedSetCounts.Items[LSetName];

      if (LCount <= 0) then
        Continue;

      if not AAllPieceSetDefinitions.TryGetValue(LSetName, LPieceSet) then
        Continue;

      LSourcePrefix := 'Set: ' + LSetName + ' (' + IntToStr(LCount) + 'pc): ';

      if LPieceSet.SetType = stNamedSet then
      begin
        // Chercher une définition de MARQUE du même nom et l'utiliser pour les bonus 1pc/2pc/3pc
        AAllPieceSetDefinitionsValues := AAllPieceSetDefinitions.Values.ToArray;
        for J := 0 to High(AAllPieceSetDefinitionsValues) do
        begin
          PS := AAllPieceSetDefinitionsValues[J];
          if (PS.Name = LPieceSet.Name) and (PS.SetType = stBrandSet) then
          begin
            LPieceSet := PS;
            Break;
          end;
        end;
      end;

      for J := 0 to High(LPieceSet.Bonuses) do
      begin
        LSetBonus := LPieceSet.Bonuses[J];
        if LCount >= LSetBonus.ItemsRequired then
        begin
          LValueFraction := LSetBonus.Value / 100.0;
          // Most set bonuses are percentages

          case LSetBonus.BonusType of
            sbtWeaponDamage: // Generic weapon damage
              begin
                AddPct(APools.B_AWD, LSourcePrefix + LSetBonus.AttributeID,
                  LValueFraction);
                ADisplayStats.TotalWeaponDamage_AWD_Pct_Display :=
                  ADisplayStats.TotalWeaponDamage_AWD_Pct_Display +
                  LValueFraction;
              end;
            sbtWeaponTypeDamage: // Specific weapon type damage
              begin
                // Check if the bonus applies to the currently active weapon type
                if LSetBonus.WeaponType = AActiveWeaponType then
                begin
                  // SWD (Specific Weapon Damage) applies if the set bonus weapon type matches the active weapon.
                  // AWD (All Weapon Damage) is also often used for these in games for simplicity in stacking,
                  // or it could be a separate SWD pool if the engine distinguishes them strongly.
                  // For now, let's add to B_SWD for calculation clarity and also to display SWD.
                  AddPct(APools.B_SWD, LSourcePrefix + LSetBonus.AttributeID,
                    LValueFraction);
                  ADisplayStats.TotalSpecificWeaponDamage_SWD_Pct_Display :=
                    ADisplayStats.TotalSpecificWeaponDamage_SWD_Pct_Display +
                    LValueFraction;
                end;
              end;
            sbtCoreAttribute:
              begin
                // Examples: "+1 Skill Tier", "+15% Weapon Damage (as a core-like bonus)"
                // This needs careful mapping based on LSetBonus.AttributeID
                if SameText(LSetBonus.AttributeID, 'skillTier') then
                // Example ID
                begin
                  ADisplayStats.TotalSkillTiers_Display :=
                    ADisplayStats.TotalSkillTiers_Display +
                    Round(LSetBonus.Value); // Skill Tiers are whole numbers
                end
                else if SameText(LSetBonus.AttributeID, 'weaponDamage') then
                // Example if a set gives WD as a "core attribute" type bonus
                begin
                  AddPct(APools.B_AWD, LSourcePrefix + LSetBonus.AttributeID,
                    LValueFraction);
                  ADisplayStats.TotalWeaponDamage_AWD_Pct_Display :=
                    ADisplayStats.TotalWeaponDamage_AWD_Pct_Display +
                    LValueFraction;
                end
                else if SameText(LSetBonus.AttributeID, 'armor') then
                // Example for flat armor
                begin
                  ADisplayStats.TotalArmor_Display :=
                    ADisplayStats.TotalArmor_Display + LSetBonus.Value;
                end;
              end;
            sbtAttribute: // General attributes like CHC, CHD, HSD, etc.
              begin
                if SameText(LSetBonus.AttributeID, 'criticalHitChance') then
                begin
                  APools.CHC := APools.CHC + LValueFraction;
                  ADisplayStats.FinalCHC_Pct_Display :=
                    ADisplayStats.FinalCHC_Pct_Display + LValueFraction;
                end
                else if SameText(LSetBonus.AttributeID, 'criticalHitDamage')
                then
                begin
                  AddPct(APools.B_CritHead,
                    LSourcePrefix + LSetBonus.AttributeID, LValueFraction);
                  ADisplayStats.FinalCHD_Pct_Display :=
                    ADisplayStats.FinalCHD_Pct_Display + LValueFraction;
                end
                else if SameText(LSetBonus.AttributeID, 'headshotDamage') then
                begin
                  APools.HeadDmg := APools.HeadDmg + LValueFraction;
                  ADisplayStats.FinalHSD_Pct_Display :=
                    ADisplayStats.FinalHSD_Pct_Display + LValueFraction;
                end
                else if SameText(LSetBonus.AttributeID, 'damageToArmor') then
                begin
                  AddPct(APools.B_AH, LSourcePrefix + LSetBonus.AttributeID,
                    LValueFraction);
                  ADisplayStats.TotalDamageToArmor_Pct_Display :=
                    ADisplayStats.TotalDamageToArmor_Pct_Display +
                    LValueFraction;
                end
                else if SameText(LSetBonus.AttributeID, 'damageToHealth') then
                // Assuming B_AH covers both DTA and DTH
                begin
                  AddPct(APools.B_AH, LSourcePrefix + LSetBonus.AttributeID,
                    LValueFraction);
                  ADisplayStats.TotalDamageToHealth_Pct_Display :=
                    ADisplayStats.TotalDamageToHealth_Pct_Display +
                    LValueFraction;
                end
                else if SameText(LSetBonus.AttributeID,
                  'damageToTargetOutOfCover') then
                begin
                  AddPct(APools.B_OOC, LSourcePrefix + LSetBonus.AttributeID,
                    LValueFraction);
                  ADisplayStats.TotalDamageToTargetOutOfCover_OOC_Pct_Display
                    := ADisplayStats.
                    TotalDamageToTargetOutOfCover_OOC_Pct_Display +
                    LValueFraction;
                end
                else if SameText(LSetBonus.AttributeID, 'weaponHandling') then
                begin
                  ADisplayStats.TotalHandling_Accuracy_Pct_Display :=
                    ADisplayStats.TotalHandling_Accuracy_Pct_Display +
                    (LValueFraction / 3);
                  ADisplayStats.TotalHandling_Stability_Pct_Display :=
                    ADisplayStats.TotalHandling_Stability_Pct_Display +
                    (LValueFraction / 3);
                  ADisplayStats.TotalHandling_ReloadSpeed_Pct_Display :=
                    ADisplayStats.TotalHandling_ReloadSpeed_Pct_Display +
                    (LValueFraction / 3);
                end;
                // Add more attribute mappings here based on common AttributeIDs from your JSON
              end;
            sbtSkillAttribute:
              begin
                if SameText(LSetBonus.AttributeID, 'skill_haste') then
                   ADisplayStats.TotalSkillHastePct := ADisplayStats.TotalSkillHastePct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'skill_damage') then
                   ADisplayStats.TotalSkillDamagePct := ADisplayStats.TotalSkillDamagePct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'repair_skills') then
                   ADisplayStats.TotalRepairSkillsPct := ADisplayStats.TotalRepairSkillsPct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'status_effects') then
                   ADisplayStats.TotalStatusEffectsPct := ADisplayStats.TotalStatusEffectsPct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'skill_duration') then
                   ADisplayStats.TotalSkillDurationPct := ADisplayStats.TotalSkillDurationPct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'skill_health') then
                   ADisplayStats.TotalSkillHealthPct := ADisplayStats.TotalSkillHealthPct + LSetBonus.Value;
              end;
            sbtDefenseAttribute:
              begin
                if SameText(LSetBonus.AttributeID, 'armor_regen') then
                   ADisplayStats.TotalArmorRegenPct := ADisplayStats.TotalArmorRegenPct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'armor_on_kill') then
                   ADisplayStats.TotalArmorOnKillPct := ADisplayStats.TotalArmorOnKillPct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'hazard_protection') then
                   ADisplayStats.TotalHazardProtectionPct := ADisplayStats.TotalHazardProtectionPct + LSetBonus.Value
                else if SameText(LSetBonus.AttributeID, 'health') then
                   ADisplayStats.TotalHealth_Display := ADisplayStats.TotalHealth_Display + ((ADisplayStats.TotalArmor_Display + ADisplayStats.TotalHealth_Display) * (LSetBonus.Value / 100.0)) // Approximation if % Health
                else if SameText(LSetBonus.AttributeID, 'incoming_repairs') then
                   ADisplayStats.TotalIncomingRepairsPct := ADisplayStats.TotalIncomingRepairsPct + LSetBonus.Value;
              end;
            sbtResistance:
               begin
                 if SameText(LSetBonus.AttributeID, 'explosive_resistance') then
                   ADisplayStats.TotalExplosiveResistancePct := ADisplayStats.TotalExplosiveResistancePct + LSetBonus.Value
                 else if SameText(LSetBonus.AttributeID, 'protection_from_elites') then
                   ADisplayStats.TotalProtectionFromElitesPct := ADisplayStats.TotalProtectionFromElitesPct + LSetBonus.Value;
               end;
            sbtGearSetBonus, sbtExoticBonus, sbtTalent, sbtSpecial:
              begin
                // These are often unique, named talents or complex mechanics.
                // Examples: "Perfectly Unbreakable", "Symptom Aggravator (Vile Mask)"
                // Simple percentage damage increases might be added to APools.B_Amp (Amplificative Damage)
                // or APools.B_TlWD (Total Weapon Damage) if they are straightforward multipliers.
                // This requires specific knowledge of each talent.
                // For now, we'll log a placeholder or skip if not a direct, known % damage.
                // if LSetBonus.Description contains '% Weapon Damage' then ...
                // Example: if a talent gives +20% Total Weapon Damage (multiplicative)
                // AddPct(APools.B_TlWD, LSourcePrefix + LSetBonus.Description, LValueFraction);
                // ADisplayStats might need a field for total multiplicative bonus if shown separately.
              end;
            sbtMultiplicativeDamage:
              begin
                // This type implies the bonus is multiplicative with other damage.
                // Often added to a specific pool like B_Amp or B_TlWD.
                AddPct(APools.B_Amp, LSourcePrefix + LSetBonus.AttributeID,
                  LValueFraction);
                // Consider if ADisplayStats needs a specific field for total multiplicative damage.
              end;
          else
            // Handle unknown bonus types or add more cases
          end;
        end;
      end;
    end;
  finally
    EquippedSetCounts.Free;
  end;
end;

// Removed HasSpecBonus function implementation due to type conflict
// and lack of use in the primary calculation flow.

function NewPool: TDamagePools;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.B_AWD := TBreakList.Create;
  Result.B_SWD := TBreakList.Create;
  Result.B_TlWD := TBreakList.Create;
  Result.B_CritHead := TBreakList.Create;
  Result.B_AH := TBreakList.Create;
  Result.B_OOC := TBreakList.Create;
  Result.B_Amp := TBreakList.Create;
end;

procedure AddPct(List: TBreakList; const Name: string; Value: Double);
begin
  if SameValue(Value, 0) then
    Exit;

  if List.ContainsKey(Name) then
    List[Name] := List[Name] + Value
  else
    List.Add(Name, Value);
end;

function Sum(const List: TBreakList): Double;
var
  V: Double;
  I: Integer;
  Values: TArray<Double>;
begin
  Result := 0;
  Values := List.Values.ToArray;
  for I := 0 to High(Values) do
  begin
    V := Values[I];
    Result := Result + V;
  end;
end;

function L(const ValuePct: Double): Double; inline;
begin
  Result := 1 + ValuePct;
end;

function ComputeDamage(const P: TDamagePools): TDamageResult;
var
  PoolWeapon: Double;
  PoolCrit: Double;
  Context: Double;
  PoolAmp: Double;
  ShotsPerSec: Double;
  TimeToEmpty: Double;
begin
  PoolWeapon := L(Sum(P.B_AWD) + Sum(P.B_SWD));
  PoolCrit := L(Sum(P.B_CritHead));
  Context := L(Sum(P.B_AH)) * L(Sum(P.B_OOC));
  PoolAmp := L(Sum(P.B_Amp));

  Result.Body := P.BaseDamage * PoolWeapon * Context * PoolAmp;
  Result.BodyCrit := Result.Body * PoolCrit;
  Result.Head := Result.Body * L(P.HeadDmg);
  Result.HeadCrit := Result.Head * PoolCrit;

  Result.AvgShot := (1 - P.CHC) * Result.Body + P.CHC *
    Result.BodyCrit;

  ShotsPerSec := P.RPM / 60.0;
  Result.BurstDPS := Result.AvgShot * ShotsPerSec;

  if (P.Magazine > 0) and (ShotsPerSec > 0) then
  begin
    TimeToEmpty := P.Magazine / ShotsPerSec;
    Result.SustainDPS := Result.BurstDPS *
      (TimeToEmpty / (TimeToEmpty + P.ReloadSec));
  end;
end;

// --- Helper for applying TWeaponModEffect (from mods or talents) to TDamagePools ---
// procedure ApplyModOrTalentEffectToPools(const SourceName: string; const Effect: TWeaponModEffect; IsDrawback: Boolean;
// var APools: TDamagePools);
// var
// Multiplier: Double;
procedure ApplyModOrTalentEffect(const SourceName: string;
  const Effect: TWeaponModEffect; IsDrawback: Boolean; var APools: TDamagePools;
  var FinalAcc, FinalStab, FinalOptRange: Double);
var
  Multiplier: Double;
  EffectValue: Double;
begin
  if IsDrawback then
    Multiplier := -1.0
  else
    Multiplier := 1.0;

  // --- Damage Related Stats (to APools) ---
  // Percentages are divided by 100 before being added to dictionary pools or applied as multipliers
  if Effect.WeaponDamage <> 0 then
    AddPct(APools.B_AWD, SourceName, Effect.WeaponDamage / 100.0 * Multiplier);
  if Effect.CriticalHitChance <> 0 then
    APools.CHC := APools.CHC +
      (Effect.CriticalHitChance / 100.0 * Multiplier);
  if Effect.CriticalHitDamage <> 0 then
    AddPct(APools.B_CritHead, SourceName, Effect.CriticalHitDamage / 100.0 *
      Multiplier);
  if Effect.HeadshotDamage <> 0 then
    APools.HeadDmg := APools.HeadDmg +
      (Effect.HeadshotDamage / 100.0 * Multiplier);

  // Absolute values for RateOfFire and ExtraRounds from TWeaponModEffect
  if Effect.RateOfFire <> 0 then
    APools.RPM := APools.RPM + (Effect.RateOfFire * Multiplier);
  if Effect.ExtraRounds <> 0 then
    APools.Magazine := APools.Magazine + (Effect.ExtraRounds * Multiplier);

  // ReloadTime in TWeaponModEffect is a percentage improvement/penalty to reload speed.
  // A positive value means faster reload (reduces APools.ReloadSec).
  // A negative value (from a drawback) means slower reload (increases APools.ReloadSec).
  if Effect.ReloadTime <> 0 then
    APools.ReloadSec := APools.ReloadSec *
      (1 - (Effect.ReloadTime / 100.0 * Multiplier));

  // Note: OptimalRange, Accuracy, Stability from TWeaponModEffect are not directly part of TDamagePools' DPS calculation here.
  // If TFullDamageCalcResult needs to return final handling stats, these would be accumulated into separate variables
  // that are also passed into or returned from CalculateWeaponPerformance.
  // Example: if Effect.OptimalRange <> 0 then APools.OptimalRange := APools.OptimalRange * (1 + (Effect.OptimalRange / 100.0 * Multiplier));
  // (This would require APools to have OptimalRange, Accuracy, Stability fields if they are to be modified directly)

  // --- Handling Stats (Accuracy, Stability, OptimalRange) ---
  // These are assumed to be percentage bonuses from TWeaponModEffect
  // A positive Effect.Accuracy means +X% Accuracy.
  if Effect.Accuracy <> 0 then
  begin
    EffectValue := Effect.Accuracy / 100.0 * Multiplier;
    FinalAcc := FinalAcc * (1 + EffectValue);
  end;
  if Effect.Stability <> 0 then
  begin
    EffectValue := Effect.Stability / 100.0 * Multiplier;
    FinalStab := FinalStab * (1 + EffectValue);
  end;
  if Effect.OptimalRange <> 0 then
  begin
    EffectValue := Effect.OptimalRange / 100.0 * Multiplier;
    FinalOptRange := FinalOptRange * (1 + EffectValue);
  end;
  // WeaponHandling is a general category, often a sum. If it's meant to be a direct multiplier to all,
  // it would need careful thought. For now, specific Acc/Stab/Range are handled.
  // if Effect.WeaponHandling <> 0 then ...
end;

// --- Helper for applying TAttribute (from TWeaponStat Core/Minor) to TDamagePools ---
// procedure ApplyStatAttributeToPools(const Attr: TAttribute; const SourcePrefix: string; var APools: TDamagePools);
// --- Helper for applying TAttribute (from TWeaponStat Core/Minor) to TDamagePools and Handling Stats ---
procedure ApplyStatAttribute(const Attr: TAttribute; const SourcePrefix: string;
  var APools: TDamagePools; var FinalAcc, FinalStab, FinalOptRange: Double);
var
  valFraction: Double;
  hdl: TFullDamageCalcResult;
begin
  // Most attributes from TWeaponStat are percentages.
  // Exceptions like 'RPM' or 'Magazine Size' if they were absolute would need special handling.
  // Based on weapon_stats.json, 'Rate of Fire' and 'Magazine Size' attributes ARE percentages.
  valFraction := Attr.Value / 100.0;

  if SameText(Attr.&Type, 'Critical Hit Chance') or
     SameText(Attr.&Type, 'Crit Hit Chance') then
    APools.CHC := APools.CHC + valFraction
  else if SameText(Attr.&Type, 'Critical Hit Damage') or
          SameText(Attr.&Type, 'Crit Hit Damage') then
    AddPct(APools.B_CritHead, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'Headshot Damage') then
    APools.HeadDmg := APools.HeadDmg + valFraction

    // Weapon Type Specific Damage (e.g., "Assault Rifle Damage") and Generic "Weapon Damage"
  else if SameText(Attr.&Type, 'Assault Rifle Damage') then
    AddPct(APools.B_SWD, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'SMG Damage') then
    AddPct(APools.B_SWD, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'LMG Damage') then
    AddPct(APools.B_SWD, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'Shotgun Damage') then
    AddPct(APools.B_SWD, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'Rifle Damage') then
    AddPct(APools.B_SWD, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'Marksman Rifle Damage') then
    AddPct(APools.B_SWD, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'Pistol Damage') then
    AddPct(APools.B_SWD, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'Weapon Damage') then
    AddPct(APools.B_AWD, SourcePrefix + Attr.&Type, valFraction)
    // Generic, if present

    // Contextual Damage Bonuses
  else if SameText(Attr.&Type, 'Health Damage') then
    AddPct(APools.B_AH, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'Damage to Armor') then
    AddPct(APools.B_AH, SourcePrefix + Attr.&Type, valFraction)
  else if SameText(Attr.&Type, 'DMG to target out of cover') then
    AddPct(APools.B_OOC, SourcePrefix + Attr.&Type, valFraction)

    // Attributes modifying base stats (as percentages from weapon_stats.json)
  else if SameText(Attr.&Type, 'Rate of Fire') then
    APools.RPM := APools.RPM * (1 + valFraction)
  else if SameText(Attr.&Type, 'Magazine Size') then
    APools.Magazine := APools.Magazine * (1 + valFraction)
  else if SameText(Attr.&Type, 'Reload Time') then
    APools.ReloadSec := APools.ReloadSec * (1 - valFraction)
    // Positive "Reload Time" attribute means faster reload

    // Handling attributes (Accuracy, Stability, Optimal Range from weapon_stats.json)
    // As before, these don't directly feed into TDamagePools for DPS calc but would be for display.
    // If you want CalculateWeaponPerformance to return these final values, you'd accumulate them.
    // For example:
    // else if SameText(Attr.&Type, 'Accuracy') then FinalAccuracy := FinalAccuracy * (1 + valFraction)
    // else if SameText(Attr.&Type, 'Stability') then FinalStability := FinalStability * (1 + valFraction)
  else if SameText(Attr.&Type, 'Accuracy') then
    FinalAcc := FinalAcc * (1 + valFraction)
  else if SameText(Attr.&Type, 'Stability') then
    FinalStab := FinalStab * (1 + valFraction)
  else if SameText(Attr.&Type, 'Optimal Range') then
    FinalOptRange := FinalOptRange * (1 + valFraction);
end;

function CalculateWeaponPerformance(const BaseWeapon: TWeapon;
  const WeaponArchetypeStats: TWeaponStat;
  const Selected3rdAttributeType: string; const ModBonuses: TModEffectsArray;
  // **** USE THE NEW TYPE ****
  const ModDrawbacks: TModEffectsArray; // **** USE THE NEW TYPE ****
  const SelectedTalent: TWeaponTalent; ExpertiseBonusPct: Double)
  : TFullDamageCalcResult;
var
  Pools: TDamagePools;
  DmgResultLowLevel: TDamageResult;
  LAttribute: TAttribute;
  i: Integer;
  LSlot: TModSlot;
  LWeaponOnlyCHD_Bonus_Accumulator: Double;
  LExpertiseFraction: Double;
  // Accumulators for final handling stats
  LFinalAccuracy: Double;
  LFinalStability: Double;
  LFinalOptimalRange: Double;
begin
  // ... (Implementation as previously discussed, ensuring loops for LSlot use Low(TModSlot) to High(TModSlot)
  // which is compatible with TModEffectsArray type) ...

  Pools := CalcEngine.NewPool;
  LWeaponOnlyCHD_Bonus_Accumulator := 0.0;

  LExpertiseFraction := ExpertiseBonusPct;
  if LExpertiseFraction > 1 then
    LExpertiseFraction := LExpertiseFraction / 100.0;
  if LExpertiseFraction < 0 then
    LExpertiseFraction := 0;

  // 1. Base Weapon Stats from TWeapon
  Pools.BaseDamage := BaseWeapon.Core.BaseDamage;
  if LExpertiseFraction > 0 then
    AddPct(Pools.B_AWD, 'Expertise', LExpertiseFraction);
  Pools.RPM := BaseWeapon.Core.RPM;
  Pools.Magazine := BaseWeapon.Core.MagazineSize;
  Pools.ReloadSec := BaseWeapon.Handling.ReloadTime;

  // Initialize handling accumulators with base weapon handling stats
  LFinalAccuracy := BaseWeapon.Handling.Accuracy;
  LFinalStability := BaseWeapon.Handling.Stability;
  LFinalOptimalRange := BaseWeapon.Handling.OptimalRange;
  // Note: Base ReloadSec is already in Pools.ReloadSec and will be modified by percentages

  Pools.CHC := 0;
  if BaseWeapon.Core.HeadshotDamage > 0 then
    Pools.HeadDmg := BaseWeapon.Core.HeadshotDamage / 100.0
  else
    Pools.HeadDmg := 0.0;

  // 2. Apply Attributes from WeaponArchetypeStats (TWeaponStat)
  for i := 0 to Min(1, Length(WeaponArchetypeStats.CoreAttributes) - 1) do
  begin
    // ApplyStatAttributeToPools(WeaponArchetypeStats.CoreAttributes[i], 'Core: ', Pools);
    // Core attributes typically don't modify handling stats directly in TD2, but if they could, pass handling vars here.
    ApplyStatAttribute(WeaponArchetypeStats.CoreAttributes[i], 'Core: ', Pools,
      LFinalAccuracy, LFinalStability, LFinalOptimalRange);
  end;
  if Selected3rdAttributeType <> '' then
  begin
    for i := 0 to High(WeaponArchetypeStats.MinorAttributes) do
    begin
      LAttribute := WeaponArchetypeStats.MinorAttributes[i];
      if LAttribute.&Type = Selected3rdAttributeType then
      begin
        // ApplyStatAttributeToPools(LAttribute, 'Minor: ', Pools);
        ApplyStatAttribute(LAttribute, 'Minor: ', Pools, LFinalAccuracy,
          LFinalStability, LFinalOptimalRange);
        Break;
      end;
    end;
  end;

  // 3. Apply Mod Effects
  for LSlot := Low(TModSlot) to High(TModSlot) do
  // This iterates correctly through TModSlot
  begin
    // Access ModBonuses[LSlot] and ModDrawbacks[LSlot]
    ApplyModOrTalentEffect('Mod ' + System.TypInfo.GetEnumName
      (TypeInfo(TModSlot), Ord(LSlot)) + ' Bonus', ModBonuses[LSlot], False,
      Pools, LFinalAccuracy, LFinalStability, LFinalOptimalRange);
    ApplyModOrTalentEffect('Mod ' + System.TypInfo.GetEnumName
      (TypeInfo(TModSlot), Ord(LSlot)) + ' Drawback', ModDrawbacks[LSlot], True,
      Pools, LFinalAccuracy, LFinalStability, LFinalOptimalRange);
  end;

  // 4. Apply Talent Effects
  ApplyModOrTalentEffect('Talent ' + SelectedTalent.Name, SelectedTalent.Effect,
    False, Pools, LFinalAccuracy, LFinalStability, LFinalOptimalRange);
  ApplyModOrTalentEffect('Talent ' + SelectedTalent.Name + ' Lack',
    SelectedTalent.Drawback, True, Pools, LFinalAccuracy, LFinalStability,
    LFinalOptimalRange); // Assuming Lack means drawback

  // 5. Final Adjustments
  if Pools.CHC < 0 then
    Pools.CHC := 0;
  if Pools.CHC > CAP_CHC then
    Pools.CHC := CAP_CHC;
  if Pools.ReloadSec < 0.1 then
    Pools.ReloadSec := 0.1;
  if Pools.Magazine < 1 then
    Pools.Magazine := 1;
  // Add sanity caps for handling stats if needed (e.g., Accuracy/Stability not exceeding 100% if they are % based, or practical limits)
  // For now, assuming they are direct values or correctly calculated percentages.

  // 6. Perform final DPS calculation
  DmgResultLowLevel := CalcEngine.ComputeDamage(Pools);

  Result.BurstDPS := DmgResultLowLevel.BurstDPS;
  Result.SustainDPS := DmgResultLowLevel.SustainDPS;
  Result.FinalCHC := Pools.CHC;
  Result.FinalCHD := Sum(Pools.B_CritHead);
  Result.FinalHSD := Pools.HeadDmg;
  Result.FinalRPM := Pools.RPM;
  Result.FinalMagazine := Pools.Magazine;
  Result.FinalReloadSec := Pools.ReloadSec;
  Result.FinalAccuracy := LFinalAccuracy; // Assign accumulated value
  Result.FinalStability := LFinalStability; // Assign accumulated value
  Result.FinalOptimalRange := LFinalOptimalRange; // Assign accumulated value
end;

function CalculateCompleteLoadoutPerformance(const LoadoutInput
  : TFullLoadoutInput; const AllPieceSetDefinitions
  : TDictionary<string, TPieceSet>;
  const AllWeaponStats: TDictionary<Integer, TWeaponStat>;
  const AllWeaponMods: TDictionary<Integer, TWeaponMod>;
  const AllWeaponTalents: TDictionary<Integer, TWeaponTalent>;
  out FullDamageResult: TFullDamageCalcResult;
  out AggregatedDisplayStats: TLoadoutAggregatedStats_Display): Boolean;
var
  Pools: TDamagePools;
  WeaponPerformanceResult: TFullDamageCalcResult;
  ActiveWeapon: TWeapon;
  WeaponStat: TWeaponStat;
  EquippedWeaponMods_Bonuses: TModEffectsArray;
  EquippedWeaponMods_Drawbacks: TModEffectsArray;
  ChosenWeaponTalent: TWeaponTalent;
  LSlot: TModSlot;
  LMod: TWeaponMod;
  LGearPiece: TGearPiece;
  i: Integer;
  LSpecBonusValue: Double;
  LActivatedBonusType: TWeaponFamily;
  LExpertiseFraction: Double;
  LWatchBonusValue: Double;
  FinalLowLevelDmgResult: TDamageResult;
  LGearArray: TArray<TGearPiece>;
  k: TItemTYpe;
begin
  Result := False; // Default to failure

  // --- 1. Initialize Pools and Output Stats ---
  Pools := NewPool;
  FillChar(AggregatedDisplayStats, SizeOf(AggregatedDisplayStats), 0); // Zero out display stats
  FillChar(FullDamageResult, SizeOf(FullDamageResult), 0);             // Zero out final damage result

  ActiveWeapon := LoadoutInput.ActiveWeaponConfig;

  // --- 2. Weapon Stats Integration ---
  // Fetch WeaponStat for the active weapon
  if not AllWeaponStats.TryGetValue(ActiveWeapon.StatsID, WeaponStat) then
  begin
    // Error: WeaponStat definition not found for the active weapon
    // Optionally log this error or handle it by returning False
    Exit; // Cannot proceed without weapon stat definition
  end;

  for i := 0 to High(WeaponStat.CoreAttributes) do
  begin
    var LAttribute := WeaponStat.CoreAttributes[i];
    if SameText(LAttribute.&Type, 'Assault Rifle Damage') or
       SameText(LAttribute.&Type, 'SMG Damage') or
       SameText(LAttribute.&Type, 'LMG Damage') or
       SameText(LAttribute.&Type, 'Shotgun Damage') or
       SameText(LAttribute.&Type, 'Rifle Damage') or
       SameText(LAttribute.&Type, 'Marksman Rifle Damage') or
       SameText(LAttribute.&Type, 'Pistol Damage') then
      AddPct(Pools.B_SWD, 'Weapon core: ' + LAttribute.&Type,
            LAttribute.Value / 100.0);
  end;

  // Prepare Equipped Weapon Mods (Bonuses and Drawbacks)
  for LSlot := Low(TModSlot) to High(TModSlot) do
  begin
    EquippedWeaponMods_Bonuses[LSlot] := Default (TWeaponModEffect);
    EquippedWeaponMods_Drawbacks[LSlot] := Default (TWeaponModEffect);
    if ActiveWeapon.EquippedMods[LSlot] <> 0 then
    begin
      if AllWeaponMods.TryGetValue(ActiveWeapon.EquippedMods[LSlot], LMod) then
      begin
        EquippedWeaponMods_Bonuses[LSlot] := LMod.Bonus;
        EquippedWeaponMods_Drawbacks[LSlot] := LMod.Drawback;
      end
      else
      begin
        // Error: Definition for an equipped mod not found.
        // Optionally log or handle. For now, we proceed with default (no effect) for this mod.
      end;
    end;
  end;

  // Fetch Chosen Weapon Talent
  ChosenWeaponTalent := Default (TWeaponTalent);
  // Default to no talent / no effect
  if ActiveWeapon.ChosenTalentID <> 0 then
  begin
    if not AllWeaponTalents.TryGetValue(ActiveWeapon.ChosenTalentID,
      ChosenWeaponTalent) then
    begin
      // Error: Definition for chosen talent not found.
      // Optionally log or handle. For now, proceed with default (no effect) talent.
      ChosenWeaponTalent.Effect := Default (TWeaponModEffect);
      ChosenWeaponTalent.Drawback := Default (TWeaponModEffect);
    end;
  end;

  // Call CalculateWeaponPerformance to get the weapon's standalone performance
  WeaponPerformanceResult := CalculateWeaponPerformance(ActiveWeapon,
    WeaponStat, ActiveWeapon.SelectedMinorAttributeType,
    EquippedWeaponMods_Bonuses, EquippedWeaponMods_Drawbacks,
    ChosenWeaponTalent, LoadoutInput.WeaponExpertiseLevel / 100.0
    // Assuming expertise is stored as integer 0-25, convert to fraction
    );

  // Transfer initial weapon performance to Pools and FullDamageResult (output)
  Pools.BaseDamage := ActiveWeapon.Core.BaseDamage;

  LExpertiseFraction := LoadoutInput.WeaponExpertiseLevel / 100.0;
  if LExpertiseFraction > 0 then
  begin
    AddPct(Pools.B_AWD, 'Expertise', LExpertiseFraction);
    AggregatedDisplayStats.TotalWeaponDamage_AWD_Pct_Display :=
      AggregatedDisplayStats.TotalWeaponDamage_AWD_Pct_Display +
      LExpertiseFraction;
  end;
  Pools.RPM := WeaponPerformanceResult.FinalRPM;
  Pools.Magazine := WeaponPerformanceResult.FinalMagazine;
  Pools.ReloadSec := WeaponPerformanceResult.FinalReloadSec;
  Pools.CHC := WeaponPerformanceResult.FinalCHC;
  // Weapon's own CHC contribution
  Pools.HeadDmg := WeaponPerformanceResult.FinalHSD;
  // Weapon's own HSD multiplier (e.g., 0.5 for +50% HSD)
  // Note: B_CritHead will sum CHD from all sources including weapon.
  // CalculateWeaponPerformance already adds base 0.25 and weapon's CHD.
  // We need to ensure B_CritHead in Pools starts correctly.
  // Let's assume CalculateWeaponPerformance's FinalCHD is total weapon CHD multiplier (1 + bonus)
  // and ComputeDamage expects B_CritHead to be sum of fractional bonuses.
  // So, if FinalCHD is 1.7 (base 1 + 0.25 innate + 0.45 from weapon), B_CritHead gets 0.45 from weapon.
  AddPct(Pools.B_CritHead, 'Weapon Base CHD', BASE_CHD);
  if (WeaponPerformanceResult.FinalCHD) > 0 then
    AddPct(Pools.B_CritHead, ActiveWeapon.Name + ' CHD',
      WeaponPerformanceResult.FinalCHD - BASE_CHD);


  // FullDamageResult will store final handling stats from weapon calculation
  FullDamageResult.FinalRPM := WeaponPerformanceResult.FinalRPM;
  FullDamageResult.FinalMagazine := WeaponPerformanceResult.FinalMagazine;
  FullDamageResult.FinalReloadSec := WeaponPerformanceResult.FinalReloadSec;
  FullDamageResult.FinalAccuracy := WeaponPerformanceResult.FinalAccuracy;
  FullDamageResult.FinalStability := WeaponPerformanceResult.FinalStability;
  FullDamageResult.FinalOptimalRange :=
    WeaponPerformanceResult.FinalOptimalRange;

  // Initialize display stats from weapon's direct contribution
  AggregatedDisplayStats.FinalCHC_Pct_Display := Pools.CHC;
  AggregatedDisplayStats.FinalCHD_Pct_Display := Sum(Pools.B_CritHead);
  // CHD is sum of fractions
  AggregatedDisplayStats.FinalHSD_Pct_Display := Pools.HeadDmg;
  // HSD is sum of fractions

  // --- 3. Gear Bonuses Aggregation ---
  for i := Ord(Low(LoadoutInput.EquippedGear)) to Ord(High(LoadoutInput.EquippedGear)) do
  begin
    LGearPiece := LoadoutInput.EquippedGear[TItemType(i)];
    if LGearPiece.Name <> '' then
    // Process only if a gear piece is equipped in the slot
    begin
      ApplyGearPieceBonuses(LGearPiece, 'Gear ' + IntToStr(i + 1) + ' ' +
        LGearPiece.Name, Pools, AggregatedDisplayStats);
    end;
  end;

  // --- 4. Set Bonuses Aggregation ---
  // TFullLoadoutInput.EquippedGear is array[TItemType] of TGearPiece
  // ApplySetBonuses expects array of TGearPiece.
  // We need to pass the values array or cast if it's a static array compatible with open array.
  // Since it's an enum-indexed static array, we can't pass it directly as open array of TGearPiece easily without casting or a helper.
  // Let's create a temporary dynamic array or pass slices if possible, or just change ApplySetBonuses signature.
  // Simpler: Iterate and build array.
  SetLength(LGearArray, Ord(itKneepads) + 1);
  for k := Low(TItemType) to itKneepads do
    LGearArray[Ord(k)] := LoadoutInput.EquippedGear[k];

  ApplySetBonuses(LGearArray, AllPieceSetDefinitions,
    ActiveWeapon.WeaponType, Pools, AggregatedDisplayStats);

  // --- 5. Specialization Bonuses ---
  if LoadoutInput.ChosenSpecialization.Name <> '' then
  begin
    // Apply inherent weapon type damage bonuses if activated and matching active weapon
    if Assigned(LoadoutInput.ChosenSpecialization.InherentWeaponTypeBonuses) then
    begin
      var HasMatchingSelection := False;
      if Length(LoadoutInput.ActivatedSpecWeaponTypeBonuses) > 0 then
        for i := 0 to High(LoadoutInput.ActivatedSpecWeaponTypeBonuses) do
        begin
          LActivatedBonusType := LoadoutInput.ActivatedSpecWeaponTypeBonuses[i];
          if LActivatedBonusType = ActiveWeapon.WeaponType then
          begin
            HasMatchingSelection := True;
            Break;
          end;
        end;

      if (Length(LoadoutInput.ActivatedSpecWeaponTypeBonuses) = 0) or
         HasMatchingSelection then
        if LoadoutInput.ChosenSpecialization.InherentWeaponTypeBonuses.
          TryGetValue(ActiveWeapon.WeaponType, LSpecBonusValue) then
        begin
          LSpecBonusValue := LSpecBonusValue / 100.0;
          AddPct(Pools.B_SWD, 'Spec: ' + GetEnumName(TypeInfo(TWeaponFamily),
            Ord(ActiveWeapon.WeaponType)), LSpecBonusValue);
        end;
    end;

    // Apply general bonuses from specialization
    if Assigned(LoadoutInput.ChosenSpecialization.GeneralBonuses) then
    begin
      var LBonusKeys := LoadoutInput.ChosenSpecialization.GeneralBonuses.Keys.ToArray;
      for i := 0 to High(LBonusKeys) do
      begin
        var LBonusName := LBonusKeys[i];
        LSpecBonusValue := LoadoutInput.ChosenSpecialization.GeneralBonuses
          [LBonusName] / 100.0;
        // Example: Map general bonuses to relevant pools or display stats
        if SameText(LBonusName, 'weaponDamage') then
        // If a spec gives general WD
        begin
          AddPct(Pools.B_AWD, 'Spec: General WD', LSpecBonusValue);
          AggregatedDisplayStats.TotalWeaponDamage_AWD_Pct_Display :=
            AggregatedDisplayStats.TotalWeaponDamage_AWD_Pct_Display +
            LSpecBonusValue;
        end
        else if SameText(LBonusName, 'criticalHitChance') then
        begin
          Pools.CHC := Pools.CHC + LSpecBonusValue;
          AggregatedDisplayStats.FinalCHC_Pct_Display :=
            AggregatedDisplayStats.FinalCHC_Pct_Display + LSpecBonusValue;
        end
        // Add more mappings as needed for other general spec bonuses
      end;
    end;
  end;

  // --- 6. Watch Bonuses ---
  LWatchBonusValue := LoadoutInput.WatchBonuses.WeaponDamagePct / 100.0;
  if LWatchBonusValue > 0 then
  begin
    AddPct(Pools.B_AWD, 'Watch WD', LWatchBonusValue);
    AggregatedDisplayStats.TotalWeaponDamage_AWD_Pct_Display :=
      AggregatedDisplayStats.TotalWeaponDamage_AWD_Pct_Display +
      LWatchBonusValue;
  end;

  LWatchBonusValue := LoadoutInput.WatchBonuses.CriticalHitChancePct / 100.0;
  if LWatchBonusValue > 0 then
  begin
    Pools.CHC := Pools.CHC + LWatchBonusValue;
    AggregatedDisplayStats.FinalCHC_Pct_Display :=
      AggregatedDisplayStats.FinalCHC_Pct_Display + LWatchBonusValue;
  end;

  LWatchBonusValue := LoadoutInput.WatchBonuses.CriticalHitDamagePct / 100.0;
  if LWatchBonusValue > 0 then
  begin
    AddPct(Pools.B_CritHead, 'Watch CHD', LWatchBonusValue);
    AggregatedDisplayStats.FinalCHD_Pct_Display :=
      AggregatedDisplayStats.FinalCHD_Pct_Display + LWatchBonusValue;
  end;

  LWatchBonusValue := LoadoutInput.WatchBonuses.HeadshotDamagePct / 100.0;
  if LWatchBonusValue > 0 then
  begin
    Pools.HeadDmg := Pools.HeadDmg + LWatchBonusValue;
    AggregatedDisplayStats.FinalHSD_Pct_Display :=
      AggregatedDisplayStats.FinalHSD_Pct_Display + LWatchBonusValue;
  end;

  // Add other watch bonuses (Armor, Health, Skill, Handling) to AggregatedDisplayStats as needed
  AggregatedDisplayStats.TotalArmor_Display :=
    AggregatedDisplayStats.TotalArmor_Display *
    (1 + LoadoutInput.WatchBonuses.ArmorPct / 100.0); // If watch armor is %
  AggregatedDisplayStats.TotalHealth_Display :=
    AggregatedDisplayStats.TotalHealth_Display +
    LoadoutInput.WatchBonuses.HealthPct; // If watch health is flat
  // ... etc for other watch stats affecting display ...

  // --- Sanitize Final Pool Values (especially CHC) ---
  if Pools.CHC < 0 then
    Pools.CHC := 0;
  if Pools.CHC > 0.60 then
    Pools.CHC := 0.60; // Cap CHC at 60%
  // Update display CHC after capping
  AggregatedDisplayStats.FinalCHC_Pct_Display := Pools.CHC;

  // --- 7. Final Damage Calculation ---
  FinalLowLevelDmgResult := ComputeDamage(Pools);

  // TWD = base body, non-crit, no headshot, AWD+SWD only:
  FullDamageResult.TotalWeaponDamage :=
    Pools.BaseDamage *
    (1 + Sum(Pools.B_AWD) + Sum(Pools.B_SWD));

  // --- 8. Populate Output Parameters ---
//  FullDamageResult.TotalWeaponDamage := Pools.BaseDamage * L(Sum(Pools.B_AWD) + Sum(Pools.B_SWD));
  FullDamageResult.BurstDPS := FinalLowLevelDmgResult.BurstDPS;
  FullDamageResult.SustainDPS := FinalLowLevelDmgResult.SustainDPS;
  FullDamageResult.FinalCHC := Pools.CHC; // Already capped
  FullDamageResult.FinalCHD := Sum(Pools.B_CritHead);
  FullDamageResult.FinalHSD := Pools.HeadDmg;
  FullDamageResult.FinalRPM   := Pools.RPM;
  FullDamageResult.FinalMagazine := Pools.Magazine;
  FullDamageResult.FinalReloadSec := Pools.ReloadSec;

  // Recalculate aggregate displays from final pools to avoid double counting / omissions
  AggregatedDisplayStats.TotalWeaponDamage_AWD_Pct_Display := Sum(Pools.B_AWD);
  AggregatedDisplayStats.TotalSpecificWeaponDamage_SWD_Pct_Display :=
    Sum(Pools.B_SWD);

  // AggregatedDisplayStats are already updated throughout the process for percentage bonuses.
  // FinalCHD_Pct_Display and FinalHSD_Pct_Display in AggregatedDisplayStats should reflect the sum of fractions too.
  AggregatedDisplayStats.FinalCHD_Pct_Display := FullDamageResult.FinalCHD;
  AggregatedDisplayStats.FinalHSD_Pct_Display := FullDamageResult.FinalHSD;

  Result := True; // Success
end;

function AggregatePlayerStats(const APlayerLoadout: TFullLoadoutInput;
  const AAllPieceSetDefinitions: TDictionary<string, TPieceSet>)
  : TPlayerAggregatedStats;
var
  LGearPiece: TGearPiece;
  LMinorAttr: TMinorAttribute;
  LFixedAttr: TFixedMinorAttributeDefinition;
  EquippedSetCounts: TDictionary<string, Integer>;
  LCount: Integer;
  LSetBonus: TSetBonus;
  I, J, K: Integer;
  LPairKeys: TArray<string>;
begin
  FillChar(Result, SizeOf(Result), 0);

  // 1. From Gear Minor/Mod Attributes
  for I := Ord(Low(APlayerLoadout.EquippedGear)) to Ord(High(APlayerLoadout.EquippedGear)) do
  begin
    LGearPiece := APlayerLoadout.EquippedGear[TItemType(I)];
    for J := 0 to High(LGearPiece.MinorAttributes) do
    begin
      LMinorAttr := LGearPiece.MinorAttributes[J];
      case LMinorAttr.MinorAttribute of
        madSkillDamage:
          Result.TotalSkillDamage := Result.TotalSkillDamage + LMinorAttr.Value;
        madSkillHaste:
          Result.TotalSkillHaste := Result.TotalSkillHaste + LMinorAttr.Value;
        madStatusEffects:
          Result.TotalStatusEffects := Result.TotalStatusEffects +
            LMinorAttr.Value;
        madRepairSkills:
          Result.TotalRepairSkills := Result.TotalRepairSkills +
            LMinorAttr.Value;
        // madSkillDuration: Result.TotalSkillDuration := Result.TotalSkillDuration + LMinorAttr.Value;
      end;
    end;

    for LFixedAttr in LGearPiece.FixedMinorAttributes do
    begin
      if SameText(LFixedAttr.ID, 'skillDamage') then
        Result.TotalSkillDamage := Result.TotalSkillDamage + LFixedAttr.Value
      else if SameText(LFixedAttr.ID, 'skillHaste') then
        Result.TotalSkillHaste := Result.TotalSkillHaste + LFixedAttr.Value
      else if SameText(LFixedAttr.ID, 'statusEffects') then
        Result.TotalStatusEffects := Result.TotalStatusEffects + LFixedAttr.Value
      else if SameText(LFixedAttr.ID, 'repairSkills') then
        Result.TotalRepairSkills := Result.TotalRepairSkills + LFixedAttr.Value
      else if SameText(LFixedAttr.ID, 'skillDuration') then
        Result.TotalSkillDuration := Result.TotalSkillDuration + LFixedAttr.Value
      else if SameText(LFixedAttr.ID, 'skillHealth') then
        Result.TotalSkillHealth := Result.TotalSkillHealth + LFixedAttr.Value;
    end;

    if LGearPiece.ModAttribute.ModEffect <> gmetUnknown then
    begin
      case LGearPiece.ModAttribute.ModEffect of
        gmetSkillDamage:
          Result.TotalSkillDamage := Result.TotalSkillDamage +
            LGearPiece.ModAttribute.Value;
        gmetSkillHaste:
          Result.TotalSkillHaste := Result.TotalSkillHaste +
            LGearPiece.ModAttribute.Value;
        gmetSkillDuration:
          Result.TotalSkillDuration := Result.TotalSkillDuration +
            LGearPiece.ModAttribute.Value;
      end;
    end;
  end;

  // 2. From Set Bonuses
  EquippedSetCounts := TDictionary<string, Integer>.Create;
  try
    for I := Ord(Low(APlayerLoadout.EquippedGear)) to Ord(High(APlayerLoadout.EquippedGear)) do
    begin
      LGearPiece := APlayerLoadout.EquippedGear[TItemType(I)];
      if LGearPiece.SetName <> '' then
      begin
        EquippedSetCounts.TryGetValue(LGearPiece.SetName, LCount);
        EquippedSetCounts.AddOrSetValue(LGearPiece.SetName, LCount + 1);
      end;
    end;

    LPairKeys := AAllPieceSetDefinitions.Keys.ToArray;
    for I := 0 to High(LPairKeys) do
    begin
      var LPairKey := LPairKeys[I];
      var LPairValue := AAllPieceSetDefinitions.Items[LPairKey];
      if EquippedSetCounts.TryGetValue(LPairKey, LCount) and (LCount > 0) then
        for J := 0 to High(LPairValue.Bonuses) do
        begin
          LSetBonus := LPairValue.Bonuses[J];
          if LCount >= LSetBonus.ItemsRequired then
          begin
            if SameText(LSetBonus.AttributeID, 'skill_damage') then
              Result.TotalSkillDamage := Result.TotalSkillDamage +
                LSetBonus.Value
            else if SameText(LSetBonus.AttributeID, 'skill_haste') then
              Result.TotalSkillHaste := Result.TotalSkillHaste + LSetBonus.Value
            else if SameText(LSetBonus.AttributeID, 'status_effects') then
              Result.TotalStatusEffects := Result.TotalStatusEffects +
                LSetBonus.Value
            else if SameText(LSetBonus.AttributeID, 'explosive_damage') then
              Result.TotalExplosiveDamage := Result.TotalExplosiveDamage +
                LSetBonus.Value;
          end;
        end;
    end;
  finally
    EquippedSetCounts.Free;
  end;

  // 3. From Watch Bonuses
  Result.TotalSkillDamage := Result.TotalSkillDamage +
    APlayerLoadout.WatchBonuses.SkillDamagePct;
  Result.TotalSkillHaste := Result.TotalSkillHaste +
    APlayerLoadout.WatchBonuses.SkillHastePct;
  Result.TotalSkillDuration := Result.TotalSkillDuration +
    APlayerLoadout.WatchBonuses.SkillDurationPct;
  Result.TotalRepairSkills := Result.TotalRepairSkills +
    APlayerLoadout.WatchBonuses.RepairSkillsPct;

  // Convert all totals to fractional percentages for calculation
  Result.TotalSkillDamage := Result.TotalSkillDamage / 100.0;
  Result.TotalSkillHaste := Result.TotalSkillHaste / 100.0;
  Result.TotalSkillDuration := Result.TotalSkillDuration / 100.0;
  Result.TotalSkillHealth := Result.TotalSkillHealth / 100.0;
  Result.TotalStatusEffects := Result.TotalStatusEffects / 100.0;
  Result.TotalExplosiveDamage := Result.TotalExplosiveDamage / 100.0;
  Result.TotalRepairSkills := Result.TotalRepairSkills / 100.0;
end;

function CalculateSkillPerformance(const ASkillVariant: TSkillVariant;
  const APlayerStats: TPlayerAggregatedStats; const ASkillTier: Integer;
  const AIsOvercharged: Boolean; const AIsPvp: Boolean)
  : TDictionary<string, Double>;
var
  LFinalSkillTier: Integer;
  LEffectTier: TSkillEffectTier;
  LEffectProperty: TSkillEffectProperty;
  LFinalValue: Double;
  I, J: Integer;
  Tier: TSkillEffectTier;
begin
  Result := TDictionary<string, Double>.Create;

  LFinalSkillTier := ASkillTier;
  if AIsOvercharged then
    LFinalSkillTier := 7;

  // Find the correct tier of effects
  LEffectTier := Default (TSkillEffectTier);
  for I := 0 to High(ASkillVariant.EffectsByTier) do
  begin
    Tier := ASkillVariant.EffectsByTier[I];
    if Tier.Tier = LFinalSkillTier then
    begin
      LEffectTier := Tier;
      Break;
    end;
  end;

  if LEffectTier.Tier = -1 then // Tier not found
  begin
    Exit;
  end;

  for J := 0 to High(LEffectTier.Effects) do
  begin
    LEffectProperty := LEffectTier.Effects[J];
    LFinalValue := LEffectProperty.Value;

    // Apply player stats based on the effect name
    if SameText(LEffectProperty.Name, 'damage') or
      SameText(LEffectProperty.Name, 'explosionDamage') or
      SameText(LEffectProperty.Name, 'burnDamage') then
    begin
      LFinalValue := LFinalValue * (1 + APlayerStats.TotalSkillDamage);
      if SameText(LEffectProperty.Name, 'explosionDamage') then
        LFinalValue := LFinalValue * (1 + APlayerStats.TotalExplosiveDamage);
      if SameText(LEffectProperty.Name, 'burnDamage') then
        LFinalValue := LFinalValue * (1 + APlayerStats.TotalStatusEffects);
    end
    else if SameText(LEffectProperty.Name, 'duration') or
      SameText(LEffectProperty.Name, 'burnDuration') then
    begin
      LFinalValue := LFinalValue * (1 + APlayerStats.TotalSkillDuration);
    end
    else if SameText(LEffectProperty.Name, 'cooldown') then
    begin
      LFinalValue := LFinalValue / (1 + APlayerStats.TotalSkillHaste);
    end
    else if SameText(LEffectProperty.Name, 'health') then
    begin
      LFinalValue := LFinalValue * (1 + APlayerStats.TotalSkillHealth);
    end
    else if SameText(LEffectProperty.Name, 'repair') then
    begin
      LFinalValue := LFinalValue * (1 + APlayerStats.TotalRepairSkills);
    end;

    // TODO: Add PvP modifiers here

    Result.AddOrSetValue(LEffectProperty.Name, LFinalValue);
  end;

end;

end.

