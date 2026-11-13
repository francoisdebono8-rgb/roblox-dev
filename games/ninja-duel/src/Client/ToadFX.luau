-- (13/11, user: « la grenouille de Naruto, c'est pas bon ») Gamakichi.
-- It was nine smooth balls that swelled in place and vanished. Now a toad
-- designed in tools/blender/fx_toad.py (the parts: Client/ToadModel, the same
-- data the Blender preview renders): wide flat head, big yellow eyes up in
-- their sockets with horizontal pupils, cream throat and belly, cheek pouches,
-- a blue-purple vest, spots, webbed hands, folded hind legs.
-- It acts, on the same timeline as the preview (ToadFX.pose):
--   0-.1 s   it hops up out of the smoke, growing;
--   .1-.2 s  it lands and squashes;
--   .05-.14  its cheeks fill;  .14-.32 it spits (the water bullet leaves
--            its mouth on the server's frame): the jaw drops, the head throws
--            forward, the cheeks empty;
--   then it sits there, breathing, proud, blinks twice, and goes in a puff.
-- Built from Roblox primitives (no mesh to upload). Presentation only.
local ToadFX={}
local Model=require(script.Parent.ToadModel)
ToadFX.clock=os.clock
local RunService=game:GetService("RunService")

function ToadFX.pose(t)
	local lift,sx,sy,head,jaw,cheek,lid=0,1,1,0,0,1,0
	if t<.1 then
		local k=t/.1
		lift=1.2*math.sin(k*math.pi*.5);sx=.3+.7*k;sy=sx
	elseif t<.2 then
		local k=(t-.1)/.1
		lift=1.2*(1-k)^2;sy=1-.22*math.sin(k*math.pi);sx=1+.12*math.sin(k*math.pi)
	end
	if t>=.05 and t<.14 then
		cheek=1+.7*(t-.05)/.09
	elseif t>=.14 and t<.32 then
		local k=(t-.14)/.18
		jaw=48*math.sin(math.min(1,k*1.6)*math.pi*.5)*(1-math.max(0,k-.6)/.4)
		head=14*math.sin(k*math.pi)
		cheek=1.7-.8*k
	elseif t>=.32 then
		cheek=.9+.1*math.min(1,(t-.32)/.2)
		head=-3*math.sin((t-.32)*6)
	end
	for _,b in {.7,1.15} do if t>=b and t<b+.12 then lid=1 end end
	return {lift=lift,sx=sx,sy=sy,head=head,jaw=jaw,cheek=cheek,lid=lid}
end

local function rest(p)
	local r=p[6]
	return CFrame.new(p[5])*CFrame.Angles(math.rad(r.X),math.rad(r.Y),math.rad(r.Z))
end
-- Each part's CFrame (in the toad's frame) and size for a pose.
function ToadFX.place(p,pose)
	local group,size=p[2],p[4]
	local cf=rest(p)
	if group=="jaw" then
		local jp=Model.jawPivot
		cf=CFrame.new(jp)*CFrame.Angles(math.rad(-pose.jaw),0,0)*CFrame.new(-jp)*cf
	end
	if group=="cheekL" or group=="cheekR" then size=size*pose.cheek end
	if string.sub(group,1,3)=="lid" then
		cf=cf*CFrame.new(0,.12-.14*pose.lid,0)
		size=Vector3.new(size.X,size.Y*(.22+.78*pose.lid),size.Z)
	end
	if group=="head" or group=="jaw" or group=="cheekL" or group=="cheekR" or string.sub(group,1,3)=="lid" then
		local hp=Model.headPivot
		cf=CFrame.new(hp)*CFrame.Angles(math.rad(-pose.head),0,0)*CFrame.new(-hp)*cf
	end
	-- the whole body: squash about the feet, then the hop
	local pos=cf.Position
	cf=CFrame.new(pos.X*pose.sx,pos.Y*pose.sy+pose.lift,pos.Z*pose.sx)*cf.Rotation
	size=Vector3.new(size.X*pose.sx,size.Y*pose.sy,size.Z*pose.sx)
	return cf,size
end

-- Builds Gamakichi standing at `frame` (feet on the floor, facing its -Z)
-- under `parent`; plays the timeline for `life` seconds, then `gone()`.
function ToadFX.summon(parent,frame,life,gone)
	local m=Instance.new("Model");m.Name="Gamakichi"
	pcall(m.SetAttribute,m,"KeepShadow",true)
	local parts={}
	for _,p in Model.parts do
		local part=Instance.new("Part")
		part.Name=p[1];part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
		part.Material=Enum.Material.SmoothPlastic;part.Color=p[7];part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth
		part.CastShadow=p[2]=="body" or p[1]=="Head"
		if p[3]=="ell" then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=part end
		part.Size=p[4]
		part.Parent=m
		table.insert(parts,{part=part,data=p})
	end
	m.Parent=parent
	local t0=ToadFX.clock()
	local function apply()
		local t=ToadFX.clock()-t0
		local pose=ToadFX.pose(t)
		for _,e in parts do
			local cf,size=ToadFX.place(e.data,pose)
			e.part.Size=Vector3.new(math.max(.05,size.X),math.max(.05,size.Y),math.max(.05,size.Z))
			e.part.CFrame=frame*cf
		end
		return t
	end
	pcall(apply)
	local conn
	conn=RunService.Heartbeat:Connect(function()
		local ok,t=pcall(apply)
		if not ok or not m.Parent or t>=life then
			if conn then conn:Disconnect();conn=nil end
			if m.Parent then m:Destroy() end
			if gone then pcall(gone) end
		end
	end)
	return m
end
return ToadFX
