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

test("in the duel: the snapshot's fields drive it (p.nature, impact.nature, actor.infused)",function()
	local fx={folder=Instance.new("Folder"),layers={},projectiles={}}
	local layer=Infusion.install(fx,nil)
	assert(fx.layers[1]==layer,"first in line")
	local m,root=kunai()
	fx.projectiles[1]={data={nature="Wind",strong=true},model=m,root=root}
	fx.projectiles[2]={data={},model=kunai()}
	layer.frame(fx);layer.frame(fx)
	assert(fx.projectiles[1].infusion2 and fx.projectiles[1].infusion2.nature=="Wind","the kunai was not dressed")
	assert(fx.projectiles[2].infusion2==nil,"a plain kunai was dressed")
	assert(layer.impact(fx,{nature="Earth",position=Vector3.new(1,2,3)})==nil,"the blow's own contact must still play")
	assert(named(fx.folder,"Infusion.Earth")>0)
	local b=body()
	layer.fighter(fx,b,{fighterId="Leaf",infused="Fire"})
	assert(b:GetAttribute("Infusion")=="Fire" and named(b.RightFoot,"Infusion.Fire")>0,"Lee's kick")
	layer.fighter(fx,b,{fighterId="Leaf",infused="Fire"})
	local count=named(b,"Infusion.Fire")
	layer.fighter(fx,b,{fighterId="Leaf",infused="Fire"})
	assert(named(b,"Infusion.Fire")==count,"rebuilt every frame")
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
	assert(layer.impact(fx,{style="stick",tag=true,position=Vector3.new(0,1,-5),direction=Vector3.new(0,0,-1),normal=Vector3.zAxis})==nil)
	assert(named(fx.folder,"ExplosiveTag")==1,"no fuse on the planted kunai")
	assert(layer.impact(fx,{style="tagBlast",position=Vector3.new(0,1,-5)})==true)
	assert(layer.impact(fx,{style="smoke",position=Vector3.zero})==true)
	assert(named(fx.folder,"SmokeCloud")==1)
end)

print(("NinjaDuel infusions and tools: %d PASS"):format(passed))
