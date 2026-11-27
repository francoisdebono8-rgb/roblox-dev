-- The walker's body in Konoha, moving like a ninja (23/11, step 4, DEC-048;
-- François after step 3: « la course ninja, le double saut, le mur, ce n'est
-- pas du tout ninja feel », « tout doit être dans cet esprit »).
--
-- In the village only, Roblox's default walk is replaced by the kit's own
-- authored clips (Client/AuthoredMotion, the duel's: <kit>.Idle, Walk.F,
-- Run.F, Sprint, Jump.Air, AirJump, Land, and the ninja parkour authored once
-- on Lion, Parkour.Leap / Vault / LandRoll / LandHard), written on his own
-- avatar's R15 joints every frame after the Animator: nothing to publish.
--   * the gait follows the ground covered (the planted foot's share of the
--     clip's stride, as Client/KonohaFolkFX and the engine do): no glide;
--   * the run up a wall is the anime's: the body leans back off the wall, the
--     feet on it, the sprint's legs running up;
--   * the second jump plays the kit's AirJump, a kick off a wall the parkour
--     leap, the hop over a roof's edge the vault;
--   * a landing from high plays the roll (moving) or the hard landing (still).
-- An avatar that is not R15, or a kit without its clips, keeps Roblox's walk.
-- Client/HubMove (the body's movement) steps it with the frame's facts.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local Body={}
Body.__index=Body
Body.STRIDE=.7                 -- the planted foot's share of a clip's stride
Body.WALK_BELOW=20             -- world studs/s: under it the walk, then the run
Body.SPRINT_ABOVE=25           -- over it the sprint (HubMove.RUN is 30 on the ground)
Body.STILL=1.5                 -- under it he stands
Body.ROLL_FALL=62              -- landing faster than this down: the roll or the hard landing
Body.ROLL_MOVING=14            -- the roll when he still moves this fast, else the hard landing
Body.WALL_TILT=math.rad(70)    -- the body off the wall, the feet on it
Body.WALL_BACK=1.4             -- studs the tilted body is moved off the wall
Body.BLEND=.12                 -- seconds to ease from one clip into the next
Body.VAULT=.35                 -- the hop over a roof's edge
Body.KICK=.45                  -- the leap after a kick off a wall
local MOTOR={Right="RightShoulder",Left="LeftShoulder"}

-- (26/11, passe 2, DEC-054: François, « des animations faites pour le
-- déplacement dans le village à plusieurs étapes de notre avatar »; the
-- ANIMATEUR's three stages, tools/blender/p2_loco.py) How he moves grows with
-- his kit's mastery (the player attribute NinjaMastery, Server/Hub.badge): the
-- novice (arms everywhere, stiff, eyes on his feet) until his tree's second
-- tier (300, Masters.Need), trained until its third (800, DEC-039), then his
-- kit's own way. No kit yet (the forest, the gate): the novice.
Body.TRAINED=300
Body.OWN=800
function Body.stage(kit,mastery)
	if type(kit)~="string" then return "Novice" end
	local m=tonumber(mastery) or 0
	if m<Body.TRAINED then return "Novice" end
	if m<Body.OWN then return "Trained" end
	return nil
end
-- The clip a kit plays for a gait or a move ("Sprint", "AirJump", "Parkour.Leap"...):
-- his stage's (Novice.Walk.F, Trained.Sprint) when there is one; standing in
-- Konoha, his kit's way of standing (<kit>.Rest: Kakashi's book, Sasuke's
-- pockets) before its guard (`rest`: he has a kit); else the kit's own, else
-- Sasuke's (AuthoredMotion's donor for the shared ones).
-- (27/11, the OUTILLEUR's kit bench: Gaara's heavy in the street was
-- Sasuke's spinning kick) A kit without a clip of its own for a strike plays
-- its own nearest strike first; then its motion family's (Fighters[kit].Motion:
-- its clips, then its body, as the duel's engine draws it); Lion last.
Body.STRIKE_NEAR={Heavy={"Light3","Light2","Light1"},Light3={"Light2","Light1"},Light2={"Light1"},Air1={"Light1"}}
local okFighters,Fighters=pcall(function() return require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters) end)
function Body.family(kit)
	local def=okFighters and Fighters and Fighters[tostring(kit)]
	local m=def and def.Motion
	local out={}
	for _,id in {m and m.clips,m and m.body} do
		if type(id)=="string" and id~=tostring(kit) and not table.find(out,id) then table.insert(out,id) end
	end
	return out
end
-- (27/11, François after playing: « la course de notre avatar est trop rapide
-- et pas assez ninja », his choice: « course ninja nette ») Before he masters
-- a kit, his run is a clean ninja run, leaning forward, the arms back, the
-- head up (the ANIMATEUR's tight ninja run, Lion's), not the novice's upright
-- flailing nor the trained athlete's pumping arms; the walk, the jumps and
-- the landings keep his stage.
Body.NINJA_RUN={["Run.F"]="Lion.Run.F",Sprint="Lion.Sprint"}
function Body.clipName(Authored,kit,move,stage,rest)
	local ninja=stage and Body.NINJA_RUN[move]
	if ninja and Authored.has(ninja) then return ninja end
	if stage and Authored.has(stage.."."..move) then return stage.."."..move end
	if rest and move=="Idle" and Authored.has(tostring(kit)..".Rest") then return tostring(kit)..".Rest" end
	local own=tostring(kit).."."..move
	if Authored.has(own) then return own end
	for _,near in Body.STRIKE_NEAR[move] or {} do
		local name=tostring(kit).."."..near
		if Authored.has(name) then return name end
	end
	for _,id in Body.family(kit) do
		local name=id.."."..move
		if Authored.has(name) then return name end
	end
	local donor="Lion."..move
	if Authored.has(donor) then return donor end
	-- (the emotes are everyone's: "Emote.Wave")
	if Authored.has(move) then return move end
	return nil
end

function Body.new(Authored)
	return setmetatable({Authored=Authored,phase=0,airborne=false,lastVy=0,landing=nil,current=nil,from=nil,blendAt=-10,tilt=0},Body)
end

-- (pure) The frame's choice: {move = the clip's move, t = its time, tilt = 0..1}.
-- `f`: {now, dt, speed (horizontal, world studs/s), vy, grounded, climbing,
-- climbSpeed, leapAt, kickAt, mantleAt, kit}.
function Body.choose(b,f)
	local A=b.Authored
	local function len(move)
		local name=Body.clipName(A,f.kit,move,f.stage,f.rest)
		return name and A.length(name) or 0
	end
	-- the landing: a fall from high is a roll (still running) or a hard landing
	if f.grounded and b.airborne then
		local fall=-(b.lastVy or 0)
		if fall>=Body.ROLL_FALL then
			b.landing={move=if f.speed>=Body.ROLL_MOVING then "Parkour.LandRoll" else "Parkour.LandHard",at=f.now}
		elseif fall>20 then
			b.landing={move="Land",at=f.now,short=.22}
		end
	end
	b.airborne=not f.grounded and not f.climbing
	b.lastVy=f.vy
	if b.landing then
		local l=b.landing
		local length=l.short or len(l.move)
		if f.grounded and f.now-l.at<length then return {move=l.move,t=f.now-l.at,tilt=0} end
		b.landing=nil
	end
	-- (26/11, passe 3, DEC-055) his kit in the street (Client/HubFightClient):
	-- the move plays through, over the walk; the guard is held on its pose
	if f.act=="Guard" and len("Guard")>0 and (f.actAt==nil or f.now-f.actAt<len("Guard")) then
		return {move="Guard",t=math.min(len("Guard")*.5,.25),tilt=0}
	end
	if f.act and f.actAt and f.act~="Guard" then
		local length=len(f.act)
		if length>0 and f.now-f.actAt<length then return {move=f.act,t=f.now-f.actAt,tilt=0} end
	end
	-- up the wall: the ANIMATEUR's wall run (23/11, Parkour.WallRun: long
	-- strides in the air, knees high, arms pumping), the body off the wall;
	-- the sprint's legs for a kit without it
	if f.climbing then
		local stride=b.strideOf and b:strideOf("Sprint") or 7
		b.phase+=(f.dt or 0)*(f.climbSpeed or 38)/math.max(stride*Body.STRIDE,1)
		local move=if len("Parkour.WallRun")>0 then "Parkour.WallRun" else "Sprint"
		return {move=move,t=(b.phase%1)*len(move),tilt=1}
	end
	if f.mantleAt and f.now-f.mantleAt<Body.VAULT then return {move="Parkour.Vault",t=f.now-f.mantleAt,tilt=0} end
	-- (23/11, step 5) an emote in the street: played while he stands, once
	if f.emote and f.emoteAt and f.grounded and f.speed<Body.STILL then
		local length=len(f.emote)
		if length>0 and f.now-f.emoteAt<length then return {move=f.emote,t=f.now-f.emoteAt,tilt=0} end
	end
	if not f.grounded then
		if f.kickAt and f.now-f.kickAt<Body.KICK then return {move="Parkour.Leap",t=f.now-f.kickAt,tilt=0} end
		local air=len("AirJump")
		if f.leapAt and f.now-f.leapAt<math.max(air,.3) then return {move="AirJump",t=f.now-f.leapAt,tilt=0} end
		-- the jump's own clip, held at the height of the arc: rising early, falling late
		local u=math.clamp((56-(f.vy or 0))/140,0,1)
		return {move="Jump.Air",t=u*len("Jump.Air"),tilt=0}
	end
	if f.speed<Body.STILL then return {move="Idle",t=f.now,tilt=0} end
	local move=if f.speed<Body.WALK_BELOW then "Walk.F" elseif f.speed<Body.SPRINT_ABOVE then "Run.F" else "Sprint"
	local stride=b.strideOf and b:strideOf(move) or 7
	b.phase+=(f.dt or 0)*f.speed/math.max(stride*Body.STRIDE,1)
	return {move=move,t=(b.phase%1)*len(move),tilt=0}
