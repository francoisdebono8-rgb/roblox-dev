-- Velmora's additive combat motion and hit feedback, retaining Ninja Duel's
-- deception visual. Rendering is continuous: bodies are drawn on a smoothed
-- track of their replicated roots instead of jumping once per network packet.
local Motion=require(script.Parent.VelmoraMotionEngine)
local Feedback=require(script.Parent.VelmoraHitFeedback)
local Effects=require(script.Parent.Effects)
-- Bodies that are not fighters (Naruto's shadow clones).
local BodyViews=require(script.Parent.BodyViews)
local Smear=require(script.Parent.MotionSmear)
local Kit=require(script.Parent.VfxKit)
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Config=require(Shared.Config)
local Attacks=require(Shared.Attacks)
local MoveGraphs=require(Shared.MoveGraphs)
local ActionContext=require(Shared.ActionContext)
local Presentation={};Presentation.__index=Presentation
local LOCOMOTION_POSE_SPEED=26
function Presentation.new()
	return setmetatable({last={},recoil={},impactSerial=0,impactEpoch=nil,clocks={},landings={},botModel=nil,fx=Effects.new(),bodies=BodyViews.new(),smooth={},freeze={}},Presentation)
end
-- (FEEL 05/11, user: « les coups qui touchent » are what feels the least fun:
-- no impact, no weight, the opponent barely reacts) Hit stop, drawn only:
-- on a contact both bodies hold their pose for a few frames, the struck one
-- shakes along the blow and its drawn track holds still, then everything
-- resumes from where it stopped. The server keeps its own clock (no change to
-- any timing of the fight): the drawn poses run that much behind for the rest
-- of the move, the drawn track catches up at its normal cap.
-- Seconds of stop per contact style.
Presentation.STOP={light=.07,air=.07,flow=.06,palm=.06,kunai=.035,shuriken=.03,block=.05,finisher=.11,launcher=.12,
	slam=.15,parry=.13,clash=.12,wallbounce=.13,jutsu=.09,repel=.1,palmburst=.1,chidori=.12,groundbounce=.12}
-- How hard the struck body is flashed (strength, seconds) per style.
local FLASH={light={.62,.11},air={.62,.11},flow={.55,.1},finisher={.8,.16},launcher={.85,.17},slam={.9,.2},
	jutsu={.75,.15},wallbounce={.85,.18},palm={.6,.11},palmburst={.8,.16}}
Presentation.FLASH=FLASH
function Presentation:hitstop(keys,style,direction,now)
	local stop=Presentation.STOP[style or ""]
	if not stop then return 0 end
	now=now or os.clock()
	for key,struck in keys do
		local f=self.freeze[key]
		-- A second contact inside a stop does not stack: it only extends it.
		if f and now<f.untilT then f.untilT=math.max(f.untilT,now+stop)
		else self.freeze[key]={from=now,untilT=now+stop,struck=struck,dir=direction,amp=math.clamp(stop*2.4,.12,.32)} end
	end
	return stop
end
-- The struck body's flash on a guessed contact (the server's own contact,
-- when it comes, does not flash it a second time: Effects reads `tinted`).
function Presentation.flash(model,strength,time)
	Kit.tint(model,Color3.fromRGB(255,244,236),time,strength)
end
function Presentation:frozen(key,now)
	local f=self.freeze[key]
	return f~=nil and now<f.untilT,f
end
-- The opponent's body in the viewer's duel folder: the server names it by the
-- id it sends as data.bot.id ("AIFighter" against the AI, a duelist online).
function Presentation.opponent(data,folder)
	return folder and folder:FindFirstChild(data and data.bot and data.bot.id or "AIFighter")
end
-- The replicated root of a server-owned fighter only moves every other
-- rendered frame (physics replication at ~30 Hz against a 60 Hz render), so a
-- body drawn on it advances in jerks. Each fighter is instead drawn on a short
-- interpolated track of its replicated positions, a fixed ~45 ms behind: the
-- motion is continuous every frame. A real teleport still snaps.
local TRACK_DELAY,TRACK_SNAP,TRACK_MAX,TRACK_SAMPLES=.045,45,12,8
-- The drawn body's fastest turn (rad/s): the server's own fastest, a rush.
local ROT_CAP=math.rad(2400)
local LOCAL_EXTRAPOLATE=1/30
local function yawOf(cf)
	local look=cf.LookVector
	return math.atan2(-look.X,-look.Z)
end
local function lerpAngle(a,b,t)
	local d=(b-a+math.pi)%(2*math.pi)-math.pi
	return a+d*t
