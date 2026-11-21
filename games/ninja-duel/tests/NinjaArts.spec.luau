-- The ninja's tree in a duel (21/11, DEC-045, step 2): what def.Ninja changes
-- in the real Combat/Brawler/Motor. The five natures on the kunai and the
-- blade (once every 4 s, each with its answer), the explosive tag, the smoke
-- bomb, and the three mobility nodes. Headless: the look and the feel stay
-- for Studio (the ANIMATEUR draws Infusion.<Nature>).
local H=require("./Harness")
local V=H.V
local N=H.load("Shared/NinjaTree")
local SkillBuilds=H.load("Server/SkillBuilds")
local NinjaArts=H.load("Server/NinjaArts")
local Families=H.load("Server/Families")
local Brawler=H.load("Server/Brawler")
local Config=H.load("Shared/Config")
local passed=0
local function test(name,fn)
	H.clearWalls()
	local ok,err=pcall(fn)
	H.clearWalls()
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
-- A player's kit with his ninja's tree: the nodes learned and on, in order.
local function ninja(fighter,nodes)
	local r=N.new()
	for _,id in nodes do N.learn(r,id,200) end
	local kit=assert(SkillBuilds.build(fighter,{}))
	kit.def.Ninja=N.def(r)
	return kit
end
local function duel(fighter,nodes,gap,other)
	local c,a,b=H.duel(fighter,other or "Mirage",{A=if nodes then ninja(fighter,nodes) else nil})
	gap=gap or 20
	c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
	a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position);b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
	c.damageLog={}
	return c,a,b
end
local function damage(c,tag)
	local n=0
	for _,entry in c.damageLog do if entry.tag==tag then n+=entry.amount end end
	return n
