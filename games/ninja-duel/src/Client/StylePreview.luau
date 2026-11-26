-- The shop's STYLE preview (DA v3, DESIGN validated 14/11, Mix-Shop: « à
-- gauche, ton avatar portant la tenue survolée »). A ViewportFrame shows a
-- copy of the player's own avatar; the outfit pointed at in the grid (mouse
-- over a card, or a pad's selection) is put on the copy with the same modelled
-- pieces as in the game (Client/OutfitDress), the copy's own outfit taken off
-- first. Presentation only: nothing is bought or worn by pointing.
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

-- A still copy of `character`, standing at the origin facing the lens (-z).
function Preview.copy(character)
	if not character then return nil end
	local was=character.Archivable
	character.Archivable=true
	local ok,copy=pcall(function() return character:Clone() end)
	character.Archivable=was
	if not ok or not copy then return nil end
	strip(copy)
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

-- The avatar shown again (his own outfit), from his character now.
function Preview:refresh(character)
	if self.model then self.model:Destroy();self.model=nil end
	self.item=nil;self.key=nil
	local copy=Preview.copy(character)
	if copy then copy.Parent=self.view;self.model=copy;self:frame() end
	return copy~=nil
end

-- The outfit `itemId` on the copy (nil: his own, as he is).
function Preview:show(itemId,character,paint)
	local key=tostring(itemId)..tostring(paint)
	if key==self.key then return end
	self:refresh(character)
	self.key=key
	self.item=itemId
	if not itemId or not self.model then return end
	local holder=Instance.new("Model")
	holder.Name="NinjaOutfit";holder:SetAttribute("NinjaOutfit",itemId);holder:SetAttribute("NinjaPreview",true)
	-- (DESIGN 26/11) the gate's creation: several pieces (a comma list) and the hair's paint
	if paint then holder:SetAttribute("NinjaHairPaint",paint) end
	holder.Parent=self.model
	task.spawn(function()
		pcall(function() require(script.Parent.OutfitDress).wear(holder) end)
		-- the copy is still: its new pieces too; the lens takes them in
		if self.model then for _,d in self.model:GetDescendants() do if d:IsA("BasePart") then d.Anchored=true end end end
		self:frame()
	end)
end

return Preview
