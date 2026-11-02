-- The select screen's two prodigies, in a real 3D set (user 02/11, "everything
-- about the faces is to redo"): a ViewportFrame neither draws the faces
-- (SurfaceGuis, Shared/Face) nor takes more than one light, so the fighters
-- stand in a small closed studio far above the arena, built on this client
-- only: an ink backdrop, the vermilion brush stroke, a key light from each
-- fighter's outer side and a back light in his colour. The menu camera
-- (Client/Camera) films it while the roster shows; Client/UI places the names
-- over it. Presentation only.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local MenuStage={}
MenuStage.__index=MenuStage

local ORIGIN=Vector3.new(0,4200,0)
local INK=Color3.fromRGB(14,12,17)
local FOV=34
local DISTANCE=21
-- The screen fractions where the two stages are (Client/UI's 1600-wide board).
MenuStage.SCREEN_X={player=.21,bot=.79}

local function part(parent,props)
	local p=Instance.new("Part")
	p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	for k,v in props do (p::any)[k]=v end
	p.Parent=parent
	return p
end
local function light(parent,class,at,props)
	local anchor=part(parent,{Name="Light",Size=Vector3.new(.2,.2,.2),Transparency=1,CFrame=at})
	local l=Instance.new(class)
	for k,v in props do (l::any)[k]=v end
	l.Parent=anchor
	return l,anchor
end

function MenuStage.new()
	local self=setmetatable({slots={},visible=false},MenuStage)
	local folder=Instance.new("Folder");folder.Name="NinjaDuelMenuStage";folder.Parent=workspace
	self.folder=folder
	local O=ORIGIN
	-- A closed box: the sun and sky never reach the set.
	part(folder,{Name="Backdrop",Size=Vector3.new(160,70,2),CFrame=CFrame.new(O+Vector3.new(0,10,9)),Color=INK})
	part(folder,{Name="Floor",Size=Vector3.new(160,2,60),CFrame=CFrame.new(O+Vector3.new(0,-3.4,-10)),Color=Color3.fromRGB(20,17,22),Reflectance=.04})
	part(folder,{Name="Roof",Size=Vector3.new(160,2,60),CFrame=CFrame.new(O+Vector3.new(0,30,-10)),Color=INK})
	part(folder,{Name="Back",Size=Vector3.new(160,70,2),CFrame=CFrame.new(O+Vector3.new(0,10,-40)),Color=INK})
	for _,s in {-1,1} do part(folder,{Name="Side",Size=Vector3.new(2,70,60),CFrame=CFrame.new(O+Vector3.new(s*80,10,-10)),Color=INK}) end
	-- The brush stroke behind the two fighters (the menu's red band).
	local band=part(folder,{Name="Stroke",Size=Vector3.new(120,4.2,.2),CFrame=CFrame.new(O+Vector3.new(0,3.2,7.6))*CFrame.Angles(0,0,math.rad(9)),
		Color=Color3.fromRGB(150,30,28),Material=Enum.Material.SmoothPlastic,Transparency=.1})
	part(folder,{Name="StrokeEdge",Size=Vector3.new(120,.6,.2),CFrame=band.CFrame*CFrame.new(0,-1.6,-.05),Color=INK,Transparency=.4})
	self.band=band
	-- One slot per stage: where the fighter stands, his lights. The lights
	-- follow the fighter (MenuStage:placeLights) wherever the screen's shape
	-- puts him.
	for _,side in {"player","bot"} do
		local outer=if side=="player" then -1 else 1
		local slot={side=side,outer=outer,x=-outer*6}
		slot.key,slot.keyAnchor=light(folder,"SpotLight",CFrame.new(O),
			{Brightness=3,Range=28,Angle=45,Color=Color3.fromRGB(255,236,214),Shadows=true,Face=Enum.NormalId.Front})
		slot.rim,slot.rimAnchor=light(folder,"SpotLight",CFrame.new(O),
			{Brightness=10,Range=16,Angle=70,Color=Color3.new(1,1,1),Shadows=false,Face=Enum.NormalId.Front})
		slot.fill,slot.fillAnchor=light(folder,"PointLight",CFrame.new(O),{Brightness=.3,Range=10,Color=Color3.fromRGB(150,140,160),Shadows=false})
		slot.glow,slot.glowAnchor=light(folder,"PointLight",CFrame.new(O),{Brightness=1.6,Range=10,Color=Color3.new(1,1,1),Shadows=false})
		self.slots[side]=slot
		self:placeLights(slot)
	end
	return self
end

-- A fighter's lights around where he stands: the key from his outer side
-- (away from the middle of the screen), the back light behind him and a
-- little inside, so his inner edge burns in his colour.
function MenuStage:placeLights(slot)
	local at=ORIGIN+Vector3.new(slot.x,0,0)
	local out=if slot.x>=0 then 1 else -1
	slot.keyAnchor.CFrame=CFrame.lookAt(at+Vector3.new(out*7,7,-9),at+Vector3.new(0,2.5,0))
	slot.rimAnchor.CFrame=CFrame.lookAt(at+Vector3.new(-out*2.4,5.5,4.2),at+Vector3.new(0,2.2,-.5))
	slot.fillAnchor.CFrame=CFrame.new(at+Vector3.new(0,1,-6))
	slot.glowAnchor.CFrame=CFrame.new(at+Vector3.new(0,3.5,3))
end
-- The camera's shot of the set (Client/Camera reads it while the roster shows).
function MenuStage:shot()
	-- Aimed low: the heads sit in the upper third, the names under the chests.
	return CFrame.lookAt(ORIGIN+Vector3.new(0,1.6,-DISTANCE),ORIGIN+Vector3.new(0,.55,0)),FOV
end
-- Each fighter stands where its stage is on this screen, whatever its shape.
function MenuStage:layout()
	local view=workspace.CurrentCamera.ViewportSize
	local aspect=if view.Y>0 then view.X/view.Y else 16/9
	local halfWidth=DISTANCE*math.tan(math.rad(FOV)/2)*aspect
	for side,slot in self.slots do
		local f=MenuStage.SCREEN_X[side]
		-- Screen right is world -X for a camera looking along +Z.
		slot.x=-(f-.5)*2*halfWidth
		self:placeLights(slot)
		if slot.model and not slot.moving then slot.model:PivotTo(self:stand(slot)) end
	end
end
function MenuStage:stand(slot)
	-- Facing the camera (-Z), turned a little toward the middle.
	return CFrame.new(ORIGIN+Vector3.new(slot.x,0,0))*CFrame.Angles(0,math.rad(slot.outer*-18),0)
end

-- `source` (a Server/Portraits model) steps onto the side's stage: he slides
-- in from the outer edge; the back light takes his colour.
function MenuStage:show(side,source,accent,animate)
	local slot=self.slots[side]
	if not slot or not source then return end
	if slot.model then slot.model:Destroy() end
	local model=source:Clone()
	if not model then return end
	model.Parent=self.folder
	slot.model=model
	slot.rim.Color=accent;slot.glow.Color=accent
	local final=self:stand(slot)
	if animate then
		slot.moving=true
		local from=final*CFrame.new(slot.outer*-4,0,0)
		local started=os.clock()
		model:PivotTo(from)
		local token={}
		slot.token=token
		local connection
		connection=RunService.RenderStepped:Connect(function()
			if slot.token~=token or not model.Parent then connection:Disconnect();return end
			local t=math.min(1,(os.clock()-started)/.34)
			local k=1-(1-t)^4
			model:PivotTo(from:Lerp(self:stand(slot),k))
			if t>=1 then slot.moving=false;connection:Disconnect() end
		end)
		-- The back light flares, then settles.
		slot.rim.Brightness=22
		TweenService:Create(slot.rim,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Brightness=10}):Play()
	else
		model:PivotTo(final)
	end
end
-- While the set is filmed the world's ambient is the studio's: low, so the
-- key and the coloured back lights model the bodies; the duel's own lighting
-- comes back the moment the board hides.
local LIGHTING={Ambient=Color3.fromRGB(40,36,46),OutdoorAmbient=Color3.fromRGB(40,36,46),ExposureCompensation=0,Brightness=0}
function MenuStage:filmed(on)
	if on==self.isFilmed then return end
	self.isFilmed=on
	local Lighting=game:GetService("Lighting")
	if on then
		self.savedLighting={}
		for k,v in LIGHTING do self.savedLighting[k]=Lighting[k];Lighting[k]=v end
	elseif self.savedLighting then
		for k,v in self.savedLighting do Lighting[k]=v end
		self.savedLighting=nil
	end
end
-- Idle life: the back lights breathe out of step, the stroke shimmers.
function MenuStage:step(t)
	for side,slot in self.slots do
		if not slot.moving then slot.glow.Brightness=1.6+.5*math.sin(t*1.3+(if side=="bot" then 1.6 else 0)) end
	end
	self.band.Transparency=.1+.06*math.sin(t*.9)
end
return MenuStage
