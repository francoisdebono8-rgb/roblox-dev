-- Semantic bindings shared by client, HUD and QA.
-- Keyboard is grouped around WASD so combat never needs a reach across the board;
-- PS5: the face buttons keep the existing layout; R1 modifies jutsu.
local Controls = {
	Keyboard = {
		-- Home row first: the actions used constantly sit under the left hand and
		-- the mouse, and substitution stays deliberately out of the way on X.
		Light = Enum.UserInputType.MouseButton1,
		Heavy = Enum.UserInputType.MouseButton2,
		Jump = Enum.KeyCode.Space,
		Dodge = Enum.KeyCode.Q,
		Guard = Enum.KeyCode.F,
		Grab = Enum.KeyCode.V,
		Tool = Enum.KeyCode.R,
		Pursuit = Enum.KeyCode.E,
		Substitute = Enum.KeyCode.X,
		Feint = Enum.KeyCode.G,
		WallDetach = Enum.KeyCode.C,
		Lock = Enum.KeyCode.LeftShift,
		Sprint = Enum.KeyCode.LeftControl,
		Technique5 = Enum.KeyCode.Five,
		Awaken = Enum.KeyCode.T,
		Skip = Enum.KeyCode.Escape,
	},
	Gamepad = {
		Light = Enum.KeyCode.ButtonX,
		Heavy = Enum.KeyCode.ButtonY,
		Jump = Enum.KeyCode.ButtonA,
		Dodge = Enum.KeyCode.ButtonB,
		Guard = Enum.KeyCode.ButtonL1,
		Tool = Enum.KeyCode.ButtonR2,
		Grab = Enum.KeyCode.ButtonL2,
		Lock = Enum.KeyCode.ButtonR3,
		Sprint = Enum.KeyCode.ButtonL3,
		Modifier = Enum.KeyCode.ButtonR1,
		Technique5 = Enum.KeyCode.DPadUp,
		Awaken = Enum.KeyCode.DPadDown,
		Rush = Enum.KeyCode.DPadLeft,
		Substitute = Enum.KeyCode.DPadRight,
		Skip = Enum.KeyCode.ButtonSelect,
	},
	-- Human-readable key names so HUD and tutorial copy cannot drift from bindings.
	KeyLabel = {
		Light = "LMB", Heavy = "RMB", Jump = "SPACE", Dodge = "Q", Guard = "F",
		Grab = "V", Tool = "R", Pursuit = "E", Substitute = "X", Feint = "G",
		WallDetach = "C", Lock = "SHIFT", Sprint = "CTRL", Technique5 = "5", Awaken = "T", Skip = "ESC",
	},
	-- HUD copy for the keyboard layout, kept next to the bindings it documents.
	Hint = "LMB light \u{00B7} RMB heavy",
	Help = "WASD move   SPACE jump   Q dodge   LMB light   RMB heavy   F guard   V grab / throw break   E chase / chakra dash   R tool   X substitute   G feint   T awaken   CTRL sprint   SHIFT lock   1-5 jutsu",
	-- The directional combo grammar, shared by every fighter.
	Grammar = "CLEAN HITS  2 hits → toward + LMB: launch · away + LMB: sweep  |  1 hit → side + LMB: angle  |  air hit → direction + LMB: drive / spike / switch  |  away + R in a string: retreat",
	GrammarPad = "CLEAN HITS  2 hits → toward + □: launch · away + □: sweep  |  1 hit → side + □: angle  |  air hit → direction + □: drive / spike / switch  |  away + R2 in a string: retreat",
	HelpPad = "L move · L3 sprint   R camera · R3 lock   □ light   △ heavy   ○ dodge / escape   × jump / chase   L1 guard   L2 grab   R2 tool   R1 + face: jutsu   D-pad ← rush · → escape · ↓ awaken · ↑ jutsu 5",
	PadLabel = {Light="□",Heavy="△",Dodge="○",Jump="×",Guard="L1",Modifier="R1",Grab="L2",Tool="R2",Sprint="L3",Lock="R3",Pursuit="×",Substitute="D-pad →",Feint="R1 + L2",WallDetach="R1 + L1"},
	TechniquePad = {"R1 + ×","R1 + □","R1 + △","R1 + ○","D-pad ↑"},
}

function Controls.comboHelp(graph,pad)
 local light=if pad then "□" else "LMB"
 local tool=if pad then "R2" else "R"
 local routes=graph.routes or {}
 local parts={"CLEAN HITS"}
 if routes.up then table.insert(parts,"2 hits → toward + "..light..": launch") end
 if routes.down then table.insert(parts,"2 hits → away + "..light..": sweep") end
 if routes.side then table.insert(parts,"1 hit → side + "..light..": angle") end
 local air={}
 if routes.airUp then table.insert(air,"toward: drive") end
 if routes.airDown then table.insert(air,"away: spike") end
 if routes.airSide then table.insert(air,"side: switch") end
 if #air>0 then table.insert(parts,"Air hit + "..light.." → "..table.concat(air," / ")) end
 if graph.disengage then table.insert(parts,"away + "..tool.." in string: retreat") end
 return table.concat(parts,"  ·  ")
end
function Controls.isGamepad(kind)
 return kind~=nil and kind.Name:match("^Gamepad")~=nil
end
return Controls
