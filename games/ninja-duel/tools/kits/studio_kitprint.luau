-- The kits' fingerprint in Studio (Edit, the command bar or Roblox_Studio
-- execute_luau): paste KitPrint.luau's body in place of the line below, run,
-- and save the JSON it returns. Any place of the game (ND-JEU, ND-DEV...): the
-- modules are the same in the four.
local KitPrint=(function()
	--[[ KitPrint.luau ]]
end)()
local RS=game:GetService("ReplicatedStorage").NinjaDuel
local server=game:GetService("ServerScriptService"):FindFirstChild("NinjaDuelServer")
local mods={Fighters=require(RS.Fighters),Attacks=require(RS.Attacks),Combo=require(RS.BanglaCombo),BetaRoster=require(RS.BetaRoster),
	SkillBuilds=server and require(server.SkillBuilds)}
return game:GetService("HttpService"):JSONEncode(KitPrint.compute(mods))
