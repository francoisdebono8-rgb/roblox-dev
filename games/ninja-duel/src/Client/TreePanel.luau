-- The skill tree of a learned kit (DEC-038, user 13/11: « vraiment les arbres
-- de compétences, vraiment comment ça va marcher »). Drawn as the design
-- board shows it: the tiers as rows (I from the start, II at 300 mastery,
-- III at 800), the branches as columns, a line from a node to the one it
-- opens in the same branch; each node a tile (on, learned, to learn, too
-- dear, its tier closed, waiting for another node). On the right, the picked
-- node: what it does, what answers it, what it opens, and the button that
-- learns it or turns it on or off. At the top, the points and the mastery
-- towards the next tier. The server decides (Matches: LearnNode, SetNode);
-- the panel draws Shared/TreeView over the server's Progression view.
-- Opened from the roster (SKILL TREE), a master's card and the result.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local TreeView=require(Shared.TreeView)
-- (21/11, DEC-045, step 2 DESIGN) two tabs: the kit's tree and the ninja's
-- tree (Shared/NinjaTree, the same for every kit). The KIT tab opens with the
-- kit's card (what he starts with, what the tree adds, his signature: the
-- CM's « why this kit »); a node that unlocks a technique shows it big. The
-- NINJA tab opens with the five chakra natures, one card each in its colour.
local Fighters=require(Shared.Fighters)
local KitTexts=require(Shared.KitTexts)
local NinjaTree=require(Shared.NinjaTree)
local okA,UIAssets=pcall(function() return require(Shared.UIAssets) end)
if not okA then UIAssets=nil end
local Panel={}
Panel.__index=Panel

local W,H=1500,800
local GRID_X,GRID_Y,GRID_W,GRID_H=24,140,1036,592
local DETAIL_X=1084
local GUTTER=92
Panel.CLOSE={X=W-156,Y=22,W=132,H=58}
local TILE_H,TILE_GAP=40,6
local CARD_H=124 -- the kit's card, over the KIT tab's grid
local NATURE_H=132 -- the natures, over the NINJA tab's grid
Panel.TAB={W=170,H=48,Y=92,X=816}

-- ------------------------------------------------------------------ pure
local function techName(def,id)
	for _,t in def and def.Techniques or {} do if t.Id==id then return string.upper(t.Name) end end
	return string.upper(id)
end
Panel.techName=techName
-- The kit's card: what he starts with, what his tree adds, the change at its
-- top, his signature. Nodes with Unlock (a technique, or "Awakening") and
-- objects (Item) are what the tree adds; a technique no node unlocks is his
-- from the start.
function Panel.kitCard(kitId)
	local def=Fighters[kitId]
	if not def then return nil end
	local unlocked,adds,transform={},{},nil
	for _,node in TreeView.tree(kitId) do
		if node.Unlock then
			unlocked[node.Unlock]=true
			table.insert(adds,if node.Unlock=="Awakening" then string.upper(node.Name) else techName(def,node.Unlock))
		elseif node.Item then table.insert(adds,string.upper(node.Name)) end
		if node.Transform then transform=string.upper(node.Name) end
	end
	local starts={}
	for _,t in def.Techniques or {} do if not unlocked[t.Id] then table.insert(starts,string.upper(t.Name)) end end
	local lines=KitTexts.of(kitId)
	-- (23/11, step 4) the CM's sheet when written (start, grows, top), for all 8
	return {name=KitTexts.name(kitId),starts=starts,adds=adds,transform=transform,signature=lines and lines.why or "",
		topLine=lines and lines.top or nil,startLine=lines and lines.start or nil}
end

