-- Roster 20, batch 3 (Deidara, Sasori, Nagato, Killer Bee): the batch's
-- server side. Their techniques run on the shared families; this module
-- dresses them.
local Base=require(script.Parent.Wave1Kit)
local paint,ARMS,LEGS,TORSO=Base.paint,Base.ARMS,Base.LEGS,Base.TORSO
local Kit={}
-- Sasori's puppet: a persistent body (Server/Bodies) on chakra threads. It
-- holds a spot between him and the opponent, off the line, and strikes on
-- its own rhythm (a poisoned blade); his heavy-after-one and his rising
-- strike are carried out by it when it is out (MoveGraphs proxy); cast again,
-- it lunges at the body. One clean blow breaks it (Bodies): then he is a
-- slow lasher with no bodyguard until he makes another.
function Kit.install(Techniques)
	local Bodies=require(script.Parent.Bodies)
	local Families=require(script.Parent.Families)
	local function flat(v) return Vector3.new(v.X,0,v.Z) end
	local function strike(c,body,b,spec)
		local tune=Bodies.tuning(body.owner,body.kind)
		body.state="Startup";body.action="PuppetJab";body.variant=nil;body.actionAt=c.now;body.actionSerial+=1
		body.pendingStrike=spec or {damage=tune.Damage or 4,reach=(tune.Reach or 5.2),reaction="HitStun",push=10,up=3,stun=.34,tag="Puppet",poison=tune.Poison}
	end
	Bodies.controllers.marionette=function(c,body,dt)
		local a=body.owner
		local b=a.target
		if not b or b.health<=0 then return end
		local tune=Bodies.tuning(a,body.kind)
		-- A strike already thrown: its contact on its own timing.
		if body.state=="Startup" and c.now>=body.actionAt+.18 then
			body.state="Active"
			local s=body.pendingStrike or {}
			if Bodies.hitFrom(c,body,b,{damage=s.damage,reach=s.reach,height=6,arc=-.2,reaction=s.reaction,push=s.push,up=s.up,stun=s.stun,tag=s.tag}) then
				if s.poison then Families.poison(c,a,b,s.poison) end
				require(script.Parent.Brawler).event(c,a,"PuppetHit")
			end
		elseif body.state=="Active" and c.now>=body.actionAt+.3 then body.state="Recovery"
		elseif body.state=="Recovery" and c.now>=body.actionAt+.55 then body.state="Neutral" end
		local goal,speed
		if body.lunge then
			-- Lunge: straight at the body, the blade on arrival.
			local line=flat(body.position-b.root.Position)
			line=if line.Magnitude>.1 then line.Unit else flat(-b.root.CFrame.LookVector).Unit
			goal=b.root.Position+line*2.4;speed=78
			if flat(body.position-goal).Magnitude<1.2 and body.state=="Neutral" then
				local l=body.lunge;body.lunge=nil
				strike(c,body,b,{damage=l.Damage or 7,reach=5,reaction="Knockback",push=l.Knock or 26,up=l.Lift or 8,stun=.45,tag="Puppet Lunge",poison=l.Poison})
				body.nextStrike=c.now+(tune.Every or 2.2)
			end
		else
			-- Its post: between the two of them, off the line, at blade's reach.
			local line=flat(a.root.Position-b.root.Position)
			line=if line.Magnitude>.1 then line.Unit else flat(-b.root.CFrame.LookVector).Unit
			local around=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(40*body.side)):VectorToWorldSpace(line)
			goal=b.root.Position+around*(tune.Hold or 4.4)
			-- On a short leash: far from him, it comes back to his side.
			if flat(a.root.Position-b.root.Position).Magnitude>(tune.Leash or 34) then goal=a.root.Position+line:Cross(Vector3.yAxis)*body.side*3 end
			speed=tune.Speed or 30
			if body.state=="Neutral" and c.now>=body.nextStrike and flat(b.root.Position-body.position).Magnitude<=(tune.Reach or 5.2)+.6 then
				strike(c,body,b)
				body.nextStrike=c.now+(tune.Every or 2.2)
			end
		end
		goal=Vector3.new(goal.X,c.match.origin.Y+3,goal.Z)
		Bodies.move(c,body,goal,speed,dt)
		Bodies.face(body,b.root.Position)
	end
