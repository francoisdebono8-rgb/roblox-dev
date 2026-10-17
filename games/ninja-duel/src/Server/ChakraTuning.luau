-- Live chakra interaction data (SYS-001 / TOOL-006): OBJECT + CHAKRA + NATURE /
-- MASTERY + CONTEXT -> a modified action. Same format as Codex's prepared
-- fixtures (7091585) and validated by ChakraRules at load; ChakraCombat is the
-- only reader. Character ids only select a mastery profile: one interpreter,
-- different identities. Stats are scales on the fighter's own ToolMastery
-- (speed, range, damage) or absolute contest values (weight, impact, contest).
local T={Enabled=true,MaxObjects=64,MaxSurfaces=32,MaxEvents=256,MaxLife=30,MaxSpeed=400,MaxChakra=1000,
	Triggers={Infuse=true,ProjectileClash=true,SurfaceHit=true,Contact=true,PointContact=true,WireContact=true,WireCross=true},
	Tags={tool=true,projectile=true,metal=true,blade=true,wire=true,sand=true,body=true,volume=true,actor=true,
		solid=true,wall=true,floor=true,anchorCompatible=true,
		chakra=true,reinforced=true,cutting=true,conductive=true,ignited=true,shockPoint=true,charged=true,
		wind=true,fire=true,lightning=true,earth=true,marked=true,
		guarding=true,bound=true,wired=true,airborne=true,holdingWire=true,
		clean=true,guarded=true,heavier=true,even=true,natureAdvantage=true,plain=true,owner=true,opponent=true,grounded=true,own=true},
	Natures={Wind={tag="wind"},Fire={tag="fire"},Lightning={tag="lightning"},Earth={tag="earth"}},
	-- Elemental precedence between natured objects (fire feeds on wind, wind
	-- cuts lightning, lightning breaks earth). Anything else is decided by weight.
	Beats={Fire="Wind",Wind="Lightning",Lightning="Earth"},
	Properties={Marked={tag="marked",requires={"tool"}}},
	MasterySkills={Wind=true,Fire=true,Lightning=true,GentleFist=true,Seal=true},
	Masteries={
		Basic={tags={},levels={Wind=0,Fire=0,Lightning=0,GentleFist=0,Seal=0}},
		-- Minato: wind through the kunai, seals in the hand.
		WindBlade={tags={"wind"},levels={Wind=3,Fire=0,Lightning=0,GentleFist=0,Seal=3}},
		-- Itachi: Katon carried by precise shuriken.
		FireBlade={tags={"fire"},levels={Wind=0,Fire=3,Lightning=0,GentleFist=0,Seal=0}},
		-- Neji: chakra goes through the body, never into a thrown blade.
		GentleFist={tags={"body"},levels={Wind=0,Fire=0,Lightning=0,GentleFist=3,Seal=0}},
		-- Sasuke: lightning in steel and wire (fire stays in his jutsu).
		LightningWire={tags={"lightning","wire"},levels={Wind=0,Fire=2,Lightning=3,GentleFist=0,Seal=0}},
	},
	CharacterMastery={Flashstep="WindBlade",Mirage="FireBlade",GentleFist="GentleFist",Lion="LightningWire",Sand="Basic"},
	-- What the chakra modifier pours into each tool, per mastery (Basic: plain
	-- reinforcement). A body mastery turns the tool action into a palm.
	Preferred={
		Basic={Kunai="Reinforce",Shuriken="Reinforce",Sand="Reinforce",Palm="GentleFist"},
		WindBlade={Kunai="Wind",Shuriken="Wind"},
		FireBlade={Shuriken="Fire",Kunai="Fire"},
		GentleFist={Palm="GentleFist"},
		LightningWire={Shuriken="Lightning",Kunai="Lightning"},
	},
	BodyTool={GentleFist="Palm"},
	-- Projectile kinds as interaction objects. Volumes are jutsu bodies: they
	-- take part in clashes with their real radius.
	ObjectOf={kunai="Kunai",marked="Marked",shuriken="Shuriken",wire="Wire",sand="Sand",
		fireball="Fireball",phoenix="Phoenix",palm="VacuumPalm",wind="WindCut",sandwave="SandWave"},
	Objects={},Surfaces={},Infusions={},Rules={},
}
-- Rock Lee (stress-test wave): he cannot mould chakra at all, so there is
-- nothing to pour into a tool and no palm either. His tool is a kick
-- (Techniques.deflectKick) and the chakra modifier is refused with the usual
-- fizzle (Combat, def.Tool "Deflect"). Named here so every reader of the
-- profile (logs, lab, tools) says Taijutsu instead of falling back to Basic.
T.Masteries.Taijutsu={tags={"body"},levels={Wind=0,Fire=0,Lightning=0,GentleFist=0,Seal=0}}
T.CharacterMastery.Leaf="Taijutsu"
T.Preferred.Taijutsu={}
-- Naruto (roster wave): no nature yet (his wind is Part II). His chakra goes
-- into a body, not into the steel: the chord turns the thrown kunai into a
-- shadow clone near the target (ToolMastery.Transform, Server/Bodies). With
-- two clones already out, the same chord only reinforces the kunai.
T.Masteries.ShadowClone={tags={},levels={Wind=0,Fire=0,Lightning=0,GentleFist=0,Seal=0}}
T.CharacterMastery.Legion="ShadowClone"
T.Preferred.ShadowClone={Kunai="Reinforce"}
local O=T.Objects
local function tool(toolType,tags,infusions,weight,impact,contest,visual)
	return {toolType=toolType,tags=tags,canLaunch=true,infusions=infusions,
		stats={speed=1,range=1,damage=1,weight=weight,impact=impact},
		caps={speed=2,range=2,damage=2,weight=8,impact=4},radius=contest,visual=visual}
