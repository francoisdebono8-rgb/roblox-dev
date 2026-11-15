-- The face-cam of the duel's HUD (HUD v3; François 15/11: « une image animée
-- du visage »): which parts are filmed, where a face plate is seen through the
-- lens, whether it faces it, its roll, and the drawing mirrored from the real
-- one. Headless (Lune's Roblox instances); the picture is a Studio check.
local H=require("./Harness")
local roblox=require("@lune/roblox")
local Instance=roblox.Instance
local Vector3=roblox.Vector3
local Vector2=roblox.Vector2
-- (Lune's own lookAt faces away: the harness's CFrame has the right one)
local CFrame=H.C
H.envBase.Instance=Instance
H.envBase.UDim2=roblox.UDim2;H.envBase.UDim=roblox.UDim
local FaceCam=H.load("Client/FaceCam")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local function part(name,at,parent)
	local p=Instance.new("Part");p.Name=name;p.CFrame=CFrame.new(at);p.Size=Vector3.new(1,1,1);p.Parent=parent
	return p
end
local function weld(a,b,class)
	local w=Instance.new(class or "WeldConstraint");w.Part0=a;w.Part1=b;w.Parent=a
	return w
end

test("the parts filmed: the head, its hair and what holds to it, the torso; not the arms, the root or the face's plates",function()
	local model=Instance.new("Model")
	local head=part("Head",Vector3.new(0,4.5,0),model)
	local torso=part("UpperTorso",Vector3.new(0,3,0),model)
	local root=part("HumanoidRootPart",Vector3.new(0,2.6,0),model)
	local arm=part("LeftUpperArm",Vector3.new(-1.5,3,0),model)
	local hair=part("Hair",Vector3.new(0,5.1,0),model)
	local band=part("HairBand",Vector3.new(0,5.3,.4),model)
	local eye=part("FaceEye",Vector3.new(.3,4.5,-.6),model)
	local sword=part("Sword",Vector3.new(0,9,0),model)
	weld(torso,head,"Motor6D");weld(root,torso,"Motor6D");weld(torso,arm,"Motor6D")
	weld(head,hair);weld(hair,band);weld(head,eye);weld(hair,sword)
	local list=FaceCam.collect(model)
	local got={}
	for _,p in list do got[p.Name]=true end
	assert(got.Head and got.Hair and got.HairBand and got.UpperTorso,"missing a part of the head")
	assert(not got.LeftUpperArm and not got.HumanoidRootPart and not got.FaceEye and not got.Sword,"filmed what is not the head")
	assert(#FaceCam.collect(Instance.new("Model"))==0,"a model without a head")
end)

test("the lens: in front of the chest, looking at the face; a plate seen where it is, its size, facing, upright",function()
	local head=Instance.new("Part");head.CFrame=CFrame.new(0,4.5,0)
	local torso=Instance.new("Part");torso.CFrame=CFrame.lookAt(Vector3.new(0,3,0),Vector3.new(0,3,-1))
	local lens=FaceCam.lens(head,torso)
	assert(lens.Position.Z<-3.5 and math.abs(lens.Position.X)<1e-3,"the lens is not in front of him: "..tostring(lens.Position))
	local size=Vector2.new(88,88)
	local x,y,perStud,front=FaceCam.project(lens,FaceCam.FOV,size,head.CFrame.Position)
	assert(front and math.abs(x-44)<1 and math.abs(y-44)<8,"the head is not in the middle: "..x..","..y)
	local xr=FaceCam.project(lens,FaceCam.FOV,size,head.CFrame.Position+Vector3.new(-.3,0,0))
	-- his left (-x when he faces -z) is on the picture's right
	assert(xr>x,"left and right swapped")
	assert(perStud>30 and perStud<46,"a stud is "..perStud.." px")
	local _,_,_,behind=FaceCam.project(lens,FaceCam.FOV,size,lens.Position+lens.LookVector*-2)
	assert(not behind,"a point behind the lens is drawn")
	-- an eye plate on his face, facing out (-z): seen, upright
	local plate=Instance.new("Part");plate.Size=Vector3.new(.4,.3,.02)
	plate.CFrame=CFrame.lookAt(Vector3.new(.3,4.5,-.9),Vector3.new(.3,4.5,-2))
	assert(FaceCam.facing(plate,lens),"an eye facing the lens is hidden")
	assert(math.abs(FaceCam.roll(plate,lens))<2,"an upright face is rolled: "..FaceCam.roll(plate,lens))
	-- the head turned away: hidden
	plate.CFrame=CFrame.lookAt(Vector3.new(.3,4.5,.9),Vector3.new(.3,4.5,2))
	assert(not FaceCam.facing(plate,lens),"the back of the head shows its eyes")
	-- the head tilted 20 degrees: the drawing turns with it
	plate.CFrame=CFrame.lookAt(Vector3.new(.3,4.5,-.9),Vector3.new(.3,4.5,-2))*CFrame.Angles(0,0,math.rad(20))
	assert(math.abs(math.abs(FaceCam.roll(plate,lens))-20)<2,"the tilt is lost: "..FaceCam.roll(plate,lens))
end)

test("the drawing is mirrored from the real face, and copied again when its shape changes",function()
	local source=Instance.new("Folder")
	local white=Instance.new("Frame");white.Name="White";white.Parent=source
	local iris=Instance.new("Frame");iris.Name="Iris";iris.Parent=white
	local copy=Instance.new("Folder")
	for _,c in source:GetChildren() do c:Clone().Parent=copy end
	white.Size=roblox.UDim2.fromScale(.4,.1);iris.Visible=false
	assert(FaceCam.mirror(source,copy),"same shape refused")
	local w2=copy:FindFirstChild("White")
	assert(w2.Size==white.Size and w2:FindFirstChild("Iris").Visible==false,"the lid did not close on the copy")
	local tomoe=Instance.new("Frame");tomoe.Parent=iris
	assert(not FaceCam.mirror(source,copy),"a new drawing (the Sharingan) is not noticed")
end)

print(string.format("NinjaDuel face-cam (HUD v3): %d PASS",passed))
