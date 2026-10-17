-- Temari's motion family (roster wave, DEC-015): her stance, gait, clips,
-- throw overlay (the fan gust), cast poses and intro, added to the motion
-- engine's tables by install(E) (VelmoraMotionEngine passes its STANCE, GAIT,
-- CLIPS, THROWS, CAST, INTRO and builders). No clip of another fighter for her
-- string, routes, heavy or air: the right hand always carries the iron fan
-- (GaleFX draws it), so every strike is a thrust, a sweep or a chop with a
-- long, heavy weapon, the third and the routes open it into a gust. Grabs and
-- throws fall back to Itachi's (listed in TEMARI.md). Presentation only.
local GaleMotion={}
function GaleMotion.install(E)
	local K,merge,smooth=E.K,E.merge,E.smooth
	-- Upright and composed, weight on the back foot, left side to the opponent,
	-- chin up; the right hand rests on the hip (the fan is on her back), the
	-- left hand low and open in front.
	local T={root={y=-.22,pitch=-2,yaw=26},torso={pitch=-3,yaw=-12},head={pitch=-6,yaw=-14},
		ra={raise=-8,out=38,twist=-50,elbow=104,wrist=10},la={raise=46,out=6,twist=-14,elbow=40,wrist=-20},
		rf={x=.18,z=.66,yaw=34},lf={x=-.06,z=-.5,yaw=-4},breath=.6,tempo=4.4}
	E.STANCE.Gale=T
	-- Measured steps, little bounce, no guard carried; the hand stays on the
	-- hip until she breaks into a full run (holdRear).
	E.GAIT.Gale={stride=.98,cadence=.92,arm=16,lean=-1,bob=.65,guard=0,holdRear=true}
	local function t(over) return merge(T,over) end
	local AIR={root={pitch=4},torso={pitch=6},head={pitch=-6},ra={raise=60,out=30,elbow=70},la={raise=40,out=30,elbow=60},rl={lift=50,knee=86,ankle=-10},ll={lift=30,knee=64,ankle=-10}}
	local function air(over) return merge(AIR,over) end
	local C={}
	C.Light1={ -- the closed fan driven straight out like a spear
		K(0,t({root={y=-.34,yaw=40,pitch=2},torso={yaw=18,pitch=2},ra={raise=50,out=24,twist=10,elbow=118,wrist=0},la={raise=40,out=10,elbow=50}})),
		K(1,t({root={y=-.36,z=-.28,yaw=8,pitch=8},torso={yaw=-18,pitch=6},head={yaw=-6},ra={raise=88,out=-4,twist=0,elbow=4,wrist=0},la={raise=20,out=30,elbow=40},lf={z=-.82},rf={z=.72}}),"out"),
		K(2,t({root={y=-.36,z=-.3,yaw=6,pitch=8},torso={yaw=-20,pitch=6},ra={raise=86,out=-6,elbow=8},la={raise=20,out=30,elbow=40},lf={z=-.82},rf={z=.72}})),
		K(3,T),
	}
	C.Light2={ -- a flat sweep from the right across her front, the whole body turning
		K(0,t({root={y=-.32,yaw=52},torso={yaw=30},ra={raise=80,out=76,twist=-6,elbow=16},la={raise=50,out=-10,elbow=70}})),
		K(1,t({root={y=-.36,yaw=-6,pitch=6},torso={yaw=-30,pitch=4},head={yaw=8},ra={raise=86,out=-34,twist=6,elbow=10},la={raise=26,out=30,elbow=40},lf={z=-.7,x=-.1}}),"out"),
		K(2,t({root={y=-.36,yaw=-12,pitch=6},torso={yaw=-38,pitch=4},ra={raise=84,out=-48,elbow=14},la={raise=26,out=30,elbow=40},lf={z=-.7,x=-.1}})),
		K(3,T),
	}
	C.Light3={ -- both hands: the fan raised overhead opens and comes down in a gust
		K(0,t({root={y=-.2,pitch=-8,yaw=12},torso={pitch=-14,yaw=6},head={pitch=-10},ra={raise=168,out=14,elbow=40},la={raise=160,out=-6,elbow=60}})),
		K(1,t({root={y=-.62,z=-.4,pitch=14,yaw=0},torso={pitch=18},head={pitch=4},ra={raise=74,out=-6,elbow=8},la={raise=70,out=-14,elbow=20},lf={z=-1.1},rf={z=.9}}),"out"),
		K(2,t({root={y=-.62,z=-.42,pitch=14},torso={pitch=20},ra={raise=68,out=-6,elbow=10},la={raise=64,out=-14,elbow=22},lf={z=-1.1},rf={z=.9}})),
		K(3,T),
	}
	C.Heavy={ -- the closed fan chopped down from overhead, one hand
		K(0,t({root={y=-.3,pitch=-6,yaw=24},torso={pitch=-10,yaw=14},ra={raise=172,out=22,elbow=46},la={raise=60,out=16,elbow=60}})),
		K(.75,t({root={y=-.36,pitch=-8,yaw=26},torso={pitch=-12,yaw=16},ra={raise=176,out=24,elbow=52},la={raise=62,out=16,elbow=60}})),
		K(1,t({root={y=-.8,z=-.5,pitch=22,yaw=4},torso={pitch=24,yaw=-8},head={pitch=8},ra={raise=46,out=-4,elbow=4},la={raise=10,out=40,elbow=30},lf={z=-1.2},rf={z=1.0}}),"out"),
		K(2,t({root={y=-.8,z=-.52,pitch=22,yaw=2},torso={pitch=24,yaw=-10},ra={raise=42,out=-4,elbow=6},la={raise=10,out=40,elbow=30},lf={z=-1.2},rf={z=1.0}})),
		K(3,T),
	}
	C.Updraft={ -- low, then the half-open fan scoops the body up into the rising air
		K(0,t({root={y=-1.0,pitch=20,yaw=20},torso={pitch=14,yaw=10},ra={raise=-20,out=24,twist=-10,elbow=20},la={raise=40,out=20,elbow=50},lf={z=-.6},rf={z=.6}})),
		K(1,t({root={y=.08,pitch=-14,yaw=-4},torso={pitch=-16,yaw=-6},head={pitch=-22},ra={raise=168,out=8,elbow=10},la={raise=-10,out=36,elbow=24},rf={toe=-20},lf={z=-.3}}),"out"),
		K(2,t({root={y=.06,pitch=-16},torso={pitch=-18},head={pitch=-22},ra={raise=172,out=8,elbow=14},la={raise=-10,out=36,elbow=24},rf={toe=-18},lf={z=-.3}})),
		K(3,T),
	}
	C.FanSlam={ -- both hands: the closed fan brought down like a beam
		K(0,t({root={y=-.16,pitch=-10},torso={pitch=-18},head={pitch=-12},ra={raise=170,out=6,elbow=40},la={raise=166,out=-4,elbow=50}})),
		K(1,t({root={y=-.95,z=-.3,pitch=28},torso={pitch=26},head={pitch=10},ra={raise=34,out=-8,elbow=8},la={raise=30,out=-12,elbow=14},lf={z=-1.0},rf={z=.9}}),"out"),
		K(2,t({root={y=-.95,z=-.32,pitch=28},torso={pitch=26},ra={raise=32,out=-8,elbow=10},la={raise=28,out=-12,elbow=16},lf={z=-1.0},rf={z=.9}})),
		K(3,T),
	}
	local Y=T.root.yaw
	-- A full turn on the lead foot, the open fan held out at arm's length (each
	-- key under half a turn from the next, so the body turns the right way).
	local turn={
		K(0,t({root={y=-.4,yaw=Y-30},torso={yaw=-20},ra={raise=84,out=70,elbow=14},la={raise=60,out=40,elbow=30}})),
		K(1,t({root={y=-.48,yaw=Y+90,roll=-6},torso={yaw=10},head={yaw=-60},ra={raise=88,out=86,elbow=8},la={raise=70,out=60,elbow=20},lf={x=.3,yaw=90}}),"out"),
		K(2,t({root={y=-.48,yaw=Y+200,roll=-6},torso={yaw=10},head={yaw=-60},ra={raise=88,out=86,elbow=8},la={raise=70,out=60,elbow=20},lf={x=.3,yaw=200}})),
		K(2.5,t({root={y=-.36,yaw=Y+290},ra={raise=70,out=50,elbow=30},lf={x=.2,yaw=290}})),
		K(3,merge(T,{root={yaw=Y+360}})),
	}
	C.FanPirouette=turn
	C.FanBackhand={ -- the backhand: from across her body out to the right
		K(0,t({root={y=-.32,yaw=-10},torso={yaw=-34},ra={raise=80,out=-54,twist=40,elbow=74},la={raise=40,out=24,elbow=50}})),
		K(1,t({root={y=-.38,z=-.3,yaw=48,pitch=6},torso={yaw=30},head={yaw=-10},ra={raise=86,out=66,twist=-10,elbow=10},la={raise=30,out=-10,elbow=80},lf={z=-.8},rf={z=.8,yaw=40}}),"out"),
		K(2,t({root={y=-.38,z=-.32,yaw=54,pitch=6},torso={yaw=34},ra={raise=84,out=70,elbow=12},la={raise=30,out=-10,elbow=80},lf={z=-.8},rf={z=.8,yaw=40}})),
		K(3,T),
	}
	C.DashAttack={ -- a running thrust, the fan leading
		K(0,t({root={y=-.7,z=.2,pitch=26,yaw=20},torso={pitch=6},ra={raise=40,out=24,twist=10,elbow=110},la={raise=70,out=-6,elbow=30},lf={z=-1.1},rf={z=1.2}})),
		K(1,t({root={y=-.66,z=-.95,pitch=26,yaw=-6},torso={yaw=-12},head={pitch=-14},ra={raise=94,out=-4,elbow=0},la={raise=-26,out=24,elbow=30},lf={z=-1.6},rf={z=1.45,y=.2,toe=-20}}),"out"),
		K(2,t({root={y=-.64,z=-.98,pitch=24,yaw=-8},torso={yaw=-14},ra={raise=92,out=-4,elbow=4},la={raise=-24,out=24,elbow=30},lf={z=-1.6},rf={z=1.45,y=.2,toe=-20}})),
		K(3,T),
	}
	C.Riposte=C.Light1
	C.FlyingKick={ -- out of a full run: a leaping thrust
		K(0,t({root={y=-.5,pitch=18},ra={raise=40,out=20,elbow=110},la={raise=60,out=20,elbow=40},lf={z=-.9},rf={z=1.0}})),
		K(1,t({root={y=-.1,z=-.8,pitch=10},torso={pitch=8},ra={raise=96,out=-4,elbow=2},la={raise=-20,out=30,elbow=20},rl={lift=40,knee=80},lf={z=-1.2,toe=-20}}),"out"),
		K(2,t({root={y=-.12,z=-.82,pitch=10},torso={pitch=8},ra={raise=94,out=-4,elbow=4},la={raise=-20,out=30,elbow=20},rl={lift=36,knee=76},lf={z=-1.2,toe=-18}})),
		K(3,T),
	}
	C.SlideSweep={ -- out of a full run: dropped low, the closed fan reaps the ankles
		K(0,t({root={y=-.9,pitch=20,yaw=30},torso={yaw=20},ra={raise=30,out=70,elbow=20},la={raise=30,out=20,elbow=40},lf={z=-1.0},rf={z=1.1}})),
		K(1,t({root={y=-1.15,pitch=24,yaw=-20},torso={yaw=-30,pitch=10},ra={raise=24,out=-40,elbow=10},la={raise=-10,out=40,elbow=20},lf={z=-1.3},rf={z=1.3}}),"out"),
		K(2,t({root={y=-1.15,pitch=24,yaw=-24},torso={yaw=-34,pitch=10},ra={raise=22,out=-48,elbow=12},la={raise=-10,out=40,elbow=20},lf={z=-1.3},rf={z=1.3}})),
		K(3,T),
	}
	C.WallDive={ -- off the wall: the fan first, the body behind it
		K(0,air({root={pitch=-10},ra={raise=150,out=20,elbow=60},la={raise=100,out=30,elbow=40},rl={lift=80,knee=110},ll={lift=70,knee=100}})),
		K(1,air({root={pitch=36},torso={pitch=20},ra={raise=100,out=-4,elbow=2},la={raise=20,out=40,elbow=30},rl={lift=10,knee=30},ll={lift=30,knee=50}}),"out"),
		K(2,air({root={pitch=38},torso={pitch=22},ra={raise=98,out=-4,elbow=4},la={raise=20,out=40,elbow=30},rl={lift=10,knee=30},ll={lift=30,knee=50}})),
		K(3,T),
	}
	C.Air1={ -- in the air: a sweep from the right
		K(0,air({torso={yaw=-24},ra={raise=100,out=70,elbow=30}})),
		K(1,air({torso={yaw=26,pitch=12},ra={raise=80,out=-30,elbow=10},la={raise=20,out=40,elbow=40}}),"out"),
		K(2,air({torso={yaw=30,pitch=12},ra={raise=78,out=-40,elbow=12},la={raise=20,out=40,elbow=40}})),
		K(3,AIR),
	}
	C.Air2={ -- in the air: the backhand
		K(0,air({torso={yaw=26},ra={raise=80,out=-40,twist=30,elbow=70}})),
		K(1,air({torso={yaw=-28,pitch=10},ra={raise=86,out=64,elbow=10},rl={lift=70,knee=60}}),"out"),
		K(2,air({torso={yaw=-32,pitch=10},ra={raise=84,out=70,elbow=12},rl={lift=66,knee=62}})),
		K(3,AIR),
	}
	C.AirDrive={ -- in the air: the fan driven straight through the body
		K(0,air({root={pitch=-6},ra={raise=50,out=20,elbow=110},la={raise=60,out=10,elbow=60}})),
		K(1,air({root={pitch=14},torso={pitch=12},ra={raise=92,out=-4,elbow=2},la={raise=10,out=40,elbow=30},rl={lift=20,knee=40},ll={lift=70,knee=90}}),"out"),
		K(2,air({root={pitch=14},torso={pitch=12},ra={raise=90,out=-4,elbow=4},la={raise=10,out=40,elbow=30},rl={lift=20,knee=40},ll={lift=70,knee=90}})),
		K(3,AIR),
	}
	C.FanDive={ -- in the air: the open fan beats down, the body under it is driven into the floor
		K(0,air({root={pitch=-14},torso={pitch=-18},ra={raise=172,out=8,elbow=40},la={raise=168,out=-4,elbow=44},rl={lift=70,knee=100},ll={lift=60,knee=96}})),
		K(1,air({root={pitch=34},torso={pitch=30},head={pitch=10},ra={raise=30,out=-6,elbow=8},la={raise=26,out=-10,elbow=12},rl={lift=10,knee=40},ll={lift=20,knee=60}}),"out"),
		K(2,air({root={pitch=36},torso={pitch=30},ra={raise=28,out=-6,elbow=10},la={raise=24,out=-10,elbow=14},rl={lift=10,knee=40},ll={lift=20,knee=60}})),
		K(3,AIR),
	}
	C.Slam={ -- the air heavy: an overhead chop that carries her down
		K(0,air({root={pitch=-10},torso={pitch=-16},ra={raise=176,out=10,elbow=42},la={raise=80,out=30,elbow=50},rl={lift=64,knee=110},ll={lift=58,knee=100}})),
		K(1,air({root={pitch=28},torso={pitch=40},head={pitch=12},ra={raise=40,out=-6,elbow=6},la={raise=40,out=30,elbow=30},rl={lift=-10,knee=40},ll={lift=14,knee=60}}),"out"),
		K(2,air({root={pitch=30},torso={pitch=42},ra={raise=36,out=-6,elbow=8},la={raise=40,out=30,elbow=30},rl={lift=-10,knee=40},ll={lift=14,knee=60}})),
		K(3,t({root={y=-.9,pitch=22},torso={pitch=18}})),
	}
	E.CLIPS.Gale=C
	setmetatable(C,{__index=E.CLIPS.Mirage})
	-- The tool: the fan flicked open from the right and swept across her front.
	E.THROWS.Gust=function(time,release)
		local wind={torso={yaw=34,pitch=-2},head={yaw=-16},ra={raise=86,out=74,twist=-10,elbow=30,wrist=0},la={raise=40,out=10,elbow=60}}
		local snap={torso={yaw=-26,pitch=6},head={yaw=6},ra={raise=88,out=-30,twist=10,elbow=8,wrist=0},la={raise=30,out=30,elbow=50}}
		if time<release then return wind,smooth(time/math.max(release*.7,.02)) end
		if time<release+.28 then return snap,1 end
		return snap,1-smooth((time-release-.28)/.17)
	end
	-- Casts: the fan drawn and opened (one moon, two, all three), then swung.
	local channel={Kamaitachi=.3,GreatGust=.5,Cyclone=.24}
	E.CAST.Kamaitachi=function(actor,base,time,state)
		if state=="TechniqueChannel" then
			local u=smooth(time/channel.Kamaitachi)
			return merge(base,{root={y=-.4,yaw=30+16*u},torso={yaw=30+10*u,pitch=-4},head={yaw=-30},ra={raise=120+30*u,out=50+10*u,twist=-20,elbow=70-10*u},la={raise=60,out=-10,elbow=60},lf={z=-.7},rf={z=.8}})
		end
		return merge(base,{root={y=-.46,yaw=-10,pitch=8},torso={yaw=-34,pitch=6},head={yaw=4},ra={raise=88,out=-50,elbow=8},la={raise=30,out=30,elbow=40},lf={z=-.9},rf={z=.8}})
	end
	E.CAST.GreatGust=function(actor,base,time,state)
		if state=="TechniqueChannel" then
			local u=smooth(time/channel.GreatGust)
			return merge(base,{root={y=-.5-.2*u,yaw=40+14*u},torso={yaw=36+8*u,pitch=-6},head={yaw=-36},ra={raise=140+20*u,out=40,elbow=40},la={raise=130+20*u,out=10,elbow=70},lf={z=-1.1,x=-.2},rf={z=1.0,x=.3,yaw=50}})
		end
		return merge(base,{root={y=-.72,z=-.3,yaw=-20,pitch=14},torso={yaw=-40,pitch=14},head={yaw=8},ra={raise=90,out=-40,elbow=8},la={raise=84,out=-20,elbow=16},lf={z=-1.2},rf={z=1.0}})
	end
	E.CAST.Cyclone=function(actor,base,time,state)
		if state=="TechniqueChannel" then
			-- The open fan held up in front, turned in the wrist: the air starts to spin.
			return merge(base,{root={y=-.5,yaw=10},torso={yaw=-6,pitch=4},head={pitch=-6},ra={raise=110,out=10,elbow=30,wroll=(time*900)%360},la={raise=50,out=20,elbow=60},lf={z=-.8},rf={z=.7}})
		end
		return merge(base,{root={y=-.3,pitch=-4},torso={pitch=-8},head={pitch=-10},ra={raise=150,out=10,elbow=10},la={raise=40,out=30,elbow=50}})
	end
	-- The intro: the fan planted open beside her (GaleFX), her right hand on its
	-- edge, the left on her hip, chin up.
	E.INTRO.Gale=function(base)
		return merge(base,{root={y=-.1,pitch=-3,yaw=10},torso={pitch=-5,yaw=-4},head={pitch=-12,yaw=-10},
			ra={raise=72,out=60,twist=0,elbow=26,wrist=20},la={raise=-8,out=38,twist=-50,elbow=104,wrist=10},rf={x=.14,z=.3},lf={x=-.1,z=-.3}})
	end
end
return GaleMotion
