-- (21/11, étape 2 ANIMATEUR 2-3, DEC-045) The ninja's tree on screen: the five natures on the
-- kunai, the impact and the 3rd hit (Client/InfusionFX, Infusion.<Nature>), the explosive tag
-- and the smoke bomb (Client/NinjaToolsFX). Headless: every nature of Shared/NinjaTree has its
-- look under its name, a kunai is dressed once and keeps stepping, the limb is cleaned after
-- the blow, the tools build and the duel layers answer the snapshot's fields. The look itself
-- is a Studio check.
local H=require("./Harness")
local roblox=require("@lune/roblox")
for _,k in {"Instance","Vector3","Vector2","Color3","CFrame","Enum","ColorSequence","ColorSequenceKeypoint","NumberSequence",
	"NumberSequenceKeypoint","NumberRange"} do H.envBase[k]=roblox[k] end
local Infusion=H.load("Client/InfusionFX")
local Tools=H.load("Client/NinjaToolsFX")
local NinjaTree=H.load("Shared/NinjaTree")
local Instance,Vector3,CFrame=roblox.Instance,roblox.Vector3,roblox.CFrame
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function kunai()
	local m=Instance.new("Model")
	local root=Instance.new("Part");root.Name="Root";root.Size=Vector3.new(.2,.2,1.4);root.Parent=m
	m.PrimaryPart=root
	return m,root
end
local PARTS={"HumanoidRootPart","Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
	"LeftHand","RightHand","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"}
local function body()
	local m=Instance.new("Model")
	for _,n in PARTS do local p=Instance.new("Part");p.Name=n;p.Size=Vector3.new(1,1,1);p.Parent=m end
	return m
end
local function named(root,name)
	local n=0
	for _,d in root:GetDescendants() do if d.Name==name then n+=1 end end
	return n
end

