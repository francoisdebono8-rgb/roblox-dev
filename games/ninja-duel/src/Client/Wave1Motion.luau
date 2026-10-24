-- Roster batch 1 bodies authored from their Combat Bibles (DEC-026). First:
-- Zabuza (docs/characters/ZABUZA.md §2–§7, §11, B): Kubikiribōchō held in
-- both hands from the guard to the recovery (Wave1FX welds it to the right
-- hand; the left hand rides the handle). The weight goes first, the blade
-- follows; the handle works close, the edge works far; every recovery takes
-- the mass back. No fan clip any more.
-- Keys as in Wave4Motion: 0 wind-up, 1 contact ("out"), 2 end of the live
-- window, 3 back to the stance (the server's startup/active/recovery set
-- their length). What is not authored (throws, grab, wall dive) falls back
-- to Itachi's body (Mirage). Presentation only.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Wave1Motion={}
function Wave1Motion.install(E)
	local K,merge=E.K,E.merge
	local AIR={root={pitch=4},torso={pitch=6},head={pitch=-6},ra={raise=70,out=10,elbow=60},la={raise=66,out=-10,elbow=70},rl={lift=50,knee=86,ankle=-10},ll={lift=30,knee=64,ankle=-10}}
	local function clip(T,keys)
		local out={}
		for i,k in keys do
			local at,pose,ease=k[1],k[2],k[3]
			out[i]=K(at,if pose=="T" then T elseif pose.air then merge(AIR,pose.air) else merge(T,pose),ease)
		end
		return out
	end
	-- The left hand stays on the handle unless a gesture lets it go.
	local function both(ra,extra)
		local la={raise=ra.raise-4,out=(ra.out or 0)-14,twist=(ra.twist or 0),elbow=(ra.elbow or 0)+16,wrist=-10}
		local pose={ra=ra,la=la}
		for key,value in extra or {} do pose[key]=value end
		return pose
	end

	local Z=Fighters.Mist.Motion.stance
	local C={}
	-- L1: the handle, short, into the sternum; the blade stays high on the diagonal.
	C.Light1=clip(Z,{
		{0,both({raise=60,out=10,twist=-10,elbow=96},{root={y=-.6,yaw=30,z=.1},torso={yaw=14}})},
		{1,both({raise=86,out=-6,twist=-10,elbow=24},{root={y=-.62,z=-.35,yaw=20,pitch=6},torso={yaw=-4,pitch=6},lf={z=-.85}}),"out"},
		{2,both({raise=84,out=-6,twist=-10,elbow=28},{root={y=-.62,z=-.36,yaw=20,pitch=6},torso={yaw=-6,pitch=6},lf={z=-.85}})},
		{3,"T"}})
	-- L2: the edge, a horizontal arc right to left at the ribs, 60° of hip.
	C.Light2=clip(Z,{
		{0,both({raise=86,out=70,twist=-30,elbow=30},{root={y=-.62,yaw=58},torso={yaw=44,pitch=2},head={yaw=-30}})},
		{.7,both({raise=88,out=74,twist=-30,elbow=30},{root={y=-.64,yaw=62},torso={yaw=48,pitch=2},head={yaw=-32}})},
		{1,both({raise=90,out=-58,twist=20,elbow=12},{root={y=-.6,z=-.25,yaw=-4,pitch=4},torso={yaw=-40,pitch=4},head={yaw=-6},rf={z=.5,yaw=10}}),"out"},
		{2,both({raise=88,out=-64,twist=20,elbow=14},{root={y=-.6,z=-.26,yaw=-6,pitch=4},torso={yaw=-44,pitch=4},rf={z=.5,yaw=10}})},
		{3,"T"}})
	-- L3: the reverse cut from high left down to the opposite hip; the weight
	-- falls on the front foot and the blade visibly brakes.
	C.Light3=clip(Z,{
		{0,both({raise=156,out=-40,twist=40,elbow=40},{root={y=-.5,yaw=-20,pitch=-4},torso={yaw=-34,pitch=-6},head={pitch=-6}})},
		{.75,both({raise=162,out=-42,twist=40,elbow=44},{root={y=-.48,yaw=-22,pitch=-6},torso={yaw=-36,pitch=-8}})},
		{1,both({raise=26,out=46,twist=-20,elbow=10},{root={y=-.86,z=-.45,yaw=24,pitch=16},torso={yaw=26,pitch=18},head={pitch=8},lf={z=-1.05},rf={z=.8}}),"out"},
		{2,both({raise=20,out=50,twist=-20,elbow=12},{root={y=-.9,z=-.46,yaw=26,pitch=18},torso={yaw=28,pitch=20},lf={z=-1.05},rf={z=.8}})},
		{2.6,both({raise=22,out=48,twist=-20,elbow=16},{root={y=-.84,z=-.4,yaw=24,pitch=14},torso={yaw=24,pitch=16},lf={z=-1.0},rf={z=.8}})},
		{3,"T"}})
	-- Heavy: the cleaver charged over the shoulder, the rear foot pushes, a
	-- long diagonal down; the point ends low and must be taken back.
	C.Heavy=clip(Z,{
		{0,both({raise=172,out=26,twist=-20,elbow=76},{root={y=-.62,yaw=44,pitch=-4,z=.15},torso={yaw=36,pitch=-6},head={yaw=-26},rf={z=.95}})},
		{.8,both({raise=176,out=28,twist=-20,elbow=80},{root={y=-.66,yaw=48,pitch=-6,z=.18},torso={yaw=40,pitch=-8},head={yaw=-28},rf={z=1.0}})},
		{1,both({raise=34,out=-44,twist=24,elbow=8},{root={y=-.88,z=-.7,yaw=-12,pitch=18},torso={yaw=-34,pitch=18},head={pitch=8},lf={z=-1.15},rf={z=.85}}),"out"},
		{2,both({raise=24,out=-48,twist=24,elbow=10},{root={y=-.92,z=-.72,yaw=-14,pitch=20},torso={yaw=-36,pitch=20},lf={z=-1.15},rf={z=.85}})},
		{2.6,both({raise=26,out=-46,twist=24,elbow=14},{root={y=-.86,z=-.64,yaw=-12,pitch=16},torso={yaw=-32,pitch=16},lf={z=-1.1},rf={z=.85}})},
		{3,"T"}})
	-- Forward after two: the handle lifts the forearm, then the blade rises from the hip; the legs push.
	C.CleaverRise=clip(Z,{
		{0,both({raise=100,out=-10,twist=10,elbow=96},{root={y=-.95,pitch=14,yaw=16},torso={pitch=10,yaw=10}})},
		{1,both({raise=170,out=14,twist=-10,elbow=14},{root={y=-.15,z=-.3,pitch=-10,yaw=12},torso={pitch=-12,yaw=-6},head={pitch=-16},rf={toe=-20}}),"out"},
		{2,both({raise=172,out=14,twist=-10,elbow=16},{root={y=-.15,z=-.32,pitch=-12,yaw=12},torso={pitch=-14,yaw=-6},head={pitch=-16},rf={toe=-18}})},
		{3,"T"}})
	-- Side after one: the outer foot steps and the edge covers the flank (not a pirouette).
	C.CleaverArc=clip(Z,{
		{0,both({raise=80,out=-60,twist=30,elbow=30},{root={y=-.66,yaw=-36},torso={yaw=-40},lf={x=.45}})},
		{1,both({raise=84,out=64,twist=-30,elbow=12},{root={y=-.66,yaw=40,pitch=4},torso={yaw=44,pitch=4},head={yaw=-34},lf={x=.7,z=-.6}}),"out"},
		{2,both({raise=82,out=68,twist=-30,elbow=14},{root={y=-.66,yaw=42,pitch=4},torso={yaw=46,pitch=4},lf={x=.7,z=-.6}})},
		{3,"T"}})
	-- Away after two: a low cut as he backs off, the point keeps the space then returns.
	C.CleaverDrop=clip(Z,{
		{0,both({raise=60,out=40,twist=-20,elbow=30},{root={y=-.7,yaw=30},torso={yaw=24,pitch=6}})},
		{1,both({raise=12,out=-44,twist=30,elbow=8},{root={y=-1.05,z=.35,yaw=-10,pitch=22},torso={yaw=-30,pitch=16},lf={z=-.5},rf={z=1.2}}),"out"},
		{2,both({raise=14,out=-40,twist=30,elbow=10},{root={y=-1.0,z=.4,yaw=-8,pitch=20},torso={yaw=-28,pitch=14},lf={z=-.5},rf={z=1.25}})},
		{3,"T"}})
	-- The handle answers a held guard (riposte), and the heavy after one keeps it.
	C.CleaverHilt=clip(Z,{
		{0,both({raise=70,out=20,twist=-20,elbow=100},{root={y=-.58,yaw=34,z=.1},torso={yaw=20}})},
		{1,both({raise=92,out=-10,twist=-10,elbow=14},{root={y=-.6,z=-.4,yaw=12,pitch=8},torso={yaw=-12,pitch=8},lf={z=-.9}}),"out"},
		{2,both({raise=90,out=-10,twist=-10,elbow=16},{root={y=-.6,z=-.42,yaw=10,pitch=8},torso={yaw=-14,pitch=8},lf={z=-.9}})},
		{3,"T"}})
	-- Silent Killing: arrival with the blade already up, the weight behind it.
	C.SilentCleave=clip(Z,{
		{0,both({raise=168,out=20,twist=-20,elbow=60},{root={y=-.6,yaw=40},torso={yaw=34,pitch=-6}})},
		{1,both({raise=30,out=-40,twist=24,elbow=8},{root={y=-.86,z=-.6,yaw=-10,pitch=18},torso={yaw=-30,pitch=18},lf={z=-1.1}}),"out"},
		{2,both({raise=24,out=-44,twist=24,elbow=10},{root={y=-.9,z=-.62,yaw=-12,pitch=20},torso={yaw=-32,pitch=20},lf={z=-1.1}})},
		{3,"T"}})
	-- Air: a short strike of the flat, then the descending terminal cut.
	C.Air1=clip(Z,{
		{0,{air={torso={yaw=24},ra={raise=110,out=40,elbow=60},la={raise=104,out=26,elbow=76}}}},
		{1,{air={torso={yaw=-20,pitch=10},ra={raise=86,out=-30,elbow=12},la={raise=80,out=-44,elbow=28}}},"out"},
		{2,{air={torso={yaw=-22,pitch=10},ra={raise=84,out=-32,elbow=14},la={raise=78,out=-46,elbow=30}}}},
		{3,{air={}}}})
	C.Air2=clip(Z,{
		{0,{air={root={pitch=-8},torso={pitch=-12},ra={raise=168,out=10,elbow=50},la={raise=162,out=-4,elbow=66}}}},
		{1,{air={root={pitch=24},torso={pitch=24},ra={raise=40,out=-10,elbow=8},la={raise=36,out=-24,elbow=24}}},"out"},
		{2,{air={root={pitch=26},torso={pitch=24},ra={raise=38,out=-10,elbow=10},la={raise=34,out=-24,elbow=26}}}},
		{3,{air={}}}})
	C.CleaverDive=clip(Z,{
		{0,{air={root={pitch=-14},torso={pitch=-18},ra={raise=176,out=8,elbow=40},la={raise=170,out=-6,elbow=56}}}},
		{1,{air={root={pitch=34},torso={pitch=30},ra={raise=30,out=-6,elbow=8},la={raise=26,out=-20,elbow=24}}},"out"},
		{2,{air={root={pitch=36},torso={pitch=30},ra={raise=28,out=-6,elbow=10},la={raise=24,out=-20,elbow=26}}}},
		{3,{air={}}}})
	C.Slam=C.CleaverDive
	-- Dash strike: the handle first (an entry, not a brawler's dive).
	C.DashAttack=C.CleaverHilt
	E.CLIPS.Mist=C
	setmetatable(C,{__index=E.CLIPS.Mirage})
	-- A heavy run: shorter stride, little bounce, the blade near the flank.
	E.GAIT.Mist={stride=.9,cadence=.86,arm=6,lean=4,bob=.9,guard=.6,holdRear=false}

	-- Kimimaro (docs/characters/KIMIMARO.md §2–§7, §11, B): a living
	-- skeleton in the blows, not a white sword on a brawler. Wave1FX grows
	-- the bone on the limb that strikes (knuckles, elbow, shin, forearms)
	-- before the contact and retracts it after.
	local K2=Fighters.Bone.Motion.stance
	local B={}
	-- L1: a straight right, the knuckle bones lengthen it; a step in, the elbow by the ribs.
	B.Light1=clip(K2,{
		{0,{ra={raise=62,out=6,twist=10,elbow=112},la={raise=60,out=-10,elbow=100},root={y=-.52,yaw=32},torso={yaw=16}}},
		{1,{ra={raise=88,out=-4,twist=0,elbow=4},la={raise=56,out=-14,elbow=110},root={y=-.52,z=-.35,yaw=10,pitch=6},torso={yaw=-18,pitch=4},lf={z=-.8}},"out"},
		{2,{ra={raise=86,out=-4,twist=0,elbow=8},la={raise=56,out=-14,elbow=110},root={y=-.52,z=-.36,yaw=8,pitch=6},torso={yaw=-20,pitch=4},lf={z=-.8}}},
		{3,"T"}})
	-- L2: the left elbow from outside to the ribs on a turn of the hip; the
	-- spur grows before the contact.
	B.Light2=clip(K2,{
		{0,{la={raise=74,out=56,twist=-10,elbow=128},ra={raise=60,out=-10,elbow=110},root={y=-.56,yaw=34},torso={yaw=30},head={yaw=-20},rf={yaw=40}}},
		{1,{la={raise=88,out=-30,twist=20,elbow=140},ra={raise=56,out=-10,elbow=110},root={y=-.56,z=-.25,yaw=-16,pitch=4},torso={yaw=-40,pitch=4},head={yaw=-6},rf={yaw=60}},"out"},
		{2,{la={raise=86,out=-32,twist=20,elbow=140},ra={raise=56,out=-10,elbow=110},root={y=-.56,z=-.26,yaw=-18,pitch=4},torso={yaw=-42,pitch=4},rf={yaw=60}}},
		{3,"T"}})
	-- L3: a short round kick of the rear leg, hip to shoulder; the shin
	-- spurs bite then retract; a 90° pivot and a visible landing.
	B.Light3=clip(K2,{
		{0,{root={y=-.6,yaw=-34,pitch=6},torso={yaw=-18},ra={raise=56,out=-6,elbow=112},la={raise=56,out=-4,elbow=112},rl={lift=64,out=18,knee=106,ankle=-10},lf={z=-.35,yaw=-30}}},
		{1,{root={y=-.34,yaw=60,pitch=-6,roll=-18},torso={yaw=12,roll=-22},head={roll=14,yaw=-30},ra={raise=-4,out=40,elbow=46},la={raise=62,out=-6,twist=18,elbow=104},rl={lift=84,out=56,twist=-28,knee=12,ankle=-24},lf={z=-.3,yaw=40}},"out"},
		{2,{root={y=-.36,yaw=72,pitch=-4,roll=-16},torso={yaw=16,roll=-18},ra={raise=-4,out=40,elbow=48},la={raise=60,out=-6,twist=18,elbow=104},rl={lift=78,out=58,twist=-30,knee=18,ankle=-20},lf={z=-.3,yaw=52}}},
		{2.5,{root={y=-.56,yaw=50},rl={lift=36,out=18,knee=80},lf={z=-.3,yaw=36}}},
		{3,"T"}})
	-- Heavy: the elbows cross, ribs and forearms make an offensive guard,
	-- then the shoulder pushes; the spurs fold back in the recovery.
	B.Heavy=clip(K2,{
		{0,{ra={raise=82,out=-38,twist=40,elbow=118},la={raise=80,out=-38,twist=40,elbow=120},root={y=-.72,pitch=10,yaw=20,z=.12},torso={pitch=10,yaw=14},head={pitch=4}}},
		{.8,{ra={raise=84,out=-40,twist=40,elbow=120},la={raise=82,out=-40,twist=40,elbow=122},root={y=-.76,pitch=12,yaw=22,z=.14},torso={pitch=12,yaw=16}}},
		{1,{ra={raise=94,out=-20,twist=30,elbow=84},la={raise=92,out=-22,twist=30,elbow=88},root={y=-.6,z=-.65,pitch=14,yaw=-24},torso={pitch=10,yaw=-26},head={yaw=12},lf={z=-1.05},rf={z=.75}},"out"},
		{2,{ra={raise=92,out=-20,twist=30,elbow=86},la={raise=90,out=-22,twist=30,elbow=90},root={y=-.62,z=-.66,pitch=14,yaw=-26},torso={pitch=10,yaw=-28},lf={z=-1.05},rf={z=.75}}},
		{2.6,{ra={raise=80,out=-10,twist=20,elbow=96},la={raise=78,out=-12,twist=20,elbow=100},root={y=-.58,z=-.58,pitch=10,yaw=-20},torso={pitch=8,yaw=-20},lf={z=-1.0},rf={z=.75}}},
		{3,"T"}})
	-- Forward after two: the bone forearm rises under the guard and carries the body (a bounded lift).
	B.BoneRise=clip(K2,{
		{0,{ra={raise=40,out=10,twist=20,elbow=120},la={raise=70,out=-20,elbow=110},root={y=-.95,pitch=14,yaw=14},torso={pitch=12,yaw=10}}},
		{1,{ra={raise=156,out=8,twist=20,elbow=70},la={raise=60,out=-20,elbow=110},root={y=-.2,z=-.3,pitch=-10,yaw=6},torso={pitch=-12,yaw=-6},head={pitch=-14},rf={toe=-20}},"out"},
		{2,{ra={raise=158,out=8,twist=20,elbow=72},la={raise=60,out=-20,elbow=110},root={y=-.2,z=-.32,pitch=-12,yaw=6},torso={pitch=-14,yaw=-6},rf={toe=-18}}},
		{3,"T"}})
	-- Side after one: the flank elbow on an arc of the hip (the bone follows the real limb).
	B.CamelliaArc=clip(K2,{
		{0,{ra={raise=76,out=60,twist=-10,elbow=128},root={y=-.56,yaw=-36},torso={yaw=-40},lf={x=.45}}},
		{1,{ra={raise=88,out=-34,twist=20,elbow=140},root={y=-.56,yaw=40,pitch=4},torso={yaw=44,pitch=4},head={yaw=-30},lf={x=.7,z=-.5}},"out"},
		{2,{ra={raise=86,out=-36,twist=20,elbow=140},root={y=-.56,yaw=42,pitch=4},torso={yaw=46,pitch=4},lf={x=.7,z=-.5}}},
		{3,"T"}})
	-- Away after two: the leg reaps with brief shin spurs, the body backs off.
	B.BoneReap=clip(K2,{
		{0,{root={y=-.8,yaw=-20,pitch=10},torso={yaw=-10,pitch=8},ra={raise=50,out=-10,elbow=110},la={raise=50,out=-10,elbow=110},rl={lift=20,out=10,knee=60}}},
		{1,{root={y=-1.0,z=.35,yaw=46,pitch=16},torso={yaw=20,pitch=12},ra={raise=30,out=30,elbow=60},la={raise=60,out=-20,elbow=100},rl={lift=40,out=60,twist=-20,knee=10,ankle=-10},lf={z=.1,yaw=30}},"out"},
		{2,{root={y=-1.0,z=.4,yaw=52,pitch=16},torso={yaw=22,pitch=12},rl={lift=36,out=62,twist=-20,knee=14},lf={z=.12,yaw=34}}},
		{3,"T"}})
	-- The bone elbow answers a held guard.
	B.BoneElbow=clip(K2,{
		{0,{la={raise=76,out=50,twist=-10,elbow=130},root={y=-.56,yaw=36},torso={yaw=28}}},
		{1,{la={raise=90,out=-30,twist=20,elbow=140},root={y=-.56,z=-.4,yaw=-10,pitch=6},torso={yaw=-36,pitch=6},lf={z=-.85}},"out"},
		{2,{la={raise=88,out=-32,twist=20,elbow=140},root={y=-.56,z=-.42,yaw=-12,pitch=6},torso={yaw=-38,pitch=6},lf={z=-.85}}},
		{3,"T"}})
	-- Willow (signature): a lunge, the forearm bones out ahead.
	B.WillowCut=clip(K2,{
		{0,{ra={raise=60,out=20,elbow=120},la={raise=60,out=20,elbow=120},root={y=-.8,pitch=18,z=.2},torso={pitch=12}}},
		{1,{ra={raise=96,out=-10,twist=20,elbow=20},la={raise=92,out=-14,twist=20,elbow=24},root={y=-.62,z=-.8,pitch=20,yaw=-10},torso={pitch=14,yaw=-14},lf={z=-1.2},rf={z=.9}},"out"},
		{2,{ra={raise=94,out=-10,twist=20,elbow=22},la={raise=90,out=-14,twist=20,elbow=26},root={y=-.62,z=-.82,pitch=20,yaw=-10},torso={pitch=14,yaw=-14},lf={z=-1.2},rf={z=.9}}},
		{3,"T"}})
	-- Air: a knee with a short spur, then the bone heel driven down.
	B.Air1=clip(K2,{
		{0,{air={rl={lift=40,knee=120},ra={raise=80,out=20,elbow=90},la={raise=70,out=10,elbow=90}}}},
		{1,{air={root={pitch=10},rl={lift=110,knee=130},ra={raise=50,out=30,elbow=60},la={raise=60,out=20,elbow=80}}},"out"},
		{2,{air={root={pitch=10},rl={lift=106,knee=128}}}},
		{3,{air={}}}})
	B.Air2=clip(K2,{
		{0,{air={root={pitch=-10},rl={lift=150,knee=10,ankle=-30},ra={raise=40,out=40,elbow=30},la={raise=40,out=40,elbow=30}}}},
		{1,{air={root={pitch=24},rl={lift=40,knee=10,ankle=20},ra={raise=60,out=30,elbow=40},la={raise=60,out=30,elbow=40}}},"out"},
		{2,{air={root={pitch=26},rl={lift=36,knee=12,ankle=20}}}},
		{3,{air={}}}})
	B.BoneHeel=B.Air2
	B.Slam=B.Air2
	-- Dash strike: an elbow entry, the spur born during the push.
	B.DashAttack=clip(K2,{
		{0,{ra={raise=76,out=50,twist=-10,elbow=128},root={y=-.7,pitch=18},torso={pitch=12,yaw=20}}},
		{1,{ra={raise=88,out=-30,twist=20,elbow=140},root={y=-.62,z=-.55,pitch=18,yaw=-16},torso={pitch=12,yaw=-30},lf={z=-1.0}},"out"},
		{2,{ra={raise=86,out=-32,twist=20,elbow=140},root={y=-.62,z=-.56,pitch=18,yaw=-16},torso={pitch=12,yaw=-32},lf={z=-1.0}}},
		{3,"T"}})
	E.CLIPS.Bone=B
	setmetatable(B,{__index=E.CLIPS.Lion})
	-- Fluid, the bones do not trail: a light gliding stride.
	E.GAIT.Bone={stride=1.0,cadence=1.02,arm=5,lean=6,bob=.8,guard=.7,holdRear=false}

	-- Haku (docs/characters/HAKU.md §2–§7, §11, B): precise touches with the
	-- senbon held in the fingers, ice only in the transitions (a spike at the
	-- wrist, a thin plate under the gliding foot: Wave1FX). Not seven
	-- projectiles per light, not an ice mallet.
	local H=Fighters.Mirror.Motion.stance
	local M={}
	-- L1: the right hand pricks obliquely at the shoulder; a short inner step.
	M.Light1=clip(H,{
		{0,{ra={raise=80,out=10,twist=30,elbow=120,wrist=-10},root={y=-.36,yaw=36},torso={yaw=12}}},
		{1,{ra={raise=104,out=-14,twist=20,elbow=24,wrist=-20},root={y=-.38,z=-.25,yaw=14,pitch=4},torso={yaw=-14,pitch=2},lf={z=-.7}},"out"},
		{2,{ra={raise=102,out=-14,twist=20,elbow=28,wrist=-20},root={y=-.38,z=-.26,yaw=12,pitch=4},torso={yaw=-16,pitch=2},lf={z=-.7}}},
		{3,"T"}})
	-- L2: the left palm inside to the forearm, a spike born at the wrist; a
	-- lateral glide on a plate that breaks.
	M.Light2=clip(H,{
		{0,{la={raise=60,out=40,twist=-10,elbow=90,wrist=20},ra={raise=80,out=-10,elbow=110},root={y=-.4,yaw=10,x=.1},torso={yaw=20}}},
		{1,{la={raise=90,out=-20,twist=10,elbow=14,wrist=-40},ra={raise=78,out=-10,elbow=112},root={y=-.42,x=-.4,z=-.15,yaw=-10,pitch=4},torso={yaw=-24,pitch=4},lf={x=-.4}},"out"},
		{2,{la={raise=88,out=-22,twist=10,elbow=16,wrist=-40},ra={raise=78,out=-10,elbow=112},root={y=-.42,x=-.42,z=-.16,yaw=-12,pitch=4},torso={yaw=-26,pitch=4},lf={x=-.4}}},
		{3,"T"}})
	-- L3: the exiting senbon, shoulder to outside while he withdraws; the
	-- outer foot brakes (a small shard marks it).
	M.Light3=clip(H,{
		{0,{ra={raise=110,out=-30,twist=40,elbow=60,wrist=-10},root={y=-.38,yaw=0},torso={yaw=-20}}},
		{1,{ra={raise=90,out=60,twist=-10,elbow=10,wrist=-10},root={y=-.46,z=.3,yaw=40,pitch=-4},torso={yaw=34,pitch=-2},head={yaw=-30},rf={z=.85,x=.4}},"out"},
		{2,{ra={raise=88,out=64,twist=-10,elbow=12,wrist=-10},root={y=-.48,z=.32,yaw=44,pitch=-4},torso={yaw=36,pitch=-2},rf={z=.85,x=.4}}},
		{2.5,{ra={raise=80,out=30,elbow=60},root={y=-.42,z=.2,yaw=34},rf={z=.75,x=.3}}},
		{3,"T"}})
	-- Heavy: the left forearm leans on a short spike, the right hand drives
	-- the senbon in a short push. Readable, little physical push.
	M.Heavy=clip(H,{
		{0,{la={raise=70,out=-10,twist=20,elbow=100,wrist=-20},ra={raise=60,out=20,twist=20,elbow=130,wrist=-10},root={y=-.5,pitch=6,yaw=30,z=.1},torso={pitch=4,yaw=20}}},
		{.8,{la={raise=72,out=-10,twist=20,elbow=102,wrist=-20},ra={raise=58,out=24,twist=20,elbow=134,wrist=-10},root={y=-.52,pitch=8,yaw=32,z=.12},torso={pitch=6,yaw=22}}},
		{1,{la={raise=80,out=-16,twist=20,elbow=90,wrist=-30},ra={raise=94,out=-6,twist=10,elbow=6,wrist=-20},root={y=-.5,z=-.5,pitch=10,yaw=4},torso={pitch=8,yaw=-12},lf={z=-.95},rf={z=.7}},"out"},
		{2,{la={raise=80,out=-16,twist=20,elbow=90,wrist=-30},ra={raise=92,out=-6,twist=10,elbow=8,wrist=-20},root={y=-.5,z=-.52,pitch=10,yaw=2},torso={pitch=8,yaw=-14},lf={z=-.95},rf={z=.7}}},
		{2.6,{la={raise=74,out=-12,elbow=96},ra={raise=86,out=0,elbow=30},root={y=-.46,z=-.44,pitch=8},lf={z=-.9},rf={z=.7}}},
		{3,"T"}})
	-- Forward after two: the wrist takes a hold, a spike lifts the foe's
	-- foot and the palm guides it up.
	M.FrostLift=clip(H,{
		{0,{la={raise=40,out=10,elbow=60,wrist=30},ra={raise=70,out=-10,elbow=110},root={y=-.8,pitch=14,yaw=14},torso={pitch=10,yaw=10}}},
		{1,{la={raise=150,out=10,elbow=20,wrist=-20},ra={raise=80,out=-10,elbow=110},root={y=-.2,z=-.25,pitch=-8,yaw=4},torso={pitch=-10,yaw=-6},head={pitch=-12},rf={toe=-18}},"out"},
		{2,{la={raise=152,out=10,elbow=22,wrist=-20},ra={raise=80,out=-10,elbow=110},root={y=-.2,z=-.26,pitch=-10,yaw=4},torso={pitch=-12,yaw=-6},rf={toe=-16}}},
		{3,"T"}})
	-- Side after one: a lateral glide on ice and a senbon touch.
	M.IceSlide=clip(H,{
		{0,{ra={raise=80,out=-30,twist=40,elbow=110},root={y=-.42,yaw=-24,x=-.2},torso={yaw=-20},lf={x=.3}}},
		{1,{ra={raise=96,out=40,twist=10,elbow=16,wrist=-20},root={y=-.46,x=.6,yaw=30,pitch=4},torso={yaw=30,pitch=2},head={yaw=-26},lf={x=.8,z=-.4}},"out"},
		{2,{ra={raise=94,out=42,twist=10,elbow=18,wrist=-20},root={y=-.46,x=.62,yaw=32,pitch=4},torso={yaw=32,pitch=2},lf={x=.8,z=-.4}}},
		{3,"T"}})
	-- Away after two: a low prick, then the retreat on an ice footing.
	M.SenbonLow=clip(H,{
		{0,{ra={raise=50,out=10,twist=20,elbow=110,wrist=-10},root={y=-.7,yaw=20,pitch=10},torso={yaw=14,pitch=8}}},
		{1,{ra={raise=40,out=-10,twist=10,elbow=10,wrist=-30},root={y=-.95,z=.35,yaw=6,pitch=20},torso={yaw=-10,pitch=16},lf={z=-.4},rf={z=1.15}},"out"},
		{2,{ra={raise=42,out=-10,twist=10,elbow=12,wrist=-30},root={y=-.9,z=.4,yaw=6,pitch=18},torso={yaw=-10,pitch=14},lf={z=-.4},rf={z=1.2}}},
		{3,"T"}})
	-- The senbon to a vital point: the riposte, and the Mirror Step's arrival.
	M.SenbonStab=clip(H,{
		{0,{ra={raise=84,out=0,twist=30,elbow=120,wrist=-10},root={y=-.4,yaw=30,z=.1},torso={yaw=16}}},
		{1,{ra={raise=100,out=-6,twist=20,elbow=6,wrist=-24},root={y=-.42,z=-.4,yaw=8,pitch=6},torso={yaw=-12,pitch=4},head={pitch=2},lf={z=-.85}},"out"},
		{2,{ra={raise=98,out=-6,twist=20,elbow=8,wrist=-24},root={y=-.42,z=-.42,yaw=6,pitch=6},torso={yaw=-14,pitch=4},lf={z=-.85}}},
		{3,"T"}})
	-- Air: a body senbon, then the senbon driven down.
	M.Air1=clip(H,{
		{0,{air={torso={yaw=20},ra={raise=110,out=20,elbow=80,wrist=-10}}}},
		{1,{air={torso={yaw=-16,pitch=8},ra={raise=88,out=-10,elbow=8,wrist=-20}}},"out"},
		{2,{air={torso={yaw=-18,pitch=8},ra={raise=86,out=-10,elbow=10,wrist=-20}}}},
		{3,{air={}}}})
	M.SenbonDive=clip(H,{
		{0,{air={root={pitch=-10},torso={pitch=-12},ra={raise=170,out=6,elbow=30,wrist=-10},la={raise=150,out=-10,elbow=40}}}},
		{1,{air={root={pitch=30},torso={pitch=26},ra={raise=40,out=-6,elbow=6,wrist=-30},la={raise=60,out=-10,elbow=40}}},"out"},
		{2,{air={root={pitch=32},torso={pitch=26},ra={raise=38,out=-6,elbow=8,wrist=-30}}}},
		{3,{air={}}}})
	M.Air2=M.SenbonDive
	M.Slam=M.SenbonDive
	-- Dash strike: a short glide on an ice footing that ends on a planted foot.
	M.DashAttack=clip(H,{
		{0,{ra={raise=80,out=10,twist=30,elbow=120},root={y=-.6,pitch=14},torso={pitch=8}}},
		{1,{ra={raise=100,out=-10,twist=20,elbow=8,wrist=-20},root={y=-.5,z=-.55,pitch=12,yaw=-10},torso={pitch=8,yaw=-16},lf={z=-1.0}},"out"},
		{2,{ra={raise=98,out=-10,twist=20,elbow=10,wrist=-20},root={y=-.5,z=-.56,pitch=12,yaw=-10},torso={pitch=8,yaw=-16},lf={z=-1.0}}},
		{3,"T"}})
	E.CLIPS.Mirror=M
	setmetatable(M,{__index=E.CLIPS.Mirage})
	-- A fine run, limbs close; short gliding steps.
	E.GAIT.Mirror={stride=.95,cadence=1.06,arm=3,lean=6,bob=.7,guard=.6,holdRear=false}
end
return Wave1Motion
