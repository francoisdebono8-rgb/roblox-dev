-- The shop's STYLE preview (DA v3, DESIGN validated 14/11, Mix-Shop: « à
-- gauche, ton avatar portant la tenue survolée »). A ViewportFrame shows a
-- copy of the player's own avatar; the outfit pointed at in the grid (mouse
-- over a card, or a pad's selection) is put on the copy with the same modelled
-- pieces as in the game (Client/OutfitDress), in place of the piece he wears in
-- that slot (the rest of his outfit stays on). Presentation only: nothing is
-- bought or worn by pointing.
local Shop=require(game:GetService("ReplicatedStorage").NinjaDuel.Shop)

local Preview={}
Preview.__index=Preview

Preview.FOV=34
Preview.DISTANCE=9

local function strip(model)
	for _,d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false end
	end
	for _,c in model:GetChildren() do
		if c.Name=="NinjaOutfit" or c.Name=="NinjaOutfitMesh" or c:IsA("Humanoid") then
			if c:IsA("Humanoid") then c.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None else c:Destroy() end
		end
	end
end

-- (26/11, passe 2, seen in the shop and at the gate: the copy kept the pose
-- his body had when it was taken, a stride, knees bent, leaning across the
-- stage) The copy stands at rest: from the root, each part put back where its
-- joint holds it without the animation's turn (a Motor6D, an accessory's
-- weld: part1 = part0 * C0 * C1⁻¹; a weld constraint keeps the offset it had).
-- Returns how many parts were placed.
function Preview.rest(model)
	local root=model and model:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then return 0 end
	local links={}
	local function link(a,b,place)
		links[a]=links[a] or {}
		table.insert(links[a],{b,place})
	end
	for _,j in model:GetDescendants() do
		if j:IsA("JointInstance") and j.Part0 and j.Part1 then
			local c0,c1=j.C0,j.C1
			link(j.Part0,j.Part1,function(cf) return cf*c0*c1:Inverse() end)
			link(j.Part1,j.Part0,function(cf) return cf*c1*c0:Inverse() end)
		elseif j:IsA("WeldConstraint") and j.Part0 and j.Part1 then
			local offset=j.Part0.CFrame:ToObjectSpace(j.Part1.CFrame)
			link(j.Part0,j.Part1,function(cf) return cf*offset end)
			link(j.Part1,j.Part0,function(cf) return cf*offset:Inverse() end)
		end
	end
	local seen={[root]=true}
	local queue={root}
	local i,n=1,0
	while queue[i] do
		local part=queue[i];i+=1
		for _,l in links[part] or {} do
			local other=l[1]
			if not seen[other] and other:IsDescendantOf(model) then
				seen[other]=true
				other.CFrame=l[2](part.CFrame)
				n+=1
				table.insert(queue,other)
			end
		end
	end
	return n
end

-- A still copy of `character`, standing at rest at the origin facing the lens
-- (-z), its own outfit taken off (Preview:show puts one back on).
function Preview.copy(character)
	if not character then return nil end
	local was=character.Archivable
	character.Archivable=true
	local ok,copy=pcall(function() return character:Clone() end)
	character.Archivable=was
	if not ok or not copy then return nil end
	strip(copy)
	pcall(Preview.rest,copy)
	local root=copy:FindFirstChild("HumanoidRootPart")
	if root then
		pcall(function()
			copy.PrimaryPart=root
			-- (21/11, François: « notre personnage est à l'envers », seen from
			-- the back) The lens stands at -Z looking +Z: the body faces it
			-- (its front is -Z), turned a little for a three-quarter view.
			copy:PivotTo(CFrame.new(0,3,0)*CFrame.Angles(0,math.rad(-20),0))
		end)
	end
	return copy
end

-- (26/11, passe 2, seen in the shop: the big avatar stood in his skin, his
-- outfit taken off and only the look pointed at put back, nothing at all on
-- the tabs without clothes; DEC-054: never naked) What he wears now: the
-- server's holder on his character (Server/Outfit), its items and his hair's
-- paint.
function Preview.worn(character)
	local holder=character and character:FindFirstChild("NinjaOutfit")
	local ids={}
	local list=holder and holder:GetAttribute("NinjaOutfit")
	if type(list)=="string" then
		for _,id in string.split(list,",") do if id~="" then table.insert(ids,id) end end
	end
	local paint=holder and holder:GetAttribute("NinjaHairPaint")
	return ids,(if typeof(paint)=="Color3" then paint else nil)