test("one look per nature of the ninja's tree, under its name",function()
	assert(#Infusion.NATURES==#NinjaTree.Natures,"natures: the tree has "..#NinjaTree.Natures)
	for i,n in NinjaTree.Natures do
		assert(Infusion.NATURES[i]==n,"nature "..i)
		assert(Infusion.valid(n) and Infusion.id(n)=="Infusion."..n)
	end
	assert(not Infusion.valid("Ice") and not Infusion.valid(nil))
end)

test("the infused kunai: dressed in its nature, it steps, mastery makes it bigger",function()
	for _,n in Infusion.NATURES do
		local m,root=kunai()
		local d=assert(Infusion.kunai(m,root,n,false),n..": nothing")
		assert(named(m,"Infusion."..n)>0,n..": nothing named Infusion."..n)
		assert(m:GetAttribute("Infusion")==n)
		for _=1,5 do d.step(1/60) end
		local m2,root2=kunai()
		local strong=Infusion.kunai(m2,root2,n,true)
		assert(strong.strong and not d.strong)
		local sz,sz2=0,0
		for _,x in m:GetDescendants() do if x:IsA("ParticleEmitter") then sz+=x.Rate end end
		for _,x in m2:GetDescendants() do if x:IsA("ParticleEmitter") then sz2+=x.Rate end end
		assert(sz2>=sz,n..": mastery not denser")
	end
	assert(Infusion.kunai(kunai(),nil,"Fire")==nil and Infusion.kunai(Instance.new("Model"),Instance.new("Part"),"Ice")==nil)
end)

test("the infused impact: a burst in the nature's shape where it lands",function()
	for _,n in Infusion.NATURES do
		local folder=Instance.new("Folder")
		local h=assert(Infusion.impact(folder,Vector3.new(0,3,0),n,true,Vector3.new(0,0,-1),Vector3.yAxis),n)
		assert(h.Parent==folder and named(folder,"Infusion."..n)>0,n..": nothing in the folder")
	end
end)

test("the 3rd hit: the striking limb carries it, then it is cleared",function()
	for _,n in Infusion.NATURES do
		local m=body()
		local made,clear=Infusion.limb(m,"RightFoot",n,false)
		assert(#made>0 and m:GetAttribute("Infusion")==n,n)
		assert(named(m.RightFoot,"Infusion."..n)>0 or named(m,"Infusion."..n)>0,n..": not on the foot")
		clear()
		assert(m:GetAttribute("Infusion")==nil,n..": attribute left")
		for _,x in made do if x:IsA("ParticleEmitter") then assert(not x.Enabled,n..": still emitting") end end
	end
end)

test("in the duel: the DEV's fields drive it (p.ninja, actor.ninja + Light3, impact \"infusion\")",function()
	local fx={folder=Instance.new("Folder"),layers={},projectiles={}}
	local layer=Infusion.install(fx,nil)
	assert(fx.layers[1]==layer,"first in line")
	local m,root=kunai()
	local data={human={id="P1",ninja={nature="Wind",strong=true}},bot={id="AI"}}
	fx.projectiles[1]={data={ninja="Wind",owner="P1"},model=m,root=root}
	local m2,r2=kunai()
	fx.projectiles[2]={data={ninja=true,owner="P1"},model=m2,root=r2}
	layer.frame(fx,data);layer.frame(fx,data)
	local d=fx.projectiles[1].infusion2
	assert(d and d.nature=="Wind" and d.strong,"the kunai was not dressed (or not strong)")
	assert(fx.projectiles[2].infusion2==nil,"a plain kunai was dressed")
	local arena=Instance.new("Folder")
	local target=body();target.Name="AI";target.Parent=arena
	assert(layer.impact(fx,{style="infusion",nature="Fire",how="kunai",target="AI",position=Vector3.new(1,2,3)},arena)==true)
	assert(named(fx.folder,"Infusion.Fire")>0,"no burst")
	assert(target:GetAttribute("InfusionBody")=="Fire" and named(target,"Infusion.Fire.Body")>0,"the target does not burn")
	assert(layer.impact(fx,{style="hit",position=Vector3.zero},arena)==nil,"another style taken")
	for _,n in Infusion.NATURES do assert(Infusion.body(body(),n,true),n..": nothing on the body") end
	local b=body()
	local actor={fighterId="Leaf",attackName="Light3",state="Startup",ninja={nature="Fire",blade=true,ready=true}}
	layer.fighter(fx,b,actor)
	assert(b:GetAttribute("Infusion")=="Fire" and named(b.RightFoot,"Infusion.Fire")>0,"Lee's kick")
	local count=named(b,"Infusion.Fire")
	layer.fighter(fx,b,actor)
	assert(named(b,"Infusion.Fire")==count,"rebuilt every frame")
	local c=body()
	layer.fighter(fx,c,{fighterId="Leaf",attackName="Light3",state="Active",ninja={nature="Fire",blade=true,ready=false}})
	layer.fighter(fx,c,{fighterId="Leaf",attackName="Light2",state="Active",ninja={nature="Fire",blade=true,ready=true}})
	layer.fighter(fx,c,{fighterId="Leaf",attackName="Light3",state="Active",infused="Fire"})
	assert(named(c,"Infusion.Fire")==0,"drawn when the blade is not ready, on another hit, or from a chakra flow")
end)

test("the explosive tag and the smoke bomb build, and their layer answers",function()
	local m,root=kunai()
	local d=Tools.tagKunai(m,root)
	for _=1,4 do d.step(1/60) end
	assert(m:FindFirstChild("ExplosiveTag"),"no tag on the kunai")
	local folder=Instance.new("Folder")
	local tag=Tools.fuse(folder,Vector3.new(0,0,-4),Vector3.new(0,0,-1),Vector3.new(0,0,1))
	assert(tag.Parent==folder and named(tag,"TagFuse")==1,"no fuse")
	local floor=Tools.fuse(folder,Vector3.new(0,0,0),Vector3.new(0,-1,0),Vector3.yAxis)
	assert(floor.Parent==folder,"planted in the floor")
	local bomb=Tools.buildSmokeBomb()
	assert(bomb.PrimaryPart and named(bomb,"FuseSpark")==1)
	local cloud=Tools.smoke(folder,Vector3.zero)
	assert(cloud.Parent==folder and named(cloud,"SmokeHold")==1)
	local BUILD={}
	local fx={folder=Instance.new("Folder"),layers={},projectiles={}}
	local layer=Tools.install(fx,{BUILD=BUILD})
	assert(BUILD.smoke and BUILD.smoke().PrimaryPart,"the smoke bomb projectile")
	local k2,r2=kunai()
	fx.projectiles.a={data={tag=true},model=k2,root=r2}
	layer.frame(fx)
	assert(fx.projectiles.a.tagDecor,"the tagged kunai")
	assert(layer.impact(fx,{style="look",kind="tag",position=Vector3.new(0,1,-5),radius=6})==true,"the blast")
	assert(named(fx.folder,"TagScrap")>0)
	assert(layer.impact(fx,{style="zone",kind="mist",smoke=true,position=Vector3.zero,radius=7,time=1.5})==true,"the smoke")
	assert(named(fx.folder,"SmokeCloud")==1)
	assert(layer.impact(fx,{style="zone",kind="mist",position=Vector3.zero})==nil,"another mist taken")
	assert(layer.impact(fx,{style="look",kind="crows",position=Vector3.zero})==nil,"another look taken")
	-- the planted tag: a Families charge whose look is "tag"; the other looks stay FamilyFX's
	local FX2={layers={},hazardBuild=function() return {family=true,other=true} end,hazardFinish=function(e) e.finished=true end}
	FX2.buildKunai=function() local km=kunai();return km end
	local t2=Tools.install(FX2,{})
	assert(t2)
	local fx2=setmetatable({folder=Instance.new("Folder")},{__index=FX2})
	local entry=FX2.hazardBuild(fx2,{look="tag",position=Vector3.new(0,0,0)})
	assert(entry and entry.ninjaTag and entry.family and named(fx2.folder,"ExplosiveTag")==1,"the planted tag")
	FX2.hazardFinish(entry)
	local other=FX2.hazardBuild(fx2,{look="ink",position=Vector3.zero})
	assert(other.other,"another look drawn by the tag")
	FX2.hazardFinish(other)
	assert(other.finished,"another look not finished by FamilyFX")
end)

local Transform=H.load("Client/TransformFX")
test("the three transformations: the wall burns, the thrown Rasengan, the Lotus into the Entry",function()
	local folder=Instance.new("Folder")
	local scar=Transform.scorch(folder,Vector3.new(0,2,0),Vector3.new(1,0,0),Vector3.new(0,1,0))
	assert(scar.Parent==folder and named(folder,"WallChidoriBurn")==2,"the burn on the wall")
	local m,decor=Transform.buildRasengan()
	assert(m.PrimaryPart and named(m,"WindBand")==2 and named(m,"RasenganWake")==1)
	for _=1,5 do decor.step(1/60) end
	local BUILD={}
	local fx={folder=Instance.new("Folder"),layers={},projectiles={}}
	local layer=Transform.install(fx,{BUILD=BUILD})
	local r=BUILD.rasengan()
	assert(r:GetAttribute("TransformRasengan"),"BUILD.rasengan")
	fx.projectiles[1]={data={kind="rasengan"},model=r,root=r.PrimaryPart}
	layer.frame(fx)
	-- the fighters' states that are not theirs draw nothing (and nothing breaks without a wall)
	local b=body()
	layer.fighter(fx,b,{fighterId="Lion",castId="FireBloom",state="TechniqueChannel"})
	layer.fighter(fx,b,{fighterId="Leaf",attackVariant="PrimaryLotus",attackName="Slam",state="Active"})
	assert(named(fx.folder,"LotusEntryRing")==0)
end)

print(("NinjaDuel infusions and tools: %d PASS"):format(passed))
