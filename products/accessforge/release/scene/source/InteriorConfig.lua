-- InteriorConfig - shared contract for Session 5A "InteriorWorld + Endgame Loop".
--
-- Pure data + pure layout math (no instances, no side effects). Every Session-5A
-- module reads its world coordinates, colors, rank thresholds, endgame timings and
-- DataStore keys from here so there are no magic numbers duplicated across modules
-- and the 8 buildings / tunnels / orb / boards never disagree on where things are.
--
-- World facts it builds on (from WorldLayout / MapBuilder, NOT modified):
--   * Core at origin; Nexus plaza ~150x150 (floor top y~1); 6 district kiosks named
--     Kiosk_<NAME> at radius 60, angle math.rad(30 + (i-1)*60) in this order:
--     1 EXCHANGE, 2 /root, 3 BREACH, 4 COLLECTIVE, 5 ARENA, 6 TRADING.
--   * Per-player plots on the ring at radius 160. Baseplate top y=0 spans +/-1024.
-- So the 8 buildings sit OUT past the plot ring (radius ~225) on the baseplate,
-- each aligned to its district angle with its door facing the Core.

local InteriorConfig = {}

----------------------------------------------------------------------
-- Palette
----------------------------------------------------------------------
InteriorConfig.GOLD = Color3.fromRGB(255, 215, 0)
InteriorConfig.DARK = Color3.fromRGB(12, 14, 20)

----------------------------------------------------------------------
-- Buildings (8). angleDeg/radius place the building on the baseplate; the door
-- faces the Core. `size` is the interior box (X wide, Y tall, Z deep). `kind`
-- tells the per-building builder which themed interior to assemble.
----------------------------------------------------------------------
-- District buildings sit at radius 260 so even the deepest (Exchange, depth 110)
-- has its inner edge at ~205 - clear of the plot ring (plots span radius 140-180)
-- and the dino patrol path (radius 150). Adjacent buildings are 60deg apart (~260
-- studs between centres), so widths up to ~110 leave a comfortable gap.
InteriorConfig.BUILD_RADIUS = 260

InteriorConfig.Buildings = {
	{ key = "EXCHANGE",   district = "EXCHANGE",   angleDeg = 30,  radius = 260, size = Vector3.new(110, 58, 110), color = Color3.fromRGB(255, 160, 0),   sign = "THE EXCHANGE",     kind = "exchange",   deadEnd = false, secretRoom = true },
	{ key = "ROOT",       district = "/root",      angleDeg = 90,  radius = 260, size = Vector3.new(80, 26, 80),   color = Color3.fromRGB(0, 255, 120),   sign = "/root ACCESS",     kind = "root",       deadEnd = true,  secretRoom = false },
	{ key = "BREACH",     district = "BREACH",     angleDeg = 150, radius = 260, size = Vector3.new(82, 26, 82),   color = Color3.fromRGB(255, 40, 90),   sign = "THE BREACH HQ",    kind = "breach",     deadEnd = true,  secretRoom = true },
	{ key = "COLLECTIVE", district = "COLLECTIVE", angleDeg = 210, radius = 260, size = Vector3.new(86, 28, 86),   color = Color3.fromRGB(255, 0, 200),   sign = "THE COLLECTIVE",   kind = "collective", deadEnd = true,  secretRoom = false },
	{ key = "ARENA",      district = "ARENA",      angleDeg = 270, radius = 260, size = Vector3.new(96, 34, 96),   color = Color3.fromRGB(235, 235, 255), sign = "THE ARENA LOBBY",  kind = "arena",      deadEnd = true,  secretRoom = false },
	{ key = "TRADING",    district = "TRADING",    angleDeg = 330, radius = 260, size = Vector3.new(92, 26, 96),   color = Color3.fromRGB(0, 200, 255),   sign = "TRADING POST",     kind = "trading",    deadEnd = true,  secretRoom = false },
	{ key = "VOID",       district = nil,          angleDeg = 0,   radius = 255, size = Vector3.new(46, 22, 46),   color = Color3.fromRGB(16, 16, 22),    sign = "",                 kind = "void",       deadEnd = true,  secretRoom = false },
	-- UNMARKED: no exterior sign, pushed way out behind the BREACH/COLLECTIVE arc and
	-- rotated so its door faces AWAY from the plaza = easy to miss (see `hidden`).
	{ key = "UNMARKED",   district = nil,          angleDeg = 180, radius = 320, size = Vector3.new(50, 22, 56),   color = Color3.fromRGB(40, 42, 54),    sign = "",                 kind = "unmarked",   deadEnd = true,  secretRoom = false, hidden = true },
}

function InteriorConfig.GetBuilding(key)
	for _, e in ipairs(InteriorConfig.Buildings) do
		if e.key == key then
			return e
		end
	end
	return nil
end

-- Base CFrame at floor level (world y=1). Local -Z faces the Core (the door wall);
-- local +Z runs deeper into the building (away from the plaza); local +Y is up.
-- Build interior parts at world CFrame = base * CFrame.new(localX, localY, localZ).
function InteriorConfig.BuildingBaseCFrame(keyOrEntry)
	local e = keyOrEntry
	if type(e) == "string" then
		e = InteriorConfig.GetBuilding(e)
	end
	if not e then
		return nil
	end
	local a = math.rad(e.angleDeg)
	local ground = Vector3.new(math.sin(a) * e.radius, 1, math.cos(a) * e.radius)
	local lookTarget = Vector3.new(0, 1, 0)
	if e.hidden then
		-- Door faces away from the Core (player must walk around the back to enter).
		lookTarget = ground + (ground - Vector3.new(0, 1, 0))
	end
	return CFrame.lookAt(ground, lookTarget)
end