-- The natures' colours (the element seen on the blade and the kunai).
Panel.NATURE_COLOR={Fire={226,84,36},Wind={118,196,150},Lightning={246,206,58},Earth={150,108,66},Water={54,128,206}}
Panel.NATURE_DARK={Fire=true,Earth=true,Water=true} -- cream words on these
-- The ninja tree's node state as a tile's (the KIT tab's words).
function Panel.ninjaStatus(node)
	if node.state=="active" then return "active" elseif node.state=="learned" then return "off" elseif node.state=="open" then return "learn" end
	local why=node.why or ""
	if why:find("^Tier") then return "tier" elseif why:find("^Not enough") then return "short" end
	return "locked"
end
-- The NINJA tab: the five natures, then the other branches as the KIT tab's
-- grid (tiers as rows: I from the start, II and III at NinjaTree.TierNeed).
function Panel.ninjaLayout(view)
	view=view or NinjaTree.view(nil,0)
	local out={natures={},branches={},tiers={},points=view.points,free=view.free,nature=view.nature}
	local byName={}
	for _,node in view.nodes do
		local def=NinjaTree.ById[node.id]
		local item={id=node.id,name=node.name,cost=node.cost,kind=node.branch,kindLabel=string.upper(node.branch),tier=node.tier,
			status=Panel.ninjaStatus(node),why=node.why,shows=node.shows,nature=node.nature,major=node.tier==3,requires=def and def.Requires}
		if node.nature then table.insert(out.natures,item)
		else
			local branch=byName[node.branch]
			if not branch then branch={name=string.upper(node.branch),nodes={}};byName[node.branch]=branch;table.insert(out.branches,branch) end
			table.insert(branch.nodes,item)
		end
	end
	for t,need in NinjaTree.TierNeed do
		local row={index=t,name=NinjaTree.TierNames[t],need=need,open=(view.points or 0)>=need,cells={}}
		for b,branch in out.branches do
			row.cells[b]={}
			for _,node in branch.nodes do if node.tier==t then table.insert(row.cells[b],node) end end
		end
		table.insert(out.tiers,row)
	end
	for _,row in out.tiers do if not row.open then out.nextTier=row break end end
	out.progress=if out.nextTier then math.clamp((view.points or 0)/out.nextTier.need,0,1) else 1
	return out
end
-- The detail strip of a ninja node.
function Panel.ninjaDetail(view,id)
	for _,node in (view or {nodes={}}).nodes do
		if node.id==id then
			local status=Panel.ninjaStatus(node)
			local action=nil
			if status=="learn" then action={kind="learn",label="LEARN  •  "..node.cost.." POINTS"}
			elseif status=="off" then action={kind="on",label=if node.nature then "CHOOSE "..string.upper(node.nature) else "TURN ON"}
			elseif status=="active" and not node.nature then action={kind="off",label="TURN OFF"} end
			local answer=node.nature and NinjaTree.Infusion[node.nature] and NinjaTree.Infusion[node.nature].Answer
			local note=if node.why then string.upper(node.why) else nil
			if status=="active" and node.nature then note="YOUR NATURE: YOUR INFUSED KUNAI AND BLADE CARRY IT. CHANGE IT BETWEEN DUELS." end
			return {id=id,head=node.name.."  •  "..node.cost.." POINTS  •  TIER "..NinjaTree.TierNames[node.tier].."  •  "..string.upper(node.branch),
				shows=node.shows,counter=if answer then "ANSWER: "..answer elseif node.nature==nil and node.branch=="Infusion" then "NEEDS A NATURE" else "",
				note=note,status=status,action=action}
		end
	end
	return nil
end
-- A node's pictogram: the technique it unlocks, its object, its element.
function Panel.icon(node)
	if not UIAssets then return nil end
	if node.Unlock and node.Unlock~="Awakening" then return UIAssets.id(UIAssets.iconName(node.Unlock)) end
	if node.Item then return UIAssets.item(node.Item) or UIAssets.id("icon_weights") end
	if node.id=="InfusedKunai" or node.id=="InfusedBlade" or node.id=="ExplosiveTag" then return UIAssets.id("icon_kunai") end
	if node.id=="SmokeBomb" then return UIAssets.id("icon_clone") end
	return nil
end

function Panel.new(kit,gui,send)
	local self=setmetatable({kit=kit,send=send,tiles={},drawn={}},Panel)
	local P,create,frame,text,button,corner=kit.palette,kit.create,kit.frame,kit.text,kit.button,kit.corner
	self.P=P
	-- (DA v3, DESIGN validated 14/11; François 15/11: « c'était toujours les
	-- cadres IA ») the tree is a page of the manga, as the shop: paper, ink,
	-- one red for what can be learned.
	local M=Panel.colors(kit)
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	local function ring(gui,thick) return create("UIStroke",gui,{Color=M.ink,Thickness=thick or 3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
	self.ring=ring
	self.root=frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=74;self.root.Visible=false;self.root.Active=true
	local card=frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(W,H),M.back,0)
	corner(card,6);ring(card,4)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=75
	self.card=card
	local scale=create("UIScale",card,{Scale=1})
	-- (14/11, a reader's report on PR #84) the card fits any window: no floor
	-- that pushes CLOSE off a narrow or portrait one (Panel.fit); small, a
	-- close mark anchored in the window's corner, and the pad's B closes.
	self.corner=kit.cornerClose(self.root,function() self:hide() end)
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=Panel.fit(v,kit)
		self.corner.Visible=scale.Scale<kit.SMALL
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input)
			if input.KeyCode==Enum.KeyCode.ButtonB and self.root.Visible then self:hide() end
		end)
	end)
	self.title=text(card,"",UDim2.fromOffset(32,12),UDim2.fromOffset(700,62),58,M.ink,kit.TITLE_FONT)
	local brush=frame(card,UDim2.fromOffset(34,72),UDim2.fromOffset(200,7),M.red,0);corner(brush,4);brush.Rotation=-1
	self.subtitle=text(card,"",UDim2.fromOffset(34,84),UDim2.fromOffset(760,22),17,M.brown,STRONG)
	-- Mastery towards the next tier, and the points.
	self.tierLabel=text(card,"",UDim2.fromOffset(W-640,28),UDim2.fromOffset(330,20),16,M.ink,STRONG)
	self.tierNext=text(card,"",UDim2.fromOffset(W-640,28),UDim2.fromOffset(330,20),15,M.brown,STRONG,Enum.TextXAlignment.Right)
	local track=frame(card,UDim2.fromOffset(W-640,56),UDim2.fromOffset(330,12),M.paper,0);corner(track,6);ring(track,2)
	self.tierFill=frame(track,UDim2.fromOffset(0,0),UDim2.new(0,0,1,0),M.red,0);corner(self.tierFill,6)
	local chip=frame(card,UDim2.fromOffset(W-290,20),UDim2.fromOffset(120,66),M.paper,0);chip.Rotation=2;ring(chip,3)
	self.free=text(chip,"",UDim2.fromOffset(0,4),UDim2.fromOffset(120,36),36,M.ink,STRONG,Enum.TextXAlignment.Center)
	self.earned=text(chip,"",UDim2.fromOffset(0,42),UDim2.fromOffset(120,18),12,M.brown,STRONG,Enum.TextXAlignment.Center)
	-- (step 2) the two tabs
	self.tab="kit";self.tabs={}
	for i,t in {{id="kit",name="KIT TREE"},{id="ninja",name="NINJA TREE"}} do
		local b=button(card,t.name,UDim2.fromOffset(Panel.TAB.X+(i-1)*(Panel.TAB.W+10),Panel.TAB.Y),UDim2.fromOffset(Panel.TAB.W,Panel.TAB.H),function()
			if self.tab~=t.id then self.tab=t.id;self.selected=nil;self:draw() end
		end,M.paper)
		b.Font=STRONG;b.TextSize=20;ring(b,3)
		self.tabs[t.id]=b
	end
	self.close=button(card,"CLOSE",UDim2.fromOffset(Panel.CLOSE.X,Panel.CLOSE.Y),UDim2.fromOffset(Panel.CLOSE.W,Panel.CLOSE.H),function() self:hide() end,M.paper)
	self.close.TextColor3=M.ink;self.close.Font=STRONG;self.close.TextSize=24;ring(self.close,3)
	-- The grid (scrolls when a tree is tall).
	self.grid=create("ScrollingFrame",card,{Position=UDim2.fromOffset(GRID_X,GRID_Y),Size=UDim2.fromOffset(GRID_W,GRID_H),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=5,CanvasSize=UDim2.fromOffset(GRID_W,GRID_H),ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=76})
	-- The picked node.
	local detail=frame(card,UDim2.fromOffset(DETAIL_X,GRID_Y),UDim2.fromOffset(W-DETAIL_X-24,GRID_H),M.paper,0)
	corner(detail,4);ring(detail,3)
	local DW=W-DETAIL_X-24
	self.kicker=text(detail,"",UDim2.fromOffset(20,18),UDim2.fromOffset(DW-40,18),14,M.red,STRONG)
	self.head=text(detail,"",UDim2.fromOffset(20,40),UDim2.fromOffset(DW-40,84),40,M.ink,kit.TITLE_FONT)
	self.head.TextYAlignment=Enum.TextYAlignment.Top
	self.shows=text(detail,"",UDim2.fromOffset(20,132),UDim2.fromOffset(DW-40,100),17,M.mid,kit.BODY_FONT)
	self.shows.TextYAlignment=Enum.TextYAlignment.Top
	-- (step 2) the technique a node unlocks, big: its pictogram and its name
	self.unlock=frame(detail,UDim2.fromOffset(20,236),UDim2.fromOffset(DW-40,100),M.ink,0);corner(self.unlock,4)
	self.unlock.Visible=false
	self.unlockIcon=create("ImageLabel",self.unlock,{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(84,84),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit})
	text(self.unlock,"UNLOCKS",UDim2.fromOffset(102,10),UDim2.new(1,-110,0,18),14,M.red,STRONG)
	self.unlockName=text(self.unlock,"",UDim2.fromOffset(102,30),UDim2.new(1,-110,0,62),34,M.cream,kit.TITLE_FONT)
	self.unlockName.TextScaled=true
	self.counter=text(detail,"",UDim2.fromOffset(20,344),UDim2.fromOffset(DW-40,56),15,M.brown,kit.BODY_FONT)
	self.counter.TextYAlignment=Enum.TextYAlignment.Top
	self.note=text(detail,"",UDim2.fromOffset(20,402),UDim2.fromOffset(DW-40,90),15,M.red,STRONG)
	self.note.TextYAlignment=Enum.TextYAlignment.Top
	self.action=button(detail,"",UDim2.new(0,20,1,-80),UDim2.new(1,-40,0,60),function() self:press() end,M.red)
	self.action.TextSize=26;self.action.Font=STRONG;self.action.Visible=false
	self.actionRing=ring(self.action,3);self.actionRing.Enabled=false
	-- The legend under the grid.
	self.legend=text(card,"ON  •  LEARNED, OFF  •  TO LEARN  •  NOT ENOUGH POINTS  •  TIER CLOSED  •  WAITS FOR A NODE",
		UDim2.fromOffset(GRID_X,H-56),UDim2.fromOffset(GRID_W,20),14,M.mid,STRONG)
	self.footer=text(card,"Switch nodes between duels. In ranked, everyone has the full kit.",
		UDim2.fromOffset(GRID_X,H-34),UDim2.fromOffset(W-48,20),13,M.brown,kit.BODY_FONT)
	return self
