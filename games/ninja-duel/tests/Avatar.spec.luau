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
-- (`constraints`: the joints as Roblox now builds them, AnimationConstraints
-- between two attachments, no Motor6D.)
local function fakeAvatar(scale,drop,constraints)
	local objects={}
	local Obj={}
	Obj.__index=Obj
	local function new(class,name,parent)
		local o=setmetatable({ClassName=class,Name=name,Parent=parent},Obj)
		table.insert(objects,o)
		return o
	end
	function Obj:IsA(c) return c==self.ClassName or (c=="BasePart" and (self.ClassName=="MeshPart" or self.ClassName=="Part")) end
	function Obj:GetDescendants()
		local out={}
		local function walk(node) for _,o in objects do if o.Parent==node then table.insert(out,o);walk(o) end end end
		walk(self)
		return out
	end
	function Obj:FindFirstChild(n) for _,o in objects do if o.Parent==self and o.Name==n then return o end end return nil end
	function Obj:Destroy() self.Parent=nil end
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
		if constraints then
			local a0=new("Attachment",name.."RigAttachment",parts[p0]);a0.CFrame=c0
			local a1=new("Attachment",name.."RigAttachment",parts[p1]);a1.CFrame=c1
			local c=new("AnimationConstraint",name,parts[p1]);c.Attachment0=a0;c.Attachment1=a1
			return
		end
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
	return model,parts,function(class) return new(class,class,nil) end
end

test("an avatar is put on the game's skeleton: every pivot where the rig's is, motors under their Part0",function()
	local World=H.load("Server/World")
	local AvatarBody=H.load("Server/AvatarBody")
	for _,scale in {1,1.25} do
		local model,parts=fakeAvatar(scale)
		local joints,rest=AvatarBody.fit(model,World.RIG)
		assert(joints,"fit refused a complete avatar: "..tostring(rest))
		-- (19/11) The rig's pivots are where its motors put them, parent to
		-- child (Part0 * C0 = Part1 * C1), as on every prodigy in a duel.
		local chain={HumanoidRootPart=V.zero}
		for _,j in World.RIG.joints do chain[j[3]]=chain[j[2]]+j[4]-j[5] end
		for _,j in World.RIG.joints do
			local m=joints[j[1]]
			assert(m and m.Parent==parts[j[2]],j[1].." is not under its Part0 "..j[2])
			-- The rest pose closes: Part0 * C0 = Part1 * C1, at the rig's pivot.
			local pivot0=rest[j[2]]*m.C0
			local pivot1=rest[j[3]]*m.C1
			assert(near(pivot0.Position,pivot1.Position),j[1].." does not close at rest")
			assert(near(pivot0.Position,chain[j[2]]+j[4]),j[1].." pivot "..tostring(pivot0.Position).." is not the rig's")
		end
		-- (19/11) The body is the rig's: every part but the head takes the rig's
		-- size and sits where the rig's does on its pivot (no air at the elbow,
		-- no torso swallowing the head, the soles on the rig's floor).
		for _,j in World.RIG.joints do
			if j[3]~="Head" then
				local size=World.RIG.parts[j[3]][1]
				assert(near(parts[j[3]].Size,size),j[3].." keeps its own size "..tostring(parts[j[3]].Size).." on the rig's "..tostring(size))
				assert(near(rest[j[3]].Position,chain[j[3]]),j[3].." is not where the rig's is")
			end
		end
		-- The head keeps its size (its hair is fitted to it) and sits on the
		-- torso as the rig's: its bottom where the rig's head bottom is.
		local rigHead,rigC1=World.RIG.parts.Head[1],World.RIG.joints[3][5]
		local neck=chain.UpperTorso+V.new(0,.9,0)
		assert(near(parts.Head.Size,V.new(1.2,1.2,1.2)*scale),"the head was resized")
		local sole=rest.RightFoot.Position.Y-parts.RightFoot.Size.Y/2
		assert(math.abs(sole+3.01)<1e-3,"the soles are not on the prodigies' floor (3.01 under the root): "..sole)
		local bottom=rest.Head.Position.Y-parts.Head.Size.Y/2
		assert(math.abs(bottom-(neck.Y-(rigHead.Y/2+rigC1.Y)))<1e-4,"the head does not sit on the torso: its bottom at "..bottom)
	end
end)

