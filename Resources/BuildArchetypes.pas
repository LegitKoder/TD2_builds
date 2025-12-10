unit BuildArchetypes;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Game.Types,
  RecommendationEngine;

procedure InitArchetype(out AArchetype: TBuildArchetype);
procedure FreeArchetype(var AArchetype: TBuildArchetype);

procedure GetDpsBuildArchetype(var AArchetype: TBuildArchetype);
procedure GetTankBuildArchetype(var AArchetype: TBuildArchetype);
procedure GetSkillBuildArchetype(var AArchetype: TBuildArchetype);
procedure GetSupportBuildArchetype(var AArchetype: TBuildArchetype);

implementation

procedure InitArchetype(out AArchetype: TBuildArchetype);
begin
  FillChar(AArchetype, SizeOf(AArchetype), 0);

  // Brand / set requirements
  AArchetype.RequiredBrandSets :=
    TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);

  // Per-slot requirements
  AArchetype.RequiredTalents :=
    TDictionary<TItemType, string>.Create;
  AArchetype.RequiredAttributes :=
    TDictionary<TItemType, TArray<TMinorAttributeType>>.Create;
  AArchetype.RequiredCoreAttribute :=
    TDictionary<TItemType, TCoreAttributeType>.Create;

  // Weapons & talents & skills
  AArchetype.RequiredWeapons :=
    TDictionary<TWeaponSlot, string>.Create;

  // Allowed brands whitelist
  AArchetype.AllowedBrandSets :=
    TList<string>.Create;

  // Attribute weighting for PreFilterGear
  AArchetype.AttributeWeights :=
    TDictionary<string, Double>.Create(TIStringComparer.Ordinal);

  // Arrays / strings default to nil / ''
  SetLength(AArchetype.RequiredSkills, 0);
  SetLength(AArchetype.RequiredWeaponTalents, 0);
  SetLength(AArchetype.RequiredExotics, 0);
  AArchetype.RequiredSpecialization := '';
end;

procedure FreeArchetype(var AArchetype: TBuildArchetype);
begin
  if Assigned(AArchetype.RequiredBrandSets) then
    AArchetype.RequiredBrandSets.Free;
  if Assigned(AArchetype.RequiredTalents) then
    AArchetype.RequiredTalents.Free;
  if Assigned(AArchetype.RequiredAttributes) then
    AArchetype.RequiredAttributes.Free;
  if Assigned(AArchetype.RequiredCoreAttribute) then
    AArchetype.RequiredCoreAttribute.Free;
  if Assigned(AArchetype.RequiredWeapons) then
    AArchetype.RequiredWeapons.Free;
  if Assigned(AArchetype.AllowedBrandSets) then
    AArchetype.AllowedBrandSets.Free;
  if Assigned(AArchetype.AttributeWeights) then
    AArchetype.AttributeWeights.Free;

  FillChar(AArchetype, SizeOf(AArchetype), 0);
end;

procedure GetDpsBuildArchetype(var AArchetype: TBuildArchetype);
var
  ItemType: TItemType;
begin
  InitArchetype(AArchetype);

  // Example: enforce WD core on all 6 slots
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredCoreAttribute.Add(ItemType, catWeaponDamage);

  // Example brand requirement (keys must match canonical brand names)
  // AArchetype.RequiredBrandSets.Add('Providence Defense', 3);

  // Minor attributes we care about most (used by PreFilterGear weighting)
  // These keys should match AttributeID patterns from your JSON
  AArchetype.AttributeWeights.Add('criticalHitChance',       1.0);
  AArchetype.AttributeWeights.Add('criticalHitDamage',       0.95);
  AArchetype.AttributeWeights.Add('headshotDamage',          0.60);
  AArchetype.AttributeWeights.Add('damageToArmor',           0.45);
  AArchetype.AttributeWeights.Add('damageToTargetOutOfCover',0.80);
  AArchetype.AttributeWeights.Add('weaponDamage',            0.70);

  // Optionally enforce required minors per slot
  // Example: all pieces prefer CHC/CHD
  {
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredAttributes.Add(ItemType,
      TArray<TMinorAttributeType>.Create(
        madCriticalHitChance,
        madCriticalHitDamage
      ));
  }
end;

procedure GetTankBuildArchetype(var AArchetype: TBuildArchetype);
var
  ItemType: TItemType;
begin
  InitArchetype(AArchetype);

  // All cores = Armor
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredCoreAttribute.Add(ItemType, catArmor);

  // Example tanky brand
  // AArchetype.RequiredBrandSets.Add('Gila Guard', 3);

  // Tank weights – defensive stuff
  AArchetype.AttributeWeights.Add('armor',             1.0);
  AArchetype.AttributeWeights.Add('health',            0.9);
  AArchetype.AttributeWeights.Add('armorRegen',        0.8);
  AArchetype.AttributeWeights.Add('hazardProtection',  0.7);
  AArchetype.AttributeWeights.Add('explosiveResistance', 0.6);
  AArchetype.AttributeWeights.Add('incomingRepairs',   0.4);

  // Example: prefer defensive minors everywhere
  {
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredAttributes.Add(ItemType,
      TArray<TMinorAttributeType>.Create(
        madArmorRegen,
        madHealth
      ));
  }
end;

procedure GetSkillBuildArchetype(var AArchetype: TBuildArchetype);
var
  ItemType: TItemType;
begin
  InitArchetype(AArchetype);

  // All cores = Skill Tier
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredCoreAttribute.Add(ItemType, catSkillTier);

  // Example brand
  // AArchetype.RequiredBrandSets.Add('Hana-U Corporation', 3);

  // Skill weights
  AArchetype.AttributeWeights.Add('skillDamage',      1.0);
  AArchetype.AttributeWeights.Add('skillHaste',       0.9);
  AArchetype.AttributeWeights.Add('statusEffects',    0.7);
//  AArchetype.AttributeWeights.Add('repairSkills',     0.5);
  AArchetype.AttributeWeights.Add('skillDuration',    0.4);
//  AArchetype.AttributeWeights.Add('skillHealth',      0.3);

  {
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredAttributes.Add(ItemType,
      TArray<TMinorAttributeType>.Create(
        madSkillDamage,
        madSkillHaste
      ));
  }
end;

procedure GetSupportBuildArchetype(var AArchetype: TBuildArchetype);
var
  ItemType: TItemType;
begin
  InitArchetype(AArchetype);

  // Support: mix of Skill Tier and maybe a couple of Armor cores (optional)
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredCoreAttribute.Add(ItemType, catSkillTier);

  // Example brand
  // AArchetype.RequiredBrandSets.Add('Alps Summit Armament', 3);

  // Support weights (heals, haste, status)
  AArchetype.AttributeWeights.Add('repairSkills',     1.0);
  AArchetype.AttributeWeights.Add('incomingRepairs',  0.8);
  AArchetype.AttributeWeights.Add('skillHaste',       0.8);
//  AArchetype.AttributeWeights.Add('statusEffects',    0.6);
  AArchetype.AttributeWeights.Add('skillDuration',    0.5);
  AArchetype.AttributeWeights.Add('skillHealth',      0.3);

  {
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredAttributes.Add(ItemType,
      TArray<TMinorAttributeType>.Create(
        madRepairSkills,
        madSkillHaste
      ));
  }
end;

end.