end
function Presentation:smoothRoot(key,actualCF,dt,warp)
	local now=os.clock()
	local st=self.smooth[key]
	if not st then st={samples={},vel=Vector3.zero};self.smooth[key]=st end
	local samples=st.samples
	local actual=actualCF.Position
	local newest=samples[#samples]
	if (warp and warp~=st.warp) or (newest and (actual-newest.p).Magnitude>TRACK_SNAP) then
		table.clear(samples);newest=nil;st.vel=Vector3.zero;st.pos=nil
	end
	st.warp=warp
	local yaw=yawOf(actualCF)
	if not newest or (actual-newest.p).Magnitude>1e-4 or math.abs(lerpAngle(newest.yaw,yaw,1)-newest.yaw)>1e-4 then
		table.insert(samples,{t=now,p=actual,yaw=yaw})
		while #samples>TRACK_SAMPLES do table.remove(samples,1) end
	elseif now-newest.t>.1 then
		-- Standing still: keep the track anchored to the present.
		newest.t=now
	end
	-- (É7, the player's own body) The opponent is drawn 45 ms behind on the
	-- interpolated track; the player's own body is drawn on the PRESENT: past
	-- the newest packet it carries on along the last segment, for at most one
	-- packet's gap (the 45 ms were a quarter of the lag he felt).
	local at=now-(if key=="human" then 0 else TRACK_DELAY)
	local pos,face=samples[#samples].p,samples[#samples].yaw
	if key=="human" and #samples>=2 and at>samples[#samples].t then
		local a,b=samples[#samples-1],samples[#samples]
		local span=b.t-a.t
		if span>1e-3 and span<.12 then
			local ahead=math.min(at-b.t,LOCAL_EXTRAPOLATE)
			pos=b.p+(b.p-a.p)*(ahead/span);face=b.yaw
		end
	elseif at<=samples[1].t then pos,face=samples[1].p,samples[1].yaw
	else
		for i=#samples-1,1,-1 do
			local a,b=samples[i],samples[i+1]
			if at>=a.t then
				local span=b.t-a.t
				local t=if span>1e-4 then math.clamp((at-a.t)/span,0,1) else 1
				pos=a.p:Lerp(b.p,t);face=lerpAngle(a.yaw,b.yaw,t)
				break
			end
		end
	end
	local offset=pos-actual
	if offset.Magnitude>TRACK_MAX then pos=actual+offset.Unit*TRACK_MAX end
	-- Velocity of the drawn body: what the legs and lean must match.
	if st.pos then
		local v=(pos-st.pos)/math.max(dt,1/240)
		st.vel=st.vel:Lerp(v,math.min(1,dt*18))
	end
	st.pos=pos;st.yaw=face
	return CFrame.new(pos)*CFrame.Angles(0,face,0)
end
function Presentation:visualRoot(key)
	local st=self.smooth[key]
	return st and st.pos
end
function Presentation:visualVelocity(key)
	-- (The player's own body: the velocity it is drawn with, lead included.)
	if key=="human" and self.lead and self.lead.vel then return self.lead.vel end
	local st=self.smooth[key]
	return st and st.vel
end
-- (DEC-030 Partie 1, responsiveness) The player's own body answers the stick
-- at once. The server still moves it (authority), but its track arrives
-- 100-170 ms after the press; the body is drawn ahead of that track by what a
-- body obeying the stick would have run since - an offset that fades as the
-- track catches up (it is zero at any steady speed), never more than 3 studs,
-- never into the opponent. Outside free movement it follows the track.
local LEAD_TAU,LEAD_MAX,LEAD_GUESS_MAX=.13,3,5
function Presentation:leadLocal(actor,drawn,dt)
	local st=self.lead
	if not st then st={off=Vector3.zero,v=Vector3.zero};self.lead=st end
	local track=self.smooth.human and self.smooth.human.vel or Vector3.zero
	local trackFlat=Vector3.new(track.X,0,track.Z)
	local free=actor.state=="Neutral" and not actor.reaction and not actor.airborne and not actor.wall and actor.groundPose==nil
	local want=trackFlat
	local guess=self:movement(actor)
	if guess then
		-- (É7) A dodge or a jump pressed: the body goes at once, on the same
		-- curve the server will run ~80 ms later; the offset holds while the
		-- track catches up, then fades.
		want=Vector3.new(guess.X,0,guess.Z)
		st.v=want
		st.vy=guess.Y
		local g=self.movePrediction
		if g then g.covered=(g.covered or 0)+want.Magnitude*dt end
	elseif free then
		local dir=self.inputDir or Vector3.zero
		dir=Vector3.new(dir.X,0,dir.Z)
		if dir.Magnitude>1 then dir=dir.Unit end
		local def=Fighters[actor.fighterId]
		local move=Config.Movement or {}
		local speed=if self.inputSprint then (move.SprintSpeed or 45)*(def and def.SprintScale or 1) else (def and def.Speed or 18)
		want=dir*speed
	end
	st.v=st.v:Lerp(want,math.min(1,dt*28))
	st.off+=(st.v-trackFlat)*dt
	-- (É7) the jump's rise: ahead of the track while the server's jump is on its way
	st.offY=(st.offY or 0)+((if guess then st.vy or 0 else track.Y)-track.Y)*dt
	st.offY*=math.exp(-dt/(if guess then LEAD_TAU else .06))
	st.offY=math.clamp(st.offY,-.5,LEAD_MAX)
	-- (É7, audit 02/11) A strike out of a run used to pull the body back onto
	-- the track in 70 ms (a visible yank as the blow starts): the run's lead now
	-- fades through the strike; a reaction still snaps it back fast.
	local striking=actor.attackName~=nil and (actor.state=="Startup" or actor.state=="Active" or actor.state=="Recovery") and not actor.reaction
	st.off*=math.exp(-dt/(if free or guess then LEAD_TAU elseif striking then .18 else .07))
	local cap=if guess then LEAD_GUESS_MAX else LEAD_MAX
	if st.off.Magnitude>cap then st.off=st.off.Unit*cap end
	local other=self:visualRoot("bot")
	if other and st.off.Magnitude>1e-3 then
		-- (Studio 03/11: Minato pushed into Gaara and the two bodies merged)
		-- The lead never draws him closer to the opponent than the server
		-- keeps him (Motor.SURFACE 3.4 root to root): pushing into him, the
		-- part of the lead that goes toward him is dropped.
		local function gap(k)
			local at=drawn.Position+st.off*k
			return Vector3.new(at.X-other.X,0,at.Z-other.Z).Magnitude
		end
		local floor=math.min(3.2,gap(0))
		if gap(1)<floor then
			local lo,hi=0,1
			for _=1,6 do local mid=(lo+hi)/2;if gap(mid)<floor then hi=mid else lo=mid end end
			st.off*=lo
		end
	end
	local out=drawn+st.off+Vector3.new(0,st.offY,0)
	if st.prev then
		local v=(out.Position-st.prev)/math.max(dt,1/240)
		st.vel=(st.vel or v):Lerp(v,math.min(1,dt*18))
	end
	st.prev=out.Position
	return out
end
-- (Responsiveness) A light or heavy pressed starts moving the body on the
-- press: the strike the server will start is guessed (the next light of the
-- string, or a heavy from neutral) and drawn from the press; when the server's
-- strike arrives it continues from the same instant if the guess was right,
-- otherwise the server's strike takes over (through the transition). A guess
-- the server never confirms fades after 0.25 s.
-- (Stage 6) The string's light for its confirmed hits (Brawler.request: the
-- index after `combo` hits, by the fighter's StringLength; the last is Light3).
local function lightName(combo,fighterId)
	local f=Fighters[fighterId]
	local length=(f and f.StringLength) or 4
	local index=(combo or 0)+1
	return if index>=length then "Light3" elseif index<=2 then "Light"..index else "Light"..(index+1)
end
-- (É7, the most felt lag) A dodge and a jump start at the press. The server
-- still decides (cooldowns, cost, a hit in between); its state confirms the
-- guess within ~0.1 s, or the guess is dropped and the body eases back.
local DODGE_TIME,DODGE_DISTANCE=.32,14
local WALL_ONLY={wall=true}
-- (É7) The body as the server will read it when a press made now lands, `dt`
-- seconds after the snapshot: Brawler.guessView's windows run out, a
-- recovery or a dodge ends. (The opponent can still change it: a hit.)
function Presentation.viewAt(h,dt)
	local g=h.guess or {}
	local state=h.state
	local left=g.left or 0
	if dt>0 and (state=="Recovery" or state=="Dodging" or state=="TechniqueRecovery") and left<=dt then state="Neutral" end
	local chainReady=state=="Recovery" and g.chainOpen==true and (g.chainIn or 0)<=dt
	local combo,airCombo=g.combo or 0,g.airCombo or 0
	local arrival
	if h.state=="Dodging" then arrival=state=="Dodging" and dt>=left-.23
	elseif h.state=="Rush" or h.state=="Pursuit" then arrival=g.arrival==true
	else arrival=dt<(g.rushArriveLeft or 0) and (state=="Neutral" or (state=="Recovery" and g.arrivalRecovery==true)) end
	local cancel=g.cancelAt
	-- a blow taken: stepped out of by a dodge once its share has run
	-- (Brawler.recoverable "stand"); ending on its own first: unknown state
	local reaction=h.reaction
	local stand=reaction~=nil and g.standIn~=nil and g.standIn<=dt
	if reaction and not stand and dt>0 and (g.reactionLeft or math.huge)<=dt then reaction="?" end
	return {state=state,airborne=h.airborne,fighterId=h.fighterId,awaken=h.awaken,reaction=reaction,stand=stand,
		chainReady=chainReady,combo=combo,airCombo=airCombo,
		stringAlive=not h.airborne and combo>=1 and not g.stringHurt and ((chainReady and not g.chainAir) or dt<=(g.stringLeft or 0)),
		airAlive=h.airborne==true and airCombo>=1 and not g.airHurt and ((chainReady and g.chainAir==true) or dt<=(g.airLeft or 0)),
		arrival=arrival,riposte=(g.riposteLeft or 0)>dt or (g.counterLeft or 0)>dt,counter=math.max(0,(g.counterLeft or 0)-dt),
		lion=(g.lionLeft or 0)>dt,airRecent=(g.airRecentLeft or 0)>dt,
		cancelReady=(state=="Recovery" or state=="TechniqueRecovery") and cancel~=nil and cancel<=dt,
		jumpCancel=state=="Recovery" and (cancel==nil or cancel<=dt),
		dodge=math.max(0,(h.dodge or 0)-dt),pursuit=math.max(0,(h.pursuit or 0)-dt)}
end
-- How long after the snapshot a press made now lands on the server: the
-- snapshot's age plus the trip back (the lowest age seen, noteSnapshot).
function Presentation:noteSnapshot(age)
	if type(age)~="number" then return end
	local w=self.oneWay
	if not w or age<w then self.oneWay=math.max(0,age) else self.oneWay=w+(age-w)*.02 end
end
function Presentation:pressAhead(data)
	local w=self.oneWay
	if not w or not data or not data.serverNow then return 0 end
	local age=0
	pcall(function() age=workspace:GetServerTimeNow()-data.serverNow end)
	return math.clamp(age+w,0,.35)
end
-- A guess is drawn only when it holds across the trip's uncertainty: read at
-- the landing time and half a trip either side, the same answer three times
-- (a window closing, a body crossing a reach as the press lands: no guess).
local STEADY={.5,1.5}
function Presentation:steady(ahead,read)
	local mid=read(ahead)
	if ahead<=0 then return mid end
	for _,k in STEADY do if read(ahead*k)~=mid then return nil end end
	return mid
end
-- (É7) Sprint + dodge toward a locked opponent at mid range is the re-engage
-- (Brawler.dashIntent): the chase in a pursuit window, else the chakra dash
-- (Combat:rush); only when neither is there does it stay a dodge. true: a
-- re-engage, false: a dodge, "?": the client cannot tell.
function Presentation:dashes(h,v,data,dt)
	local g=h.guess or {}
	if not self.inputSprint or g.locked~=true or h.airborne then return false end
	local me,them=self:guessRoots()
	local bot=data and data.bot
	if not me or not them or not bot or (bot.health or 1)<=0 then return false end
	local to=Vector3.new(them.X-me.X,0,them.Z-me.Z)
	if to.Magnitude<=.05 or ActionContext.stick(self.inputDir or Vector3.zero,to.Unit,Config.Combo)~="forward" then return false end
	local style=(MoveGraphs[h.fighterId] or {}).reengage or {}
	local tune=Config.Rush or {}
	if to.Magnitude<(style.minRange or tune.MinRange or 7) then return false end
	local gap=(them-me).Magnitude
	local cost=Config.PursuitCost or 8
	if v.pursuit>0 then return (h.chakra or 0)>=cost and gap<=(Config.PursuitRange or 46) end
	if style.reposition then return "?" end
	if (h.chakra or 0)<cost and (g.freeRushLeft or 0)<=dt then return false end
	if (g.rushReadyLeft or 0)>dt then return false end
	if gap>(tune.Range or 48) then return false end
	return true
end
function Presentation:predictMove(action,data,ahead)
	local h=data and data.human
	if not h or h.wall or h.groundPose or (h.health or 1)<=0 or (h.guess and h.guess.held) then return end
	if h.reaction and action~="Dodge" then return end
	local now=os.clock()
	ahead=ahead or self:pressAhead(data)
	local def=Fighters[h.fighterId]
	local root=nil
	pcall(function()
		local character=game:GetService("Players").LocalPlayer.Character
		root=character and character:FindFirstChild("HumanoidRootPart")
	end)
	-- (Audit 04/11) A press the server turns into a string route (Brawler
	-- .buttonRoute: ○ around, × rising after two hits, the stick not pushed
	-- away) is a strike, not a dash or a hop: no guess (the body dashed, then
	-- snapped back into the route).
	if not h.airborne and (action=="Dodge" or action=="Jump" or action=="PadJump") then
		local v=Presentation.viewAt(h,ahead)
		local routes=(MoveGraphs[h.fighterId] or {}).routes or {}
		local route=if action=="Dodge" then routes.side else routes.up
		local away=false
		local dir,b=self.inputDir,data.bot
		if dir and root and b and b.position then
			local flat=Vector3.new(dir.X,0,dir.Z)
			local to=Vector3.new(b.position.X-root.Position.X,0,b.position.Z-root.Position.Z)
			away=to.Magnitude>.1 and ActionContext.stick(flat,to.Unit,Config.Combo)=="back"
		end
		if route and Attacks[route] and v.combo>=2 and (v.stringAlive or v.chainReady) and not away then return end
	end
	if action=="Dodge" then
		-- The server's own rules (Combat:requestInner): chakra for it, off
		-- cooldown (snapshot `dodge`), not Gaara's sand flicker (a teleport),
		-- not loaded (the chakra dash), not the sprinting re-engage at him.
		-- (a recovery past its cancel point is left by a dodge, as on the server)
		if h.airborne or (def and def.SandFlicker) then return end
		if h.chakraLoad then return end
		local g=h.guess or {}
		local free=self:steady(ahead,function(dt)
			-- a press already waiting may fire before this one lands
			if g.buffered and dt>0 then return "?" end
			local v=Presentation.viewAt(h,dt)
			local cost=Config.DodgeCost or 10
			if v.reaction=="?" then return "?" end
			if v.reaction then
				-- (EMB-003) past its share the blow is stepped out of, then
				-- the dodge goes as usual; earlier the dodge is a substitution
				if not v.stand then return false end
				cost+=(Config.Agency and Config.Agency.StepCost or 6)
				v.state="Neutral"
			end
			if (h.chakra or 0)<cost then return false end
			if not ((v.state=="Neutral" or v.state=="Guarding" or v.cancelReady) and v.dodge<=0) then return false end
			-- (Combat: sprint + dodge at him is the re-engage when one is there)
			self.ahead=dt
			local dash=self:dashes(h,v,data,dt)
			self.ahead=nil
			if dash=="?" then return "?" end
			return not dash
		end)
		if free~=true then return end
		if now-(self.lastDodgeGuess or -10)<(Config.DodgeCooldown or .8) then return end
		local dir=self.inputDir or Vector3.zero
		dir=Vector3.new(dir.X,0,dir.Z)
		if dir.Magnitude<.1 then dir=if root then root.CFrame.RightVector else Vector3.xAxis end
		self.lastDodgeGuess=now
		-- (waits a round trip for the server's dodge; out of a blow the body
		-- is still reacting until then)
		self.movePrediction={kind="Dodge",at=now,dir=dir.Unit,distance=DODGE_DISTANCE*(def and def.DashScale or 1),time=DODGE_TIME,serial=h.warpSerial,
			wait=math.max(.16,ahead+.1),fromReaction=h.reaction~=nil}
	elseif action=="Jump" or action=="PadJump" then
		-- (a pad jump in a chase window is the chase: the server's call)
		if h.airborne then return end
		local free=self:steady(ahead,function(dt)
			local v=Presentation.viewAt(h,dt)
			return (v.state=="Neutral" or v.jumpCancel) and v.pursuit<=0
		end)
		if not free then return end
		local move=Config.Movement or {}
		local v0=(move.JumpVelocity or 58)*(def and def.JumpScale or 1)
		self.movePrediction={kind="Jump",at=now,v0=v0,g=workspace.Gravity,time=math.max(.18,ahead+.1)}
	end
end
-- The guessed velocity of the body now (nil when there is no live guess).
function Presentation:movement(actor)
	local g=self.movePrediction
	if not g then return nil end
	local t=os.clock()-g.at
	if g.kind=="Dodge" then
		if actor.state=="Dodging" then g.confirmed=true end
		if t>g.time or (not g.confirmed and (t>(g.wait or .16) or (actor.reaction and not g.fromReaction))) then self.movePrediction=nil;return nil end
		local k=t/g.time
		return g.dir*(g.distance*2*(1-k)/g.time)
	elseif g.kind=="Strike" then
		if actor.attackName==g.name and (actor.state=="Startup" or actor.state=="Active") then g.confirmed=true end
		if t>g.time or actor.reaction or (not g.confirmed and t>(g.wait or .16)) then self.movePrediction=nil;return nil end
		-- Combat's drive: .32 + 1.18 sin(pi p) of the full step; stopped at the reach.
		local done=g.covered or 0
		local speed=g.full*(.32+1.18*math.sin(math.clamp(t/g.time,0,1)*math.pi))/g.time
		if done>=g.distance then return Vector3.zero end
		return g.dir*speed
	elseif g.kind=="Jump" then
		if actor.airborne then g.confirmed=true end
		if t>g.time or actor.reaction then self.movePrediction=nil;return nil end
		return Vector3.new(0,g.v0-g.g*t,0)
	end
	return nil
end
-- (É7) Where the two bodies will be when a press lands (`self.ahead` seconds
-- on): each drawn root carried on by its velocity. The guess reads these.
function Presentation:guessRoots()
	local me,them=self:visualRoot("human"),self:visualRoot("bot")
	local dt=self.ahead or 0
	if dt>0 and me and them then
		local mv=self.lead and self.lead.v or Vector3.zero
		local tv=self.smooth.bot and self.smooth.bot.vel or Vector3.zero
		me+=Vector3.new(mv.X,0,mv.Z)*dt;them+=Vector3.new(tv.X,0,tv.Z)*dt
	end
	return me,them
end
-- (É7) The stick as Brawler.intent reads it at the press: the strong push
-- now, else the latest one inside Config.Combo.IntentWindow (observeStick
-- keeps it every frame, as Brawler.observe does on the server).
function Presentation:lineToOpponent()
	local me,them=self:guessRoots()
	if not me or not them then return nil end
	local to=Vector3.new(them.X-me.X,0,them.Z-me.Z)
	return if to.Magnitude>.05 then to.Unit else nil
end
function Presentation:observeStick(now)
	local line=self:lineToOpponent()
	if not line then return end
	local dir,side=ActionContext.stick(self.inputDir or Vector3.zero,line,Config.Combo)
	if dir then self.stickMemory={dir=dir,side=side,at=now} end
end
function Presentation:stickIntent(now)
	local line=self:lineToOpponent() or (self.myLook and Vector3.new(self.myLook.X,0,self.myLook.Z).Unit) or Vector3.new(0,0,-1)
	local dir=ActionContext.stick(self.inputDir or Vector3.zero,line,Config.Combo)
	if dir then return dir end
	local m=self.stickMemory
	if m and now-m.at<=(Config.Combo.IntentWindow or .22) then return m.dir end
	return "neutral"
end
-- The world only (fighters and effects excluded), as the server's rays see it.
local function worldRay(data,from,delta)
	local exclude={}
	pcall(function()
		local character=game:GetService("Players").LocalPlayer.Character
		if character then table.insert(exclude,character) end
		local folder=character and character.Parent
		local bot=Presentation.opponent(data,folder);if bot then table.insert(exclude,bot) end
		local effects=folder and folder:FindFirstChild("Effects");if effects then table.insert(exclude,effects) end
		local fx=workspace:FindFirstChild("NinjaDuelFX");if fx then table.insert(exclude,fx) end
	end)
	local ok,hit=pcall(function()
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances=exclude
		return workspace:Raycast(from,delta,params)
	end)
	return if ok then hit else nil
end
-- A surface at the opponent's back on this body's line (Server/Perception's
-- behindTarget): the same ray, from his root along the line.
function Presentation:wallBehind(me,them,data)
	local line=Vector3.new(them.X-me.X,0,them.Z-me.Z)
	if line.Magnitude<=.05 then return nil end
	local hit=worldRay(data,them,line.Unit*((Config.Perception and Config.Perception.Behind) or 14))
	if hit and math.abs(hit.Normal.Y)<.5 and ActionContext.surface(hit.Instance) then return hit.Distance end
	return nil
end
-- (É7) When the airborne body touches down (a ballistic fall from its height
-- over the floor below and its vertical speed): an air press landing after
-- that is a ground press.
local STAND_HEIGHT=3
function Presentation:landIn(data)
	local h=data.human
	if not h.airborne then return 0 end
	local me=self:visualRoot("human")
	if not me then return math.huge end
	local hit=worldRay(data,me,Vector3.new(0,-80,0))
	if not hit then return math.huge end
	local height=math.max(0,me.Y-(hit.Position.Y+STAND_HEIGHT))
	local vy=h.velocity and h.velocity.Y or 0
	local g=workspace.Gravity or 196.2
	-- (an air string holds the body up first: it falls from where it hangs)
	local hold=h.guess and h.guess.airHoldLeft or 0
	if hold>0 then vy=0 end
	return hold+(vy+math.sqrt(vy*vy+2*g*height))/g
end
-- (É7) The opener the server will pick from the body's situation: the same
-- shared reader (ActionContext) fed with what this client draws. Returns
-- (move or nil, known): known=false when the client cannot read it (no
-- opponent drawn).
function Presentation:situational(data,def,graph,now,only)
	local me,them=self:guessRoots()
	local bot=data and data.bot
	local h=data and data.human
	if not me or not them or not bot then return nil,false end
	-- Under an illusion the server reads the image the body believes in.
	local fooled=h and (h.illusion or 0)>0 and h.decoy
	if fooled then them=h.decoy end
	local to=Vector3.new(them.X-me.X,0,them.Z-me.Z)
	local line=if to.Magnitude>.05 then to.Unit else Vector3.new(0,0,-1)
	local lead=self.lead and self.lead.v or Vector3.zero
	local vy=h and h.velocity and h.velocity.Y or 0
	local x=ActionContext.read({pos=me,look=self.myLook or line,vel=Vector3.new(lead.X,vy,lead.Z),airborne=h and h.airborne,
		target={pos=them,look=if fooled then me-them else (bot.lookVector or -line),airborne=bot.airborne and not fooled,
			down=bot.reaction=="Knockdown" or bot.reaction=="Wakeup" or bot.groundPose~=nil,guarding=bot.state=="Guarding"}})
	local light=Attacks.Light1
	local profile=def and def.AttackProfile and def.AttackProfile.Light1
	x.plainReach=light.travel*(def and def.CombatTravel or 1)*(profile and profile.travel or 1)+(profile and profile.contact or light.contact or 3.6)+1
	x.stick=self:stickIntent(now or os.clock())
	if not fooled then x.wallBehind=self:wallBehind(me,them,data) end
	return (ActionContext.resolve(x,graph,Attacks,only)),true
end
-- (É7) The strike a press will start, read the way Brawler.request reads it,
-- in the same order, from the body as it will be when the press lands
-- (viewAt) and what this client draws. nil: no strike, a buffered press, or
-- a branch the client cannot read (a counter stance, an awakened riposte...).
function Presentation:guessGround(action,v,def,graph,data,now)
	local bot=data.bot or {}
	if action=="Attack" and v.riposte then
		-- a riposte (not a counter stance's answer, not an awakened one)
		if v.counter>0 or (v.awaken or 0)>0 then return nil end
		if v.state=="Guarding" or v.state=="Neutral" or v.state=="Dodging" or v.state=="Recovery" then return graph.riposte or "Riposte" end
	end
	local canChain,arrival=v.chainReady,v.arrival
	-- committed: the press waits (buffered) and starts nothing now
	if v.state~="Neutral" and v.state~="Guarding" and not canChain and not arrival then return nil end
	if action=="Attack" and graph.readCounter and v.counter>0 and not canChain then return nil end
	local alive=v.stringAlive
	local inChain=canChain and alive
	local reentry=arrival and v.state~="Dodging"
	local vel=self.lead and self.lead.v or Vector3.zero
	local speed=Vector3.new(vel.X,0,vel.Z).Magnitude
	local running=not canChain and not arrival and v.state=="Neutral" and self.inputSprint and speed>28
	-- (a run still building or fading as the press lands: the server may read
	-- either side of its threshold)
	if not canChain and not arrival and v.state=="Neutral" and self.inputSprint and (self.ahead or 0)>0 then
		local pushing=Vector3.new((self.inputDir or Vector3.zero).X,0,(self.inputDir or Vector3.zero).Z).Magnitude>=.45
		if running~=(pushing and speed>28) or (pushing and speed<=28) or (not pushing and speed>8) then return "?" end
	end
	if running then
		if action=="Attack" then return "Light1" end
		local m=graph.runStrike or "DashAttack"
		return if Attacks[m] then m else "FlyingKick"
	end
	local combo=v.combo
	if action=="Heavy" then
		if inChain and combo==1 and graph.heavyAfterOne then return graph.heavyAfterOne end
		if inChain and combo>=2 then return def and def.LauncherMove or "Launcher" end
		if reentry and graph.heavyAfterOne and bot.reaction~="WallSplat" then return graph.heavyAfterOne end
		return def and def.HeavyMove or "Heavy"
	end
	local routes=graph.routes or {}
	if inChain or (alive and v.state=="Neutral") then
		local dir=self:stickIntent(now)
		local route=if combo<2 then nil elseif dir=="forward" then routes.up elseif dir=="back" then routes.down elseif dir=="side" then routes.side else nil
		if route and Attacks[route] then return route end
	end
	-- (EMB-002) inside a string a surface at his back is the drive into it
	if inChain and combo>=1 then
		local move,known=self:situational(data,def,graph,now,WALL_ONLY)
		if not known then return nil end
		if move then return move end
	end
	if not alive then combo=0 end
	if not inChain and not arrival then
		local move,known=self:situational(data,def,graph,now)
		if not known then return nil end
		if move then return move end
	end
	local name=lightName(combo,v.fighterId)
	if name=="Light3" and def and def.GentleFist and (bot.tenketsu or 0)>=3 then return "PalmThrust" end
	if arrival then return "DashAttack" end
	return name
end
function Presentation:guessAir(action,v,def,graph,data,now)
	local bot=data.bot or {}
	local canChain,arrival=v.chainReady,v.arrival
	if v.state~="Neutral" and v.state~="Guarding" and not canChain and not arrival then return nil end
	if action=="Attack" and graph.readCounter and v.counter>0 and not canChain then return nil end
	local airCombo=v.airCombo
	local targetUp=(bot.health or 1)>0
	if action=="Heavy" then
		if v.lion and targetUp then return "Slam" end
		if airCombo>=1 or v.airRecent then return "Slam" end
		return def and def.AirHeavy or "AirFlip"
	end
	local routes=graph.routes or {}
	if (canChain or v.state=="Neutral") and v.airAlive and airCombo>=1 then
		local dir=self:stickIntent(now)
		local route=if dir=="forward" then routes.airUp elseif dir=="back" then routes.airDown elseif dir=="side" then routes.airSide else nil
		if route then return route end
	end
	if not v.airAlive then
		airCombo=0
		local me,them=self:guessRoots()
		if not me or not them then return nil end
		-- (Audit 03/11) Only the flat motion is read ahead, and the body falls
		-- through the trip: near the edge of the dive's height (a few studs
		-- lower changes the answer), the server decides alone.
		local dive=ActionContext.airDive(me,them)
		if targetUp and not bot.airborne and dive~=ActionContext.airDive(me-Vector3.new(0,3,0),them) then return nil end
		if targetUp and not bot.airborne and dive then return "WallDive" end
		local move,known=self:situational(data,def,graph,now)
		if not known then return nil end
		if move and Attacks[move] and move==(((graph.context or {}).drop) or "DropStrike") then return move end
	end
	return if airCombo%2==0 then "Air1" else "Air2"
end
function Presentation:predictStrike(action,data,now,ahead)
	local h=data and data.human
	if not h or h.reaction or h.wall or h.groundPose or (h.health or 1)<=0 or (h.guess and h.guess.held) then return end
	local g=h.guess or {}
	-- (É7) branches ahead of the strike the client leaves to the server: a
	-- held body state, a teleport's arrival strike, a grab's throw, a blade
	-- still leaving the hand, a counter stance.
	if h.bodyState or g.flash or g.grab or (action=="Attack" and g.stance) then return end
	if h.throwKind and (h.throwElapsed or 99)<(h.throwRelease or .1) then return end
	now=now or os.clock()
	ahead=ahead or self:pressAhead(data)
	local def=Fighters[h.fighterId]
	local graph=MoveGraphs[h.fighterId] or {}
	local land=if h.airborne and ahead>0 then self:landIn(data) else math.huge
	local guess=self:steady(ahead,function(dt)
		if dt>=land then return "?" end
		-- a press already waiting may fire first: this one would land behind it
		if g.buffered and dt>0 then return "?" end
		self.ahead=dt
		local v=Presentation.viewAt(h,dt)
		local m=if h.airborne then self:guessAir(action,v,def,graph,data,now) else self:guessGround(action,v,def,graph,data,now)
		return m or false
	end)
	self.ahead=nil
	if not guess or not Attacks[guess] then return end
	self.prediction={name=guess,at=os.clock(),serial=h.attackSerial or 0,wait=math.max(.25,ahead+.15)}
	local spec=Attacks[guess]
	local prof=Fighters[h.fighterId] and Fighters[h.fighterId].AttackProfile
	prof=prof and (prof[guess] or prof[spec.clip or ""]) or {}
	self.strikeGuess={name=guess,at=os.clock(),contact=spec.startup*(prof.startup or 1),reach=(prof.contact or spec.contact or 3.6)+1.1}
	-- (É7) its step-in too, on the ground: the body closes on the opponent from
	-- the press, on the server's own drive curve, stopping at the strike's reach.
	local me,them=self:visualRoot("human"),self:visualRoot("bot")
	if not h.airborne and me and them and (spec.travel or 0)>0 then
		local to=Vector3.new(them.X-me.X,0,them.Z-me.Z)
		local room=to.Magnitude-(prof.contact or spec.contact or 3.6)
		local travel=math.min(spec.travel*(prof.travel or 1),math.max(0,room))
		local time=spec.startup*(prof.startup or 1)+spec.active*(prof.active or 1)
		if travel>.2 and to.Magnitude<11 and time>0 then
			self.movePrediction={kind="Strike",name=guess,at=os.clock(),dir=to.Unit,distance=travel,full=spec.travel*(prof.travel or 1),time=time,wait=math.max(.16,ahead+.1)}
		end
	end
end
-- (É7) The blow lands for the player when his drawn fist reaches the drawn
-- body, not ~1.5 ping later when the server's contact arrives: at the guessed
-- strike's contact time, if the opponent is in reach and open (not dodging,
-- guarding, down, spinning or out of the fight), the hit sound, shards and lens
-- kick play at once. The server's contact for that blow then plays its world
-- effects only (no second sound). A guarded or dodged blow is never guessed.
local CONTACT_STYLE={light=true,launcher=true,slam=true,finisher=true}
function Presentation.contactOpen(bot,myPos,theirPos,reach)
	if not bot or not myPos or not theirPos then return false end
	if (bot.health or 1)<=0 or bot.state=="Dodging" or bot.state=="Guarding" or bot.rotation or bot.counter and bot.counter>0 then return false end
	if bot.groundPose~=nil or bot.reaction=="Knockdown" or bot.reaction=="Wakeup" or bot.reaction=="Down" then return false end
	local d=theirPos-myPos
	if math.abs(d.Y)>3 then return false end
	return Vector3.new(d.X,0,d.Z).Magnitude<=reach
end
function Presentation:localContact(data,myPos,theirPos,now)
	local g=self.strikeGuess
	if not g or g.checked or now-g.at<g.contact then return nil end
	g.checked=true
	if now-g.at>g.contact+.2 then return nil end
	if not Presentation.contactOpen(data and data.bot,myPos,theirPos,g.reach) then return nil end
	local style=if g.name=="Heavy" then "launcher" else "light"
	local at=myPos:Lerp(theirPos,.7)+Vector3.new(0,.6,0)
	self.localHit={at=now,style=style,position=at}
	return self.localHit
end
function Presentation:applyPrediction(actor,now)
	local g=self.movePrediction
	if g and g.kind=="Dodge" and not g.confirmed and actor.state~="Dodging" and now-g.at<=(g.wait or .16) then
		-- The dodge's body from the press (the server's Dodging follows); out
		-- of a blow it has already stepped out of it.
		local v=table.clone(actor)
		v.state="Dodging";v.velocity=g.dir*35;v.dodge=math.max(0,g.time-(now-g.at))
		if g.fromReaction then v.reaction=nil;v.reactionElapsed=nil end
		return v
	end
	local p=self.prediction
	if not p then return actor end
	if (actor.attackSerial or 0)~=p.serial then
		self.prediction=nil
		if actor.attackName==p.name then
			local clock=self.clocks.human
			if not clock then clock={};self.clocks.human=clock end
			clock.attackName=actor.attackName;clock.attackSerial=actor.attackSerial or 0;clock.attackAt=p.at
		end
		return actor
	end
	if now-p.at>(p.wait or .25) or actor.reaction then self.prediction=nil;return actor end
	local v=table.clone(actor)
	v.attackName=p.name;v.state="Startup";v.attackSerial=-1-p.serial;v.attackElapsed=now-p.at
	return v
end
-- The server's root for this frame from the snapshot: its position when the
-- snapshot was taken, carried forward by its velocity over the snapshot's age
-- (at most 0.1 s: a late packet is not extrapolated into a wall). Facing from
-- the snapshot's look vector, carried by its turn rate the same way (fluidity
-- audit 05/11: held for a whole packet, a turn at 1440-2400 deg/s was drawn
-- in steps of 48-80 deg). A turn faster than TURN_MAX is a facing written at
-- once (a reaction, a teleport): not carried. Falls back to the replicated
-- root. `at` (server time) defaults to now.
local TURN_MAX=45
function Presentation.snapshotRoot(data,actor,fallback,at)
	if not actor.position or not data.serverNow then return fallback end
	local age=math.clamp((at or workspace:GetServerTimeNow())-data.serverNow,0,.1)
	local v=actor.velocity
	local p=actor.position
	if typeof(v)=="Vector3" and v.Magnitude<200 then
		-- (Probe 03/11: a landing drawn 4 studs under the floor, then popped
		-- up) Carried on flat; in the air the fall bends with gravity and
		-- stops at the floor under it; on the ground, no vertical guess.
		p+=Vector3.new(v.X,0,v.Z)*age
		if actor.airborne then
			local y=v.Y*age-.5*(workspace.Gravity or 196.2)*age*age
			if y<0 then
				local floor=nil
				pcall(function()
					local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
					local exclude={}
					local character=game:GetService("Players").LocalPlayer.Character
					if character then table.insert(exclude,character) end
					local folder=character and character.Parent
					local bot=Presentation.opponent(data,folder);if bot then table.insert(exclude,bot) end
					local effects=folder and folder:FindFirstChild("Effects");if effects then table.insert(exclude,effects) end
					params.FilterDescendantsInstances=exclude
					local hit=workspace:Raycast(actor.position,Vector3.new(0,y-3,0),params)
					floor=hit and hit.Position.Y+2.9
				end)
				if floor then y=math.max(y,math.min(0,floor-actor.position.Y)) end
			end
			p+=Vector3.new(0,y,0)
		end
	end
	local look=actor.lookVector
	local flatLook=if typeof(look)=="Vector3" then Vector3.new(look.X,0,look.Z) else Vector3.zero
	if flatLook.Magnitude<.05 then return fallback.Rotation+p end
	local yaw=math.atan2(-flatLook.X,-flatLook.Z)
	local turn=actor.turn
	if type(turn)=="number" and math.abs(turn)<=TURN_MAX then yaw+=turn*age end
	return CFrame.new(p)*CFrame.Angles(0,yaw,0)
end
-- The velocity and turn rate the snapshot carries the body with at `at`
-- (what snapshotRoot adds per second; none once the packet is 0.1 s old).
local function anchorMotion(data,actor,at)
	if not data.serverNow then return Vector3.zero,0 end
	local age=math.clamp(at-data.serverNow,0,.1)
	if age>=.1 then return Vector3.zero,0 end
	local v=actor.velocity
	local out=Vector3.zero
	if typeof(v)=="Vector3" and v.Magnitude<200 then
		out=Vector3.new(v.X,0,v.Z)
		if actor.airborne then out+=Vector3.new(0,v.Y-(workspace.Gravity or 196.2)*age,0) end
	end
	local turn=actor.turn
	return out,if type(turn)=="number" and math.abs(turn)<=TURN_MAX then turn else 0
end
-- (Fluidity audit 05/11: 38-46 % of the packets moved the drawn body more than
-- 0.18 stud in a single frame, p90 0.44, up to 6; the screen showed 4-7 times
-- the velocity breaks of the server's own path, 85 % of them in plain neutral)
-- A new packet no longer moves the body by itself. From the frame it arrives,
-- the body leaves the course it was drawn on (its position and velocity) and
-- joins the new packet's course over BLEND_T, its velocity blending into the
-- packet's as its position does (projective velocity blending: C. Murphy,
-- "Believable Dead Reckoning for Networked Games", Game Engine Gems 2). Once
-- joined it is exactly on the packet's course: no lag piles up. The facing
-- joins the same way, at most BLEND_YAW_RATE: a 159 deg facing written at
-- once by the server (a hit reaction) turns over ~0.1 s, ~25 deg a frame. A
-- teleport (warp), a new duel or a gap over SETTLE_MAX studs still cuts.
local BLEND_T,BLEND_YAW_RATE,SETTLE_MAX=.066,math.rad(1500),8
local function wrapAngle(a) return (a+math.pi)%(2*math.pi)-math.pi end
local function yawOfCF(cf) local look=cf.LookVector;return math.atan2(-look.X,-look.Z) end
function Presentation:settleAnchor(key,data,actor,cf,dt,at)
	local all=self.settled
	if not all then all={};self.settled=all end
	local st=all[key]
	if not st then st={};all[key]=st end
	at=at or workspace:GetServerTimeNow()
	local pos,yaw=cf.Position,yawOfCF(cf)
	-- (A body on a wall can face up it: no yaw to blend, its rotation is kept.)
	local look=cf.LookVector
	local hasYaw=Vector3.new(look.X,0,look.Z).Magnitude>.05
	if data.serverNow~=st.serverNow then
		local same=st.data~=nil and st.epoch==data.epoch and st.warp==(actor.warpSerial or 0) and st.drawn~=nil
		if same and (st.drawn-pos).Magnitude<=SETTLE_MAX then
			-- The velocity the body was being carried with (not its drawn
			-- velocity: that one holds the last blend's own correction, and
			-- feeding it back made the course oscillate).
			local v0,w0=anchorMotion(st.data,st.actor,at)
			local old=st.blend
			if old then
				local e=math.max(0,at-old.t0)
				local tau=math.clamp(e/BLEND_T,0,1)
				local tauY=math.clamp(e/old.ty,0,1)
				v0=old.v0+(v0-old.v0)*tau
				w0=old.w0+(w0-old.w0)*tauY
			end
			-- (From the last drawn frame: on this one the body already moves on.)
			st.blend={t0=at-dt,p0=st.drawn,v0=v0,y0=st.drawnYaw,w0=w0,
				ty=if st.drawnYaw then math.max(BLEND_T,math.abs(wrapAngle(yaw-st.drawnYaw))/BLEND_YAW_RATE) else BLEND_T}
		else
			-- A cut: drawn where the packet is.
			st.blend=nil
		end
		st.serverNow=data.serverNow;st.data=data;st.actor=actor;st.epoch=data.epoch;st.warp=actor.warpSerial or 0
	end
	local outPos,outYaw=pos,yaw
	local b=st.blend
	if b then
		local e=math.max(0,at-b.t0)
		local vNew,wNew=anchorMotion(data,actor,at)
		local tau=math.clamp(e/BLEND_T,0,1)
		if tau<1 then
			local vb=b.v0+(vNew-b.v0)*tau
			local course=b.p0+vb*e
			outPos=course+(pos-course)*tau
			-- (A fall caught by a landing between two packets: the old course
			-- still goes down, the packet's is on the floor; never under both.)
			outPos=Vector3.new(outPos.X,math.max(outPos.Y,math.min(pos.Y,b.p0.Y)),outPos.Z)
		end
		local tauY=math.clamp(e/b.ty,0,1)
		if tauY<1 and hasYaw and b.y0 then
			local wb=b.w0+(wNew-b.w0)*tauY
			local course=b.y0+wb*e
			outYaw=course+wrapAngle(yaw-course)*tauY
		end
		if tau>=1 and tauY>=1 then st.blend=nil end
	end
	st.drawn=outPos;st.drawnYaw=if hasYaw then outYaw else nil
	if outPos==pos and outYaw==yaw then return cf end
	-- The packet's own rotation turned about the vertical: a lean or a pitch
	-- it carries is kept.
	return CFrame.new(outPos)*CFrame.fromAxisAngle(Vector3.yAxis,wrapAngle(outYaw-yaw))*cf.Rotation
end
-- Just before rendering: the replicated roots have their positions for this
-- frame; advance each track and draw the body on it (position and facing).
function Presentation:smoothStep(data,dt)
	if not data or data.phase~="Duel" then return end
	local character=game:GetService("Players").LocalPlayer.Character
	local folder=character and character.Parent
	for key,model in {human=character,bot=Presentation.opponent(data,folder)} do
		local root=model and model:FindFirstChild("HumanoidRootPart")
		local actor=data[key]
		-- (Audit 29/10) Anchored roots too: the final blow's flight moves an
		-- anchored root, and an untracked one froze the camera (and the look)
		-- on the impact point while the body flew off.
		if root and actor then
			-- The true replicated pose: if the root still sits exactly where we
			-- drew it last frame, no new packet arrived since.
			local st=self.smooth[key]
			local actualCF=root.CFrame
			if st and st.drawnCF and st.replicatedCF and (actualCF.Position-st.drawnCF.Position).Magnitude<1e-3
				and actualCF.LookVector:Dot(st.drawnCF.LookVector)>.99999 then actualCF=st.replicatedCF end
			-- (Tutorial probe 02/11, Lion run) Roblox's replicated root ran 370 ms
			-- (10 studs, up to 18) behind the server through a jump, 60-130 ms in
			-- a chase or a run: the body was drawn late, then caught up in jumps.
			-- The snapshot carries the server's own root and the time it was
			-- taken (30 Hz): the track follows that, carried to the present by
			-- its velocity.
			actualCF=Presentation.snapshotRoot(data,actor,actualCF)
			-- (Fluidity audit 05/11) and a new packet settles in instead of
			-- moving the body in one frame.
			actualCF=self:settleAnchor(key,data,actor,actualCF,math.max(dt,1/240))
			local drawn=self:smoothRoot(key,actualCF,math.max(dt,1/240),actor.warpSerial)
			-- (Audit 04/11) a watched tournament match: the body is the AI's own.
			if key=="human" and not data.spectate then drawn=self:leadLocal(actor,drawn,math.max(dt,1/240)) end
			st=self.smooth[key]
			st.replicatedCF=actualCF
			-- (Tutorial probe 03/11: 12-19 pops per fighter, 3-9 studs in one
			-- frame) A packet that disagrees with where the body was drawn (an
			-- extrapolation past a landing, a dive or a dash started between two
			-- packets) moved the body in a single frame. The drawn root now
			-- covers at most a body's top speed per frame; the rest is caught up
			-- over the next frames. A declared warp still snaps.
			local step=math.max(dt,1/240)
			if st.drawnCF and st.capWarp==actor.warpSerial then
				local v=actor.velocity
				local speed=math.max(actor.speed or 0,if typeof(v)=="Vector3" then v.Magnitude else 0)
				local cap=math.max(80,speed*1.4)*step
				local d=drawn.Position-st.drawnCF.Position
				if d.Magnitude>cap and d.Magnitude<TRACK_SNAP then drawn=drawn.Rotation+(st.drawnCF.Position+d.Unit*cap) end
				-- (Studio 06/11, after the packet blend) A body leaving a wall for
				-- its dive still turned 51-64 deg in one frame: the wall pose has no
				-- yaw to blend. The drawn rotation turns at most ROT_CAP a second,
				-- the server's own fastest turn (a rush, 2400 deg/s); the rest
				-- follows over the next frames.
				local _,turned=(st.drawnCF.Rotation:Inverse()*drawn.Rotation):ToAxisAngle()
				turned=math.abs(turned)
				local most=ROT_CAP*step
				if turned>most then drawn=CFrame.new(drawn.Position)*st.drawnCF.Rotation:Lerp(drawn.Rotation,most/turned) end
			end
			st.capWarp=actor.warpSerial
			-- Draw the whole body on the track for this frame only; the next
			-- replication packet overwrites the client copy, never the server.
			local target=drawn
			-- (FEEL 05/11) Hit stop: the struck body holds where the blow met it
			-- and shakes along the blow (a few studs-tenths, 30 Hz), then its
			-- track catches up. Only a body this client does not simulate (the
			-- opponent): the player's own root is his physics.
			local now=os.clock()
			local isFrozen,f=self:frozen(key,now)
			if isFrozen and f.struck and key~="human" and st.drawnCF then
				f.hold=f.hold or st.drawnCF.Position
				local dir=f.dir
				if typeof(dir)~="Vector3" or dir.Magnitude<.05 then dir=target.RightVector end
				local fade=math.clamp((f.untilT-now)/math.max(f.untilT-f.from,1e-3),0,1)
				local wobble=math.sin((now-f.from)*2*math.pi*30)*f.amp*fade
				target=target.Rotation+(f.hold+Vector3.new(dir.X,0,dir.Z).Unit*wobble)
			elseif f and not isFrozen then f.hold=nil end
			if (target.Position-root.Position).Magnitude>1e-4 or target.LookVector:Dot(root.CFrame.LookVector)<.99999 then
				model:PivotTo(target*root.CFrame:Inverse()*model:GetPivot())
			end
			st.drawnCF=root.CFrame
		end
	end
end
-- Contact feed straight from the server: play the impact on the frame the hit
-- happened, so sound and VFX never lead or lag the animation.
function Presentation:impacts(data,camera)
 self.camera=camera or self.camera
 -- Projectiles first, so a contact in the same packet can finish its blade.
 if data.phase=="Duel" then self.fx:sync(data) end
 if not data.impacts then return end
 -- The server restarts its contact serial with every duel.
 if self.impactEpoch~=data.epoch then self.impactEpoch=data.epoch;self.impactSerial=0 end
 local serial=data.impactSerial or 0
 if serial<=self.impactSerial then return end
 local character=game:GetService("Players").LocalPlayer.Character
 local folder=character and character.Parent
 for _,impact in data.impacts do
  if impact.serial==nil or impact.serial>self.impactSerial then
   local lh=self.localHit
   local played=lh and not lh.used and data.bot and impact.victim==data.bot.id and CONTACT_STYLE[impact.style or ""] and os.clock()-lh.at<.4
   if played then lh.used=true;impact.tinted=true
   else
    Feedback.impact(impact.style or "light",impact.position,impact)
    if camera and camera.impulse then camera:impulse(impact.style,impact.role,impact) end
    -- (FEEL 05/11) the hit stop for a contact the client did not guess: both
    -- bodies hold, the struck one shakes (not on a guard: a guard is a stop
    -- for the attacker's arm only).
    if impact.victim and not impact.guarded and data.human and data.bot then
     local struck=if impact.victim==data.human.id then "human" elseif impact.victim==data.bot.id then "bot" else nil
     if struck then self:hitstop({human=struck=="human",bot=struck=="bot"},impact.style,impact.direction) end
    elseif impact.guarded then
     self:hitstop({human=false,bot=false},"block",impact.direction)
    end
   end
   self.fx:impact(impact,folder)
  end
 end
 self.impactSerial=serial
end
-- Genjutsu image. The server says who is deceived (illusion + decoy on that
-- actor). Seen by the deceived player, the image IS Itachi: a frozen copy in
-- his stance facing them, with a faint red outline pulsing now and then (the
-- tell), and the real body behind it drawn faint. Seen by Itachi's player, the
-- image is a red translucent afterimage of himself: he sees the trap he left.
function Presentation.fade(model,amount)
 if not model then return end
 for _,d in model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=amount end end
end
function Presentation:clearEcho()
 local echo=self.echo
 if not echo then return end
 if echo.model then echo.model:Destroy() end
 if echo.mode=="deceived" then Presentation.fade(echo.source,0) end
 self.echo=nil
end
-- Which view of the genjutsu this client draws: "deceived" (my fighter is
-- under it), "caster" (the opponent is under mine) or nil.
function Presentation.illusionView(data)
 if not data or data.phase~="Duel" then return nil end
 if data.human and (data.human.illusion or 0)>0 and data.human.decoy then return "deceived",data.human.decoy end
 if data.bot and (data.bot.illusion or 0)>0 and data.bot.decoy then return "caster",data.bot.decoy end
 return nil
end
function Presentation:illusion(data,model)
 local folder=model and model.Parent
 local opponent=Presentation.opponent(data,folder)
 local mode,decoy=Presentation.illusionView(data)
 local source=if mode=="deceived" then opponent elseif mode=="caster" then model else nil
 local watcher=if mode=="deceived" then model else opponent
 if not source then mode=nil end
 local echo=self.echo
 if echo and (echo.mode~=mode or echo.epoch~=data.epoch or echo.source~=source) then self:clearEcho();echo=nil end
 if not mode then return end
 if not echo then
  echo={mode=mode,epoch=data.epoch,source=source,model=self.fx:image(source,mode),born=os.clock()}
  self.echo=echo
 end
 if mode=="deceived" then Presentation.fade(source,.55) end
 local image=echo.model
 if not image then return end
 local root=watcher and watcher:FindFirstChild("HumanoidRootPart")
 local look=if root then Vector3.new(root.Position.X-decoy.X,0,root.Position.Z-decoy.Z) else Vector3.zero
 if look.Magnitude<.1 then look=Vector3.zAxis end
 local t=os.clock()-echo.born
 local at=decoy+Vector3.new(0,math.sin(t*5)*.03,0)
 image:PivotTo(CFrame.lookAt(at,at+look.Unit))
 local tell=image:FindFirstChild("Tell")
 if tell then tell.OutlineTransparency=1-.45*math.max(0,math.sin(t*7))^8 end
end
-- Local presentation clocks: an attack animates from the frame it was first
-- seen, so a late or jittery packet cannot make the body jump backwards.
local function clockFor(self,key,actor,now)
 local clock=self.clocks[key]
 if not clock then clock={};self.clocks[key]=clock end
 -- (FEEL 05/11) Hit stop: the clips hold on the contact frame, then resume
 -- from it (their start moves forward by the time they were held).
 local frozen=self:frozen(key,now)
 if frozen then
  clock.heldFrom=clock.heldFrom or now
 elseif clock.heldFrom then
  local held=now-clock.heldFrom
  clock.heldFrom=nil
  if clock.attackAt then clock.attackAt+=held end
  if clock.reactionAt then clock.reactionAt+=held end
 end
 local at=clock.heldFrom or now
 -- A new swing restarts the clock even when it repeats the same move name.
 if actor.attackName~=clock.attackName or (actor.attackSerial or 0)~=clock.attackSerial then
  -- Start the clip where the server already is: a snapshot arrives up to an
  -- interval late, and a clip restarted at 0 trailed the real contact (the
  -- launcher's kick was cut off by the chase before it ever showed).
  clock.attackName=actor.attackName;clock.attackSerial=actor.attackSerial or 0
  clock.attackAt=now-math.clamp(actor.attackElapsed or 0,0,.12)
 end
 -- A fresh contact restarts the recoil even when it repeats the same reaction
 -- kind (Light1 -> Light2 are both HitStun), so every hit reads as a hit.
 if actor.reaction~=clock.reaction or (actor.reaction and (actor.impactSerial or 0)~=clock.impactSerial) then
  clock.reaction=actor.reaction;clock.reactionAt=now
 end
 clock.impactSerial=actor.impactSerial or 0
 clock.attackElapsed=if actor.attackName then math.max(0,at-clock.attackAt) else 0
 clock.reactionElapsed=if actor.reaction then math.max(0,at-clock.reactionAt) else 0
 return clock
end
-- A landing belongs to one body. Opponent landings must never bend the
-- player's knees; keep a local phase so compression releases before neutral.
function Presentation:landing(key,actor,previous,now)
 if previous and previous.airborne and not actor.airborne then
  self.landings[key]={at=now,duration=if actor.landStrong then .22 else .1,strong=actor.landStrong==true,pending=true}
 end
 local landing=self.landings[key]
 if not landing then return false,0,false end
 -- (Audit 29/10) The server says "landed" before the drawn body gets there
 -- (it is drawn ~45 ms behind its replicated root): at a fall's speed the
 -- crouch began two studs up in the air. It starts when the drawn body
 -- reaches the floor it landed on (or after 0.12 s at most).
 if landing.pending then
  local drawn=self.visualRoot and self:visualRoot(key)
  local floor=actor.position and actor.position.Y
  if drawn and floor and drawn.Y-floor>.35 and now-landing.at<.12 then return false,0,false end
  landing.pending=nil;landing.at=now
 end
 if actor.airborne or now>=landing.at+landing.duration then
  self.landings[key]=nil
  return false,0,false
 end
 return true,math.clamp((now-landing.at)/landing.duration,0,1),landing.strong
end
function Presentation:update(data,dt)
 dt=math.max(dt or 1/60,.001)
 -- One presentation tick per rendered frame; every pose below reads this clock.
 Motion.tick(dt)
 local players=game:GetService("Players")
 if not data.human then
  self:clearEcho()
  self.fx:update(data,dt,nil)
  self.bodies:update(data,dt,nil)
  return
 end
 if self.epoch~=data.epoch then
  -- Character switch, rematch or a fresh duel: the only place a hard reset is
  -- right. Normal presentation never snaps the skeleton.
  self.epoch=data.epoch
  table.clear(self.clocks);table.clear(self.last);table.clear(self.smooth);table.clear(self.landings)
  self.lead=nil;self.prediction=nil;self.movePrediction=nil;self.strikeGuess=nil;self.localHit=nil;table.clear(self.freeze)
  self.smears={}
  if players.LocalPlayer.Character then Motion.reset(players.LocalPlayer.Character) end
  if self.botModel then Motion.reset(self.botModel) end
 end
 local now=os.clock()
 local character=players.LocalPlayer.Character
 self:illusion(data,character)
 local folder=character and character.Parent
 local bot=Presentation.opponent(data,folder)
 self.botModel=bot
 local models={human=character,bot=bot}
 for key,model in models do
  local actor=data[key];local previous=self.last[key]
  if model and actor then
   -- The motion engine owns every joint. A Humanoid Animator (run locally for
   -- the player's own character) resets the joints between our write and the
   -- render, which left the body in its rest pose; remove it on this client.
   local humanoid=model:FindFirstChildOfClass("Humanoid")
   local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
   if animator then animator:Destroy() end
   if key=="human" then
    actor=self:applyPrediction(actor,now)
    local me=model:FindFirstChild("HumanoidRootPart")
    if me then self.myLook=me.CFrame.LookVector end
    local them=bot and bot:FindFirstChild("HumanoidRootPart")
    local hit=self:localContact(data,me and me.Position,them and them.Position,now)
    if hit then
     Feedback.impact(hit.style,hit.position,{victim=data.bot and data.bot.id,predicted=true})
     if self.camera and self.camera.impulse then self.camera:impulse(hit.style,"attacker",{predicted=true}) end
     -- (FEEL 05/11) the blow lands on the frame the fist arrives: both bodies
     -- hold, the struck one flashes and shakes along the strike.
     local dir=if me and them then Vector3.new(them.Position.X-me.Position.X,0,them.Position.Z-me.Position.Z) else nil
     self:hitstop({human=false,bot=true},hit.style,dir,now)
     local flash=FLASH[hit.style]
     if flash and bot then pcall(Presentation.flash,bot,flash[1],flash[2]) end
    end
   end
   local clock=clockFor(self,key,actor,now)
   local root=model:FindFirstChild("HumanoidRootPart")
   -- The body is drawn on a smoothed track of the replicated root (see
   -- Presentation:smoothStep, run just before each frame is rendered).
   -- Take-off and get-up sounds, from the state change itself.
   if previous and not previous.airborne and actor.airborne and root and root.AssemblyLinearVelocity.Y>15 and not actor.reaction then self.fx:jumpSound(root.Position) end
   if previous and previous.reaction=="Wakeup" and actor.reaction~="Wakeup" and root then self.fx:getUpSound(root.Position) end
   local landing,landingPhase,landingStrong=self:landing(key,actor,previous,now)
   -- Health lost without a new contact (burn, sand): a slow drain such as the
   -- curse mark (~0.1 HP per snapshot) is not a hit and spawns nothing.
   if previous and actor.health<=previous.health-1 and actor.impactSerial==(previous.impactSerial or -1) then
    local damage=previous.health-actor.health
    if root then Feedback.burst(root.Position,if actor.cue=="GUARDED" then Color3.fromRGB(255,235,160) else Color3.fromRGB(255,91,74),damage,actor.cue=="GUARDED") end
   end
   if actor.events and previous and actor.events.Parry and actor.events.Parry>(previous.parry or 0) then
    if root then Feedback.burst(root.Position,Color3.fromRGB(255,245,176),0,true) end
   end
   -- Locomotion is posed from the rig's live velocity, not a 10 Hz value.
   local tracked=self:visualVelocity(key)
   local velocity=if root then root.AssemblyLinearVelocity else actor.velocity
   if tracked and velocity then
    -- Wall motion is positioned by the server with zero assembly velocity.
    -- Its vertical cadence must follow the drawn track as well as its X/Z.
    velocity=Vector3.new(tracked.X,if actor.wall then tracked.Y else velocity.Y,tracked.Z)
   end
   local planar=if velocity then Vector3.new(velocity.X,0,velocity.Z).Magnitude else 0
   local speed=if key=="human" and self.lead then planar else math.max(actor.speed or 0,planar)
   -- Everything the presentation contract needs, with locally measured clocks so
   -- a late packet cannot make the body replay its wind-up.
   local visual=table.clone(actor)
   -- A dash is server-driven translation: pose it from its declared direction.
   visual.velocity=if actor.state=="Dodging" then actor.velocity else velocity
   visual.speed=speed
   visual.reactionElapsed=clock.reactionElapsed
   visual.attackElapsed=clock.attackElapsed
   visual.landing=landing;visual.landingPhase=landingPhase;visual.landStrong=landingStrong
   visual.intro=data.intro
   -- (Partie 2) The winner's pose after the K.O. and on the result screen.
   visual.victory=data.winner~=nil and (data.ko==true or data.phase=="Result") and (actor.health or 0)>0
    and ((key=="human")==(data.winner=="PlayerFighter"))
   local other=if key=="human" then "bot" else "human"
   visual.lookAt=self:visualRoot(other) or (data[other] and data[other].position)
   -- Throws and casts run on the shared server clock (slightly behind, like the
   -- projectiles), so the blade leaves the hand on the frame it starts flying.
   if data.serverNow then
    local visualNow=workspace:GetServerTimeNow()-Effects.DELAY
    if actor.throwElapsed then visual.throwElapsed=visualNow-(data.serverNow-actor.throwElapsed) end
    if actor.castElapsed then visual.castElapsed=workspace:GetServerTimeNow()-(data.serverNow-actor.castElapsed) end
    if actor.channel then visual.channel=math.max(0,actor.channel-(workspace:GetServerTimeNow()-data.serverNow)) end
   end
   Motion.weapon(model,visual)
   self.presented=self.presented or {}
   self.presented[key]=string.format("%s hp=%s state=%s",tostring(Motion.present(model,visual,clock,dt)),tostring(visual.health),tostring(visual.state))
   -- Speed smear (fluidity pass): faster than a sprint, or a teleport, is
   -- drawn as motion. Not during an intro or between rounds (repositioning).
   self.smears=self.smears or {}
   self.smears[key]=self.smears[key] or {}
   if data.phase=="Duel" and (data.intro or 0)<=0 then Smear.step(self.smears[key],model,dt) else self.smears[key]={} end
   self.arcs=self.arcs or {}
   self.arcs[key]=self.arcs[key] or {}
   Smear.limbs(self.arcs[key],model,actor.attackName~=nil and (actor.state=="Startup" or actor.state=="Active"))
   self.last[key]={health=actor.health,attackName=actor.attackName,parry=actor.events and actor.events.Parry or 0,
    impactSerial=actor.impactSerial or 0,airborne=actor.airborne,reaction=actor.reaction}
  end
 end
 self.fx:update(data,dt,folder)
 self.bodies:update(data,dt,folder)
end
return Presentation
