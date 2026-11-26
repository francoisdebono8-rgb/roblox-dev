-- The outfit check, on the client (OUTILLEUR, passe commune 2, 26/11; DEC-054:
-- « il dit quelle pièce traverse ou flotte, sur quel corps »).
--
-- A client module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py outfit
-- after the server has put the row of avatars there, dressed
-- (tools/outfitcheck/outfit_bodies.luau, NDOutfitBodies). For each body of the
-- row and each modelled piece the client put on it (Client/OutfitDress), it
-- takes the piece's own vertices (Shared/OutfitMeshes, unpacked as
-- Client/MeshKit does) where the piece stands, and measures each one against
-- the body under it: a ray from outside the vertex toward the bone of the
-- body part it is worn on, against that limb's parts (or the torso, or the
-- head). The ray meets the body's surface
--   before the vertex: the vertex is inside the body by that much: the body
--                      comes through the cloth there (traverse);
--   after the vertex:  the cloth stands off the body by that much (flotte).
-- The poses: the rest (the skeleton at rest) and frames of the game's own
-- clips (Client/AuthoredMotion, the motion engine's data) set on the joints,
-- as the engine sets them: the cloth in motion.
--
--   _G.NDOutfitCheck.measure({look="SetLee", clips={"Lion.Idle",…}})  (yields: a few seconds)
--   _G.NDOutfitCheck.pose("Lion.Heavy",.3) / .rest()   the row in a pose, for captures
--   _G.NDOutfitCheck.play({"Lion.Run",…})  /  .stop()  the row in motion (for a video)
--   _G.NDOutfitCheck.camera("front"|"back"|"side")     the capture camera on the row
--   _G.NDOutfitCheck.compact(json) / .summary({look=compact,...})  the numbers, short
-- The body's surface is its parts' collision shape (Roblox's, from the
-- avatar's meshes): close to the drawn mesh on a limb, rounder in a hollow.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local ClientFolder=player:WaitForChild("PlayerScripts"):WaitForChild("NinjaDuelClient")
local OutfitMeshes=require(RS.NinjaDuel.OutfitMeshes)
local MeshKit=require(ClientFolder.MeshKit)
local Authored=require(ClientFolder.AuthoredMotion)
local okShop,Shop=pcall(function() return require(RS.NinjaDuel.Shop) end)

local Check={}
Check.SAMPLES=260
Check.INSIDE=.05   -- a vertex deeper than this in the body: the body shows through
Check.OFF=.25      -- a vertex farther than this from the body: the cloth stands off
Check.CLIPS={{"Lion.Idle",0},{"Lion.Run",.15},{"Lion.Run",.45},{"Lion.Light1",.2},{"Lion.Heavy",.3},{"Lion.Guard",.2},
	{"Lion.Jump.Air",.2},{"Lion.Hit.Body",.15},{"Lion.Grab",.25},{"Lion.Knockdown",.5}}
local MOTOR={Right="RightShoulder",Left="LeftShoulder"}
local CHAIN={
	UpperTorso={"UpperTorso","LowerTorso"},LowerTorso={"LowerTorso","UpperTorso"},Head={"Head"},
}
for _,side in {"Right","Left"} do
	local arm={side.."UpperArm",side.."LowerArm",side.."Hand"}
	local leg={side.."UpperLeg",side.."LowerLeg",side.."Foot"}
	for _,n in arm do CHAIN[n]=arm end
	for _,n in leg do CHAIN[n]=leg end
end
-- pieces made to hang off the body: the kinds cape, back, hair, and in a
-- set the slots of a cape, a scarf, hair, a scroll, a sheath, a gourd
local LOOSE_KIND={cape=true,back=true,hair=true}
local LOOSE_SLOT={Cape=true,Scarf=true,Hair=true,Paper=true,Wood=true,Sheath=true,Grip=true,Gourd=true}
local function loose(item,slot)
	local c=OutfitMeshes.Catalog and OutfitMeshes.Catalog[item]
	local kind=c and c.kind
	if not kind and okShop and Shop.item then local it=Shop.item(item);kind=it and it.slot end
	if LOOSE_KIND[kind or ""] then return true,kind end
	return LOOSE_SLOT[slot or ""]==true,kind
end

local function r2(x) return math.floor(x*100+.5)/100 end
local function row()
	local f=workspace:FindFirstChild("NDOutfitBodies")
	local out={}
	if not f then return out end
	for _,m in f:GetChildren() do if m:IsA("Model") and m:GetAttribute("NDBodyKey") then table.insert(out,m) end end
	table.sort(out,function(a,b) return a:GetPivot().Position.X<b:GetPivot().Position.X end)
	return out
end
local function motors(model)
	local j={}
	for _,d in model:GetDescendants() do if d:IsA("Motor6D") then j[d.Name]=d end end
	return j
end

-- ------------------------------------------------------------------ poses
local held=nil
local heldConn=nil
local function hold(poseOf)
	held=poseOf
	if heldConn then return end
	heldConn=(RunService.PreSimulation or RunService.Stepped):Connect(function()
		if not held then return end
		for _,m in row() do
			local p=held(m)
			if p then
				local j=motors(m)
				for name,cf in p do local mo=j[MOTOR[name] or name];if mo then mo.Transform=cf end end
			end
		end
	end)
end
local function settle() for _=1,3 do RunService.PostSimulation:Wait() end end
function Check.rest()
	held=nil
	for _,m in row() do for _,mo in motors(m) do mo.Transform=CFrame.identity end end
	settle()
	return "repos"
end
function Check.pose(name,t)
	local p=Authored.sample(name,t or 0)
	if not p then return "pas de clip "..tostring(name) end
	hold(function() return p end)
	settle()
	return "pose "..name.." "..tostring(t)
end
local playing=nil
function Check.play(list)
	list=list or {"Lion.Run","Lion.Light1","Lion.Heavy","Lion.Jump.Air","Lion.Guard"}
	local t0=os.clock()
	playing=list
	hold(function()
		if not playing then return nil end
		local total=0
		for _,n in playing do total+=math.max(.3,Authored.length(n)) end
		local t=(os.clock()-t0)%math.max(total,.3)
		for _,n in playing do
			local len=math.max(.3,Authored.length(n))
			if t<len then return Authored.sample(n,t) end
			t-=len
		end
		return nil
	end)
	return "en mouvement : "..table.concat(list,", ")
end
function Check.stop() playing=nil;return Check.rest() end

-- ------------------------------------------------------------------ the camera
function Check.camera(view)
	local bodies=row()
	if #bodies==0 then return "pas de rangée" end
	local a,b=bodies[1]:GetPivot().Position,bodies[#bodies]:GetPivot().Position
	local c=(a+b)/2+Vector3.new(0,.4,0)
	local dist=(b-a).Magnitude*.62+6
	local cam=workspace.CurrentCamera
	cam.CameraType=Enum.CameraType.Scriptable
	cam.FieldOfView=40
	local at=if view=="back" then c+Vector3.new(0,1,dist) elseif view=="side" then c+Vector3.new(-dist*.9,1,-dist*.35) else c+Vector3.new(0,1,-dist)
	cam.CFrame=CFrame.lookAt(at,c)
	return view or "front"
end
function Check.release()
	local cam=workspace.CurrentCamera
	cam.CameraType=Enum.CameraType.Custom;cam.FieldOfView=70
	return "caméra rendue"
end

-- ------------------------------------------------------------------ the pieces
local specsOf={}
local unpacked={}
local function specs(id)
	local model=OutfitMeshes.Items[id]
	if not model then return {} end
	local list=specsOf[model]
	if list then return list end
	list={}
	for _,spec in OutfitMeshes.Models[model] or {} do table.insert(list,spec) end
	specsOf[model]=list
	return list
end
-- The modelled pieces worn on a body: {part, spec, on, item}.
local function worn(model)
	local folder=model:FindFirstChild("NinjaOutfitMesh")
	local holder=model:FindFirstChild("NinjaOutfit")
	if not folder or not holder then return nil end
	local ids=string.split(holder:GetAttribute("NinjaOutfit") or "",",")
	local pool={}
	for _,id in ids do for _,spec in specs(id) do table.insert(pool,{spec=spec,item=id}) end end
	local out={}
	local used={}
	for _,p in folder:GetChildren() do
		if p:IsA("BasePart") then
			local weld=p:FindFirstChildOfClass("WeldConstraint")
			local on=weld and weld.Part0 and weld.Part0.Name
			for k,e in pool do
				if not used[k] and e.spec.name==p.Name and e.spec.on==on then
					used[k]=true
					table.insert(out,{part=p,spec=e.spec,on=on,item=e.item,slot=e.spec.slot})
					break
				end
			end
		end
	end
	return out
end
local function vertices(spec)
	local v=unpacked[spec]
	if v then return v end
	local ok,pos=pcall(function() local p=MeshKit.unpack(spec);return p end)
	v=if ok and pos then pos else {}
	unpacked[spec]=v
	return v
end

-- One piece on one body, in the pose it stands in now.
local function measurePiece(model,piece,params)
	local body=model:FindFirstChild(piece.on)
	if not body then return nil end
	local chain={}
	for _,n in CHAIN[piece.on] or {piece.on} do local p=model:FindFirstChild(n);if p then table.insert(chain,p) end end
	params.FilterDescendantsInstances=chain
	local h=piece.spec.h
	local scale=Vector3.new(piece.part.Size.X/(2*h[1]),piece.part.Size.Y/(2*h[2]),piece.part.Size.Z/(2*h[3]))
	local cf=piece.part.CFrame
	local pos=vertices(piece.spec)
	local n=#pos
	if n==0 then return nil end
	local stride=math.max(1,math.floor(n/Check.SAMPLES))
	local bcf,bs=body.CFrame,body.Size
	local axisZ=string.find(piece.on,"Foot")~=nil
	local count,inside,off,nohit=0,0,0,0
	local maxIn,maxOff=0,0
	local gaps={}
	local worstIn,worstOff=nil,nil
	for i=1,n,stride do
		local v=cf*(pos[i]*scale)
		local l=bcf:PointToObjectSpace(v)
		local c
		if piece.on=="Head" then c=bcf.Position
		elseif axisZ then c=bcf*Vector3.new(0,0,math.clamp(l.Z,-bs.Z/2,bs.Z/2))
		else c=bcf*Vector3.new(0,math.clamp(l.Y,-bs.Y/2,bs.Y/2),0) end
		local out=v-c
		local d=out.Magnitude
		if d>.03 then
			local u=out/d
			local from=v+u*1.2
			local hit=workspace:Raycast(from,-u*(1.2+d),params)
			count+=1
			if hit then
				local t=(hit.Position-from):Dot(-u)
				local depth=1.2-t
				if depth>Check.INSIDE then
					inside+=1
					if depth>maxIn then maxIn=depth;worstIn=v end
				elseif -depth>Check.OFF then
					off+=1
					if -depth>maxOff then maxOff=-depth;worstOff=v end
				end
				table.insert(gaps,-depth)
			else
				nohit+=1
			end
		end
	end
	if count==0 then return nil end
	table.sort(gaps)
	local function pct(q) return if #gaps>0 then r2(gaps[math.max(1,math.ceil(#gaps*q))]) else nil end
	return {n=count,inside=r2(inside/count),maxIn=r2(maxIn),off=r2(off/count),maxOff=r2(maxOff),nohit=r2(nohit/count),
		median=pct(.5),p90=pct(.9),worstIn=worstIn,worstOff=worstOff}
end

local function bodyParts(model,on)
	for _,d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then d.CanQuery=on end
	end
end

-- Measures the row in the rest pose and in each clip frame of Check.CLIPS.
-- The result: per body, per piece: the worst frame for "traverse" and for
-- "flotte", with its numbers.
function Check.measure(options)
	options=options or {}
	local bodies=row()
	if #bodies==0 then return HttpService:JSONEncode({error="pas de rangée (NDOutfitBodies.dress)"}) end
	-- the modelled pieces on: the client's OutfitDress builds them (yields)
	local t0=os.clock()
	while os.clock()-t0<20 do
		local all=true
		for _,m in bodies do if not m:FindFirstChild("NinjaOutfitMesh") then all=false end end
		if all then break end
		task.wait(.2)
	end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	local poses={{"repos",nil,0}}
	for _,c in options.clips or Check.CLIPS do if Authored.has(c[1]) then table.insert(poses,{c[1].."@"..c[2],c[1],c[2]}) end end
	local result={look=options.look,poses={},bodies={}}
	for _,p in poses do table.insert(result.poses,p[1]) end
	local per={}
	for _,m in bodies do bodyParts(m,true) end
	for _,p in poses do
		if p[2] then Check.pose(p[2],p[3]) else Check.rest() end
		for _,m in bodies do
			local key=m:GetAttribute("NDBodyKey")
			per[key]=per[key] or {label=m:GetAttribute("NDBodyLabel"),pieces={}}
			for _,piece in worn(m) or {} do
				local name=piece.item.."/"..piece.part.Name
				local rec=per[key].pieces[name]
				if not rec then
					local hangs,kind=loose(piece.item,piece.slot)
					rec={item=piece.item,kind=kind,piece=piece.part.Name,slot=piece.slot,on=piece.on,loose=hangs,rest=nil,worstIn=nil,worstOff=nil}
					per[key].pieces[name]=rec
				end
				local ok,mm=pcall(measurePiece,m,piece,params)
				if ok and mm then
					mm.worstIn=nil;mm.worstOff=nil
					if p[1]=="repos" then rec.rest=mm end
					if not rec.worstIn or mm.inside>rec.worstIn.inside then rec.worstIn=mm;rec.worstInPose=p[1] end
					if not rec.worstOff or mm.off>rec.worstOff.off then rec.worstOff=mm;rec.worstOffPose=p[1] end
				elseif not ok then rec.error=tostring(mm) end
			end
		end
	end
	for _,m in bodies do bodyParts(m,false) end
	Check.rest()
	for key,b in per do
		local list={}
		for _,rec in b.pieces do table.insert(list,rec) end
		table.sort(list,function(a,c) return a.item..a.piece<c.item..c.piece end)
		result.bodies[key]={label=b.label,pieces=list}
	end
	result.seconds=r2(os.clock()-t0)
	return HttpService:JSONEncode(result)
end
-- (26/11) One look's measure, per item: the worst share of points inside
-- (and its pose, its piece), the worst share standing off, the rest pose.
function Check.compact(txt)
	local d=HttpService:JSONDecode(txt)
	local out={look=d.look,seconds=d.seconds,poses=#d.poses,bodies={}}
	for key,b in d.bodies do
		local items={}
		for _,p in b.pieces do
			local it=items[p.item] or {item=p.item,kind=p.kind,pieces=0,inMax=0,inShare=0,offMax=0,offShare=0,restIn=0,restOff=0,loose=p.loose}
			items[p.item]=it
			it.pieces+=1
			local wi,wo,re=p.worstIn or {},p.worstOff or {},p.rest or {}
			if (wi.inside or 0)>it.inShare then it.inShare=wi.inside;it.inPose=p.worstInPose;it.inPiece=p.piece end
			it.inMax=math.max(it.inMax,wi.maxIn or 0)
			if (wo.off or 0)>it.offShare then it.offShare=wo.off;it.offPose=p.worstOffPose;it.offPiece=p.piece end
			it.offMax=math.max(it.offMax,wo.maxOff or 0)
			it.restIn=math.max(it.restIn,re.inside or 0);it.restOff=math.max(it.restOff,re.off or 0)
		end
		local list={}
		for _,it in items do table.insert(list,it) end
		out.bodies[key]=list
	end
	return HttpService:JSONEncode(out)
end
-- Many looks at once ({look = Check.compact(...)}): François's numbers per
-- item, and the bodies whose numbers differ (tools/outfitcheck/report.py reads it).
function Check.summary(results)
	local out={}
	for look,txt in results do
		local d=HttpService:JSONDecode(txt)
		local items={}
		for _,it in d.bodies.francois or {} do
			items[it.item]={i=string.format("%.2f/%.2f",it.inShare,it.inMax),ip=it.inPose,ipc=it.inPiece,
				o=string.format("%.2f/%.2f",it.offShare,it.offMax),op=it.offPose,opc=it.offPiece,
				r=string.format("%.2f/%.2f",it.restIn,it.restOff),k=it.kind,l=it.loose,n=it.pieces,diff={}}
		end
		for body,list in d.bodies do
			if body~="francois" then
				for _,it in list do
					local base=items[it.item]
					local i,o=string.format("%.2f/%.2f",it.inShare,it.inMax),string.format("%.2f/%.2f",it.offShare,it.offMax)
					if base and (i~=base.i or o~=base.o) then base.diff[body]=i.." "..o end
				end
			end
		end
		out[look]=items
	end
	return HttpService:JSONEncode(out)
end
return Check
