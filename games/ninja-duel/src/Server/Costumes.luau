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

	-- Kakashi (14, the Copy Ninja): silver hair swept up and to one side, the
	-- mask over his nose and mouth, the headband slanted over his left eye
	-- (the Sharingan under it), a green flak vest over navy.
	dressers.Kakashi=function(model,def)
		local hair=rgb(214,218,222)
		local hairShade=rgb(178,184,192)
		local navy=rgb(40,50,72)
		local vest=rgb(92,112,70)
		local vestShade=rgb(70,88,54)
		local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
		face(model,rgb(40,40,44),rgb(150,150,156))
		hairCap(model,hair)
		-- The hair rises in a slanted crest toward his right.
		local spikes={{Vector3.new(0,.8,.1),Vector3.new(.5,1,.2),1.5},{Vector3.new(-.3,.75,.2),Vector3.new(.1,1,.3),1.4},{Vector3.new(.35,.65,.1),Vector3.new(.9,.7,.2),1.3},
			{Vector3.new(-.55,.55,.2),Vector3.new(-.4,1,.4),1.1},{Vector3.new(0,.5,.6),Vector3.new(.3,.6,1),1.2},{Vector3.new(.55,.35,.3),Vector3.new(1,.25,.4),1.0}}
		for i,s in spikes do spike(model,s[1],s[2],s[3],.5,.42,if i%2==0 then hairShade else hair) end
		-- The mask: up over the nose, the mouth hidden.
		wear(model,"Head","Mask",Vector3.new(1.62,.62,1.62),CFrame.new(0,-.36,-.02),navy)
		for _,p in model:GetChildren() do if p.Name=="Mouth" then p.Transparency=1 end end
		-- The headband slanted down over the left eye (+12 degrees of roll lowers
		-- his left side, -X).
		local tilt=A(0,0,R(12))
		wear(model,"Head","Headband",Vector3.new(1.68,.26,1.68),CFrame.new(0,.26,0)*tilt,rgb(28,36,58))
		wear(model,"Head","HeadbandPlate",Vector3.new(.9,.32,.06),CFrame.new(-.06,.24,-.86)*tilt,rgb(176,184,194),Enum.Material.Metal)
		wear(model,"Head","LeafMark",Vector3.new(.3,.14,.02),CFrame.new(-.06,.26,-.9)*tilt,rgb(70,78,90),Enum.Material.Metal)
		wear(model,"Head","EyeCover",Vector3.new(.42,.26,.06),CFrame.new(-.3,.1,-.83),rgb(28,36,58))
		paint(model,TORSO,navy);paint(model,ARMS,navy);paint(model,LEGS,navy)
		-- Flak vest with its scroll pouches, the red swirl on the shoulders skipped.
		wear(model,"UpperTorso","Vest",Vector3.new(2.1,1.62,1.14),CFrame.new(0,-.02,0),vest)
		wear(model,"UpperTorso","VestCollar",Vector3.new(1.5,.3,1.16),CFrame.new(0,.82,.02),vestShade)
		for _,x in {-.5,.5} do
			for k=0,1 do wear(model,"UpperTorso","Pouch",Vector3.new(.42,.36,.12),CFrame.new(x,-.12-k*.42,-.6),vestShade) end
		end
		wear(model,"LowerTorso","Belt",Vector3.new(2.06,.2,1.06),CFrame.new(0,.34,0),rgb(30,34,46))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Glove",Vector3.new(.84,.4,.84),CFrame.new(0,-.36,0),rgb(30,32,40))
			wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.86,.55,.86),CFrame.new(0,-.2,0),rgb(220,220,214))
		end
		wear(model,"RightUpperLeg","Holster",Vector3.new(.24,.5,.5),CFrame.new(.5,-.05,0),rgb(30,34,46))
		sandals(model,def,rgb(40,46,66))
	end
end
return Costumes
