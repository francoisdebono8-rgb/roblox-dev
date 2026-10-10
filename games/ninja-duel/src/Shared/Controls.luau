-- Semantic bindings shared by client, HUD and QA.
-- Keyboard is grouped around WASD so combat never needs a reach across the board;
-- the face buttons keep the existing gamepad layout and RB remains the jutsu modifier.
return {
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
		Skip = Enum.KeyCode.ButtonSelect,
	},
	-- Human-readable key names so HUD and tutorial copy cannot drift from bindings.
	KeyLabel = {
		Light = "LMB", Heavy = "RMB", Jump = "SPACE", Dodge = "Q", Guard = "F",
		Grab = "V", Tool = "R", Pursuit = "E", Substitute = "X", Feint = "G",
		WallDetach = "C", Lock = "SHIFT", Sprint = "CTRL", Technique5 = "5", Skip = "ESC",
	},
	-- HUD copy for the keyboard layout, kept next to the bindings it documents.
	Hint = "LMB light \u{00B7} RMB heavy",
	Help = "WASD move   SPACE jump / wall rebound   Q dodge   LMB light   RMB heavy   F guard   V grab   E chase   R tool   X substitute   G feint   C wall detach   CTRL sprint   SHIFT lock   1-5 jutsu",
	HelpPad = "LS move / sprint   RS camera / lock   X light   Y heavy   B dodge   A jump / chase   LB guard   LT grab   RT tool   RB + face jutsu   D-pad up = jutsu 5",
}