end

-- A gait clip's stride (world studs: its meta, else 7).
function Body:strideOf(move)
	self.strides=self.strides or {}
	local key=tostring(self.kit)..tostring(self.walkStage)..move
	if self.strides[key] then return self.strides[key] end
	local name=Body.clipName(self.Authored,self.kit,move,self.walkStage,self.rest)
	local clip=name and self.Authored.clip(name)
	local stride=(clip and clip.meta and clip.meta.stride) or 7
	self.strides[key]=stride
	return stride
end

-- The pose of a choice, eased from the last one when the clip changed, the
-- wall's tilt on the root. Returns {joint=CFrame}.
function Body:pose(choice,now)
	local name=Body.clipName(self.Authored,self.kit,choice.move,self.walkStage,self.rest)
	if not name then return nil end
	local pose=self.Authored.sample(name,choice.t)
	if not pose then return nil end
	if name~=self.current then
		self.from=self.last;self.blendAt=now;self.current=name
	end
	-- the tilt eases in and out with the clip
	local target=choice.tilt or 0
	local k=math.clamp((now-self.blendAt)/Body.BLEND,0,1)
	self.tilt=if target>0 then math.max(self.tilt*(1-k),target*k) else self.tilt*(1-k)
	if self.tilt>1e-3 and pose.Root then
		pose.Root=CFrame.new(0,0,Body.WALL_BACK*self.tilt)*CFrame.Angles(Body.WALL_TILT*self.tilt,0,0)*pose.Root
	end
	if self.from and k<1 then
		local out={}
		for joint,cf in pose do
			local a=self.from[joint]
			out[joint]=if a then a:Lerp(cf,k) else cf
		end
		pose=out
	end
	self.last=pose
	return pose
