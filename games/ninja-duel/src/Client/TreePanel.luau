-- The skill tree of a learned kit (DEC-038, user 13/11: « il faut faire les
-- arbres de compétences réelles »): its branches side by side, each node a
-- tile (on, unlocked, to learn, too dear, locked), and under them what the
-- picked node does, what answers it and the button that learns it or turns it
-- on or off. The server decides (Matches: LearnNode, SetNode); the panel draws
-- Shared/TreeView over the server's Progression view. Opened from the roster
-- (SKILL TREE) and, in the hub, at the kit's master.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local TreeView=require(Shared.TreeView)
local Panel={}
Panel.__index=Panel

local W,H=1180,690
local COLUMN_TOP,COLUMN_H=104,420

function Panel.new(kit,gui,send)
	local self=setmetatable({kit=kit,send=send,tiles={},columns={}},Panel)
	local P,create,frame,text,button,corner=kit.palette,kit.create,kit.frame,kit.text,kit.button,kit.corner
	self.P=P
	self.root=frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(6,5,8),.2)
	self.root.ZIndex=74;self.root.Visible=false;self.root.Active=true
	local card=kit.inkCard(frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(W,H),kit.CARD,0))
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=75
	self.card=card
	local scale=create("UIScale",card,{Scale=1})
	local function fit() local v=workspace.CurrentCamera.ViewportSize;scale.Scale=math.clamp(math.min(v.X/(W+80),v.Y/(H+60)),.45,1.2) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
	self.title=kit.inkTitle(text(card,"",UDim2.fromOffset(32,16),UDim2.fromOffset(760,50),44,P.paper,kit.TITLE_FONT))
	self.subtitle=text(card,"",UDim2.fromOffset(34,64),UDim2.fromOffset(900,22),15,P.gold,kit.BODY_FONT)
	self.close=button(card,"CLOSE",UDim2.fromOffset(W-206,16),UDim2.fromOffset(176,56),function() self:hide() end,P.red)
	-- The strip under the columns.
	local strip=frame(card,UDim2.fromOffset(24,COLUMN_TOP+COLUMN_H+14),UDim2.fromOffset(W-48,H-(COLUMN_TOP+COLUMN_H+14)-20),P.ink,.15)
	corner(strip,8)
	self.head=text(strip,"",UDim2.fromOffset(16,8),UDim2.fromOffset(W-380,30),24,P.paper,kit.TITLE_FONT)
	self.shows=text(strip,"",UDim2.fromOffset(16,40),UDim2.fromOffset(W-380,46),15,P.text,kit.BODY_FONT)
	self.shows.TextWrapped=true;self.shows.TextYAlignment=Enum.TextYAlignment.Top
	self.counter=text(strip,"",UDim2.fromOffset(16,88),UDim2.fromOffset(W-380,20),13,P.muted,kit.BODY_FONT)
	self.counter.TextWrapped=true
	self.note=text(strip,"",UDim2.fromOffset(16,110),UDim2.fromOffset(W-380,20),13,P.gold,kit.BODY_FONT)
	self.action=button(strip,"",UDim2.new(1,-320,.5,-30),UDim2.fromOffset(300,60),function() self:press() end,P.red)
	self.action.Visible=false
	for _,item in {self.head,self.shows,self.counter,self.note} do item.TextXAlignment=Enum.TextXAlignment.Left end
	return self
end

function Panel:shown() return self.root.Visible end
function Panel:hide() self.root.Visible=false end

-- Open (or redraw) the tree of `kitId` with the server's `kits` view.
function Panel:show(kitId,kits)
	self.kitId=kitId;self.kits=kits
	if self.selected and not TreeView.node(kitId,self.selected) then self.selected=nil end
	self:draw()
	self.root.Visible=true
end
function Panel:refresh(kits)
	self.kits=kits
	if self.root.Visible then self:draw() end
end

local STYLE={
	active={bg="gold",text="ink",alpha=0,stroke=nil},
	off={bg="panel",text="paper",alpha=0,stroke="gold"},
	learn={bg="red",text="paper",alpha=0,stroke=nil},
	short={bg="panel",text="muted",alpha=.15,stroke=nil},
	locked={bg="locked",text="muted",alpha=.35,stroke=nil},
}