end
local steel={Reinforce=true,Wind=true,Fire=true,Lightning=true}
O.Kunai=tool("Kunai",{"tool","projectile","metal","blade"},steel,2,1,.45,"kunai")
O.Marked=tool("Kunai",{"tool","projectile","metal","blade","marked"},{},2,1,.45,"kunai")
O.Shuriken=tool("Shuriken",{"tool","projectile","metal","blade"},steel,1.5,.6,.5,"shuriken")
O.Wire=tool("Wire",{"tool","projectile","metal","wire"},{},1.5,.5,.5,"wire")
O.Sand=tool("Sand",{"tool","projectile","sand","earth"},{Reinforce=true},2,1,.6,"target")
O.Palm={toolType="Palm",tags={"body"},canLaunch=false,infusions={GentleFist=true},stats={damage=1,weight=6,impact=1},caps={damage=2,weight=8,impact=4},radius=1,visual="target"}
local function volume(tags,weight)
	return {toolType="Volume",tags=tags,canLaunch=true,infusions={},stats={weight=weight},caps={weight=8},radius=1,visual="target"}
end
O.Fireball=volume({"projectile","volume","fire"},6)
O.Phoenix=volume({"projectile","volume","fire"},2.5)
O.VacuumPalm=volume({"projectile","volume","body"},5)
O.WindCut=volume({"projectile","volume","wind","cutting"},4)
O.SandWave=volume({"projectile","volume","sand","earth"},6)
T.Surfaces.Wall={tags={"solid","wall","anchorCompatible"},normal={x=-1,y=0,z=0},radius=8}
T.Surfaces.Floor={tags={"solid","floor","anchorCompatible"},normal={x=0,y=1,z=0},radius=8}
-- Every chakra blade is reinforced steel; a mastered nature adds its own rule.
T.Infusions.Reinforce={tags={"chakra","reinforced"},cost=6}
T.Infusions.Wind={nature="Wind",tags={"chakra","reinforced","cutting"},cost=8}
T.Infusions.Fire={nature="Fire",tags={"chakra","reinforced"},cost=8}
T.Infusions.Lightning={nature="Lightning",tags={"chakra","reinforced","conductive"},cost=8}
T.Infusions.GentleFist={tags={"chakra","body"},cost=10}
-- Magnitudes of the signals the rules select (read by ChakraCombat only).
T.Effects={
	toolCost=true, -- a thrown chakra tool also pays the plain throw cost (free in a string cancel)
	contestBonus=.45, -- a chakra blade meets other projectiles from further away
	hitRadius=.25, -- and connects with a body through a small sphere ("stronger contact")
	guardCrush={stamina=14,push=1.1,stun=.45},
	shock={stun=.38,damage=1},
	wireSurge={damage=3,bind=.45},
	ignite={radius=2.2,duration=1.0,damage=3},
	burnPoint={radius=2.6,duration=2.0,damage=4},
	gust={push=20,lift=6,chase=.6},
	plant={life=5,max=4,refund=4,radius=2.4,height=4.5,settle=.5,contest=.9},
	shockPoint={stun=.4,damage=3},
	palm={damage=.6,travel=2.2,reach=8.5,cone=.3,drain=8,stamina=18,points=1,push=1.6},
	conduct={damage=5,bind=.4,maxBind=2.2,uses=2},
	tripwire={life=6,radius=2.7,shock=4,bind=.4,charge=4,burn=1.4,patch=4},
	feed={damage=1.5},
}
local function rule(id,trigger,priority,when,effects,extra)
	local r={id=id,enabled=true,priority=priority,trigger=trigger,when=when,effects=effects}
	for k,v in extra or {} do r[k]=v end
	table.insert(T.Rules,r)