end

-- (DA v3) the page's colours (UI.kit.MANGA), and what a tile of each state wears.
function Panel.colors(kit)
	local M=kit.MANGA or {}
	return {paper=M.paper or Color3.fromRGB(255,253,248),back=M.back or Color3.fromRGB(242,235,221),ink=M.ink or Color3.fromRGB(20,16,17),
		red=M.red or Color3.fromRGB(195,18,29),cream=M.cream or Color3.fromRGB(246,238,222),brown=M.brown or Color3.fromRGB(94,79,67),
		mid=M.mid or Color3.fromRGB(58,47,40),off=M.off or Color3.fromRGB(138,124,112)}
end
-- The card's scale in a window of `viewport` pixels (it always fits).
function Panel.fit(viewport,kit) return kit.fitScale(viewport,W+60,H+40,1.2) end
-- Where CLOSE sits in the window, for the suites: {x, y, w, h} in pixels.
function Panel.closeRect(viewport,kit)
	local s=Panel.fit(viewport,kit)
	local left,top=viewport.X/2-W*s/2,viewport.Y/2-H*s/2
	return {x=left+Panel.CLOSE.X*s,y=top+Panel.CLOSE.Y*s,w=Panel.CLOSE.W*s,h=Panel.CLOSE.H*s,scale=s}
