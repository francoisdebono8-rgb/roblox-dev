-- Roster 20, batch 2 (Shisui, Orochimaru, Kabuto): the batch's server side.
-- Their techniques all run on the shared families; this module dresses them.
local Base=require(script.Parent.Wave1Kit)
local paint,ARMS,LEGS,TORSO=Base.paint,Base.ARMS,Base.LEGS,Base.TORSO
local Kit={}
function Kit.install(Techniques) end
function Kit.dress(dressers,kit)
	local wear,face,hairCap,spike,headband,rgb,A,R=kit.wear,kit.face,kit.hairCap,kit.spike,kit.headband,kit.rgb,kit.A,kit.R
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

	-- Shisui (13): thick, messy black curls, the Leaf headband, the high-
	-- collared dark Uchiha shirt with the fan on the back, a short sword
	-- (tantō) at the small of the back, arm guards.
	dressers.Shisui=function(model,def)
		local hair=rgb(24,24,30)
		local shirt=rgb(40,44,60)
		local shade=rgb(30,32,44)
		hideCap(model,hair)
		face(model,rgb(40,30,30),hair)
		hairCap(model,hair)
		for _,s in {{Vector3.new(-.5,.7,-.2),Vector3.new(-.7,.6,-.6)},{Vector3.new(.5,.7,-.2),Vector3.new(.7,.6,-.6)},{Vector3.new(0,.8,.2),Vector3.new(0,1,.2)},
			{Vector3.new(-.6,.4,.4),Vector3.new(-1,.2,.6)},{Vector3.new(.6,.4,.4),Vector3.new(1,.2,.6)},{Vector3.new(0,.4,.7),Vector3.new(0,0,1)}} do
			spike(model,s[1],s[2],.8,.5,.46,hair)
		end
		headband(model)
		paint(model,TORSO,shirt);paint(model,ARMS,shirt);paint(model,LEGS,shade)
		wear(model,"UpperTorso","Collar",Vector3.new(1.4,.5,1.18),CFrame.new(0,.82,.02),shirt)
		-- The Uchiha fan on the back: white handle, red top.
		wear(model,"UpperTorso","FanRed",Vector3.new(.7,.5,.04),CFrame.new(0,.3,.56),rgb(200,40,40))
		wear(model,"UpperTorso","FanWhite",Vector3.new(.7,.36,.04),CFrame.new(0,-.1,.56),rgb(240,240,236))
		wear(model,"UpperTorso","FanHandle",Vector3.new(.14,.5,.04),CFrame.new(0,-.5,.56),rgb(240,240,236))
		wear(model,"LowerTorso","Belt",Vector3.new(2.06,.2,1.06),CFrame.new(0,.34,0),rgb(20,22,28))
		wear(model,"LowerTorso","Tanto",Vector3.new(.16,.16,1.6),CFrame.new(0,.2,.66)*A(0,R(90),R(10)),rgb(30,30,34))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","ArmGuard",Vector3.new(.86,.6,.86),CFrame.new(0,-.16,0),rgb(150,156,164),Enum.Material.Metal)
			wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.86,.5,.86),CFrame.new(0,-.2,0),rgb(220,220,214))
		end
		sandals(model,def,rgb(30,32,40))
	end

	-- Orochimaru (12): long straight black hair past the shoulders, pale
	-- skin, the purple marks round the eyes, a grey-blue genin outfit with a
	-- purple rope belt, the Leaf headband.
	dressers.Orochimaru=function(model,def)
		local hair=rgb(24,24,30)
		local suit=rgb(70,78,96)
		local shade=rgb(54,60,76)
		hideCap(model,hair)
		face(model,rgb(200,170,60),hair)
		hairCap(model,hair)
		wear(model,"Head","Fringe",Vector3.new(1.6,.36,.2),CFrame.new(0,.5,-.78),hair)
		for _,side in {-1,1} do
			wear(model,"Head","SideHair",Vector3.new(.22,1.8,1.1),CFrame.new(side*.84,-.4,.1),hair)
			wear(model,"Head","EyeMark",Vector3.new(.3,.12,.03),CFrame.new(side*.26,.12,-.83),rgb(130,80,160))
		end
		wear(model,"Head","BackHair",Vector3.new(1.6,2,.3),CFrame.new(0,-.6,.76),hair)
		headband(model)
		paint(model,TORSO,suit);paint(model,ARMS,suit);paint(model,LEGS,shade)
		wear(model,"UpperTorso","Robe",Vector3.new(2.1,1.7,1.14),CFrame.new(0,-.02,0),suit)
		wear(model,"UpperTorso","Lapel",Vector3.new(.5,1.4,.06),CFrame.new(.3,0,-.58)*A(0,0,R(-12)),shade)
		wear(model,"LowerTorso","Rope",Vector3.new(2.2,.4,1.2),CFrame.new(0,.3,0),rgb(110,70,150))
		wear(model,"LowerTorso","RopeKnot",Vector3.new(.5,.5,.4),CFrame.new(0,.3,.62),rgb(110,70,150))
		-- A small white snake curled round the left wrist.
		wear(model,"LeftLowerArm","WristSnake",Vector3.new(.92,.2,.92),CFrame.new(0,-.36,0),rgb(236,234,228))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.86,.5,.86),CFrame.new(0,-.2,0),rgb(220,220,214))
		end
		sandals(model,def,rgb(40,44,52))
	end

	-- Kabuto (13): grey hair in a short ponytail, round glasses, the purple
	-- shirt with the white collar, a dark belt with pouches, the Leaf headband.
	dressers.Kabuto=function(model,def)
		local hair=rgb(200,200,206)
		local shirt=rgb(110,84,130)
		local shade=rgb(84,64,100)
		hideCap(model,hair)
		face(model,rgb(40,36,40),hair)
		hairCap(model,hair)
		wear(model,"Head","Fringe",Vector3.new(1.6,.3,.2),CFrame.new(0,.52,-.78),hair)
		wear(model,"Head","Tail",Vector3.new(.4,.9,.36),CFrame.new(0,-.4,.86),hair)
		-- Round glasses: two rims and the bridge.
		for _,side in {-1,1} do
			wear(model,"Head","Lens",Vector3.new(.36,.3,.03),CFrame.new(side*.26,.1,-.86),rgb(220,236,240),Enum.Material.Glass)
			wear(model,"Head","Rim",Vector3.new(.4,.34,.02),CFrame.new(side*.26,.1,-.85),rgb(60,60,66),Enum.Material.Metal)
		end
		wear(model,"Head","Bridge",Vector3.new(.16,.04,.03),CFrame.new(0,.14,-.87),rgb(60,60,66),Enum.Material.Metal)
		headband(model)
		paint(model,TORSO,shirt);paint(model,ARMS,shirt);paint(model,LEGS,shade)
		wear(model,"UpperTorso","Collar",Vector3.new(1.5,.32,1.16),CFrame.new(0,.82,0),rgb(236,234,230))
		wear(model,"LowerTorso","Belt",Vector3.new(2.06,.24,1.06),CFrame.new(0,.34,0),rgb(40,36,44))
		for _,x in {-.6,.6} do wear(model,"LowerTorso","Pouch",Vector3.new(.4,.4,.2),CFrame.new(x,.2,-.58),rgb(60,54,66)) end
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Wrap",Vector3.new(.86,.4,.86),CFrame.new(0,-.36,0),rgb(220,220,214))
		end
		sandals(model,def,rgb(40,36,44))
	end
end
return Kit
