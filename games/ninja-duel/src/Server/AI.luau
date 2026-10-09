local Config=require(game:GetService("ReplicatedStorage").NinjaDuel.Config)
local AI={}; AI.__index=AI
function AI.new(combat,actor,seed)
	return setmetatable({combat=combat,actor=actor,nextTick=0,observed=nil,observedAt=0,guardUntil=0,rng=Random.new(seed or 23)},AI)
end
function AI:update(now)
	local c,a=self.combat,self.actor; local target=a.target; local tune=Config.AI
	if c.match.phase~="Duel" or a.health<=0 or target.health<=0 then a.move=Vector3.zero; return end
	if now<self.nextTick then return end
	self.nextTick=now+tune.Tick
	local position=if a.decoyPosition and a.illusionUntil>now then a.decoyPosition else target.root.Position
	local delta=position-a.root.Position; delta=Vector3.new(delta.X,0,delta.Z)
	local distance=delta.Magnitude; local toward=if distance>0.1 then delta.Unit else Vector3.zAxis
	if a.state~="Dodging" then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+toward) end
	local tangent=Vector3.new(-toward.Z,0,toward.X)
	local desired=a.def.PreferredRange or 7
	local radial=if distance>desired+2 then 1 elseif distance<desired-2 then -0.6 else 0
	a.move=(toward*radial+tangent*math.sin(now*0.7)*0.7)
	a.sprinting=distance>desired+6
	if a.move.Magnitude>1 then a.move=a.move.Unit end
	if now>=self.guardUntil and a.state=="Guarding" then c:request(a,"GuardOff") end
	if target.state~=self.observed then self.observed=target.state; self.observedAt=now end
	local reacted=now-self.observedAt>=tune.Reaction
	local danger=target.state=="Startup" or target.state=="TechniqueChannel"
	-- A newly observed telegraph may alter movement, but cannot trigger an
	-- instant defensive action or coincidental interrupt before reaction latency.
	if danger and not reacted then return end
	if reacted and danger and distance<9 then
		if target.state=="TechniqueChannel" and distance<=6.8 and self.rng:NextNumber()<tune.Aggression then
			c:request(a,"Attack"); return
		end
		if self.rng:NextNumber()<tune.Defense then
			if self.rng:NextNumber()<0.45 then c:request(a,"Dodge")
			else c:request(a,"Guard"); self.guardUntil=now+0.5 end
			return
		end
	end
	if a.pursuitUntil>now and distance>8 and distance<Config.PursuitRange and self.rng:NextNumber()<0.58 then
		c:request(a,"Pursuit"); return
	end
	if a.state~="Neutral" then return end
	if a.chakra<18 then a.move=-toward+tangent*0.2; return end
	-- Choose by capabilities/technique identifiers, never by a second bot combat engine.
	if self.rng:NextNumber()<tune.Technique then
		for slot,spec in a.def.Techniques do
			local use=false; local aim=target.root.Position
			if spec.Id=="MarkedBlade" then use=not a.anchor and distance>9; aim=position+target.hum.MoveDirection*2-Vector3.new(0,3,0)
			elseif spec.Id=="Flashstep" then use=a.anchor~=nil and distance>10
			elseif spec.Id=="BurstStrike" then use=distance<7 and (target.state=="Recovery" or target.state=="Stunned" or target.state=="TechniqueRecovery")
			elseif spec.Id=="Read" then use=distance<8 and danger and reacted
			elseif spec.Id=="NeedleFan" then use=distance>8 and distance<27
			elseif spec.Id=="MirageCast" then use=distance>10 and distance<21 and (target.state=="Recovery" or target.state=="Guarding" or self.rng:NextNumber()<0.18) end
			if use and c:request(a,"Technique"..slot,aim) then return end
		end
	end
	if distance<8 and self.rng:NextNumber()<tune.Aggression then c:request(a,"Attack") end
	if distance>6 and distance<17 and self.rng:NextNumber()<0.1 then c:request(a,"Jump") end
	-- Sidestep cover when the direct route is obstructed.
	local block=workspace:Raycast(a.root.Position,toward*6,c:rayParams(true))
	if block then a.move=tangent; c:request(a,"Jump") end
end
return AI
