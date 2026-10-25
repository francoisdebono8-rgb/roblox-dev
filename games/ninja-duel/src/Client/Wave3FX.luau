-- Roster 20, batch 3 (Deidara, Sasori, Nagato, Killer Bee): the batch's own
-- drawing, installed by Effects like SandFX: projectile builders
-- (kit.BUILD[kind]), FX.poses[kind], and layers in FX.layers
-- ({impact=..., fighter=..., step=..., frame=...}). Most objects need nothing
-- here: Shared/Looks + Client/FamilyFX draw them.
local M={}
function M.install(FX,kit)
	local new,block,num=kit.new,kit.block,kit.num
	-- Killer Bee's seven blades (bible KILLER_BEE.md §7): configuration A =
	-- a blade in each hand (continuing the forearm, as Wave3Motion authors
	-- them) and one under the left elbow; four sheathed on the back. For L3
	-- and the knee kick the elbow blade rides behind the right knee, point
	-- out of the body. Lariat / KO: everything goes back to the sheaths (the
	-- three spare ones fill). Presentation only: the server's single contact
	-- is unchanged, no blade adds a hitbox.
	local STEEL=Color3.fromRGB(206,212,220)
	local GRIP=Color3.fromRGB(40,36,40)
	local SHEATH=Color3.fromRGB(70,48,34)
	local KNEE={Light3=true,KneeKick=true}
	local ELBOW={Light2=true,ElbowCut=true}
	local BOTH={Heavy=true,Air2=true}
	local STOW={Lariat=true,LariatArm=true}
	local held=setmetatable({},{__mode="k"})
	local function weld(part0,parts)
		for _,p in parts do p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;new("WeldConstraint",{Part0=part0,Part1=p},p) end
	end
	local function show(parts,on) for _,p in parts do p.LocalTransparencyModifier=if on then 0 else 1 end end
	local function trail(blade,from,to)
		local a0=new("Attachment",{Position=from},blade)
		local a1=new("Attachment",{Position=to},blade)
		return new("Trail",{Attachment0=a0,Attachment1=a1,Lifetime=.12,Color=ColorSequence.new(Color3.fromRGB(236,240,248)),LightEmission=.5,
			Transparency=num({{0,.35},{1,1}}),FaceCamera=false,Enabled=false},blade)
	end
	local function handBlade(m,hand)
		local cf=hand.CFrame
		local blade=block(m,Vector3.new(.08,2.4,.26),cf*CFrame.new(0,-1.55,-.04),STEEL,Enum.Material.Metal)
		local guard=block(m,Vector3.new(.34,.08,.34),cf*CFrame.new(0,-.36,0),GRIP,Enum.Material.Metal)
		local grip=block(m,Vector3.new(.16,.6,.16),cf*CFrame.new(0,-.05,0),GRIP,Enum.Material.SmoothPlastic)
		weld(hand,{blade,guard,grip})
		return {blade,guard,grip},trail(blade,Vector3.new(0,-1.1,0),Vector3.new(0,1.1,0))
	end
	local function blades(model)
		local rh,lh=model:FindFirstChild("RightHand"),model:FindFirstChild("LeftHand")
		local la,rl=model:FindFirstChild("LeftLowerArm"),model:FindFirstChild("RightLowerLeg")
		local torso=model:FindFirstChild("UpperTorso")
		if not (rh and lh and la and rl and torso) then return nil end
		local m=new("Model",{Name="SevenBlades"},model)
		local st={}
		st.right,st.rightTrail=handBlade(m,rh)
		st.left,st.leftTrail=handBlade(m,lh)
		-- Under the left elbow: along the forearm, past the elbow, tilted out.
		local e=block(m,Vector3.new(.08,2.1,.24),la.CFrame*CFrame.new(0,.75,.26)*CFrame.Angles(math.rad(14),0,0),STEEL,Enum.Material.Metal)
		weld(la,{e})
		st.elbow={e};st.elbowTrail=trail(e,Vector3.new(0,-1,0),Vector3.new(0,1,0))
		-- Behind the right knee, the point out to the side.
		local k=block(m,Vector3.new(2.1,.24,.08),rl.CFrame*CFrame.new(1.2,.3,.24),STEEL,Enum.Material.Metal)
		local kg=block(m,Vector3.new(.3,.3,.14),rl.CFrame*CFrame.new(.2,.3,.24),GRIP,Enum.Material.SmoothPlastic)
		weld(rl,{k,kg})
		st.knee={k,kg};st.kneeTrail=trail(k,Vector3.new(-1,0,0),Vector3.new(1,0,0))
		-- Seven sheaths fanned on the back; the last three are filled only
		-- while the hand/elbow blades are put away.
		st.sheaths={};st.spare={}
		for i=1,7 do
			local x=(i-4)*.18
			local cf=torso.CFrame*CFrame.new(x,.15,.58)*CFrame.Angles(0,0,math.rad((i-4)*9))
			local s=block(m,Vector3.new(.14,2.2,.16),cf,SHEATH,Enum.Material.Wood)
			local h=block(m,Vector3.new(.12,.42,.12),cf*CFrame.new(0,1.3,0),GRIP,Enum.Material.SmoothPlastic)
			weld(torso,{s})
			weld(torso,{h})
			table.insert(st.sheaths,s)
			if i>=5 then table.insert(st.spare,h) end
		end
		return st
	end
	local function sevenBlades(model,actor)
		if actor.fighterId~="Ink" then return end
		local st=held[model]
		if st==nil then st=blades(model) or false;held[model]=st end
		if not st then return end
		local a=actor.attackName
		local stow=(actor.health or 1)<=0 or actor.toolThrowActive or (a~=nil and STOW[a]==true)
		local knee=not stow and a~=nil and KNEE[a]==true
		local config=if stow then "stow" elseif knee then "knee" else "A"
		local live=actor.state=="Active" and a~=nil
		st.rightTrail.Enabled=live and not stow and not KNEE[a] and not ELBOW[a]
		st.leftTrail.Enabled=live and BOTH[a]==true
		st.elbowTrail.Enabled=live and ELBOW[a]==true
		st.kneeTrail.Enabled=live and knee
		if st.config==config then return end
		st.config=config
		show(st.right,not stow);show(st.left,not stow)
		show(st.elbow,config=="A");show(st.knee,knee)
		show(st.spare,stow)
	end
	table.insert(FX.layers,{name="Wave3",fighter=function(fx,model,actor,dt) if model then sevenBlades(model,actor) end end})
end
return M