end

-- ------------------------------------------------------------------ in the game
-- (23/11, François: « je ne vois pas la course ninja, le double saut, la
-- course sur les murs ») Roblox now joins a player's avatar with
-- AnimationConstraints, not Motor6Ds (seen on his own avatar in Studio: 15
-- AnimationConstraints, no Motor6D). Both carry the same Transform, written
-- the same way: a body with only the old joints found nothing to pose, and
-- Roblox's own walk showed.
function Body.joints(character)
	local j={}
	for _,d in character:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
			if not j[d.Name] or d:IsA("Motor6D") then j[d.Name]=d end
		end
	end
	return j
end
local joints=Body.joints

-- One frame: HubMove's facts. Remembers the pose; it is written on the joints
-- after the Animator (PreSimulation), so Roblox's walk never shows.
function Body:step(character,hum,f)
	if not character or not hum then self.pending=nil;return end
	if hum.RigType~=Enum.HumanoidRigType.R15 then self.pending=nil;return end
	if self.character~=character then self.character=character;self.j=joints(character);self.strides=nil end
	-- (26/11, passe 3, seen in the game: after the gate's card, his body walked
	-- Roblox's own walk again and his kit's blows did not show) A character
	-- taken while Roblox still built it had no joint yet: looked for again
	-- until there are some (and when one went with a rebuilt part).
	local any=next(self.j or {})
	if not any or not self.j[any].Parent then self.j=joints(character) end
	local kit=f.kit or (Players.LocalPlayer and Players.LocalPlayer:GetAttribute("NinjaKit"))
	-- his stage, from his real kit and its mastery (the others': crowdFacts)
	local mastery=f.mastery
	if mastery==nil and f.kit==nil and Players.LocalPlayer then mastery=Players.LocalPlayer:GetAttribute("NinjaMastery") end
	local stage=Body.stage(kit,mastery)
	local rest=type(kit)=="string"
	if not (type(kit)=="string" and Body.clipName(self.Authored,kit,"Sprint")) then kit="Lion" end
	if kit~=self.kit or stage~=self.walkStage then self.kit=kit;self.walkStage=stage;self.strides=nil end
	self.rest=rest
	f.kit=kit;f.stage=stage;f.rest=rest
	local choice=Body.choose(self,f)
	self.pending=self:pose(choice,f.now)
	self.pendingAt=f.now
	if not self.connection then
		local event=RunService.PreSimulation or RunService.Stepped
		self.connection=event:Connect(function() self:write() end)
	end
end
function Body:write()
	local pose=self.pending
	-- a pose a quarter of a second old: the walk is not stepped (a duel, a
	-- menu): the Animator has the body again
	if not pose or os.clock()-(self.pendingAt or 0)>.25 then return end
	for joint,cf in pose do
		local m=self.j and self.j[MOTOR[joint] or joint]
		if m and m.Parent then m.Transform=cf end
	end
end
function Body:stop()
	self.pending=nil
	if self.connection then self.connection:Disconnect();self.connection=nil end
end

-- ------------------------------------------------------------ the other walkers
-- (23/11, step 5, DEC-049) What this client writes on joints stays on this
-- client: so each screen poses every walker near it, his own way. Speed and
-- height come with his body's physics; the ground by a ray under him; the
-- wall, the bound, the kick and the hop by his character's NinjaPose /
-- NinjaPoseSeq (Server/Hub.pose, sent by his own HubMove).
Body.CROWD_RANGE=160
Body.crowd=setmetatable({},{__mode="k"})
-- (pure) a walker's frame from what this screen sees of him; `w` keeps what
-- the previous frames saw (the pose's sequence and when each move began).
function Body.crowdFacts(w,now,dt,velocity,grounded,pose,seq,kit,emote,mastery,act,actSeq)
	if seq~=w.seq then
		w.seq=seq
		if pose=="leap" then w.leapAt=now elseif pose=="kick" then w.kickAt=now elseif pose=="vault" then w.mantleAt=now
		elseif pose=="emote" then w.emoteAt=now end
	end
	-- (26/11, passe 3) his kit's move in the street (Server/HubFight: NinjaAct, NinjaActSeq)
	if actSeq~=w.actSeq then
		if w.actSeq~=nil and type(act)=="string" then w.act,w.actAt=act,now end
		w.actSeq=actSeq
	end
	local clip=w.act and (require(game:GetService("ReplicatedStorage").NinjaDuel.HubFight).Moves[w.act] or {}).clip
	return {now=now,dt=dt,speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude,vy=velocity.Y,grounded=grounded and pose~="climb",
		climbing=pose=="climb",climbSpeed=38,leapAt=w.leapAt,kickAt=w.kickAt,mantleAt=w.mantleAt,kit=kit,mastery=mastery or 0,
		emote=if pose=="emote" then emote else nil,emoteAt=w.emoteAt,act=clip,actAt=if clip then w.actAt else nil}
end
function Body.poseOthers(Authored,dt,here)
	local me=Players.LocalPlayer
	local now=os.clock()
	local seen={}
	for _,player in Players:GetPlayers() do
		if player==me then continue end
		local character=player.Character
		local hum=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not (hum and root and hum.Health>0) or (here and (root.Position-here).Magnitude>Body.CROWD_RANGE) then continue end
		seen[character]=true
		local w=Body.crowd[character]
		if not w then w={body=Body.new(Authored)};Body.crowd[character]=w end
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character}
		local grounded=workspace:Raycast(root.Position,Vector3.new(0,-(hum.HipHeight+root.Size.Y/2+.6),0),params)~=nil
		local kit=player:GetAttribute("NinjaKit")
		local f=Body.crowdFacts(w,now,dt,root.AssemblyLinearVelocity,grounded,character:GetAttribute("NinjaPose"),character:GetAttribute("NinjaPoseSeq"),if type(kit)=="string" then kit else nil,character:GetAttribute("NinjaEmote"),player:GetAttribute("NinjaMastery"),
			character:GetAttribute("NinjaAct"),character:GetAttribute("NinjaActSeq"))
		pcall(w.body.step,w.body,character,hum,f)
	end
	for character,w in Body.crowd do
		if not seen[character] then w.body:stop();Body.crowd[character]=nil end
	end
end

return Body
