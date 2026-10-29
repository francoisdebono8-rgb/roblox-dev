-- Costumes of the roster breadth pass (ROSTER_20): each one registers under
-- its fighter's Name and is built from World's costume helpers (kit: wear,
-- cyl, headband, face, hairCap, spike, rgb, A, R). Young fighters (12-14),
-- practical gear, silhouettes that read at combat distance; flat materials.
local Costumes={}

function Costumes.install(dressers,kit)
	local wear,face,hairCap,spike,rgb,A,R=kit.wear,kit.face,kit.hairCap,kit.spike,kit.rgb,kit.A,kit.R

	local function paint(model,names,color)
		for _,name in names do local part=model:FindFirstChild(name);if part then part.Color=color end end
	end
	local ARMS={"LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"}
	local LEGS={"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"}
	local TORSO={"UpperTorso","LowerTorso"}
	local function sandals(model,def,strap)
		local skin=Color3.fromRGB(table.unpack(def.Skin))
		for _,side in {"Left","Right"} do
			local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=strap end
			wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),skin)
		end
	end
	Costumes.paint=paint;Costumes.sandals=sandals

	-- Hinata (12): short dark-indigo hair with two long locks framing the face,
	-- a pale lavender hooded jacket with a fur-trimmed hood down, navy trousers,
	-- the headband worn round the neck, the Byakugan's pale eyes.
	dressers.Hinata=function(model,def)
		local hair=rgb(40,36,70)
		local jacket=rgb(222,214,236)
		local jacketShade=rgb(190,180,212)
		local trousers=rgb(44,48,82)
		local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
		face(model,rgb(214,206,240),hair)
		for _,p in model:GetChildren() do
			if p.Name=="Eye" then p.Color=rgb(244,242,252);p.Size=Vector3.new(.32,.2,.04) end
			if p.Name=="Iris" then p.Material=Enum.Material.Neon;p.Transparency=.35;p.Color=rgb(206,198,240) end
		end
		hairCap(model,hair)
		-- Short cut: a straight fringe and two long locks down to the chin.
		wear(model,"Head","Fringe",Vector3.new(1.62,.3,.18),CFrame.new(0,.52,-.78),hair)
		for _,side in {-1,1} do
			wear(model,"Head","FaceLock",Vector3.new(.2,1.25,.32),CFrame.new(side*.78,-.22,-.5)*A(0,0,R(side*-3)),hair)
			wear(model,"Head","SideHair",Vector3.new(.18,.9,.9),CFrame.new(side*.82,.02,.2),hair)
		end
		wear(model,"Head","BackHair",Vector3.new(1.66,1.1,.28),CFrame.new(0,0,.74),hair)
		paint(model,TORSO,jacket);paint(model,ARMS,jacket);paint(model,LEGS,trousers)
		-- The jacket: a zip, a fur trim where the hood falls, cuffs.
		wear(model,"UpperTorso","Zip",Vector3.new(.06,1.5,.04),CFrame.new(0,-.05,-.53),jacketShade)
		wear(model,"UpperTorso","HoodDown",Vector3.new(1.5,.5,.6),CFrame.new(0,.7,.42),jacketShade)
		wear(model,"UpperTorso","FurTrim",Vector3.new(1.56,.2,1.12),CFrame.new(0,.86,0),rgb(238,234,226))
		wear(model,"LowerTorso","Hem",Vector3.new(2.08,.34,1.1),CFrame.new(0,-.1,0),jacket)
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Cuff",Vector3.new(.86,.2,.86),CFrame.new(0,-.42,0),jacketShade)
		end
		-- The Leaf headband round her neck, the plate at her throat.
		wear(model,"UpperTorso","NeckBand",Vector3.new(1.3,.22,1.0),CFrame.new(0,.98,0),rgb(28,36,58))
		wear(model,"UpperTorso","NeckPlate",Vector3.new(.66,.24,.06),CFrame.new(0,.98,-.52),rgb(176,184,194),Enum.Material.Metal)
		sandals(model,def,rgb(40,46,66))
	end

	-- Kakashi (13, Kakashi Gaiden; user 29/10: "Kakashi petit, version Storm,
	-- un petit sabre dans le dos"): silver hair swept up and to his right, the
	-- navy mask over nose and mouth, the headband straight across the forehead
	-- (Obito's eye comes with the awakening), a navy high-collared shirt with
	-- no vest, dark arm guards, and the White Light Chakra Sabre sheathed
	-- across his back, the white-wrapped hilt over his right shoulder. The hilt
	-- parts are named Sheathed*: the client hides them while the blade is drawn.
	dressers.Kakashi=function(model,def)
		local hair=rgb(214,218,222)
		local hairShade=rgb(178,184,192)
		local navy=rgb(36,44,66)
		local navyShade=rgb(26,32,50)
		local guardDark=rgb(28,30,38)
		local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
		face(model,rgb(40,40,44),rgb(150,150,156))
		hairCap(model,hair)
		local spikes={{Vector3.new(0,.8,.1),Vector3.new(.5,1,.2),1.5},{Vector3.new(-.3,.75,.2),Vector3.new(.1,1,.3),1.4},{Vector3.new(.35,.65,.1),Vector3.new(.9,.7,.2),1.3},
			{Vector3.new(-.55,.55,.2),Vector3.new(-.4,1,.4),1.1},{Vector3.new(0,.5,.6),Vector3.new(.3,.6,1),1.2},{Vector3.new(.55,.35,.3),Vector3.new(1,.25,.4),1.0},
			{Vector3.new(-.2,.6,-.45),Vector3.new(.2,.8,-.6),.9}}
		for i,s in spikes do spike(model,s[1],s[2],s[3],.5,.42,if i%2==0 then hairShade else hair) end
		-- The mask, up over the nose; the mouth hidden.
		wear(model,"Head","Mask",Vector3.new(1.62,.62,1.62),CFrame.new(0,-.36,-.02),navy)
		for _,p in model:GetChildren() do if p.Name=="Mouth" then p.Transparency=1 end end
		-- Headband straight across the forehead.
		wear(model,"Head","Headband",Vector3.new(1.68,.26,1.68),CFrame.new(0,.3,0),rgb(28,36,58))
		wear(model,"Head","HeadbandPlate",Vector3.new(.9,.3,.06),CFrame.new(0,.3,-.86),rgb(176,184,194),Enum.Material.Metal)
		wear(model,"Head","LeafMark",Vector3.new(.3,.13,.02),CFrame.new(0,.31,-.9),rgb(70,78,90),Enum.Material.Metal)
		paint(model,TORSO,navy);paint(model,ARMS,navy);paint(model,LEGS,navy)
		-- High collar joined to the mask, a seam down the front.
		wear(model,"UpperTorso","Collar",Vector3.new(1.2,.34,1.0),CFrame.new(0,.88,0),navy)
		wear(model,"UpperTorso","Seam",Vector3.new(.05,1.4,.03),CFrame.new(.18,-.05,-.52),navyShade)
		-- Dark arm guards, elbow to knuckles.
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","ArmGuard",Vector3.new(.84,.9,.84),CFrame.new(0,-.1,0),guardDark)
			wear(model,side.."LowerArm","GuardPlate",Vector3.new(.5,.5,.08),CFrame.new(0,-.05,-.44),rgb(120,126,138),Enum.Material.Metal)
			wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.86,.55,.86),CFrame.new(0,-.2,0),rgb(220,220,214))
		end
		wear(model,"LowerTorso","Belt",Vector3.new(2.06,.2,1.06),CFrame.new(0,.34,0),navyShade)
		wear(model,"LowerTorso","BackPouch",Vector3.new(.7,.36,.24),CFrame.new(0,.2,.6),rgb(54,60,74))
		wear(model,"RightUpperLeg","Holster",Vector3.new(.24,.5,.5),CFrame.new(.5,-.05,0),navyShade)
		-- The sword strap across the chest, right shoulder to left hip.
		wear(model,"UpperTorso","Strap",Vector3.new(.14,2.05,.05),CFrame.new(0,.02,-.53)*A(0,0,R(36)),rgb(60,52,46))
		wear(model,"UpperTorso","StrapBack",Vector3.new(.14,2.05,.05),CFrame.new(0,.02,.53)*A(0,0,R(-36)),rgb(60,52,46))
		-- The sheath across the back, its mouth over the right shoulder.
		local axis=CFrame.new(.08,.1,.66)*A(0,0,R(-36))
		wear(model,"UpperTorso","Sheath",Vector3.new(.24,1.75,.2),axis,rgb(24,24,30))
		wear(model,"UpperTorso","SheathTip",Vector3.new(.26,.12,.22),axis*CFrame.new(0,-.9,0),rgb(150,154,162),Enum.Material.Metal)
		wear(model,"UpperTorso","SheathedGuard",Vector3.new(.36,.06,.36),axis*CFrame.new(0,.9,0),rgb(46,46,54),Enum.Material.Metal)
		wear(model,"UpperTorso","SheathedHilt",Vector3.new(.16,.6,.16),axis*CFrame.new(0,1.22,0),rgb(232,230,222))
		for k=0,2 do wear(model,"UpperTorso","SheathedWrap",Vector3.new(.18,.04,.18),axis*CFrame.new(0,1.02+k*.17,0),guardDark) end
		sandals(model,def,rgb(40,46,66))
	end
end
return Costumes
