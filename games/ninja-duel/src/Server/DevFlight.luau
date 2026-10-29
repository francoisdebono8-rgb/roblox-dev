-- Debug/QA places only (DevHooks.install): a flight recorder for a human
-- playtest (user 29/10 midday: "au bout d'un moment, je peux plus bouger, ça
-- freeze"). It keeps, for the local session:
--   samples  the human fighter at 20 Hz for the last 40 s
--   inputs   every press that reached the server: what Matches:act did with
--            it (the anti-cheat gate, Combat's answer)
--   freezes  each moment the stick is held, the body is alive and in a duel,
--            and it does not move for 0.3 s, with everything that can hold a
--            body at that moment (states, timers, humanoid, anchoring)
-- Read with the dev hook: NinjaDuelDev:Invoke("flight").
local RunService=game:GetService("RunService")
local Flight={}

local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function push(list,item,max) table.insert(list,item);while #list>max do table.remove(list,1) end end

-- Everything that can hold a fighter, relative to the duel clock.
function Flight.holds(a,now)
	local function left(t) return if type(t)=="number" and t>now then math.floor((t-now)*100)/100 else nil end
	local hum=a.hum
	return {
		state=a.state,reaction=a.reaction,attack=a.attackName,airborne=a.airborne,wall=a.wall~=nil,
		untilIn=math.floor((a.untilTime-now)*100)/100,reactionLeft=left(a.reactionUntil),hitstop=left(a.hitstopUntil),
		airHold=left(a.airHold),landUntil=left(a.landUntil),takeoff=left(a.takeoffUntil),rotation=left(a.rotationUntil),
		flurry=left(a.flurryUntil),counter=left(a.counterUntil),grabbedBy=a.grabbedBy~=nil,grabVictim=a.grabVictim~=nil,
		throwing=a.throwing and a.throwing.kind,pending=a.pending and (a.pending.name or (a.pending.spec and a.pending.spec.Id)),
		guardHeld=a.guardHeld,guardWanted=a.guardWanted,stamina=a.stamina and math.floor(a.stamina),
		anchored=a.root.Anchored,walkSpeed=hum and math.floor(hum.WalkSpeed*10)/10,humState=hum and hum:GetState().Name,
		platformStand=hum and hum.PlatformStand,autoRotate=hum and hum.AutoRotate,
		traversal=a.model:GetAttribute("MovementTraversalActive"),base=a.model:GetAttribute("MovementBase"),
		locomotion=a.locomotion and math.floor(a.locomotion.Magnitude*10)/10,speedScale=a.speedScale,
		move=a.move and math.floor(flat(a.move).Magnitude*100)/100,lastMove=a.lastMove and math.floor((os.clock()-a.lastMove)*100)/100,
		velocity=math.floor(flat(a.root.AssemblyLinearVelocity).Magnitude*10)/10,vy=math.floor(a.root.AssemblyLinearVelocity.Y*10)/10,
		y=math.floor(a.root.Position.Y*100)/100,latePress=a.latePress and a.latePress.action,
		bound=a.reaction=="Bound",channel=a.state=="TechniqueChannel",
		x=math.floor(a.root.Position.X*10)/10,z=math.floor(a.root.Position.Z*10)/10,
		grounded=a.root:IsGrounded(),gap=a.target and math.floor((flat(a.target.root.Position-a.root.Position)).Magnitude*10)/10,
		hipHeight=hum and hum.HipHeight,floor=hum and hum.FloorMaterial.Name,
		blockers=Flight.blockers(a),
	}
end
-- Solid parts touching the body (props, walls, debris): what a stuck body is
-- standing against.
function Flight.blockers(a)
	local ok,list=pcall(function()
		local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={a.model,a.target and a.target.model}
		local out={}
		for _,part in workspace:GetPartBoundsInRadius(a.root.Position,3.2,params) do
			if part.CanCollide and part.Name~="Training floor" and #out<6 then
				table.insert(out,part.Name..(if part.Anchored then "" else "(loose)"))
			end
		end
		return table.concat(out,",")
	end)
	return if ok then list else "?"
end

function Flight.install(matches,session)
	local R={samples={},inputs={},freezes={},started=os.clock()}
	Flight.data=R
	-- Every press that reaches Matches:act, and what came of it.
	local act=matches.act
	matches.act=function(self,s,actor,payload,clock)
		local action=type(payload)=="table" and payload.action
		if action=="Move" or s~=select(2,session()) then return act(self,s,actor,payload,clock) end
		local refused=actor.refusedInputs or 0
		local logged=actor.pressLog and #actor.pressLog or 0
		local before=actor.pressLog and actor.pressLog[logged]
		act(self,s,actor,payload,clock)
		local entry={t=os.clock()-R.started,action=action,state=actor.state,reaction=actor.reaction,air=actor.airborne}
		if (actor.refusedInputs or 0)>refused then
			entry.verdict="GATE"
			entry.age=actor.refusedAge and math.floor(actor.refusedAge*1000)
		else
			local last=actor.pressLog and actor.pressLog[#actor.pressLog]
			if last and last~=before then entry.verdict=if last.ok then "ok" else "refused";entry.reason=last.reason
			else entry.verdict="dropped" end
		end
		push(R.inputs,entry,150)
	end
	local still,lastSample,freezeOpen=0,0,false
	RunService.Heartbeat:Connect(function(dt)
		local _,s=session()
		local a=s and s.human
		if not (a and s.combat and s.phase=="Duel") then still=0;return end
		local c=s.combat
		local now=os.clock()-R.started
		if now-lastSample>=.05 then
			lastSample=now
			R.worstDt=math.max(R.worstDt or 0,dt)
			push(R.samples,{t=math.floor(now*100)/100,state=a.state,reaction=a.reaction,air=a.airborne,
				x=math.floor(a.root.Position.X*10)/10,z=math.floor(a.root.Position.Z*10)/10,
				bot=a.target and a.target.attackName or (a.target and a.target.state),
				dt=math.floor(dt*1000),
				move=a.move and math.floor(flat(a.move).Magnitude*10)/10,speed=math.floor(flat(a.root.AssemblyLinearVelocity).Magnitude*10)/10,
				y=math.floor(a.root.Position.Y*10)/10,hp=math.floor(a.health)},800)
		end
		local wants=a.move and flat(a.move).Magnitude>.5
		local moving=flat(a.root.AssemblyLinearVelocity).Magnitude>1
		local alive=a.health>0 and not s.finishing and not (s.introUntil and c.now<s.introUntil)
		if wants and not moving and alive then
			still+=dt
			if still>=.3 and not freezeOpen then
				freezeOpen=true
				local holds=Flight.holds(a,c.now)
				holds.t=math.floor(now*100)/100
				push(R.freezes,holds,30)
			end
		else
			if freezeOpen and R.freezes[#R.freezes] then R.freezes[#R.freezes].lasted=math.floor(still*100)/100 end
			still=0;freezeOpen=false
		end
	end)
	return R
end
return Flight
