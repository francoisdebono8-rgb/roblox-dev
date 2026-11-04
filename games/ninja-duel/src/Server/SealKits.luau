-- The seal jutsu that are not a plain family object (04/11, the user's kit
-- review: "trouve-moi les autres attaques des 8, il y en a sûrement déjà qui
-- sont bonnes" → 15 of the 33 repeated a move the fighter already had and were
-- replaced; Shared/SealJutsu). The ones a Family runs as data (a projectile, a
-- burst, a strike with its Move) stay in Server/Families; these need a body
-- reading the other:
--   Sasuke   SharinganCopy       the opponent's last family jutsu, sent back
--   Naruto   CloneAmbush         a clone out of the floor under him, a kick up
--            CloneThrow          a clone throws him across the gap head first
--   Lee      DancingLeafShadow   after a launched body, behind it in the air
--   Itachi   SharinganParalysis  frozen if he looks Itachi in the eyes
-- Each entry: check(c,a,spec,now) -> ok, reason; execute(c,a,pending).
local Bodies=require(script.Parent.Bodies)
local SealKits={}
local function brawler() return require(script.Parent.Brawler) end
local function families() return require(script.Parent.Families) end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function unitOr(v,fallback) return if v.Magnitude>1e-3 then v.Unit else fallback end
-- What the Sharingan can take back: a jutsu that is data (its look and its
-- contact fields), not a body's own technique (clones, a dome, a teleport).
SealKits.COPYABLE={Projectile=true,Burst=true,Zone=true}
SealKits.COPY_WINDOW=6
local function target(c,a,spec,needSight)
	local b=a.target
	if not b or b.health<=0 then return nil,"No target" end
	if (b.root.Position-a.root.Position).Magnitude>(spec.Range or 20)+1.5 then return nil,"Out of range" end
	if needSight and not c:lineOfSight(a,b) then return nil,"No line of sight" end
	return b
end
-- Combat, at every cast: the last family jutsu each body used (the copy reads it).
function SealKits.noteCast(c,a,spec)
	if spec and spec.Family and SealKits.COPYABLE[spec.Family] then a.lastFamilyCast={spec=spec,at=c.now} end
end

