unit Game.AttributeMapper;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  Game.Types;

type
  EUnknownAttribute = class(Exception);

  TAttributeMapper = class
  private
    class var FToEnum: TDictionary<string, TAttributeID>;
    class var FDisplayNames: array[TAttributeID] of string;
    class procedure RegisterAttribute(AttrID: TAttributeID; const Names: array of string); static;
  public
    class constructor Create;
    class destructor Destroy;
    class function Parse(const S: string): TAttributeID; static;
    class function TryParse(const S: string; out AttrID: TAttributeID): Boolean; static;
    class function DisplayName(AttrID: TAttributeID): string; static;
  end;

implementation

uses
  Utils;

class procedure TAttributeMapper.RegisterAttribute(
  AttrID: TAttributeID; const Names: array of string);
var
  Name: string;
begin
  for Name in Names do
    FToEnum.AddOrSetValue(Name, AttrID);
end;

class constructor TAttributeMapper.Create;
begin
  FToEnum := TDictionary<string, TAttributeID>.Create(TIStringComparer.Ordinal);

  RegisterAttribute(atCriticalHitChance, [
    'critical_hit_chance', 'criticalHitChance', 'Critical Hit Chance',
    'Crit Hit Chance', 'CHC', 'criticalhitchance'
  ]);
  FDisplayNames[atCriticalHitChance] := 'Critical Hit Chance';

  RegisterAttribute(atCriticalHitDamage, [
    'critical_hit_damage', 'criticalHitDamage', 'Critical Hit Damage',
    'Crit Hit Damage', 'CHD', 'criticalhitdamage'
  ]);
  FDisplayNames[atCriticalHitDamage] := 'Critical Hit Damage';

  RegisterAttribute(atHeadshotDamage, [
    'headshot_damage', 'headshotDamage', 'Headshot Damage',
    'HSD', 'headshotdamage'
  ]);
  FDisplayNames[atHeadshotDamage] := 'Headshot Damage';

  RegisterAttribute(atWeaponDamage, [
    'weapon_damage', 'weaponDamage', 'Weapon Damage', 'weapondamage'
  ]);
  FDisplayNames[atWeaponDamage] := 'Weapon Damage';

  RegisterAttribute(atAssaultRifleDamage, [
    'assault_rifle_damage', 'assaultRifleDamage', 'Assault Rifle Damage',
    'AR Damage', 'assaultrifledamage'
  ]);
  FDisplayNames[atAssaultRifleDamage] := 'Assault Rifle Damage';

  RegisterAttribute(atSMGDamage, [
    'smg_damage', 'smgDamage', 'SMG Damage', 'smgdamage'
  ]);
  FDisplayNames[atSMGDamage] := 'SMG Damage';

  RegisterAttribute(atLMGDamage, [
    'lmg_damage', 'lmgDamage', 'LMG Damage', 'lmgdamage'
  ]);
  FDisplayNames[atLMGDamage] := 'LMG Damage';

  RegisterAttribute(atShotgunDamage, [
    'shotgun_damage', 'shotgunDamage', 'Shotgun Damage',
    'STG Damage', 'shotgundamage'
  ]);
  FDisplayNames[atShotgunDamage] := 'Shotgun Damage';

  RegisterAttribute(atRifleDamage, [
    'rifle_damage', 'rifleDamage', 'Rifle Damage', 'rifledamage'
  ]);
  FDisplayNames[atRifleDamage] := 'Rifle Damage';

  RegisterAttribute(atMMRDamage, [
    'marksman_rifle_damage', 'marksmanRifleDamage', 'MMR Damage',
    'Marksman Rifle Damage', 'marksmanrifledamage'
  ]);
  FDisplayNames[atMMRDamage] := 'Marksman Rifle Damage';

  RegisterAttribute(atPistolDamage, [
    'pistol_damage', 'pistolDamage', 'Pistol Damage', 'pistoldamage'
  ]);
  FDisplayNames[atPistolDamage] := 'Pistol Damage';

  RegisterAttribute(atDamageToArmor, [
    'damage_to_armor', 'damageToArmor', 'Damage to Armor',
    'DTA', 'damagetoarmor'
  ]);
  FDisplayNames[atDamageToArmor] := 'Damage to Armor';

  RegisterAttribute(atHealthDamage, [
    'health_damage', 'healthDamage', 'damage_to_health', 'damageToHealth',
    'Health Damage', 'DTH', 'healthdamage', 'damagetohealth'
  ]);
  FDisplayNames[atHealthDamage] := 'Health Damage';

  RegisterAttribute(atDamageOutOfCover, [
    'damage_out_of_cover', 'damageOutOfCover',
    'DMG to target out of cover', 'Damage To Target Out of Cover',
    'DTTOOC', 'OOC', 'damagetotargetoutofcover', 'damageoutofcover'
  ]);
  FDisplayNames[atDamageOutOfCover] := 'Damage to Targets Out of Cover';

  RegisterAttribute(atHealth, [
    'health', 'Health'
  ]);
  FDisplayNames[atHealth] := 'Health';

  RegisterAttribute(atArmor, [
    'armor', 'Armor', 'total_armor', 'totalArmor'
  ]);
  FDisplayNames[atArmor] := 'Armor';

  RegisterAttribute(atArmorRegen, [
    'armor_regen', 'armorRegen', 'armorRegen_0', 'armorRegen_1',
    'Armor Regeneration', 'armorregen', 'armorregenpct', 'armor_regen_pct'
  ]);
  FDisplayNames[atArmorRegen] := 'Armor Regeneration';

  RegisterAttribute(atArmorOnKill, [
    'armor_on_kill', 'armorOnKill', 'Armor On Kill', 'armoronkill'
  ]);
  FDisplayNames[atArmorOnKill] := 'Armor on Kill';

  RegisterAttribute(atHealthOnKill, [
    'health_on_kill', 'healthOnKill', 'Health On Kill', 'healthonkill'
  ]);
  FDisplayNames[atHealthOnKill] := 'Health on Kill';

  RegisterAttribute(atHazardProtection, [
    'hazard_protection', 'hazardProtection', 'Hazard Protection', 'hazardprotection'
  ]);
  FDisplayNames[atHazardProtection] := 'Hazard Protection';

  RegisterAttribute(atExplosiveResistance, [
    'explosive_resistance', 'explosiveResistance', 'Explosive Resistance',
    'explosiveresistance'
  ]);
  FDisplayNames[atExplosiveResistance] := 'Explosive Resistance';

  RegisterAttribute(atIncomingRepairs, [
    'incoming_repairs', 'incomingRepairs', 'Incoming Repairs', 'incomingrepairs'
  ]);
  FDisplayNames[atIncomingRepairs] := 'Incoming Repairs';

  RegisterAttribute(atSkillTier, [
    'skill_tier', 'skillTier', 'Skill Tier', 'skilltier'
  ]);
  FDisplayNames[atSkillTier] := 'Skill Tier';

  RegisterAttribute(atSkillDamage, [
    'skill_damage', 'skillDamage', 'Skill Damage', 'skilldamage'
  ]);
  FDisplayNames[atSkillDamage] := 'Skill Damage';

  RegisterAttribute(atSkillHaste, [
    'skill_haste', 'skillHaste', 'Skill Haste', 'skillhaste'
  ]);
  FDisplayNames[atSkillHaste] := 'Skill Haste';

  RegisterAttribute(atSkillDuration, [
    'skill_duration', 'skillDuration', 'Skill Duration', 'skillduration'
  ]);
  FDisplayNames[atSkillDuration] := 'Skill Duration';

  RegisterAttribute(atRepairSkills, [
    'repair_skills', 'repairSkills', 'Repair Skills', 'repairskills'
  ]);
  FDisplayNames[atRepairSkills] := 'Repair Skills';

  RegisterAttribute(atStatusEffects, [
    'status_effects', 'statusEffects', 'statusEffects_0', 'statusEffects_1',
    'Status Effects', 'statuseffects'
  ]);
  FDisplayNames[atStatusEffects] := 'Status Effects';

  RegisterAttribute(atSkillHealth, [
    'skill_health', 'skillHealth', 'Skill Health', 'skillhealth'
  ]);
  FDisplayNames[atSkillHealth] := 'Skill Health';

  RegisterAttribute(atExplosiveDamage, [
    'explosive_damage', 'explosiveDamage', 'Explosive Damage', 'explosivedamage'
  ]);
  FDisplayNames[atExplosiveDamage] := 'Explosive Damage';

  RegisterAttribute(atAccuracy, [
    'accuracy', 'Accuracy'
  ]);
  FDisplayNames[atAccuracy] := 'Accuracy';

  RegisterAttribute(atStability, [
    'stability', 'Stability'
  ]);
  FDisplayNames[atStability] := 'Stability';

  RegisterAttribute(atReloadSpeed, [
    'reload_speed', 'reloadSpeed', 'Reload Speed', 'Reload Time',
    'reloadspeed', 'reloadtime'
  ]);
  FDisplayNames[atReloadSpeed] := 'Reload Speed';

  RegisterAttribute(atOptimalRange, [
    'optimal_range', 'optimalRange', 'Optimal Range', 'optimalrange'
  ]);
  FDisplayNames[atOptimalRange] := 'Optimal Range';

  RegisterAttribute(atWeaponHandling, [
    'weapon_handling', 'weaponHandling', 'Weapon Handling', 'weaponhandling'
  ]);
  FDisplayNames[atWeaponHandling] := 'Weapon Handling';

  RegisterAttribute(atSwapSpeed, [
    'swap_speed', 'swapSpeed', 'Swap Speed', 'swapspeed'
  ]);
  FDisplayNames[atSwapSpeed] := 'Swap Speed';

  RegisterAttribute(atMagazineSize, [
    'magazine_size', 'magazineSize', 'Magazine Size', 'magazinesize'
  ]);
  FDisplayNames[atMagazineSize] := 'Magazine Size';

  RegisterAttribute(atRateOfFire, [
    'rate_of_fire', 'rateOfFire', 'Rate Of Fire', 'ROF', 'rateoffire'
  ]);
  FDisplayNames[atRateOfFire] := 'Rate of Fire';

  RegisterAttribute(atAmmoCapacity, [
    'ammo_capacity', 'ammoCapacity', 'Ammo Capacity', 'ammocapacity'
  ]);
  FDisplayNames[atAmmoCapacity] := 'Ammo Capacity';
end;

class destructor TAttributeMapper.Destroy;
begin
  FToEnum.Free;
end;

class function TAttributeMapper.Parse(const S: string): TAttributeID;
begin
  if not TryParse(S, Result) then
    raise EUnknownAttribute.CreateFmt('Unknown attribute: "%s"', [S]);
end;

class function TAttributeMapper.TryParse(const S: string;
  out AttrID: TAttributeID): Boolean;
var
  Normalized: string;
  Cleaned: string;
begin
  Result := False;
  AttrID := atNone;

  if S = '' then
    Exit;

  if FToEnum.TryGetValue(S, AttrID) then
    Exit(True);

  Cleaned := RemoveAttributeSuffix(S);
  if FToEnum.TryGetValue(Cleaned, AttrID) then
    Exit(True);

  Normalized := NormalizeAttrId(Cleaned);
  if FToEnum.TryGetValue(Normalized, AttrID) then
    Exit(True);
end;

class function TAttributeMapper.DisplayName(AttrID: TAttributeID): string;
begin
  Result := FDisplayNames[AttrID];
end;

end.
