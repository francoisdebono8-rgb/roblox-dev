-- Roster 20, batch 1 (Haku, Zabuza, Kimimaro): the batch's own drawing,
-- installed by Effects. Most of it is FamilyFX's (Shared/Looks); here only
-- what a look alone cannot say: the dome of ice mirrors standing round the
-- opponent, and the Hidden Mist thick enough to lose a body in.
local Debris=game:GetService("Debris")
local M={}
function M.install(FX,kit)
	local new,block,tween,flash,shockRing,num,TEX=kit.new,kit.block,kit.tween,kit.flash,kit.shockRing,kit.num,kit.TEX
	local ICE=Color3.fromRGB(214,240,255)
	local EDGE=Color3.fromRGB(150,206,240)
	local function mirrors(fx,position,radius,time)
		local floor=kit.floorUnder(fx,position,3,14)
		local base=if floor then floor.Position else position-Vector3.new(0,2.8,0)
		local count=10
		for i=1,count do
			local angle=i/count*math.pi*2
			local at=base+Vector3.new(math.cos(angle)*radius,3.6,math.sin(angle)*radius)
			local pane=block(fx.folder,Vector3.new(2.6,5.2,.18),CFrame.lookAt(at,Vector3.new(base.X,at.Y,base.Z)),ICE,Enum.Material.Glass)
			pane.Transparency=1;pane.Reflectance=.35
			local rim=block(pane,Vector3.new(2.8,5.4,.08),pane.CFrame*CFrame.new(0,0,.06),EDGE,Enum.Material.Neon)
			rim.Transparency=1
			tween(pane,.25,{Transparency=.35});tween(rim,.25,{Transparency=.75})
			task.delay(math.max(.3,time-.4),function()
				if pane.Parent then tween(pane,.35,{Transparency=1});tween(rim,.35,{Transparency=1}) end
			end)
			Debris:AddItem(pane,time+.2)
		end
		shockRing(fx.folder,base+Vector3.new(0,.2,0),ICE,2,radius*2,.4)
	end
	local function mist(fx,position,radius,time)
		local floor=kit.floorUnder(fx,position,3,14)
		local at=if floor then floor.Position+Vector3.new(0,1,0) else position
		local holder=kit.anchorPart(fx.folder,at)
		holder.Size=Vector3.new(radius*2,4,radius*2)
		local e=new("ParticleEmitter",{Texture=TEX.smoke,Rate=22,Lifetime=NumberRange.new(2.5,3.5),Speed=NumberRange.new(.4,1.2),SpreadAngle=Vector2.new(60,60),
			EmissionDirection=Enum.NormalId.Top,Shape=Enum.ParticleEmitterShape.Box,Color=ColorSequence.new(Color3.fromRGB(226,232,238)),LightInfluence=1,
			Size=num({{0,10},{1,18}}),Transparency=num({{0,1},{.2,.55},{.8,.6},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-8,8)},holder)
		task.delay(math.max(.3,time-1),function() if e.Parent then e.Enabled=false end end)
		Debris:AddItem(holder,time+3.5)
	end
	-- Zabuza: Kubikiribōchō in his hands from the guard to the recovery
	-- (bible ZABUZA.md §7): a blade welded to the right hand for the whole
	-- duel, the one on his back hidden; the edge trail only in live frames.
	local BACK={Cleaver=true,CleaverHole=true,CleaverGrip=true}
	local held=setmetatable({},{__mode="k"})
	local function cleaver(fx,model,actor)
		if actor.fighterId~="Mist" then return end
		local swinging=(actor.health or 1)>0 and not actor.toolThrowActive
		local st=held[model]
		if not st then
			local hand=model:FindFirstChild("RightHand")
			if not hand then return end
			local m=new("Model",{Name="HeldCleaver"},model)
			local blade=block(m,Vector3.new(.16,4.4,1.5),hand.CFrame*CFrame.new(0,-3.0,-.35),Color3.fromRGB(180,188,196),Enum.Material.Metal)
			local grip=block(m,Vector3.new(.24,1.1,.24),hand.CFrame*CFrame.new(0,-.25,0),Color3.fromRGB(60,46,36),Enum.Material.SmoothPlastic)
			local hole=block(m,Vector3.new(.18,.5,.5),hand.CFrame*CFrame.new(0,-4.6,-.55),Color3.fromRGB(30,30,34),Enum.Material.SmoothPlastic)
			for _,p in {blade,grip,hole} do p.Anchored=false;p.CanCollide=false;p.Massless=true;new("WeldConstraint",{Part0=hand,Part1=p},p) end
			-- The arc the edge cuts while the strike is live (QA-004 M6: the hit
			-- reads as coming from the blade, not from his fist).
			local a0=new("Attachment",{Position=Vector3.new(0,-2.1,-.6)},blade)
			local a1=new("Attachment",{Position=Vector3.new(0,2.1,-.6)},blade)
			local trail=new("Trail",{Attachment0=a0,Attachment1=a1,Lifetime=.14,Color=ColorSequence.new(Color3.fromRGB(226,236,244)),LightEmission=.5,
				Transparency=num({{0,.35},{1,1}}),FaceCamera=false,Enabled=false},blade)
			st={model=m,parts={blade,grip,hole},shown=nil,trail=trail};held[model]=st
		end
		st.trail.Enabled=swinging and actor.state=="Active"
		if st.shown==swinging then return end
		st.shown=swinging
		for _,p in st.parts do p.LocalTransparencyModifier=if swinging then 0 else 1 end
		for _,p in model:GetChildren() do if BACK[p.Name] and p:IsA("BasePart") then p.LocalTransparencyModifier=if swinging then 1 else 0 end end
	end
	-- Kimimaro: the skeleton in the blows (bible KIMIMARO.md §7, §11). A bone
	-- is born on the limb that strikes during the wind-up, is full during the
	-- live window and visibly retracts in the recovery: knuckles (L1, the
	-- rise), elbow (L2, flank arc, riposte, dash), shin (L3, reap, air), the
	-- forearm bones (Heavy, guard, Willow). Presentation only: the server's
	-- contact and guard rules are unchanged; nothing is left out at rest.
	local BONE=Color3.fromRGB(240,234,214)
	local USE={
		Light1="knuckle",BoneRise="forearm",
		Light2="elbow",CamelliaArc="elbowR",BoneElbow="elbow",DashAttack="elbowR",
		Light3="shin",BoneReap="shin",Air1="knee",Air2="shin",BoneHeel="shin",
		Heavy="forearm",WillowCut="forearm",
	}
	local skel=setmetatable({},{__mode="k"})
	local function spur(m,limb,anchor,dir,len,thick,color,material)
		local p=block(m,Vector3.new(thick,thick,len),limb.CFrame,color or BONE,material or Enum.Material.SmoothPlastic)
		p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true
		local w=new("Weld",{Part0=limb,Part1=p,C0=anchor},p)
		p.LocalTransparencyModifier=1
		return {part=p,weld=w,anchor=anchor,dir=dir,len=len,thick=thick,f=0}
	end
	local function skeleton(model)
		local rh,la,ra,rl,ll=model:FindFirstChild("RightHand"),model:FindFirstChild("LeftLowerArm"),model:FindFirstChild("RightLowerArm"),model:FindFirstChild("RightLowerLeg"),model:FindFirstChild("LeftLowerLeg")
		if not (rh and la and ra and rl and ll) then return nil end
		local m=new("Model",{Name="LivingBones"},model)
		local down,back,fwd=Vector3.new(0,-1,0),Vector3.new(0,1,0),Vector3.new(0,0,-1)
		local st={sets={}}
		-- Knuckles: three short points out of the fist, along the punch.
		st.sets.knuckle={spur(m,rh,CFrame.new(-.15,-.35,0),down,.4,.1),spur(m,rh,CFrame.new(0,-.35,0),down,.45,.1),spur(m,rh,CFrame.new(.15,-.35,0),down,.4,.1)}
		-- Elbow spurs out past the joint (left for L2 / riposte, right for the flank arc and the dash).
		st.sets.elbow={spur(m,la,CFrame.new(0,.45,.12),back,.7,.16)}
		st.sets.elbowR={spur(m,ra,CFrame.new(0,.45,.12),back,.7,.16)}
		-- Shin spurs, short, on the front of the right shin.
		st.sets.shin={spur(m,rl,CFrame.new(0,.25,-.3),fwd,.35,.1),spur(m,rl,CFrame.new(0,-.15,-.3),fwd,.35,.1)}
		st.sets.knee={spur(m,rl,CFrame.new(0,.45,-.3),fwd,.4,.12)}
		-- Radius and ulna out along both forearms (the guard, the heavy).
		st.sets.forearm={spur(m,ra,CFrame.new(.2,-.1,0),down,1.1,.12),spur(m,la,CFrame.new(-.2,-.1,0),down,1.1,.12)}
		return st
	end
	-- Haku (bible HAKU.md §7, §11): senbon between the fingers of both hands
	-- for the whole duel (welded, never thrown by a light), a spike of ice
	-- born at the left wrist for the palm and the lift, at the right wrist
	-- for the heavy push and the guard's deflection; a thin plate of ice
	-- under the gliding foot that breaks at once.
	local ICE=Color3.fromRGB(214,240,255)
	local STEELN=Color3.fromRGB(200,206,214)
	local ICE_USE={Light2="wristL",FrostLift="wristL",Heavy="wristR"}
	local GLIDE={Light2=true,IceSlide=true,SenbonLow=true,DashAttack=true,Light3=true}
	local function icework(model)
		local rh,lh,la,ra=model:FindFirstChild("RightHand"),model:FindFirstChild("LeftHand"),model:FindFirstChild("LeftLowerArm"),model:FindFirstChild("RightLowerArm")
		if not (rh and lh and la and ra) then return nil end
		local m=new("Model",{Name="SenbonAndIce"},model)
		for _,hand in {rh,lh} do
			for i=-1,1 do
				local n=block(m,Vector3.new(.04,.7,.04),hand.CFrame*CFrame.new(i*.12,-.55,-.05),STEELN,Enum.Material.Metal)
				n.Anchored=false;n.CanCollide=false;n.CanQuery=false;n.CanTouch=false;n.Massless=true
				new("WeldConstraint",{Part0=hand,Part1=n},n)
			end
		end
		local down=Vector3.new(0,-1,0)
		local st={sets={}}
		st.sets.wristL={spur(m,la,CFrame.new(0,-.4,-.2),Vector3.new(0,0,-1),.7,.14,ICE,Enum.Material.Glass)}
		st.sets.wristR={spur(m,ra,CFrame.new(0,-.4,-.2),Vector3.new(0,0,-1),.7,.14,ICE,Enum.Material.Glass),spur(m,ra,CFrame.new(.18,-.1,0),down,.8,.1,ICE,Enum.Material.Glass)}
		return st
	end
	local KITS={Bone={build=skeleton,use=USE,guard="forearm"},Mirror={build=icework,use=ICE_USE,guard="wristR"}}
	local glided=setmetatable({},{__mode="k"})
	local function plate(fx,model,actor)
		local key=(actor.attackName or "").."@"..tostring(actor.state)
		if glided[model]==key then return end
		glided[model]=key
		if not (actor.state=="Active" and GLIDE[actor.attackName or ""]) then return end
		local root=model:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local floor=kit.floorUnder(fx,root.Position,3,14)
		local at=if floor then floor.Position else root.Position-Vector3.new(0,2.9,0)
		local p=block(fx.folder,Vector3.new(2.2,.08,2.2),CFrame.new(at+Vector3.new(0,.05,0))*CFrame.Angles(0,math.rad(math.random(0,90)),0),ICE,Enum.Material.Glass)
		p.Transparency=.35
		tween(p,.35,{Transparency=1,Size=Vector3.new(2.6,.04,2.6)})
		Debris:AddItem(p,.4)
	end
	local function bones(fx,model,actor,dt)
		local kitOf=KITS[actor.fighterId or ""]
		if not kitOf then return end
		if actor.fighterId=="Mirror" then plate(fx,model,actor) end
		local st=skel[model]
		if st==nil then st=kitOf.build(model) or false;skel[model]=st end
		if not st then return end
		local a=actor.attackName
		local want=if (actor.health or 1)<=0 then nil
			elseif actor.state=="Guarding" then kitOf.guard
			elseif a and (actor.state=="Startup" or actor.state=="Active") then kitOf.use[a]
			else nil
		for name,set in st.sets do
			-- Grow fast in the wind-up (before the contact), retract a little slower.
			local target=if name==want then 1 else 0
			for _,b in set do
				local rate=if target>b.f then 14 else 7
				b.f=if math.abs(target-b.f)<.02 then target else b.f+(target-b.f)*math.min(1,dt*rate)
				if b.f<=.02 then
					if b.part.LocalTransparencyModifier~=1 then b.part.LocalTransparencyModifier=1 end
				else
					local l=b.len*b.f
					b.part.LocalTransparencyModifier=0
					b.part.Size=if b.dir.Z~=0 then Vector3.new(b.thick,b.thick,l) else Vector3.new(b.thick,l,b.thick)
					b.weld.C0=b.anchor*CFrame.new(b.dir*l/2)
				end
			end
		end
	end
	-- Lost in Zabuza's mist (Families.shrouded on the viewer): he fades to a
	-- shadow for the one who cannot see him.
	local faded=setmetatable({},{__mode="k"})
	local function shroud(fx,data,dt,folder)
		local me,them=data.human,data.bot
		if not me or not them or not folder then return end
		local model=folder:FindFirstChild(them.id or "")
		if not model then return end
		local lost=me.family~=nil and me.family.shrouded==true
		if (faded[model]==true)==lost then return end
		faded[model]=lost
		for _,p in model:GetDescendants() do
			if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.LocalTransparencyModifier=if lost then .82 else 0 end
		end
	end
	-- Runs before FamilyFX's layer and lets it draw the zone's floor too.
	table.insert(FX.layers,1,{name="Wave1",fighter=function(fx,model,actor,dt) if model then cleaver(fx,model,actor);bones(fx,model,actor,dt or 1/60) end end,
		frame=function(fx,data,dt,folder) shroud(fx,data,dt,folder) end,impact=function(fx,impact,folder)
		if impact.style=="zone" and impact.kind=="mirror" then
			mirrors(fx,impact.position,math.max(3,(impact.radius or 7)-.5),impact.time or 5)
		elseif impact.style=="zone" and impact.kind=="mist" and (impact.radius or 0)>=10 then
			mist(fx,impact.position,impact.radius,impact.time or 6)
		end
		return false
	end})
end
return M
