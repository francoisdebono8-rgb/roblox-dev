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
end
return Wave1Motion
