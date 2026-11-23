--!nocheck
-- NDCollisionBot (OUTILLEUR, passe commune 1, DEC-051): what the player goes
-- through in Konoha. François, 23/11: « les murs sont intangibles, comme les
-- toits ». The village is built twice: the server's parts stop the body
-- (Server/Hub), and each client hides them and draws the ANIMATEUR's models in
-- their place (Client/HubDress, Client/MeshKit). Where the two differ, the
-- player walks into what he sees, or bumps into what he does not see.
--
-- In a Play of a LAB copy (tools/lab/lab_place.py), Client, in Konoha:
--   Bot.survey({})  every unit of the village: its drawn triangles (the very
--                   pieces Client/HubDress puts there, rebuilt from MeshKit's
--                   data) against its solid parts, both ways:
--                     - drawn but not solid: points of the drawing farther than
--                       Bot.GAP from any solid part of the unit (a façade in
--                       front of its box, a roof above it, a tank, an eave);
--                     - solid but not drawn: points of the solid parts' faces
--                       farther than Bot.GAP from the drawing (an invisible wall).
--   Bot.walk({max=n})  the body: for each house, it walks into the façade on
--                   the street side and stops where the solid stops it; then
--                   it falls on the roof. How deep in the drawing it went.
--   Bot.read(from,count)  the results, a slice at a time (JSON).
-- Presentation-only reads; the walk moves the player's own body (a LAB copy).
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer

local Bot={}
Bot.GAP=1.5          -- farther than this from the other geometry: a gap the body feels
Bot.DENSITY=.5       -- samples per square stud of drawing (at most Bot.MAX_SAMPLES a unit)
Bot.MAX_SAMPLES=700
Bot.FACE_STEP=2      -- the grid on the solid parts' faces, in studs
Bot.MAX_FACE=900     -- face samples a unit, at most
Bot.SLICE=.008       -- seconds of work before the frame is given back
Bot.result={state="idle",units={},walk={}}
-- walked against with the houses of the plan (Shared/KonohaLayout.Buildings)
Bot.LANDMARKS={"KonohaGate","GateBooth","Ichiraku","ExamHall","HyugaCompound","UchihaGate","NakaShrine","Torii","MemorialStone","TrainingProps"}

local function r1(x) return math.floor(x*10+.5)/10 end
local function note(s) Bot.result.state=s;pcall(function() player:SetAttribute("NDCollisionState",s) end) end

local function client()
	local ps=player:WaitForChild("PlayerScripts")
	local folder=ps:FindFirstChild("NinjaDuelClient",true) or ps
	return require(folder:FindFirstChild("MeshKit",true)),require(folder:FindFirstChild("HubDress",true))
end

local budget=os.clock()
local function breathe()
	if os.clock()-budget>Bot.SLICE then task.wait();budget=os.clock() end
end

-- The drawing of a unit, in the world: a list of {a,b,c,piece} triangles,
-- the same pieces at the same spots as Client/HubDress.dress.
local unpacked={}
local function pieceData(MeshKit,spec)
	local t=unpacked[spec]
	if not t then
		local pos,_,tri=MeshKit.unpack(spec)
		t={pos=pos,tri=tri};unpacked[spec]=t
	end
	return t