end
function Panel:shown() return self.root.Visible end
-- (14/11) The pad's focus: on the picked node when the tree opens, given back
-- when it closes (the same as Client/ShopPanel).
function Panel:hide()
	self.root.Visible=false
	pcall(function()
		local GuiService=game:GetService("GuiService")
		local selected=GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.root) then GuiService.SelectedObject=nil end
	end)
end

function Panel:show(kitId,kits)
	if self.kitId~=kitId then self.selected=nil end
	self.kitId=kitId;self.kits=kits
	if self.selected and not TreeView.node(kitId,self.selected) then self.selected=nil end
	self:draw()
	self.root.Visible=true
	local target=self.tiles[self.selected] or self.close
	pcall(function()
		if game:GetService("UserInputService"):GetLastInputType().Name:sub(1,7)~="Gamepad" then return end
		task.defer(function() pcall(function() game:GetService("GuiService").SelectedObject=target end) end)
	end)
end
function Panel:refresh(kits)
	self.kits=kits
	if self.root.Visible then self:draw() end
end

-- (DA v3) on: a band of ink, its words cream (as a picked row of YOUR
-- NINJA); learned and off: paper ringed in ink; to learn: the red; not enough
-- points, a closed tier, waiting for a node: grey words on the page.
local STYLE={
	active={bg="ink",text="cream",alpha=0,stroke=nil,tag="ON"},
	off={bg="paper",text="ink",alpha=0,stroke="ink",tag="OFF"},
	learn={bg="red",text="cream",alpha=0,stroke=nil},
	short={bg="paper",text="off",alpha=0,stroke="off"},
	tier={bg="back",text="off",alpha=0,stroke="off"},
	locked={bg="back",text="off",alpha=0,stroke="off"},
}
Panel.STYLE=STYLE

