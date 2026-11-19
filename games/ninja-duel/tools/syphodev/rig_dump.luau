-- The fighter's real skeleton (Server/World.RIG, the numbers World.rig builds
-- every fighter with; tests/Avatar.spec checks they stay equal) written as the
-- rig.json of SyphoDev's joint-space animation route
-- (.claude/skills/roblox-animation/scripts/r6_clip.py). SyphoDev reads the joints
-- out of Studio through the MCP; here they come from the same source the game
-- builds them from, and tools/syphodev/README.md has the Studio parity check.
--   lune run tools/syphodev/rig_dump.luau <out/rig.json>     (from games/ninja-duel)
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local process=require("@lune/process")
local H=require("../../tests/Harness")
local Vector3=require("@lune/roblox").Vector3

local savedGet=H.envBase.game.GetService
H.envBase.game.GetService=function(g,name)
	local ok,s=pcall(savedGet,g,name);if ok then return s end
	return setmetatable({},{__index=function() return function() return false end end})
end
local World=H.load("Server/World")
H.envBase.game.GetService=savedGet

local RIG=World.RIG
-- Frame of the route: Roblox studs, +Y up, -Z forward, feet at y=0, the root
-- at its rest. In play the Motor6D chain places every part
-- (Part1 = Part0 * C0 * C1:Inverse()), not the build offsets of RIG.parts, so
-- the feet's depth is read down the chain (identity rotations at rest).
local centre={HumanoidRootPart=Vector3.zero}
local pending=table.clone(RIG.joints)
while #pending>0 do
	local moved=false
	for i=#pending,1,-1 do
		local j=pending[i]
		if centre[j[2]] then centre[j[3]]=centre[j[2]]+j[4]-j[5];table.remove(pending,i);moved=true end
	end
	assert(moved,"the joint chain does not reach every part")
end
local low=math.huge
for name,spec in RIG.parts do
	if string.find(name,"Foot") then low=math.min(low,centre[name].Y-spec[1].Y/2) end
end
local function r(x) return math.round(x*1e4)/1e4 end
local function v(x) return {r(x.X),r(x.Y),r(x.Z)} end
local ID={{1,0,0},{0,1,0},{0,0,1}}
local out={hrp={0,r(-low),0},parts={},joints={},
	-- read by the Ninja Duel names patch of r6_clip.py
	root_joint="Root",up_joints={"Root","Waist","Neck"},torsos={"LowerTorso","UpperTorso"},
	feet={"RightFoot","LeftFoot"},arms={"RightHand","LeftHand","RightLowerArm","LeftLowerArm"},
	arm_check_below_y=99,
	-- part name -> box size, for make_parts.py
	sizes={},
	-- motor name -> the clip key AuthoredClips uses (the shoulders are "Right"/"Left")
	clip_keys={}}
local nparts=0
for name,spec in RIG.parts do
	out.parts[name]={glb=name};nparts+=1
	out.sizes[name]=v(spec[1])
end
for _,j in RIG.joints do
	table.insert(out.joints,{name=j[1],part0=j[2],part1=j[3],
		c0={pos=v(j[4]),rows=ID},c1={pos=v(j[5]),rows=ID}})
	out.clip_keys[j[1]]=if j[1]=="RightShoulder" then "Right" elseif j[1]=="LeftShoulder" then "Left" else j[1]
end
-- --check <rig.json>: the committed rig.json (read by the Mac renders, which
-- have no Lune) must still be the game's skeleton; tests/run.sh runs this.
if process.args[1]=="--check" then
	local function same(a,b)
		if type(a)~=type(b) then return false end
		if type(a)=="number" then return math.abs(a-b)<1e-6 end
		if type(a)~="table" then return a==b end
		for k,x in a do if not same(x,b[k]) then return false end end
		for k in b do if a[k]==nil then return false end end
		return true
	end
	local saved=serde.decode("json",fs.readFile(process.args[2]))
	if not same(saved,serde.decode("json",serde.encode("json",out))) then
		print("FAIL "..process.args[2].." is not World.RIG any more: run lune run tools/syphodev/rig_dump.luau "..process.args[2])
		process.exit(1)
	end
	print(("PASS rig.json = World.RIG (%d parts, %d joints)"):format(nparts,#RIG.joints))
	return
end
local path=process.args[1] or "rig.json"
fs.writeFile(path,serde.encode("json",out,true))
print(("wrote %s: %d parts, %d joints, feet %.3f below the root"):format(path,nparts,#RIG.joints,-low))
