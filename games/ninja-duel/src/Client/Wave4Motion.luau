-- DEC-026 newcomers: the bodies of Madara, Hashirama and Hiruzen as children
-- (bibles docs/characters/{MADARA,HASHIRAMA,HIRUZEN}_CHILD.md §3–§6, §11).
-- Added to the motion engine's clip table by install(E), like GaleMotion.
-- Keys: 0 wind-up, 1 contact ("out"), 2 end of the live window, 3 back to the
-- stance; the server's startup/active/recovery set how long each takes, so
-- the contact frame is the strike's. What they do not author (throws, grabs,
-- dash strike, wall dive) falls back to their body family's clips.
-- Presentation only.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Wave4Motion={}
function Wave4Motion.install(E)
	local K,merge=E.K,E.merge
	local AIR={root={pitch=4},torso={pitch=6},head={pitch=-6},ra={raise=60,out=30,elbow=70},la={raise=40,out=30,elbow=60},rl={lift=50,knee=86,ankle=-10},ll={lift=30,knee=64,ankle=-10}}
	local function air(over) return merge(AIR,over) end
	local function clip(T,keys)
		local out={}
		for i,k in keys do
			local at,pose,ease=k[1],k[2],k[3]
			out[i]=K(at,if pose=="T" then T elseif pose.air then air(pose.air) else merge(T,pose),ease)
		end
		return out
	end

	-- Madara: the right hand is the sword hand (Wave4FX), the left is free.
	local M=Fighters.Rival.Motion.stance
	local C={}
	C.Light1=clip(M,{ -- right short sword, diagonal from high right to the left hip
		{0,{root={y=-.46,yaw=40},torso={yaw=26,pitch=-4},ra={raise=150,out=46,twist=-20,elbow=50,wrist=0},la={raise=50,out=-10,elbow=60}}},
		{1,{root={y=-.52,z=-.3,yaw=2,pitch=8},torso={yaw=-30,pitch=8},head={yaw=-6},ra={raise=40,out=-46,twist=30,elbow=10},la={raise=30,out=24,elbow=50},lf={z=-.8},rf={z=.7}},"out"},
		{2,{root={y=-.52,z=-.32,yaw=0,pitch=8},torso={yaw=-34,pitch=8},ra={raise=36,out=-50,twist=30,elbow=12},la={raise=30,out=24,elbow=50},lf={z=-.8},rf={z=.7}}},
		{3,"T"}})
	C.Light2=clip(M,{ -- the sword hand drawn back, the left palm (pommel side) into the sternum
		{0,{root={y=-.44,yaw=34},torso={yaw=22},ra={raise=40,out=30,elbow=96},la={raise=60,out=10,elbow=100,wrist=-10}}},
		{1,{root={y=-.48,z=-.26,yaw=10,pitch=6},torso={yaw=-18,pitch=6},ra={raise=30,out=40,elbow=100},la={raise=88,out=-6,elbow=6,wrist=-40},lf={z=-.72}},"out"},
		{2,{root={y=-.48,z=-.28,yaw=8,pitch=6},torso={yaw=-20,pitch=6},ra={raise=30,out=40,elbow=100},la={raise=86,out=-6,elbow=8,wrist=-40},lf={z=-.72}}},
		{3,"T"}})
	C.Light3=clip(M,{ -- the reverse cut, hip to shoulder, on a 60° pivot
		{0,{root={y=-.6,yaw=-20},torso={yaw=-40,pitch=6},ra={raise=20,out=-50,twist=40,elbow=30},la={raise=40,out=30,elbow=60}}},
		{1,{root={y=-.48,z=-.4,yaw=50,pitch=-2},torso={yaw=30,pitch=-4},head={yaw=-20},ra={raise=150,out=60,twist=-20,elbow=10},la={raise=20,out=-10,elbow=70},lf={z=-.9},rf={z=.8,yaw=50}},"out"},
		{2,{root={y=-.48,z=-.42,yaw=54,pitch=-2},torso={yaw=34,pitch=-4},ra={raise=154,out=62,twist=-20,elbow=12},la={raise=20,out=-10,elbow=70},lf={z=-.9},rf={z=.8,yaw=50}}},
		{3,"T"}})
	C.Heavy=clip(M,{ -- the shoulder charges in behind a big diagonal
		{0,{root={y=-.7,yaw=50,pitch=6},torso={yaw=36,pitch=8},ra={raise=160,out=30,elbow=60},la={raise=70,out=-20,elbow=80}}},
		{.75,{root={y=-.74,yaw=54,pitch=6},torso={yaw=40,pitch=8},ra={raise=166,out=32,elbow=64},la={raise=70,out=-20,elbow=80}}},
		{1,{root={y=-.8,z=-.6,yaw=-10,pitch=16},torso={yaw=-34,pitch=14},head={pitch=6},ra={raise=30,out=-50,elbow=6},la={raise=20,out=30,elbow=40},lf={z=-1.1},rf={z=.9}},"out"},
		{2,{root={y=-.8,z=-.62,yaw=-12,pitch=16},torso={yaw=-36,pitch=14},ra={raise=28,out=-52,elbow=8},la={raise=20,out=30,elbow=40},lf={z=-1.1},rf={z=.9}}},
		{3,"T"}})
	C.QuillonRise=clip(M,{ -- the quillon catches the guard low, then a short rising cut
		{0,{root={y=-.9,pitch=16,yaw=20},torso={pitch=10,yaw=10},ra={raise=40,out=-20,twist=30,elbow=40},la={raise=70,out=-10,elbow=40}}},
		{1,{root={y=-.2,z=-.3,pitch=-10,yaw=10},torso={pitch=-12},head={pitch=-16},ra={raise=168,out=10,elbow=10},la={raise=20,out=30,elbow=40},rf={toe=-20}},"out"},
		{2,{root={y=-.2,z=-.32,pitch=-12,yaw=10},torso={pitch=-14},head={pitch=-16},ra={raise=172,out=10,elbow=12},la={raise=20,out=30,elbow=40},rf={toe=-18}}},
		{3,"T"}})
	C.GuardCut=clip(M,{ -- an outer step and a cut on the guarding arm
		{0,{root={y=-.5,yaw=60},torso={yaw=40},ra={raise=110,out=60,twist=-20,elbow=40},la={raise=50,out=-10,elbow=60},lf={x=.4}}},
		{1,{root={y=-.5,yaw=-10,pitch=6},torso={yaw=-30,pitch=6},ra={raise=80,out=-30,twist=20,elbow=10},la={raise=20,out=30,elbow=40},lf={x=.6,z=-.7}},"out"},
		{2,{root={y=-.5,yaw=-14,pitch=6},torso={yaw=-32,pitch=6},ra={raise=78,out=-34,twist=20,elbow=12},la={raise=20,out=30,elbow=40},lf={x=.6,z=-.7}}},
		{3,"T"}})
	C.HeelBarrier=clip(M,{ -- a low heel to the shin, the blade held across as he backs off
		{0,{root={y=-.6,pitch=-4,yaw=20},ra={raise=80,out=-60,twist=60,elbow=30},la={raise=40,out=30,elbow=60},rl={lift=50,knee=90}}},
		{1,{root={y=-.62,pitch=-8,yaw=10},torso={pitch=-6},ra={raise=84,out=-64,twist=60,elbow=20},la={raise=30,out=40,elbow=50},rl={lift=40,knee=10,ankle=30}},"out"},
		{2,{root={y=-.62,pitch=-8,yaw=10},torso={pitch=-6},ra={raise=84,out=-64,twist=60,elbow=20},la={raise=30,out=40,elbow=50},rl={lift=36,knee=14,ankle=30}}},
		{3,"T"}})
	C.PommelRiposte=clip(M,{ -- the pommel punched straight in off the parry
		{0,{root={y=-.46,yaw=30},torso={yaw=16},ra={raise=60,out=10,elbow=110},la={raise=60,out=-10,elbow=60}}},
		{1,{root={y=-.5,z=-.3,yaw=6,pitch=6},torso={yaw=-16,pitch=6},ra={raise=88,out=-6,elbow=8},la={raise=30,out=30,elbow=50},lf={z=-.8}},"out"},
		{2,{root={y=-.5,z=-.32,yaw=4,pitch=6},torso={yaw=-18,pitch=6},ra={raise=86,out=-6,elbow=10},la={raise=30,out=30,elbow=50},lf={z=-.8}}},
		{3,"T"}})
	C.SharinganCut=clip(M,{ -- awake: round the guard, a cut at an angle
		{0,{root={y=-.5,yaw=-30},torso={yaw=-30},ra={raise=100,out=-40,twist=40,elbow=40},la={raise=50,out=20,elbow=60}}},
		{1,{root={y=-.52,yaw=70,pitch=6},torso={yaw=36,pitch=6},head={yaw=-30},ra={raise=90,out=70,twist=-30,elbow=8},la={raise=20,out=-10,elbow=70},lf={x=.5,z=-.6}},"out"},
		{2,{root={y=-.52,yaw=74,pitch=6},torso={yaw=38,pitch=6},ra={raise=88,out=74,twist=-30,elbow=10},la={raise=20,out=-10,elbow=70},lf={x=.5,z=-.6}}},
		{3,"T"}})
	C.Air1=clip(M,{ -- in the air: one shoulder cut
		{0,{air={torso={yaw=26},ra={raise=150,out=40,elbow=50}}}},
		{1,{air={torso={yaw=-26,pitch=12},ra={raise=40,out=-40,elbow=10},la={raise=20,out=40,elbow=40}}},"out"},
		{2,{air={torso={yaw=-28,pitch=12},ra={raise=36,out=-44,elbow=12},la={raise=20,out=40,elbow=40}}}},
		{3,{air={}}}})
	C.PommelDrop=clip(M,{ -- in the air: the pommel brought down on the head
		{0,{air={root={pitch=-10},torso={pitch=-14},ra={raise=170,out=10,elbow=60}}}},
		{1,{air={root={pitch=30},torso={pitch=30},ra={raise=40,out=-6,elbow=20}}},"out"},
		{2,{air={root={pitch=32},torso={pitch=30},ra={raise=36,out=-6,elbow=22}}}},
		{3,{air={}}}})
	E.CLIPS.Rival=C
	setmetatable(C,{__index=E.CLIPS.Lion})

	-- Hashirama: open hands, a wrestler's base; the wood (Wave4FX) covers the
	-- forearm while a strike is live.
	local H=Fighters.Sapling.Motion.stance
	local S={}
	S.Light1=clip(H,{ -- left wrestler's palm, low to the sternum, fingers after the arm
		{0,{root={y=-.72,pitch=12,yaw=20},torso={yaw=14},la={raise=20,out=10,elbow=90},ra={raise=50,out=20,elbow=80}}},
		{1,{root={y=-.64,z=-.3,pitch=10,yaw=4},torso={yaw=-16,pitch=8},la={raise=80,out=-10,elbow=10,wrist=-40},ra={raise=50,out=20,elbow=80},lf={z=-.75}},"out"},
		{2,{root={y=-.64,z=-.32,pitch=10,yaw=2},torso={yaw=-18,pitch=8},la={raise=78,out=-10,elbow=14,wrist=-40},ra={raise=50,out=20,elbow=80},lf={z=-.75}}},
		{3,"T"}})
	S.Light2=clip(H,{ -- right forearm from outside onto the shoulder, the hip turning
		{0,{root={y=-.62,yaw=40},torso={yaw=40},ra={raise=90,out=80,elbow=100},la={raise=60,out=-10,elbow=70}}},
		{1,{root={y=-.66,yaw=-10,pitch=10},torso={yaw=-30,pitch=8},ra={raise=90,out=-20,elbow=92},la={raise=40,out=20,elbow=70}},"out"},
		{2,{root={y=-.66,yaw=-12,pitch=10},torso={yaw=-32,pitch=8},ra={raise=88,out=-24,elbow=92},la={raise=40,out=20,elbow=70}}},
		{3,"T"}})
	S.Light3=clip(H,{ -- both palms into the chest, the whole weight forward
		{0,{root={y=-.8,z=.2,pitch=6},torso={pitch=4},ra={raise=60,out=10,elbow=120},la={raise=60,out=-10,elbow=120}}},
		{1,{root={y=-.6,z=-.6,pitch=14},torso={pitch=12},head={pitch=-6},ra={raise=88,out=6,elbow=6,wrist=-50},la={raise=88,out=-6,elbow=6,wrist=-50},lf={z=-1.1},rf={z=.8}},"out"},
		{2,{root={y=-.6,z=-.62,pitch=14},torso={pitch=12},ra={raise=86,out=6,elbow=8,wrist=-50},la={raise=86,out=-6,elbow=8,wrist=-50},lf={z=-1.1},rf={z=.8}}},
		{3,"T"}})
	S.Heavy=clip(H,{ -- the two forearms come together at the hips, then drive
		{0,{root={y=-.92,pitch=14},torso={pitch=10},ra={raise=60,out=-30,elbow=110},la={raise=60,out=-30,elbow=110}}},
		{.75,{root={y=-.96,pitch=16},torso={pitch=12},ra={raise=62,out=-32,elbow=114},la={raise=62,out=-32,elbow=114}}},
		{1,{root={y=-.66,z=-.6,pitch=12},torso={pitch=8},ra={raise=90,out=-6,elbow=24},la={raise=90,out=-6,elbow=24},lf={z=-1.1},rf={z=.9}},"out"},
		{2,{root={y=-.66,z=-.62,pitch=12},torso={pitch=8},ra={raise=88,out=-6,elbow=26},la={raise=88,out=-6,elbow=26},lf={z=-1.1},rf={z=.9}}},
		{3,"T"}})
	S.StumpRise=clip(H,{ -- the shoulder drives the body onto a low stump that lifts it
		{0,{root={y=-.9,pitch=20,yaw=-30},torso={yaw=-40,pitch=14},ra={raise=30,out=-10,elbow=110},la={raise=40,out=10,elbow=100}}},
		{1,{root={y=-.3,z=-.3,pitch=-6,yaw=0},torso={pitch=-10},head={pitch=-14},ra={raise=140,out=10,elbow=20},la={raise=140,out=-10,elbow=20}},"out"},
		{2,{root={y=-.3,z=-.32,pitch=-8},torso={pitch=-12},ra={raise=144,out=10,elbow=22},la={raise=144,out=-10,elbow=22}}},
		{3,"T"}})
	S.WrestleStep=clip(H,{ -- the hand fixes the arm, a wrestler's step to the side
		{0,{root={y=-.66,yaw=20},la={raise=85,out=10,elbow=30,wrist=-20},ra={raise=50,out=30,elbow=90}}},
		{1,{root={y=-.7,yaw=60,pitch=8},torso={yaw=40},la={raise=80,out=-30,elbow=60},ra={raise=70,out=-20,elbow=40},lf={x=-.6,z=-.5}},"out"},
		{2,{root={y=-.7,yaw=62,pitch=8},torso={yaw=42},la={raise=78,out=-30,elbow=62},ra={raise=70,out=-20,elbow=40},lf={x=-.6,z=-.5}}},
		{3,"T"}})
	S.RootBrake=clip(H,{ -- he lets go, a palm to the ground, a low root brakes the chase
		{0,{root={y=-.8,pitch=10},la={raise=60,out=10,elbow=80},ra={raise=60,out=-10,elbow=80}}},
		{1,{root={y=-1.2,pitch=30},torso={pitch=20},head={pitch=-20},la={raise=40,out=-10,elbow=6,wrist=-60},ra={raise=20,out=30,elbow=30},lf={z=-.9},rf={z=.9}},"out"},
		{2,{root={y=-1.2,pitch=30},torso={pitch=20},la={raise=38,out=-10,elbow=8,wrist=-60},ra={raise=20,out=30,elbow=30},lf={z=-.9},rf={z=.9}}},
		{3,"T"}})
	S.ShoulderRiposte=clip(H,{ -- the blow taken, the shoulder answers
		{0,{root={y=-.8,yaw=40},torso={yaw=50,pitch=10},ra={raise=40,out=-20,elbow=120},la={raise=40,out=-20,elbow=120}}},
		{1,{root={y=-.7,z=-.5,yaw=-30,pitch=16},torso={yaw=-50,pitch=14},ra={raise=30,out=-20,elbow=120},la={raise=50,out=20,elbow=100},lf={z=-1.0},rf={z=.8}},"out"},
		{2,{root={y=-.7,z=-.52,yaw=-32,pitch=16},torso={yaw=-52,pitch=14},ra={raise=30,out=-20,elbow=120},la={raise=50,out=20,elbow=100},lf={z=-1.0},rf={z=.8}}},
		{3,"T"}})
	S.RootRise=clip(H,{ -- awake: the palm to the floor, the root rises at the point of contact
		{0,{root={y=-1.1,pitch=26},torso={pitch=18},la={raise=30,out=-10,elbow=6,wrist=-60},ra={raise=40,out=30,elbow=40}}},
		{1,{root={y=-.4,pitch=-4},torso={pitch=-6},head={pitch=-14},la={raise=130,out=-10,elbow=10,wrist=-20},ra={raise=60,out=30,elbow=40}},"out"},
		{2,{root={y=-.4,pitch=-4},torso={pitch=-6},la={raise=132,out=-10,elbow=12},ra={raise=60,out=30,elbow=40}}},
		{3,"T"}})
	S.Air1=clip(H,{ -- in the air: a palm coming down
		{0,{air={ra={raise=150,out=20,elbow=60}}}},
		{1,{air={torso={pitch=14},ra={raise=60,out=-6,elbow=10,wrist=-50}}},"out"},
		{2,{air={torso={pitch=14},ra={raise=58,out=-6,elbow=12,wrist=-50}}}},
		{3,{air={}}}})
	S.PalmStomp=clip(H,{ -- in the air: the heel stamps down
		{0,{air={root={pitch=-10},rl={lift=90,knee=110},ll={lift=60,knee=90}}}},
		{1,{air={root={pitch=10},rl={lift=-10,knee=6,ankle=20},ll={lift=40,knee=80},ra={raise=100,out=40},la={raise=100,out=40}}},"out"},
		{2,{air={root={pitch=10},rl={lift=-10,knee=8,ankle=20},ll={lift=40,knee=80},ra={raise=100,out=40},la={raise=100,out=40}}}},
		{3,{air={}}}})
	E.CLIPS.Sapling=S
	setmetatable(S,{__index=E.CLIPS.Lion})

	-- Hiruzen: the staff in both hands (Wave4FX welds it to the right).
	local P=Fighters.Professor.Motion.stance
	local Q={}
	Q.Light1=clip(P,{ -- a short thrust of the point, centre to shoulder
		{0,{root={y=-.4,yaw=40},torso={yaw=10},ra={raise=40,out=20,elbow=110},la={raise=60,out=-30,elbow=60}}},
		{1,{root={y=-.44,z=-.35,yaw=20,pitch=6},torso={yaw=-10,pitch=4},ra={raise=86,out=-4,elbow=6},la={raise=80,out=-30,elbow=30},lf={z=-.8}},"out"},
		{2,{root={y=-.44,z=-.36,yaw=18,pitch=6},torso={yaw=-12,pitch=4},ra={raise=84,out=-4,elbow=8},la={raise=80,out=-30,elbow=30},lf={z=-.8}}},
		{3,"T"}})
	Q.Light2=clip(P,{ -- the heel swung back across at the forearm, the hands changing
		{0,{root={y=-.4,yaw=10},torso={yaw=-30},ra={raise=90,out=-50,twist=60,elbow=60},la={raise=70,out=10,elbow=60}}},
		{1,{root={y=-.44,yaw=60,pitch=4},torso={yaw=30,pitch=4},head={yaw=-30},ra={raise=88,out=50,twist=-60,elbow=20},la={raise=80,out=20,elbow=40}},"out"},
		{2,{root={y=-.44,yaw=62,pitch=4},torso={yaw=32,pitch=4},ra={raise=86,out=52,twist=-60,elbow=22},la={raise=80,out=20,elbow=40}}},
		{3,"T"}})
	Q.Light3=clip(P,{ -- the lever: from under, then up and aside
		{0,{root={y=-.8,pitch=14,yaw=20},torso={pitch=8},ra={raise=10,out=30,elbow=40},la={raise=40,out=-10,elbow=60}}},
		{1,{root={y=-.3,z=-.4,yaw=10},torso={pitch=-6,yaw=-14},ra={raise=120,out=40,elbow=10},la={raise=100,out=-20,elbow=30},lf={z=-.9}},"out"},
		{2,{root={y=-.3,z=-.42,yaw=8},torso={pitch=-6,yaw=-16},ra={raise=122,out=42,elbow=12},la={raise=100,out=-20,elbow=30},lf={z=-.9}}},
		{3,"T"}})
	Q.Heavy=clip(P,{ -- the staff brought to the hip, a short two-handed arc to the shoulder
		{0,{root={y=-.6,yaw=60},torso={yaw=40},ra={raise=20,out=60,twist=-30,elbow=60},la={raise=40,out=30,elbow=70}}},
		{.75,{root={y=-.64,yaw=64},torso={yaw=44},ra={raise=18,out=62,twist=-30,elbow=62},la={raise=40,out=30,elbow=70}}},
		{1,{root={y=-.5,z=-.5,yaw=0,pitch=8},torso={yaw=-30,pitch=6},ra={raise=110,out=-20,elbow=10},la={raise=96,out=-30,elbow=30},lf={z=-1.0},rf={z=.8}},"out"},
		{2,{root={y=-.5,z=-.52,yaw=-2,pitch=8},torso={yaw=-32,pitch=6},ra={raise=108,out=-22,elbow=12},la={raise=96,out=-30,elbow=30},lf={z=-1.0},rf={z=.8}}},
		{3,"T"}})
	Q.StaffLever=clip(P,{ -- the point under the arm, then the lever lifts
		{0,{root={y=-.9,pitch=16},torso={pitch=10},ra={raise=0,out=20,elbow=30},la={raise=30,out=-10,elbow=50}}},
		{1,{root={y=-.1,z=-.3,pitch=-10},torso={pitch=-12},head={pitch=-16},ra={raise=160,out=10,elbow=20},la={raise=140,out=-10,elbow=30},rf={toe=-20}},"out"},
		{2,{root={y=-.1,z=-.32,pitch=-12},torso={pitch=-14},ra={raise=162,out=10,elbow=22},la={raise=142,out=-10,elbow=30},rf={toe=-18}}},
		{3,"T"}})
	Q.GripSwitch=clip(P,{ -- the hands swap on the staff, the heel from the other side
		{0,{root={y=-.44,yaw=-20},torso={yaw=-20},ra={raise=60,out=-60,twist=70,elbow=50},la={raise=60,out=20,elbow=50}}},
		{1,{root={y=-.48,yaw=80,pitch=4},torso={yaw=40},head={yaw=-40},ra={raise=80,out=60,twist=-40,elbow=16},la={raise=70,out=30,elbow=40},lf={x=.5,z=-.6}},"out"},
		{2,{root={y=-.48,yaw=82,pitch=4},torso={yaw=42},ra={raise=78,out=62,twist=-40,elbow=18},la={raise=70,out=30,elbow=40},lf={x=.5,z=-.6}}},
		{3,"T"}})
	Q.HeelSweep=clip(P,{ -- low, the heel of the staff at the ankles, then a step back
		{0,{root={y=-.9,pitch=16,yaw=40},torso={yaw=30},ra={raise=-10,out=40,twist=-40,elbow=20},la={raise=30,out=10,elbow=60}}},
		{1,{root={y=-1.1,pitch=20,yaw=-10},torso={yaw=-30,pitch=10},ra={raise=-10,out=-40,twist=40,elbow=20},la={raise=20,out=30,elbow=50},lf={z=-1.0},rf={z=1.0}},"out"},
		{2,{root={y=-1.1,pitch=20,yaw=-12},torso={yaw=-32,pitch=10},ra={raise=-10,out=-44,twist=40,elbow=22},la={raise=20,out=30,elbow=50},lf={z=-1.0},rf={z=1.0}}},
		{3,"T"}})
	Q.StaffThrust=clip(P,{ -- the point answers: one straight thrust
		{0,{root={y=-.46,yaw=44,z=.1},torso={yaw=14},ra={raise=50,out=20,elbow=110},la={raise=60,out=-30,elbow=60}}},
		{1,{root={y=-.5,z=-.45,yaw=16,pitch=8},torso={yaw=-12,pitch=6},ra={raise=88,out=-4,elbow=4},la={raise=84,out=-30,elbow=24},lf={z=-.95},rf={z=.8}},"out"},
		{2,{root={y=-.5,z=-.46,yaw=14,pitch=8},torso={yaw=-14,pitch=6},ra={raise=86,out=-4,elbow=6},la={raise=84,out=-30,elbow=24},lf={z=-.95},rf={z=.8}}},
		{3,"T"}})
	Q.Air1=clip(P,{ -- in the air: a short thrust
		{0,{air={ra={raise=50,out=20,elbow=110},la={raise=60,out=-20,elbow=60}}}},
		{1,{air={torso={pitch=10},ra={raise=90,out=-4,elbow=4},la={raise=80,out=-20,elbow=30}}},"out"},
		{2,{air={torso={pitch=10},ra={raise=88,out=-4,elbow=6},la={raise=80,out=-20,elbow=30}}}},
		{3,{air={}}}})
	Q.StaffBeat=clip(P,{ -- in the air: the staff beaten down
		{0,{air={root={pitch=-12},torso={pitch=-16},ra={raise=172,out=8,elbow=40},la={raise=160,out=-6,elbow=50}}}},
		{1,{air={root={pitch=30},torso={pitch=28},ra={raise=40,out=-6,elbow=8},la={raise=36,out=-10,elbow=14}}},"out"},
		{2,{air={root={pitch=32},torso={pitch=28},ra={raise=38,out=-6,elbow=10},la={raise=34,out=-10,elbow=16}}}},
		{3,{air={}}}})
	E.CLIPS.Professor=Q
	setmetatable(Q,{__index=E.CLIPS.Mirage})
end
return Wave4Motion