end
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

	-- Deidara (15): long blond hair in a high half-ponytail, a long fringe over
	-- the left eye with the scope, Iwa's flak vest over dark clothes, clay
	-- pouches at both hips.
	dressers.Deidara=function(model,def)
		local hair=rgb(240,210,110)
		local dark=rgb(60,64,80)
		local vest=rgb(140,120,96)
		hideCap(model,hair)
		face(model,rgb(70,110,170),hair)
		hairCap(model,hair)
		wear(model,"Head","Fringe",Vector3.new(.9,1.1,.24),CFrame.new(-.4,.0,-.76)*A(0,0,R(-6)),hair)
		wear(model,"Head","Topknot",Vector3.new(.5,.5,.5),CFrame.new(0,.8,.5),hair)
		wear(model,"Head","Tail",Vector3.new(.5,1.6,.4),CFrame.new(0,-.2,.9)*A(R(-10),0,0),hair)
		for _,side in {-1,1} do wear(model,"Head","SideHair",Vector3.new(.22,1.6,.9),CFrame.new(side*.84,-.4,.2),hair) end
		wear(model,"Head","Scope",Vector3.new(.3,.3,.3),CFrame.new(.62,.18,-.7),rgb(80,90,96),Enum.Material.Metal)
		headband(model)
		paint(model,TORSO,dark);paint(model,ARMS,dark);paint(model,LEGS,dark)
		wear(model,"UpperTorso","Vest",Vector3.new(2.1,1.6,1.14),CFrame.new(0,-.02,0),vest)
		wear(model,"UpperTorso","Collar",Vector3.new(1.5,.3,1.16),CFrame.new(0,.8,.02),rgb(120,100,80))
		wear(model,"LowerTorso","Belt",Vector3.new(2.06,.22,1.06),CFrame.new(0,.34,0),rgb(40,36,30))
		for _,x in {-1.05,1.05} do wear(model,"LowerTorso","ClayPouch",Vector3.new(.36,.5,.6),CFrame.new(x,.1,0),rgb(160,130,90)) end
		-- The mouth on the right palm (a dark slit).
		wear(model,"RightHand","PalmMouth",Vector3.new(.3,.06,.02),CFrame.new(0,-.1,-.32),rgb(120,40,40))
		sandals(model,def,rgb(40,40,48))
	end

	-- Sasori (14): short, untidy red hair, a calm young face, a long sand-
	-- coloured cloak with a red scarf; the thread spools at his fingers and a
	-- folded puppet on his back.
	dressers.Sasori=function(model,def)
		local hair=rgb(176,60,50)
		local cloak=rgb(170,150,120)
		local shade=rgb(130,112,90)
		hideCap(model,hair)
		face(model,rgb(120,70,50),hair)
		hairCap(model,hair)
		for _,s in {{Vector3.new(-.4,.7,-.4),Vector3.new(-.5,.6,-.8)},{Vector3.new(.4,.7,-.4),Vector3.new(.5,.6,-.8)},{Vector3.new(0,.8,0),Vector3.new(0,1,-.2)},{Vector3.new(0,.6,.6),Vector3.new(0,.4,1)}} do
			spike(model,s[1],s[2],.6,.46,.4,hair)
		end
		paint(model,TORSO,cloak);paint(model,ARMS,cloak);paint(model,LEGS,shade)
		wear(model,"UpperTorso","Cloak",Vector3.new(2.16,1.8,1.2),CFrame.new(0,-.06,0),cloak)
		wear(model,"UpperTorso","Scarf",Vector3.new(1.5,.4,1.2),CFrame.new(0,.8,0),rgb(170,40,40))
		wear(model,"LowerTorso","CloakSkirt",Vector3.new(2.2,1.3,1.22),CFrame.new(0,-.6,0),cloak)
		-- The folded puppet on his back: a wooden torso, limbs folded on it.
		wear(model,"UpperTorso","PuppetBack",Vector3.new(1.4,1.7,.5),CFrame.new(0,0,.86),rgb(150,110,74),Enum.Material.Wood)
		wear(model,"UpperTorso","PuppetHead",Vector3.new(.7,.7,.5),CFrame.new(0,1.1,.86),rgb(150,110,74),Enum.Material.Wood)
		for _,side in {"Left","Right"} do
			wear(model,side.."Hand","ThreadRing",Vector3.new(.5,.12,.5),CFrame.new(0,-.2,0),rgb(140,190,240),Enum.Material.Neon)
		end
		sandals(model,def,rgb(80,60,50))
	end

	-- Nagato (12): red hair falling over one eye, thin, a plain dark long
	-- shirt and light trousers; the Rinnegan's ringed eyes.
	dressers.Nagato=function(model,def)
		local hair=rgb(170,40,40)
		hideCap(model,hair)
		face(model,rgb(186,170,220),hair)
		for _,p in model:GetChildren() do
			if p.Name=="Iris" then p.Material=Enum.Material.Neon;p.Transparency=.3;p.Color=rgb(196,176,236) end
		end
		hairCap(model,hair)
		wear(model,"Head","Fringe",Vector3.new(1.0,1.2,.26),CFrame.new(.3,-.06,-.76)*A(0,0,R(8)),hair)
		for _,side in {-1,1} do wear(model,"Head","SideHair",Vector3.new(.22,1.4,1.0),CFrame.new(side*.84,-.3,.1),hair) end
		wear(model,"Head","BackHair",Vector3.new(1.6,1.3,.3),CFrame.new(0,-.3,.74),hair)
		paint(model,TORSO,rgb(60,60,70));paint(model,ARMS,rgb(60,60,70));paint(model,LEGS,rgb(170,166,156))
		wear(model,"UpperTorso","Shirt",Vector3.new(2.06,1.66,1.1),CFrame.new(0,-.02,0),rgb(60,60,70))
		wear(model,"LowerTorso","ShirtHem",Vector3.new(2.1,.7,1.12),CFrame.new(0,-.3,0),rgb(60,60,70))
		wear(model,"UpperTorso","Collar",Vector3.new(1.3,.26,1.12),CFrame.new(0,.82,0),rgb(48,48,56))
		for _,side in {"Left","Right"} do
			wear(model,side.."LowerArm","Bandage",Vector3.new(.86,.5,.86),CFrame.new(0,-.2,0),rgb(220,216,206))
			wear(model,side.."LowerLeg","Wrap",Vector3.new(.86,.5,.86),CFrame.new(0,-.2,0),rgb(220,216,206))
		end
		sandals(model,def,rgb(60,56,52))
	end

	-- Killer Bee (14): white hair cropped short, dark skin, sunglasses, a
	-- white scarf, Kumo's vest worn open, the tattoo on the cheek, a big build.
	dressers["Killer Bee"]=function(model,def)
		local hair=rgb(236,236,230)
		local vest=rgb(200,192,170)
		hideCap(model,hair)
		face(model,rgb(30,30,30),hair)
		hairCap(model,hair)
		wear(model,"Head","Shades",Vector3.new(1.3,.22,.06),CFrame.new(0,.12,-.85),rgb(20,20,24),Enum.Material.Glass)
		wear(model,"Head","Tattoo",Vector3.new(.06,.3,.3),CFrame.new(-.82,-.1,-.3),rgb(40,30,24))
		wear(model,"Head","Headband",Vector3.new(1.66,.24,1.66),CFrame.new(0,.4,0),rgb(40,40,48))
		wear(model,"Head","HeadbandPlate",Vector3.new(.86,.3,.06),CFrame.new(0,.4,-.85),rgb(176,184,194),Enum.Material.Metal)
		paint(model,TORSO,rgb(70,76,60));paint(model,ARMS,Color3.fromRGB(table.unpack(def.Skin)));paint(model,LEGS,rgb(70,76,60))
		wear(model,"UpperTorso","Vest",Vector3.new(2.2,1.7,1.2),CFrame.new(0,-.02,0),vest)
		wear(model,"UpperTorso","Scarf",Vector3.new(1.6,.4,1.24),CFrame.new(0,.82,0),rgb(240,240,236))
		wear(model,"LowerTorso","Belt",Vector3.new(2.1,.26,1.1),CFrame.new(0,.34,0),rgb(40,36,30))
		for _,side in {"Left","Right"} do
			wear(model,side.."UpperArm","Bulk",Vector3.new(1.1,1.0,1.1),CFrame.new(0,0,0),Color3.fromRGB(table.unpack(def.Skin)))
			wear(model,side.."LowerArm","Band",Vector3.new(.9,.3,.9),CFrame.new(0,-.36,0),rgb(240,240,236))
		end
		sandals(model,def,rgb(40,40,40))
	end
end
return Kit