----------------------------------------------------------------------
-- The 1,000,000-Bit orb (inside the UNMARKED building, above the empty desk).
-- Both the UNMARKED builder (desk) and OrbService (orb + trigger) read these.
----------------------------------------------------------------------
InteriorConfig.UNMARKED_DESK_LOCAL = Vector3.new(0, 0, 10)  -- desk base on the floor, toward the back
InteriorConfig.UNMARKED_ORB_LOCAL = Vector3.new(0, 7, 10)   -- orb floating above the desk

function InteriorConfig.OrbPosition()
	local base = InteriorConfig.BuildingBaseCFrame("UNMARKED")
	if not base then
		return Vector3.new(0, 8, -300)
	end
	return base:PointToWorldSpace(InteriorConfig.UNMARKED_ORB_LOCAL)
end

----------------------------------------------------------------------
-- Hidden under-map tunnel network (neon graffiti corridors connecting districts).
----------------------------------------------------------------------
InteriorConfig.TUNNEL = {
	LEVEL_Y = -45,          -- corridor floor top (well below the baseplate bottom at y=-16)
	RING_RADIUS = 120,      -- hex ring of corridors under the map
	WIDTH = 14,             -- corridor inner width
	HEIGHT = 11,            -- corridor inner height
	COLOR = Color3.fromRGB(0, 255, 150),
	ENTRANCE_RADIUS = 120,  -- where each district's down-ramp meets the surface
}

-- Six corridor nodes around the ring, one per district angle. Local -Z faces the
-- ring centre. Used to place the 6 NPC death-scene markers + graffiti.
function InteriorConfig.TunnelNodeCFrame(i)
	local a = math.rad(30 + (i - 1) * 60)
	local r = InteriorConfig.TUNNEL.RING_RADIUS
	local y = InteriorConfig.TUNNEL.LEVEL_Y + 1
	local pos = Vector3.new(math.sin(a) * r, y, math.cos(a) * r)
	return CFrame.lookAt(pos, Vector3.new(0, y, 0))
end

-- One scenario per NPC death-scene placeholder (exactly 6). Each is rendered as an
-- invisible marker Part named NPCScene_<i> + a code comment so the user can drop
-- their GLITCHREALITY63 avatar at the exact spot.
InteriorConfig.NPC_SCENES = {
	"slumped against the corridor wall, knees up, head down",
	"face down on the floor, one arm outstretched toward the Core",
	"frozen mid-abduction, lifted a few studs off the ground inside a beam of light",
	"sitting against a dead terminal, head tilted back, screen-glow still on the face",
	"curled on their side in a half-lit alcove, half in shadow",
	"standing dead still, facing a graffiti wall that reads THE CORE LIES",
}

----------------------------------------------------------------------
-- Rank system (by lifetime Bits). Ascending by `min`. ROOT ACCESS = gold + perks.
----------------------------------------------------------------------
InteriorConfig.Ranks = {
	{ min = 0,      label = "[SCRIPT KIDDIE]", color = Color3.fromRGB(150, 150, 165) },
	{ min = 1000,   label = "[HACKER]",        color = Color3.fromRGB(0, 255, 120) },
	{ min = 10000,  label = "[GHOST]",         color = Color3.fromRGB(0, 200, 255) },
	{ min = 100000, label = "[ZERO DAY]",      color = Color3.fromRGB(180, 90, 255) },
	{ min = 500000, label = "[ROOT ACCESS]",   color = Color3.fromRGB(255, 215, 0), gold = true },
}

function InteriorConfig.RankFor(lifetime)
	lifetime = lifetime or 0
	local best = InteriorConfig.Ranks[1]
	for _, r in ipairs(InteriorConfig.Ranks) do
		if lifetime >= r.min then
			best = r
		else
			break
		end
	end
	return best
end

----------------------------------------------------------------------
-- Endgame loop / speedrun / hints
----------------------------------------------------------------------
InteriorConfig.ORB_BITS = 1000000          -- Bits granted on collecting the orb (also the lifetime gain)
InteriorConfig.RESET_COUNTDOWN = 60        -- seconds between "cracked" and the economy reset
InteriorConfig.HINT_TEXT = "somewhere in The Mainframe... 1,000,000 Bits are waiting. no hints."
InteriorConfig.HINT_INTERVAL_MIN = 180     -- 3 min
InteriorConfig.HINT_INTERVAL_MAX = 240     -- 4 min
InteriorConfig.SPEEDRUN_TOP_N = 3          -- fastest crack times kept on the Nexus board
InteriorConfig.SPEEDRUNNER_TAG = "[SPEEDRUNNER]"

-- Nexus speedrun board: a new spire placed in the plaza (mirrors the existing
-- Leaderboard Spire, on the opposite side; HUB_SPAWN_POS is (0,0,30)).
InteriorConfig.SPEEDRUN_BOARD_POS = Vector3.new(22, 9, 30)

----------------------------------------------------------------------
-- DataStore keys (OWN stores - never touch DataService's "HackerTycoon_v1").
----------------------------------------------------------------------
InteriorConfig.LIFETIME_STORE = "HT_Lifetime_v1"  -- key = tostring(userId) -> lifetime Bits (number)
InteriorConfig.SPEEDRUN_STORE = "HT_Speedrun_v1"  -- key SPEEDRUN_KEY -> { {name=, seconds=}, ... } top N
InteriorConfig.SPEEDRUN_KEY = "topTimes"

----------------------------------------------------------------------
-- Remote channel (created at runtime by MainframeService, rendered by MainframeClient)
----------------------------------------------------------------------
InteriorConfig.REMOTE_NAME = "MainframeRemote"
-- Fired kinds: "crack" {name, seconds}, "hint" {text}, "reset_done" {}

return InteriorConfig
