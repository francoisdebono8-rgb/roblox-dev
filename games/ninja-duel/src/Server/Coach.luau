-- The first combat's coach (21/11, DEC-047; François after playing step 2:
-- « le combat/tutoriel n'est pas satisfaisant, trop long et ne m'apprend pas
-- à jouer, face à une IA trop forte pour un non-initié »; his choice: « un
-- combat facile avec des consignes au bon moment »).
--
-- A real duel, one round, against the novice (AI level "first"). No screen
-- to get through first: a prompt appears when its situation comes up (he
-- winds up a strike: GUARD; he is open: STRIKE x3; he guards: GRAB; you are
-- caught in a string: ESCAPE; the chakra is there: your SIGNATURE; far from
-- him: your TOOL), one at a time, and is gone for good once done. Nothing is
-- faked: the prompts read the real fight (combat events, accepted presses).
-- The client draws the prompt as the first minute's panel (Matches snapshot
-- `tutorial`, first = true); the words are the CM's (Shared/PlayTexts.Coach,
-- 21/11): the title, the tick of success, the touch line.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Controls=require(Shared.Controls)
local FirstMinute=require(Shared.FirstMinute)
local PlayTexts=require(Shared.PlayTexts)
local Coach={}

local K,P=Controls.KeyLabel,Controls.PadLabel
local TECH_KEY={"1","2","3","4","5"}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function ev(a,name) return a.events and a.events[name] or 0 end

-- The novice's handicap: what his blows are worth, and the share of health
-- the player keeps whatever happens (the first fight is won by trying).
Coach.BotDamage=.5
Coach.HealthFloor=.2
-- (A beginner mashing the strike beat the novice in 14 to 31 s: too short for
-- the prompts to come.) His blows are worth a little less: about 25 to 50 s.
Coach.PlayerDamage=.6
-- A prompt shows at least this long once it appears, and stays a beat after
-- it is done (the tick of success).
Coach.MinShow=1.2
Coach.DoneHold=.6
-- (22/11, the OUTILLEUR's beginner robot: guard done 4 times in 22, escape 0
-- in 3; the prompt came while he was still in a blow and was gone before the
-- next chance) A prompt whose moment passed stays this long before it goes:
-- the reactive ones (guard, escape: `stay`) until his next chance.
Coach.Stay=3.5

-- The prompts, in priority order. when(c,a,b,coach,now): its situation is
-- here; done(c,a,b,coach,now): the player did it (since the prompt came).
-- His signature (the second jutsu), or with the reduced start (DEC-045,
-- the Chidori still to learn) the first technique he has.
local function signature(a)
	local spec=FirstMinute.signature(a.def)
	if spec and not spec.Locked then return spec end
	for _,other in a.def.Techniques do if not other.Locked then return other end end
	return nil
end
Coach.signature=signature
local function slotOf(a,id)
	for slot,spec in a.def.Techniques do if spec.Id==id then return slot end end
	return FirstMinute.SignatureSlot
end
Coach.Prompts={
	{id="escape",stay=10,title=PlayTexts.coachTitle("escape"),key=function() return K.Dodge.." as his blow lands" end,pad=function() return P.Dodge.." as his blow lands" end,
		when=function(c,a) return a.reaction=="HitStun" and (a.comboHits or 0)>=2 end,
		done=function(c,a,b,k) return ev(a,"Substitute")>(k.base.Substitute or 0) or ev(a,"Recover")>(k.base.Recover or 0) end},
	{id="guard",stay=10,title=PlayTexts.coachTitle("guard"),key=function() return "Hold "..K.Guard end,pad=function() return "Hold "..P.Guard end,
		-- he winds up near you, and you are free to guard (not in a blow of yours)
		when=function(c,a,b) return b.attackName~=nil and b.state=="Startup" and a.attackName==nil and a.reaction==nil and (b.root.Position-a.root.Position).Magnitude<8 end,
		done=function(c,a,b,k) return ev(a,"GuardHit")>(k.base.GuardHit or 0) or ev(a,"Parry")>(k.base.Parry or 0) or ev(a,"Evaded")>(k.base.Evaded or 0) end},
	{id="signature",title=function(a) local spec=signature(a);return PlayTexts.coachTitle("signature",{jutsu=spec and (spec.CardName or spec.Name) or "your jutsu"}) end,
		key=function(a) local spec=signature(a);return TECH_KEY[slotOf(a,spec and spec.Id)] end,
		pad=function(a) local spec=signature(a);local slot=slotOf(a,spec and spec.Id);return Controls.TechniquePad and Controls.TechniquePad[slot] or ("Jutsu "..slot) end,
		when=function(c,a,b,k,now)
			local spec=signature(a)
			if not spec or spec.Locked or now-k.started<8 then return false end
			return a.state=="Neutral" and a.chakra>=(spec.Cost or 0) and (a.cooldowns[spec.Id] or 0)<=now and (b.root.Position-a.root.Position).Magnitude<=math.max(spec.Range or 12,6)+4
		end,
		done=function(c,a,b,k) local spec=signature(a);return spec~=nil and ev(a,"Cast:"..spec.Id)>(k.base["Cast:"..spec.Id] or 0) end},
	{id="grab",title=PlayTexts.coachTitle("grab"),key=function() return K.Grab end,pad=function() return P.Grab end,
		when=function(c,a,b) return b.state=="Guarding" and (b.root.Position-a.root.Position).Magnitude<6 end,
		done=function(c,a,b,k) return ev(a,"GrabHit")>(k.base.GrabHit or 0) end},
	{id="tool",title=function(a) return PlayTexts.coachTitle("tool",{tool=if a.def.Tool=="Sand" then "sand" else "kunai"}) end,key=function() return K.Tool end,pad=function() return P.Tool end,
		when=function(c,a,b,k,now)
			if a.def.Tool=="Deflect" or a.def.Tool=="Gust" then return false end
			if (b.root.Position-a.root.Position).Magnitude<16 then k.farSince=nil;return false end
			k.farSince=k.farSince or now
			return now-k.farSince>1.2
		end,
		done=function(c,a,b,k)
			for i=#(a.pressLog or {}),1,-1 do
				local entry=a.pressLog[i]
				if entry.t<k.shownAt then break end
				if entry.action=="Tool" and entry.ok then return true end
			end
			return false
		end},
	{id="strike",title=PlayTexts.coachTitle("strike"),key=function() return K.Light.." x3" end,pad=function() return P.Light.." x3" end,
		when=function(c,a,b) return b.attackName==nil and b.state~="Guarding" and (b.root.Position-a.root.Position).Magnitude<7 end,
		done=function(c,a,b,k) return ev(a,"Hit")-(k.base.Hit or 0)>=3 end},
	{id="move",title=PlayTexts.coachTitle("move"),key=function() return "WASD" end,pad=function() return "L stick" end,
		when=function(c,a,b,k,now) return now-k.started<6 and (b.root.Position-a.root.Position).Magnitude>8 end,
		done=function(c,a,b,k) return (k.travel or 0)>8 end},
}
Coach.ById={}
for _,p in Coach.Prompts do Coach.ById[p.id]=p end