-- (19/11, measured in Studio: the avatar 5.10 studs tall in Konoha, 5.96 in a
-- duel, the prodigies 6.51) Every avatar grows to the prodigies' height before
-- anything is worn: measured from its joints at rest, soles to crown.
test("an avatar grows to the prodigies' height, measured from its joints at rest",function()
	local AvatarBody=H.load("Server/AvatarBody")
	local small=AvatarBody.restHeight((fakeAvatar(1)))
	local big=AvatarBody.restHeight((fakeAvatar(1.25)))
	assert(small and big,"the rest height was not measured")
	assert(math.abs(big/small-1.25)<.02,"the measure does not follow the body's size: "..small.." and "..big)
	local k=AvatarBody.growth((fakeAvatar(1)))
	assert(math.abs(small*k-AvatarBody.HEIGHT)<1e-3,"the avatar does not reach "..AvatarBody.HEIGHT..": "..small.." x "..k)
	local withConstraints=AvatarBody.restHeight((fakeAvatar(1,nil,true)))
	assert(withConstraints and math.abs(withConstraints-small)<1e-4,"Roblox's new joints (AnimationConstraints) are not measured like motors")
	assert(AvatarBody.growth((fakeAvatar(1,"LeftKnee")))>0,"an incomplete body broke the measure")
	-- The village and the duel grow the same body the same way.
	local fs=require("@lune/fs")
	assert(string.find(fs.readFile("src/Server/Hub.luau"),"AvatarBody).grow(character)",1,true),"the village does not grow the walker")
	assert(string.find(fs.readFile("src/Server/AvatarBody.luau"),"entry.growth=AvatarBody.grow(model)",1,true),"the duel's avatar does not grow")
end)

