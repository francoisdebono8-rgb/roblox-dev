-- Konoha, the hub (DEC-038, user 13/11, 17 h 11-17 h 14): « travailler la boucle
-- en mode le décor, les scènes, où est-ce qu'on va choisir le maître, les
-- premiers déplacements ». A compact village: the gate the player's avatar
-- walks in through, the main street (Ichiraku), the plaza, and at its heart
-- the hall of the Chûnin exam's preliminaries, where the duels and the
-- tournament start. Around it the training ground and the memorial stone, the
-- Hyûga compound, the Uchiha district and its pier, the rooftops, the stairs up
-- to the Hokage faces. Each master waits at home: the player walks to him.
-- Shared data: Server/Hub builds it, Client/HubClient guides the player.
-- Positions are relative to Origin (studs; y=0 is the ground), facing is the
-- direction the master looks.
local M={}

-- Far from the duel lanes (Matches.laneOrigin: x = (lane-1)*520, z = 0).
M.Origin=Vector3.new(0,0,-2400)
-- The walkable square (half sizes on x and z); invisible walls beyond.
M.HalfX=290
M.MinZ=-262
M.MaxZ=216

-- Where an avatar appears: through the gate (arrival), out of the hall's door
-- (back from a duel).
M.Spawns={
	gate={at=Vector3.new(0,0,192),face=Vector3.new(0,0,-1)},
	hall={at=Vector3.new(0,0,-8),face=Vector3.new(0,0,1)},
}

-- The places (the HUD names the nearest one; markers point at some).
M.Places={
	{id="Gate",name="THE GREAT GATE",at=Vector3.new(0,0,200),radius=40},
	{id="Street",name="MAIN STREET",at=Vector3.new(0,0,120),radius=60},
	{id="Ichiraku",name="ICHIRAKU RAMEN",at=Vector3.new(-26,0,112),radius=18},
	{id="Plaza",name="THE PLAZA",at=Vector3.new(0,0,12),radius=40},
	{id="Hall",name="THE EXAM HALL",at=Vector3.new(0,0,-70),radius=60},
	{id="Training",name="TRAINING GROUND THREE",at=Vector3.new(-132,0,36),radius=55},
	{id="Memorial",name="THE MEMORIAL STONE",at=Vector3.new(-170,0,76),radius=20},
	{id="Hyuga",name="THE HYŪGA COMPOUND",at=Vector3.new(-152,0,-104),radius=50},
	{id="Uchiha",name="THE UCHIHA DISTRICT",at=Vector3.new(150,0,-90),radius=65},
	{id="Rooftops",name="THE ROOFTOPS",at=Vector3.new(44,16,122),radius=40},
	{id="Faces",name="THE HOKAGE FACES",at=Vector3.new(0,24,-214),radius=45},
	-- (14/11) the two quarters of houses (Server/Hub.quarters)
	{id="Market",name="THE MARKET STREETS",at=Vector3.new(160,0,103),radius=85},
	{id="Residences",name="THE WEST RESIDENCES",at=Vector3.new(-170,0,150),radius=70},
}

-- The exam's proctor, on the hall's floor: the board of duels (the roster:
-- against the AI, online, a private duel, the tournament).
M.Proctor={kit="Professor",at=Vector3.new(0,0,-52),face=Vector3.new(0,0,1),
	name="THE PROCTOR",place="THE EXAM HALL",line="Duels, the tournament, players from everywhere: it all starts on this floor."}

-- The masters, each at home. `line`: what he says when the player comes to him.
M.Masters={
	Legion={place="ICHIRAKU RAMEN",at=Vector3.new(-15,0,110),face=Vector3.new(1,0,0),
		line="A bowl first, then the clones. Nobody beats me at either!"},
	Lion={place="THE UCHIHA PIER",at=Vector3.new(176,1.6,-60),face=Vector3.new(-1,0,0),
		line="Fire starts in the chest, not in the hands. Show me yours."},
	Leaf={place="TRAINING GROUND THREE",at=Vector3.new(-118,0,28),face=Vector3.new(1,0,0),
		line="Five hundred laps, then we talk. Or one honest fight, right now!"},
	GentleFist={place="THE HYŪGA COMPOUND",at=Vector3.new(-146,0,-98),face=Vector3.new(1,0,0),
		line="The Byakugan sees every opening you leave. Close them first."},
	Sand={place="THE EXAM HALL'S BALCONY",at=Vector3.new(-49,12.5,-78),face=Vector3.new(1,0,0),
		line="The sand decides who is worth it. It has not decided about you."},
	Copycat={place="THE MEMORIAL STONE",at=Vector3.new(-165,0,72),face=Vector3.new(1,0,-.5),
		line="Copy first, understand later. Show me something worth copying."},
	Mirage={place="THE UCHIHA SHRINE'S TORII",at=Vector3.new(178,14.9,-108),face=Vector3.new(-1,0,.4),
		line="You see only what I let you see. Look closer."},
	Flashstep={place="UNDER THE HOKAGE FACES",at=Vector3.new(0,24,-214),face=Vector3.new(0,0,1),
		line="Plant your mark first. The speed comes after."},
}

-- The village's walk, for the HUD: the nearest place to a position (world).
-- The smallest place he stands in (Ichiraku within the street), else the
-- nearest one.
function M.placeAt(world)
	local rel=world-M.Origin
	local inside,near,score=nil,nil,math.huge
	for _,place in M.Places do
		local d=(Vector3.new(rel.X,0,rel.Z)-Vector3.new(place.at.X,0,place.at.Z)).Magnitude
		if d<=place.radius and (not inside or place.radius<inside.radius) then inside=place end
		if d-place.radius<score then near,score=place,d-place.radius end
	end
	return inside or near
end
function M.world(rel) return M.Origin+rel end
function M.inside(rel)
	return math.abs(rel.X)<=M.HalfX and rel.Z>=M.MinZ and rel.Z<=M.MaxZ
end

return M
