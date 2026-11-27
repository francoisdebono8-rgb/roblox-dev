-- (DESIGN 27/11, passe commune 4: « l'arbre où l'on voit ce que fait chaque
-- nœud ») The move a node gives, played by the player's own avatar: a still
-- of its key frame on the seal, the whole move in a loop in the panel. No
-- uploaded picture (the uploads are blocked): a ViewportFrame with a copy of
-- his character, its parts placed joint by joint from the kits' authored
-- clips (Client/AuthoredMotion; the joints' Transform as Client/HubBody).
-- Pure helpers first (the suite checks them headless), then the frames.
local Preview={}

Preview.PARTS={"Channel","Hold","Release","Recover"}
-- a node with no technique of its own shows the kind of thing it changes
Preview.KIND={counter={"Guard.Impact","Guard"},substitution={"Flip","Handspring"},airwall={"AirFlip","AirJump"},
	route={"Chase","Dash.F","DashAttack"},stat={"Light3","Heavy"},property={"Heavy","Light3"},awakening={"Awaken"},
	jutsu={"Heavy"},tool={"Throw","Heavy"}}
-- the ninja tree's branches (Shared/NinjaTree): one move each
Preview.BRANCH={Nature={"Heavy"},Body={"Light3"},Mind={"Guard"},Tools={"Throw"},Way={"Chase"}}

-- an item named apart from the technique that plays it (Lee's weights)
Preview.ALIAS={Weights="RemoveWeights"}

-- (pure) The technique ids a node names, most telling first: what it
-- unlocks, its item, the techniques its effects touch, the clone body.
function Preview.techs(node)
	local out,seen={}, {}
	local function add(id)
		id=Preview.ALIAS[id] or id
		if type(id)=="string" and id~="" and not seen[id] then seen[id]=true;table.insert(out,id) end
	end
	if not node then return out end
	add(node.Unlock);add(node.Item)
	for _,e in node.Effects or {} do
		local path=type(e)=="table" and e[1]
		if type(path)=="string" then
			add(string.match(path,"^tech%.([^%.]+)"))
			add(string.match(path,"^def%.Items%.([^%.]+)"))
			if string.match(path,"^def%.Bodies%.clone") then add("ShadowClone") end
			add(string.match(path,"^graph%.stringCancels%.([^%.]+)"))
		end
	end
	return out
end

-- (pure) The clips that play the node's move for `kitId`, in order (a
-- technique's Channel, Hold, Release, Recover; or one clip), given `has`
-- (AuthoredMotion.has). Empty: nothing authored, the seal keeps its icon.
function Preview.clips(kitId,node,has)
	if not kitId or not node or type(has)~="function" then return {} end
	for _,tech in Preview.techs(node) do
		if tech=="Awakening" then tech="Awaken" end
		local parts={}
		for _,part in Preview.PARTS do
			local name=kitId.."."..tech.."."..part
			if has(name) then table.insert(parts,name) end
		end
		if #parts>0 then return parts end
		if has(kitId.."."..tech) then return {kitId.."."..tech} end
	end
	for _,move in Preview.KIND[node.Kind or ""] or Preview.BRANCH[node.Branch or ""] or {"Heavy"} do
		local name=kitId.."."..move
		if has(name) then return {name} end
	end
	return {}
end

-- (pure) The still for the seal: the release's middle (the blow, the jutsu
-- out), else 45 % into the one clip. `length` is AuthoredMotion.length.
function Preview.still(clips,length)
	if #clips==0 then return nil,0 end
	for _,name in clips do
		if string.sub(name,-8)==".Release" then return name,(length(name) or 0)*.5 end
	end
	local name=clips[#clips==1 and 1 or math.min(2,#clips)]
	return name,(length(name) or 0)*.45
end

-- (pure) Where the loop is at `t` seconds: the clip and its time; a short
-- breath after the last one before it starts again.
Preview.BREATH=.5
function Preview.at(clips,length,t)
	local total=Preview.BREATH
	for _,name in clips do total+=math.max(length(name) or 0,.05) end
	if #clips==0 or total<=0 then return nil,0 end
	t=t%total
	for _,name in clips do
		local l=math.max(length(name) or 0,.05)
		if t<l then return name,t end
		t-=l
	end
	return clips[#clips],length(clips[#clips]) or 0
end

-- ------------------------------------------------------------------ frames
local okA,Authored=pcall(function() return require(script.Parent.AuthoredMotion) end)
if not okA then Authored=nil end
Preview.Authored=Authored

-- A copy of the player's character, still and quiet (no scripts, no name).
local template,templateFrom
function Preview.body()
	local Players=game:GetService("Players")
	local me=Players.LocalPlayer
	local char=me and me.Character
	if not char then return nil end
	if template and templateFrom==char then return template end
	local ok,copy=pcall(function()
		local was=char.Archivable
		char.Archivable=true
		local c=char:Clone()
		char.Archivable=was
		return c
	end)
	if not ok or not copy then return nil end
	for _,d in copy:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("ForceField") or d:IsA("BillboardGui") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
			d:Destroy()
		end
	end
	local hum=copy:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;pcall(function() hum.EvaluateStateMachine=false end) end
	local root=copy:FindFirstChild("HumanoidRootPart")
	if not root then copy:Destroy();return nil end
	for _,p in copy:GetDescendants() do if p:IsA("BasePart") then p.Anchored=p==root;p.CanCollide=false end end
	copy:PivotTo(CFrame.new(0,0,0))
	template,templateFrom=copy,char
	return copy
end

-- (27/11, seen in the game: his avatar is joined by AnimationConstraints,
-- which a ViewportFrame never solves) The copy's parts are placed here, from
-- the root out, each by its joint (Motor6D: part1 = part0 * C0 * T * C1^-1;
-- an AnimationConstraint or a RigidConstraint the same by its attachments; a
-- weld keeps its offset), every part anchored. Pure placement, no physics.
local function links(model)
	local root=model:FindFirstChild("HumanoidRootPart")
	local adj={}
	local function add(a,b,e) adj[a]=adj[a] or {};table.insert(adj[a],{b,e}) end
	for _,j in model:GetDescendants() do
		local p0,p1,c0,c1
		if j:IsA("JointInstance") and j.Part0 and j.Part1 then p0,p1,c0,c1=j.Part0,j.Part1,j.C0,j.C1
		elseif (j:IsA("AnimationConstraint") or j:IsA("RigidConstraint")) and j.Attachment0 and j.Attachment1 then
			local a0,a1=j.Attachment0,j.Attachment1
			if a0.Parent and a1.Parent and a0.Parent:IsA("BasePart") and a1.Parent:IsA("BasePart") then p0,p1,c0,c1=a0.Parent,a1.Parent,a0.CFrame,a1.CFrame end
		elseif j:IsA("WeldConstraint") and j.Part0 and j.Part1 then
			p0,p1,c0,c1=j.Part0,j.Part1,j.Part0.CFrame:ToObjectSpace(j.Part1.CFrame),CFrame.identity
		end
		if p0 and p1 then
			local e={name=j.Name,c0=c0,c1=c1,moves=j:IsA("Motor6D") or j:IsA("AnimationConstraint")}
			add(p0,p1,{e=e,forward=true});add(p1,p0,{e=e,forward=false})
		end
	end
	-- from the root out: each part once, by the joint that reaches it first
	local order,seen,queue,i={}, {[root]=true},{root},1
	while queue[i] do
		local part=queue[i];i+=1
		for _,l in adj[part] or {} do
			local other,info=l[1],l[2]
			if not seen[other] and other:IsDescendantOf(model) then
				seen[other]=true
				table.insert(order,{from=part,to=other,e=info.e,forward=info.forward})
				table.insert(queue,other)
			end
		end
	end
	return order
end

-- A frame with the avatar in it: {vp, model, order, root}. `full`: the
-- panel's (the whole body and room for the move); else a seal's (tighter).
function Preview.frame(parent,full)
	local body=Preview.body()
	if not body or not Authored then return nil end
	local vp=Instance.new("ViewportFrame")
	vp.BackgroundTransparency=1;vp.BorderSizePixel=0;vp.Ambient=Color3.fromRGB(215,206,196);vp.LightColor=Color3.fromRGB(255,250,242)
	-- (27/11, « peu lisible ») lit from the front and above, as the lens sees it
	vp.LightDirection=Vector3.new(.3,-.8,.6)
	local model=body:Clone()
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true end end
	model.Parent=vp
	local cam=Instance.new("Camera");cam.FieldOfView=if full then 30 else 28;cam.Parent=vp
	vp.CurrentCamera=cam
	-- three quarters from the front, the body's middle in the middle
	local root=model:FindFirstChild("HumanoidRootPart")
	local centre=(root and root.Position or Vector3.zero)+Vector3.new(0,if full then -.3 else .1,0)
	local dist=if full then 14 else 10
	cam.CFrame=CFrame.lookAt(centre+Vector3.new(-.5,.15,-1).Unit*dist,centre)
	vp.Parent=parent
	return {vp=vp,model=model,root=root,home=root and root.CFrame or CFrame.identity,order=links(model),centre=centre,full=full}
end

local NAME={Right="RightShoulder",Left="LeftShoulder"}
function Preview.pose(f,clip,t)
	if not f or not clip or not Authored or not f.root then return end
	local p=Authored.sample(clip,t)
	if not p then return end
	local T={}
	-- (the root's travel stays home, its rise and fall kept small: a leap or
	-- the Lotus's dive plays on the spot, in the frame)
	for name,cf in p do T[NAME[name] or name]=if name=="Root" then cf.Rotation+Vector3.new(0,math.clamp(cf.Y,-1.2,1.2),0) else cf end
	f.root.CFrame=f.home
	for _,l in f.order do
		local e=l.e
		local tr=(e.moves and T[e.name]) or CFrame.identity
		l.to.CFrame=if l.forward then l.from.CFrame*e.c0*tr*e.c1:Inverse() else l.from.CFrame*e.c1*tr:Inverse()*e.c0:Inverse()
	end
	-- (seen in the game: the Lotus's dive hung the body under the frame) the
	-- body stays in the frame: a seal's still centred on it, the panel's loop
	-- brought back only by what passes a stud and a half
	local ok,box=pcall(function() return (f.model:GetBoundingBox()) end)
	if ok and box and f.centre then
		local d=box.Position-f.centre
		local function over(v) local m=if f.full then 1.5 else 0 return if v>m then v-m elseif v<-m then v+m else 0 end
		local shift=Vector3.new(over(d.X),over(d.Y),over(d.Z))
		if shift.Magnitude>1e-3 then
			for _,l in f.order do l.to.CFrame=l.to.CFrame-shift end
			f.root.CFrame=f.root.CFrame-shift
		end
	end
end

-- A seal's still: the node's key frame, or nil when nothing is authored.
function Preview.thumb(parent,kitId,node)
	if not Authored then return nil end
	local clips=Preview.clips(kitId,node,Authored.has)
	if #clips==0 then return nil end
	local f=Preview.frame(parent,false)
	if not f then return nil end
	local clip,t=Preview.still(clips,Authored.length)
	Preview.pose(f,clip,t)
	return f
end

return Preview
