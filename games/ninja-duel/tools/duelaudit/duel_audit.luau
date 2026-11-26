-- The duel watcher (OUTILLEUR, passe commune 2, 26/11; DEC-054: « un robot de
-- duel qui joue des duels complets (les 8 kits, et l'avatar) et relève chaque
-- incohérence : corps bloqué, coup qui traverse, chute dans le sol, caméra
-- dans un mur, erreur en rouge »).
--
-- A client module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py duel audit
-- The duel robot (NDDuelBot) plays; this one watches every frame of every
-- duel from the client, as the player sees it, and keeps what does not hold:
--   bloque        his stick held, his body free, and it does not move (1 s)
--   fige          a body held in one state other than free for 6 s
--   superposes    the two bodies one inside the other
--   traverse      a hand, a foot, a forearm or a shin deep in the other's
--                 torso, hips or head during a strike
--   de_loin       a strike that lands while no limb of the striker is near
--                 the other's body (the hit without a contact)
--   dans_le_sol   the lowest point of a body under the ground under it
--   sous_le_sol   a body under the floor it stood on
--   camera_mur    the camera inside a drawn part (a wall, a roof, a crate)
--   camera_terrain the camera inside the terrain
--   cache         a fighter hidden by the scenery from the camera (0.5 s)
--   erreur        a red line of the client's output (the server's: NDServerLog)
-- and, for what it says about the others, how often the stick pushed against
-- the rival (pousse_rival) or a wall (pousse_mur), which is no incoherence.
--
--   _G.NDDuelAudit.start()   then NDDuelBot.start(PLAN)
--   _G.NDDuelAudit.read()    the report (JSON): runs, counts, the incidents
--   _G.NDDuelAudit.show(run,i[,view]) the frame of incident i of run `run`: the
--                            two bodies as they were, a red mark and a label,
--                            seen from their side ("back": the other side;
--                            "seen": the player's camera); then capture_screenshot
--   _G.NDDuelAudit.unshow()
-- The thresholds are in Audit.LIMITS. Studio's own limits: the client sees
-- the server a few milliseconds late (one machine); Studio in the
-- background draws fewer frames, the checks run on each frame it draws.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LogService=game:GetService("LogService")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("NinjaDuel"):WaitForChild("Action")

local Audit={}
Audit.LIMITS={blockedFor=1.0,blockedMove=.6,frozenFor=6,overlap=1.4,overlapFor=.15,far=2.5,through=.35,
	ground=.7,below=2.5,hiddenFor=.5,keepDetails=6,keepFrames=2,buffer=2.0}
-- the strikes whose hands are on the body by design
local HOLDS={Grab=true,Throw=true,ThrowUp=true,ThrowDown=true,ThrowBack=true}
local LIMBS={"RightHand","LeftHand","RightFoot","LeftFoot","RightLowerArm","LeftLowerArm","RightLowerLeg","LeftLowerLeg"}
local CORE={UpperTorso=true,LowerTorso=true,Head=true}
local FREE={Neutral=true}
local STILL={Neutral=true,Defeated=true,Guarding=true}
local STRIKING={Startup=true,Active=true}

local snap={phase="?",epoch=0}
local runs={}
local run=nil
local intent={dir=Vector3.zero,at=-10}
local conns={}
local lastPhase="?"
local errors,warnings={}, {}

local function r2(x) return math.floor(x*100+.5)/100 end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function v3(v) return {r2(v.X),r2(v.Y),r2(v.Z)} end

-- ------------------------------------------------------------------ geometry
-- How far a point is inside a box (positive: inside, by the shortest way out).
local function depthIn(cf,size,p)
	local l=cf:PointToObjectSpace(p)
	return math.min(size.X/2-math.abs(l.X),size.Y/2-math.abs(l.Y),size.Z/2-math.abs(l.Z))
end
-- From a point to a box's surface (0 inside).
local function toBox(cf,size,p)
	local l=cf:PointToObjectSpace(p)
	local dx=math.max(0,math.abs(l.X)-size.X/2)
	local dy=math.max(0,math.abs(l.Y)-size.Y/2)
	local dz=math.max(0,math.abs(l.Z)-size.Z/2)
	return math.sqrt(dx*dx+dy*dy+dz*dz)
end
local function lowest(cf,size)
	local r,u,b=cf.RightVector,cf.UpVector,cf.LookVector
	return cf.Position.Y-(math.abs(r.Y)*size.X+math.abs(u.Y)*size.Y+math.abs(b.Y)*size.Z)/2
end

-- ------------------------------------------------------------------ the bodies
-- A fighter's own parts (the R15 body), its limbs, its core, and every drawn
-- part with a path that a clone can find again.
local bodies=setmetatable({},{__mode="k"})
local function body(model)
	if not model then return nil end
	local b=bodies[model]
	local now=os.clock()
	if b and now-b.checked<1 then return b end
	local count=#model:GetDescendants()
	if b and b.count==count then b.checked=now;return b end
	b={model=model,own={},limbs={},core={},all={},paths={},index={},count=count,checked=now}
	local seen={}
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local rel=d:GetFullName()
			local base=model:GetFullName()
			rel=string.sub(rel,#base+2)
			seen[rel]=(seen[rel] or 0)+1
			table.insert(b.all,d);table.insert(b.paths,rel.."#"..seen[rel]);b.index[d]=#b.all
			if d.Parent==model and d.Name~="HumanoidRootPart" then
				table.insert(b.own,d)
				if CORE[d.Name] then table.insert(b.core,d) end
			end
		end
	end
	for _,n in LIMBS do
		local p=model:FindFirstChild(n)
		if p and p:IsA("BasePart") then table.insert(b.limbs,p) end
	end
	b.root=model:FindFirstChild("HumanoidRootPart")
	b.head=model:FindFirstChild("Head")
	bodies[model]=b
	return b
end
local function models()
	local me=player.Character
	if not me or not me.Parent then return nil end
	local him=nil
	if me.Name=="PlayerFighter" then
		him=me.Parent:FindFirstChild("AIFighter")
	elseif string.sub(me.Parent.Name,1,7)=="Online_" then
		-- (26/11, passe 3) a duel between two players (a street challenge by a
		-- blow): Duelist1 and Duelist2 in NinjaDuels.Online_<lane>
		for _,m in me.Parent:GetChildren() do
			if m~=me and m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then him=m;break end
		end
	end
	if not him then return nil end
	return body(me),body(him)
end

-- ------------------------------------------------------------------ the scenery
-- The drawn parts around the duel (dress included: what the camera can be
-- inside), in a grid of 16 studs, built once per duel place.
local CELL=16
local scenery=nil
local function key(x,y,z) return x..","..y..","..z end
local function buildScenery(origin,skip)
	local grid={}
	local n=0
	local t0=os.clock()
	for _,d in workspace:GetDescendants() do
		if d:IsA("BasePart") and not d:IsA("Terrain") and d.Transparency<.7 and d.LocalTransparencyModifier<.7 then
			local s=d.Size
			if math.max(s.X,s.Y,s.Z)>=.4 and (d.Position-origin).Magnitude-s.Magnitude/2<220 then
				local skipIt=false
				for _,m in skip do if d:IsDescendantOf(m) then skipIt=true break end end
				if not skipIt and d.Name~="NDAuditMark" then
					local cf=d.CFrame
					local half=s/2
					local ext=Vector3.new(
						math.abs(cf.RightVector.X)*half.X+math.abs(cf.UpVector.X)*half.Y+math.abs(cf.LookVector.X)*half.Z,
						math.abs(cf.RightVector.Y)*half.X+math.abs(cf.UpVector.Y)*half.Y+math.abs(cf.LookVector.Y)*half.Z,
						math.abs(cf.RightVector.Z)*half.X+math.abs(cf.UpVector.Z)*half.Y+math.abs(cf.LookVector.Z)*half.Z)
					local lo,hi=cf.Position-ext,cf.Position+ext
					local mesh=d:IsA("MeshPart") or d:IsA("UnionOperation")
					local entry={part=d,cf=cf,size=if mesh then s*.8 else s,mesh=mesh}
					for x=math.floor(lo.X/CELL),math.floor(hi.X/CELL) do
						for y=math.floor(lo.Y/CELL),math.floor(hi.Y/CELL) do
							for z=math.floor(lo.Z/CELL),math.floor(hi.Z/CELL) do
								local k=key(x,y,z)
								local list=grid[k];if not list then list={};grid[k]=list end
								table.insert(list,entry)
							end
						end
					end
					n+=1
				end
			end
		end
	end
	return {grid=grid,parts=n,origin=origin,built=os.clock()-t0}
end
-- The drawn part a point is in (nil: none).
local function inside(p,ignore)
	if not scenery then return nil end
	local list=scenery.grid[key(math.floor(p.X/CELL),math.floor(p.Y/CELL),math.floor(p.Z/CELL))]
	if not list then return nil end
	for _,e in list do
		if e.part.Parent and e.part~=ignore and depthIn(e.cf,e.size,p)>.02 then return e end
	end
	return nil
end
-- Is the segment from the camera to a point cut by a drawn part?
local function cut(a,b)
	local d=b-a
	local len=d.Magnitude
	if len<1.5 then return nil end
	local step=d/len
	local t=.6
	while t<len-1 do
		local e=inside(a+step*t)
		if e then return e end
		t+=1
	end
	return nil
end
local function inTerrain(p)
	local ok,occ=pcall(function()
		local region=Region3.new(p-Vector3.new(2,2,2),p+Vector3.new(2,2,2)):ExpandToGrid(4)
		local _,occupancy=workspace.Terrain:ReadVoxels(region,4)
		return occupancy[1][1][1]
	end)
	return ok and occ and occ>.5
end

-- ------------------------------------------------------------------ the record
-- The recent frames: the camera and every drawn part of both bodies.
local ring={}
local function push(now,me,him)
	local cam=workspace.CurrentCamera
	local f={t=now,cam=cam and cam.CFrame,me={},him={},mb=me,hb=him}
	for i,p in me.all do f.me[i]=p.CFrame end
	for i,p in him.all do f.him[i]=p.CFrame end
	table.insert(ring,f)
	while #ring>0 and now-ring[1].t>Audit.LIMITS.buffer do table.remove(ring,1) end
end
local function frameAt(t)
	local best,gap=nil,math.huge
	for _,f in ring do
		local g=math.abs(f.t-t)
		if g<gap then best,gap=f,g end
	end
	return best
end
-- A body as it stood in frame f, cloned now (kept out of the world).
local function cloneAt(b,cfs)
	local m=b.model
	local was=m.Archivable
	m.Archivable=true
	local ok,c=pcall(function() return m:Clone() end)
	m.Archivable=was
	if not ok or not c then return nil end
	local hidden={}
	for i,p in b.all do hidden[b.paths[i]]=p.LocalTransparencyModifier end
	-- (26/11) the joints first: a part moved with its joints drags the others
	for _,d in c:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("AnimationConstraint") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Animator") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored=true
		end
	end
	local seen={}
	local base=c:GetFullName()
	for _,d in c:GetDescendants() do
		if d:IsA("BasePart") then
			local rel=string.sub(d:GetFullName(),#base+2)
			seen[rel]=(seen[rel] or 0)+1
			local path=rel.."#"..seen[rel]
			for i,q in b.paths do
				if q==path and cfs[i] then d.CFrame=cfs[i] break end
			end
			d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false
			if (hidden[path] or 0)>.5 then d.Transparency=1 end
		end
	end
	-- the outfit's holder renamed: the client's OutfitDress dresses it once, already done
	for _,d in c:GetDescendants() do
		if d.Name=="NinjaOutfit" then d.Name="NinjaOutfitShown";pcall(function() d:SetAttribute("NinjaOutfit",nil) end) end
	end
	c.Name="NDShow_"..m.Name
	return c
end

local function note(kind,who,detail,extra)
	if not run then return nil end
	run.counts[kind]=(run.counts[kind] or 0)+1
	local n=run.counts[kind]
	if n>Audit.LIMITS.keepDetails then return nil end
	local rec={kind=kind,who=who,detail=detail,t=r2(run.seconds),round=snap.round or 1}
	for k,v in extra or {} do rec[k]=v end
	table.insert(run.incidents,rec)
	rec.index=#run.incidents
	return rec,n
end
-- Keeps the frame of an incident (the first ones of each kind) for show().
local function keep(rec,n,t,me,him,mark)
	if not rec or n>Audit.LIMITS.keepFrames then return end
	local f=frameAt(t)
	if not f then return end
	rec.frame={cam=f.cam,mark=mark,me=cloneAt(f.mb,f.me),him=cloneAt(f.hb,f.him)}
	rec.framed=true
end

-- ------------------------------------------------------------------ the checks
local watch={}
local function reset()
	watch={blockStart=nil,blockFrom=nil,overlapFor=0,states={},hidden={me=0,him=0},strikes={},impacts={},serial={},
		groundAt=0,camAt=0,refY=nil,lastHit=nil}
	ring={}
end
local function newRun()
	local d=snap
	run={kit=d.human and d.human.fighterId,rival=d.bot and d.bot.fighterId,fighter=d.human and d.human.fighter,
		avatar=player.Character and player.Character:GetAttribute("Avatar")~=nil,started=os.clock(),
		seconds=0,frames=0,rounds=0,counts={},incidents={},first=d.first}
	table.insert(runs,run)
	reset()
	scenery=nil
end

local function checkBlocked(now,dt,me,him,d)
	local dir=intent.dir
	local free=FREE[d.human.state] and not d.human.airborne and d.human.reaction==nil
	if dir.Magnitude>.5 and now-intent.at<.3 and free and me.root then
		if not watch.blockStart then watch.blockStart=now;watch.blockFrom=me.root.Position;return end
		if now-watch.blockStart>=Audit.LIMITS.blockedFor then
			local moved=flat(me.root.Position-watch.blockFrom).Magnitude
			if moved<Audit.LIMITS.blockedMove then
				local gap=flat(him.root.Position-me.root.Position).Magnitude
				local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances={me.model,him.model}
				local wall=workspace:Raycast(me.root.Position,flat(dir).Unit*3,params)
				if gap<4.5 and flat(him.root.Position-me.root.Position).Unit:Dot(flat(dir).Unit)>.3 then
					note("pousse_rival","joueur",string.format("pousse vers l'adversaire à %.1f studs",gap))
				elseif wall then
					note("pousse_mur","joueur",string.format("pousse contre %s",wall.Instance:GetFullName()),{at=v3(wall.Position)})
				else
					local rec,n=note("bloque","joueur",string.format("stick tenu %.1f s, corps libre, déplacé de %.2f stud (vitesse serveur %.1f)",now-watch.blockStart,moved,d.human.speed or 0),
						{at=v3(me.root.Position),state=d.human.state})
					keep(rec,n,now,me,him,me.root.Position)
				end
			end
			watch.blockStart=nil
		end
	else
		watch.blockStart=nil
	end
end

local function checkFrozen(now,dt,me,him,d)
	for _,side in {{"joueur",d.human,me},{"adversaire",d.bot,him}} do
		local who,data,b=side[1],side[2],side[3]
		local st=watch.states[who]
		local name=tostring(data.state)..(if data.reaction then "/"..tostring(data.reaction) else "")
		if not st or st.name~=name then watch.states[who]={name=name,since=now,told=false}
		elseif not st.told and not STILL[data.state] and now-st.since>Audit.LIMITS.frozenFor then
			st.told=true
			local rec,n=note("fige",who,string.format("%s depuis %.1f s",name,now-st.since),{state=name})
			keep(rec,n,now,me,him,b.root and b.root.Position)
		end
	end
end

local function checkOverlap(now,dt,me,him,d)
	if not (me.root and him.root) then return end
	local a,b=me.root.Position,him.root.Position
	local held=HOLDS[d.human.attackName or ""] or HOLDS[d.bot.attackName or ""] or d.human.reaction=="Grabbed" or d.bot.reaction=="Grabbed"
		or d.human.state=="Defeated" or d.bot.state=="Defeated"
	if not held and flat(a-b).Magnitude<Audit.LIMITS.overlap and math.abs(a.Y-b.Y)<2.5 then
		watch.overlapFor+=dt
		if watch.overlapFor>=Audit.LIMITS.overlapFor and not watch.overlapTold then
			watch.overlapTold=true
			local rec,n=note("superposes","les deux",string.format("racines à %.2f stud (%s / %s)",flat(a-b).Magnitude,tostring(d.human.state),tostring(d.bot.state)),
				{attack=d.human.attackName or d.bot.attackName})
			keep(rec,n,now,me,him,(a+b)/2)
		end
	else
		watch.overlapFor=0;watch.overlapTold=false
	end
end

-- A strike in progress: how deep its limbs go into the other's core.
local function strikeDepth(att,vic)
	local best,limb,point=0,nil,nil
	for _,l in att.limbs do
		for _,c in vic.core do
			local dep=depthIn(c.CFrame,c.Size,l.Position)
			if dep>best then best,limb,point=dep,l.Name.." dans "..c.Name,l.Position end
		end
	end
	return best,limb,point
end
-- The nearest any limb of the striker comes to the other's body.
local function contactGap(att,vic)
	local best,limb,point=math.huge,nil,nil
	for _,l in att.limbs do
		local radius=math.min(l.Size.X,l.Size.Y,l.Size.Z)/2
		for _,v in vic.own do
			local g=toBox(v.CFrame,v.Size,l.Position)-radius
			if g<best then best,limb,point=g,l.Name.."→"..v.Name,l.Position end
		end
	end
	return math.max(0,best),limb,point
end
local function checkStrikes(now,dt,me,him,d)
	for _,side in {{"joueur",d.human,me,him,d.bot},{"adversaire",d.bot,him,me,d.human}} do
		local who,data,att,vic,other=side[1],side[2],side[3],side[4],side[5]
		local s=watch.strikes[who]
		local live=data.attackName and STRIKING[data.state] and not HOLDS[data.attackName]
		local serial=(data.attackSerial or 0)..":"..tostring(data.attackName)
		if live then
			if not s or s.serial~=serial then s={serial=serial,name=data.attackName,depth=0};watch.strikes[who]=s end
			local dep,limb,point=strikeDepth(att,vic)
			if dep>s.depth then s.depth=dep;s.limb=limb;s.point=point;s.at=now end
		elseif s and not s.done then
			s.done=true
			if s.depth>Audit.LIMITS.through then
				local rec,n=note("traverse",who,string.format("%s : %s, %.2f stud dedans",s.name,s.limb,s.depth),{attack=s.name,kit=data.fighterId,depth=r2(s.depth)})
				keep(rec,n,s.at,me,him,s.point)
			end
		end
		-- a contact the server counted on the other body
		local hit=other.impactSerial or 0
		local was=watch.serial[who]
		watch.serial[who]=hit
		if was and hit>was and data.attackName and not HOLDS[data.attackName] and (STRIKING[data.state] or data.state=="Recovery") then
			table.insert(watch.impacts,{who=who,att=att,vic=vic,name=data.attackName,at=now,style=other.impactStyle,kit=data.fighterId,
				roots=flat(att.root.Position-vic.root.Position).Magnitude})
		end
	end
	-- judged a tenth of a second later, over the frames around the contact
	for i=#watch.impacts,1,-1 do
		local imp=watch.impacts[i]
		if now-imp.at>=.1 then
			table.remove(watch.impacts,i)
			local best,limb,point=math.huge,nil,nil
			for _,f in ring do
				if f.t>=imp.at-.15 and f.t<=imp.at+.1 then
					-- the limbs and the body as drawn at that frame (its own tables: a body
					-- whose parts changed is indexed anew)
					local attB,attList=f.mb,f.me
					local vicB,vicList=f.hb,f.him
					if f.mb.model~=imp.att.model then attB,attList,vicB,vicList=f.hb,f.him,f.mb,f.me end
					local function at(b,list,part)
						local k=b.index[part]
						return (k and list[k]) or part.CFrame
					end
					for _,l in attB.limbs do
						local lp=at(attB,attList,l).Position
						local radius=math.min(l.Size.X,l.Size.Y,l.Size.Z)/2
						for _,v in vicB.own do
							local g=toBox(at(vicB,vicList,v),v.Size,lp)-radius
							if g<best then best,limb,point=g,l.Name.."→"..v.Name,lp end
						end
					end
				end
			end
			if best==math.huge then best,limb,point=contactGap(imp.att,imp.vic) end
			run.contacts=(run.contacts or 0)+1
			if best>Audit.LIMITS.far then
				local rec,n=note("de_loin",imp.who,string.format("%s touche à %.1f studs de tout membre (%s), racines à %.1f",imp.name,best,limb or "?",imp.roots),
					{attack=imp.name,kit=imp.kit,gap=r2(best),style=imp.style})
				keep(rec,n,imp.at,me,him,point)
			end
		end
	end
end

local function checkGround(now,dt,me,him,d)
	if now-watch.groundAt<.1 then return end
	watch.groundAt=now
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	local skip={me.model,him.model}
	local effects=me.model.Parent and me.model.Parent:FindFirstChild("Effects")
	if effects then table.insert(skip,effects) end
	-- (26/11) the effects of the duel (a substitution log lying there) are not the floor
	local fx=workspace:FindFirstChild("NinjaDuelFX")
	if fx then table.insert(skip,fx) end
	params.FilterDescendantsInstances=skip
	for _,side in {{"joueur",me,d.human},{"adversaire",him,d.bot}} do
		local who,b,data=side[1],side[2],side[3]
		if b.root then
			local hit=workspace:Raycast(b.root.Position+Vector3.new(0,3,0),Vector3.new(0,-80,0),params)
			local low=math.huge
			for _,p in b.own do low=math.min(low,lowest(p.CFrame,p.Size)) end
			local origin=d.origin
			watch.refY=watch.refY or {}
			if not watch.refY[who] and FREE[data.state] and not data.airborne and origin then watch.refY[who]=b.root.Position.Y-origin.Y end
			local gk="ground_"..who
			-- how deep his soles stand at rest (a body standing in the floor by design is said once)
			if hit and FREE[data.state] and not data.airborne and data.reaction==nil then
				run.standing=run.standing or {}
				local list=run.standing[who] or {};run.standing[who]=list
				if #list<400 then table.insert(list,hit.Position.Y-low) end
			end
			if hit and low<hit.Position.Y-Audit.LIMITS.ground then
				if not watch[gk] then
					watch[gk]=true
					local rec,n=note("dans_le_sol",who,string.format("le point le plus bas %.2f stud sous %s (%s)",hit.Position.Y-low,hit.Instance.Name,tostring(data.state)..(if data.reaction then "/"..data.reaction else "")),
						{depth=r2(hit.Position.Y-low),under=hit.Instance:GetFullName()})
					keep(rec,n,now,me,him,Vector3.new(b.root.Position.X,low,b.root.Position.Z))
				end
			elseif origin and watch.refY[who] and b.root.Position.Y<origin.Y+watch.refY[who]-Audit.LIMITS.below then
				if not watch[gk] then
					watch[gk]=true
					local rec,n=note("sous_le_sol",who,string.format("racine %.1f studs sous sa hauteur de départ",origin.Y+watch.refY[who]-b.root.Position.Y),{})
					keep(rec,n,now,me,him,b.root.Position)
				end
			else
				watch[gk]=nil
			end
		end
	end
end

local function checkCamera(now,dt,me,him,d)
	if now-watch.camAt<.1 then return end
	local step=if watch.camAt==0 then 0 else now-watch.camAt
	watch.camAt=now
	local cam=workspace.CurrentCamera
	if not cam then return end
	local p=cam.CFrame.Position
	local e=inside(p)
	if e then
		if not watch.camTold then
			watch.camTold=true
			local rec,n=note(if e.mesh then "camera_objet" else "camera_mur","caméra",string.format("dans %s (%s)",e.part:GetFullName(),e.part.ClassName),{part=e.part:GetFullName()})
			keep(rec,n,now,me,him,p+cam.CFrame.LookVector*2)
		end
	elseif inTerrain(p) then
		if not watch.camTold then
			watch.camTold=true
			local rec,n=note("camera_terrain","caméra","dans le terrain",{})
			keep(rec,n,now,me,him,p+cam.CFrame.LookVector*2)
		end
	else
		watch.camTold=false
	end
	for _,side in {{"me","joueur",me},{"him","adversaire",him}} do
		local k,who,b=side[1],side[2],side[3]
		if b.head and b.root then
			local e1=cut(p,b.head.Position)
			local e2=e1 and cut(p,b.root.Position)
			if e1 and e2 then
				watch.hidden[k]+=step
				if watch.hidden[k]>=Audit.LIMITS.hiddenFor and not watch["hid_"..k] then
					watch["hid_"..k]=true
					local rec,n=note("cache",who,string.format("caché par %s",e1.part:GetFullName()),{part=e1.part:GetFullName()})
					keep(rec,n,now,me,him,b.head.Position)
				end
			else
				watch.hidden[k]=0;watch["hid_"..k]=nil
			end
		end
	end
end

local function tick(dt)
	local d=snap
	local phase=d.phase
	if phase~=lastPhase then
		if phase=="Duel" and lastPhase~="Duel" then newRun() end
		if lastPhase=="Duel" and run then run.winner=d.winner;run.wins=d.wins;run.wall=os.clock()-run.started end
		lastPhase=phase
	end
	if phase~="Duel" or not run or not d.human or not d.bot then return end
	if not scenery and d.origin then
		local me0,him0=models()
		if me0 and him0 then
			local skip={me0.model,him0.model}
			local effects=me0.model.Parent and me0.model.Parent:FindFirstChild("Effects")
			if effects then table.insert(skip,effects) end
			local show=workspace:FindFirstChild("NDAuditShow")
			if show then table.insert(skip,show) end
			local fx=workspace:FindFirstChild("NinjaDuelFX")
			if fx then table.insert(skip,fx) end
			scenery=buildScenery(d.origin,skip);run.scenery=scenery.parts;run.sceneryBuilt=r2(scenery.built)
		end
	end
	if (d.intro or 0)>0 or d.ko or d.winner then
		if d.ko and not watch.koTold then watch.koTold=true;run.rounds+=1 end
		return
	end
	watch.koTold=false
	local me,him=models()
	if not me or not him or not me.root or not him.root then return end
	local now=os.clock()
	run.frames+=1;run.seconds+=dt
	push(now,me,him)
	for _,check in {checkBlocked,checkFrozen,checkOverlap,checkStrikes,checkGround,checkCamera} do
		local ok,err=pcall(check,now,dt,me,him,d)
		if not ok then run.checkErrors=(run.checkErrors or 0)+1;run.lastCheckError=tostring(err) end
	end
end

-- ------------------------------------------------------------------ the API
function Audit.sent(action,payload)
	if type(payload)=="table" and typeof(payload.direction)=="Vector3" then intent={dir=payload.direction,at=os.clock()} end
	if run and action~="Move" then run.presses=(run.presses or 0)+1 end
end
function Audit.start()
	Audit.stop()
	runs={};run=nil;errors={};warnings={};lastPhase="?"
	table.insert(conns,remote.OnClientEvent:Connect(function(data)
		if type(data)~="table" or (data.epoch or 0)<(snap.epoch or 0) then return end
		snap=data
	end))
	table.insert(conns,RunService.Heartbeat:Connect(function(dt) local ok,err=pcall(tick,dt) if not ok and run then run.tickError=tostring(err) end end))
	table.insert(conns,LogService.MessageOut:Connect(function(msg,kind)
		if string.find(msg,"NDDuelAudit",1,true) then return end
		local list=if kind==Enum.MessageType.MessageError then errors elseif kind==Enum.MessageType.MessageWarning then warnings else nil
		if not list then return end
		local short=string.sub(msg,1,220)
		local entry=list[short]
		if not entry then
			entry={n=0,first=os.clock(),kit=run and run.kit,phase=snap.phase};list[short]=entry
			if kind==Enum.MessageType.MessageError and run then note("erreur","client",short,{}) end
		end
		entry.n+=1
	end))
	local bot=_G.NDDuelBot
	if bot then bot.observer=Audit.sent end
	return "audit en route"..(if bot then " (branché sur NDDuelBot)" else " (sans NDDuelBot : pas de « bloqué »)")
end
function Audit.stop()
	for _,c in conns do c:Disconnect() end
	conns={}
	if _G.NDDuelBot and _G.NDDuelBot.observer==Audit.sent then _G.NDDuelBot.observer=nil end
end
function Audit.read()
	local out={runs={},errors={},warnings={}}
	for i,r in runs do
		local inc={}
		for _,x in r.incidents do
			local c={}
			for k,v in x do if k~="frame" then c[k]=v end end
			table.insert(inc,c)
		end
		local standing={}
		for who,list in r.standing or {} do
			local c=table.clone(list);table.sort(c)
			standing[who]={median=r2(c[math.max(1,math.ceil(#c/2))] or 0),worst=r2(c[#c] or 0),n=#c}
		end
		table.insert(out.runs,{index=i,standing=standing,kit=r.kit,rival=r.rival,fighter=r.fighter,avatar=r.avatar,first=r.first,seconds=r2(r.seconds),frames=r.frames,
			rounds=r.rounds,winner=r.winner,wins=r.wins,presses=r.presses,contacts=r.contacts,scenery=r.scenery,sceneryBuilt=r.sceneryBuilt,counts=r.counts,incidents=inc,
			checkErrors=r.checkErrors,lastCheckError=r.lastCheckError,tickError=r.tickError})
	end
	for msg,e in errors do table.insert(out.errors,{msg=msg,n=e.n,kit=e.kit,phase=e.phase}) end
	for msg,e in warnings do table.insert(out.warnings,{msg=msg,n=e.n,kit=e.kit,phase=e.phase}) end
	return HttpService:JSONEncode(out)
end
local shown=nil
-- (26/11) The game's camera module writes the camera every frame, even a
-- Scriptable one: the frame is held after it, at the end of the render step.
local HOLD="NDAuditShowCam"
function Audit.unshow()
	pcall(function() RunService:UnbindFromRenderStep(HOLD) end)
	if shown then
		if shown.folder then shown.folder:Destroy() end
		for _,g in shown.guis or {} do g.Enabled=true end
		local cam=workspace.CurrentCamera
		if cam then cam.CameraType=shown.camType or Enum.CameraType.Custom;cam.FieldOfView=shown.fov or 70 end
		shown=nil
	end
	return "ok"
end
-- The frame of an incident: both bodies where they were, a red mark and its
-- label, the screens hidden; the camera from the side of the two bodies
-- (view "back": the other side; view "seen": where the player's camera was).
function Audit.show(r,i,view)
	Audit.unshow()
	local rec=runs[r] and runs[r].incidents[i]
	if not rec or not rec.frame then return "pas d'image pour cet incident" end
	local f=rec.frame
	local folder=Instance.new("Folder");folder.Name="NDAuditShow";folder.Parent=workspace
	local roots={}
	for _,c in {f.me,f.him} do
		if c then
			local copy=c:Clone();copy.Parent=folder
			local root=copy:FindFirstChild("HumanoidRootPart")
			if root then table.insert(roots,root.Position) end
		end
	end
	local mark=f.mark or roots[1]
	if mark then
		local m=Instance.new("Part");m.Name="NDAuditMark";m.Shape=Enum.PartType.Ball;m.Size=Vector3.new(.5,.5,.5)
		m.Anchored=true;m.CanCollide=false;m.CanQuery=false;m.Material=Enum.Material.Neon;m.Color=Color3.fromRGB(255,40,40);m.Transparency=.25
		m.Position=mark;m.Parent=folder
		local g=Instance.new("BillboardGui");g.Size=UDim2.fromOffset(460,56);g.StudsOffset=Vector3.new(0,3.2,0);g.AlwaysOnTop=true;g.Parent=m
		local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=.3;t.BackgroundColor3=Color3.new(0,0,0)
		t.TextColor3=Color3.new(1,1,1);t.TextScaled=true;t.Font=Enum.Font.GothamBold
		t.Text=string.upper(rec.kind).." · "..tostring(rec.detail);t.Parent=g
	end
	local cam=workspace.CurrentCamera
	shown={folder=folder,camType=cam.CameraType,fov=cam.FieldOfView,guis={}}
	for _,g in player:WaitForChild("PlayerGui"):GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then g.Enabled=false;table.insert(shown.guis,g) end
	end
	cam.CameraType=Enum.CameraType.Scriptable
	if view=="seen" or not mark then
		cam.CFrame=f.cam
	else
		local a,b=roots[1] or mark,roots[2] or mark
		local line=Vector3.new(b.X-a.X,0,b.Z-a.Z)
		line=if line.Magnitude>.1 then line.Unit else Vector3.xAxis
		local side=line:Cross(Vector3.yAxis)*(if view=="back" then -1 else 1)
		local c=Vector3.new((a.X+b.X)/2,mark.Y,(a.Z+b.Z)/2)
		cam.FieldOfView=50
		cam.CFrame=CFrame.lookAt(c+side*9+Vector3.new(0,1.2,0),c)
	end
	local held,fov=cam.CFrame,cam.FieldOfView
	RunService:BindToRenderStep(HOLD,Enum.RenderPriority.Last.Value+10,function()
		local now=workspace.CurrentCamera
		if now then now.CameraType=Enum.CameraType.Scriptable;now.CFrame=held;now.FieldOfView=fov end
	end)
	return string.format("%s · %s (run %d, %s contre %s)",rec.kind,tostring(rec.detail),r,tostring(runs[r].kit),tostring(runs[r].rival))
end
-- The incidents that have a frame: {run, index, kind}.
function Audit.framed()
	local out={}
	for r,x in runs do for i,rec in x.incidents do if rec.frame then table.insert(out,{r,i,rec.kind}) end end end
	return HttpService:JSONEncode(out)
end
return Audit
