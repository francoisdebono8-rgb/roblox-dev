-- FILM01 shot maps v2, one per take (A = Minato, B = Neji, S = the planted seal).
-- v1 review (05/11): fits of two bodies 15-20 studs apart are tiny in 9:16, the
-- sun and the bloom washed the frames, the seal close-up hid Neji. v2: singles
-- while they are apart, two-shots once Minato has arrived, the lens on the
-- side away from the sun, a light bloom, the seal low with Neji walking in.
_G.NDFilm01 = {
	T1 = { -- master: geography (both bodies, the seal)
		faceoff = {kind = "fit", yaw = 0, pitch = 8},
		throw = {kind = "fit", who = "ABS", yaw = 10, pitch = 10},
		bait = {kind = "fit", who = "ABS", yaw = 25, pitch = 12},
		teleport = {kind = "fit", who = "ABS", yaw = 40, pitch = 14},
		counter = {kind = "fit", who = "ABX", yaw = 30, pitch = 22, m = 0.8},
		after = {kind = "fit", yaw = 10, pitch = 16, m = 0.8},
		default = {kind = "fit"},
	},
	T2 = { -- singles, then the arrival two-shot
		faceoff = {kind = "close", who = "A", ang = 36},
		throw = {kind = "track", who = "A", yaw = -6},
		bait = {kind = "close", who = "B", ang = 24},
		teleport = {seq = {{at = 0, kind = "close", who = "B", ang = 30}, {at = 0.12, kind = "fit", yaw = 25, pitch = 4, m = 0.92}}},
		counter = {kind = "fit", yaw = -15, pitch = 6, m = 0.86},
		after = {kind = "fit", yaw = 20, pitch = 10, m = 0.82},
		default = {kind = "fit"},
	},
	T3 = { -- specials: the seal low with Neji behind (the hook), the dome from above
		faceoff = {kind = "close", who = "B", ang = 38},
		throw = {kind = "fit", who = "ABS", yaw = -25, pitch = 6},
		bait = {kind = "seal", dist = 2.0, off = 0.3, h = 0.6, lift = 0.55, fov = 50},
		teleport = {seq = {{at = 0, kind = "seal", dist = 2.0, off = 0.3, h = 0.6, lift = 0.55, fov = 50}, {at = 0.12, kind = "fit", yaw = 35, pitch = 8, m = 0.9}}},
		counter = {kind = "fit", who = "ABX", top = true, pitch = 78, m = 0.78},
		after = {kind = "fit", yaw = 45, pitch = 24, m = 0.8},
		default = {kind = "fit"},
	},
	T4 = { -- second angles
		faceoff = {kind = "fit", yaw = 15, pitch = 4},
		throw = {kind = "track", who = "A", yaw = 12, pitch = 2},
		bait = {kind = "seal", dist = 2.6, off = -0.6, h = 0.5, lift = 0.5, fov = 46},
		teleport = {seq = {{at = 0, kind = "fit", who = "BS", yaw = 50, pitch = 10, m = 0.8}, {at = 0.12, kind = "fit", yaw = 55, pitch = 10, m = 0.9}}},
		counter = {kind = "fit", yaw = 0, pitch = 10, m = 0.84},
		after = {kind = "fit", yaw = -20, pitch = 12, m = 0.8},
		default = {kind = "fit"},
	},
}
return "maps ready"
