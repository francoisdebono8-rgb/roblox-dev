-- Roster batch 3 bodies authored from their Combat Bibles (DEC-026). First:
-- Killer Bee (docs/characters/KILLER_BEE.md §2–§7, §11, B): a young
-- swordsman with seven blades. Configuration A = a blade in each hand and a
-- third held under the left elbow, four (seven when he stows) sheathed on
-- the back (Wave3FX draws and moves them). Each light strikes from another
-- grip: L1 the right hand, L2 the elbow, L3 the back of the right knee; the
-- heavy opens two blades in an X. The hand blades continue the forearm, so
-- these arm angles are the blades' angles.
-- Keys as in Wave1Motion: 0 wind-up, 1 contact ("out"), 2 end of the live
-- window, 3 back to the stance. What is not authored (throws, grab, wall
-- dive) falls back to the Lion body. Presentation only.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Wave3Motion={}
function Wave3Motion.install(E)
	local K,merge=E.K,E.merge
	local AIR={root={pitch=4},torso={pitch=6},head={pitch=-6},ra={raise=70,out=10,elbow=50},la={raise=66,out=10,elbow=60},rl={lift=50,knee=86,ankle=-10},ll={lift=30,knee=64,ankle=-10}}
	local function clip(T,keys)
		local out={}
		for i,k in keys do
			local at,pose,ease=k[1],k[2],k[3]
			out[i]=K(at,if pose=="T" then T elseif pose.air then merge(AIR,pose.air) else merge(T,pose),ease)
		end
		return out
	end
	-- The off blade keeps a guard while the other one works.
	local RGUARD={raise=96,out=-14,twist=10,elbow=50}
	local LGUARD={raise=92,out=-18,twist=10,elbow=56}

	local B=Fighters.Ink.Motion.stance
	local C={}
	-- L1: the right-hand blade on the diagonal, right hip to the opposite
	-- shoulder; an inner step; the left blade stays up.
	C.Light1=clip(B,{
		{0,{ra={raise=14,out=44,twist=-10,elbow=14},la=LGUARD,root={y=-.56,yaw=30},torso={yaw=18}}},
		{1,{ra={raise=126,out=-36,twist=20,elbow=10},la=LGUARD,root={y=-.52,z=-.45,yaw=8,pitch=6},torso={yaw=-22,pitch=4},lf={z=-.75}},"out"},
		{2,{ra={raise=128,out=-38,twist=20,elbow=12},la=LGUARD,root={y=-.52,z=-.46,yaw=6,pitch=6},torso={yaw=-24,pitch=4},lf={z=-.75}}},
		{3,"T"}})
	-- L2: the blade under the left elbow, a reverse cut from outside to the
	-- ribs on the way back (60° of pivot, not a full turn); the left hand has
	-- taken the other grip and the elbow leads.
	C.Light2=clip(B,{
		{0,{la={raise=84,out=-56,twist=20,elbow=124},ra=RGUARD,root={y=-.6,yaw=52},torso={yaw=36},head={yaw=-28}}},
		{.7,{la={raise=86,out=-58,twist=20,elbow=126},ra=RGUARD,root={y=-.62,yaw=56},torso={yaw=40},head={yaw=-30}}},
		{1,{la={raise=88,out=54,twist=-10,elbow=120},ra=RGUARD,root={y=-.56,z=-.3,yaw=-8,pitch=4},torso={yaw=-38,pitch=4},head={yaw=-4},rf={z=.45,yaw=12}},"out"},
		{2,{la={raise=86,out=58,twist=-10,elbow=120},ra=RGUARD,root={y=-.56,z=-.3,yaw=-10,pitch=4},torso={yaw=-40,pitch=4},rf={z=.45,yaw=12}}},
		{3,"T"}})
	-- L3: the freed blade rides behind the right knee, point out of the body;
	-- a small hip kick swings it flat into the flank, the hand takes it back.
	C.Light3=clip(B,{
		{0,{ra=RGUARD,la=LGUARD,root={y=-.5,yaw=-30,roll=6},torso={yaw=-10},rl={lift=30,out=6,knee=104,ankle=-10},lf={z=-.3,yaw=-30}}},
		{1,{ra={raise=70,out=30,elbow=40},la={raise=80,out=-20,elbow=60},root={y=-.42,yaw=44,roll=-14},torso={yaw=18,roll=-12},head={yaw=-34},rl={lift=56,out=64,twist=-20,knee=92,ankle=-14},lf={z=-.3,yaw=36}},"out"},
		{2,{ra={raise=70,out=30,elbow=40},la={raise=80,out=-20,elbow=60},root={y=-.44,yaw=54,roll=-12},torso={yaw=20,roll=-10},rl={lift=52,out=66,twist=-20,knee=94,ankle=-14},lf={z=-.3,yaw=44}}},
		{2.5,{ra={raise=40,out=10,elbow=60},root={y=-.52,yaw=30},rl={lift=20,out=14,knee=70},lf={z=-.3,yaw=24}}},
		{3,"T"}})
	-- Heavy: the crossed guard opens in an X, the shoulder carries the
	-- weight; two blades on distinct planes, one accent. A long take-back.
	C.Heavy=clip(B,{
		{0,{ra={raise=150,out=-40,twist=20,elbow=24},la={raise=146,out=-40,twist=20,elbow=26},root={y=-.62,pitch=-4,z=.12},torso={pitch=-8},head={pitch=-6}}},
		{.8,{ra={raise=156,out=-44,twist=20,elbow=26},la={raise=150,out=-44,twist=20,elbow=28},root={y=-.64,pitch=-6,z=.14},torso={pitch=-10}}},
		{1,{ra={raise=50,out=56,twist=-10,elbow=4},la={raise=64,out=52,twist=-10,elbow=6},root={y=-.78,z=-.6,pitch=16,yaw=10},torso={pitch=14,yaw=8},head={pitch=6},lf={z=-1.0},rf={z=.8}},"out"},
		{2,{ra={raise=44,out=60,twist=-10,elbow=6},la={raise=58,out=56,twist=-10,elbow=8},root={y=-.8,z=-.62,pitch=18,yaw=10},torso={pitch=16,yaw=8},lf={z=-1.0},rf={z=.8}}},
		{2.6,{ra={raise=50,out=50,twist=-10,elbow=14},la={raise=60,out=46,twist=-10,elbow=16},root={y=-.74,z=-.54,pitch=14,yaw=8},torso={pitch=12},lf={z=-.95},rf={z=.8}}},
		{3,"T"}})
	-- Forward after two: the elbow blade beats the guard down, then the
	-- shoulder and the right blade lift the body (a wrestler's push, not an uppercut).
	C.BladeLift=clip(B,{
		{0,{la={raise=70,out=-36,elbow=126},ra={raise=30,out=20,elbow=30},root={y=-.95,pitch=16,yaw=14},torso={pitch=12,yaw=10}}},
		{1,{la={raise=118,out=10,elbow=100},ra={raise=168,out=10,twist=-10,elbow=8},root={y=-.2,z=-.35,pitch=-10,yaw=6},torso={pitch=-12,yaw=-6},head={pitch=-16},rf={toe=-20}},"out"},
		{2,{la={raise=120,out=10,elbow=100},ra={raise=170,out=10,twist=-10,elbow=10},root={y=-.2,z=-.36,pitch=-12,yaw=6},torso={pitch=-14,yaw=-6},rf={toe=-18}}},
		{3,"T"}})
	-- Side after one: the hand and elbow blades change places, the outer foot
	-- steps out; one edge makes the contact.
	C.BladeSwap=clip(B,{
		{0,{ra={raise=92,out=-50,twist=20,elbow=22},la={raise=70,out=-30,elbow=110},root={y=-.56,yaw=-30},torso={yaw=-34},lf={x=.4}}},
		{1,{ra={raise=90,out=62,twist=-20,elbow=8},la={raise=86,out=-20,elbow=120},root={y=-.56,yaw=38,pitch=4},torso={yaw=42,pitch=4},head={yaw=-30},lf={x=.7,z=-.5}},"out"},
		{2,{ra={raise=88,out=66,twist=-20,elbow=10},la={raise=86,out=-20,elbow=120},root={y=-.56,yaw=40,pitch=4},torso={yaw=44,pitch=4},lf={x=.7,z=-.5}}},
		{3,"T"}})
	-- Away after two: blades barred across, a retreating kick that puts the
	-- knee blade between them; the configuration closes.
	C.KneeKick=clip(B,{
		{0,{ra={raise=104,out=-40,twist=30,elbow=60},la={raise=100,out=-40,twist=30,elbow=64},root={y=-.6,yaw=-20},rl={lift=40,knee=110,ankle=-10}}},
		{1,{ra={raise=104,out=-40,twist=30,elbow=60},la={raise=100,out=-40,twist=30,elbow=64},root={y=-.4,z=.35,yaw=36,pitch=-6,roll=-10},torso={yaw=12,pitch=-6},rl={lift=88,out=40,twist=-20,knee=66,ankle=-20},lf={z=.1,yaw=30}},"out"},
		{2,{ra={raise=102,out=-40,twist=30,elbow=62},la={raise=98,out=-40,twist=30,elbow=66},root={y=-.42,z=.4,yaw=40,pitch=-6,roll=-8},rl={lift=84,out=42,twist=-20,knee=70},lf={z=.12,yaw=34}}},
		{3,"T"}})
	-- The blade nobody expected answers a held guard: the elbow.
	C.ElbowCut=clip(B,{
		{0,{la={raise=82,out=-50,twist=20,elbow=130},ra=RGUARD,root={y=-.58,yaw=40},torso={yaw=30}}},
		{1,{la={raise=90,out=46,twist=-10,elbow=124},ra=RGUARD,root={y=-.56,z=-.4,yaw=-6,pitch=6},torso={yaw=-34,pitch=6},lf={z=-.85}},"out"},
		{2,{la={raise=88,out=48,twist=-10,elbow=124},ra=RGUARD,root={y=-.56,z=-.42,yaw=-8,pitch=6},torso={yaw=-36,pitch=6},lf={z=-.85}}},
		{3,"T"}})
	-- Air: one return cut, then the finisher — two blades crossing in a big X.
	C.Air1=clip(B,{
		{0,{air={torso={yaw=24},ra={raise=140,out=30,elbow=10},la={raise=96,out=-20,elbow=50}}}},
		{1,{air={torso={yaw=-20,pitch=10},ra={raise=50,out=-30,elbow=8},la={raise=96,out=-20,elbow=50}}},"out"},
		{2,{air={torso={yaw=-22,pitch=10},ra={raise=48,out=-32,elbow=10},la={raise=96,out=-20,elbow=50}}}},
		{3,{air={}}}})
	C.Air2=clip(B,{
		{0,{air={root={pitch=-8},torso={pitch=-10},ra={raise=160,out=44,elbow=8},la={raise=158,out=44,elbow=8}}}},
		{1,{air={root={pitch=20},torso={pitch=20},ra={raise=60,out=-44,elbow=4},la={raise=56,out=-44,elbow=4}}},"out"},
		{2,{air={root={pitch=22},torso={pitch=20},ra={raise=56,out=-46,elbow=6},la={raise=52,out=-46,elbow=6}}}},
		{3,{air={}}}})
	-- Air down: the blade brought down (not every weapon thrown).
	C.BladeFall=clip(B,{
		{0,{air={root={pitch=-14},torso={pitch=-16},ra={raise=174,out=8,elbow=10},la={raise=110,out=-20,elbow=50}}}},
		{1,{air={root={pitch=32},torso={pitch=28},ra={raise=36,out=-6,elbow=4},la={raise=80,out=-20,elbow=50}}},"out"},
		{2,{air={root={pitch=34},torso={pitch=28},ra={raise=34,out=-6,elbow=6},la={raise=78,out=-20,elbow=52}}}},
		{3,{air={}}}})
	C.Slam=C.BladeFall
	-- Dash strike: a shoulder entry under a covering blade.
	C.DashAttack=clip(B,{
		{0,{la={raise=112,out=-40,twist=20,elbow=60},ra={raise=30,out=10,elbow=40},root={y=-.7,pitch=20},torso={pitch=14,yaw=-10}}},
		{1,{la={raise=112,out=-40,twist=20,elbow=60},ra={raise=96,out=10,elbow=6},root={y=-.62,z=-.55,pitch=20,yaw=-16},torso={pitch=14,yaw=-24},lf={z=-1.0}},"out"},
		{2,{la={raise=110,out=-40,twist=20,elbow=62},ra={raise=94,out=10,elbow=8},root={y=-.62,z=-.56,pitch=20,yaw=-16},torso={pitch=14,yaw=-24},lf={z=-1.0}}},
		{3,"T"}})
	E.CLIPS.Ink=C
	setmetatable(C,{__index=E.CLIPS.Lion})
	-- Wide but mobile, the weight alternates; two blades steady while running.
	E.GAIT.Ink={stride=1.0,cadence=1.04,arm=4,lean=6,bob=1.1,guard=.6,holdRear=false}
end
return Wave3Motion