end
-- (pure) His outfit `worn` with the look `itemId` in place of the one of its
-- slot: a master's outfit over the pieces (the accessories, the headband and
-- the hair stay), a piece instead of a master's outfit (the base outfit where
-- that leaves nothing, as the server does), « none » takes the slot off. A hair
-- colour gives its paint. Returns the items and the paint (nil: his own).
local PIECE={top=true,bottom=true,arms=true,feet=true}
local function slotOf(id)
	local item=Shop.item(id)
	return item and item.slot
end
function Preview.ids(worn,itemId)
	local out=table.clone(worn or {})
	local item=itemId and Shop.item(itemId)
	if not item then return out,nil end
	local slot=item.slot
	if slot=="hairColor" then
		-- (false: his own colour, the paint taken off)
		local h=item.colors and item.colors.Hair
		if not h then return out,false end
		return out,(if typeof(h)=="Color3" then h else Color3.fromRGB(h[1],h[2],h[3]))
	end
	local info=Shop.Slots[slot]
	if not (info and (info.outfit or slot=="headband" or slot=="hair")) then return out,nil end
	local keep={}
	local hadSet=false
	for _,id in out do
		local s=slotOf(id)
		if s=="set" then hadSet=true end
		local drop=s==slot or (slot=="set" and not item.none and PIECE[s]) or (PIECE[slot] and s=="set")
		if not drop then table.insert(keep,id) end
	end
	if not item.none then
		if slot=="set" then table.insert(keep,1,item.id) else table.insert(keep,item.id) end
	end
	if hadSet and (PIECE[slot] or (slot=="set" and item.none)) then
		local have={}
		for _,id in keep do local s=slotOf(id) if s then have[s]=true end end
		for _,s in Shop.OutfitSlots do
			local base=Shop.BASE and Shop.BASE[s]
			if base and not have[s] then table.insert(keep,base) end
		end
	end
	return keep,nil
end

-- (26/11) His own hair on the copy: hidden under a hair style, shown without
-- one (the server hid it while he wears a style), painted his chosen colour
-- (false: his own colour, as the server keeps it aside).
function Preview.hair(model,styled,paint)
	for _,accessory in model:GetChildren() do
		local handle=accessory:IsA("Accessory") and accessory:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") and (accessory.AccessoryType==Enum.AccessoryType.Hair or handle:GetAttribute("NinjaHairHidden")~=nil) then
			if styled then handle.Transparency=1
			else
				local was=handle:GetAttribute("NinjaHairHidden")
				if type(was)=="number" then handle.Transparency=was end
				local mesh=handle:FindFirstChildOfClass("SpecialMesh")
				if paint then
					handle.Color=paint
					pcall(function() if mesh then mesh.TextureId="" elseif handle:IsA("MeshPart") then (handle::any).TextureID="" end end)
				elseif paint==false and handle:GetAttribute("NinjaHairTexture")~=nil then
					local texture=handle:GetAttribute("NinjaHairTexture")
					local color=handle:GetAttribute("NinjaHairColor")
					pcall(function() if mesh then mesh.TextureId=texture elseif handle:IsA("MeshPart") then (handle::any).TextureID=texture end end)
					if typeof(color)=="Color3" then handle.Color=color end
				end
			end
		end
	end
end

function Preview.new(parent,position,size)
	local self=setmetatable({},Preview)
	local view=Instance.new("ViewportFrame")
	view.Name="StylePreview";view.Position=position;view.Size=size
	view.BackgroundTransparency=1;view.BorderSizePixel=0
	view.Ambient=Color3.fromRGB(160,150,140);view.LightColor=Color3.fromRGB(255,244,228);view.LightDirection=Vector3.new(-.4,-1,.6)
	view.ZIndex=(parent.ZIndex or 1)+2
	view.Parent=parent
	local lens=Instance.new("Camera");lens.FieldOfView=Preview.FOV;lens.Parent=view
	lens.CFrame=CFrame.lookAt(Vector3.new(0,3.6,-Preview.DISTANCE),Vector3.new(0,2.6,0))
	view.CurrentCamera=lens
	self.view,self.lens=view,lens
	return self
end

