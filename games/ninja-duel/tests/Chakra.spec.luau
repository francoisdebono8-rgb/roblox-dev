-- Systemic chakra (SYS-001 / TOOL-006): OBJECT + CHAKRA + NATURE / MASTERY +
-- CONTEXT = a modified action. Codex's declarative rules (ChakraRules,
-- ChakraInputPlan) drive the live ChakraTuning through ChakraCombat on the real
-- duel: infused throws, meetings in flight, guards, planted points, the wire
-- and Neji's palm. Headless: it proves rules, state and timing, not the look.
local H=require("./Harness")
local V=H.V
local Config=H.load("Shared/Config")
local Rules=H.load("Server/ChakraRules")
local T=H.load("Server/ChakraTuning")
local Chakra=H.load("Server/ChakraCombat")
local S=H.load("Server/ProfileSchema")
local passed=0
local function test(name,fn)
	H.clearWalls()
	local ok,err=pcall(fn)
	H.clearWalls()
	if ok then passed+=1;print("PASS "..name)
	else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,pa,pb)
	c:relocate(a,pa);c:relocate(b,pb)
	a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
	b.root.CFrame=H.C.lookAt(b.root.Position,V.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
end
local function until_(c,seconds,cond,message)
	for _=1,math.ceil(seconds/.01) do
		H.step(c,.01)
		if cond() then return end
	end
	error(message)
end
local function slot(a,id) for i,t in a.def.Techniques do if t.Id==id then return "Technique"..i end end end
local function mine(c,a,kind)
	local list={}
	for _,p in c.projectiles do if p.a==a and (kind==nil or p.kind==kind) and not p.dead then table.insert(list,p) end end
	return list
end
local function outcomes(c)
	local list={}
	for _,row in c.chakraLog or {} do if row.trigger=="ProjectileClash" then table.insert(list,row.outcome) end end
	return list
end
local function count(list,value) local n=0;for _,v in list do if v==value then n+=1 end end;return n end
local function impactWith(c,kind)
	for _,impact in c.impacts do if impact.chakra==kind then return impact end end
	return nil
end
local function chakraTool(c,a,aim) return c:request(a,"Tool",aim,nil,{chakra=true}) end
-- Swap a fighter's mastery profile for one test (data only, no engine change).
local function withMastery(fighter,profile,fn)
	local before=T.CharacterMastery[fighter]
	T.CharacterMastery[fighter]=profile
	local ok,err=pcall(fn)
	T.CharacterMastery[fighter]=before
	if not ok then error(err,0) end
end

test("Codex's rules validate the live tuning and refuse unsafe edits",function()
	assert(Rules.validate(T) and T.Enabled==true)
	for _,mutate in {
		function(c) c.Rules[1].effects[1].kind="ExecuteCode" end,
		function(c) c.Rules[1].when.source.all={"misspelled"} end,
		function(c) c.Rules[2].id=c.Rules[1].id end,
		function(c) c.Infusions.Wind.cost=0/0 end,
		function(c) c.CharacterMastery.Flashstep="Unknown" end,
		function(c) c.Objects.Kunai.caps.speed=-1 end,
	} do
		local copy=S.copy(T);mutate(copy)
		assert(not pcall(Rules.validate,copy),"an unsafe tuning edit was accepted")
	end
end)

test("one interpreter, four identities: the same chakra + tool input per mastery",function()
	local expect={Flashstep={"Wind","throw","Kunai"},Mirage={"Fire","throw","Shuriken"},Lion={"Lightning","throw","Shuriken"},
		GentleFist={"GentleFist","body","Palm"},Sand={"Reinforce","throw","Sand"}}
	for id,want in expect do
		local c,a=H.duel(id,"Flashstep")
		local tool=if a.def.Tool=="Sand" then "Sand" elseif a.def.ToolMastery.Kind=="kunai" then "Kunai" else "Shuriken"
		local plan=assert(Chakra.plan(c,a,tool))
		assert(plan.infusion==want[1] and plan.mode==want[2] and plan.object==want[3],
			id..": "..plan.infusion.."/"..plan.mode.."/"..plan.object)
		assert(plan.tags.chakra and (want[2]=="body" or plan.tags.reinforced),id.." is not chakra steel")
	end
	-- The character id only selects a profile: remapping it is data, not code.
	withMastery("Flashstep","Basic",function()
		local c,a=H.duel("Flashstep","Mirage")
		local plan=Chakra.plan(c,a,"Kunai")
		assert(plan.infusion=="Reinforce" and not plan.tags.wind,"the profile mapping did not drive the infusion")
	end)
end)

test("without the modifier a throw is exactly the plain one",function()
	for _,id in {"Flashstep","Mirage","GentleFist","Lion","Sand"} do
		local c,a,b=H.duel(id,"Flashstep")
		place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
		local before=a.chakra
		assert(c:request(a,"Tool",b.root.Position),id.." could not throw")
		assert(math.abs(before-a.chakra-Config.ToolCost)<1e-6,id.." plain throw cost changed")
		local seen={}
		for _=1,30 do H.step(c,.01);for _,p in c.projectiles do if p.a==a then seen[p]=true end end end
		local mastery=a.def.ToolMastery
		for p in seen do
			assert(p.chakra==nil and p.infusion==nil,id.." plain throw carries chakra")
			if a.def.Tool~="Sand" then
				assert(p.speed==mastery.Speed and p.range==62 and p.damage==mastery.Damage and p.radius==0,id.." plain flight changed")
			else assert(p.speed==90 and p.range==56 and p.radius==.6,"sand bullet changed") end
		end
		assert(next(seen)~=nil,id.." threw nothing")
	end
end)

test("chakra cost per infusion, paid once; refused with a visible fizzle when short",function()
	local c,a,b=H.duel("Flashstep","Mirage")
	place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
	local plan=Chakra.plan(c,a,"Kunai")
	local price=Chakra.cost(plan,false)
	assert(price==T.Infusions.Wind.cost+Config.ToolCost,"wind kunai price "..price)
	a.chakra=price-.5
	local ok,why=chakraTool(c,a)
	assert(not ok and why=="Need chakra","a short reserve was not refused: "..tostring(why))
	assert(a.chakra==price-.5 and a.throwing==nil and #mine(c,a)==0,"a refused infusion still threw or charged")
	assert(impactWith(c,"fizzle") and (a.events or {}).ChakraRefused,"the refusal had no cue")
	for _,row in c.chakraLog or {} do assert(row.trigger~="Infuse","a refused infusion was logged as committed") end
	a.chakra=100
	assert(chakraTool(c,a))
	assert(math.abs(100-a.chakra-price)<1e-6,"paid "..(100-a.chakra))
	-- Inside a confirmed string the plain throw part is free, the chakra is not.
	local c2,x,y=H.duel("Flashstep","Mirage")
	assert(c2:request(x,"Attack"))
	until_(c2,1,function() return x.state=="Recovery" and x.chainOpen and c2.now>=x.chainAt end,"the string never opened")
	local before=x.chakra
	assert(chakraTool(c2,x),"chakra tool refused inside a string")
	assert(math.abs(before-x.chakra-T.Infusions.Wind.cost)<1e-6,"string cancel paid "..(before-x.chakra))
	-- Neji's palm and Sasuke's current throw nothing: no plain throw cost.
	local c3,n,m=H.duel("GentleFist","Flashstep")
	local palm=Chakra.plan(c3,n,"Kunai")
	assert(Chakra.cost(palm,false)==T.Infusions.GentleFist.cost)
end)

test("wind kunai (Minato): faster, longer, cuts the lighter blades in its lane, opens a chase",function()
	local c,a,b=H.duel("Flashstep","Mirage")
	place(c,a,b,V.new(0,3,20),V.new(0,3,-20))
	assert(c:request(b,"Tool"))
	H.step(c,.02)
	assert(chakraTool(c,a))
	until_(c,.3,function() return #mine(c,a,"kunai")>0 end,"no wind kunai")
	local kunai=mine(c,a,"kunai")[1]
	local mastery=a.def.ToolMastery
	assert(kunai.infusion=="Wind" and kunai.speed>=mastery.Speed*1.4 and kunai.range>=62*1.6,"wind kunai flies like a plain one")
	for _=1,60 do H.step(c,.01) end
	local results=outcomes(c)
	assert(count(results,"pierce")==2,"the wind kunai did not cut both shuriken ("..table.concat(results,",")..")")
	assert(#mine(c,b,"shuriken")==0,"a cut shuriken kept flying")
	assert(impactWith(c,"cut"),"no cut impact for the client")
	assert(impactWith(c,"gust") and a.pursuitUntil>c.now-1,"the wind kunai hit opened no chase")
end)

test("chakra-reinforced steel: heavier, deflects a lighter blade, leans on a guard until it breaks",function()
	withMastery("Flashstep","Basic",function()
		local c,a,b=H.duel("Flashstep","Mirage")
		place(c,a,b,V.new(0,3,20),V.new(0,3,-20))
		assert(c:request(b,"Tool"))
		H.step(c,.02)
		assert(chakraTool(c,a))
		for _=1,60 do H.step(c,.01) end
		local results=outcomes(c)
		assert(count(results,"deflect")>=1,"reinforced kunai deflected nothing ("..table.concat(results,",")..")")
		assert(impactWith(c,"deflect"),"no deflect impact")
		-- Guard: a reinforced blade takes far more guard than a plain one and moves the body.
		local function guarded(infused)
			local c2,x,y=H.duel("Flashstep","Mirage")
			place(c2,x,y,V.new(0,3,14),V.new(0,3,-14))
			assert(c2:request(y,"Guard"));H.step(c2,.35)
			y.stamina=100
			local p=c2:projectile(x,y.root.Position,96,62,3,"kunai",nil,{chakra=if infused then Chakra.plan(c2,x,"Kunai") else nil})
			local start=y.root.Position
			c2:projectileHit(p,y,y.root.Position,-p.direction)
			assert(y.impactStyle=="block","the guard did not block")
			return 100-y.stamina,(y.root.Position-start).Magnitude,c2,y
		end
		local plainCost,plainPush=guarded(false)
		local crushCost,crushPush,c3,y3=guarded(true)
		assert(crushCost>=plainCost*3 and crushPush>plainPush+1,"reinforced steel did not crush the guard ("..crushCost.."/"..plainCost..")")
		y3.stamina=10
		local p=c3:projectile(c3.actors[1],y3.root.Position,96,62,3,"kunai",nil,{chakra=Chakra.plan(c3,c3.actors[1],"Kunai")})
		c3:projectileHit(p,y3,y3.root.Position,-p.direction)
		assert(y3.state=="Stunned" and not y3.guardHeld,"an emptied guard did not break")
	end)
end)

test("fire shuriken (Itachi): ignites the body, leaves a burning point, feeds on the wind",function()
	local c,a,b=H.duel("Mirage","Flashstep")
	place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
	local p=c:projectile(a,b.root.Position,88,70,2,"shuriken",nil,{chakra=Chakra.plan(c,a,"Shuriken")})
	local hazards=#c.hazards
	c:projectileHit(p,b,b.root.Position,-p.direction)
	assert(#c.hazards==hazards+1 and c.hazards[#c.hazards].kind=="Fire","a clean fire blade did not ignite")
	-- A miss against the wall: the blade stays planted and the point burns.
	local c2,x,y=H.duel("Mirage","Flashstep")
	place(c2,x,y,V.new(0,3,0),V.new(0,3,-14))
	H.addWall(8)
	local q=c2:projectile(x,V.new(12,4,0),88,70,2,"shuriken",nil,{chakra=Chakra.plan(c2,x,"Shuriken")})
	until_(c2,.3,function() return q.dead or not table.find(c2.projectiles,q) end,"the fire blade never reached the wall")
	local burning=false
	for _,h in c2.hazards do if h.kind=="Fire" and math.abs(h.position.X-8)<1.5 then burning=true end end
	assert(burning,"no burning point at the wall")
	local points=mine(c2,x,"point")
	assert(#points==1 and points[1].infusion=="Fire" and points[1].planted=="shuriken","the fire blade did not stay planted")
	-- Fire feeds on wind: Itachi's fire shuriken eat Minato's wind kunai.
	local c3,m,i=H.duel("Flashstep","Mirage")
	place(c3,m,i,V.new(0,3,20),V.new(0,3,-20))
	assert(chakraTool(c3,i))
	until_(c3,.3,function() return #mine(c3,i,"shuriken")==2 end,"no fire pair")
	local pair=mine(c3,i,"shuriken")
	assert(chakraTool(c3,m))
	until_(c3,.3,function() return #mine(c3,m,"kunai")==1 end,"no wind kunai")
	local wind=mine(c3,m,"kunai")[1]
	for _=1,60 do H.step(c3,.01) end
	local results=outcomes(c3)
	assert(count(results,"absorb")==1 and wind.dead,"fire did not feed on the wind ("..table.concat(results,",")..")")
	assert((pair[1].flared or pair[2].flared) and impactWith(c3,"absorb"),"the fire blade did not flare")
	local damage=if pair[1].flared then pair[1].damage else pair[2].damage
	assert(damage>2*1.25+T.Effects.feed.damage-1e-6,"a flared blade hits no harder")
end)

test("lightning shuriken (Sasuke): a clean hit stuns longer; a planted one is a shock trap",function()
	local function stun(infused)
		local c,a,b=H.duel("Lion","Flashstep")
		place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
		local p=c:projectile(a,b.root.Position,92,62,2,"shuriken",nil,{chakra=if infused then Chakra.plan(c,a,"Shuriken") else nil})
		c:projectileHit(p,b,b.root.Position,-p.direction)
		assert(b.state=="Stunned","no hit stun")
		return b.untilTime-c.now,c
	end
	local plain=stun(false)
	local shocked,c=stun(true)
	assert(shocked>=T.Effects.shock.stun-1e-6 and shocked>plain+.1,"lightning did not lengthen the stun ("..shocked.." vs "..plain..")")
	assert(impactWith(c,"shock"),"no shock impact")
	-- A lightning blade that drops at the end of its flight stays as a trap.
	local c2,a,b=H.duel("Lion","Flashstep")
	place(c2,a,b,V.new(0,3,30),V.new(0,3,-30))
	local p=c2:projectile(a,V.new(40,4,30),92,20,2,"shuriken",nil,{chakra=Chakra.plan(c2,a,"Shuriken")})
	until_(c2,.5,function() return #mine(c2,a,"point")>0 end,"the lightning blade never planted")
	local point=mine(c2,a,"point")[1]
	assert(point.tags.shockPoint and point.infusion=="Lightning","the planted blade is not a shock point")
	H.step(c2,T.Effects.plant.settle)
	c2:relocate(b,V.new(point.position.X+.5,3,point.position.Z))
	local health=b.health
	H.step(c2,.05)
	assert(point.dead and b.health<health and b.state=="Stunned","the shock point did not trigger on the opponent")
	assert(impactWith(c2,"pointshock"),"no shock-point impact")
end)

test("wire: Wire Trap binds, chakra + tool runs lightning down it, Dragon Flame still follows",function()
	local c,a,b=H.duel("Lion","Flashstep")
	place(c,a,b,V.new(0,3,16),V.new(0,3,-16))
	assert(c:request(a,slot(a,"WireTrap"),b.root.Position),"Wire Trap refused")
	until_(c,.8,function() return b.reaction=="Bound" end,"the wire never bound")
	assert(a.wireVictim==b and b.boundAt~=nil)
	local health,untilBound=b.health,b.reactionUntil
	local blades=#mine(c,a,"shuriken")
	local plan=Chakra.plan(c,a,"Shuriken")
	assert(plan.mode=="conduct","holding the wire does not conduct")
	assert(chakraTool(c,a),"the current down the wire was refused")
	assert(b.health<health and b.reactionUntil>untilBound,"the lightning did not run down the wire")
	assert(b.reactionUntil<=b.boundAt+T.Effects.conduct.maxBind+1e-6,"the bind grew past its bound")
	assert(#mine(c,a,"shuriken")==blades and (a.events or {}).WireLightning,"a blade was thrown instead")
	assert(impactWith(c,"conduct"),"no conduct impact")
	H.step(c,.4)
	assert(b.reaction=="Bound","the bind ended under the current")
	assert(c:request(a,slot(a,"FireBloom"),b.root.Position),"Dragon Flame refused after the current")
	until_(c,.6,function() return b.reaction=="Knockdown" end,"Dragon Flame did not follow the wire")
end)

test("a missed wire stays stretched: binds on contact, carries fire, is cut by wind",function()
	local function stretched()
		local c,a,b=H.duel("Lion","Flashstep")
		place(c,a,b,V.new(0,3,16),V.new(30,3,16))
		assert(c:request(a,slot(a,"WireTrap"),V.new(0,3,-30)),"Wire Trap refused")
		until_(c,1.2,function() return #mine(c,a,"tripwire")>0 end,"the missed wire was not stretched")
		local w=mine(c,a,"tripwire")[1]
		assert(w.planted=="wire" and w.range>10,"the wire is too short")
		return c,a,b,w
	end
	local c,a,b,w=stretched()
	local middle=w.origin+w.direction*(w.range*.5)
	c:relocate(b,V.new(middle.X,3,middle.Z))
	H.step(c,.03)
	assert(b.reaction=="Bound" and b.boundBy==a and a.wireVictim==b and w.dead,"walking into the wire did not bind")
	-- Fire touching the wire runs along it and burns it away.
	local c2,x,_,w2=stretched()
	local mid=w2.origin+w2.direction*(w2.range*.5)
	local before=#c2.hazards
	c2:addHazard(x,mid,2,1,4,"Fire")
	H.step(c2,.02)
	assert(w2.dead and #c2.hazards>=before+3,"the fire did not run along the wire")
	-- A wind kunai thrown across the wire cuts it.
	local c3,s,m,w3=stretched()
	local cross=w3.origin+w3.direction*(w3.range*.6)
	c3:relocate(m,cross+V.new(14,0,0))
	H.step(c3,.6)
	assert(chakraTool(c3,m,cross),"wind kunai refused")
	until_(c3,.5,function() return w3.dead end,"the wind kunai did not cut the wire")
	assert(impactWith(c3,"wirecut"),"no wire-cut impact")
	-- A Rotation dome (state as Techniques.Rotation sets it) snaps a wire it
	-- touches along its length, not only at the anchor.
	local c4,_,spinner,w4=stretched()
	spinner.rotationUntil=c4.now+.3
	c4:relocate(spinner,w4.origin+w4.direction*(w4.range*.5)+V.new(3,0,0))
	H.step(c4,.02)
	assert(w4.dead,"the Rotation dome did not snap the wire")
end)

test("Neji's chakra palm: swats the blades in front, reaches the chakra network through a guard",function()
	local c,n,m=H.duel("GentleFist","Flashstep")
	place(c,n,m,V.new(0,3,0),V.new(0,3,-14))
	assert(c:request(m,"Tool"))
	until_(c,.3,function() return #mine(c,m,"kunai")>0 end,"no incoming kunai")
	local kunai=mine(c,m,"kunai")[1]
	assert(chakraTool(c,n),"chakra palm refused")
	assert(n.attackName=="PalmThrust" and n.attackVariant=="ChakraPalm","the palm did not come out")
	until_(c,.4,function() return kunai.dead end,"the palm did not swat the kunai")
	assert(count(outcomes(c),"swat")==1 and impactWith(c,"swat"),"no swat recorded")
	-- Through the guard: the palm drains and closes a point a guard would stop.
	local c2,x,y=H.duel("GentleFist","Flashstep")
	place(c2,x,y,V.new(0,3,3.6),V.new(0,3,0))
	assert(c2:request(y,"Guard"));H.step(c2,.35)
	y.chakra=100;y.stamina=100
	assert(chakraTool(c2,x))
	until_(c2,.6,function() return (x.events or {}).PalmThroughGuard~=nil end,"the palm never reached through the guard")
	assert(y.tenketsu>=1 and y.chakra<=100-x.def.GentleFist.GuardDrain-T.Effects.palm.drain+1e-6,"the guard stopped the chakra")
	assert(impactWith(c2,"throughguard"),"no through-guard impact")
end)

test("meetings resolve deterministically, whatever the order of the projectile list",function()
	local function meet(firstFire)
		local c,i,s=H.duel("Mirage","Lion")
		place(c,i,s,V.new(-12,3,0),V.new(12,3,0))
		local function fire() return c:projectile(i,V.new(12,4,0),88,40,2,"shuriken",nil,{origin=V.new(-6,4,0),chakra=Chakra.plan(c,i,"Shuriken")}) end
		local function bolt() return c:projectile(s,V.new(-12,4,0),88,40,2,"shuriken",nil,{origin=V.new(6,4,0),chakra=Chakra.plan(c,s,"Shuriken")}) end
		local f,l
		if firstFire then f=fire();l=bolt() else l=bolt();f=fire() end
		for _=1,20 do H.step(c,.01) end
		return outcomes(c),f.dead,l.dead,impactWith(c,"intercept")
	end
	local r1,f1,l1,i1=meet(true)
	local r2,f2,l2,i2=meet(false)
	assert(#r1==1 and r1[1]=="intercept" and f1 and l1 and i1 and i1.other~=nil,"equal steel did not intercept ("..table.concat(r1,",")..")")
	assert(table.concat(r1,",")==table.concat(r2,",") and f2 and l2 and i2,"the outcome depended on the list order")
	-- Heavier wins whichever was thrown first.
	withMastery("Flashstep","Basic",function()
		for _,first in {true,false} do
			local c,m,i=H.duel("Flashstep","Mirage")
			place(c,m,i,V.new(-12,3,0),V.new(12,3,0))
			local k,sh
			local function kunai() return c:projectile(m,V.new(12,4,0),96,40,3,"kunai",nil,{origin=V.new(-6,4,0),chakra=Chakra.plan(c,m,"Kunai")}) end
			local function shuriken() return c:projectile(i,V.new(-12,4,0),84,40,2,"shuriken",nil,{origin=V.new(6,4,0)}) end
			if first then k=kunai();sh=shuriken() else sh=shuriken();k=kunai() end
			for _=1,20 do H.step(c,.01) end
			assert(sh.dead and not k.dead and outcomes(c)[1]=="deflect","the heavier blade did not win (first="..tostring(first)..")")
		end
	end)
end)

test("planted chakra blades are contestable points: recovered, knocked out, timed, capped",function()
	local c,a,b=H.duel("Flashstep","Mirage")
	place(c,a,b,V.new(0,3,20),V.new(0,3,-20))
	local p=c:projectile(a,V.new(0,0,10),139,40,3,"kunai",nil,{chakra=Chakra.plan(c,a,"Kunai")})
	until_(c,.4,function() return #mine(c,a,"point")>0 end,"the chakra kunai did not stay planted")
	local point=mine(c,a,"point")[1]
	assert(p.dead or not table.find(c.projectiles,p))
	assert(point.planted=="kunai" and point.infusion=="Wind" and point.speed==0,"the planted point is not at rest")
	-- The owner walks over it: recovered for chakra.
	H.step(c,T.Effects.plant.settle)
	a.chakra=50
	c:relocate(a,V.new(point.position.X,3,point.position.Z+1))
	H.step(c,.03)
	assert(point.dead and a.chakra>=50+T.Effects.plant.refund-1e-6,"the owner did not recover the point")
	-- A thrown object knocks a planted point out.
	local p2=c:projectile(a,V.new(6,0,10),139,40,3,"kunai",nil,{chakra=Chakra.plan(c,a,"Kunai")})
	until_(c,.4,function() return #mine(c,a,"point")>0 end,"no second point")
	local second=mine(c,a,"point")[1]
	c:relocate(a,V.new(0,3,30))
	c:projectile(b,second.position+V.new(0,.2,0),84,40,2,"shuriken",nil,{origin=second.position+V.new(-10,.2,0)})
	until_(c,.3,function() return second.dead end,"the opponent's blade did not knock the point out")
	assert(impactWith(c,"knock"))
	-- Points expire, and an owner keeps at most four.
	for k=1,5 do
		c:projectile(a,V.new(-12+k*4,0,0),139,60,3,"kunai",nil,{chakra=Chakra.plan(c,a,"Kunai")})
		H.step(c,.25)
	end
	assert(#mine(c,a,"point")==T.Effects.plant.max,"the point cap does not hold: "..#mine(c,a,"point"))
	H.step(c,T.Effects.plant.life+.1)
	assert(#mine(c,a,"point")==0,"planted points never expire")
	assert(p2)
end)

test("jutsu volumes clear tools from their path; jutsu never cancel each other",function()
	local c,n,m=H.duel("GentleFist","Flashstep")
	place(c,n,m,V.new(-20,3,0),V.new(20,3,0))
	local palm=c:projectile(n,V.new(20,3,0),96,32,7,"palm",nil,{origin=V.new(-10,3,0),radius=1.5,growth=2.5})
	local kunai=c:projectile(m,V.new(-20,3,0),96,40,3,"kunai",nil,{origin=V.new(10,3,0)})
	for _=1,20 do H.step(c,.01) end
	assert(kunai.dead and not palm.dead and impactWith(c,"blown"),"the Vacuum Palm did not blow the kunai away")
	local c2,i,x=H.duel("Mirage","Flashstep")
	place(c2,i,x,V.new(-20,3,0),V.new(20,3,0))
	local fire=c2:projectile(i,V.new(20,3,0),54,40,16,"fireball",nil,{origin=V.new(-8,3,0),radius=2.4,growth=2.2})
	local wind=c2:projectile(x,V.new(-20,3,0),88,40,7,"wind",nil,{origin=V.new(8,3,0),radius=1.4})
	for _=1,20 do H.step(c2,.01) end
	assert(not fire.dead and not wind.dead and #outcomes(c2)==1 and outcomes(c2)[1]=="pass","two jutsu interfered")
	-- Small flames: reinforced steel heavier than a Phoenix flame goes through it,
	-- a wind blade is eaten by it (fire feeds on wind).
	local function flame(fighter,tool)
		local c3,x3,y3=H.duel(fighter,"Mirage")
		place(c3,x3,y3,V.new(-20,3,0),V.new(20,3,0))
		local blade=c3:projectile(x3,V.new(20,4,0),96,40,3,tool,nil,{origin=V.new(-6,4,0),chakra=Chakra.plan(c3,x3,if tool=="kunai" then "Kunai" else "Shuriken")})
		local phoenix=c3:projectile(y3,V.new(-20,4,0),72,40,4,"phoenix",nil,{origin=V.new(6,4,0),radius=.9,growth=.35})
		for _=1,20 do H.step(c3,.01) end
		return blade,phoenix,outcomes(c3)[1]
	end
	local blade,phoenix,o=flame("Lion","shuriken")
	assert(phoenix.dead and not blade.dead and o=="pierce","reinforced steel did not go through the flame ("..tostring(o)..")")
	blade,phoenix,o=flame("Flashstep","kunai")
	assert(blade.dead and not phoenix.dead and o=="absorb" and phoenix.flared,"the flame did not eat the wind blade ("..tostring(o)..")")
end)

test("rule switches: the legacy plain-blade pass is data and can be turned off for A/B",function()
	local function run(enabled)
		local c,m,i=H.duel("Flashstep","Mirage")
		place(c,m,i,V.new(-12,3,0),V.new(12,3,0))
		if enabled~=nil then Chakra.toggle(c,"plain-pass",enabled) end
		local k=c:projectile(m,V.new(12,4,0),96,40,3,"kunai",nil,{origin=V.new(-6,4,0)})
		local s=c:projectile(i,V.new(-12,4,0),84,40,2,"shuriken",nil,{origin=V.new(6,4,0)})
		for _=1,20 do H.step(c,.01) end
		return k.dead,s.dead,outcomes(c)[1]
	end
	local kd,sd,o=run(nil)
	assert(not kd and not sd and o=="pass","plain blades interact by default")
	kd,sd,o=run(false)
	assert(not kd and sd and o=="deflect","switching plain-pass off did not let the heavier plain blade win")
	assert(not pcall(Chakra.toggle,H.duel("Flashstep","Mirage"),"no-such-rule",true),"an unknown rule was toggled")
end)

-- Remote entry point: the real Matches validation (as in Input.spec).
H.workspace.GetServerTimeNow=function() return 100 end
local Matches=H.load("Server/Matches")
local AntiCheat=H.load("Server/VelmoraAntiCheat")
test("remote: the chakra flag is a validated boolean, never an infusion choice",function()
	local c,a,b=H.duel("Flashstep","Mirage")
	place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
	local player={};local s=c.match;s.epoch=1;s.combat=c;s.human=a;s.bot=b;s.bucket={tokens=100,time=os.clock()}
	local matches=setmetatable({sessions={[player]=s}},Matches)
	local function send(chakra)
		AntiCheat.clear(a)
		matches:request(player,{action="Tool",epoch=1,clientTime=100,chakra=chakra})
	end
	local before=a.chakra
	for _,bad in {"Wind",1,{}} do send(bad) end
	assert(a.chakra==before and a.throwing==nil,"a malformed chakra flag reached combat")
	send(true)
	assert(a.throwing~=nil and before-a.chakra>Config.ToolCost,"chakra=true did not infuse")
	until_(c,.3,function() return #mine(c,a,"kunai")>0 end,"no infused kunai")
	assert(mine(c,a,"kunai")[1].infusion=="Wind","the server did not pick the mastery's infusion")
	H.step(c,1)
	before=a.chakra
	send(nil)
	assert(math.abs(before-a.chakra-Config.ToolCost)<1e-6,"a plain remote throw paid chakra infusion")
end)

-- Client presentation: every chakra contact kind, planted objects and unknown
-- kinds render through the real Effects module without error (stubbed scene).
test("client: infused flights, planted objects and every chakra contact render without error",function()
	local R=H.roblox
	for _,k in {"ColorSequence","ColorSequenceKeypoint","NumberSequence","NumberSequenceKeypoint","NumberRange"} do H.envBase[k]=R[k] end
	local function instance(class)
		local o={ClassName=class,Name=class,children={},props={}}
		local mt={}
		mt.__index=function(t,k)
			if k=="Parent" then return rawget(t,"_parent") end
			if k=="Position" then local cf=rawget(t,"CFrame");return cf and cf.Position or V.zero end
			return rawget(t,"props")[k]
		end
		mt.__newindex=function(t,k,v)
			if k=="Parent" then
				local old=rawget(t,"_parent")
				if old and old.children then local i=table.find(old.children,t);if i then table.remove(old.children,i) end end
				rawset(t,"_parent",v)
				if type(v)=="table" and v.children then table.insert(v.children,t) end
			else rawget(t,"props")[k]=v end
		end
		setmetatable(o,mt)
		o.IsA=function(self,q) return q==self.ClassName or q=="Instance" or (q=="BasePart" and (self.ClassName=="Part" or self.ClassName=="WedgePart")) end
		o.GetChildren=function(self) return table.clone(self.children) end
		o.GetDescendants=function(self)
			local out={}
			local function walk(x) for _,ch in x.children do table.insert(out,ch);walk(ch) end end
			walk(self);return out
		end
		o.FindFirstChild=function(self,name) for _,ch in self.children do if ch.Name==name then return ch end end return nil end
		o.FindFirstChildOfClass=function(self,cl) for _,ch in self.children do if ch.ClassName==cl then return ch end end return nil end
		o.Destroy=function(self) self.Parent=nil end
		o.ClearAllChildren=function(self) table.clear(self.children) end
		o.Emit=function() end;o.Play=function() end;o.Stop=function() end
		o.PivotTo=function(self,cf) if self.PrimaryPart then self.PrimaryPart.CFrame=cf end end
		o.GetPivot=function(self) return if self.PrimaryPart then self.PrimaryPart.CFrame else H.C.new() end
		return o
	end
	H.envBase.Instance={new=instance}
	H.envBase.task={delay=function(_,fn,...) fn(...) end,spawn=function() end,wait=function() end}
	H.workspace.GetServerTimeNow=function() return 100 end
	local FX=H.load("Client/Effects")
	local fx=FX.new()
	local folder=instance("Folder")
	local projectiles={}
	for i,spec in {{"kunai","Wind"},{"shuriken","Fire"},{"shuriken","Lightning"},{"sand","Reinforce"},{"kunai",nil},{"wire",nil},{"kunai","UnknownNature"}} do
		table.insert(projectiles,{id=i,kind=spec[1],origin=V.new(0,4,0),direction=V.zAxis,speed=90,born=99,range=60,owner="A",radius=.25,growth=0,infusion=spec[2]})
	end
	table.insert(projectiles,{id=20,kind="point",planted="kunai",origin=V.new(3,2,0),direction=-V.yAxis,speed=0,born=99,range=0,owner="A",radius=0,growth=0,infusion="Lightning"})
	table.insert(projectiles,{id=21,kind="point",planted="shuriken",origin=V.new(5,2,0),direction=-V.yAxis,speed=0,born=99,range=0,owner="A",radius=0,growth=0,infusion="Fire"})
	table.insert(projectiles,{id=22,kind="tripwire",planted="wire",origin=V.new(0,1,0),direction=V.xAxis,speed=0,born=99,range=12,owner="B",radius=0,growth=0,infusion="Lightning"})
	table.insert(projectiles,{id=23,kind="point",planted="mystery",origin=V.new(7,2,0),direction=-V.yAxis,speed=0,born=99,range=0,owner="A",radius=0,growth=0})
	local data={phase="Duel",epoch=1,projectiles=projectiles,hazards={},human={id="A",seals={}},bot={id="B",seals={}}}
	fx:sync(data)
	for _=1,3 do fx:stepProjectiles(1/60) end
	assert(fx.projectiles[1].decor and fx.projectiles[20].static and fx.projectiles[22].wire,"infused/planted entries were not built")
	assert(fx.projectiles[23]==nil,"an unknown planted tool was drawn")
	local kinds={"cut","deflect","knock","swat","blown","burn","absorb","intercept","crush","shock","pointshock","wirecharge","surge","conduct",
		"ignite","gust","plant","stretch","recover","deny","expire","fizzle","palm","throughguard","tenketsu","tripwire","wirecut","wireburn","no-such-kind"}
	for i,kind in kinds do
		local impact={style=if i%2==0 then "deflect" else "mystery-style",position=V.new(0,3,0),chakra=kind,projectile=i,other=i+1,kind="shuriken",
			direction=V.zAxis,tumble=V.yAxis,from=V.new(0,3,0),to=V.new(4,3,0),infusion=if i%3==0 then nil else "Lightning",owner="A",victim="B",serial=i}
		-- Called directly first (FX:impact guards it with pcall), so an error shows.
		fx:chakraImpact(impact,folder)
		fx:impact(impact,folder)
	end
	for _,p in projectiles do if p.planted and p.planted~="mystery" then assert(fx:planted(p),"planted "..p.planted.." not built") end end
	fx:impact({style="never-heard-of-it",position=V.new(0,3,0),serial=99},folder)
	data.projectiles={}
	fx:sync(data)
	for _=1,30 do fx:stepProjectiles(.05) end
end)

print("NinjaDuel chakra systemic: "..passed.." PASS (headless rules, state and timing; the look is a Studio check)")
