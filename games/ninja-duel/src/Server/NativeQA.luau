-- Test-only module omitted from playable artifact.
local Players=game:GetService("Players")
local World=require(script.Parent.World)
local Combat=require(script.Parent.Combat)
local AI=require(script.Parent.AI)
local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
local QA={}
function QA.run(matches)
	local passed,failed=0,0
	local function test(name,fn)
		local ok,err=xpcall(fn,debug.traceback)
		if ok then passed+=1; print("[NinjaDuelQA] PASS "..name)
		else failed+=1; warn("[NinjaDuelQA] FAIL "..name.." "..tostring(err)) end
	end
	local active={}
	local function pair(first,second)
		local f=Instance.new("Folder"); f.Name="NativeQAFixture"; f.Parent=workspace; table.insert(active,f)
		local e=Instance.new("Folder"); e.Name="Effects"; e.Parent=f
		local match={origin=Vector3.new(1200+#active*240,0,0),folder=f,effects=e,phase="Duel"}
		World.arena(f,match.origin)
		local c=Combat.new(match); c.now=100
		local function add(id,def,z)
			local p=match.origin+Vector3.new(0,3,z)
			local m,h,r,j=World.rig(f,Fighters[def],CFrame.lookAt(p,match.origin+Vector3.new(0,3,-z)),id)
			r.Anchored=true
			return c:add(id,m,h,r,j,def)
		end
		local a,b=add("A",first,2.5),add("B",second,-2.5); a.target=b; b.target=a
		match.finish=function(winner) match.phase="Result"; match.winner=winner.id; c:clear() end
		task.wait() -- allow native broadphase / joints to settle before ray tests
		return c,a,b,match
	end
	local function step(c,n)
		for _=1,math.ceil(n/0.02) do c:update(0.02,c.now+0.02) end
	end
	test("R15 rigs expose standard animation joints",function()
		local c,a,b=pair("Flashstep","Mirage")
		for _,actor in {a,b} do
			assert(actor.hum.RigType==Enum.HumanoidRigType.R15)
			assert(actor.hum:FindFirstChildOfClass("Animator")~=nil)
			for _,name in {"Root","Waist","Neck","LeftShoulder","RightShoulder","LeftElbow","RightElbow","LeftHip","RightHip","LeftKnee","RightKnee","LeftAnkle","RightAnkle"} do
				assert(actor.joints[name]~=nil,"Missing R15 joint "..name)
			end
		end
	end)
	test("sprint accelerates, braking settles, and jump exceeds default height",function()
		local c,a,b=pair("Flashstep","Mirage")
		a.root.Anchored=false; a.move=Vector3.new(1,0,0); a.sprinting=true
		step(c,0.1); local early=a.locomotion.Magnitude
		step(c,0.3); assert(a.locomotion.Magnitude>early and a.locomotion.Magnitude>35)
		a.move=Vector3.zero; a.sprinting=false; step(c,0.3)
		assert(a.locomotion.Magnitude<1,"Ground braking failed")
		assert(c:request(a,"Jump")); assert(a.airborne)
		local originalY=a.root.Position.Y
		task.wait(0.35)
		assert(a.root.Position.Y>originalY+4,"Ninja jump lacks visible height")
	end)
	test("four moving chain beats, launch, and pursuit cost/expiry",function()
		local c,a,b=pair("Flashstep","Mirage")
		local first=a.root.Position
		for beat=1,4 do
			assert(c:request(a,"Attack"),"Combo input rejected "..beat)
			step(c,0.36)
			assert(b.health<b.def.Health)
		end
		assert((a.root.Position-first).Magnitude>1,"Melee remained stationary")
		assert(a.pursuitUntil>c.now,"Finisher did not create pursuit window")
		local chakra=a.chakra
		assert(c:request(a,"Pursuit")); assert(a.chakra==chakra-8)
		step(c,0.4); assert(not c:request(a,"Pursuit"))
	end)
	test("one air dodge per jump, server rejects repeats",function()
		local c,a,b=pair("Flashstep","Mirage")
		a.root.Anchored=false
		assert(c:request(a,"Jump"))
		task.wait(0.08)
		assert(a.airborne and c:request(a,"Dodge"))
		step(c,0.4)
		assert(not c:request(a,"Dodge")); assert(a.airDodgeUsed)
	end)
	test("all four fighter pairings complete by real validated melee",function()
		for _,f in {"Flashstep","Mirage"} do for _,g in {"Flashstep","Mirage"} do
			local c,a,b,m=pair(f,g)
			for _=1,40 do
				if m.phase~="Duel" then break end
				c:request(a,"Attack"); step(c,0.7)
			end
			assert(m.winner=="A" and b.health==0 and b.state=="Defeated")
			assert(not c:request(b,"Attack"))
		end end
	end)
	test("all five interruptible technique channels cancel before payoff",function()
		for _,f in {"Flashstep","Mirage"} do
			for slot,spec in Fighters[f].Techniques do if spec.Interruptible then
				local c,a,b=pair(f,"Flashstep")
				if spec.Requires=="Anchor" then
					a.anchor={position=a.root.Position+Vector3.new(8,0,0),expires=120,part=c:effect("Anchor",a.root.Position,a.color,Vector3.one,12)}
				end
				assert(c:request(a,"Technique"..slot,b.root.Position))
				local initial=a.root.Position
				assert(c:damage(b,a,7,false,true)); assert(a.state=="Stunned" and a.pending==nil and a.cue=="INTERRUPTED")
				assert(a.cooldowns[spec.Id]>100 and a.chakra==100-spec.Cost)
				step(c,1.3)
				assert(b.health==b.def.Health and b.illusionUntil==0)
				assert((a.root.Position-initial).Magnitude<0.1)
			end end
		end
	end)
	test("cost, cooldown, invalid slot and missing anchor rejected",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(not c:request(a,"Technique2")); a.chakra=0; assert(not c:request(a,"Technique1"))
		a.chakra=100; assert(c:request(a,"Technique3")); step(c,1.1)
		assert(not c:request(a,"Technique3")); assert(not c:request(a,"Technique99"))
	end)
	test("range, facing and real geometry occlusion validate hits",function()
		local c,a,b=pair("Flashstep","Mirage")
		b.root.CFrame=CFrame.new(c.match.origin+Vector3.new(0,3,-30)); assert(not c:strike(a,99,7,0.25,false))
		c:relocate(b,c.match.origin+Vector3.new(0,3,-2.5))
		local wall=World.part(c.match.folder,"CoverQA",Vector3.new(8,8,1),CFrame.new(c.match.origin+Vector3.new(0,4,0)),Color3.new())
		assert(not c:strike(a,99,7,0.25,false)); wall:Destroy()
		a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+Vector3.zAxis)
		assert(not c:strike(a,99,7,0.25,false)); assert(b.health==b.def.Health)
	end)
	test("guard chip, backside hit and guard break",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(c:request(b,"Guard")); c:damage(a,b,10,false,true)
		assert(math.abs(b.health-(b.def.Health-1.2))<0.01 and b.state=="Guarding")
		b.chakra=1; c:damage(a,b,10,false,true); assert(b.state=="Stunned" and b.cue=="GUARD BREAK")
		b.state="Guarding"; b.chakra=100; b.root.CFrame=CFrame.lookAt(b.root.Position,b.root.Position-Vector3.zAxis)
		local old=b.health; c:damage(a,b,10,false,true); assert(old-b.health==10)
	end)
	test("dodge invulnerability ends; cooldown blocks repeat",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(c:request(b,"Dodge")); local hp=b.health
		assert(not c:damage(a,b,10,false,true)); assert(b.health==hp)
		step(c,0.4); assert(not c:request(b,"Dodge")); assert(c:damage(a,b,10,false,true))
	end)
	test("Read catches one frontal melee, grants punish, projectiles bypass",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(c:request(b,"Technique1")); step(c,0.15)
		assert(not c:damage(a,b,10,false,true)); assert(b.bonusUntil>c.now and a.state=="Stunned")
		local hp=a.health; c:damage(b,a,10,false,true); assert(math.abs(hp-a.health-13.5)<0.01)
		b.readUntil=c.now+1; hp=b.health; c:damage(a,b,5,false,false); assert(hp-b.health==5)
	end)
	test("noninterruptible Read preparation survives a hit but still takes damage",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(c:request(b,"Technique1")); c:damage(a,b,7,false,true)
		assert(b.health==b.def.Health-7 and b.state=="TechniqueChannel" and b.pending~=nil)
		step(c,0.15); assert(b.readUntil>c.now)
	end)
	test("Mirage cast preserves movement and expires cleanly",function()
		local c,a,b=pair("Mirage","Flashstep")
		assert(c:request(a,"Technique3")); step(c,1.2)
		assert(b.illusionUntil>c.now and b.decoyPosition~=nil and b.state=="Neutral")
		b.move=Vector3.xAxis; step(c,0.1); assert(b.hum.WalkSpeed>0)
		step(c,3.1); assert(b.decoyPosition==nil)
	end)
	test("Mirage rechecks sight at payoff",function()
		local c,a,b=pair("Mirage","Flashstep")
		assert(c:request(a,"Technique3")); c:relocate(b,c.match.origin+Vector3.new(0,3,-35)); step(c,1.2)
		assert(b.illusionUntil==0 and a.cue=="CAST LOST SIGHT")
	end)
	test("real projectile places floor anchor; relocation consumes it",function()
		local c,a,b=pair("Flashstep","Mirage")
		local floor=c.match.origin+Vector3.new(12,0,0)
		assert(c:request(a,"Technique1",floor)); step(c,1)
		assert(a.anchor~=nil and a.anchor.part.Parent~=nil,"Floor anchor missing; projectiles="..#c.projectiles.." actor="..tostring(a.root.Position).." cue="..a.cue)
		local at=a.anchor.position
		assert(c:request(a,"Technique2")); step(c,0.5)
		assert(a.anchor==nil and (a.root.Position-at).Magnitude<0.1 and a.state=="TechniqueRecovery")
	end)
	test("AI interrupts after reaction delay via shared combat API",function()
		local interrupted=false
		for seed=1,8 do
			local c,a,b=pair("Mirage","Flashstep")
			local ai=AI.new(c,b,seed)
			assert(c:request(a,"Technique3")); ai:update(c.now)
			assert(b.state=="Neutral","AI reacted without delay")
			for _=1,50 do
				step(c,0.02); ai:update(c.now)
				if a.cue=="INTERRUPTED" then
					assert(c.now>=100+0.38,"AI interrupt bypassed reaction latency")
					interrupted=true; break
				end
			end
			if interrupted then break end
		end
		assert(interrupted,"AI never interrupted across seeded decisions")
	end)
	test("death during channel and effect/reset cleanup",function()
		local c,a,b,m=pair("Mirage","Flashstep")
		c:request(a,"Technique3"); c:damage(b,a,1000,false,true)
		assert(m.phase=="Result" and a.pending==nil and #c.projectiles==0 and #c.effects==0)
		assert(#m.effects:GetChildren()==0); local hp=b.health; step(c,5); assert(b.health==hp)
	end)
	for _,f in active do f:Destroy() end
	local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	test("remote validation + two rematches + return selection",function()
		matches:start(player,"Flashstep","Mirage")
		local s=matches.sessions[player]; local oldEpoch=s.epoch
		matches:request(player,{action="Move",epoch=s.epoch,direction=Vector3.new(0/0,0,0)})
		assert(s.human.move==Vector3.zero)
		matches:request(player,{action="Technique3",epoch=s.epoch,aim=Vector3.new(math.huge,0,0)})
		assert(s.human.state=="Neutral")
		matches:request(player,{action="Move",epoch=s.epoch-1,direction=Vector3.xAxis}); assert(s.human.move==Vector3.zero)
		for _=1,2 do
			s.combat:damage(s.human,s.bot,1000,false,true)
			local old=s.folder; assert(s.phase=="Result")
			s.lastLifecycle=-10; matches:request(player,{action="Rematch",epoch=s.epoch})
			assert(s.phase=="Duel" and old.Parent==nil and s.human.health==125)
		end
		assert(s.epoch==oldEpoch+2)
		s.combat:damage(s.human,s.bot,1000,false,true); s.lastLifecycle=-10
		matches:request(player,{action="Selection",epoch=s.epoch}); assert(s.phase=="Selection" and not s.folder)
		s.lastLifecycle=-10; matches:request(player,{action="Start",epoch=s.epoch,player="Mirage",bot="Flashstep"})
		assert(s.phase=="Duel" and s.human.def.Name=="Mirage")
		matches:selection(player)
	end)
	print(string.format("[NinjaDuelQA] TOTAL %d PASS / %d FAIL",passed,failed))
end
return QA