end
function Bot.drawing(unit,MeshKit,HubDress)
	local name=unit:GetAttribute("Dress")
	local fallback=false
	if not MeshKit.has(name) then
		name=unit:GetAttribute("DressFallback")
		if not name or not MeshKit.has(name) then return nil,nil end
		fallback=true
	end
	local specs=MeshKit.Data[name] or {}
	local tris={}
	for _,spot in HubDress.spots(unit,fallback) do
		local s=spot.scale
		for _,spec in specs do
			local d=pieceData(MeshKit,spec)
			local cf=spot.at*CFrame.new(Vector3.new(spec.o[1],spec.o[2],spec.o[3])*s)
			local w=table.create(#d.pos)
			for i,p in d.pos do w[i]=cf:PointToWorldSpace(p*s) end
			for k=1,#d.tri,3 do
				table.insert(tris,{w[d.tri[k]],w[d.tri[k+1]],w[d.tri[k+2]],spec.name})
			end
			breathe()
		end
	end
	return tris,name
end

-- The unit's solid parts (what stops the body there).
local function solids(unit,HubDress)
	local list={}
	for _,p in HubDress.parts(unit) do
		if p.CanCollide then table.insert(list,p) end
	end
	for _,d in unit:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Keep") and d.CanCollide then table.insert(list,d) end
	end
	return list
end

-- Distance from a point to a part's solid (0 inside).
local function obb(part,p)
	local l=part.CFrame:PointToObjectSpace(p)
	local h=part.Size/2
	local dx=math.max(math.abs(l.X)-h.X,0)
	local dy=math.max(math.abs(l.Y)-h.Y,0)
	local dz=math.max(math.abs(l.Z)-h.Z,0)
	return math.sqrt(dx*dx+dy*dy+dz*dz)
end
local closest=nil
local function distPart(part,p)
	if part:IsA("Part") and part.Shape==Enum.PartType.Block then return obb(part,p) end
	if closest~=false then
		local ok,q=pcall(function() return part:GetClosestPointOnSurface(p) end)
		if ok and typeof(q)=="Vector3" then
			closest=true
			-- the closest point of the surface; the point itself when inside
			return (q-p).Magnitude
		end
		closest=false
	end
	return obb(part,p)
end
local function distSolids(list,p,stop)
	local best=math.huge
	for _,part in list do
		local d=distPart(part,p)
		if d<best then best=d;if best<=stop then break end end
	end
	return best
end

-- Point to triangle distance (Ericson, Real-Time Collision Detection 5.1.5).
local function distTri(p,a,b,c)
	local ab,ac,ap=b-a,c-a,p-a
	local d1,d2=ab:Dot(ap),ac:Dot(ap)
	if d1<=0 and d2<=0 then return (p-a).Magnitude end
	local bp=p-b
	local d3,d4=ab:Dot(bp),ac:Dot(bp)
	if d3>=0 and d4<=d3 then return (p-b).Magnitude end
	local vc=d1*d4-d3*d2
	if vc<=0 and d1>=0 and d3<=0 then local v=d1/(d1-d3);return (p-(a+ab*v)).Magnitude end
	local cp=p-c
	local d5,d6=ab:Dot(cp),ac:Dot(cp)
	if d6>=0 and d5<=d6 then return (p-c).Magnitude end
	local vb=d5*d2-d1*d6
	if vb<=0 and d2>=0 and d6<=0 then local w=d2/(d2-d6);return (p-(a+ac*w)).Magnitude end
	local va=d3*d6-d5*d4
	if va<=0 and (d4-d3)>=0 and (d5-d6)>=0 then
		local w=(d4-d3)/((d4-d3)+(d5-d6));return (p-(b+(c-b)*w)).Magnitude
	end
	local denom=1/(va+vb+vc)
	local v,w=vb*denom,vc*denom
	return (p-(a+ab*v+ac*w)).Magnitude
end

-- Ray to triangle (Möller-Trumbore): the distance along the unit ray, or nil.
local function rayTri(o,dir,a,b,c)
	local e1,e2=b-a,c-a
	local pv=dir:Cross(e2)
	local det=e1:Dot(pv)
	if math.abs(det)<1e-9 then return nil end
	local inv=1/det
	local tv=o-a
	local u=tv:Dot(pv)*inv
	if u<0 or u>1 then return nil end
	local qv=tv:Cross(e1)
	local v=dir:Dot(qv)*inv
	if v<0 or u+v>1 then return nil end
	local t=e2:Dot(qv)*inv
	return if t>0 then t else nil
end
function Bot.rayDrawing(tris,o,dir,far)
	local best=far or math.huge
	local hit=nil
	for _,t in tris do
		local d=rayTri(o,dir,t[1],t[2],t[3])
		if d and d<best then best=d;hit=t end
	end
	return if hit then best else nil,hit
end

-- A grid of the drawing's triangles, for the distance from the solid faces.
local CELL=3
local function key(x,y,z) return x..","..y..","..z end
local function grid(tris)
	local g={}
	for i,t in tris do
		local lo=t[1]:Min(t[2]):Min(t[3])
		local hi=t[1]:Max(t[2]):Max(t[3])
		for x=math.floor(lo.X/CELL),math.floor(hi.X/CELL) do
			for y=math.floor(lo.Y/CELL),math.floor(hi.Y/CELL) do
				for z=math.floor(lo.Z/CELL),math.floor(hi.Z/CELL) do
					local k=key(x,y,z)
					local cell=g[k]
					if not cell then cell={};g[k]=cell end
					table.insert(cell,i)
				end
			end
		end
	end
	return g
end
local function distDrawing(g,tris,p,stop)
	local best=math.huge
	local cx,cy,cz=math.floor(p.X/CELL),math.floor(p.Y/CELL),math.floor(p.Z/CELL)
	local seen={}
	for x=cx-1,cx+1 do for y=cy-1,cy+1 do for z=cz-1,cz+1 do
		local cell=g[key(x,y,z)]
		if cell then
			for _,i in cell do
				if not seen[i] then
					seen[i]=true
					local t=tris[i]
					local d=distTri(p,t[1],t[2],t[3])
					if d<best then best=d;if best<=stop then return best end end
				end
			end
		end
	end end end
	return best
end

local function plan(HubMap,p)
	local o=HubMap.Origin or Vector3.zero
	return {r1(p.X-o.X),r1(p.Z-o.Z)}
end

-- One unit, both ways.
function Bot.unit(unit,MeshKit,HubDress,HubMap,seed)
	local tris,model=Bot.drawing(unit,MeshKit,HubDress)
	local list=solids(unit,HubDress)
	local base=unit:GetAttribute("DressAt")
	local row={u=unit.Name,model=model or unit:GetAttribute("Dress"),at=if typeof(base)=="CFrame" then plan(HubMap,base.Position) else nil,
		solids=#list,tris=tris and #tris or 0}
	if not tris or #tris==0 or #list==0 then row.skip=if not tris then "no drawing" elseif #list==0 then "no solid" else "empty" end return row end
	local baseY=if typeof(base)=="CFrame" then base.Position.Y else 0
	-- the drawing, sampled by area
	local area=0
	local areas=table.create(#tris)
	for i,t in tris do
		local a=(t[2]-t[1]):Cross(t[3]-t[1]).Magnitude/2
		areas[i]=a;area+=a
	end
	local n=math.min(Bot.MAX_SAMPLES,math.max(30,math.floor(area*Bot.DENSITY)))
	local rng=Random.new(seed)
	local each=area/n
	local kinds={facade={area=0,cross=0,max=0},roof={area=0,cross=0,max=0},under={area=0,cross=0,max=0}}
	local pieces={}
	local worst=nil
	local acc=0
	local i=1
	for k=1,n do
		local target=(k-rng:NextNumber())*each
		while i<#tris and acc+areas[i]<target do acc+=areas[i];i+=1 end
		local t=tris[i]
		local u,v=rng:NextNumber(),rng:NextNumber()
		if u+v>1 then u,v=1-u,1-v end
		local p=t[1]+(t[2]-t[1])*u+(t[3]-t[1])*v
		local nrm=(t[2]-t[1]):Cross(t[3]-t[1])
		nrm=if nrm.Magnitude>1e-9 then nrm.Unit else Vector3.yAxis
		local kind=if nrm.Y>.5 then "roof" elseif nrm.Y<-.5 then "under" else "facade"
		local gap=distSolids(list,p,Bot.GAP)
		local K=kinds[kind]
		K.area+=each
		if gap>Bot.GAP then
			K.cross+=each
			local g=math.min(gap,20)
			if g>K.max then K.max=g end
			pieces[t[4]]=(pieces[t[4]] or 0)+each
			if kind~="under" and (not worst or g>worst.gap) then
				worst={gap=r1(g),kind=kind,piece=t[4],at=plan(HubMap,p),y=r1(p.Y-baseY)}
			end
		end
		breathe()
	end
	for _,K in kinds do K.area=r1(K.area);K.cross=r1(K.cross);K.max=r1(K.max) end
	row.drawn=r1(area);row.facade=kinds.facade;row.roof=kinds.roof;row.under=kinds.under;row.worst=worst
	local top={}
	for name,a in pieces do table.insert(top,{name,r1(a)}) end
	table.sort(top,function(a,b) return a[2]>b[2] end)
	row.pieces={table.unpack(top,1,math.min(4,#top))}
	-- the solid faces, against the drawing
	local g=grid(tris)
	local ghost,faces,ghostMax=0,0,0
	local ghostAt=nil
	local count=0
	for _,part in list do
		local h=part.Size/2
		for axis=1,3 do
			for sign=-1,1,2 do
				local nx=if axis==1 then sign else 0
				local ny=if axis==2 then sign else 0
				local nz=if axis==3 then sign else 0
				local su=if axis==1 then h.Y else h.X
				local sv=if axis==3 then h.Y else h.Z
				local nu=math.max(1,math.floor(su*2/Bot.FACE_STEP))
				local nv=math.max(1,math.floor(sv*2/Bot.FACE_STEP))
				local cell=(su*2/nu)*(sv*2/nv)
				for a=1,nu do for b=1,nv do
					if count>=Bot.MAX_FACE then break end
					local fu=-su+(a-.5)*su*2/nu
					local fv=-sv+(b-.5)*sv*2/nv
					local l=if axis==1 then Vector3.new(sign*h.X,fu,fv) elseif axis==2 then Vector3.new(fu,sign*h.Y,fv) else Vector3.new(fu,fv,sign*h.Z)
					local p=part.CFrame:PointToWorldSpace(l)
					-- a face inside another solid of the unit is not a face
					local hidden=false
					for _,other in list do
						if other~=part and distPart(other,p+part.CFrame:VectorToWorldSpace(Vector3.new(nx,ny,nz))*.2)<=0 then hidden=true;break end
					end
					if hidden then continue end
					-- under the ground: not reached
					if p.Y<baseY+.5 then continue end
					count+=1;faces+=cell
					local d=distDrawing(g,tris,p,Bot.GAP)
					if d>Bot.GAP then
						ghost+=cell
						local dd=math.min(d,20)
						if dd>ghostMax then ghostMax=dd;ghostAt={at=plan(HubMap,p),y=r1(p.Y-baseY),part=part.Name} end
					end
					breathe()
				end end
			end
		end
	end
	row.faces=r1(faces);row.ghost=r1(ghost);row.ghostMax=r1(ghostMax);row.ghostAt=ghostAt
	return row
end

function Bot.survey(opts)
	opts=opts or {}
	if Bot.result.state=="survey" then return "already running" end
	local MeshKit,HubDress=client()
	local HubMap=require(game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("HubMap"))
	local root=workspace:FindFirstChild("NinjaDuelHub")
	if not root then return "no village" end
	if MeshKit.state~="ready" then return "MeshKit "..tostring(MeshKit.state) end
	Bot.result.units={};Bot.result.gap=Bot.GAP;Bot.result.closest=nil
	local units=HubDress.units(root)
	if opts.only then
		local keep={}
		for _,u in units do if string.find(u.Name,opts.only,1,true) or string.find(tostring(u:GetAttribute("Dress")),opts.only,1,true) then table.insert(keep,u) end end
		units=keep
	end
	if opts.max then units={table.unpack(units,1,math.min(opts.max,#units))} end
	task.spawn(function()
		local t0=os.clock()
		for i,unit in units do
			note("survey "..i.."/"..#units)
			local ok,row=pcall(Bot.unit,unit,MeshKit,HubDress,HubMap,i)
			if not ok then row={u=unit.Name,error=tostring(row)} end
			table.insert(Bot.result.units,row)
			unpacked={}
		end
		Bot.result.closest=closest
		Bot.result.seconds=r1(os.clock()-t0)
		note("survey done")
	end)
	return "survey of "..#units.." units"
end

-- The body against the drawing.
local function body()
	local c=player.Character
	return c and c:FindFirstChild("HumanoidRootPart"),c and c:FindFirstChildOfClass("Humanoid")
end
local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude;rayParams.RespectCanCollide=true
local function solidRay(o,d)
	rayParams.FilterDescendantsInstances={player.Character}
	return workspace:Raycast(o,d,rayParams)
end
local function settle(root,hum,limit)
	local t0=os.clock()
	while os.clock()-t0<limit do
		task.wait(.05)
		if hum.FloorMaterial~=Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y)<1 then return true end
	end
	return false
end

function Bot.walkOne(unit,MeshKit,HubDress,HubMap)
	local root,hum=body()
	if not root or not hum then return {u=unit.Name,error="no body"} end
	local tris,model=Bot.drawing(unit,MeshKit,HubDress)
	if not tris or #tris==0 then return {u=unit.Name,skip="no drawing"} end
	local lo,hi=Vector3.one*math.huge,-Vector3.one*math.huge
	for _,t in tris do lo=lo:Min(t[1]):Min(t[2]):Min(t[3]);hi=hi:Max(t[1]):Max(t[2]):Max(t[3]) end
	local base=unit:GetAttribute("DressAt")
	local cf=if typeof(base)=="CFrame" then base else CFrame.new((lo+hi)/2)
	local centre=Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2)
	local row={u=unit.Name,model=model,at=plan(HubMap,centre),height=r1(hi.Y-lo.Y)}
	-- the street side: the side with the most room before a solid
	local best,dir=-1,nil
	for _,d in {cf.LookVector,-cf.LookVector,cf.RightVector,-cf.RightVector} do
		d=Vector3.new(d.X,0,d.Z).Unit
		local half=math.abs((hi-lo).X*d.X)/2+math.abs((hi-lo).Z*d.Z)/2
		local from=centre+d*(half+1)+Vector3.new(0,3,0)
		local hit=solidRay(from,d*30)
		local room=if hit then hit.Distance else 30
		if room>best then best=room;dir=d end
	end
	if best<7 then row.facade={skip="no street ("..r1(best)..")"} else
		local half=math.abs((hi-lo).X*dir.X)/2+math.abs((hi-lo).Z*dir.Z)/2
		local start=centre+dir*(half+6)
		local ground=solidRay(start+Vector3.new(0,25,0),Vector3.new(0,-60,0))
		local gy=if ground then ground.Position.Y else lo.Y
		local hip=hum.HipHeight+root.Size.Y/2
		local o=Vector3.new(start.X,gy+hip,start.Z)
		-- the drawing and the solid ahead, at the body's heights
		local seen,solid=nil,nil
		for _,y in {gy+1,gy+3,gy+5} do
			local p=Vector3.new(o.X,y,o.Z)
			local d=Bot.rayDrawing(tris,p,-dir,20)
			if d and (not seen or d<seen) then seen=d end
			local h=solidRay(p,-dir*20)
			if h and (not solid or h.Distance<solid) then solid=h.Distance end
		end
		row.facade={drawn=seen and r1(seen),solid=solid and r1(solid)}
		if seen then
			root.AssemblyLinearVelocity=Vector3.zero
			root.CFrame=CFrame.lookAt(o,o-dir)
			settle(root,hum,1)
			local from=root.Position
			local last,since=from,os.clock()
			local conn=RunService.Stepped:Connect(function() hum.WalkSpeed=16;hum:Move(-dir,false) end)
			local t0=os.clock()
			while os.clock()-t0<3 do
				task.wait(.05)
				if (root.Position-last).Magnitude>.05 then last=root.Position;since=os.clock() end
				if os.clock()-since>.4 then break end
			end
			conn:Disconnect();hum:Move(Vector3.zero,false)
			local went=(root.Position-from):Dot(-dir)
			local front=root.Size.Z/2
			row.facade.went=r1(went)
			-- how far the body's front is inside the drawn façade
			row.facade.into=r1(went+front-seen)
		end
	end
	-- the roof: dropped on the drawing's highest point near the middle
	local top=Vector3.new(centre.X,hi.Y+30,centre.Z)
	local seenDown=Bot.rayDrawing(tris,top,-Vector3.yAxis,hi.Y-lo.Y+40)
	if seenDown then
		local roofY=top.Y-seenDown
		local solidHit=solidRay(top,Vector3.new(0,-(hi.Y-lo.Y+40),0))
		root.AssemblyLinearVelocity=Vector3.zero
		root.CFrame=CFrame.new(centre.X,roofY+6,centre.Z)
		local landed=settle(root,hum,2.5)
		local feet=root.Position.Y-hum.HipHeight-root.Size.Y/2
		row.roof={drawn=r1(roofY-lo.Y),solid=solidHit and r1(solidHit.Position.Y-lo.Y) or nil,feet=r1(feet-lo.Y),sink=r1(roofY-feet),landed=landed}
	else
		row.roof={skip="no drawing above the middle"}
	end
	return row
end

function Bot.walk(opts)
	opts=opts or {}
	if Bot.result.state=="walk" then return "already running" end
	local MeshKit,HubDress=client()
	local HubMap=require(game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("HubMap"))
	local root=workspace:FindFirstChild("NinjaDuelHub")
	if not root then return "no village" end
	-- the houses and the landmarks: what one walks against and onto
	local big={}
	pcall(function()
		local Layout=require(game:GetService("ReplicatedStorage").NinjaDuel.KonohaLayout)
		for _,b in Layout.Buildings do big[b[1]]=true end
	end)
	for _,name in Bot.LANDMARKS do big[name]=true end
	local units={}
	for _,u in HubDress.units(root) do
		local name=tostring(u:GetAttribute("Dress"))
		if opts.all or big[name] or u:GetAttribute("DressFallback") or string.find(name,"House") then table.insert(units,u) end
	end
	if opts.only then
		local keep={}
		for _,u in units do if string.find(u.Name,opts.only,1,true) or string.find(tostring(u:GetAttribute("Dress")),opts.only,1,true) then table.insert(keep,u) end end
		units=keep
	end
	if opts.max then units={table.unpack(units,1,math.min(opts.max,#units))} end
	Bot.result.walk={}
	task.spawn(function()
		local t0=os.clock()
		for i,unit in units do
			note("walk "..i.."/"..#units)
			local ok,row=pcall(Bot.walkOne,unit,MeshKit,HubDress,HubMap)
			if not ok then row={u=unit.Name,error=tostring(row)} end
			table.insert(Bot.result.walk,row)
			unpacked={}
		end
		Bot.result.walkSeconds=r1(os.clock()-t0)
		note("walk done")
	end)
	return "walk of "..#units.." units"
end

-- A slice of the results, as JSON (the attribute keeps only the state).
function Bot.read(which,from,count)
	local list=Bot.result[which or "units"] or {}
	from=from or 1
	count=count or 40
	return HttpService:JSONEncode({state=Bot.result.state,n=#list,from=from,gap=Bot.GAP,closest=Bot.result.closest,
		seconds=Bot.result.seconds,walkSeconds=Bot.result.walkSeconds,rows={table.unpack(list,from,math.min(#list,from+count-1))}})
end

return Bot