function Panel:draw()
	local K,P=self.kit,self.P
	local state=self.kits and self.kits.trees and self.kits.trees[self.kitId]
	local layout=TreeView.layout(self.kitId,state)
	for _,column in self.columns do column:Destroy() end
	self.columns={};self.tiles={}
	if not layout then self.title.Text="NO TREE";return end
	self.title.Text=layout.title
	self.subtitle.Text=layout.subtitle
	local n=#layout.branches
	local gap=12
	local colW=math.floor((W-48-gap*(n-1))/n)
	for i,branch in layout.branches do
		local x=24+(i-1)*(colW+gap)
		local column=K.frame(self.card,UDim2.fromOffset(x,COLUMN_TOP),UDim2.fromOffset(colW,COLUMN_H),P.ink,1)
		table.insert(self.columns,column)
		K.text(column,branch.name,UDim2.fromOffset(0,0),UDim2.fromOffset(colW,24),18,P.gold,K.TITLE_FONT,Enum.TextXAlignment.Center)
		local list=K.create("ScrollingFrame",column,{Position=UDim2.fromOffset(0,28),Size=UDim2.new(1,0,1,-28),BackgroundTransparency=1,BorderSizePixel=0,
			ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
		K.create("UIListLayout",list,{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
		for order,node in branch.nodes do
			local style=STYLE[node.status] or STYLE.locked
			local tile=K.create("TextButton",list,{Text="",LayoutOrder=order,Size=UDim2.new(1,-6,0,38),BackgroundColor3=P[style.bg] or P.panel,
				BackgroundTransparency=style.alpha,BorderSizePixel=0,AutoButtonColor=true})
			K.corner(tile,6)
			if style.stroke or node.item then
				K.create("UIStroke",tile,{Color=P[style.stroke or "gold"],Thickness=if node.item then 2.5 else 1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
			end
			local name=K.text(tile,string.upper(node.name),UDim2.fromOffset(8,2),UDim2.new(1,-50,0,20),if node.major then 17 else 15,P[style.text] or P.text,
				if node.major then K.TITLE_FONT else K.BODY_FONT)
			name.TextXAlignment=Enum.TextXAlignment.Left;name.TextTruncate=Enum.TextTruncate.AtEnd
			local tag=K.text(tile,if node.item then "KIT OBJECT" else node.kindLabel,UDim2.fromOffset(8,21),UDim2.new(1,-50,0,14),10,P[style.text] or P.muted,K.BODY_FONT)
			tag.TextXAlignment=Enum.TextXAlignment.Left;tag.TextTransparency=.25
			local cost=K.text(tile,if node.status=="active" then "ON" elseif node.status=="off" then "OFF" else tostring(node.cost),
				UDim2.new(1,-46,0,0),UDim2.fromOffset(40,38),18,P[style.text] or P.text,K.TITLE_FONT,Enum.TextXAlignment.Center)
			cost.TextTransparency=0
			tile.Activated:Connect(function() self.selected=node.id;self:detail() end)
			self.tiles[node.id]=tile
		end
	end
	if not self.selected then
		-- Open on what can be done now: the first node to learn, else the first.
		for _,branch in layout.branches do for _,node in branch.nodes do
			if not self.selected and node.status=="learn" then self.selected=node.id end
		end end
		self.selected=self.selected or (layout.branches[1] and layout.branches[1].nodes[1] and layout.branches[1].nodes[1].id)
	end
	self:detail()
end

function Panel:detail()
	local state=self.kits and self.kits.trees and self.kits.trees[self.kitId]
	local d=self.selected and TreeView.detail(self.kitId,state,self.selected)
	for id,tile in self.tiles do
		local mark=tile:FindFirstChild("Picked")
		if id==self.selected and not mark then
			local m=self.kit.create("UIStroke",tile,{Name="Picked",Color=self.P.paper,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
			m.Name="Picked"
		elseif id~=self.selected and mark then mark:Destroy() end
	end
	if not d then self.head.Text="";self.shows.Text="";self.counter.Text="";self.note.Text="";self.action.Visible=false;return end
	self.head.Text=d.head
	self.shows.Text=d.shows
	self.counter.Text=d.counter
	self.note.Text=d.note or ""
	self.pending=d.action
	self.action.Visible=d.action~=nil
	if d.action then
		self.action.Text=d.action.label
		self.action.BackgroundColor3=if d.action.kind=="learn" then self.P.red elseif d.action.kind=="on" then self.P.gold else self.P.panel
		self.action.TextColor3=if d.action.kind=="on" then self.P.ink else self.P.text
	end
end

function Panel:press()
	local act=self.pending
	if not act or not self.kitId or not self.selected then return end
	if act.kind=="learn" then self.send("LearnNode",{player=self.kitId,node=self.selected})
	else self.send("SetNode",{player=self.kitId,node=self.selected,on=act.kind=="on"}) end
end

return Panel
