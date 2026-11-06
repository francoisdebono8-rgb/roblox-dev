-- (06/11, user: « Kakashi : le Sharingan qui copie », after the @piercevile
-- reel, the powers that do something and show) The Copy Ninja's Sharingan.
-- A jutsu cast in front of Kakashi is copied: he faces it, it is in sight and
-- within his eye's reach, and he is not reeling from a blow. The copy takes
-- his copy slot (Fighters.Copycat.Copy.Slot: the Water Dragon's, his first
-- copy) for Life seconds or Uses casts, and he casts it the way its owner
-- does (the owner's technique, at its own cost and cooldown). Uncovered (his
-- awakening) the eye needs no facing.
-- What the eye cannot take: a Hyuga's (kekkei genkai), a sealing formula (the
-- Flying Thunder God, the marked kunai, the barrier), a jutsu without seals
-- (the Rasengan), another dojutsu's own read, what only a body trained for it
-- can do (the weights, the Lotus), and a technique thrown on the run.
-- Combat calls Copy.cast at every cast; Matches shows the slot; the client
-- draws the read (Client/CopyFX) and lights his left eye while he holds one.
local Copy={}
Copy.REACH=36 -- studs: how far the eye reads a jutsu
Copy.FACING=.5 -- cosine: within 60 degrees of where he looks
Copy.NEVER={
	CloneRasengan=true,BurstStrike=true, -- the Rasengan: no seals to read
	Flashstep=true,FlyingThunderTwo=true,MarkedBlade=true,SealingTrap=true,SpaceTimeBarrier=true, -- Minato's formula
	Read=true,SharinganCopy=true,SharinganCounter=true,SharinganParalysis=true, -- another Sharingan's own read
	RemoveWeights=true,PrimaryLotus=true, -- Lee's body
}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function techniques() return require(script.Parent.Techniques) end
local function brawler() return require(script.Parent.Brawler) end
function Copy.copyable(caster,spec)
	if not spec or not spec.Id or Copy.NEVER[spec.Id] or spec.Mobile or spec.Requires=="Anchor" then return false end
	if caster.def.Byakugan then return false end
	return techniques()[spec.Id]~=nil
end
-- Does `k`'s eye see `caster` cast right now?
function Copy.watching(c,k,caster)
	if k==caster or k.health<=0 or caster.health<=0 or k.reaction then return false end
	local d=caster.root.Position-k.root.Position
	if d.Magnitude>Copy.REACH then return false end
	if (k.awakenUntil or 0)<=c.now then
		local look,to=flat(k.root.CFrame.LookVector),flat(d)
		if look.Magnitude<.1 or (to.Magnitude>.5 and look.Unit:Dot(to.Unit)<Copy.FACING) then return false end
	end
	return c:lineOfSight(k,caster)
end
-- The spec his slot casts now: the copy while it holds (time and casts left),
-- or while the work of a spent one is still out (a copied crowd: the key
-- keeps taking bodies); nil otherwise (the slot is his own again).
function Copy.slotSpec(c,a,slot)
	local copy=a.copy
	if not copy or slot~=copy.slot then return nil end
	if copy.uses>0 and c.now<copy.untilT then return copy.spec end
	-- (Studio 06/11) a beat after the cast first: a copied crowd comes out in
	-- a ripple, and the slot let go of it before the first clone was out.
	if copy.spentAt and c.now<copy.spentAt+1 then return copy.spec end
	local t=techniques()[copy.spec.Id]
	if t and t.view and t.view(c,a,copy.spec,c.now)~=nil then return copy.spec end
	a.copy=nil
	return nil
end
-- At every cast (Combat): a copy spent, and the Sharingan across the field.
function Copy.cast(c,a,spec)
	if not spec then return end
	if spec.Copied and a.copy and a.copy.spec.Id==spec.Id then
		a.copy.uses-=1;a.copy.spentAt=c.now
		c:pushImpact(a.root.Position,"copycast",false,{owner=a.id,fighter=a.fighterId,technique=spec.Id})
		brawler().event(c,a,"CopyCast")
	end
	for _,k in c.actors do
		local tune=k.def.Copy
		if tune and k~=a and Copy.copyable(a,spec) and Copy.watching(c,k,a) then
			-- A spent copy whose work is still out (his copied crowd) is kept.
			local held=k.copy
			local busy=held~=nil and held.uses<=0 and Copy.slotSpec(c,k,held.slot)~=nil
			if not busy then
				local copied=table.clone(spec)
				copied.Copied=true;copied.CopiedFrom=a.def.Name
				-- (a charge buried as its owner's is not his: it goes off as cast)
				copied.Charge=nil
				k.copy={spec=copied,slot=tune.Slot or 1,uses=tune.Uses or 1,at=c.now,untilT=c.now+(tune.Life or 15),from=a.fighterId}
				-- The bodies a copied jutsu makes are tuned like its owner's.
				if a.def.Bodies then k.borrowedBodies=a.def.Bodies end
				c:pushImpact(k.root.Position,"copy",false,{owner=k.id,fighter=k.fighterId,from=a.id,technique=spec.Id,name=spec.Name,channel=spec.Channel or .3})
				c:cue(k,"SHARINGAN • COPIED: "..string.upper(spec.Name or spec.Id),1.1)
				brawler().event(c,k,"Copied")
			end
		end
	end
end
-- Snapshot (Matches): what he holds, for the eye and the slot.
function Copy.view(c,a)
	local copy=a.copy
	if not copy then return nil end
	return {id=copy.spec.Id,name=copy.spec.Name,remaining=math.max(0,copy.untilT-c.now),uses=copy.uses,from=copy.from}
end
return Copy
