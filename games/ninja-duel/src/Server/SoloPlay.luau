-- The things to do alone in Konoha, on the server (21/11, étape 3 DEV 4,
-- DEC-047; François: « il n'y a rien à faire dans le village s'il n'y a
-- personne »). The rules are Shared/Solo's; here the walker's body is read,
-- the profile paid (Progression.solo) and the client told.
--   RACE      the prompt at the start post (action SoloRace): a countdown at
--             the post, then the rings in order, his body sampled ten times a
--             second; a time too fast, a jump across the map: no time.
--   TARGETS   the prompt at the mark (SoloTargets), then SoloThrow {direction}:
--             a kunai from his chest along it (Solo.hitBoard, server-side).
--   CHALLENGE an inspiration waits in a free street of the village for a
--             while; whoever accepts (SoloChallenge) fights him there
--             (Matches.challengeStart); the duel decided pays (challengeEnded).
-- What the client reads (Client/SoloView), attributes on the player:
--   NinjaSolo        "race" | "targets" | nil
--   NinjaSoloAt      the server time the clock starts (after the countdown)
--   NinjaSoloNext    the race's next ring
--   NinjaSoloUp      the boards still up, "1"/"0" each
--   NinjaSoloMisses  the targets missed
--   NinjaSoloEnd     the last end, "finish" | "done" | "fail:<why>", with
--   NinjaSoloTime NinjaSoloBest (hundredths) NinjaSoloGain (mastery) NinjaSoloNew
--   (a new best) and NinjaSoloSerial (one more each end: the client's cue).
-- And on the challenger's rig: NinjaChallenge (his kit), NinjaChallengeLine.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Solo=require(Shared.Solo)
local HubMap=require(Shared.HubMap)

local SoloPlay={}
SoloPlay.__index=SoloPlay
SoloPlay.SAMPLE=.1

function SoloPlay.new(matches,deps)
	deps=deps or {}
	local self=setmetatable({matches=matches,runs={},challenge=nil,nextChallenge=nil,nextSample=0,
		-- injected for the suite
		bodies=deps.bodies,pay=deps.pay,rig=deps.rig,random=deps.random or math.random,beaten=deps.beaten},SoloPlay)
	return self
end

-- His walker's root in the village, or nil.
function SoloPlay:root(player)
	local bodies=self.bodies or (function() local ok,Hub=pcall(function() return require(script.Parent.Hub) end);return ok and Hub.bodies or nil end)()
	local body=bodies and bodies[player]
	local character=body and body.character
	return character and character:FindFirstChild("HumanoidRootPart")
end
local function set(player,name,value) pcall(function() player:SetAttribute(name,value) end) end
local function clear(player)
	for _,name in {"NinjaSolo","NinjaSoloAt","NinjaSoloNext","NinjaSoloUp","NinjaSoloMisses"} do set(player,name,nil) end
end
local function upString(round)
	local out={}
	for i in Solo.Targets.boards do out[i]=if round.up[i] then "1" else "0" end
	return table.concat(out)
end
-- What a thing done paid, told to the client (`result`: Progression.solo's).
function SoloPlay:ended(player,what,time,result)
	-- (23/11, step 5) the test place's record: a race finished, or left
	local s=self.matches and self.matches.sessions and self.matches.sessions[player]
	if s then
		local TestLog=require(script.Parent.TestLog)
		if what=="finish" then TestLog.race(s,time)
		elseif type(what)=="string" and string.sub(what,1,5)=="fail:" then TestLog.quit(s,"race:"..string.sub(what,6)) end
	end
	set(player,"NinjaSoloEnd",what)
	set(player,"NinjaSoloTime",time)
	set(player,"NinjaSoloBest",result and result.best or nil)
	set(player,"NinjaSoloGain",result and result.amount or nil)
	set(player,"NinjaSoloNew",result and result.improved==true or nil)
	set(player,"NinjaSoloSerial",(player:GetAttribute("NinjaSoloSerial") or 0)+1)
end
function SoloPlay:payFor(player,kind,args)
	if self.pay then return self.pay(player,kind,args) end
	local ok,result=pcall(function() return require(script.Parent.Progression).solo(player,kind,args) end)
	return if ok then result else nil
end

-- ------------------------------------------------------------------ start, stop
-- Starts `kind` ("race" | "targets") at `now`: he must walk in the village, by
-- the post or the mark, free. Returns ok, why.
function SoloPlay:start(player,kind,now)
	local root=self:root(player)
	if not root then return false,"Not in the village" end
	local pos=root.Position
	local run
	if kind=="race" then
		local post=Solo.startPost()
		if (Vector3.new(pos.X,0,pos.Z)-Vector3.new(post.X,0,post.Z)).Magnitude>Solo.Race.startReach*(HubMap.Scale or 1)+4 then return false,"Too far from the post" end
		run=Solo.newRun(now,pos)
	elseif kind=="targets" then
		if not Solo.atMark(pos) then return false,"Too far from the mark" end
		run=Solo.newTargets(now)
	else
		return false,"Unknown"
	end
	self.runs[player]=run
	set(player,"NinjaSolo",kind)
	set(player,"NinjaSoloAt",run.at)
	if kind=="race" then set(player,"NinjaSoloNext",1) else set(player,"NinjaSoloUp",upString(run));set(player,"NinjaSoloMisses",0) end
	return true
end
function SoloPlay:stop(player,why)
	local run=self.runs[player]
	self.runs[player]=nil
	clear(player)
	if run and why then self:ended(player,"fail:"..why,nil,nil) end
end

-- ------------------------------------------------------------------ the race
function SoloPlay:sample(now)
	for player,run in self.runs do
		if run.kind=="race" then
			local root=self:root(player)
			if not root then self:stop(player,"left")
			else
				local what,value=Solo.raceStep(run,root.Position,now)
				if what=="ring" then set(player,"NinjaSoloNext",value+1)
				elseif what=="finish" then
					local time=Solo.hundredths(value)
					self.runs[player]=nil;clear(player)
					self:ended(player,"finish",time,self:payFor(player,"race",{time=time}))
				elseif what=="fail" then self:stop(player,value) end
			end
		elseif run.kind=="targets" then
			if now-run.at>Solo.Targets.limit or not self:root(player) then self:stop(player,"time") end
		end
	end
end

-- ------------------------------------------------------------------ the targets
-- A kunai thrown along `direction` (a Vector3 from the client: only its
-- direction is taken) from his chest.
function SoloPlay:throw(player,direction,now)
	local round=self.runs[player]
	if not round or round.kind~="targets" or typeof(direction)~="Vector3" or direction.Magnitude<.5 or direction~=direction then return nil end
	local root=self:root(player)
	if not root then return nil end
	if not Solo.atMark(root.Position) then return "far" end
	local what,a,b=Solo.throw(round,root.Position+Vector3.new(0,1.5,0),direction.Unit,now)
	if what=="hit" or what=="done" then
		set(player,"NinjaSoloUp",upString(round))
	elseif what=="miss" then
		set(player,"NinjaSoloMisses",round.misses)
	end
	if what=="done" then
		local time=Solo.hundredths(a)
		self.runs[player]=nil;clear(player)
		self:ended(player,"done",time,self:payFor(player,"targets",{time=time}))
	elseif what=="fail" then
		self:stop(player,b or "time")
	end
	return what
end

-- ------------------------------------------------------------------ the challenge
-- Who may be challenged: walkers not in a duel nor busy alone.
function SoloPlay:walkers()
	local out={}
	local bodies=self.bodies or (function() local ok,Hub=pcall(function() return require(script.Parent.Hub) end);return ok and Hub.bodies or nil end)()
	for player in bodies or {} do
		if not self.runs[player] and self:root(player) then table.insert(out,player) end
	end
	table.sort(out,function(a,b) return a.UserId<b.UserId end)
	return out
end
-- The free street place nearest to `pos`, or nil.
function SoloPlay:siteNear(pos)
	local best,bestD=nil,math.huge
	for _,street in HubMap.Streets or {} do
		local c=HubMap.Origin+street.at
		local d=(Vector3.new(c.X,0,c.Z)-Vector3.new(pos.X,0,pos.Z)).Magnitude
		local free=not self.matches or not self.matches.siteFree or self.matches:siteFree(street.key)
		if free and d<bestD then best,bestD=street,d end
	end
	return best
end
-- The kits that may challenge him: the eight inspirations, his own kit's too
-- (24/11, the CM's series MY AVATAR VS THE 8: STUDENT OF THE EIGHT asks for
-- all eight beaten, and his own kit's inspiration never came to him, so he
-- had to change kits to earn it). `own` stays for the callers.
function SoloPlay.challengers(own)
	local out={}
	for id in HubMap.Masters do if Solo.Challenge.lines[id] then table.insert(out,id) end end
	table.sort(out)
	return out
end
-- (26/11, passe 3, STORY-001: the eight seals) The inspirations whose
-- challenge he already won (kit -> true).
function SoloPlay:beatenOf(player)
	if self.beaten then return self.beaten(player) or {} end
	local ok,out=pcall(function()
		local h=require(script.Parent.Progression).handles[player]
		return h and h.data.solo and h.data.solo.beaten
	end)
	return ok and out or {}
end
-- (pure) The kits that may come for him now: the ones he has not beaten yet
-- (his next seals), all of them once he has the eight.
function SoloPlay.forSeals(kits,beaten)
	local out={}
	for _,kit in kits do if not (beaten and beaten[kit]) then table.insert(out,kit) end end
	return if #out>0 then out else kits
end
-- One inspiration in the street at a time: he comes when the last one is gone
-- for `every` s, near a walker, and leaves after `stay` s if nobody accepts.
function SoloPlay:challengeStep(now)
	local c=self.challenge
	if c then
		-- taken: his duel's end frees it (challengeEnded); a duel never
		-- decided frees it after a while
		if (c.taken and now-c.takenAt>600) or (not c.taken and now>=c.leaveAt) then self:challengeGone(now) end
		return
	end
	self.nextChallenge=self.nextChallenge or now+Solo.Challenge.every/2
	if now<self.nextChallenge then return end
	local walkers=self:walkers()
	if #walkers==0 then self.nextChallenge=now+10;return end
	local who=walkers[self.random(1,#walkers)]
	local root=self:root(who)
	local site=root and self:siteNear(root.Position)
	if not site then self.nextChallenge=now+10;return end
	local own=who:GetAttribute("NinjaKit")
	local kits=SoloPlay.forSeals(SoloPlay.challengers(own),self:beatenOf(who))
	local kit=kits[self.random(1,#kits)]
	self.challenge={kit=kit,site=site,at=now,leaveAt=now+Solo.Challenge.stay,line=Solo.Challenge.lines[kit]}
	self:showChallenger(self.challenge,root.Position)
end
function SoloPlay:showChallenger(c,toward)
	if self.rig then c.model=self.rig(c);return end
	pcall(function()
		local Hub=require(script.Parent.Hub)
		local World=require(script.Parent.World)
		local def=require(Shared.Fighters)[c.kit]
		local holder=Hub.folder and Hub.folder:FindFirstChild("Masters")
		if not def or not holder then return end
		local at=HubMap.Origin+c.site.at
		local face=Vector3.new(toward.X,at.Y,toward.Z)
		local cf=CFrame.lookAt(at+Vector3.new(0,3,0),face+Vector3.new(0,3,0))
		local model,_,root=World.rig(holder,def,cf,"Challenger")
		root.Anchored=true
		model:SetAttribute("NinjaChallenge",c.kit)
		model:SetAttribute("NinjaChallengeLine",c.line)
		local prompt=Instance.new("ProximityPrompt")
		prompt.Name="Talk";prompt.ActionText="ACCEPT THE CHALLENGE";prompt.ObjectText=require(Shared.KitTexts).name(c.kit).." • "..(c.site.place or "")
		prompt.HoldDuration=0;prompt.MaxActivationDistance=14;prompt.RequiresLineOfSight=false
		prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
		prompt:SetAttribute("NinjaChallenge",c.kit)
		prompt.Parent=root
		c.model=model
	end)
end
-- (24/11, the CM's series) A chosen inspiration in a chosen street, facing
-- `toward`: whoever stood there before leaves. Returns the challenge.
function SoloPlay:summon(kit,site,toward,now)
	if not (Solo.Challenge.lines[kit] and site) then return nil end
	if self.challenge then self:challengeGone(now) end
	self.challenge={kit=kit,site=site,at=now,leaveAt=now+Solo.Challenge.stay,line=Solo.Challenge.lines[kit]}
	self:showChallenger(self.challenge,toward)
	return self.challenge
end
function SoloPlay:challengeGone(now)
	local c=self.challenge
	self.challenge=nil
	self.nextChallenge=now+Solo.Challenge.every
	if c and c.model then pcall(function() c.model:Destroy() end) end
end
-- He accepts: the challenge is his if he stands by the challenger. Returns
-- the challenge (its kit, its site) or nil.
function SoloPlay:accept(player,kit,now)
	local c=self.challenge
	if not c or c.taken or c.kit~=kit or self.runs[player] then return nil end
	local root=self:root(player)
	local at=HubMap.Origin+c.site.at
	if not root or (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(at.X,0,at.Z)).Magnitude>c.site.radius+20 then return nil end
	c.taken=player;c.takenAt=now
	if c.model then pcall(function() c.model:Destroy() end);c.model=nil end
	return c
end
-- His duel against the challenger is decided (or abandoned): paid, the next
-- one comes later.
function SoloPlay:challengeEnded(player,won,now)
	local c=self.challenge
	if not c or c.taken~=player then return nil end
	self:challengeGone(now)
	local result=self:payFor(player,"challenge",{won=won==true,kit=c.kit})
	self:ended(player,if won then "won" else "lost",nil,result)
	return result
end

-- ------------------------------------------------------------------ the loop
function SoloPlay:update(now)
	if now<self.nextSample then return end
	self.nextSample=now+SoloPlay.SAMPLE
	self:sample(now)
	self:challengeStep(now)
end
-- He leaves the village (a duel, gone): whatever he was doing alone stops.
function SoloPlay:leave(player)
	if self.runs[player] then self:stop(player,nil) end
end

return SoloPlay
