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
-- (15/11, François: « la taille des personnages, l'échelle de la map […] La
-- taille des joueurs, bah, s'ils sont grands, fait tout un peu plus grand
-- aussi ») The village is drawn below at the scale it was first built (a
-- floor of 8 studs, a door of 6.4, for bodies of about 5.5); everything in it
-- is `Scale` times bigger: the positions and the places here (M.applyScale,
-- at the end of this file), the buildings, props and dressing in Server/Hub
-- (Hub.scaleVillage). The bodies keep their size.
M.Scale=1.3
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
	-- (15/11) between the Uchiha wall and the market (Server/Hub.alleys)
	{id="Alleys",name="THE BACK ALLEYS",at=Vector3.new(180,0,-3),radius=60},
}

-- The exam's proctor, on the hall's floor: the board of duels (the roster:
-- against the AI, online, a private duel, the tournament).
M.Proctor={kit="Professor",at=Vector3.new(0,0,-52),face=Vector3.new(0,0,1),
	name="THE PROCTOR",place="THE EXAM HALL",line="Duels, the tournament, players from everywhere: it all starts on this floor."}

-- The masters, each at home. `line`: what he says when the player comes to him.
-- `duel` (14/11, Config.Hub.VillageDuels): where a duel started at his home
-- is fought, in the village (its centre on the ground, the radius the bodies
-- are held in); without it, the stadium.
-- (14/11, measured in Studio: Roblox's paths from the gate) each faces the way
-- a player walks up to him. Naruto, Gaara and Kakashi showed their side or
-- back (67, 84 and 64 degrees off), Lee 35; now under 10.
M.Masters={
	Legion={place="ICHIRAKU RAMEN",at=Vector3.new(-15,0,110),face=Vector3.new(.45,0,.9),
		duel={at=Vector3.new(0,0,140),radius=34},
		line="A bowl first, then the clones. Nobody beats me at either!"},
	Lion={place="THE UCHIHA PIER",at=Vector3.new(176,1.6,-60),face=Vector3.new(-1,0,0),
		line="Fire starts in the chest, not in the hands. Show me yours."},
	Leaf={place="TRAINING GROUND THREE",at=Vector3.new(-118,0,28),face=Vector3.new(.85,0,.53),
		duel={at=Vector3.new(-136,0,10),radius=34},
		line="Five hundred laps, then we talk. Or one honest fight, right now!"},
	GentleFist={place="THE HYŪGA COMPOUND",at=Vector3.new(-146,0,-98),face=Vector3.new(1,0,0),
		duel={at=Vector3.new(-152,0,-104),radius=36},
		line="The Byakugan sees every opening you leave. Close them first."},
	Sand={place="THE EXAM HALL'S BALCONY",at=Vector3.new(-49,12.5,-78),face=Vector3.new(.1,0,1),
		line="The sand decides who is worth it. It has not decided about you."},
	Copycat={place="THE MEMORIAL STONE",at=Vector3.new(-165,0,72),face=Vector3.new(.82,0,.57),
		line="Copy first, understand later. Show me something worth copying."},
	Mirage={place="THE UCHIHA SHRINE'S TORII",at=Vector3.new(178,14.9,-108),face=Vector3.new(-1,0,.4),
		line="You see only what I let you see. Look closer."},
	Flashstep={place="UNDER THE HOKAGE FACES",at=Vector3.new(0,24,-214),face=Vector3.new(0,0,1),
		line="Plant your mark first. The speed comes after."},
}

-- (DEC-041, user 14/11 21 h 49: « quand c'était comme un starter, c'était pas
-- des fiches et tu vas vraiment les rencontrer avec ton personnage. Et tu vois,
-- avec des petites animations, tu comprends leur état d'esprit », then
-- « ensemble près de la porte ») For a new player the three first
-- inspirations hang out together at the top of the main street, just inside
-- the gate, each in his own mood (Client/HubMoods): Naruto showing off, Lee
-- training, Sasuke leaning apart, half turned away. Once he has chosen, they
-- are back home (Client/HubClient moves them, on his screen only).
M.Welcome={
	Legion={at=Vector3.new(-9,0,166),face=Vector3.new(.25,0,1)},
	Leaf={at=Vector3.new(1,0,158),face=Vector3.new(0,0,1)},
	Lion={at=Vector3.new(12,0,172),face=Vector3.new(-.75,0,.66)},
}

-- (14/11, audit: « que notre perso puisse combattre, qu'on puisse apprendre »)
-- Training Ground Three's dummy: E there trains with his kit (Server/Hub
-- places the prompt, Client/HubClient answers it).
M.Training={at=Vector3.new(-150,0,16),place="TRAINING GROUND THREE",duel={at=Vector3.new(-136,0,10),radius=34}}
-- (14/11, François: « on va créer une boutique propre au jeu avec des Ryō »)
-- The market of Konoha, at the crossing of its lanes: the looks sold for Ryō
-- (Client/ShopPanel in its "market" mode; the SHOP sells for Robux).
M.Market={at=Vector3.new(158,0,62),place="THE MARKET STREETS"}
-- (15/11, François: « J'aime bien ce que ça implique des combats dans la rue,
-- des combats un peu partout sur la map ») Where a 1v1 between two players
-- walking in Konoha is fought: the open places of the village already tried
-- in Studio with a duel (Matches.streetSite picks the nearest free one).
M.Streets={}
do
	local seen={}
	local keys={}
	for key,spot in M.Masters do if spot.duel then table.insert(keys,key) end end
	table.sort(keys)
	local function add(key,spot)
		local at=spot.duel.at
		local id=string.format("%d,%d",at.X,at.Z)
		if seen[id] then return end
		seen[id]=true
		table.insert(M.Streets,{key=key,at=at,radius=spot.duel.radius,place=spot.place})
	end
	for _,key in keys do add(key,M.Masters[key]) end
	add("Training",M.Training)
	-- (15/11, François: « des combats un peu partout sur la map », « dans
	-- des espaces resserrés ») the street fights' own places: the plaza, a
	-- market lane, the back alleys' courtyard and lane, the residences' lane.
	-- `axis`: the way the street runs (the two fighters start along it,
	-- `start` studs from the centre each).
	for _,spot in {
		{key="Plaza",at=Vector3.new(0,0,10),radius=28,place="THE PLAZA",axis=Vector3.xAxis,start=16},
		{key="MarketLane",at=Vector3.new(115,0,56),radius=26,place="THE MARKET STREETS",axis=Vector3.xAxis,start=14},
		{key="Courtyard",at=Vector3.new(165,0,-3),radius=24,place="THE BACK-ALLEY COURTYARD",axis=Vector3.xAxis,start=14},
		{key="BackAlley",at=Vector3.new(232,0,-3),radius=20,place="THE BACK ALLEYS",axis=Vector3.xAxis,start=12},
		{key="Residences",at=Vector3.new(-160,0,150),radius=24,place="THE WEST RESIDENCES",axis=Vector3.xAxis,start=12},
	} do table.insert(M.Streets,spot) end
end

-- (14/11, user: « les têtes sont moches […] à terme ça sera les champions, on
-- peut mettre le dev aussi et des trucs drôles pour l'instant ») The four
-- heads on the cliff: the game's creator (1), the last three tournament
-- champions (2 to 4, newest first), a funny head while a place is empty
-- (Server/ChampionCliff). Centres of the heads, facing the village (+z).
-- (14/11, François: the faces of the anime's monument are big, not aligned,
-- and stand out of the rock) Four places, staggered, each 26 x 30 x 8 scaled
-- by HeadScale (about 50 x 58 x 19): the back flush with the cliff (z -232),
-- the face out to about -213; above the terrace (its top at y 24).
M.Heads={Vector3.new(-96,58,-222.4),Vector3.new(-32,55,-222.4),Vector3.new(32,61,-222.4),Vector3.new(96,53,-222.4)}
M.HeadScale=Vector3.new(1.92,1.92,2.4)
-- (15/11) the cliff as Server/Hub builds it, before the village is scaled
M.Base={Heads=table.clone(M.Heads),HeadScale=M.HeadScale}

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
-- (15/11) Every position and size of this map times `s` (once, at load).
function M.applyScale(s)
	if M.scaled or s==1 then return end
	M.scaled=true
	M.HalfX*=s;M.MinZ*=s;M.MaxZ*=s
	for _,spot in M.Spawns do spot.at*=s end
	for _,place in M.Places do place.at*=s;place.radius*=s end
	M.Proctor.at*=s
	for _,spot in M.Masters do
		spot.at*=s
		if spot.duel then spot.duel={at=spot.duel.at*s,radius=spot.duel.radius*s} end
	end
	for _,spot in M.Welcome do spot.at*=s end
	M.Training.at*=s
	if M.Training.duel then M.Training.duel={at=M.Training.duel.at*s,radius=M.Training.duel.radius*s} end
	M.Market.at*=s
	for k,at in M.Heads do M.Heads[k]=at*s end
	M.HeadScale*=s
	for _,street in M.Streets do street.at*=s;street.radius*=s;if street.start then street.start*=s end end
end
function M.inside(rel)
	return math.abs(rel.X)<=M.HalfX and rel.Z>=M.MinZ and rel.Z<=M.MaxZ
end

M.applyScale(M.Scale)

return M
