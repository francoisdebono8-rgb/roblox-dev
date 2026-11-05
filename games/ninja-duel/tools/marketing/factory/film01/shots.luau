-- FILM01 shot maps, one per take (A = Minato, B = Neji, S = the planted seal).
-- T1/T2 cover every plan once, T3/T4 give the second take of each plan from
-- another angle; all lenses stay on one side of the opening fight line.
_G.NDFilm01 = {
	T1 = { -- master: both bodies whole
		faceoff = {kind = "fit", yaw = 0, pitch = 6},
		throw = {kind = "fit", who = "ABS", yaw = 10, pitch = 8},
		bait = {kind = "fit", who = "ABS", yaw = 20, pitch = 10},
		teleport = {kind = "fit", who = "ABS", yaw = 40, pitch = 12},
		counter = {kind = "fit", who = "ABX", yaw = 30, pitch = 20, m = 0.8},
		after = {kind = "fit", yaw = 10, pitch = 16, m = 0.78},
		default = {kind = "fit"},
	},
	T2 = { -- closer
		faceoff = {kind = "close", who = "B", ang = 38},
		throw = {kind = "track", who = "A", yaw = -6},
		bait = {kind = "ots", who = "B", ang = 30},
		teleport = {kind = "fit", yaw = 25, pitch = 4, m = 0.9},
		counter = {kind = "fit", yaw = -15, pitch = -4, m = 0.86},
		after = {kind = "close", who = "B", ang = 34},
		default = {kind = "fit"},
	},
	T3 = { -- specials: the seal close-up (hook), overhead dome
		faceoff = {kind = "close", who = "A", ang = 36},
		throw = {kind = "fit", who = "ABS", yaw = -25, pitch = 4},
		bait = {kind = "seal", dist = 3.4, off = 0.8, h = 0.9, lift = 0.22},
		teleport = {kind = "fit", who = "BS", yaw = 50, pitch = 8, m = 0.8},
		counter = {kind = "fit", who = "ABX", top = true, pitch = 78, m = 0.78},
		after = {kind = "fit", yaw = 45, pitch = 24, m = 0.8},
		default = {kind = "fit"},
	},
	T4 = { -- second angles
		faceoff = {kind = "fit", yaw = 15, pitch = 4},
		throw = {kind = "fit", who = "ABS", yaw = 5, pitch = 6, m = 0.78},
		bait = {kind = "seal", dist = 2.6, off = -0.8, h = 0.6, lift = 0.3},
		teleport = {kind = "fit", who = "ABS", yaw = 55, pitch = 14},
		counter = {kind = "fit", yaw = 0, pitch = 10, m = 0.84},
		after = {kind = "fit", yaw = -20, pitch = 12, m = 0.78},
		default = {kind = "fit"},
	},
}
return "maps ready"
