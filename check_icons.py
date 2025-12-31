import json
import os

def check_talents():
    try:
        with open('Assets/Talents.json', 'r') as f:
            data = json.load(f)

        talents = data.get('talents', {})
        brand_sets = talents.get('brandSets', {})

        vest_talents = brand_sets.get('Vest', {})

        # Check weapon_dps category where Braced is
        weapon_dps = vest_talents.get('weapon_dps', [])

        print(f"Found {len(weapon_dps)} talents in Vest/weapon_dps")

        for talent in weapon_dps:
            name = talent.get('name')
            icon = talent.get('icon')
            print(f"Talent: {name}, Icon: {icon}")

            if icon:
                # Simulate NormalizedKey logic
                # TPath.GetFileNameWithoutExtension(Def.IconFilename).Trim.ToLower
                # Python equivalent:
                base_name = os.path.splitext(os.path.basename(icon))[0].strip().lower()

                # Simulate FileToLoad logic
                # Path := .../Assets/Talents/Gears
                # FileToLoad := .../base_name + '.png'

                expected_path = os.path.join('Assets/Talents/Gears', base_name + '.png')
                if os.path.exists(expected_path):
                    print(f"  [OK] File exists: {expected_path}")
                else:
                    print(f"  [FAIL] File NOT found: {expected_path}")

                    # Check if maybe raw path exists
                    raw_path = os.path.join('Assets/Talents/Gears', os.path.basename(icon))
                    if os.path.exists(raw_path):
                         print(f"  [WARN] Raw path exists: {raw_path}")
                    else:
                         print(f"  [FAIL] Raw path also NOT found.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_talents()