-- (14/11, Studio: « [AvatarBody] no joint Root ») Roblox builds the avatar's
-- joints as AnimationConstraints now: without motorize, no avatar was ever
-- fitted and the player fought in his prodigy's body.
test("an avatar built with Roblox's new joints (AnimationConstraints) is fitted like one with motors",function()
	local World=H.load("Server/World")
	local AvatarBody=H.load("Server/AvatarBody")
	local model,parts,make=fakeAvatar(1,nil,true)
	local before=AvatarBody.fit(model,World.RIG)
	assert(before==nil,"fixture: an avatar without motors was fitted")
	local model2,parts2,make2=fakeAvatar(1,nil,true)
	local n=AvatarBody.motorize(model2,make2)
	assert(n==15,"motorize turned "..n.." constraints into motors, not 15")
	for _,d in model2:GetDescendants() do assert(d.ClassName~="AnimationConstraint","a constraint was left: "..d.Name) end
	local joints,rest=AvatarBody.fit(model2,World.RIG)
	assert(joints,"the motorized avatar was refused: "..tostring(rest))
	-- the same rest pose as an avatar built with motors
	local ref,refParts=fakeAvatar(1)
	local _,refRest=AvatarBody.fit(ref,World.RIG)
	for name,cf in refRest do assert(rest[name] and near(rest[name].Position,cf.Position),name.." rests elsewhere than with motors") end
	for _,j in World.RIG.joints do
		local m=joints[j[1]]
		assert(m.Part0==parts2[j[2]] and m.Part1==parts2[j[3]],j[1].." links the wrong parts")
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


-- (19/11, seen in Studio) The plate sat across the eyes of a dynamic head (16 %
-- of the head's box above its centre, and a dynamic head's box runs from the
-- chin to the crown); the band was a square whose corners stood out.
test("the headband sits on the brow, above the eyes, as a ring round the head",function()
	local roblox=require("@lune/roblox")
	H.envBase.Instance=roblox.Instance
	local Headband=H.load("Server/Headband")
	local model=roblox.Instance.new("Model")
	local head=roblox.Instance.new("MeshPart");head.Name="Head";head.Size=V.new(1.2,1.2,1.2);head.Parent=model
	local face=roblox.Instance.new("Attachment");face.Name="FaceFrontAttachment";face.Position=V.new(0,-.01,-.59);face.Parent=head
	local hat=roblox.Instance.new("Attachment");hat.Name="HatAttachment";hat.Position=V.new(0,.61,0);hat.Parent=head
	local band=Headband.wear(model,"HeadbandBlue")
	assert(band,"no headband")
	local plate,strips=nil,{}
	for _,p in band:GetChildren() do
		if p.Name=="Plate" then plate=p elseif p.Name=="Band" then table.insert(strips,p) end
	end
	assert(plate and #strips==8,"the band is not a ring of eight strips with its plate ("..#strips..")")
	local at=head.CFrame:PointToObjectSpace(plate.CFrame.Position)
	assert(at.Y-plate.Size.Y/2>.2,"the plate comes down over the eyes: its bottom at "..(at.Y-plate.Size.Y/2))
	assert(at.Y+plate.Size.Y/2<.61,"the plate is above the crown")
	assert(at.Z<-.6,"the plate is not in front of the face")
	for _,p in strips do
		local c=head.CFrame:PointToObjectSpace(p.CFrame.Position)
		assert(math.abs(c.Y-at.Y)<1e-3,"a strip is off the plate's height")
		assert((c.X/.6)^2+(c.Z/.6)^2>.8,"a strip runs inside the head")
	end
	-- An old blocky head (no attachments): a little above its centre.
	local old=roblox.Instance.new("Model")
	local block=roblox.Instance.new("Part");block.Name="Head";block.Size=V.new(1.2,1.2,1.2);block.Parent=old
	assert(math.abs(Headband.brow(block)-.324)<1e-3,"a blocky head's brow moved")
end)

-- (20/11, DEC-044, the OUTILLEUR's fitting room) One forehead protector per
-- ninja; hair filed as a hat stays; an armour torso is swapped.
test("one protector: a set with its own takes the headband's place; a modelled headband goes with the outfit",function()
	local Headband=H.load("Server/Headband")
	local Outfit=H.load("Server/Outfit")
	for _,id in {"SetLee","SetGaara","SetEmberMonk","SetStormCourier","SetLeafMedic"} do
		assert(Headband.owned(id),id.." has its own protector")
	end
	for _,id in {"SetNaruto","SetSasuke","SetMistHunter","SetNone"} do
		assert(not Headband.owned(id),id.." has no protector of its own")
	end
	assert(Headband.worn({set="SetLee",headband="HeadbandRed"})==nil,"two protectors on Lee")
	assert(Headband.worn({set="SetNaruto",headband="HeadbandRed"})=="HeadbandRed","Naruto lost his headband")
	assert(Headband.worn({headband="HeadbandNone"})==nil,"NO HEADBAND worn")
	-- the modelled headband is an outfit item (the client puts the model on),
	-- not the flat band; a headband without a model stays the flat band
	-- (26/11, François) the black and the red bands have the classic model now; a band with no
	-- model (none left in the Shop) would stay the flat band
	assert(Headband.modelled("HeadbandBlue") and Headband.modelled("HeadbandRed") and Headband.modelled("HeadbandBlack"),"the models")
	local function has(list,id) for _,x in list do if x==id then return true end end return false end
	assert(has(Outfit.items({set="SetNaruto",headband="HeadbandBlue"}),"HeadbandBlue"),"the modelled headband is not dressed")
	assert(not has(Outfit.items({set="SetLee",headband="HeadbandBlue"}),"HeadbandBlue"),"a headband over Lee's own")
	assert(has(Outfit.items({set="SetNaruto",headband="HeadbandRed"}),"HeadbandRed"),"the red headband is not dressed")
end)

test("stripping keeps the hair Roblox files as a hat; the hats go",function()
	local Outfit=H.load("Server/Outfit")
	assert(Outfit.isHair("Black Ponytail") and Outfit.isHair("Pal Hair") and not Outfit.isHair("Bucket Hat"),"the names")
	local desc={HatAccessory="11,22,33",HairAccessory="44",FaceAccessory="55",Shirt=1,Pants=2,GraphicTShirt=3,
		GetAccessories=function() return {} end,SetAccessories=function() end}
	local names={["11"]="Bucket Hat",["22"]="Woman's Brown Hair",["33"]="Long Braid"}
	Outfit.strip(desc,function(id) return names[tostring(id)] end)
	assert(desc.FaceAccessory=="" and desc.Shirt==0,"the clothes stay on")
	-- (21/11) a hair filed as a hat stays a hat: Roblox builds it only from there
	local kept={}
	for _,id in string.split(desc.HatAccessory,",") do kept[id]=true end
	assert(desc.HairAccessory=="44" and kept["22"] and kept["33"] and not kept["11"],"the hair: "..desc.HatAccessory.." / "..desc.HairAccessory)
	local bald={HatAccessory="11",HairAccessory="",Shirt=1,GetAccessories=function() return {} end,SetAccessories=function() end}
	Outfit.strip(bald,function(id) return names[tostring(id)] end)
	assert(bald.HatAccessory=="","a hat that is not hair stayed")
end)

test("an armour torso and arms (Korblox) are swapped for the standard ones; an Rthro body stays",function()
	local AvatarBody=H.load("Server/AvatarBody")
	local function body(size,arm)
		arm=arm or V.new(1,1.2,1)
		return {FindFirstChild=function(_,name)
			if name=="UpperTorso" then return {Size=size,IsA=function() return true end} end
			if name=="RightUpperArm" or name=="LeftUpperArm" then return {Size=arm,IsA=function() return true end} end
		end,Destroy=function() end}
	end
	local arms={Torso=1,LeftArm=21,RightArm=22}
	assert(AvatarBody.plainTorso(arms,function() return body(V.new(2,1.6,1),V.new(1.53,3.28,1.58)) end) and arms.LeftArm==0 and arms.RightArm==0 and arms.Torso==1,"Korblox's arms stay")
	local rthroArms={LeftArm=31,RightArm=32}
	assert(not AvatarBody.plainTorso(rthroArms,function() return body(V.new(2.3,2.1,1.2),V.new(1.1,1.5,1.1)) end) and rthroArms.LeftArm==31,"Rthro's arms swapped")
	assert(AvatarBody.oversized(body(V.new(3.25,6.3,3.02))),"Korblox kept")
	assert(not AvatarBody.oversized(body(V.new(2,1.6,1))) and not AvatarBody.oversized(body(V.new(2.3,2.1,1.2))),"a normal torso swapped")
	local desc={Torso=12345}
	assert(AvatarBody.plainTorso(desc,function() return body(V.new(3.25,6.3,3.02)) end) and desc.Torso==0,"Korblox's torso stays")
	local rthro={Torso=678}
	assert(not AvatarBody.plainTorso(rthro,function() return body(V.new(2.3,2.1,1.2)) end) and rthro.Torso==678,"Rthro's torso swapped")
end)

print(string.format("NinjaDuel avatar body (DEC-036): %d PASS",passed))
