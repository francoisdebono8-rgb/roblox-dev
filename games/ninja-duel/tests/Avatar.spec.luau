-- The player's own Roblox avatar as his fighter's body (DEC-036, user 12/11:
-- « c'est avec mon perso Roblox personnel qu'il faut tester » ; everything he
-- bought stays: clothes, layered clothing, accessories, hair, heads, body
-- bundles). Checked here, headless: the game's skeleton as data (World.RIG)
-- is exactly what World.rig builds; an R15 avatar is put on that skeleton
-- (every joint pivot where the rig's is, each part keeping its own offset,
-- the motors under their Part0 where the motion engine looks); a model
-- without a joint is refused. Roblox builds the avatar itself
-- (Players:CreateHumanoidModelFromDescription): that, the look and the
-- animations on it are the Studio trial.
local H=require("./Harness")
local V,CF=H.V,H.roblox.CFrame
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local function near(a,b) return (a-b).Magnitude<1e-4 end

test("World.RIG is exactly the skeleton World.rig builds",function()
	local made={}
	local baseNew=H.envBase.Instance.new
	local savedNew,savedGet=H.envBase.Instance,H.envBase.game.GetService
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		if type(x)=="table" then
			x.SetNetworkOwner=function() end
			if not x.GetDescendants then x.GetDescendants=function() return {} end end
			table.insert(made,x)
		end
		return x
	end}
	H.envBase.game.GetService=function(g,name)
		local ok,s=pcall(savedGet,g,name);if ok then return s end
		return setmetatable({},{__index=function() return function() return false end end})
	end
	local ok,err=pcall(function()
		local World=H.load("Server/World")
		local Fighters=H.load("Shared/Fighters")
		local folder=baseNew("Folder")
		World.rig(folder,Fighters.Lion,CF.new(),"X")
		local parts,motors={},{}
		for _,x in made do
			if x.ClassName=="Motor6D" then motors[x.Name]=x
			elseif x.ClassName=="Part" and x.Size then parts[x.Name]=parts[x.Name] or x end
		end
		for name,spec in World.RIG.parts do
			local p=parts[name]
			assert(p,"the rig has no "..name)
			assert(near(p.Size,spec[1]),name.." size "..tostring(p.Size).." ~= RIG "..tostring(spec[1]))
			assert(near(p.CFrame.Position,spec[2]),name.." centre "..tostring(p.CFrame.Position).." ~= RIG "..tostring(spec[2]))
		end
		assert(#World.RIG.joints==15,"RIG has "..#World.RIG.joints.." joints")
		for _,j in World.RIG.joints do
			local m=motors[j[1]]
			assert(m,"the rig has no joint "..j[1])
			assert(m.Part0.Name==j[2] and m.Part1.Name==j[3],j[1].." links "..m.Part0.Name.."-"..m.Part1.Name)
			assert(near(m.C0.Position,j[4]) and near(m.C1.Position,j[5]),j[1].." pivots differ from RIG")
		end
	end)
	H.envBase.Instance=savedNew;H.envBase.game.GetService=savedGet
	assert(ok,err)
end)

