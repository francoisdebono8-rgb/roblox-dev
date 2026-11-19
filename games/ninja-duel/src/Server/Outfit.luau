-- The ninja outfit over the player's own avatar (DEC-040, user 14/11: « que
-- l'utilisateur ait juste son avatar mais il arrive genre nu et on ait un petit
-- truc de customisation de personnage. Genre au début on propose des trucs
-- simples mais qui font un peu de tenue ninja »).
--
-- Two things:
--   * Outfit.strip: his Roblox avatar keeps its body, face and hair; its
--     clothes and every other accessory come off (the walk in Konoha,
--     Server/Hub; the duel's body, Server/AvatarBody).
--   * Outfit.wear: the pieces he chose (Shared/Shop, slots set/top/bottom/
--     arms/feet) are put on, welded to his body parts, never colliding nor
--     hit. A piece is cloth over the part it covers, sized on that part, so it
--     fits any avatar at the game's standard scales. The ANIMATEUR's modelled
--     pieces (OutfitMeshes, when they exist) replace these by name.
local Shop=require(game:GetService("ReplicatedStorage").NinjaDuel.Shop)
local Outfit={}

-- The rigid accessory lists of a description that come off (hair stays).
Outfit.RIGID={"HatAccessory","FaceAccessory","NeckAccessory","ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory"}

-- His avatar without its clothes: body, face and hair. Changes `desc` (a
-- HumanoidDescription) and returns it.
function Outfit.strip(desc)
	if not desc then return nil end
	pcall(function() desc.Shirt=0;desc.Pants=0;desc.GraphicTShirt=0 end)
	for _,key in Outfit.RIGID do pcall(function() (desc::any)[key]="" end) end
	-- Layered clothing and shoes go; layered hair stays.
	pcall(function()
		local keep={}
		for _,a in desc:GetAccessories(false) do
			if a.AccessoryType==Enum.AccessoryType.Hair then table.insert(keep,a) end
		end
		desc:SetAccessories(keep,false)
	end)
	return desc
end

local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end
-- `on` → the body parts it names (UpperArm: both sides).
local SIDES={UpperArm=true,LowerArm=true,Hand=true,UpperLeg=true,LowerLeg=true,Foot=true}
function Outfit.parts(model,on)
	local out={}
	local names=if SIDES[on] then {"Left"..on,"Right"..on} else {on}
	for _,name in names do
		local p=model:FindFirstChild(name)
		if p and p:IsA("BasePart") then table.insert(out,p) end
	end
	return out
end

local function cloth(holder,body,name,size,offset,color,material)
	local p=Instance.new("Part")
	p.Name=name;p.Size=size;p.Color=color;p.Material=material
	p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.CastShadow=false
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	p.CFrame=body.CFrame*offset
	local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=p;weld.Parent=p
	p.Parent=holder
	return p
end

-- One piece on one body part. The kinds:
--   shell (default): cloth round the part, `h` of its height from `y0`;
--   band: a thin wrap round it (bandages, ties, belts);
--   collar: a raised collar on the torso's top; shoulders: across the top;
--   vest: a thicker shell on the torso with two pockets in front;
--   sash: a band across the chest; tail: cloth hanging down from the hips.
-- (15/11) The legs' length against the standard R15's (2.41), for what hangs
-- from the hips (a tail): its length follows the legs, not the hips' height
-- (0.4 standard, often 0.6 to 1 on a bundle).
Outfit.LEGS=1.217+1.193
function Outfit.legScale(model)
	local up,low=model and model:FindFirstChild("RightUpperLeg"),model and model:FindFirstChild("RightLowerLeg")
	if not (up and low) then return 1 end
	return (up.Size.Y+low.Size.Y)/Outfit.LEGS
end
function Outfit.piece(holder,body,spec,colors,legs)
	local s=body.Size
	local color=rgb((colors and colors[spec.c]) or {120,120,120})
	-- (19/11, seen in Studio) Fabric reads near-black under the game's light:
	-- the cloth wears the prodigies' SmoothPlastic (Client/OutfitDress does the same).
	local material=Enum.Material[spec.mat or "SmoothPlastic"] or Enum.Material.SmoothPlastic
	if material==Enum.Material.Fabric then material=Enum.Material.SmoothPlastic end
	local pad=spec.pad or .06
	local kind=spec.kind or "shell"
	local y0,h=spec.y0 or 0,spec.h or 1
	-- (y0, h) as a box's centre and height along the part (its top is +Y/2)
	local function along(top,height) return s.Y/2-top*s.Y-height*s.Y/2 end
	if kind=="shell" or kind=="band" then
		local grow=if kind=="band" then pad+.04 else pad
		return cloth(holder,body,"Cloth",Vector3.new(s.X+2*grow,math.max(.05,h*s.Y),s.Z+2*grow),CFrame.new(0,along(y0,h),0),color,material)
	elseif kind=="collar" then
		local hh=(spec.h or .2)*s.Y
		return cloth(holder,body,"Collar",Vector3.new(s.X*.62,hh,s.Z+2*pad),CFrame.new(0,s.Y/2+hh/2-.02,0),color,material)
	elseif kind=="shoulders" then
		return cloth(holder,body,"Shoulders",Vector3.new(s.X+2*pad+.04,s.Y*.22,s.Z+2*pad+.04),CFrame.new(0,s.Y/2-s.Y*.11,0),color,material)
	elseif kind=="vest" then
		local v=cloth(holder,body,"Vest",Vector3.new(s.X+2*pad+.14,s.Y*.86,s.Z+2*pad+.16),CFrame.new(0,-s.Y*.05,0),color,material)
		for _,side in {-1,1} do
			cloth(holder,body,"Pocket",Vector3.new(s.X*.26,s.Y*.22,.12),CFrame.new(side*s.X*.24,-s.Y*.18,-(s.Z/2+pad+.14)),color,material)
		end
		return v
	elseif kind=="sash" then
		return cloth(holder,body,"Sash",Vector3.new(s.X*1.25,s.Y*.18,s.Z+2*pad+.06),CFrame.new(0,0,0)*CFrame.Angles(0,0,math.rad(-38)),color,material)
	elseif kind=="tail" then
		-- the standard hips (0.4) times 1.6, along the legs
		local hh=h*.4*1.6*(legs or 1)
		return cloth(holder,body,"Tail",Vector3.new(s.X+2*pad+.1,hh,s.Z+2*pad+.1),CFrame.new(0,-s.Y/2-hh/2+s.Y*.3,0),color,material)
	end
	return nil
end

-- What he wears, from his looks (Progression.looks): a master's outfit
-- covers the four slots; else each slot's piece. Item ids, in order.
function Outfit.items(looks)
	if not looks then return {} end
	if looks.set then return {looks.set} end
	local out={}
	for _,slot in Shop.OutfitSlots do if looks[slot] then table.insert(out,looks[slot]) end end
	return out
end

-- Dresses `model` (an R15 body) in `looks`; an older outfit comes off first.
-- Returns the outfit's holder (nil: nothing to wear).
function Outfit.wear(model,looks)
	if not model then return nil end
	for _,old in model:GetChildren() do if old:GetAttribute("NinjaOutfit") then old:Destroy() end end
	local ids=Outfit.items(looks)
	if #ids==0 then return nil end
	local holder=Instance.new("Model");holder.Name="NinjaOutfit";holder:SetAttribute("NinjaOutfit",table.concat(ids,","))
	-- (built whole before it is parented: the client's OutfitDress sees it
	-- once, with all its pieces)
	for _,id in ids do
		local item=Shop.item(id)
		if item and item.pieces and not item.none then
			for _,spec in item.pieces do
				for _,body in Outfit.parts(model,spec.on) do Outfit.piece(holder,body,spec,item.colors,Outfit.legScale(model)) end
			end
		end
	end
	holder.Parent=model
	return holder
end

return Outfit
