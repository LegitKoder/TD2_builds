unit BuildArchetypes;

interface

uses
  System.SysUtils, System.Generics.Collections, Game.Types, RecommendationEngine;

procedure GetDpsBuildArchetype(var AArchetype: TBuildArchetype);
procedure GetTankBuildArchetype(var AArchetype: TBuildArchetype);
procedure GetSkillBuildArchetype(var AArchetype: TBuildArchetype);
procedure GetSupportBuildArchetype(var AArchetype: TBuildArchetype);

implementation

procedure GetDpsBuildArchetype(var AArchetype: TBuildArchetype);
var
  ItemType: TItemType;
begin
//  AArchetype.RequiredBrandSets.Add('Providence Defense', 3);
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredCoreAttribute.Add(ItemType, catWeaponDamage);
end;

procedure GetTankBuildArchetype(var AArchetype: TBuildArchetype);
var
  ItemType: TItemType;
begin
//  AArchetype.RequiredBrandSets.Add('Gila Guard', 3);
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredCoreAttribute.Add(ItemType, catArmor);
end;

procedure GetSkillBuildArchetype(var AArchetype: TBuildArchetype);
var
  ItemType: TItemType;
begin
//  AArchetype.RequiredBrandSets.Add('Hana-U Corporation', 3);
  for ItemType := Low(TItemType) to itKneepads do
    AArchetype.RequiredCoreAttribute.Add(ItemType, catSkillTier);
end;

procedure GetSupportBuildArchetype(var AArchetype: TBuildArchetype);
begin
//  AArchetype.RequiredBrandSets.Add('Alps Summit Armament', 3);
end;

end.
