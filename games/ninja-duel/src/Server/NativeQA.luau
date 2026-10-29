-- Test-only module omitted from playable artifact.
local Players=game:GetService("Players")
local World=require(script.Parent.World)
local Combat=require(script.Parent.Combat)
local AI=require(script.Parent.AI)
local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
local Elements=require(script.Parent.Elements)
local Brawler=require(script.Parent.Brawler)
local Tutorial=require(script.Parent.Tutorial)
local Controls=require(game:GetService("ReplicatedStorage").NinjaDuel.Controls)
local QA={}
function QA.run(matches)
	print("[NinjaDuelQA] START "..require(game:GetService("ReplicatedStorage").NinjaDuel.Config).Version)
	print("[NinjaDuelQA] BUILD "..game:GetService("ReplicatedStorage").NinjaDuel.BuildFingerprint.Value)
	local passed,failed=0,0
	local function test(name,fn)
		local ok,err=xpcall(fn,debug.traceback)
		if ok then passed+=1; print("[NinjaDuelQA] PASS "..name)
		else failed+=1; warn("[NinjaDuelQA] FAIL "..name.." "..tostring(err)) end
	end
	local active={}
	-- (Stage 6) jutsu are ordered by role (R1 + □ △ ○ ×): name them, not a slot.
	local function slot(a,id)
		for i,t in a.def.Techniques do if t.Id==id then return "Technique"..i end end
		return "Technique0"
	end
	local function pair(first,second)
		local f=Instance.new("Folder"); f.Name="NativeQAFixture"; f.Parent=workspace; table.insert(active,f)
		local e=Instance.new("Folder"); e.Name="Effects"; e.Parent=f
		local match={origin=Vector3.new(1200+#active*240,0,0),folder=f,effects=e,phase="Duel"}
		World.arena(f,match.origin)
		local c=Combat.new(match); c.now=100
		local function add(id,def,z)
			local p=match.origin+Vector3.new(0,3,z)
			local m,h,r,j=World.rig(f,Fighters[def],CFrame.lookAt(p,match.origin+Vector3.new(0,3,-z)),id)
			r.Anchored=true;m:SetAttribute("SkipDonorAnimationQA",true)
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
 test("imported Bangla dependencies, three-hit route and Place1 runtime",function()
  local shared=game:GetService("ReplicatedStorage").NinjaDuel
  local combo=require(shared.BanglaCombo)
  assert(combo.maxComboCount==3 and combo.Damage.Punch==5)
  assert(shared.BanglaAssets.Animations.Punch.AnimationId=="rbxassetid://18342131933")
  assert(shared.ThirdPartyLicenses.bangla.Value:find("Dewan Mukto"))
  assert(shared.ThirdPartyLicenses.velmora.Value:find("Yashveer Singh"))
  local c,a,b=pair("Flashstep","Mirage")
  assert(c:request(a,"Attack"));step(c,.3)
  assert(a.model:GetAttribute("CombatBase")=="BanglaBattlegrounds")
  assert(a.model:GetAttribute("MovementBase")=="Place1")
  assert(a.donorHitCount==1 and b.health==b.def.Health-5)
 end)
	test("data-driven identities and five element families",function()
		assert(Fighters.Flashstep.Name=="Minato" and Fighters.Mirage.Name=="Itachi")
		assert(Fighters.Flashstep.Speed>Fighters.Mirage.Speed)
		assert(Fighters.Mirage.Chakra>Fighters.Flashstep.Chakra)
		for _,element in {"Fire","Lightning","Wind","Water","Earth"} do
			assert(Elements.Families[element] and Elements.Families[element].primitive)
		end
	end)
	test("wall enter, rise, rebound and clean detach",function()
		local c,a,b=pair("Flashstep","Mirage")
		c:relocate(a,c.match.origin+Vector3.new(76,3,0))
		a.move=Vector3.xAxis
		step(c,0.3)
		assert(a.wall~=nil,"Wall did not attach")
		assert(a.root.Position.Y>5,"Wall run did not rise")
		assert(c:request(a,"Jump") and a.wall==nil,"Wall rebound failed")
		assert(a.root.AssemblyLinearVelocity.Y>30)
		step(c,0.1); assert(a.wall==nil,"Wall immediately reattached")
	end)
	test("wall edge exits and arena travel stays bounded",function()
		local c,a,b=pair("Flashstep","Mirage")
		c:relocate(a,c.match.origin+Vector3.new(24,3,12))
		a.move=Vector3.xAxis; step(c,0.05); assert(a.wall)
		a.move=Vector3.zAxis; step(c,0.35)
		assert(a.wall==nil,"Wall edge kept actor attached")
		c:relocate(a,c.match.origin+Vector3.new(74,3,50))
		local moved=require(script.Parent.Motor).travel(a,c,Vector3.xAxis,30)
		assert(moved<=4.01 and a.root.Position.X<=c.match.origin.X+78)
	end)
	test("substitution needs fresh hit, charge and chakra",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(not c:request(b,"Substitute"))
		assert(c:damage(a,b,10,false,true))
		local hp=b.health
		assert(c:request(b,"Substitute")); assert(b.subCharges==1 and b.health==hp)
		assert(not c:request(b,"Substitute"))
		b.state="Stunned"; b.lastHurt=c.now; b.subCharges=0
		assert(not c:request(b,"Substitute"))
	end)
	test("declared early technique feint keeps cooldown and partial cost",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(c:request(a,"Technique1",b.root.Position))
		local reserved=a.chakra
		assert(c:request(a,"Feint"))
		assert(a.pending==nil and a.state=="Recovery" and a.chakra>reserved)
		step(c,0.3)
		assert(not c:request(a,"Technique1"),"Feint erased cooldown")
	end)
	test("death clears wall, projectiles, hazards and stale combat state",function()
		local c,a,b,m=pair("Flashstep","Mirage")
		a.wall={part=a.root,normal=Vector3.xAxis,untilTime=110}
		c:addHazard(a,a.root.Position,4,3,10,"Fire")
		c:projectile(a,b.root.Position,50,20,3,"tool")
		assert(c:damage(b,a,1000,false,true))
		assert(m.phase=="Result" and a.wall==nil and #c.projectiles==0 and #c.hazards==0)
	end)
	test("launcher chase air combo slam knockdown and wakeup",function()
 local c,a,b=pair("Flashstep","Mirage")
 for _=1,2 do assert(c:request(a,"Attack"));step(c,.3) end
 assert(c:request(a,"Heavy"));assert(a.attackName=="Launcher")
 step(c,.35);assert(b.reaction=="Launched" and b.root.Position.Y>8)
 local chakra=a.chakra;assert(c:request(a,"Pursuit"));assert(a.chakra==chakra-8)
 step(c,.26);assert(a.airborne and (a.root.Position-b.root.Position).Magnitude<8)
 assert(c:request(a,"Attack"));step(c,.28);assert(b.reaction=="Juggled")
 assert(c:request(a,"Attack"));step(c,.28);assert((a.events.AirHit or 0)>=2)
 assert(c:request(a,"Heavy"));assert(a.attackName=="Slam");step(c,.4)
 assert(b.reaction=="Knockdown" and (a.events.SlamHit or 0)>0)
 step(c,.8);assert(not b.reaction or b.reaction=="Wakeup")
 assert(not c:request(a,"Pursuit"))
 end)
 test("grab directional throw upthrow invalid range and escape",function()
 local c,a,b=pair("Mirage","Flashstep")
 c:relocate(b,c.match.origin+Vector3.new(0,3,-20));assert(c:request(a,"Grab"));step(c,.4);assert(not a.grabVictim)
 step(c,1.2);c:relocate(b,c.match.origin+Vector3.new(0,3,-2));assert(c:request(a,"Grab"));step(c,.23)
 assert(a.grabVictim==b and b.reaction=="Grabbed")
 assert(not c:request(b,"Attack"));a.move=Vector3.xAxis;assert(c:request(a,"Attack"));step(c,.2)
 assert(not a.grabVictim and not b.grabbedBy and b.reaction=="Knockdown" and b.reactionVelocity.X>20)
 step(c,1.5);a.state="Neutral";b.reaction=nil;c:relocate(a,c.match.origin+Vector3.new(0,3,2.5));c:relocate(b,c.match.origin+Vector3.new(0,3,-2.5));a.root.CFrame=CFrame.lookAt(a.root.Position,b.root.Position)
 assert(c:request(a,"Grab"));step(c,.23);assert(c:request(a,"Heavy"));step(c,.2);assert(b.reaction=="Launched")
 end)
 test("active window catches late entry, whiff cannot chain, defender can escape",function()
 local c,a,b=pair("Flashstep","Mirage")
 c:relocate(b,c.match.origin+Vector3.new(0,3,-18));assert(c:request(a,"Attack"));step(c,.12);assert(b.health==b.def.Health)
 c:relocate(b,a.root.Position+a.root.CFrame.LookVector*3);step(c,.04);assert(b.health<b.def.Health)
 assert(c:request(b,"Dodge"));assert(b.subCharges==1 and not b.reaction)
 step(c,.7);c:relocate(b,c.match.origin+Vector3.new(0,3,-35));assert(c:request(a,"Attack"));step(c,.25)
 assert(not a.chainOpen and not c:request(a,"Attack"))
 end)
	test("Fire area and Wind projectile differ, with costs and cooldown",function()
		local c,a,b=pair("Mirage","Flashstep")
		assert(c:request(a,slot(a,"FireBloom"),b.root.Position))
		step(c,0.58)
		assert(b.health<b.def.Health and #c.hazards>0,"Fire area did not pressure target")
		assert(not c:request(a,slot(a,"FireBloom")),"Fire ignored commitment")
		step(c,1.1); assert(#c.hazards==0)
		local w,x,y=pair("Flashstep","Mirage")
		assert(w:request(x,slot(x,"WindCut"),y.root.Position))
		step(w,0.8)
		assert(y.health<y.def.Health,"Wind projectile did not hit")
		assert(#w.hazards==0,"Wind reused Fire area behavior")
	end)
	test("sprint accelerates, braking settles, and jump exceeds default height",function()
		local c,a,b=pair("Flashstep","Mirage")
		a.root.Anchored=false; a.move=Vector3.new(1,0,0); a.sprinting=true
		step(c,0.1); local early=a.locomotion.Magnitude
			step(c,0.3); assert(early>35 and a.locomotion.Magnitude>35)
		a.move=Vector3.zero; a.sprinting=false; step(c,0.3)
		assert(a.locomotion.Magnitude<1,"Ground braking failed")
		assert(c:request(a,"Jump")); assert(a.airborne)
		local originalY=a.root.Position.Y
		task.wait(0.35)
		assert(a.root.Position.Y>originalY+4,"Ninja jump lacks visible height")
	end)
	test("horizontal chain and dash attack remain advancing and bounded",function()
 local c,a,b=pair("Flashstep","Mirage");local first=a.root.Position
	 for beat=1,(a.def.StringLength or 4) do assert(c:request(a,"Attack"));step(c,.31) end
 assert(a.attackName=="Light3" and b.reaction=="Knockback")
 assert((a.root.Position-first).Magnitude>1)
 step(c,1);a.move=-Vector3.zAxis;assert(c:request(a,"Dodge"));step(c,.18)
 assert(c:request(a,"Attack") and a.attackName=="DashAttack")
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
				c:relocate(b,a.root.Position+a.root.CFrame.LookVector*5);b.reaction=nil; c:request(a,"Attack"); step(c,0.7)
			end
			assert(m.winner=="A" and b.health==0 and b.state=="Defeated")
			assert(not c:request(b,"Attack"))
		end end
	end)
	test("all interruptible technique channels cancel before payoff",function()
		for _,f in {"Flashstep","Mirage"} do
			for slot,spec in Fighters[f].Techniques do if spec.Interruptible then
				local c,a,b=pair(f,"Flashstep")
				if spec.Requires=="Anchor" then
					a.anchor={position=a.root.Position+Vector3.new(8,0,0),expires=120,part=c:effect("Anchor",a.root.Position,a.color,Vector3.one,12)}
				end
				assert(c:request(a,"Technique"..slot,b.root.Position))
				local initial=a.root.Position
				assert(c:damage(b,a,7,false,true)); assert(a.state=="Stunned" and a.pending==nil and a.cue=="INTERRUPTED")
			assert(a.cooldowns[spec.Id]>100 and a.chakra==(a.def.Chakra or 100)-spec.Cost)
				step(c,1.3)
				assert(b.health==b.def.Health and b.illusionUntil==0)
				assert((a.root.Position-initial).Magnitude<0.1)
			end end
		end
	end)
	test("cost, cooldown, invalid slot and missing anchor rejected",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(not c:request(a,slot(a,"Flashstep"))); a.chakra=0; assert(not c:request(a,"Technique1"))
		a.chakra=100; assert(c:request(a,slot(a,"LightningStrike"),b.root.Position)); step(c,1.1)
		assert(not c:request(a,slot(a,"LightningStrike"))); assert(not c:request(a,"Technique99"))
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
			assert(c:request(b,"Guard"));step(c,.22);c:damage(a,b,10,false,true)
			assert(math.abs(b.health-(b.def.Health-2.4))<0.01 and b.state=="Guarding")
			b.stamina=1;c:damage(a,b,10,false,true);assert(b.state=="Stunned" and b.cue=="GUARD BREAK")
			b.state="Guarding";b.stamina=100;b.root.CFrame=CFrame.lookAt(b.root.Position,b.root.Position-Vector3.zAxis)
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
		assert(c:request(b,slot(b,"Read"))); step(c,0.15)
		assert(not c:damage(a,b,10,false,true)); assert(b.bonusUntil>c.now and a.state=="Stunned")
		local hp=a.health; c:damage(b,a,10,false,true); assert(math.abs(hp-a.health-13.5)<0.01)
		b.readUntil=c.now+1; hp=b.health; c:damage(a,b,5,false,false); assert(hp-b.health==5)
	end)
	test("noninterruptible Read preparation survives a hit but still takes damage",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(c:request(b,slot(b,"Read"))); c:damage(a,b,7,false,true)
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
		assert(c:request(a,slot(a,"Flashstep"))); step(c,0.5)
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
 test("controller semantic actions and tutorial objectives are complete",function()
 for _,name in {"Light","Heavy","Jump","Dodge","Guard","Tool","Grab","Lock","Sprint","Modifier","Technique5","Skip"} do
  local key=Controls.Gamepad[name]
  assert(key~=nil,"No gamepad mapping "..name)
  assert(string.match(key.Name,"^Button") or string.match(key.Name,"^DPad"),"Not a controller key for "..name)
 end
 assert(#Tutorial.Steps==20)
 local c,a,b=pair("Flashstep","Mirage");local s=c.match;s.combat=c;s.human=a;s.bot=b;s.ai=AI.new(c,b,23)
 Tutorial.new(s);Tutorial.update(s,c.now,.02)
 a.root.CFrame+=Vector3.new(4,0,0);Tutorial.update(s,c.now+.02,.02)
 assert(s.tutorial.index==1,"Uncompleted movement objective skipped")
 for _=1,4 do a.root.CFrame+=Vector3.new(4,0,0);Tutorial.update(s,c.now+.04,.02) end
 Tutorial.update(s,c.now+.4,.02);assert(s.tutorial.index==2,"Real movement did not advance objective")
 end)
 test("death during grab and launch clears both relationship endpoints",function()
 local c,a,b,m=pair("Flashstep","Mirage")
 assert(c:request(a,"Grab"));step(c,.23);assert(a.grabVictim==b)
 c:damage(b,a,1000,false,false);assert(m.phase=="Result" and not b.grabbedBy and not a.grabVictim and not b.reaction)
 end)
	test("contacts are reported once with a hit position and a style",function()
		local c,a,b=pair("Flashstep","Mirage")
		assert(c:request(a,"Attack"));step(c,.4)
		assert(b.health<b.def.Health,"native strike did not land")
		local feed=c.impacts or {}
		assert(#feed>0,"no contact was reported")
		local last=0
		for _,impact in feed do
			assert(impact.serial>last,"impact serials are not ordered")
			assert(typeof(impact.position)=="Vector3","impact without a position")
			assert(type(impact.style)=="string","impact without a style")
			last=impact.serial
		end
		assert(c.impactSerial==last,"impactSerial disagrees with the feed")
		-- A whiff must be reported separately from a contact.
		local before=#(c.impacts or {})
		c:relocate(b,c.match.origin+Vector3.new(0,3,-40))
		assert(c:request(a,"Attack"));step(c,.6)
		local sawWhiff=false;local sawContact=false
		for _,impact in c.impacts or {} do
			if impact.style=="whiff" then sawWhiff=true end
			if impact.style=="light" or impact.style=="finisher" then sawContact=true end
		end
		assert(sawWhiff,"native whiff was not reported")
		assert(not sawContact,"out-of-range swing reported a contact")
	end)
	test("the slam brings its own actor back to the floor",function()
		local c,a,b=pair("Flashstep","Mirage")
		c:relocate(a,c.match.origin+Vector3.new(0,26,1))
		c:relocate(b,c.match.origin+Vector3.new(0,3,-1))
		a.root.CFrame=CFrame.lookAt(a.root.Position,b.root.Position)
		a.root.Anchored=false
		a.airborne=true;a.hitConfirmed=true;a.chainOpen=true;a.attackName="Air2";a.state="Recovery";a.chainAt=0
		assert(c:request(a,"Heavy"),"slam refused")
		assert(a.attackName=="Slam","air heavy did not select the slam")
		step(c,2)
		assert(not a.airborne,"slam left the attacker airborne")
		assert(a.root.Position.Y<c.match.origin.Y+7,"slam parked the attacker at Y="..string.format("%.1f",a.root.Position.Y))
		a.root.Anchored=true
	end)
	-- The animation/presentation contract is a client module and cannot be
	-- required from the server; it is covered by tests/Animation.spec.luau.
	test("PC keyboard mapping matches the documented home-row layout",function()
		local keyboard=Controls.Keyboard
		for _,action in {"Light","Heavy","Dodge","Guard","Grab","Pursuit","Tool","Jump","Substitute"} do
			assert(keyboard[action]~=nil,"no keyboard binding for "..action)
		end
		assert(keyboard.Light==Enum.UserInputType.MouseButton1 and keyboard.Heavy==Enum.UserInputType.MouseButton2)
		assert(keyboard.Jump==Enum.KeyCode.Space and keyboard.Dodge==Enum.KeyCode.Q)
		assert(keyboard.Grab==Enum.KeyCode.V and keyboard.Guard==Enum.KeyCode.F)
		local seen={}
		for action,key in keyboard do
			assert(seen[key.Name]==nil,"key "..key.Name.." drives both "..tostring(seen[key.Name]).." and "..action)
			seen[key.Name]=action
		end
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
			local old=s.folder; assert(s.phase=="Result" or s.finishing)
			s.lastLifecycle=-10; matches:request(player,{action="Rematch",epoch=s.epoch})
			assert(s.phase=="Duel" and old.Parent==nil and s.human.health==125)
		end
		assert(s.epoch==oldEpoch+2)
		s.combat:damage(s.human,s.bot,1000,false,true); s.lastLifecycle=-10
		matches:request(player,{action="Selection",epoch=s.epoch}); assert(s.phase=="Selection" and not s.folder)
		s.lastLifecycle=-10; matches:request(player,{action="Start",epoch=s.epoch,player="Mirage",bot="Flashstep"})
		assert(s.phase=="Duel" and s.human.def.Name=="Itachi")
		matches:selection(player)
	end)
	test("input remote carries the press direction and rejects invalid vectors",function()
  matches:start(player,"Flashstep","Mirage")
  local s=matches.sessions[player];s.introUntil=nil;s.botFrozen=true
  local a,c=s.human,s.combat
  a.root.Anchored=true;s.bot.root.Anchored=true
  local anti=require(script.Parent.VelmoraAntiCheat)
  local function press(direction)
   anti.clear(a)
   matches:request(player,{action="Dodge",epoch=s.epoch,direction=direction,clientTime=workspace:GetServerTimeNow()})
  end
  for _,direction in {Vector3.new(0/0,0,0),Vector3.new(2,0,0),Vector3.new(0,1,0)} do
   press(direction);assert(a.state=="Neutral" and a.move==Vector3.zero,"invalid action intent was accepted")
  end
  press(Vector3.xAxis)
  assert(a.state=="Dodging" and a.dodgeDirection.X>.9,"dodge used stale movement")
  print("[NinjaDuelInputQA] PASS atomic direction + validation")
  matches:selection(player)
 end)
 test("input PS5 chords and existing buffered routes remain available",function()
  assert(Controls.Gamepad.Light==Enum.KeyCode.ButtonX and Controls.Gamepad.Heavy==Enum.KeyCode.ButtonY)
  assert(Controls.Gamepad.Substitute==Enum.KeyCode.DPadRight)
  assert(Controls.TechniquePad[1]=="R1 + ×" and Controls.TechniquePad[2]=="R1 + □")
  for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
   local c,a,b=pair(id,"Flashstep")
   local function confirm()
    assert(c:request(a,"Attack"))
    for _=1,60 do step(c,.02);if a.state=="Recovery" and a.chainOpen then return end end
    error(id..": no chain window")
   end
   confirm();assert(c:request(a,"Attack"));step(c,.02)
   a.move=a.root.CFrame.LookVector
   assert(c:request(a,"Attack"));assert(a.buffered and a.buffered.intent[1]=="forward")
   a.move=Vector3.zero
   local route=if id=="Lion" then "LionKick" else "Launcher"
   for _=1,60 do step(c,.02);if a.attackName==route then break end end
   assert(a.attackName==route,id..": the existing buffer lost its direction")
  end
  print("[NinjaDuelInputQA] PASS PS5 mapping + four fighter buffered routes")
 end)
	 test("R15 procedural combat motion is local and donor clips are optional",function()
  local c,a,b=pair("Flashstep","Mirage")
	  local client=game:GetService("StarterPlayer").StarterPlayerScripts.NinjaDuelClient
	  assert(client:FindFirstChild("VelmoraMotionEngine") and client:FindFirstChild("VelmoraHitFeedback"))
  a.model:SetAttribute("SkipDonorAnimationQA",nil)
  local animation=require(script.Parent.Animation)
  assert(animation.attach(a))
  local deadline=os.clock()+15
  repeat task.wait(.1) until a.model:GetAttribute("DonorAnimationStatus")~="Loading" or os.clock()>deadline
	  if a.model:GetAttribute("DonorAnimationStatus")=="Ready" then
	   for _,name in {"Punch","HardSmack","MegaPunch","Parry"} do
	    local track=a.animation.tracks[name];assert(track,name.." missing")
	    track:Play();task.wait(.2);assert(track.Length>0 and track.IsPlaying,name.." did not play");track:Stop()
	   end
	  else warn("[NinjaDuelQA] External Bangla clips unavailable; Velmora procedural R15 motion remains active") end
  animation.clear(a)
 end)
 for _,f in active do if f.Parent then f:Destroy() end end
	print(string.format("[NinjaDuelQA] TOTAL %d PASS / %d FAIL",passed,failed))
end
return QA