end
local function throw(c,a,b)
	local before=#c.projectiles
	assert(c:request(a,"Tool",b.root.Position),"the throw was refused")
	for _=1,30 do H.step(c,.01);if #c.projectiles>before then break end end
	local p=c.projectiles[#c.projectiles]
	assert(p and p.a==a,"no blade left his hand")
	return p
end
local scale=Config.DamageScale or 1
-- The harness's rays see floors and walls, not bodies: a thin blade's contact
-- with the body is played as the flight step would (Combat:projectileHit).
local function land(c,p,b)
	c:removeProjectile(p)
	c:projectileHit(p,b,b.root.Position,-p.direction)
end

test("the thrown blade carries his nature; Wind flies further and faster; nothing without the tree",function()
	local c,a,b=duel("Legion",{"NatureWind","InfusedKunai"})
	local p=throw(c,a,b)
	assert(p.ninja=="Wind","the blade carries "..tostring(p.ninja))
	local c2,a2,b2=duel("Legion",nil)
	local plain=throw(c2,a2,b2)
	assert(plain.ninja==nil and plain.tag==nil,"a blade without a tree carries something")
	assert(math.abs(p.speed/plain.speed-1.2)<.01 and math.abs(p.range/plain.range-1.2)<.01,
		string.format("the wind blade: speed x%.2f, range x%.2f",p.speed/plain.speed,p.range/plain.range))
	-- Mastered, the effect is half again as strong (x1.3 here).
	local c3,a3,b3=duel("Legion",{"NatureWind","InfusedKunai","InfusedBlade","ElementMastery"})
	local strong=throw(c3,a3,b3)
	assert(math.abs(strong.range/plain.range-1.3)<.01,"mastery: range x"..strong.range/plain.range)
	-- The duel's snapshot reads it (Matches: the fighter's ninja, the projectile's).
	local view=NinjaArts.view(c,a)
	assert(view and view.nature=="Wind" and view.kunai and not view.blade,"the fighter's view")
	assert(NinjaArts.view(c2,a2)==nil,"a fighter without the tree has a view")
end)

test("Fire: an infused kunai burns 3 over 2 s, once every 4 s; a raised guard puts the flames out",function()
	local c,a,b=duel("Legion",{"NatureFire","InfusedKunai"})
	land(c,throw(c,a,b),b)
	H.step(c,2.4)
	local burnt=damage(c,"burn")
	assert(math.abs(burnt-3*scale)<.01,string.format("burnt %.2f, want %.2f",burnt,3*scale))
	assert(a.infusionUntil and a.infusionUntil>c.now,"no gap after the infusion")
	-- Within the gap a second blade does not burn.
	c.damageLog={}
	a.neutralToolAt=0;a.chakra=100
	land(c,throw(c,a,b),b);H.step(c,1.2)
	assert(damage(c,"burn")==0,"a second burn inside the 4 s")
	-- Past it, it burns again; the guard raised in the flames puts them out.
	H.step(c,1);c.damageLog={};a.neutralToolAt=0;a.chakra=100
	assert(c.now>=a.infusionUntil,"the gap outlived itself")
	NinjaArts.hit(c,a,b,"kunai",true,false)
	H.step(c,.55)
	local first=damage(c,"burn")
	assert(first>0,"the burn did not start")
	b.guardHeld=true
	H.step(c,2)
	assert(damage(c,"burn")==first,"the guard did not put the flames out")
	-- A guarded blade does not burn at all.
	b.guardHeld=false;a.infusionUntil=0
	assert(NinjaArts.hit(c,a,b,"kunai",true,true)==nil,"a guarded blade burns")
end)

test("Lightning holds the body a beat; Earth cracks the guard (and breaks a tired one); Water slows, the substitution washes it",function()
	local c,a,b=duel("Legion",{"NatureLightning","InfusedKunai","InfusedBlade"},4)
	-- The blade: the reaction it gives is held 0.25 s longer (Brawler.react's floor).
	assert(NinjaArts.hit(c,a,b,"blade",true,false,.3)=="Lightning")
	assert(math.abs(b.stunFloorUntil-(c.now+.55))<.001,"the stun floor")
	assert(b.shockUntil>c.now,"the client sees no shock")
	assert(NinjaArts.hit(c,a,b,"blade",true,false,.3)==nil,"twice inside the 4 s")
	-- A kunai on a stunned body: its stun runs 0.25 s longer.
	a.infusionUntil=0;b.stunFloorUntil=nil
	c:setState(b,"Stunned",.2)
	local untilBefore=b.untilTime
	NinjaArts.hit(c,a,b,"kunai",true,false)
	assert(math.abs(b.untilTime-untilBefore-.25)<.001,"the kunai's paralysis")
	-- Earth: nothing on an open body, 10 more on a guard, a spent guard breaks.
	local c2,a2,b2=duel("Legion",{"NatureEarth","InfusedKunai"},4)
	assert(NinjaArts.hit(c2,a2,b2,"kunai",true,false)==nil,"Earth on an open body")
	b2.stamina=25;b2.guardHeld=true;b2.state="Guarding"
	assert(NinjaArts.hit(c2,a2,b2,"kunai",true,true)=="Earth" and b2.stamina==15 and b2.guardHeld,"the cracked guard")
	a2.infusionUntil=0;b2.stamina=8
	NinjaArts.hit(c2,a2,b2,"kunai",true,true)
	assert(b2.state=="Stunned" and not b2.guardHeld,"a guard with nothing left did not break")
	-- A dodge avoids it whole: an evaded blade did not land.
	a2.infusionUntil=0
	assert(NinjaArts.hit(c2,a2,b2,"kunai",false,false)==nil,"Earth through a dodge")
	-- Water: 15 % slower for 1.5 s; mastered 22.5 %; a substitution washes it off.
	local c3,a3,b3=duel("Legion",{"NatureWater","InfusedKunai"},4)
	NinjaArts.hit(c3,a3,b3,"kunai",true,false)
	assert(math.abs(Families.speedScale(b3,c3.now)-.85)<.001,"the slow")
	H.step(c3,1.6)
	assert(Families.speedScale(b3,c3.now)==1,"the slow outlived 1.5 s")
	a3.infusionUntil=0
	NinjaArts.hit(c3,a3,b3,"kunai",true,false)
	b3.lastHurt=c3.now;b3.state="Stunned";b3.untilTime=c3.now+.3
	assert(c3:substitute(b3),"the substitution was refused")
	assert(Families.speedScale(b3,c3.now)==1,"the substitution did not wash the water off")
	local c4,a4,b4=duel("Legion",{"NatureWater","InfusedKunai","InfusedBlade","ElementMastery"},4)
	NinjaArts.hit(c4,a4,b4,"kunai",true,false)
	assert(math.abs(Families.speedScale(b4,c4.now)-.775)<.001,"the mastered slow")
	-- Wind on the blade: the strike's push, 20 % further.
	local c5,a5=duel("Legion",{"NatureWind","InfusedKunai","InfusedBlade"},4)
	local pushed=NinjaArts.gust(a5,V.new(0,10,40))
	assert(math.abs(pushed.Z-48)<.001 and pushed.Y==10,"the wind blade's push")
	local _=c5
	-- The infused kunai is only the kunai's: without the node, the blade does nothing.
	local c6,a6,b6=duel("Legion",{"NatureFire","InfusedKunai"},4)
	assert(NinjaArts.hit(c6,a6,b6,"blade",true,false,.3)==nil,"the blade burns without its node")
end)

test("the end of the basic string carries the nature in a real string (Brawler.hit, Light3)",function()
	local c,a,b=duel("Legion",{"NatureFire","InfusedKunai","InfusedBlade"},4)
	local burnt=false
	for _=1,8 do
		c:request(a,"Attack")
		for _=1,40 do H.step(c,.01) end
		c:relocate(a,b.root.Position+V.new(0,0,3.6))
		a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
		if (a.infusionUntil or 0)>c.now then burnt=true;break end
	end
	assert(burnt,"no hit of the string carried the fire")
	H.step(c,2.2)
	assert(damage(c,"burn")>0,"the blade's fire did no damage")
end)

test("the explosive tag: on a thrown blade once every 8 s, it blows 1 s after it lands; out of reach, nothing",function()
	local c,a,b=duel("Legion",{"ExplosiveTag"},20)
	local p=throw(c,a,b)
	assert(p.tag==true,"the first blade carries no tag")
	a.neutralToolAt=0;a.chakra=100
	H.step(c,.8)
	local second=throw(c,a,b)
	assert(not second.tag,"a tag inside the 8 s")
	-- A tag where the body stands blows 1 s later.
	local health=b.health
	c.damageLog={}
	NinjaArts.tagEnd(c,{a=a,tag=true},b.root.Position)
	H.step(c,.5)
	assert(damage(c,"charge")==0,"it blew before its second")
	H.step(c,.6)
	assert(damage(c,"charge")>0 and b.health<health,"the tag did not blow under him")
	-- Stepped out of it: nothing.
	c.damageLog={}
	NinjaArts.tagEnd(c,{a=a,tag=true},b.root.Position)
	c:relocate(b,b.root.Position+V.new(12,0,0))
	H.step(c,1.2)
	assert(damage(c,"charge")==0,"the tag reached a body that stepped out")
end)

test("the smoke bomb: his substitution hides him 1.5 s (the rival loses him, no chase); without it nothing",function()
	local c,a,b=duel("Legion",{"SmokeBomb"},4)
	-- b strikes him; he substitutes out.
	a.lastHurt=c.now;a.state="Stunned";a.untilTime=c.now+.3
	assert(c:substitute(a),"the substitution was refused")
	assert(Families.shrouded(c,b),"the rival still sees him")
	assert(b.pursuitUntil<=c.now,"the rival may chase through the smoke")
	H.step(c,1.6)
	assert(not Families.shrouded(c,b),"the smoke outlived 1.5 s")
	local c2,a2,b2=duel("Legion",nil,4)
	a2.lastHurt=c2.now;a2.state="Stunned";a2.untilTime=c2.now+.3
	assert(c2:substitute(a2))
	assert(not Families.shrouded(c2,b2),"a substitution without the tree hid him")
end)

test("mobility: the wall run lasts longer, a second jump in the air, a quick rise",function()
	-- Wall Runner: the same entry stays on the wall ~40 % longer.
	local function wallTime(nodes)
		H.clearWalls();H.addWall(10)
		local c,a,b=H.duel("Leaf","Mirage",{A=if nodes then ninja("Leaf",nodes) else nil})
		c:relocate(a,V.new(8,3,0));c:relocate(b,V.new(-40,3,60))
		a.move=V.zero;H.step(c,.01)
		local dir=V.new(1,0,-1).Unit
		a.locomotion=dir*50;a.move=dir
		H.step(c,.01)
		assert(a.wall,"no wall run")
		local start=c.now
		for _=1,400 do H.step(c,.01);if not a.wall then break end end
		return c.now-start
	end
	local plain,long=wallTime(nil),wallTime({"WallRunner"})
	assert(long>=plain*1.25,string.format("the wall run: %.2f s, with the node %.2f s",plain,long))
	-- Cloud Step: one more jump in the air, then not until the floor.
	local c,a=duel("Leaf",{"WallRunner","CloudStep"},30)
	c:relocate(a,V.new(0,14,15));a.airborne=true;a.state="Neutral"
	assert(c:request(a,"Jump"),"the second jump was refused")
	assert(a.airJumpUsed and a.root.AssemblyLinearVelocity.Y>30,"the second jump does not rise")
	assert((a.events and a.events.AirJump or 0)==1,"no AirJump event for the client")
	assert(not c:request(a,"Jump"),"a third jump")
	local c2,a2=duel("Leaf",{"WallRunner"},30)
	c2:relocate(a2,V.new(0,14,15));a2.airborne=true;a2.state="Neutral"
	assert(not c2:request(a2,"Jump"),"a second jump without the node")
	-- Quick Rise: the time down after a knockdown.
	local c3,a3,b3=duel("Leaf",{"QuickRise"},4)
	Brawler.react(c3,a3,"Knockdown",V.zero,.8,b3)
	assert(math.abs(a3.reactionUntil-c3.now-.8*N.Mobility.QuickRise)<.001,"the quick rise")
	Brawler.react(c3,b3,"Knockdown",V.zero,.8,a3)
	assert(math.abs(b3.reactionUntil-c3.now-.8)<.001,"a body without the node rose quick")
end)

print(string.format("NinjaDuel the ninja's arts in a duel (DEC-045): %d PASS",passed))