-- (DESIGN 23/11) the shop's big avatar: front on, turning slowly.
Preview.SPIN=28 -- degrees per second
function Preview:turn(on)
	self.turning=on
	if on and not self.spinning then
		self.spinning=true
		pcall(function()
			self.angle=0
			game:GetService("RunService").RenderStepped:Connect(function(dt)
				if not self.turning or not self.model or not self.view.Visible then return end
				self.angle=(self.angle+Preview.SPIN*dt)%360
				self.model:PivotTo(CFrame.new(0,3,0)*CFrame.Angles(0,math.rad(180+self.angle),0))
			end)
		end)
	end
end

-- (26/11, François at the gate's creation: « on ne voit pas l'avatar en
-- entier ») The lens takes in the whole body, head to feet, whatever his
-- height (an avatar grown to the prodigies', a tall hair style, a hat), with a
-- margin; the frame's shape (a tall card, a wide one) counts.
Preview.MARGIN=1.14
-- (pure) Where the lens stands and looks for a body's box (its centre and
-- size, the body facing -Z) in a frame `aspect` wide for 1 high.
function Preview.fit(center,size,aspect,fov)
	local tanV=math.tan(math.rad((fov or Preview.FOV)/2))
	local half=size.Y/2*Preview.MARGIN
	local wide=math.max(size.X,size.Z)/2*Preview.MARGIN
	local dist=math.max(half/tanV,wide/(tanV*math.max(aspect or 1,.2)))+math.max(size.X,size.Z)/2
	local eye=center+Vector3.new(0,size.Y*.04,-dist)
	return CFrame.lookAt(eye,center)
end
function Preview:frame()
	local model=self.model
	if not model then return end
	local ok,cf,size=pcall(function() return model:GetBoundingBox() end)
	if not ok or not cf then return end
	local abs=self.view.AbsoluteSize
	local aspect=if abs.Y>1 then abs.X/abs.Y else 1
	self.lens.CFrame=Preview.fit(cf.Position,size,aspect)
end

-- The avatar shown again as he is now (his own outfit), from his character.
function Preview:refresh(character)
	self.key=nil
	return self:show(nil,character)
end

-- The look `itemId` on the copy, over the rest of his outfit (nil: his own
-- outfit, as he is). `whole`: `itemId` is a whole outfit (a comma list, the
-- gate's card), worn as it is; `paint`: the hair's colour.
function Preview:show(itemId,character,paint,whole)
	-- (what he wears counts: re-dressed by the server, his copy is taken again)
	local worn,wornPaint=Preview.worn(character)
	local key=(if whole then "=" else "")..tostring(itemId)..tostring(paint).."|"..table.concat(worn,",")..tostring(wornPaint)
	if key==self.key and self.model then return true end
	if self.model then self.model:Destroy();self.model=nil end
	self.key=nil;self.item=nil
	local copy=Preview.copy(character)
	if not copy then return false end
	copy.Parent=self.view;self.model=copy
	self.key=key
	self.item=itemId
	local ids,itemPaint
	if whole then
		ids={}
		for _,id in string.split(tostring(itemId or ""),",") do if id~="" then table.insert(ids,id) end end
	else
		ids,itemPaint=Preview.ids(worn,itemId)
	end
	if itemPaint==false then paint=paint or false else paint=paint or itemPaint or wornPaint end
	local styled=false
	for _,id in ids do if slotOf(id)=="hair" then styled=true end end
	pcall(Preview.hair,copy,styled,paint)
	self:frame()
	if #ids==0 then return true end
	local holder=Instance.new("Model")
	holder.Name="NinjaOutfit";holder:SetAttribute("NinjaOutfit",table.concat(ids,","));holder:SetAttribute("NinjaPreview",true)
	-- (DESIGN 26/11) the gate's creation: several pieces (a comma list) and the hair's paint
	if typeof(paint)=="Color3" then holder:SetAttribute("NinjaHairPaint",paint) end
	holder.Parent=copy
	task.spawn(function()
		pcall(function() require(script.Parent.OutfitDress).wear(holder) end)
		-- the copy is still: its new pieces too; the lens takes them in
		if self.model==copy then
			for _,d in copy:GetDescendants() do if d:IsA("BasePart") then d.Anchored=true end end
			self:frame()
		end
	end)
	return true
end

return Preview
