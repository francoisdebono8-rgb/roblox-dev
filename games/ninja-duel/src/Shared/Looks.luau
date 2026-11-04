-- How a family object looks (Families.luau, client FamilyFX): one entry per
-- projectile/zone kind, shared by server (launch point, radius, contact
-- style) and client (shape, colours, light, trail, contact burst).
--
-- shape: orb | needle | blade | wave | beast | serpent | swarm | shadow | boulder
-- color/color2: core and edge (RGB); size: {width, height, length} in studs;
-- light: PointLight brightness (0 = none); trail: trail width (0 = none);
-- hit: contact burst (splash | shatter | burst | smoke | sparks | crush);
-- zone: how a zone of that kind is drawn (mist | swarm | water | scorch | shadow | spikes).
local function rgb(r,g,b) return {r,g,b} end
return {
	-- Plain moulded chakra: the neutral fallback, never a kunai.
	chakra={shape="orb",color=rgb(150,210,255),color2=rgb(70,140,255),size={1.2,1.2,1.2},light=2,trail=.8,hit="burst",launch="Palm"},
	water={shape="orb",color=rgb(150,214,255),color2=rgb(40,120,210),size={1.4,1.4,1.8},light=.6,trail=1,hit="splash",zone="water",launch="Palm"},
	waterdragon={shape="serpent",color=rgb(120,196,255),color2=rgb(30,96,190),size={3,3,18},light=1,trail=2.4,hit="splash",zone="water",launch="Fireball",radius=2.4},
	shark={shape="beast",color=rgb(92,140,196),color2=rgb(222,236,248),size={2.4,2.2,5.4},light=.4,trail=1.8,hit="splash",zone="water",launch="Fireball",radius=2.2},
	ice={shape="blade",color=rgb(214,240,255),color2=rgb(150,206,240),size={.5,.5,3.2},light=.8,trail=.4,hit="shatter",zone="ice",launch="Palm"},
	senbon={shape="needle",color=rgb(220,226,236),color2=rgb(170,180,196),size={.08,.08,1.6},light=0,trail=.15,hit="sparks",launch="Shuriken",radius=.45},
	bone={shape="needle",color=rgb(240,234,214),color2=rgb(208,196,170),size={.22,.22,1.4},light=0,trail=.25,hit="sparks",launch="Palm",radius=.5},
	shadow={shape="shadow",color=rgb(16,14,22),color2=rgb(40,34,56),size={1.6,.06,1},light=0,trail=0,hit="smoke",zone="shadow",launch="Ground",radius=1.4},
	insects={shape="swarm",color=rgb(30,32,26),color2=rgb(70,84,50),size={3,2.4,3},light=0,trail=0,hit="smoke",zone="swarm",launch="Palm",radius=1.8},
	hounds={shape="beast",color=rgb(150,120,90),color2=rgb(60,52,46),size={1.4,1.6,2.8},light=0,trail=.6,hit="crush",launch="Ground",radius=1.6},
	dog={shape="beast",color=rgb(244,240,230),color2=rgb(200,170,150),size={1.3,1.5,2.4},light=0,trail=.6,hit="crush",launch="Ground",radius=1.5},
	snakes={shape="serpent",color=rgb(96,70,120),color2=rgb(176,150,96),size={.8,.8,6},light=0,trail=.5,hit="crush",launch="Palm",radius=1},
	tag={shape="blade",color=rgb(232,222,190),color2=rgb(190,40,36),size={.5,.04,1.1},light=0,trail=.2,hit="burst",zone="scorch",launch="Kunai",radius=.6},
	mud={shape="wave",color=rgb(120,92,64),color2=rgb(84,64,46),size={6,3,2},light=0,trail=0,hit="crush",zone="mud",launch="Ground",radius=2.4},
	boulder={shape="boulder",color=rgb(200,150,110),color2=rgb(150,104,72),size={5,5,5},light=0,trail=0,hit="crush",launch="Ground",radius=2.4},
	-- Roster 20, remaining ten (DEC-022).
	-- Shisui: the Katon fireball (drawn by Effects' own fireball builder).
	fireball={shape="orb",color=rgb(255,160,60),color2=rgb(255,90,30),size={3,3,3},light=3,trail=1,hit="burst",zone="scorch",launch="Fireball",radius=2.2},
	-- Orochimaru: one long shadow snake shot from the sleeve.
	snake={shape="serpent",color=rgb(70,60,86),color2=rgb(150,132,90),size={.7,.7,7},light=0,trail=.4,hit="crush",launch="Palm",radius=1.1},
	-- Kimimaro: a long bone drawn from the shoulder, the larch of spikes.
	bonespear={shape="needle",color=rgb(244,238,220),color2=rgb(214,200,172),size={.45,.45,3.2},light=0,trail=.3,hit="shatter",launch="Palm",radius=.8},
	bones={shape="needle",color=rgb(244,238,220),color2=rgb(214,200,172),size={.3,.3,2},light=0,trail=0,hit="shatter",zone="spikes",radius=1},
	-- Nagato: the Rinnegan's pull, a ripple of bent air, and the push.
	gravity={shape="orb",color=rgb(196,170,230),color2=rgb(120,96,170),size={1.6,1.6,1.6},light=1.2,trail=1.4,hit="burst",launch="Palm",radius=1.6},
	repulsion={shape="orb",color=rgb(214,200,240),color2=rgb(150,126,200),size={1,1,1},light=0,trail=0,hit="burst"},
	-- Sasori: the puppet on its threads, its poisoned needles.
	puppet={shape="beast",color=rgb(150,110,74),color2=rgb(86,64,46),size={1.6,2.4,2.6},light=0,trail=.4,hit="crush",launch="Palm",radius=1.6},
	poisonneedle={shape="needle",color=rgb(150,200,120),color2=rgb(80,120,60),size={.1,.1,1.4},light=0,trail=.2,hit="sparks",launch="Shuriken",radius=.5},
	-- Deidara: moulded explosive clay.
	claybird={shape="beast",color=rgb(240,236,222),color2=rgb(204,196,176),size={2.2,1,2.4},light=0,trail=.5,hit="burst",zone="scorch",launch="Palm",radius=1.6},
	clayspider={shape="beast",color=rgb(236,232,218),color2=rgb(196,188,168),size={.9,.5,1},light=0,trail=0,hit="burst",zone="scorch",launch="Ground",radius=1.2},
	-- A charge laid on the floor (a missed bird or spider, a buried mine).
	claycharge={shape="orb",color=rgb(240,236,222),color2=rgb(255,120,60),size={.9,.6,.9},light=0,trail=0,hit="burst",zone="charge",radius=1},
	clay={shape="orb",color=rgb(240,236,222),color2=rgb(255,190,90),size={1,1,1},light=0,trail=0,hit="burst",zone="scorch"},
	-- Killer Bee: the Eight-Tails' ink and a tentacle.
	ink={shape="orb",color=rgb(30,28,40),color2=rgb(60,56,80),size={1,1,1},light=0,trail=0,hit="smoke",zone="mist"},
	tentacle={shape="serpent",color=rgb(170,96,80),color2=rgb(220,170,150),size={1.4,1.4,8},light=0,trail=.6,hit="crush",launch="Palm",radius=1.6},
	-- Haku: a mirror of ice (the dome is drawn by Wave1FX).
	mirror={shape="blade",color=rgb(214,240,255),color2=rgb(150,206,240),size={.2,3,2},light=.8,trail=0,hit="shatter",zone="ice"},
	-- Kabuto: the scalpel of chakra.
	scalpel={shape="blade",color=rgb(140,240,200),color2=rgb(60,200,150),size={.3,.06,1.2},light=1,trail=.3,hit="sparks"},
	flicker={shape="orb",color=rgb(40,40,48),color2=rgb(230,60,60),size={1,1,1},light=0,trail=0,hit="smoke"},
	-- Zones that are not thrown.
	mist={shape="orb",color=rgb(226,232,238),color2=rgb(190,200,210),size={1,1,1},light=0,trail=0,hit="smoke",zone="mist"},
	fist={shape="orb",color=rgb(255,190,190),color2=rgb(255,120,140),size={1.6,1.6,1.6},light=2.5,trail=0,hit="crush",zone="crater"},
	-- DEC-026 newcomers (Wave4). Hashirama's contact root runs the floor from
	-- his hand; the short Katon breath of Madara and Hiruzen (a cone drawn by
	-- Wave4FX); the stances: Madara's read (the blade turned flat), the young
	-- wood guard, Hiruzen's lever.
	root={shape="serpent",color=rgb(120,84,50),color2=rgb(150,190,90),size={.9,.9,4},light=0,trail=0,hit="crush",launch="Ground",radius=1.5},
	firebreath={shape="orb",color=rgb(255,170,70),color2=rgb(255,90,30),size={2,2,2},light=3,trail=0,hit="burst",zone="scorch"},
	swordread={shape="blade",color=rgb(220,60,60),color2=rgb(200,206,214),size={.2,.06,2.4},light=0,trail=0,hit="sparks"},
	woodguard={shape="blade",color=rgb(150,110,70),color2=rgb(110,160,80),size={.6,.6,1.6},light=0,trail=0,hit="crush"},
	-- (Stage 6) the eight main fighters' new jutsu: Minato's flash cut,
	-- Kakashi's white-chakra cut, Lee's entry kick, Neji's sight, Gaara's
	-- armour and Lee's weights (bodies and buffs: no thrown object).
	flash={shape="blade",color=rgb(255,236,120),color2=rgb(255,200,40),size={.3,.06,1.6},light=2,trail=.6,hit="sparks"},
	lightning={shape="blade",color=rgb(236,246,255),color2=rgb(130,190,255),size={.3,.06,2.2},light=2.5,trail=.5,hit="sparks"},
	leaf={shape="orb",color=rgb(120,200,90),color2=rgb(60,140,50),size={1.2,1.2,1.2},light=0,trail=.6,hit="crush"},
	byakugan={shape="orb",color=rgb(236,232,255),color2=rgb(170,160,230),size={1,1,1},light=1,trail=0,hit="burst"},
	sandarmor={shape="orb",color=rgb(214,186,130),color2=rgb(170,140,90),size={1,1,1},light=0,trail=0,hit="crush"},
	weights={shape="boulder",color=rgb(150,140,130),color2=rgb(90,84,78),size={1,1,1},light=0,trail=0,hit="crush"},
	staffread={shape="blade",color=rgb(232,200,120),color2=rgb(90,64,40),size={.2,.2,4},light=0,trail=0,hit="sparks"},
	-- (DEC-032) the hand-seal jutsu of the eight (Shared/SealJutsu).
	windmill={shape="blade",color=rgb(196,204,214),color2=rgb(90,96,110),size={1.1,.08,1.1},light=0,trail=.3,hit="sparks",launch="Shuriken",radius=.7},
	fuma={shape="blade",color=rgb(170,178,190),color2=rgb(60,64,76),size={2.6,.12,2.6},light=0,trail=.6,hit="sparks",launch="Shuriken",radius=1.3},
	firedragon={shape="serpent",color=rgb(255,170,60),color2=rgb(255,80,20),size={2.6,2.6,14},light=3,trail=2,hit="burst",zone="scorch",launch="Fireball",radius=2.2},
	foxchakra={shape="orb",color=rgb(255,120,40),color2=rgb(200,30,20),size={1.4,1.4,1.4},light=2,trail=0,hit="burst"},
	sandgrab={shape="wave",color=rgb(222,194,136),color2=rgb(176,146,96),size={3,1.4,2.4},light=0,trail=0,hit="crush",zone="mud",launch="Ground",radius=1.6},
	sandspike={shape="needle",color=rgb(226,198,140),color2=rgb(180,150,100),size={.6,.6,3},light=0,trail=0,hit="crush",zone="spikes",launch="Ground",radius=1.2},
	quicksand={shape="wave",color=rgb(214,184,124),color2=rgb(170,140,90),size={6,1,2},light=0,trail=0,hit="crush",zone="mud",launch="Ground",radius=2.4},
	thirdeye={shape="orb",color=rgb(226,198,140),color2=rgb(120,90,50),size={.9,.9,.9},light=.6,trail=0,hit="burst"},
	crows={shape="swarm",color=rgb(18,16,24),color2=rgb(150,30,40),size={3.4,2.6,3.4},light=0,trail=0,hit="smoke",zone="swarm",launch="Palm",radius=2},
	airpalm={shape="orb",color=rgb(236,240,255),color2=rgb(176,190,240),size={1.6,1.6,1.6},light=.8,trail=1.2,hit="burst",launch="Palm",radius=1.2},
	-- (04/11) Minato: a sealing formula written on the floor (Families zone Trap),
	-- the space-time barrier (a warping stance) and its seal.
	-- (04/11) The replaced seal jutsu: Gamakichi's water bullet (and the toad
	-- itself), Shukaku's arm of sand, Neji's mountain crusher, the Sharingan's
	-- hold, the smoke of a shadow clone popping out.
	toadwater={shape="orb",color=rgb(170,222,255),color2=rgb(60,140,220),size={2.2,2.2,2.8},light=.8,trail=1.4,hit="splash",zone="water",launch="Palm",radius=1.6},
	toad={shape="beast",color=rgb(236,120,50),color2=rgb(90,60,120),size={2.4,1.8,2.6},light=0,trail=0,hit="smoke"},
	sandarm={shape="wave",color=rgb(214,184,124),color2=rgb(150,118,78),size={12,3,2},light=0,trail=0,hit="crush",launch="Ground",radius=3},
	hasangeki={shape="wave",color=rgb(220,232,255),color2=rgb(150,176,240),size={7,5,2},light=1.2,trail=1.6,hit="burst",launch="Palm",radius=3.4},
	sharingan={shape="orb",color=rgb(230,30,40),color2=rgb(20,10,12),size={.6,.6,.6},light=1.6,trail=0,hit="burst"},
	clonepop={shape="orb",color=rgb(244,240,236),color2=rgb(255,150,40),size={1,1,1},light=0,trail=0,hit="smoke"},
	sealtrap={shape="orb",color=rgb(244,236,214),color2=rgb(40,34,30),size={1,1,1},light=0,trail=0,hit="burst",zone="seal",launch="Ground",radius=4.2},
	barrier={shape="orb",color=rgb(255,222,120),color2=rgb(40,34,30),size={1,1,1},light=1.4,trail=0,hit="burst"},
	trigram={shape="orb",color=rgb(214,220,255),color2=rgb(150,160,230),size={1,1,1},light=0,trail=0,hit="burst",zone="shadow"},
	markedkunai={shape="needle",color=rgb(206,212,222),color2=rgb(255,214,92),size={.14,.14,1.3},light=.6,trail=.3,hit="sparks",launch="Kunai",radius=.6},
	earthwall={shape="boulder",color=rgb(150,120,88),color2=rgb(104,82,60),size={6,5,1.4},light=0,trail=0,hit="crush",zone="spikes",launch="Ground",radius=3},
	earthhand={shape="beast",color=rgb(142,112,82),color2=rgb(96,76,56),size={1.4,1.8,1.8},light=0,trail=0,hit="crush",zone="mud",launch="Ground",radius=1.6},
	earthdragon={shape="serpent",color=rgb(150,118,84),color2=rgb(96,74,52),size={3,3,18},light=0,trail=1.6,hit="crush",zone="crater",launch="Ground",radius=2.4},
}
