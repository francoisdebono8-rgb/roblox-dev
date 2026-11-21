-- The kits' fingerprint, headless (lune): the same KitPrint.luau as in Studio,
-- on the modules the Harness loads (tests/Harness.luau).
--   lune run tools/kits/kitprint_lune.luau > empreinte.json
--   python3 tools/kits/empreinte.py empreinte.json
local H=require("../../tests/Harness")
local KitPrint=require("./KitPrint")
local serde=require("@lune/serde")
local mods={Fighters=H.load("Shared/Fighters"),Attacks=H.load("Shared/Attacks"),Combo=H.load("Shared/BanglaCombo"),
	BetaRoster=H.load("Shared/BetaRoster"),SkillBuilds=H.load("Server/SkillBuilds"),Config=H.load("Shared/Config"),
	NinjaTree=H.load("Shared/NinjaTree")}
print(serde.encode("json",KitPrint.compute(mods),true))
