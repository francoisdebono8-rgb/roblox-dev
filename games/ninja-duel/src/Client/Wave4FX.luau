-- DEC-026 newcomers (Madara, Hashirama, Hiruzen as children): the weapons
-- their bodies fight with, installed by Effects. Presentation only; the
-- server's strike is the contact.
--   Madara: the short sword leaves the scabbard for his right hand while he
--     strikes or guards (a trail on the live edge); the hilt at the hip hides.
--   Hashirama: a sheath of wood grows over the forearms while a strike is
--     live, and the small grips his routes name (a stump under the launcher,
--     a low root for the brake, the awakening's root at the contact point).
--   Hiruzen: the dark staff, always in his hands.
--   Both Katon breaths: a short cone of fire ahead of the caster.
local Debris=game:GetService("Debris")
local M={}
function M.install(FX,kit)
	local new,block,tween,flash,shockRing,num,TEX,smokePuff=kit.new,kit.block,kit.tween,kit.flash,kit.shockRing,kit.num,kit.TEX,kit.smokePuff
	local held=setmetatable({},{__mode="k"})
	local function weld(hand,parts)
		for _,p in parts do p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;new("WeldConstraint",{Part0=hand,Part1=p},p) end
	end
	local function live(actor) return actor.attackName~=nil and (actor.state=="Startup" or actor.state=="Active" or actor.state=="Recovery") end
	local function show(parts,on) for _,p in parts do p.LocalTransparencyModifier=if on then 0 else 1 end end
	local function trail(blade,from,to,color)
		local a0=new("Attachment",{Position=from},blade)
		local a1=new("Attachment",{Position=to},blade)
		return new("Trail",{Attachment0=a0,Attachment1=a1,Lifetime=.12,Color=ColorSequence.new(color),LightEmission=.5,
			Transparency=num({{0,.35},{1,1}}),FaceCamera=false,Enabled=false},blade)
	end

	local function sword(model,actor)
		local st=held[model]
		if not st then
			local hand=model:FindFirstChild("RightHand")
			if not hand then return end
			local m=new("Model",{Name="HeldSword"},model)
			local cf=hand.CFrame
			local blade=block(m,Vector3.new(.1,.28,2.5),cf*CFrame.new(0,-.2,-1.75),Color3.fromRGB(200,206,214),Enum.Material.Metal)
			local guard=block(m,Vector3.new(.5,.12,.12),cf*CFrame.new(0,-.2,-.45),Color3.fromRGB(50,44,40),Enum.Material.Metal)
			local grip=block(m,Vector3.new(.16,.16,.7),cf*CFrame.new(0,-.2,0),Color3.fromRGB(60,40,30),Enum.Material.SmoothPlastic)
			weld(hand,{blade,guard,grip})
			st={parts={blade,guard,grip},trail=trail(blade,Vector3.new(0,0,-1.2),Vector3.new(0,0,1.2),Color3.fromRGB(230,236,244)),shown=nil};held[model]=st
		end
		local drawn=live(actor) or actor.state=="Guarding" or actor.state=="TechniqueChannel"
		st.trail.Enabled=actor.state=="Active" and actor.attackName~=nil
		if st.shown==drawn then return end
		st.shown=drawn
		show(st.parts,drawn)
		local hilt=model:FindFirstChild("Hilt")
		if hilt and hilt:IsA("BasePart") then hilt.LocalTransparencyModifier=if drawn then 1 else 0 end
	end

	local function staff(model,actor)
		local st=held[model]
		if not st then
			local hand=model:FindFirstChild("RightHand")
			if not hand then return end
			local m=new("Model",{Name="HeldStaff"},model)
			local cf=hand.CFrame
			local pole=block(m,Vector3.new(.22,.22,5.4),cf*CFrame.new(0,-.2,-.7),Color3.fromRGB(70,50,36),Enum.Material.Wood)
			local cap1=block(m,Vector3.new(.26,.26,.2),cf*CFrame.new(0,-.2,-3.35),Color3.fromRGB(40,32,26),Enum.Material.SmoothPlastic)
			local cap2=block(m,Vector3.new(.26,.26,.2),cf*CFrame.new(0,-.2,1.95),Color3.fromRGB(40,32,26),Enum.Material.SmoothPlastic)
			weld(hand,{pole,cap1,cap2})
			st={trail=trail(pole,Vector3.new(0,0,-2.6),Vector3.new(0,0,-1.2),Color3.fromRGB(236,220,190))};held[model]=st
		end
		st.trail.Enabled=actor.state=="Active" and actor.attackName~=nil
	end

	local WOOD=Color3.fromRGB(132,96,60)
	local LEAF=Color3.fromRGB(110,160,80)
	local function grip(fx,at,height,width,time)
		local floor=kit.floorUnder(fx,at,3,14)
		local base=if floor then floor.Position else at-Vector3.new(0,2.8,0)
		local stump=block(fx.folder,Vector3.new(width,.2,width),CFrame.new(base),WOOD,Enum.Material.Wood)
		stump.Shape=Enum.PartType.Cylinder;stump.CFrame=CFrame.new(base)*CFrame.Angles(0,0,math.rad(90))
		tween(stump,.12,{Size=Vector3.new(height,width,width),CFrame=CFrame.new(base+Vector3.new(0,height/2,0))*CFrame.Angles(0,0,math.rad(90))})
		local bud=block(fx.folder,Vector3.new(.4,.4,.4),CFrame.new(base+Vector3.new(width*.4,height*.8,0)),LEAF,Enum.Material.Grass)
		task.delay(time,function()
			if stump.Parent then tween(stump,.25,{Size=Vector3.new(.2,width,width),CFrame=CFrame.new(base)*CFrame.Angles(0,0,math.rad(90)),Transparency=1}) end
			if bud.Parent then tween(bud,.2,{Transparency=1}) end
		end)
		Debris:AddItem(stump,time+.4);Debris:AddItem(bud,time+.4)
		smokePuff(fx.folder,base+Vector3.new(0,.4,0),Color3.fromRGB(150,120,90),6,1.2)
	end
	local GRIPS={StumpRise={reach=3.2,height=2.6,width=1.6,time=.7},RootRise={reach=3.4,height=3.2,width=1.2,time=.8},RootBrake={reach=2.4,height=1,width=.9,time=1.1}}
	local function wood(fx,model,actor)
		local st=held[model]
		if not st then
			local sheaths={}
			for _,side in {"Left","Right"} do
				local arm=model:FindFirstChild(side.."LowerArm")
				if arm then
					local s=block(model,Vector3.new(.74,1.0,.74),arm.CFrame*CFrame.new(0,-.05,0),WOOD,Enum.Material.Wood)
					weld(arm,{s});table.insert(sheaths,s)
				end
			end
			if #sheaths==0 then return end
			st={parts=sheaths,shown=nil,serial=nil};held[model]=st
		end
		local on=actor.state=="Active" and actor.attackName~=nil
		if st.shown~=on then st.shown=on;show(st.parts,on) end
		-- The grip a route grows, once per strike, as its contact opens.
		local key=actor.state=="Active" and actor.attackName and GRIPS[actor.attackName] and (actor.attackName..tostring(actor.attackSerial or actor.attackAt or ""))
		if key and key~=st.serial then
			st.serial=key
			local root=model:FindFirstChild("HumanoidRootPart")
			local g=GRIPS[actor.attackName]
			if root then grip(fx,root.Position+root.CFrame.LookVector*g.reach,g.height,g.width,g.time) end
		elseif not key and actor.state~="Active" then st.serial=nil end
	end

	local function breath(fx,position,direction,reach)
		local look=if direction and direction.Magnitude>.1 then direction.Unit else Vector3.zAxis
		local from=position+Vector3.new(0,1.2,0)+look*1.2
		local holder=kit.anchorPart(fx.folder,from)
		holder.CFrame=CFrame.lookAt(from,from+look)
		local e=new("ParticleEmitter",{Texture=TEX.glow,Rate=260,Lifetime=NumberRange.new(.22,.32),Speed=NumberRange.new(reach*2.6,reach*3.2),
			SpreadAngle=Vector2.new(22,22),EmissionDirection=Enum.NormalId.Front,LightEmission=1,
			Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,240,180)),ColorSequenceKeypoint.new(.4,Color3.fromRGB(255,150,50)),ColorSequenceKeypoint.new(1,Color3.fromRGB(150,40,20))}),
			Size=num({{0,.8},{.6,3.2},{1,4}}),Transparency=num({{0,.1},{.7,.4},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-90,90)},holder)
		local light=new("PointLight",{Color=Color3.fromRGB(255,150,60),Brightness=3,Range=reach*1.6},holder)
		task.delay(.3,function() if e.Parent then e.Enabled=false end;if light.Parent then tween(light,.25,{Brightness=0}) end end)
		Debris:AddItem(holder,1)
		flash(fx.folder,from,Color3.fromRGB(255,170,70),1,5,.2,.3)
	end

	table.insert(FX.layers,1,{name="Wave4",fighter=function(fx,model,actor,dt)
		if not model then return end
		if actor.fighterId=="Rival" then sword(model,actor)
		elseif actor.fighterId=="Professor" then staff(model,actor)
		elseif actor.fighterId=="Sapling" then wood(fx,model,actor) end
	end,impact=function(fx,impact,folder)
		if impact.style=="look" and impact.kind=="firebreath" and impact.radius then
			breath(fx,impact.position,impact.direction,impact.radius)
			return true
		end
		return false
	end})
end
return M
