-- Roster 20, batch 1 (Haku, Zabuza, Kimimaro): the batch's server side. All
-- three techniques sets run on the shared families (Server/Families); this
-- module only dresses them. Never a condition on a fighter's name in the
-- shared core: hooks and families.
local Kit={}
function Kit.install(Techniques) end

local ARMS={"LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"}
local LEGS={"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"}
local TORSO={"UpperTorso","LowerTorso"}
local function paint(model,names,color)
	for _,name in names do local part=model:FindFirstChild(name);if part then part.Color=color end end
end
Kit.paint=paint;Kit.ARMS=ARMS;Kit.LEGS=LEGS;Kit.TORSO=TORSO

function Kit.dress(dressers,kit)
	local wear,face,hairCap,spike,rgb,A,R=kit.wear,kit.face,kit.hairCap,kit.spike,kit.rgb,kit.A,kit.R
	local function sandals(model,def,strap)
		local skin=Color3.fromRGB(table.unpack(def.Skin))
		for _,side in {"Left","Right"} do
			local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=strap end
			wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),skin)
		end
	end
	local function hideCap(model,color)
		local cap=model:FindFirstChild("Hair");if cap then cap.Color=color;cap.Transparency=1 end
	end

	-- Haku (15): long black hair tied back loosely, two locks at the face, a
	-- green-and-white haori over a dark kimono, the hunter-nin mask pushed to
	-- the side of his head, a wide obi.
	dressers.Haku=function(model,def)
		local hair=rgb(30,30,36)
		local robe=rgb(110,140,112)
		local robeShade=rgb(84,110,88)
		local under=rgb(40,46,52)
		hideCap(model,hair)
		face(model,rgb(70,60,52),hair)
		hairCap(model,hair)
		wear(model,"Head","Fringe",Vector3.new(1.6,.32,.2),CFrame.new(0,.5,-.78),hair)
		for _,side in {-1,1} do
			wear(model,"Head","FaceLock",Vector3.new(.22,1.4,.3),CFrame.new(side*.78,-.3,-.48),hair)
		end
		wear(model,"Head","BackHair",Vector3.new(1.5,1.2,.3),CFrame.new(0,0,.74),hair)
		wear(model,"Head","Tail",Vector3.new(.5,1.6,.4),CFrame.new(0,-.9,.84)*A(R(-12),0,0),hair)
		wear(model,"Head","HairTie",Vector3.new(.56,.16,.46),CFrame.new(0,-.1,.86),rgb(220,220,214))
		-- The mask: white, the Mist's mark, pushed to the side.
		wear(model,"Head","Mask",Vector3.new(.9,1.1,.08),CFrame.new(.84,.1,-.1)*A(0,R(-70),0),rgb(240,240,236))
		wear(model,"Head","MaskMark",Vector3.new(.5,.08,.02),CFrame.new(.88,.36,-.12)*A(0,R(-70),0),rgb(150,40,40))
		paint(model,TORSO,under);paint(model,ARMS,robe);paint(model,LEGS,under)
		wear(model,"UpperTorso","Haori",Vector3.new(2.1,1.7,1.14),CFrame.new(0,-.02,0),robe)
		wear(model,"UpperTorso","Collar",Vector3.new(1.2,.5,1.16),CFrame.new(0,.7,-.02),rgb(226,230,222))
		wear(model,"LowerTorso","Obi",Vector3.new(2.1,.46,1.12),CFrame.new(0,.28,0),robeShade)
		wear(model,"LowerTorso","Skirt",Vector3.new(2.14,.8,1.16),CFrame.new(0,-.36,0),robe)
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Sleeve",Vector3.new(1.0,.5,1.0),CFrame.new(0,-.2,0),robeShade)
		end
		-- Senbon held in the right hand's fingers (the tool's tell at rest).
		for k=-1,1 do
			wear(model,"RightHand","Senbon",Vector3.new(.04,.04,1.1),CFrame.new(k*.1,-.2,-.3),rgb(220,226,236),Enum.Material.Metal)
		end
		sandals(model,def,rgb(40,46,52))
	end

	-- Zabuza (14): spiky black hair, the forehead protector worn sideways, the
	-- bandage over the mouth, bare arms, grey camouflage trousers, the leather
	-- harness and the great cleaver on his back.
	dressers.Zabuza=function(model,def)
		local hair=rgb(30,30,34)
		local grey=rgb(120,128,130)
		local greyShade=rgb(96,104,108)
		local skin=Color3.fromRGB(table.unpack(def.Skin))
		hideCap(model,hair)
		face(model,rgb(36,34,32),hair)
		hairCap(model,hair)
		for i,s in {{Vector3.new(0,.8,.1),Vector3.new(0,1,.2)},{Vector3.new(-.4,.7,.2),Vector3.new(-.5,.9,.3)},{Vector3.new(.4,.7,.2),Vector3.new(.5,.9,.3)},{Vector3.new(0,.6,.6),Vector3.new(0,.6,1)}} do
			spike(model,s[1],s[2],1.0,.42,.36,hair)
		end
		-- Headband slanted to the side, the Mist's plate.
		wear(model,"Head","Headband",Vector3.new(1.68,.26,1.68),CFrame.new(0,.34,0)*A(0,0,R(-10)),rgb(60,66,70))
		wear(model,"Head","HeadbandPlate",Vector3.new(.86,.3,.06),CFrame.new(.2,.36,-.85)*A(0,R(-14),R(-10)),rgb(176,184,194),Enum.Material.Metal)
		-- The bandage over the mouth and neck.
		wear(model,"Head","Bandage",Vector3.new(1.64,.62,1.64),CFrame.new(0,-.38,-.02),rgb(226,222,210))
		for _,p in model:GetChildren() do if p.Name=="Mouth" then p.Transparency=1 end end
		paint(model,TORSO,grey);paint(model,ARMS,skin);paint(model,LEGS,grey)
		wear(model,"UpperTorso","Harness",Vector3.new(.3,1.9,1.14),CFrame.new(.2,0,0)*A(0,0,R(30)),rgb(70,56,44))
		wear(model,"LowerTorso","Belt",Vector3.new(2.06,.24,1.06),CFrame.new(0,.34,0),rgb(70,56,44))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Guard",Vector3.new(.86,.6,.86),CFrame.new(0,-.2,0),greyShade)
			wear(model,side.."LowerLeg","Wrap",Vector3.new(.86,.6,.86),CFrame.new(0,-.2,0),greyShade)
		end
		-- Kubikiribōchō on the back: the great blade, its round hole, the handle.
		wear(model,"UpperTorso","Cleaver",Vector3.new(.16,4.6,1.6),CFrame.new(0,.3,.72)*A(0,R(90),R(-28)),rgb(180,188,196),Enum.Material.Metal)
		wear(model,"UpperTorso","CleaverHole",Vector3.new(.18,.6,.6),CFrame.new(-.9,1.6,.72)*A(0,R(90),R(-28)),rgb(30,30,34))
		wear(model,"UpperTorso","CleaverGrip",Vector3.new(.24,1.3,.24),CFrame.new(1.3,-1.8,.72)*A(0,0,R(-28)),rgb(60,46,36))
		sandals(model,def,rgb(50,54,58))
	end

	-- Kimimaro (13): white hair to the shoulders parted in the middle, two red
	-- dots on the brow, a loose white robe open at the chest, the thick purple
	-- rope belt; bone at the shoulder ready to be drawn.
	dressers.Kimimaro=function(model,def)
		local hair=rgb(236,234,228)
		local robe=rgb(236,232,224)
		local robeShade=rgb(206,200,190)
		hideCap(model,hair)
		face(model,rgb(60,90,60),hair)
		hairCap(model,hair)
		wear(model,"Head","Parting",Vector3.new(1.66,.3,.3),CFrame.new(0,.5,-.74),hair)
		for _,side in {-1,1} do
			wear(model,"Head","SideHair",Vector3.new(.24,1.4,1.0),CFrame.new(side*.84,-.2,.1),hair)
			wear(model,"Head","BrowDot",Vector3.new(.14,.14,.04),CFrame.new(side*.22,.42,-.82),rgb(196,40,48))
		end
		wear(model,"Head","BackHair",Vector3.new(1.6,1.4,.3),CFrame.new(0,-.2,.74),hair)
		paint(model,TORSO,robe);paint(model,ARMS,robe);paint(model,LEGS,robeShade)
		wear(model,"UpperTorso","Robe",Vector3.new(2.1,1.7,1.14),CFrame.new(0,-.02,0),robe)
		wear(model,"UpperTorso","OpenChest",Vector3.new(.5,.9,.06),CFrame.new(0,.2,-.58),Color3.fromRGB(table.unpack(def.Skin)))
		wear(model,"LowerTorso","Rope",Vector3.new(2.2,.5,1.2),CFrame.new(0,.3,0),rgb(110,70,150))
		wear(model,"LowerTorso","RopeKnot",Vector3.new(.6,.6,.4),CFrame.new(0,.3,.62),rgb(110,70,150))
		wear(model,"LowerTorso","Skirt",Vector3.new(2.14,.9,1.16),CFrame.new(0,-.4,0),robe)
		-- The bone at the shoulder (the Camellia's hilt) and a spur at each wrist.
		wear(model,"RightUpperArm","ShoulderBone",Vector3.new(.24,.9,.24),CFrame.new(0,.7,0)*A(R(-20),0,0),rgb(244,238,220))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","WristSpur",Vector3.new(.14,.6,.14),CFrame.new(0,-.1,.4)*A(R(30),0,0),rgb(244,238,220))
		end
		sandals(model,def,rgb(200,196,186))
	end
end
return Kit