function Panel:state() return self.kits and self.kits.trees and self.kits.trees[self.kitId] end

function Panel:draw()
	local K,P=self.kit,self.P
	for id,b in self.tabs do
		b.BackgroundColor3=if id==self.tab then self.M.ink else self.M.paper
		b.TextColor3=if id==self.tab then self.M.cream else self.M.ink
	end
	for _,item in self.drawn do item:Destroy() end
	self.drawn={};self.tiles={}
	if self.tab=="ninja" then return self:drawNinja() end
	local layout=TreeView.layout(self.kitId,self:state())
	if not layout then self.title.Text="NO TREE";return end
	self.title.Text=layout.title
	self.subtitle.Text=layout.subtitle
	self.free.Text=tostring(layout.free)
	self.earned.Text="FREE / "..layout.points.." POINTS"
	self.tierLabel.Text="MASTERY "..layout.mastery
	self.tierNext.Text=if layout.nextTier then "TIER "..layout.nextTier.name.." AT "..layout.nextTier.need else "EVERY TIER OPEN"
	self.tierFill.Size=UDim2.new(layout.progress,0,1,0)
	local n=#layout.branches
	local colW=math.floor((GRID_W-GUTTER-12-(n-1)*12)/n)
	local function colX(b) return GUTTER+(b-1)*(colW+12) end
	local function add(item) table.insert(self.drawn,item);return item end
	-- (step 2) the kit's card
	local top=self:drawCard(Panel.kitCard(self.kitId))
	-- Branch headers.
	for b,branch in layout.branches do
		add(K.text(self.grid,branch.name,UDim2.fromOffset(colX(b),top),UDim2.fromOffset(colW,24),20,self.M.ink,K.TITLE_FONT,Enum.TextXAlignment.Center))
	end
	local y=top+34
	self:drawRows(layout,n,colX,y)
end

