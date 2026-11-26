-- Konoha's minimap and big map (DESIGN, step 3, DEC-047), drawn from
-- Shared/KonohaLayout: its districts in their colours, its streets in cream,
-- its places (Pois) as ink seals, the masters' homes as red seals and the
-- things to do alone as gold stars. A page of the manga: paper, ink ring.
--
-- The minimap: a window under the place box (Client/HubLayout's hud), the
-- village sliding under a red arrow (the player, turned with the camera);
-- the nearest place written at its foot. Tap it, or M, for the big map: the
-- whole village, every place named, and the list of things to do.
-- Presentation only: positions come from the character, nothing is sent.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Layout=require(Shared.KonohaLayout)
local HubMap=require(Shared.HubMap) -- its Origin: KonohaLayout's base frame
-- (DESIGN 26/11, passe 2: « la carte dessinée de Konoha, pas un plan de blocs »)
-- the drawn map (assets/ui/map_konoha.png, generate_map.py) under the seals
-- once uploaded; until then, the plan of blocks
local okA,UIAssets=pcall(function() return require(Shared.UIAssets) end)
local DRAWN=okA and UIAssets.id and UIAssets.id("map_konoha") or nil
if DRAWN=="" then DRAWN=nil end

local Map={}
Map.DRAWN=DRAWN
Map.__index=Map

Map.SIZE=208        -- the minimap's window (px)
Map.ZOOM=1.25       -- px per base stud in the minimap
Map.BIG=1.55        -- px per base stud on the big map
-- The things to do alone (step 3), by place: what the gold star says.
Map.TODO={
	Training={"TRAINING DUMMIES","Hit stuff."},
	Rooftops={"ROOFTOP RACE","Beat the clock."},
	Market={"KUNAI TARGETS","Don't miss."},
	Hall={"DUEL THE AI","Or hit DUELS anywhere."},
}

-- ------------------------------------------------------------------ pure
-- A world position into the layout's base frame (x, z in base studs).
function Map.toBase(position:Vector3)
	local rel=position-HubMap.Origin
	local s=Layout.Scale or 1
	return rel.X/s,rel.Z/s
end
-- A base position into map pixels, the map's top-left at (-HalfX, MinZ).
function Map.toPixels(x,z,zoom)
	return (x+Layout.HalfX)*zoom,(z-Layout.MinZ)*zoom
end
-- The map's size in pixels at a zoom.
function Map.extent(zoom)
	return 2*Layout.HalfX*zoom,(Layout.MaxZ-Layout.MinZ)*zoom
end
-- The kind of a place's seal: "todo", "master" or "place".
function Map.kind(poi)
	if Map.TODO[poi.id] then return "todo" elseif poi.master then return "master" end
	return "place"
end
-- The nearest named place to a base position, within `reach` studs.
function Map.nearest(x,z,reach)
	local best,dist=nil,reach or 60
	for _,p in Layout.Pois do
		if not p.far then
			local d=math.sqrt((p.at.X-x)^2+(p.at.Y-z)^2)
			if d<dist then best,dist=p,d end
		end
	end
	return best
end
-- The big map's list: the things to do, in a fixed order.
function Map.todoList()
	local out={}
	for _,p in Layout.Pois do
		local t=Map.TODO[p.id]
		if t then table.insert(out,{id=p.id,title=t[1],line=t[2],place=p.name}) end
	end
	return out
end

-- ------------------------------------------------------------------ drawing
local function drawVillage(kit,parent,zoom,tier,labels)
	local M=kit.MANGA
	local w,h=Map.extent(zoom)
	local village=kit.frame(parent,UDim2.fromOffset(0,0),UDim2.fromOffset(w,h),M.back or M.paper,0)
	village.Name="Village"
	if Map.DRAWN then
		kit.create("ImageLabel",village,{Name="Drawn",Image=Map.DRAWN,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Stretch})
	end
	for _,d in (if Map.DRAWN then {} else Layout.Districts) do
		local x,y=Map.toPixels(d.x0,d.z0,zoom)
		local f=kit.frame(village,UDim2.fromOffset(x,y),UDim2.fromOffset((d.x1-d.x0)*zoom,(d.z1-d.z0)*zoom),d.color,.35)
		f.BorderSizePixel=0
		local named=false
		for _,p in Layout.Pois do if p.name==d.name then named=true end end
		if labels and not named then
			local t=kit.text(f,d.name,UDim2.fromOffset(4,2),UDim2.new(1,-8,0,14),11,M.ink,kit.STRONG_FONT or kit.BODY_FONT)
			t.TextTransparency=.35
		end
	end
	for _,s in (if Map.DRAWN then {} else Layout.Streets) do
		local ax,ay=Map.toPixels(s.a.X,s.a.Y,zoom)
		local bx,by=Map.toPixels(s.b.X,s.b.Y,zoom)
		local len=math.sqrt((bx-ax)^2+(by-ay)^2)
		local street=kit.frame(village,UDim2.fromOffset((ax+bx)/2,(ay+by)/2),UDim2.fromOffset(len+s.width*zoom,math.max(3,s.width*zoom*.6)),M.paper,0)
		street.AnchorPoint=Vector2.new(.5,.5)
		street.Rotation=math.deg(math.atan2(by-ay,bx-ax))
	end
	-- (23/11, DEV, François: « la carte n'est vraiment pas complète ») the
	-- roofs of the plan, as the village is built (tools/village): the rows of
	-- houses in their quarter's colour, the landmarks in ink, the walkways
	for _,b in Layout.Buildings do
		local bw,bd=b[4],b[5]
		if (b[7] or 0)%180==90 then bw,bd=bd,bw end
		local x,y=Map.toPixels(b[2]-bw/2,b[3]-bd/2,zoom)
		local quarter=Layout.districtAt(b[2],b[3])
		local tint=if b[9] then M.ink elseif quarter then quarter.color:Lerp(M.ink,.45) else M.ink
		local roof=kit.frame(village,UDim2.fromOffset(x,y),UDim2.fromOffset(math.max(2,bw*zoom),math.max(2,bd*zoom)),tint,if b[9] then .1 else .2)
		roof.BorderSizePixel=0
	end
	for _,br in Layout.Bridges or {} do
		local ax,ay=Map.toPixels(br[1],br[2],zoom)
		local bx,by=Map.toPixels(br[4],br[5],zoom)
		local plank=kit.frame(village,UDim2.fromOffset(math.min(ax,bx)-1,math.min(ay,by)-1),UDim2.fromOffset(math.abs(bx-ax)+2,math.abs(by-ay)+2),M.ink,.3)
		plank.BorderSizePixel=0
	end
	local seals={}
	for _,p in Layout.poisFor(tier) do
		if not p.far then
			local x,y=Map.toPixels(p.at.X,p.at.Y,zoom)
			local kind=Map.kind(p)
			local size=if kind=="place" then 12 else 18
			local seal=kit.frame(village,UDim2.fromOffset(x,y),UDim2.fromOffset(size,size),
				if kind=="todo" then (M.gold or Color3.fromRGB(232,178,48)) elseif kind=="master" then M.red else M.ink,0)
			seal.AnchorPoint=Vector2.new(.5,.5);seal.Rotation=if kind=="todo" then 45 else 0
			kit.create("UIStroke",seal,{Color=M.paper,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
			if kind~="todo" then
				local round=kit.create("UICorner",seal,{});round.CornerRadius=UDim.new(.5,0)
			end
			seal.Name=p.id
			seals[p.id]=seal
			if labels and (not Map.DRAWN or kind=="todo") then
				-- near the east edge the name reads leftwards of its seal
				local east=x>w-230
				local t=kit.text(village,(if kind=="todo" then Map.TODO[p.id][1].."  •  " else "")..p.name,UDim2.fromOffset(if east then x-252 else x+12,y-9),UDim2.fromOffset(240,18),13,M.ink,kit.STRONG_FONT or kit.BODY_FONT,
					if east then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left)
				kit.create("UIStroke",t,{Color=M.paper,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
			end
		end
	end
	return village,seals
end

local function arrow(kit,parent,size)
	local M=kit.MANGA
	-- a red arrowhead: a turned square cut by its parent's clip, with a cream rim
	local holder=kit.frame(parent,UDim2.fromScale(.5,.5),UDim2.fromOffset(size,size),M.paper,1)
	holder.AnchorPoint=Vector2.new(.5,.5);holder.ZIndex=30
	local tip=kit.frame(holder,UDim2.fromScale(.5,.42),UDim2.fromOffset(size*.62,size*.62),M.red,0)
	tip.AnchorPoint=Vector2.new(.5,.5);tip.Rotation=45;tip.ZIndex=31
	kit.create("UIStroke",tip,{Color=M.paper,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local dot=kit.frame(holder,UDim2.fromScale(.5,.5),UDim2.fromOffset(size*.4,size*.4),M.ink,0)
	dot.AnchorPoint=Vector2.new(.5,.5);dot.ZIndex=32
	local round=kit.create("UICorner",dot,{});round.CornerRadius=UDim.new(.5,0)
	return holder
end

function Map.new(kit,gui)
	local self=setmetatable({kit=kit},Map)
	local M=kit.MANGA
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	-- the minimap
	local mini=kit.button(gui,"",UDim2.fromOffset(18,110),UDim2.fromOffset(Map.SIZE,Map.SIZE+30),function() self:openBig() end,M.paper)
	mini.Name="MiniMap";mini.Visible=false;mini.ZIndex=20;mini.ClipsDescendants=false
	-- (23/11, A06) never turned: Roblox does not clip a turned frame's
	-- children, and the whole village then spills over the phone's left side
	kit.create("UIStroke",mini,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.mini=mini
	self.miniScale=kit.create("UIScale",mini,{Scale=1})
	local window=kit.frame(mini,UDim2.fromOffset(6,6),UDim2.fromOffset(Map.SIZE-12,Map.SIZE-12),M.back or M.paper,0)
	window.ClipsDescendants=true;window.ZIndex=21
	self.window=window
	self.village=drawVillage(kit,window,Map.ZOOM,2,false)
	self.arrow=arrow(kit,window,22)
	self.placeLabel=kit.text(mini,"",UDim2.fromOffset(6,Map.SIZE-2),UDim2.new(1,-50,0,26),15,M.ink,STRONG)
	self.placeLabel.TextScaled=true
	kit.create("UITextSizeConstraint",self.placeLabel,{MaxTextSize=15,MinTextSize=9})
	local key=kit.text(mini,"M",UDim2.new(1,-40,0,Map.SIZE-2),UDim2.fromOffset(32,24),15,M.cream,STRONG,Enum.TextXAlignment.Center)
	key.BackgroundTransparency=0;key.BackgroundColor3=M.ink
	self.mKey=key
	-- the big map
	-- (23/11, François: « la carte prend tout l'écran ») the game stays seen
	-- around it: a lighter veil, the card at most 86 % of the screen
	local root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.55)
	root.Visible=false;root.ZIndex=70;root.Active=true;root.Name="BigMap"
	self.root=root
	local w,h=Map.extent(Map.BIG)
	local W,H=w+330,h+110
	self.W,self.H=W,H
	local card=kit.frame(root,UDim2.fromScale(.5,.5),UDim2.fromOffset(W,H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5)
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.bigScale=kit.create("UIScale",card,{Scale=1})
	kit.text(card,"KONOHA",UDim2.fromOffset(28,10),UDim2.fromOffset(400,64),60,M.ink,kit.TITLE_FONT)
	kit.frame(card,UDim2.fromOffset(28,70),UDim2.fromOffset(180,6),M.red,0)
	self.closeBig=kit.button(card,"X",UDim2.new(1,-88,0,14),UDim2.fromOffset(68,68),function() self:closeBigMap() end,M.ink)
	self.closeBig.TextColor3=M.cream;self.closeBig.TextSize=34
	local frame=kit.frame(card,UDim2.fromOffset(28,90),UDim2.fromOffset(w,h),M.back or M.paper,0)
	frame.ClipsDescendants=true
	kit.create("UIStroke",frame,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.bigVillage,self.bigSeals=drawVillage(kit,frame,Map.BIG,3,true)
	self.you=arrow(kit,self.bigVillage,26)
	-- the things to do alone
	local list=kit.frame(card,UDim2.fromOffset(w+48,90),UDim2.fromOffset(W-w-72,h),M.ink,0)
	kit.text(list,"ALONE? GO DO",UDim2.fromOffset(16,10),UDim2.new(1,-32,0,36),32,M.cream,kit.TITLE_FONT)
	for i,t in Map.todoList() do
		local y=58+(i-1)*96
		local star=kit.frame(list,UDim2.fromOffset(26,y+14),UDim2.fromOffset(18,18),M.gold or Color3.fromRGB(232,178,48),0);star.Rotation=45
		kit.text(list,t.title,UDim2.fromOffset(52,y),UDim2.new(1,-64,0,28),24,M.cream,kit.TITLE_FONT)
		kit.text(list,t.line,UDim2.fromOffset(52,y+28),UDim2.new(1,-64,0,22),15,M.cream,kit.BODY_FONT)
		kit.text(list,t.place,UDim2.fromOffset(52,y+50),UDim2.new(1,-64,0,18),12,M.redSoft or M.red,STRONG)
	end
	local legend=kit.text(list,"● RED: A MASTER'S HOME     ◆ GOLD: SOMETHING TO DO",UDim2.new(0,16,1,-56),UDim2.new(1,-32,0,44),13,M.cream,STRONG)
	legend.TextWrapped=true
	pcall(function()
		local function fit()
			local v=workspace.CurrentCamera.ViewportSize
			self.bigScale.Scale=kit.fitScale(Vector2.new(v.X*.86,(v.Y-58)*.86),W+24,H+24,1)
		end
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
	end)
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
			if processed then return end
			if input.KeyCode==Enum.KeyCode.M then
				if self.root.Visible then self:closeBigMap() elseif self.mini.Visible then self:openBig() end
			elseif self.root.Visible and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then
				self:closeBigMap()
			end
		end)
	end)
	return self
end

function Map:shown() return self.root.Visible end
function Map:openBig() self.root.Visible=true;if self.onChange then self.onChange() end end
function Map:closeBigMap() self.root.Visible=false;if self.onChange then self.onChange() end end
-- Where the minimap sits (window px) and its scale (Client/HubLayout's).
function Map:place(x,y,scale)
	self.mini.Position=UDim2.fromOffset(math.floor(x+.5),math.floor(y+.5))
	self.miniScale.Scale=scale or 1
end
function Map:setVisible(on) self.mini.Visible=on end
-- Every frame: the village slides under the arrow; the arrow turns with the
-- camera; the place under him is written.
function Map:update(position:Vector3?,look:Vector3?)
	if not position then return end
	local x,z=Map.toBase(position)
	local px,py=Map.toPixels(x,z,Map.ZOOM)
	local half=(Map.SIZE-12)/2
	self.village.Position=UDim2.fromOffset(math.floor(half-px+.5),math.floor(half-py+.5))
	local heading=0
	if look and (look.X~=0 or look.Z~=0) then heading=math.deg(math.atan2(look.X,-look.Z)) end
	self.arrow.Rotation=heading
	local bx,by=Map.toPixels(x,z,Map.BIG)
	self.you.Position=UDim2.fromOffset(bx,by);self.you.Rotation=heading
	local near=Map.nearest(x,z,70)
	local district=Layout.districtAt(x,z)
	self.placeLabel.Text=(near and near.name) or (district and district.name) or "KONOHA"
end

return Map
