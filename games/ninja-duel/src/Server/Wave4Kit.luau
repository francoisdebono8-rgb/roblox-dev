-- DEC-026 newcomers (Madara, Hashirama, Hiruzen as children): the batch's
-- server side. Their techniques run on the shared families (Counter with a
-- real answering strike, Burst arcs, a ground Projectile); this module only
-- dresses them. The weapons in their hands are drawn by Client/Wave4FX.
local Base=require(script.Parent.Wave1Kit)
local paint,ARMS,LEGS,TORSO=Base.paint,Base.ARMS,Base.LEGS,Base.TORSO
local Kit={}
function Kit.install(Techniques) end
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

	-- Madara (13): navy tunic with a short collar, dark trousers, short messy
	-- black hair, light arm guards; the short sword's scabbard at the left
	-- hip (the blade itself is in his hand while he strikes, Wave4FX).
	dressers.Madara=function(model,def)
		local hair=rgb(24,24,30)
		local navy=rgb(40,46,84)
		local dark=rgb(30,30,36)
		hideCap(model,hair)
		face(model,rgb(30,30,34),hair)
		hairCap(model,hair)
		for _,s in {{Vector3.new(-.5,.6,-.3),Vector3.new(-.7,.2,-.6)},{Vector3.new(.5,.6,-.3),Vector3.new(.7,.2,-.6)},{Vector3.new(0,.8,-.2),Vector3.new(.2,.5,-.9)},
			{Vector3.new(-.4,.5,.5),Vector3.new(-.8,-.2,.8)},{Vector3.new(.4,.5,.5),Vector3.new(.8,-.2,.8)},{Vector3.new(0,.5,.7),Vector3.new(0,-.4,1)}} do
			spike(model,s[1],s[2],.7,.5,.4,hair)
		end
		paint(model,TORSO,navy);paint(model,ARMS,navy);paint(model,LEGS,dark)
		wear(model,"UpperTorso","Tunic",Vector3.new(2.08,1.62,1.12),CFrame.new(0,-.02,0),navy)
		wear(model,"UpperTorso","Collar",Vector3.new(1.3,.34,1.14),CFrame.new(0,.82,.04),rgb(34,38,70))
		-- The fan crest on the back (a white disc over a red one).
		wear(model,"UpperTorso","CrestRed",Vector3.new(.8,.56,.04),CFrame.new(0,.26,.58),rgb(190,40,40))
		wear(model,"UpperTorso","CrestWhite",Vector3.new(.6,.42,.04),CFrame.new(0,.1,.59),rgb(236,236,236))
		wear(model,"LowerTorso","Belt",Vector3.new(2.04,.22,1.06),CFrame.new(0,.34,0),rgb(90,40,40))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","ArmGuard",Vector3.new(.66,.8,.66),CFrame.new(0,-.05,0),rgb(70,74,86),Enum.Material.Metal)
		end
		wear(model,"LowerTorso","Scabbard",Vector3.new(.2,.24,2.6),CFrame.new(-1.02,.1,.2)*A(R(28),0,0),rgb(30,26,26))
		wear(model,"LowerTorso","Hilt",Vector3.new(.18,.18,.8),CFrame.new(-1.02,.7,-1.0)*A(R(28),0,0),rgb(60,40,30))
		sandals(model,def,rgb(30,30,36))
	end

	-- Hashirama (13): a brick-brown short-sleeved tunic, dark trousers, black
	-- hair of a young length tied at the nape, bare forearms (the wood
	-- sheathes them when he strikes, Wave4FX).
	dressers.Hashirama=function(model,def)
		local hair=rgb(26,22,20)
		local tunic=rgb(150,74,46)
		local dark=rgb(46,40,36)
		local skin=Color3.fromRGB(table.unpack(def.Skin))
		hideCap(model,hair)
		face(model,rgb(60,40,30),hair)
		hairCap(model,hair)
		wear(model,"Head","Fringe",Vector3.new(1.6,.4,.3),CFrame.new(0,.48,-.78),hair)
		wear(model,"Head","NapeTie",Vector3.new(.4,.4,.4),CFrame.new(0,-.1,.92),hair)
		wear(model,"Head","NapeTail",Vector3.new(.36,1.0,.3),CFrame.new(0,-.7,.9)*A(R(-8),0,0),hair)
		paint(model,TORSO,tunic);paint(model,LEGS,dark)
		paint(model,{"LeftUpperArm","RightUpperArm"},tunic);paint(model,{"LeftLowerArm","RightLowerArm"},skin)
		wear(model,"UpperTorso","Tunic",Vector3.new(2.1,1.64,1.14),CFrame.new(0,-.02,0),tunic)
		wear(model,"UpperTorso","Collar",Vector3.new(1.4,.26,1.16),CFrame.new(0,.82,.02),rgb(120,56,36))
		wear(model,"LowerTorso","Sash",Vector3.new(2.08,.3,1.08),CFrame.new(0,.32,0),rgb(70,96,60))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Wrap",Vector3.new(.64,.24,.64),CFrame.new(0,-.36,0),rgb(220,210,190))
		end
		sandals(model,def,rgb(60,46,36))
	end

	-- Hiruzen (13): an earth-ochre tunic, short dark trousers, bandaged
	-- forearms, short brown hair brushed up, a young face; the dark wooden
	-- staff is in his hands (Wave4FX).
	dressers.Hiruzen=function(model,def)
		local hair=rgb(92,64,40)
		local ochre=rgb(176,134,70)
		local dark=rgb(54,48,40)
		hideCap(model,hair)
		face(model,rgb(80,60,40),hair)
		hairCap(model,hair)
		for _,s in {{Vector3.new(-.4,.8,-.3),Vector3.new(-.5,1.3,-.4)},{Vector3.new(0,.9,-.3),Vector3.new(0,1.4,-.4)},{Vector3.new(.4,.8,-.3),Vector3.new(.5,1.3,-.4)},
			{Vector3.new(-.3,.8,.3),Vector3.new(-.4,1.2,.5)},{Vector3.new(.3,.8,.3),Vector3.new(.4,1.2,.5)}} do
			spike(model,s[1],s[2],.45,.42,.36,hair)
		end
		paint(model,TORSO,ochre);paint(model,ARMS,ochre);paint(model,LEGS,dark)
		wear(model,"UpperTorso","Tunic",Vector3.new(2.08,1.62,1.12),CFrame.new(0,-.02,0),ochre)
		wear(model,"UpperTorso","Collar",Vector3.new(1.4,.26,1.14),CFrame.new(0,.82,.02),rgb(140,104,54))
		wear(model,"LowerTorso","Belt",Vector3.new(2.04,.22,1.06),CFrame.new(0,.34,0),rgb(60,46,30))
		wear(model,"LowerTorso","ShurikenPouch",Vector3.new(.5,.4,.4),CFrame.new(.9,.1,.5),rgb(70,60,46))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Bandage",Vector3.new(.66,.9,.66),CFrame.new(0,-.04,0),rgb(232,226,210))
		end
		sandals(model,def,rgb(50,42,34))
	end
end
return Kit