-- The tiers as rows, the branches as columns, and the lines between nodes.
function Panel:drawRows(layout,n,colX,y)
	local K=self.kit
	local function add(item) table.insert(self.drawn,item);return item end
	local at={}
	for _,row in layout.tiers do
		local tallest=0
		for b=1,n do tallest=math.max(tallest,#row.cells[b]) end
		local height=math.max(1,tallest)*(TILE_H+TILE_GAP)+10
		add(K.frame(self.grid,UDim2.fromOffset(0,y-6),UDim2.fromOffset(GRID_W-12,2),self.M.ink,0))
		local label=add(K.text(self.grid,row.name,UDim2.fromOffset(0,y),UDim2.fromOffset(GUTTER-8,40),40,if row.open then self.M.red else self.M.off,K.TITLE_FONT))
		label.TextYAlignment=Enum.TextYAlignment.Top
		local unit=if self.tab=="ninja" then "POINTS " else "MASTERY "
		add(K.text(self.grid,if row.need==0 then "FROM THE START" elseif row.open then unit..row.need.." • OPEN" else unit..row.need,
			UDim2.fromOffset(0,y+42),UDim2.fromOffset(GUTTER-8,30),12,if row.open then self.M.brown else self.M.off,K.STRONG_FONT or K.BODY_FONT))
		for b=1,n do
			for k,node in row.cells[b] do
				local ty=y+(k-1)*(TILE_H+TILE_GAP)
				at[node.id]={x=colX(b),y=ty,col=b}
				self:tile(node,colX(b),ty,colW)
			end
		end
		y+=height
	end
	-- The line from a node to the one it opens, in the same branch.
	for _,branch in layout.branches do
		for _,node in branch.nodes do
			for _,need in node.requires or {} do
				local from,to=at[need],at[node.id]
				if from and to and from.col==to.col and to.y>from.y then
					local line=add(K.frame(self.grid,UDim2.fromOffset(from.x+12,from.y+TILE_H),UDim2.fromOffset(3,to.y-from.y-TILE_H),
						if node.status=="active" or node.status=="off" then self.M.ink else self.M.off,0))
					line.ZIndex=76
				end
			end
		end
	end
	self.grid.CanvasSize=UDim2.fromOffset(GRID_W-12,y+10)
	if not self.selected then
		for _,row in layout.tiers do for b=1,n do for _,node in row.cells[b] do
			if not self.selected and node.status=="learn" then self.selected=node.id end
		end end end
		self.selected=self.selected or (layout.branches[1] and layout.branches[1].nodes[1] and layout.branches[1].nodes[1].id)
	end
	self:detail()
end

-- (step 2) The kit's card over the grid; returns where the grid starts.
function Panel:drawCard(c)
	if not c then return 0 end
	local K,M=self.kit,self.M
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local card=K.frame(self.grid,UDim2.fromOffset(0,0),UDim2.fromOffset(GRID_W-12,CARD_H-10),M.paper,0)
	table.insert(self.drawn,card);K.corner(card,4);self.ring(card,3)
	card.Name="KitCard"
	-- four columns: what he starts with, what the tree adds, its top (the
	-- transformation), his signature (the CM's « why this kit »)
	local cols={
		{"STARTS WITH",table.concat(c.starts,"  •  "),nil},
		{"THE TREE ADDS",table.concat(c.adds,"  •  "),nil},
		{"AT THE TOP",c.transform or "",c.topLine},
		{"SIGNATURE",nil,c.signature},
	}
	local w=math.floor((GRID_W-12-24)/4)
	for i,col in cols do
		local x=12+(i-1)*w
		K.text(card,col[1],UDim2.fromOffset(x,8),UDim2.fromOffset(w-12,16),13,M.red,STRONG)
		local y=26
		if col[2] then
			local body=K.text(card,if col[2]=="" then "—" else col[2],UDim2.fromOffset(x,y),UDim2.fromOffset(w-14,if col[3] then 22 else 80),16,M.ink,STRONG)
			body.TextYAlignment=Enum.TextYAlignment.Top;body.TextWrapped=true
			y+=24
		end
		if col[3] then
			local line=K.text(card,col[3],UDim2.fromOffset(x,y),UDim2.fromOffset(w-14,CARD_H-10-y-6),13,M.mid,K.BODY_FONT)
			line.TextYAlignment=Enum.TextYAlignment.Top;line.TextWrapped=true
		end
	end
	return CARD_H
end

-- (step 2) The NINJA tab: the header, the five natures, the other branches.
function Panel:ninjaView() return self.kits and self.kits.ninja end
function Panel:drawNinja()
	local K,M=self.kit,self.M
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local view=self:ninjaView()
	local layout=Panel.ninjaLayout(view)
	self.title.Text="YOUR NINJA'S TREE"
	self.subtitle.Text=string.format("%d POINTS FREE  •  %d EARNED  •  1 POINT PER %d MASTERY, EVERY KIT TOGETHER",layout.free or 0,layout.points or 0,NinjaTree.PointEvery)
	self.free.Text=tostring(layout.free or 0)
	self.earned.Text="FREE / "..(layout.points or 0).." POINTS"
	self.tierLabel.Text="NINJA POINTS "..(layout.points or 0)
	self.tierNext.Text=if layout.nextTier then "TIER "..layout.nextTier.name.." AT "..layout.nextTier.need else "EVERY TIER OPEN"
	self.tierFill.Size=UDim2.new(layout.progress,0,1,0)
	local function add(item) table.insert(self.drawn,item);return item end
	-- The natures: one card each, in the element's colour; the chosen one inked.
	add(K.text(self.grid,"CHAKRA NATURE  •  ONE AT A TIME",UDim2.fromOffset(0,0),UDim2.fromOffset(GRID_W-12,24),20,M.ink,K.TITLE_FONT))
	local cw=math.floor((GRID_W-12-4*12)/5)
	for i,node in layout.natures do
		local rgb=Panel.NATURE_COLOR[node.nature] or {200,200,200}
		local color=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		local ink=if Panel.NATURE_DARK[node.nature] then M.cream else M.ink
		local chosen=node.status=="active"
		local card=K.create("TextButton",self.grid,{Text="",Position=UDim2.fromOffset((i-1)*(cw+12),30),Size=UDim2.fromOffset(cw,NATURE_H-40),
			BackgroundColor3=color,BackgroundTransparency=if node.status=="locked" or node.status=="tier" or node.status=="short" then .45 else 0,BorderSizePixel=0,AutoButtonColor=true,ZIndex=77})
		add(card);K.corner(card,4)
		K.create("UIStroke",card,{Color=M.ink,Thickness=if chosen then 5 else 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		card.Name="Nature"..node.nature
		K.text(card,string.upper(node.nature),UDim2.fromOffset(10,6),UDim2.new(1,-20,0,34),30,ink,K.TITLE_FONT).ZIndex=78
		local line=K.text(card,node.shows or "",UDim2.fromOffset(10,40),UDim2.new(1,-20,0,32),12,ink,K.BODY_FONT)
		line.TextWrapped=true;line.TextYAlignment=Enum.TextYAlignment.Top;line.ZIndex=78
		local tag=if chosen then "YOUR NATURE" elseif node.status=="off" then "LEARNED • CHOOSE" elseif node.status=="learn" then "LEARN • "..node.cost elseif node.status=="short" then node.cost.." POINTS" else "LOCKED"
		local band=K.frame(card,UDim2.new(0,0,1,-22),UDim2.new(1,0,0,22),if chosen then M.ink else M.paper,0);band.ZIndex=78
		K.text(band,tag,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),13,if chosen then M.cream else M.ink,STRONG,Enum.TextXAlignment.Center).ZIndex=79
		card.Activated:Connect(function() self.selected=node.id;self:detail() end)
		self.tiles[node.id]=card
	end
	local n=#layout.branches
	local colW=math.floor((GRID_W-GUTTER-12-(n-1)*12)/n)
	local function colX(b) return GUTTER+(b-1)*(colW+12) end
	for b,branch in layout.branches do
		add(K.text(self.grid,branch.name,UDim2.fromOffset(colX(b),NATURE_H),UDim2.fromOffset(colW,24),20,M.ink,K.TITLE_FONT,Enum.TextXAlignment.Center))
	end
	if not self.selected and not layout.nature then
		for _,node in layout.natures do if not self.selected and (node.status=="learn" or node.status=="off") then self.selected=node.id end end
	end
	self:drawRows(layout,n,colX,NATURE_H+34)
end

function Panel:tile(node,x,y,w)
	local K,P=self.kit,self.P
	local style=STYLE[node.status] or STYLE.locked
	local M=self.M
	local tile=K.create("TextButton",self.grid,{Text="",Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,TILE_H),BackgroundColor3=M[style.bg] or M.paper,
		BackgroundTransparency=style.alpha,BorderSizePixel=0,AutoButtonColor=true,ZIndex=77})
	table.insert(self.drawn,tile)
	K.corner(tile,3)
	if style.stroke or node.item then
		-- a kit object (the gourd, the weights) wears a red ring
		K.create("UIStroke",tile,{Color=if node.item then M.red else (M[style.stroke] or M.ink),Thickness=if node.item then 3 else 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	end
	local color=M[style.text] or M.ink
	-- (step 2) its pictogram: the technique it unlocks, its object, its element
	local def=if self.tab=="ninja" then {id=node.id} else (TreeView.node(self.kitId,node.id) or {})
	local icon=Panel.icon(def)
	local left=10
	if icon then
		K.create("ImageLabel",tile,{Image=icon,Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(TILE_H-8,TILE_H-8),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ZIndex=78})
		left=TILE_H
	end
	local name=K.text(tile,string.upper(node.name),UDim2.fromOffset(left,3),UDim2.new(1,-44-left,0,20),if node.major then 18 else 14,color,if node.major then K.TITLE_FONT else (K.STRONG_FONT or K.BODY_FONT))
	name.TextTruncate=Enum.TextTruncate.AtEnd;name.TextWrapped=false;name.ZIndex=78
	local sub=if node.item then "KIT OBJECT" elseif node.status=="tier" then "TIER "..(if node.tier==2 then "II" else "III").." CLOSED"
		elseif node.status=="locked" then "WAITS FOR A NODE" elseif node.status=="learn" then "TO LEARN" else node.kindLabel
	if self.tab=="ninja" and node.status=="locked" and node.why then sub=string.upper(node.why) end
	local tag=K.text(tile,sub,UDim2.fromOffset(left,22),UDim2.new(1,-44-left,0,14),11,color,K.BODY_FONT)
	tag.TextTransparency=.15;tag.ZIndex=78
	local right=K.text(tile,style.tag or tostring(node.cost),UDim2.new(1,-46,0,0),UDim2.fromOffset(40,TILE_H),18,color,K.STRONG_FONT or K.TITLE_FONT,Enum.TextXAlignment.Center)
	right.ZIndex=78
	tile.Activated:Connect(function() self.selected=node.id;self:detail() end)
	self.tiles[node.id]=tile
end

function Panel:detail()
	local ninja=self.tab=="ninja"
	local d=self.selected and (if ninja then Panel.ninjaDetail(self:ninjaView() or NinjaTree.view(nil,0),self.selected) else TreeView.detail(self.kitId,self:state(),self.selected))
	-- (step 2) the technique it unlocks, big
	local node=if not ninja and self.selected then TreeView.node(self.kitId,self.selected) else nil
	self.unlock.Visible=node~=nil and node.Unlock~=nil
	if self.unlock.Visible then
		self.unlockName.Text=if node.Unlock=="Awakening" then string.upper(node.Name) else techName(Fighters[self.kitId],node.Unlock)
		self.unlockIcon.Image=Panel.icon(node) or ""
	end
	for id,tile in self.tiles do
		local mark=tile:FindFirstChild("Picked")
		if id==self.selected and not mark then
			local m=self.kit.create("UIStroke",tile,{Color=self.M.red,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
			m.Name="Picked"
		elseif id~=self.selected and mark then mark:Destroy() end
	end
	if not d then self.kicker.Text="";self.head.Text="";self.shows.Text="";self.counter.Text="";self.note.Text="";self.action.Visible=false;return end
	local pieces={}
	for piece in string.gmatch(d.head,"[^•]+") do table.insert(pieces,(string.gsub(piece,"^%s*(.-)%s*$","%1"))) end
	self.head.Text=pieces[1] or ""
	table.remove(pieces,1)
	self.kicker.Text=table.concat(pieces,"  •  ")
	self.shows.Text=d.shows
	self.counter.Text=d.counter
	-- What this node opens next in the tree.
	local opens={}
	for _,other in (if ninja then NinjaTree.Nodes else TreeView.tree(self.kitId)) do
		for _,need in other.Requires or {} do if need==self.selected then table.insert(opens,string.upper(other.Name)) end end
	end
	local note=d.note or ""
	if #opens>0 then note=(if note~="" then note.."\n" else "").."OPENS NEXT: "..table.concat(opens,", ") end
	self.note.Text=note
	self.pending=d.action
	self.action.Visible=d.action~=nil
	if d.action then
		self.action.Text=d.action.label
		-- (DA v3) learn in red, turn on in ink, turn off on paper ringed in ink
		self.action.BackgroundColor3=if d.action.kind=="learn" then self.M.red elseif d.action.kind=="on" then self.M.ink else self.M.paper
		self.action.TextColor3=if d.action.kind=="learn" or d.action.kind=="on" then self.M.cream else self.M.ink
		self.actionRing.Enabled=d.action.kind~="learn" and d.action.kind~="on"
	end
end

function Panel:press()
	local act=self.pending
	if not act or not self.kitId or not self.selected then return end
	if self.tab=="ninja" then
		if act.kind=="learn" then self.send("NinjaLearn",{node=self.selected})
		else self.send("NinjaSet",{node=self.selected,on=act.kind=="on"}) end
		return
	end
	if act.kind=="learn" then self.send("LearnNode",{player=self.kitId,node=self.selected})
	else self.send("SetNode",{player=self.kitId,node=self.selected,on=act.kind=="on"}) end
end

return Panel