end
local function scale(stat,factor,extra)
	local e={kind="scaleStat",stat=stat,factor=factor}
	for k,v in extra or {} do e[k]=v end
	return e
end
local function signal(name) return {kind="signal",name=name} end
-- Infuse: how the chakra changes the object itself (stats are scales).
rule("reinforced-steel","Infuse",20,{source={all={"tool","reinforced"}}},
	{scale("weight",2),scale("impact",1.8),scale("range",1.15),scale("damage",1.25)})
rule("wind-blade","Infuse",30,{source={all={"blade","wind"}}},
	{scale("speed",1.3,{mastery="Wind",perLevel=.05,maxFactor=1.5}),scale("range",1.5),scale("weight",.8)})
rule("fire-blade","Infuse",30,{source={all={"blade","fire"}}},
	{scale("speed",1.05),{kind="tag",tag="ignited",target="source"}})
rule("lightning-steel","Infuse",30,{source={all={"metal","lightning"}}},
	{scale("speed",1.1),{kind="tag",tag="conductive",target="source"}})
rule("sand-reinforced","Infuse",30,{source={all={"sand","reinforced"}}},{scale("weight",1.2)})
-- With the wire still on a bound opponent, Sasuke's lightning runs down it.
rule("lightning-down-the-wire","Infuse",60,{source={all={"lightning"}},context={all={"holdingWire"}}},{signal("conduct-wire")})
rule("gentle-palm","Infuse",40,{source={all={"body","chakra"}}},{signal("chakra-palm")})
-- ProjectileClash: one exclusive outcome per meeting, from the dominant side.
rule("plain-pass","ProjectileClash",100,{context={all={"plain"}}},{signal("clash-pass")},{group="clash"})
-- Two jutsu never cancel each other: matchups between techniques stay as they are.
rule("volumes-pass","ProjectileClash",99,{source={all={"volume"}},target={all={"volume"}}},{signal("clash-pass")},{group="clash"})
rule("fire-feeds-on-wind","ProjectileClash",95,{source={all={"fire"}},target={all={"wind"}},context={all={"natureAdvantage"}}},{signal("clash-absorb")},{group="clash"})
rule("element-overpowers","ProjectileClash",90,{context={all={"natureAdvantage"}}},{signal("clash-pierce")},{group="clash"})
-- Neji's chakra palm swats the blades in front of it (it never meets a jutsu).
rule("palm-swats-blades","ProjectileClash",85,{source={all={"body","chakra"}},target={all={"tool"}}},{signal("clash-swat")},{group="clash"})
rule("volume-swallows-tool","ProjectileClash",80,{source={all={"volume"}},target={all={"tool"}}},{signal("clash-swallow")},{group="clash"})
-- A reinforced blade heavier than a small flame (Phoenix Flower) goes through it.
rule("heavy-steel-pierces-flame","ProjectileClash",78,{source={all={"tool","reinforced"}},target={all={"volume"}},context={all={"heavier"}}},{signal("clash-pierce")},{group="clash"})
rule("wind-cuts-the-lane","ProjectileClash",70,{source={all={"cutting","tool"}},target={all={"tool"}},context={any={"heavier","even"}}},{signal("clash-pierce")},{group="clash"})
rule("heavier-deflects","ProjectileClash",50,{context={all={"heavier"}}},{signal("clash-deflect")},{group="clash"})
rule("even-intercept","ProjectileClash",10,{},{signal("clash-intercept")},{group="clash"})
-- Contact: what the infused object does to the body it reaches.
rule("reinforced-guard-crush","Contact",50,{source={all={"reinforced"}},target={all={"guarding"}}},{signal("guard-crush")})
rule("lightning-wire-surge","Contact",45,{source={all={"lightning"}},target={all={"wired"}}},{signal("wire-surge")})
rule("lightning-shock","Contact",40,{source={all={"lightning"}},context={all={"clean"}}},{signal("shock")})
rule("fire-ignites","Contact",40,{source={all={"fire","tool"}},context={all={"clean"}}},{signal("ignite")})
rule("wind-gust","Contact",40,{source={all={"wind","tool"}},context={all={"clean"}}},{signal("gust")})
rule("gentle-palm-through-guard","Contact",50,{source={all={"body","chakra"}},target={all={"guarding"}}},{signal("palm-through-guard")})
rule("gentle-palm-point","Contact",40,{source={all={"body","chakra"}},context={all={"clean"}}},{signal("palm-point")})
-- SurfaceHit: a chakra blade stays planted; natures leave their mark.
rule("chakra-blade-plants","SurfaceHit",50,{source={all={"chakra","blade"}},surface={all={"anchorCompatible"}}},{{kind="embed",target="source"}})
rule("lightning-shock-point","SurfaceHit",45,{source={all={"lightning","blade"}}},{{kind="tag",tag="shockPoint",target="source"}})
rule("fire-burn-point","SurfaceHit",40,{source={all={"fire","tool"}}},{signal("burn-point")})
rule("wire-stretches","SurfaceHit",60,{source={all={"wire"}},surface={all={"anchorCompatible"}}},{signal("wire-stretch")})
-- PointContact: a planted chakra blade is a contestable point.
rule("owner-recovers","PointContact",50,{context={all={"owner","grounded"}}},{signal("point-recover")},{group="point"})
rule("shock-point-trap","PointContact",60,{source={all={"shockPoint"}},context={all={"opponent","grounded"}}},{signal("point-shock")},{group="point"})
rule("opponent-tramples","PointContact",10,{context={all={"opponent","grounded"}}},{signal("point-deny")},{group="point"})
-- Wire: a stretched wire binds on contact, carries fire, conducts lightning.
rule("tripwire-binds","WireContact",50,{context={all={"opponent","grounded"}}},{signal("tripwire-bind")})
rule("charged-wire-shocks","WireContact",60,{source={all={"charged"}},context={all={"opponent","grounded"}}},{signal("tripwire-shock")})
rule("fire-runs-the-wire","WireCross",60,{source={all={"fire"}}},{signal("wire-burn")},{group="wire"})
rule("lightning-charges-wire","WireCross",50,{source={all={"lightning"}},context={all={"own"}}},{signal("wire-charge")},{group="wire"})
rule("wind-cuts-wire","WireCross",40,{source={all={"cutting"}}},{signal("wire-cut")},{group="wire"})
return T
