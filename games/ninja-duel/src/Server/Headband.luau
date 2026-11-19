-- The Konoha headband a player's own avatar wears (13/11, the shop: Shared/Shop
-- slot "headband"; DEC-036: the game's ninja pieces over the player's avatar).
-- A cloth band round the head and the engraved metal plate on the brow, sized
-- on the avatar's own head, welded to it, never colliding nor hit. The
-- prodigies keep their own costumes; this goes on avatar bodies only, in the
-- duel (Server/AvatarBody) and in Konoha (Server/Hub).
local Shop=require(game:GetService("ReplicatedStorage").NinjaDuel.Shop)
local Headband={}

local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end
local function piece(model,head,name,size,offset,color,material)
	local p=Instance.new("Part")
	p.Name=name;p.Size=size;p.Color=color;p.Material=material
	p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.CastShadow=false
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	p.CFrame=head.CFrame*offset
	p.Parent=model
	local weld=Instance.new("WeldConstraint");weld.Part0=head;weld.Part1=p;weld.Parent=p
	return p
end

-- The band's height and how far round the head it sits (head's half sizes).
Headband.HEIGHT=.15
Headband.REACH=1.07
-- Where the brow is on this head, in its own frame: BROW of the way from the
-- eyes' level (the face's front attachment) up to the top of the head (the
-- hat attachment). A head without them (an old blocky head): 27 % of its
-- height above its centre.
Headband.BROW=.6
function Headband.brow(head)
	local face=head:FindFirstChild("FaceFrontAttachment")
	local top=head:FindFirstChild("HatAttachment") or head:FindFirstChild("HairAttachment")
	if face and top and face:IsA("Attachment") and top:IsA("Attachment") and top.Position.Y>face.Position.Y then
		return face.Position.Y+(top.Position.Y-face.Position.Y)*Headband.BROW
	end
	return head.Size.Y*.27
end

-- Puts the look `itemId` (a headband of Shared/Shop) on `model`; any older
-- headband comes off first. Returns the band, or nil (no head, no headband).
function Headband.wear(model,itemId)
	if not model then return nil end
	for _,old in model:GetChildren() do if old:GetAttribute("NinjaHeadband") then old:Destroy() end end
	local item=itemId and Shop.item(itemId)
	if not item or item.slot~="headband" or item.none or not item.colors then return nil end
	local head=model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return nil end
	local s=head.Size
	local holder=Instance.new("Model");holder.Name="NinjaHeadband";holder:SetAttribute("NinjaHeadband",item.id)
	holder.Parent=model
	-- (19/11, seen in Studio) The plate sat across the eyes of a dynamic head:
	-- its height was a share of the head's box (16 % above the centre), and the
	-- box of a dynamic head runs from the chin to the crown. The band now sits
	-- on the brow, between the eyes' level (the face's front attachment) and
	-- the top of the head, and it is a ring of eight strips round the head's
	-- oval instead of a square whose corners stood out.
	local y=Headband.brow(head)
	local h=s.Y*Headband.HEIGHT
	local band=rgb(item.colors.Band)
	local a,b=s.X/2*Headband.REACH,s.Z/2*Headband.REACH
	local corners={}
	for i=0,7 do
		local phi=math.rad(-67.5+i*45) -- a strip centred on the brow (-Z) and one at the back
		table.insert(corners,Vector3.new(a*math.cos(phi),y,b*math.sin(phi)))
	end
	for i=1,8 do
		local p0,p1=corners[i],corners[i%8+1]
		local along=p1-p0
		local mid=(p0+p1)/2
		local right=along.Unit
		local frame=CFrame.fromMatrix(mid,right,Vector3.yAxis,right:Cross(Vector3.yAxis))
		piece(holder,head,"Band",Vector3.new(along.Magnitude+.04,h,.05),frame,band,Enum.Material.Fabric)
	end
	-- The two tails behind, from the knot.
	local back=b*math.cos(math.rad(22.5))
	for _,side in {-1,1} do
		piece(holder,head,"Tail",Vector3.new(.14,s.Y*.5,.04),CFrame.new(side*.12,y-s.Y*.26,back+.05)*CFrame.Angles(math.rad(14),0,math.rad(side*8)),band,Enum.Material.Fabric)
	end
	-- The plate on the brow, as wide as the front strip.
	local front=-b*math.cos(math.rad(22.5))
	piece(holder,head,"Plate",Vector3.new(a*.8,h*.86,.05),CFrame.new(0,y,front-.05),rgb(item.colors.Plate or {200,204,210}),Enum.Material.Metal)
	return holder
end

-- The headband in a look list (Progression.looks): the one worn, or none.
function Headband.fromLooks(model,looks)
	return Headband.wear(model,looks and looks.headband)
end

return Headband