-- A standard Roblox R15 avatar, as Roblox builds it: its own part sizes, the
-- motors inside their Part1, its own pivots (an Rthro-like taller build).
local function fakeAvatar(scale,drop)
	local objects={}
	local Obj={}
	Obj.__index=Obj
	local function new(class,name,parent)
		local o=setmetatable({ClassName=class,Name=name,Parent=parent},Obj)
		table.insert(objects,o)
		return o
	end
	function Obj:IsA(c) return c==self.ClassName or (c=="BasePart" and self.ClassName=="MeshPart") end
	function Obj:GetDescendants()
		local out={}
		local function walk(node) for _,o in objects do if o.Parent==node then table.insert(out,o);walk(o) end end end
		walk(self)
		return out
	end
	function Obj:FindFirstChild(n) for _,o in objects do if o.Parent==self and o.Name==n then return o end end return nil end
	local model=new("Model","Avatar",nil)
	local s=scale or 1
	local sizes={HumanoidRootPart=V.new(2,2,1),LowerTorso=V.new(2,.4,1)*s,UpperTorso=V.new(2,1.6,1)*s,Head=V.new(1.2,1.2,1.2)*s,
		LeftUpperArm=V.new(1,1.17,1)*s,RightUpperArm=V.new(1,1.17,1)*s,LeftLowerArm=V.new(1,1.05,1)*s,RightLowerArm=V.new(1,1.05,1)*s,
		LeftHand=V.new(1,.3,1)*s,RightHand=V.new(1,.3,1)*s,LeftUpperLeg=V.new(1,1.22,1)*s,RightUpperLeg=V.new(1,1.22,1)*s,
		LeftLowerLeg=V.new(1,1.19,1)*s,RightLowerLeg=V.new(1,1.19,1)*s,LeftFoot=V.new(1,.3,1)*s,RightFoot=V.new(1,.3,1)*s}
	local parts={}
	for name,size in sizes do local p=new(if name=="HumanoidRootPart" then "Part" else "MeshPart",name,model);p.Size=size;parts[name]=p end
	local function motor(name,p0,p1,c0,c1)
		if name==drop then return end
		local m=new("Motor6D",name,parts[p1]);m.Part0=parts[p0];m.Part1=parts[p1];m.C0=c0;m.C1=c1
	end
	motor("Root","HumanoidRootPart","LowerTorso",CF.new(0,-.75*s,0),CF.new(0,-.2*s,0))
	motor("Waist","LowerTorso","UpperTorso",CF.new(0,.2*s,0),CF.new(0,-.8*s,0))
	motor("Neck","UpperTorso","Head",CF.new(0,.8*s,0),CF.new(0,-.5*s,0))
	for _,side in {-1,1} do
		local pre=if side==-1 then "Left" else "Right"
		motor(pre.."Shoulder","UpperTorso",pre.."UpperArm",CF.new(side*1,.56*s,0),CF.new(-side*.5,.4*s,0))
		motor(pre.."Elbow",pre.."UpperArm",pre.."LowerArm",CF.new(0,-.33*s,0),CF.new(0,.26*s,0))
		motor(pre.."Wrist",pre.."LowerArm",pre.."Hand",CF.new(0,-.5*s,0),CF.new(0,.12*s,0))
		motor(pre.."Hip","LowerTorso",pre.."UpperLeg",CF.new(side*.5,-.2*s,0),CF.new(0,.42*s,0))
		motor(pre.."Knee",pre.."UpperLeg",pre.."LowerLeg",CF.new(0,-.41*s,0),CF.new(0,.4*s,0))
		motor(pre.."Ankle",pre.."LowerLeg",pre.."Foot",CF.new(0,-.55*s,0),CF.new(0,.1*s,0))
	end
	return model,parts
end

test("an avatar is put on the game's skeleton: every pivot where the rig's is, motors under their Part0",function()
	local World=H.load("Server/World")
	local AvatarBody=H.load("Server/AvatarBody")
	for _,scale in {1,1.25} do
		local model,parts=fakeAvatar(scale)
		local joints,rest=AvatarBody.fit(model,World.RIG)
		assert(joints,"fit refused a complete avatar: "..tostring(rest))
		for _,j in World.RIG.joints do
			local m=joints[j[1]]
			assert(m and m.Parent==parts[j[2]],j[1].." is not under its Part0 "..j[2])
			-- The rest pose closes: Part0 * C0 = Part1 * C1, at the rig's pivot.
			local pivot0=rest[j[2]]*m.C0
			local pivot1=rest[j[3]]*m.C1
			assert(near(pivot0.Position,pivot1.Position),j[1].." does not close at rest")
			local rigParent=if j[2]=="HumanoidRootPart" then V.zero else World.RIG.parts[j[2]][2]
			assert(near(pivot0.Position,rigParent+j[4]),j[1].." pivot "..tostring(pivot0.Position).." is not the rig's")
		end
		-- Each part keeps its own offset from its pivot (its own look).
		assert(near(rest.Head.Position,World.RIG.parts.UpperTorso[2]+V.new(0,.9,0)+V.new(0,.5*scale,0)),"the head moved off its own neck offset")
	end
end)

test("a model without one of the joints is refused (the prodigy's body is built instead)",function()
	local World=H.load("Server/World")
	local AvatarBody=H.load("Server/AvatarBody")
	local model=fakeAvatar(1,"LeftKnee")
	local joints,missing=AvatarBody.fit(model,World.RIG)
	assert(joints==nil and missing=="LeftKnee","fit took an avatar without its left knee ("..tostring(missing)..")")
end)

test("everything bought stays: only the size sliders are reset",function()
	local AvatarBody=H.load("Server/AvatarBody")
	local keys={}
	for k in AvatarBody.SCALES do table.insert(keys,k) end
	table.sort(keys)
	assert(table.concat(keys,",")=="BodyTypeScale,DepthScale,HeadScale,HeightScale,ProportionScale,WidthScale","the avatar loses more than its size sliders: "..table.concat(keys,","))
	local fs=require("@lune/fs")
	local src=fs.readFile("src/Server/AvatarBody.luau")
	for _,removed in {"Accessory","Shirt","Pants","Clothing","WrapLayer","BodyColors"} do
		assert(not string.find(src,'IsA("'..removed..'")',1,true),"AvatarBody removes "..removed)
	end
end)

print(string.format("NinjaDuel avatar body (DEC-036): %d PASS",passed))