function SealKits.install(Techniques)
	Techniques.SharinganCopy={
		check=function(c,a,spec)
			local b,why=target(c,a,spec,true)
			if not b then return false,why end
			local seen=b.lastFamilyCast
			if not seen or c.now-seen.at>SealKits.COPY_WINDOW then return false,"Nothing to copy" end
			return true
		end,
		execute=function(c,a,pending)
			local b=a.target
			local seen=b and b.lastFamilyCast
			if not seen then return end
			local copy=table.clone(seen.spec)
			copy.Name="SHARINGAN COPY • "..tostring(seen.spec.Name)
			-- (a copied charge is not his: it goes off as a blast, not a buried lump)
			copy.Charge=nil
			local F=families().F[copy.Family]
			if not F then return end
			c:pushImpact(a.root.Position,"look",true,{owner=a.id,kind="sharingan"})
			brawler().event(c,a,"SharinganCopy")
			F.execute(c,a,{spec=copy,aim=pending.aim or b.root.Position,id=pending.id})
		end,
	}
	Techniques.CloneAmbush={
		check=function(c,a,spec)
			local b,why=target(c,a,spec,true)
			if not b then return false,why end
			if b.airborne then return false,"Target in the air" end
			return true
		end,
		execute=function(c,a,pending)
			local spec=pending.spec
			local b=a.target
			if not b or b.health<=0 then return end
			local under=b.root.Position
			-- The floor cracks under him first: a beat to read it (and to step off).
			c:pushImpact(under-Vector3.new(0,2.4,0),"look",false,{owner=a.id,kind="clonepop"})
			c:schedule(c.now+.2,function()
				if a.health<=0 or b.health<=0 or c.match.phase~="Duel" then return end
				-- (Audit 04/11) the clone comes out where the floor cracked: a body
				-- that stepped off or jumped is missed (it followed him anywhere).
				local line=unitOr(flat(under-a.root.Position),Vector3.zAxis)
				local at=under
				Bodies.spawn(c,a,{kind="clone",position=at-line*.9-Vector3.new(0,1.4,0),ephemeral=true,life=.5,mode="spent",airborne=true,state="Active",action="UzumakiKick"})
				c:pushImpact(at,"look",true,{owner=a.id,kind="clonepop",victim=b.id})
				if flat(b.root.Position-at).Magnitude>3.5 or b.airborne or math.abs(b.root.Position.Y-at.Y)>3 then return end
				if families().barrierTakes(c,a,b) then return end
				c.damageTag=spec.Name
				local hit=c:damage(a,b,spec.Damage or 8,true,false)
				c.damageTag=nil
				if c.match.phase~="Duel" or not hit or b.impactStyle=="block" then return end
				brawler().react(c,b,"Launched",Vector3.new(0,50,0)+line*4,1.1,a)
				a.pursuitUntil=math.max(a.pursuitUntil or 0,c.now+1.1)
				c:cue(a,"SHADOW CLONE • E TO CHASE",.8)
				brawler().event(c,a,"CloneAmbush")
			end)
			c:cue(a,string.upper(spec.Name),.6)
		end,
	}
	Techniques.CloneThrow={
		check=function(c,a,spec)
			local b,why=target(c,a,spec,true)
			if not b then return false,why end
			return true
		end,
		execute=function(c,a,pending)
			local spec=pending.spec
			local b=a.target
			if not b then return end
			local line=unitOr(flat(b.root.Position-a.root.Position),flat(a.root.CFrame.LookVector).Unit)
			a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+line)
			-- The clone that throws him: behind him, arms swung through.
			Bodies.spawn(c,a,{kind="clone",position=a.root.Position-line*1.6,ephemeral=true,life=.45,mode="spent",state="Active",action="Throw"})
			local Brawler=brawler()
			Brawler.start(c,a,"HeadDive")
			local p=a.pending
			if p then
				p.spec=table.clone(p.spec)
				local gap=flat(b.root.Position-a.root.Position).Magnitude
				local travel=math.clamp(gap-2.6,4,(spec.Range or 20))
				p.spec.travel=travel;a.travelRemaining=travel
				p.spec.travelTime=math.max(p.spec.travelTime or .28,.24)
				p.spec.damage=spec.Damage or p.spec.damage
				p.family=spec
			end
			c:pushImpact(a.root.Position,"look",false,{owner=a.id,kind="clonepop"})
			c:cue(a,string.upper(spec.Name),.6)
			Brawler.event(c,a,"CloneThrow")
		end,
	}
	Techniques.DancingLeafShadow={
		check=function(c,a,spec)
			local b,why=target(c,a,spec,true)
			if not b then return false,why end
			if not (b.reaction=="Launched" or b.reaction=="Juggled") then return false,"Launch him first" end
			return true
		end,
		execute=function(c,a,pending)
			local b=a.target
			if not b or b.health<=0 then return end
			local line=unitOr(flat(b.root.Position-a.root.Position),flat(a.root.CFrame.LookVector).Unit)
			local from=a.root.Position
			-- Right behind it and a little under it, like its shadow.
			local goal=b.root.Position-line*1.4-Vector3.new(0,1.2,0)
			c:relocate(a,goal)
			a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+line)
			a.airborne=true;a.airHold=c.now+.7
			-- His air finisher's window (MoveGraphs airFinisher: the lotus).
			a.lionUntil=c.now+1.4
			c:pushImpact(goal,"teleport",false,{owner=a.id,fighter=a.fighterId,from=from,to=goal,kind="leaf"})
			c:cue(a,"SHADOW OF THE DANCING LEAF • HEAVY: LOTUS",.9)
			brawler().event(c,a,"DancingLeaf")
		end,
	}
	Techniques.SharinganParalysis={
		check=function(c,a,spec)
			local b,why=target(c,a,spec,true)
			if not b then return false,why end
			return true
		end,
		execute=function(c,a,pending)
			local spec=pending.spec
			local b=a.target
			if not b or b.health<=0 then return end
			-- The eyes meet only if he is facing Itachi (a body looking away, or
			-- behind his guard turned aside, is not caught).
			local toItachi=unitOr(flat(a.root.Position-b.root.Position),Vector3.zAxis)
			local facing=flat(b.root.CFrame.LookVector)
			local meets=facing.Magnitude>.1 and facing.Unit:Dot(toItachi)>.35
			-- (Audit 04/11) a raised guard looks down behind the arms: not caught
			-- (it was an unblockable instant hold from 16 studs).
			local guarding=b.state=="Guarding" or b.guardHeld==true
			c:pushImpact(a.root.Position+Vector3.new(0,1.6,0),"look",false,{owner=a.id,kind="sharingan"})
			if guarding then
				c:cue(a,string.upper(spec.Name).." • GUARDED",.7)
				brawler().event(c,a,"ParalysisMissed")
				return
			end
			if not meets then
				c:cue(a,string.upper(spec.Name).." • HE LOOKED AWAY",.7)
				brawler().event(c,a,"ParalysisMissed")
				return
			end
			families().bind(c,a,b,{Bind=spec.Bind or .8,Name=spec.Name,Kind="sharingan"})
			c:pushImpact(b.root.Position,"look",true,{owner=a.id,kind="sharingan",victim=b.id})
			brawler().event(c,a,"Paralysis")
		end,
	}
end
return SealKits
