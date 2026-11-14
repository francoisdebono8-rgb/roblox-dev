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
	-- The cloth: a ring of four strips just outside the head, at the brow.
	local y=s.Y*.16
	local band=rgb(item.colors.Band)
	local w,d=s.X*1.06,s.Z*1.06
	piece(holder,head,"Band",Vector3.new(w,s.Y*.2,.06),CFrame.new(0,y,-d/2),band,Enum.Material.Fabric)
	piece(holder,head,"Band",Vector3.new(w,s.Y*.2,.06),CFrame.new(0,y,d/2),band,Enum.Material.Fabric)
	piece(holder,head,"Band",Vector3.new(.06,s.Y*.2,d),CFrame.new(-w/2,y,0),band,Enum.Material.Fabric)
	piece(holder,head,"Band",Vector3.new(.06,s.Y*.2,d),CFrame.new(w/2,y,0),band,Enum.Material.Fabric)
	-- The two tails behind.
	for _,side in {-1,1} do
		piece(holder,head,"Tail",Vector3.new(.14,s.Y*.5,.04),CFrame.new(side*.12,y-s.Y*.26,d/2+.05)*CFrame.Angles(math.rad(14),0,math.rad(side*8)),band,Enum.Material.Fabric)
	end
	-- The plate on the brow.
	piece(holder,head,"Plate",Vector3.new(w*.62,s.Y*.17,.05),CFrame.new(0,y,-d/2-.05),rgb(item.colors.Plate or {200,204,210}),Enum.Material.Metal)
	return holder
end

-- The headband in a look list (Progression.looks): the one worn, or none.
function Headband.fromLooks(model,looks)
	return Headband.wear(model,looks and looks.headband)
end

return Headband
