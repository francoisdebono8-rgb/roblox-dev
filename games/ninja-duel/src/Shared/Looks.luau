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
	waterdragon={shape="serpent",color=rgb(120,196,255),color2=rgb(30,96,190),size={2.6,2.6,9},light=1,trail=2.4,hit="splash",zone="water",launch="Fireball",radius=2.4},
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
	-- Zones that are not thrown.
	mist={shape="orb",color=rgb(226,232,238),color2=rgb(190,200,210),size={1,1,1},light=0,trail=0,hit="smoke",zone="mist"},
	fist={shape="orb",color=rgb(255,190,190),color2=rgb(255,120,140),size={1.6,1.6,1.6},light=2.5,trail=0,hit="crush",zone="crater"},
}