local function text(value,a) if type(value)=="function" then return value(a) end return value end

function Coach.new(s,now)
	local k={started=now,done={},current=nil,shownAt=0,doneAt=nil,base={},travel=0,last=nil,count=0}
	s.coach=k
	-- (26/11, DEC-054) the forest's fight has no jutsu nor tool to teach
	if s.bare then k.done.signature=true;k.done.tool=true;k.skip=2 end
	-- The novice's handicap, on this duel's bodies only.
	if s.bot then s.bot.outScale=Coach.BotDamage end
	if s.human then s.human.healthFloor=s.human.def.Health*Coach.HealthFloor;s.human.outScale=Coach.PlayerDamage end
	-- (22/11) Gaara's sand stops blows on its own: the novice has none (the
	-- first fight against him ran 54 to 91 s in Studio, 30 to 60 s the others)
	if s.bot and s.bot.def.SandShield then s.bot.noSandShield=true;s.bot.shieldCharges=0 end
	return k
end
local function show(k,a,prompt,now)
	k.current=prompt;k.shownAt=now;k.doneAt=nil
	k.base=table.clone(a.events or {})
end
function Coach.update(s,now,dt)
	local k=s.coach
	if not k or not s.combat or not s.human or not s.bot then return end
	local c,a,b=s.combat,s.human,s.bot
	if a.health<=0 or b.health<=0 then return end
	local here=a.root.Position
	k.travel+=math.min(((k.last or here)-here).Magnitude,4);k.last=here
	local p=k.current
	-- A more urgent moment (he winds up, you are caught) takes the place of
	-- the prompt on screen; the other comes back when its moment does.
	if p and not k.doneAt then
		for _,prompt in Coach.Prompts do
			if prompt==p then break end
			if not k.done[prompt.id] and prompt.when(c,a,b,k,now) then show(k,a,prompt,now);return end
		end
	end
	if p then
		if not k.doneAt and p.done(c,a,b,k,now) then
			k.doneAt=now;k.done[p.id]=true;k.count+=1
			c:cue(a,PlayTexts.coachDone(p.id),.5)
		end
		if k.doneAt then
			if now-k.doneAt<Coach.DoneHold then return end
			k.current=nil
		elseif now-k.shownAt<Coach.MinShow then return
		elseif not p.when(c,a,b,k,now) and now-k.shownAt>(p.stay or Coach.Stay) then
			-- its moment passed: it comes back when its situation does
			k.current=nil
		else return end
	end
	for _,prompt in Coach.Prompts do
		if not k.done[prompt.id] and prompt.when(c,a,b,k,now) then show(k,a,prompt,now);return end
	end
end
function Coach.snapshot(s)
	local k=s.coach
	local p=k and k.current
	if not p or not s.human then return nil end
	local a=s.human
	return {index=k.count+(if k.doneAt then 0 else 1),total=#Coach.Prompts-(k.skip or 0),title=text(p.title,a),key=text(p.key,a),pad=text(p.pad,a),
		touch=FirstMinute.Touch[p.id],id=p.id,first=true,coach=true,done=k.doneAt~=nil or nil}
end
return Coach
