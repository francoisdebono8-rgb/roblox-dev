-- The ninja's personalization beyond the outfit (21/11, étape 3 DEV 2,
-- DEC-047; François after playing: « il faudrait plus de personnalisation que
-- des simples tenues », and every kind the DEV proposed: hair styles and
-- colours, the colour of his chakra and jutsu, victory poses and emotes,
-- auras, weapons, titles, face-cam frames).
--
-- The DEV's data, next to the ANIMATEUR's Shared/Catalog (same entry format,
-- merged by Shared/Shop.Items): everything that needs no model is here, so no
-- tab is empty. What needs a model or a clip (hair styles, victory poses,
-- emotes, the shop's auras) the ANIMATEUR adds to Catalog in the same slots.
-- One more price besides `ryo`, `robux` and `base`:
--   earned   never sold: the rule that gives it (Style.earned), the line the
--            shop shows (`how`) so a look to earn says how to earn it
-- What a look changes on screen (none of it a number, DEC-039):
--   hairColor  his avatar's hair, painted (Server/Style.apply)
--   chakra     the colour of his chakra, infusions and jutsu: the player's
--              attribute NinjaChakra (Color3), read by the client's effects
--   title      the line under his name: the attribute NinjaTitle
--   frame      his face-cam's frame (the DESIGN), the attribute NinjaFrame
--   aura       a merit aura chosen among those earned (NinjaAura), or a shop
--              aura (NinjaShopAura, the ANIMATEUR's Aura.<id>)
--   victory / emote  the clips the ANIMATEUR makes (Victory.<id>, Emote.<id>)
local Style={}

local function rgb(r,g,b) return {r,g,b} end
Style.Items={
	-- HAIR COLOUR: his own hair, painted.
	{id="HairNatural",slot="hairColor",name="YOUR OWN COLOUR",base=true,none=true},
	{id="HairRaven",slot="hairColor",name="RAVEN BLACK",ryo=400,colors={Hair=rgb(24,22,30)}},
	{id="HairNight",slot="hairColor",name="NIGHT BLUE",ryo=500,colors={Hair=rgb(36,46,86)}},
	{id="HairSun",slot="hairColor",name="SUN BLOND",ryo=500,colors={Hair=rgb(246,204,72)}},
	{id="HairFlame",slot="hairColor",name="FLAME RED",ryo=600,colors={Hair=rgb(196,48,40)}},
	{id="HairBlossom",slot="hairColor",name="BLOSSOM PINK",ryo=600,colors={Hair=rgb(238,150,184)}},
	{id="HairLeaf",slot="hairColor",name="LEAF GREEN",ryo=600,colors={Hair=rgb(70,150,80)}},
	{id="HairSnow",slot="hairColor",name="SNOW WHITE",ryo=800,colors={Hair=rgb(236,236,240)}},
	{id="HairEmber",slot="hairColor",name="EMBER ORANGE",ryo=800,colors={Hair=rgb(232,118,40)}},
	{id="HairSilver",slot="hairColor",name="ANBU SILVER",robux="HairSilver",colors={Hair=rgb(176,182,196)}},
	{id="HairVoid",slot="hairColor",name="VOID PURPLE",robux="HairVoid",colors={Hair=rgb(92,52,150)}},
	-- CHAKRA COLOUR: his chakra, his infusions and his jutsu.
	{id="ChakraBlue",slot="chakra",name="LEAF BLUE",base=true,colors={Chakra=rgb(110,180,255)}},
	{id="ChakraCrimson",slot="chakra",name="CRIMSON",ryo=900,colors={Chakra=rgb(220,40,48)}},
	{id="ChakraViolet",slot="chakra",name="VIOLET",ryo=900,colors={Chakra=rgb(150,80,230)}},
	{id="ChakraJade",slot="chakra",name="JADE",ryo=900,colors={Chakra=rgb(60,210,130)}},
	{id="ChakraSun",slot="chakra",name="SUNFIRE",ryo=1200,colors={Chakra=rgb(255,190,60)}},
	{id="ChakraFrost",slot="chakra",name="FROST",ryo=1200,colors={Chakra=rgb(170,240,255)}},
	{id="ChakraSakura",slot="chakra",name="SAKURA",ryo=1200,colors={Chakra=rgb(255,140,200)}},
	{id="ChakraBlackFlame",slot="chakra",name="BLACK FLAME",robux="ChakraBlackFlame",colors={Chakra=rgb(40,24,48)}},
	{id="ChakraGold",slot="chakra",name="SAGE GOLD",robux="ChakraGold",colors={Chakra=rgb(255,214,90)}},
	-- AURA: the merit auras, chosen among those earned (never sold); the
	-- shop's own auras come from the ANIMATEUR (Catalog, slot "aura").
	{id="AuraNone",slot="aura",name="NO AURA",base=true},
	{id="AuraEmber",slot="aura",name="EMBER AURA",earned="merit1",how="25 merit: win duels",tier=1},
	{id="AuraStorm",slot="aura",name="STORM AURA",earned="merit2",how="100 merit: win duels",tier=2},
	{id="AuraLegend",slot="aura",name="LEGEND AURA",earned="merit3",how="300 merit: win duels",tier=3},
	-- TITLE: the line under his name. Earned only.
	{id="TitleNone",slot="title",name="NO TITLE",base=true,none=true},
	{id="TitleGraduate",slot="title",name="ACADEMY GRADUATE",earned="wins1",how="Win your first duel"},
	{id="TitleStreet",slot="title",name="STREET FIGHTER",earned="pvp10",how="Win 10 duels against players"},
	{id="TitleGenin",slot="title",name="THE GENIN",earned="rank2",how="Reach GENIN in ranked"},
	{id="TitleChunin",slot="title",name="THE CHUNIN",earned="rank3",how="Reach CHUNIN in ranked"},
	{id="TitleJonin",slot="title",name="THE JONIN",earned="rank4",how="Reach JONIN in ranked"},
	{id="TitleAnbu",slot="title",name="ANBU",earned="rank5",how="Reach ANBU in ranked"},
	{id="TitleKage",slot="title",name="THE KAGE",earned="rank6",how="Reach KAGE in ranked"},
	{id="TitleSevenDays",slot="title",name="SEVEN DAYS STRONG",earned="days7",how="Play 7 days in a row"},
	{id="TitleRooftops",slot="title",name="ROOFTOP RUNNER",earned="rooftops",how="Finish the rooftop course"},
	{id="TitleHundred",slot="title",name="HUNDRED VICTORIES",earned="wins100",how="Win 100 duels"},
	-- FACE-CAM FRAME: the frame of his head in the duel's HUD (the DESIGN).
	{id="FramePlain",slot="frame",name="PLAIN INK",base=true,colors={Frame=rgb(24,22,26)}},
	{id="FrameVermilion",slot="frame",name="VERMILION BRUSH",ryo=900,colors={Frame=rgb(190,40,36)}},
	{id="FrameLeaf",slot="frame",name="LEAF SEAL",ryo=1200,colors={Frame=rgb(70,140,70)}},
	{id="FrameStorm",slot="frame",name="STORM SCROLL",ryo=1500,colors={Frame=rgb(90,110,200)}},
	{id="FrameGold",slot="frame",name="GOLD LEAF",robux="FrameGold",colors={Frame=rgb(230,184,86)}},
	{id="FrameLegend",slot="frame",name="LEGEND'S FRAME",earned="merit3",how="300 merit: win duels",colors={Frame=rgb(255,120,40)}},
	-- HAIR STYLE, VICTORY POSE, EMOTE: one entry each that everyone has; the
	-- styles, poses and emotes themselves are the ANIMATEUR's (Catalog).
	{id="HairOwn",slot="hair",name="YOUR OWN HAIR",base=true,none=true},
	{id="VictoryBow",slot="victory",name="THE BOW",base=true,clip="Victory.Bow"},
	{id="EmoteWave",slot="emote",name="WAVE",base=true,clip="Emote.Wave"},
}

-- The earned rules: whether a profile has met `rule` (pure, from the
-- profile's merit, ranked and daily records).
local Ranked,Merit
local function ranked() Ranked=Ranked or require(script.Parent.Ranked);return Ranked end
local function merit() Merit=Merit or require(script.Parent.Merit);return Merit end
function Style.met(p,rule)
	local m=p.merit or {}
	local wins,pvp,points=m.wins or 0,m.pvpWins or 0,m.points or 0
	if rule=="wins1" then return wins>=1 end
	if rule=="wins100" then return wins>=100 end
	if rule=="pvp10" then return pvp>=10 end
	local tier=string.match(rule,"^merit(%d)$")
	if tier then return merit().tier(points)>=tonumber(tier) end
	local rank=string.match(rule,"^rank(%d)$")
	if rank then return p.ranked~=nil and ranked().rank(p.ranked.rating or 0).index>=tonumber(rank) end
	if rule=="days7" then return p.daily~=nil and (p.daily.streak or 0)>=7 end
	if rule=="rooftops" then return p.rooftops~=nil and p.rooftops.best~=nil end
	return false
end
-- The earned looks a profile qualifies for and does not own yet (ids).
function Style.earned(p,items)
	local out={}
	for _,item in items or Style.Items do
		if item.earned and not (p.style and p.style.owned[item.id]) and Style.met(p,item.earned) then table.insert(out,item.id) end
	end
	return out
end
-- An item's colour (Color3) from its colors table, or nil.
function Style.color(item,key)
	local c=item and item.colors and item.colors[key]
	return c and Color3.fromRGB(c[1],c[2],c[3]) or nil
end

return Style
