-- The skill tree of a learned kit (DEC-038, user 13/11: « vraiment les arbres
-- de compétences, vraiment comment ça va marcher »). (DESIGN 27/11, fourth
-- pass) One branch at a time, as in Assassin's Creed Shadows: the branches
-- listed on the left (how far each one is), the picked one drawn as a tree
-- in the middle (tier I at the foot, III at the top, each seal named with
-- its state or price), the picked seal told on the right with its button.
-- The NINJA tab: the chakra natures first, then its three branches. The
-- server decides (Matches: LearnNode, SetNode); the panel draws
-- Shared/TreeView over the server's Progression view. Opened from the
-- roster (SKILL TREE), a master's card and the result.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
-- (26/11) capitals by Text.upper: string.upper follows the player's locale and broke « • » and « — »
local Text=require(Shared.Text)
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
-- (fourth pass) the branches' list on the left, the picked branch's tree beside it
local BAR_W=232
local BAR_X=GRID_X
local TREE_X=GRID_X+BAR_W+16
local TREE_W=GRID_X+GRID_W-TREE_X
Panel.CLOSE={X=W-156,Y=22,W=132,H=58}
Panel.TAB={W=170,H=48,Y=92,X=816}

-- ------------------------------------------------------------------ pure
local function techName(def,id)
	for _,t in def and def.Techniques or {} do if t.Id==id then return Text.upper(t.Name) end end
	return Text.upper(id)
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
			table.insert(adds,if node.Unlock=="Awakening" then Text.upper(node.Name) else techName(def,node.Unlock))
		elseif node.Item then table.insert(adds,Text.upper(node.Name)) end
		if node.Transform then transform=Text.upper(node.Name) end
	end
	local starts={}
	for _,t in def.Techniques or {} do if not unlocked[t.Id] then table.insert(starts,Text.upper(t.Name)) end end
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
		local item={id=node.id,name=node.name,cost=node.cost,kind=node.branch,kindLabel=Text.upper(node.branch),tier=node.tier,
			status=Panel.ninjaStatus(node),why=node.why,shows=node.shows,nature=node.nature,major=node.tier==3,requires=def and def.Requires}
		if node.nature then table.insert(out.natures,item)
		else
			local branch=byName[node.branch]
			if not branch then branch={name=Text.upper(node.branch),nodes={}};byName[node.branch]=branch;table.insert(out.branches,branch) end
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
			elseif status=="off" then action={kind="on",label=if node.nature then "CHOOSE "..Text.upper(node.nature) else "TURN ON"}
			elseif status=="active" and not node.nature then action={kind="off",label="TURN OFF"} end
			local answer=node.nature and NinjaTree.Infusion[node.nature] and NinjaTree.Infusion[node.nature].Answer
			local note=if node.why then Text.upper(node.why) else nil
			if status=="active" and node.nature then note="YOUR NATURE: YOUR INFUSED KUNAI AND BLADE CARRY IT. CHANGE IT BETWEEN DUELS." end
			return {id=id,head=node.name.."  •  "..node.cost.." POINTS  •  TIER "..NinjaTree.TierNames[node.tier].."  •  "..Text.upper(node.branch),
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
	local self=setmetatable({kit=kit,send=send,tiles={},drawn={},scales={}},Panel)
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
	-- (OUTILLEUR 27/11, robot humain) the page swallows clicks: none reach the screen behind
	self.root.Active=true
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
			if self.tab~=t.id then self.tab=t.id;self.selected=nil;self.branch=nil;self:draw() end
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
	-- The legend under the tree: the seals themselves, small, and what they mean.
	local legend=frame(card,UDim2.fromOffset(GRID_X,H-58),UDim2.fromOffset(GRID_W,22),M.back,1)
	self.legend=legend
	local samples={{fill=M.ink,stroke=M.ink,word="YOURS"},{fill=M.ink,stroke=M.red,word="ON"},{fill=M.paper,stroke=M.ink,dot=true,word="YOU CAN LEARN IT"},
		{fill=M.paper,stroke=M.off,word="NOT YET"}}
	local lx=0
	for _,s in samples do
		local c=frame(legend,UDim2.fromOffset(lx,2),UDim2.fromOffset(18,18),s.fill,0);corner(c,9)
		create("UIStroke",c,{Color=s.stroke,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		if s.dot then local d=frame(c,UDim2.new(1,-5,0,-3),UDim2.fromOffset(8,8),M.red,0);corner(d,4) end
		text(legend,s.word,UDim2.fromOffset(lx+26,2),UDim2.fromOffset(#s.word*9,18),14,M.mid,STRONG)
		lx+=26+#s.word*9+24
	end
	text(legend,"POINT AT A SEAL TO READ IT",UDim2.fromOffset(lx,2),UDim2.fromOffset(300,18),14,M.red,STRONG)
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
	self.enteredFor=nil -- (27/11) reopened, the tree rises again
	pcall(function()
		local GuiService=game:GetService("GuiService")
		local selected=GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.root) then GuiService.SelectedObject=nil end
	end)
end

function Panel:show(kitId,kits)
	if self.kitId~=kitId then self.selected=nil;self.branch=nil end
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
	self.drawn={};self.tiles={};self.scales={}
	-- (fourth pass) the tree beside the branches' list
	self.grid.Position=UDim2.fromOffset(TREE_X,GRID_Y);self.grid.Size=UDim2.fromOffset(TREE_W,GRID_H)
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
	self:drawKit(layout)
end

-- ------------------------------------------------------------------ the tree
-- (DESIGN 27/11, fourth pass. François: « on n'y comprend rien, repars de
-- l'arbre et adapte l'interface à ce que tu as vu, sois méticuleux ».)
-- What the menus of real games do, and what this page takes from each:
-- * Assassin's Creed Shadows (Masteries): ONE tree at a time, picked in a
--   list on the left that says how far each one is; the tiers are rows
--   numbered in the margin with what opens them; the nodes hang on one line,
--   each with its name; the last one, big, at the end of the line.
-- * Ghost of Tsushima (Techniques): a quiet page, the picked skill told in
--   a fixed panel (name, what it does, price, the button), never over the
--   tree; small round seals, all alike.
-- * Sekiro: a skill that needs another sits after it on the same line.
-- So: on the left the branches (name, learned out of all, a red dot when
-- one can be learned); in the middle the picked branch as a tree, its
-- trunk going up from tier I at the foot to tier III and the crown, each
-- seal on a twig, left and right of the trunk, its name and its price or
-- state written beside it; a closed tier under a veil that says what opens
-- it; on the right, the panel. The ink, the paper and the red of the shop.
Panel.TREE={BAR_W=BAR_W,ROW=78,PAD=56,OFF=190,SEAL=54,BIG=62,CROWN=150,FOOT=26,TRUNK=12}
Panel.TREE_W=TREE_W
local BARK=Color3.fromRGB(58,40,28)
local KIND_ICON={jutsu="scroll",property="weights",stat="fist",route="flash",airwall="wind",counter="palm",substitution="clone",awakening="fire",tool="kunai"}
local WORD_ICON={{"rasengan","spiral"},{"clone","clone"},{"kunai","kunai"},{"shuriken","shuriken"},{"chidori","bolt"},{"lightning","bolt"},
	{"sand","sand"},{"water","water"},{"fire","fire"},{"wind","wind"},{"eye","eye"},{"sharingan","eye"},{"byakugan","eye"},{"palm","palm"},
	{"wire","wire"},{"hound","hound"},{"dog","hound"},{"fist","fist"},{"lotus","fist"},{"mark","mark"},{"chakra","whirl"},{"tails","fire"}}
-- The pictogram of a node: its item's, else a word of its name, else its kind.
function Panel.sealIcon(node,def)
	if not UIAssets then return nil end
	local own=Panel.icon(def or {id=node.id})
	if own and own~="" then return own end
	local low=string.lower(node.name or "")
	for _,pair in WORD_ICON do
		if string.find(low,pair[1],1,true) then return UIAssets.id("icon_"..pair[2]) end
	end
	return UIAssets.id("icon_"..(KIND_ICON[node.kind or ""] or "scroll"))
end
-- What a seal says beside its name (pure): its state, or its price.
function Panel.sealState(node,tierNeed)
	local st=node.status
	if st=="active" then return "ON"
	elseif st=="off" then return "LEARNED  •  OFF"
	elseif st=="learn" then return "LEARN  •  "..tostring(node.cost).." PTS"
	elseif st=="short" then return tostring(node.cost).." PTS  •  NOT ENOUGH"
	elseif st=="tier" then return "TIER CLOSED"
	end
	return "NEEDS ANOTHER FIRST"
end
-- How far a branch is (pure): learned, all, how many he can learn now.
function Panel.branchCount(branch)
	local mine,can=0,0
	for _,node in branch.nodes do
		if node.status=="active" or node.status=="off" then mine+=1 end
		if node.status=="learn" then can+=1 end
	end
	return mine,#branch.nodes,can
end
-- One branch as a tree (pure). Tier I at the foot, III at the top, the
-- transformation (or the branch's big node of tier III) as the crown; in a
-- tier, the seals two by two, left and right of the trunk, upwards.
function Panel.branchLayout(layout,b,width,minHeight)
	local T=Panel.TREE
	local trunkX=width/2
	local crown=nil
	local bands={}
	local total=T.FOOT
	for t,row in layout.tiers do
		local cells={}
		for _,node in row.cells[b] or {} do
			if node.transform and not crown then crown=node else table.insert(cells,node) end
		end
		local rows=math.max(1,math.ceil(#cells/2))
		bands[t]={cells=cells,h=T.PAD+rows*T.ROW,open=row.open,name=row.name,need=row.need,index=t}
		total+=bands[t].h
	end
	total+=if crown then T.CROWN else 20
	local height=math.max(total,minHeight or 0)
	local at={}
	local y=height-T.FOOT
	for t,band in bands do
		band.bottom=y;band.top=y-band.h
		for i,node in band.cells do
			local row=math.ceil(i/2)
			local side=if i%2==1 then -1 else 1
			at[node.id]={x=trunkX+side*T.OFF,y=band.bottom-T.PAD*.5-(row-.5)*T.ROW+8,side=side,t=t,node=node}
		end
		y=band.top
	end
	local crownAt=nil
	if crown then
		crownAt={x=trunkX,y=y-T.CROWN+44,side=0,t=#bands,node=crown,crown=true}
		at[crown.id]=crownAt
	end
	return {at=at,bands=bands,trunkX=trunkX,height=height,top=if crown then crownAt.y else y,foot=height-T.FOOT,crown=crownAt}
end
-- A tween that cannot break a draw (TweenService missing in the tests).
function Panel.tween(object,time,goal,style,repeats,reverses,delay)
	pcall(function()
		local TS=game:GetService("TweenService")
		TS:Create(object,TweenInfo.new(time,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out,repeats or 0,reverses or false,delay or 0),goal):Play()
	end)
end
local function rect(self,parent,x,y,w,h,color,alpha,z)
	local f=self.kit.frame(parent,UDim2.fromOffset(x,y),UDim2.fromOffset(w,h),color,alpha or 0)
	f.BorderSizePixel=0;f.ZIndex=z or 77
	table.insert(self.drawn,f)
	return f
end
-- The branches on the left: one button each, how far it is, a red dot when
-- something can be learned in it. `extra`: a first entry (the natures).
function Panel:drawBranches(branches,extra)
	local K,M=self.kit,self.M
	local T=Panel.TREE
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local head=K.text(self.card,"BRANCHES",UDim2.fromOffset(BAR_X,GRID_Y-2),UDim2.fromOffset(T.BAR_W,18),14,M.red,STRONG)
	head.ZIndex=77;table.insert(self.drawn,head)
	local list={}
	if extra then table.insert(list,extra) end
	for b,branch in branches do
		local mine,all,can=Panel.branchCount(branch)
		table.insert(list,{key=b,name=branch.name,line=string.format("%d / %d LEARNED",mine,all),can=can,fill=if all>0 then mine/all else 0})
	end
	self.branchButtons={}
	for i,item in list do
		local y=GRID_Y+22+(i-1)*62
		local on=item.key==self.branch
		local b=K.create("TextButton",self.card,{Text="",Position=UDim2.fromOffset(BAR_X,y),Size=UDim2.fromOffset(T.BAR_W,54),
			BackgroundColor3=if on then M.ink else M.paper,BorderSizePixel=0,AutoButtonColor=false,ZIndex=77})
		b.Name="Branch_"..tostring(item.key)
		table.insert(self.drawn,b);K.corner(b,4)
		K.create("UIStroke",b,{Color=M.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local name=K.text(b,item.name,UDim2.fromOffset(12,4),UDim2.new(1,-40,0,28),24,if on then M.cream else M.ink,K.TITLE_FONT)
		name.ZIndex=78;name.TextScaled=true;K.create("UITextSizeConstraint",name,{MaxTextSize=24,MinTextSize=12})
		local line=K.text(b,item.line,UDim2.fromOffset(12,31),UDim2.new(1,-24,0,14),12,if on then M.cream else M.brown,STRONG)
		line.ZIndex=78
		if item.fill then
			local track=K.frame(b,UDim2.new(0,12,1,-7),UDim2.new(1,-24,0,3),if on then M.mid else M.back,0);track.ZIndex=78
			local fill=K.frame(track,UDim2.fromOffset(0,0),UDim2.fromScale(item.fill,1),M.red,0);fill.ZIndex=79
		end
		if (item.can or 0)>0 then
			local dot=K.frame(b,UDim2.new(1,-22,0,10),UDim2.fromOffset(12,12),M.red,0);dot.ZIndex=79;K.corner(dot,6)
		end
		b.Activated:Connect(function()
			if self.branch~=item.key then self.branch=item.key;self.selected=nil;self:draw() end
		end)
		pcall(function()
			b.MouseEnter:Connect(function() if self.branch~=item.key then b.BackgroundColor3=M.back end end)
			b.MouseLeave:Connect(function() if self.branch~=item.key then b.BackgroundColor3=M.paper end end)
		end)
		self.branchButtons[item.key]=b
	end
	return GRID_Y+22+#list*62
end
-- The kit in three lines under the branches: what it starts with, its crown.
function Panel:drawKitNote(card,y)
	if not card then return end
	local K,M=self.kit,self.M
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local T=Panel.TREE
	local h=GRID_Y+GRID_H-y-4
	if h<60 then return end
	local box=rect(self,self.card,BAR_X,y+6,T.BAR_W,h,M.paper,0,77);K.corner(box,4)
	K.create("UIStroke",box,{Color=M.off,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local t=K.text(box,"YOU START WITH",UDim2.fromOffset(10,8),UDim2.new(1,-20,0,14),12,M.red,STRONG);t.ZIndex=78
	local s=K.text(box,table.concat(card.starts,"\n"),UDim2.fromOffset(10,24),UDim2.new(1,-20,0,h-30),13,M.ink,STRONG)
	s.TextWrapped=true;s.TextYAlignment=Enum.TextYAlignment.Top;s.ZIndex=78
end
-- The picked branch as a tree.
function Panel:drawBranch(layout,b)
	local K,M=self.kit,self.M
	local T=Panel.TREE
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local L=Panel.branchLayout(layout,b,TREE_W-12,GRID_H)
	local g=self.grid
	-- the trunk, from the foot to the crown, a little wider at the foot
	local trunkTop=L.top
	local trunk=rect(self,g,L.trunkX-T.TRUNK/2,trunkTop,T.TRUNK,L.foot-trunkTop+10,BARK,0,76);K.corner(trunk,6)
	local foot=rect(self,g,L.trunkX-T.TRUNK,L.foot-30,T.TRUNK*2,40,BARK,0,76);K.corner(foot,8)
	local ground=rect(self,g,L.trunkX-130,L.foot+8,260,3,BARK,.3,76);K.corner(ground,2)
	-- the tiers: a rule and its numeral in the margin, what opens it
	for t,band in L.bands do
		local unit=if self.tab=="ninja" then "POINTS" else "MASTERY"
		local rule=rect(self,g,0,band.top,TREE_W-12,1,M.ink,.82,75)
		-- its name on the rule, at the left: TIER II • OPEN
		local word=if band.need==0 then "FROM THE START" elseif band.open then "OPEN" else unit.." "..tostring(band.need)
		local tag=K.text(g,"TIER "..band.name.."  •  "..word,UDim2.fromOffset(0,band.top+4),UDim2.fromOffset(260,18),14,if band.open then M.red else M.off,K.TITLE_FONT)
		tag.ZIndex=78;table.insert(self.drawn,tag)
		if not band.open then
			local veil=rect(self,g,0,band.top+1,TREE_W-12,band.h-1,M.back,.25,85)
			local lock=K.text(veil,string.format("OPENS AT %s %d",unit,band.need),UDim2.new(1,-356,0,3),UDim2.fromOffset(350,20),18,M.ink,K.TITLE_FONT,Enum.TextXAlignment.Right)
			lock.ZIndex=86
		end
	end
	-- the twigs and the seals
	for id,p in L.at do
		local def=if self.tab=="ninja" then nil else TreeView.node(self.kitId,id)
		if not p.crown then
			local x0=math.min(L.trunkX,p.x);local w=math.abs(p.x-L.trunkX)
			rect(self,g,x0,p.y-2,w,4,BARK,0,77)
		end
		self:seal(p,def)
	end
	g.CanvasSize=UDim2.fromOffset(TREE_W-12,L.height)
	local key=tostring(self.kitId)..tostring(self.tab)..tostring(b)
	if self.scrolledFor~=key then
		self.scrolledFor=key
		-- the tree is read from its foot: tier I first
		pcall(function() g.CanvasPosition=Vector2.new(0,math.max(0,L.height-GRID_H)) end)
	end
	if not self.selected then
		for _,band in L.bands do for _,node in band.cells do if not self.selected and node.status=="learn" then self.selected=node.id end end end
		if not self.selected then for _,band in L.bands do for _,node in band.cells do self.selected=self.selected or node.id end end end
		self.selected=self.selected or (L.crown and L.crown.node.id)
	end
	return L
end
-- A seal on its twig, its name and its state beside it.
function Panel:seal(p,def)
	local K,M=self.kit,self.M
	local T=Panel.TREE
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local node=p.node
	local r=(if p.crown or node.major then T.BIG else T.SEAL)/2
	local st=node.status
	local mine=st=="active" or st=="off"
	local faded=st=="locked" or st=="tier" or st=="short"
	local x,y=p.x,p.y
	local fill=if p.crown and not mine then M.red elseif mine then M.ink else M.paper
	-- (the crown out of reach stays red, but faded like any seal out of reach)
	local b=K.create("TextButton",self.grid,{Text="",Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(r*2,r*2),AnchorPoint=Vector2.new(.5,.5),
		BackgroundColor3=fill,BackgroundTransparency=if p.crown and faded then .55 else 0,BorderSizePixel=0,AutoButtonColor=false,ZIndex=80})
	b.Name="Seal_"..tostring(node.id)
	table.insert(self.drawn,b);K.corner(b,r)
	K.create("UIStroke",b,{Color=if st=="active" then M.red elseif mine or st=="learn" or p.crown then M.ink else M.off,
		Thickness=if st=="active" then 4 else 3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local icon=Panel.sealIcon(node,def)
	local light=mine or (p.crown and not mine)
	if icon and icon~="" then
		K.create("ImageLabel",b,{Image=icon,Size=UDim2.fromScale(.56,.56),Position=UDim2.fromScale(.22,.22),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,
			ImageColor3=if light then M.cream else M.ink,ImageTransparency=if faded then .55 else 0,ZIndex=81})
	end
	if st=="learn" then
		local dot=K.frame(b,UDim2.new(1,-8,0,-2),UDim2.fromOffset(14,14),M.red,0);dot.ZIndex=82;K.corner(dot,7)
		K.create("UIStroke",dot,{Color=M.paper,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	end
	if self.selected==node.id then
		local sel=K.frame(b,UDim2.fromScale(.5,.5),UDim2.new(1,14,1,14),M.ink,1);sel.AnchorPoint=Vector2.new(.5,.5);sel.ZIndex=79;K.corner(sel,r+7)
		K.create("UIStroke",sel,{Color=M.red,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	end
	-- its name and its state, outside the trunk (under the crown)
	local LW=T.OFF-r-24
	local nameX,align
	if p.crown then nameX,align=x-150,Enum.TextXAlignment.Center
	elseif p.side<0 then nameX,align=x-r-12-LW,Enum.TextXAlignment.Right
	else nameX,align=x+r+12,Enum.TextXAlignment.Left end
	local nameY=if p.crown then y+r+4 else y-20
	local nameW=if p.crown then 300 else LW
	if p.crown then
		-- the crown's words sit on a strip of the page, over the trunk
		local strip=K.frame(self.grid,UDim2.fromOffset(nameX-6,nameY-2),UDim2.fromOffset(nameW+12,40),M.back,0);strip.ZIndex=80;K.corner(strip,4)
		table.insert(self.drawn,strip)
	end
	local name=K.text(self.grid,(if p.crown then "THE CROWN  •  " else "")..Text.upper(node.name),UDim2.fromOffset(nameX,nameY),UDim2.fromOffset(nameW,20),16,if faded then M.off else M.ink,K.TITLE_FONT,align)
	name.ZIndex=81;name.TextScaled=true;K.create("UITextSizeConstraint",name,{MaxTextSize=17,MinTextSize=10});table.insert(self.drawn,name)
	local state=K.text(self.grid,Panel.sealState(node),UDim2.fromOffset(nameX,nameY+20),UDim2.fromOffset(nameW,16),12,
		if st=="learn" or st=="active" then M.red elseif faded then M.off else M.brown,STRONG,align)
	state.ZIndex=81;table.insert(self.drawn,state)
	-- under the pointer it grows a little and the panel tells it
	local scale=K.create("UIScale",b,{Scale=1})
	pcall(function()
		b.MouseEnter:Connect(function() Panel.tween(scale,.1,{Scale=1.1});self:detail(node.id) end)
		b.MouseLeave:Connect(function() Panel.tween(scale,.1,{Scale=1});self:detail() end)
	end)
	b.Activated:Connect(function() self.pressed=node.id;self.selected=node.id;self:draw() end)
	self.tiles[node.id]=b
	self.scales[node.id]=scale
	return b
end
-- Movements only when he acts: a branch opened, its seals come up from the
-- foot; a seal pressed gives under the finger; a seal just learned rings.
function Panel:animateTree(L,key)
	local status={}
	for id,p in L.at do status[id]=p.node.status end
	local before=if self.statusFor==key then self.lastStatus else nil
	self.statusFor=key;self.lastStatus=status
	if self.enteredFor~=key then
		self.enteredFor=key
		for id,p in L.at do
			local s=self.scales[id]
			if s then s.Scale=.5;Panel.tween(s,.22,{Scale=1},Enum.EasingStyle.Back,0,false,math.clamp((L.foot-p.y)/math.max(1,L.height),0,1)*.3) end
		end
	end
	local pressed=self.pressed;self.pressed=nil
	if pressed and self.scales[pressed] then
		local s=self.scales[pressed];s.Scale=.88;Panel.tween(s,.2,{Scale=1},Enum.EasingStyle.Back)
	end
	for id,st in status do
		local was=before and before[id]
		if was and was~=st and (st=="active" or st=="off") and was~="active" and was~="off" then
			local p=L.at[id]
			if p then
				local f=self.kit.frame(self.grid,UDim2.fromOffset(p.x,p.y),UDim2.fromOffset(60,60),self.M.red,1)
				f.AnchorPoint=Vector2.new(.5,.5);f.ZIndex=83;self.kit.corner(f,80);table.insert(self.drawn,f)
				local ring=self.kit.create("UIStroke",f,{Color=self.M.red,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
				Panel.tween(f,.5,{Size=UDim2.fromOffset(130,130)});Panel.tween(ring,.5,{Transparency=1})
			end
		end
	end
end
-- The kit's tab: the branches, the picked one as a tree, the kit's note.
function Panel:drawKit(layout)
	if self.branch==nil or type(self.branch)~="number" or not layout.branches[self.branch] then
		-- open on the first branch where something can be learned
		self.branch=1
		for b,branch in layout.branches do
			local _,_,can=Panel.branchCount(branch)
			if can>0 then self.branch=b;break end
		end
	end
	local bottom=self:drawBranches(layout.branches,nil)
	self:drawKitNote(Panel.kitCard(self.kitId),bottom)
	local L=self:drawBranch(layout,self.branch)
	self:animateTree(L,tostring(self.kitId).."kit"..tostring(self.branch))
	self:detail()
end
function Panel:ninjaView() return self.kits and self.kits.ninja end
-- The ninja's tab: the natures first, then his three branches.
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
	if self.branch~="nature" and not (type(self.branch)=="number" and layout.branches[self.branch]) then self.branch="nature" end
	local chosen=layout.nature
	local natureLine=if chosen then "YOURS: "..Text.upper(chosen) else "CHOOSE ONE"
	self:drawBranches(layout.branches,{key="nature",name="CHAKRA NATURE",line=natureLine,can=(function()
		for _,n in layout.natures do if n.status=="learn" then return 1 end end
		return 0
	end)()})
	if self.branch~="nature" then
		local L=self:drawBranch(layout,self.branch)
		self:animateTree(L,"ninja"..tostring(self.branch))
		self:detail()
		return
	end
	-- the natures: one card each, in the element's colour; the chosen one inked
	local function add(item) table.insert(self.drawn,item);return item end
	local g=self.grid
	add(K.text(g,"CHAKRA NATURE  •  ONE AT A TIME",UDim2.fromOffset(0,0),UDim2.fromOffset(TREE_W-12,26),24,M.ink,K.TITLE_FONT))
	add(K.text(g,"Your nature runs through your infused kunai and blade. Change it between duels.",UDim2.fromOffset(0,30),UDim2.fromOffset(TREE_W-12,18),14,M.brown,K.BODY_FONT))
	local cw=math.floor((TREE_W-12-12)/2)
	for i,node in layout.natures do
		local rgb=Panel.NATURE_COLOR[node.nature] or {200,200,200}
		local color=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		local ink=if Panel.NATURE_DARK[node.nature] then M.cream else M.ink
		local isChosen=node.status=="active"
		local col=(i-1)%2;local row=math.floor((i-1)/2)
		local card=K.create("TextButton",g,{Text="",Position=UDim2.fromOffset(col*(cw+12),62+row*112),Size=UDim2.fromOffset(cw,100),
			BackgroundColor3=color,BackgroundTransparency=if node.status=="locked" or node.status=="tier" or node.status=="short" then .45 else 0,BorderSizePixel=0,AutoButtonColor=true,ZIndex=77})
		add(card);K.corner(card,4)
		K.create("UIStroke",card,{Color=if self.selected==node.id then M.red else M.ink,Thickness=if isChosen or self.selected==node.id then 5 else 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		card.Name="Nature"..node.nature
		K.text(card,Text.upper(node.nature),UDim2.fromOffset(14,8),UDim2.new(1,-28,0,34),32,ink,K.TITLE_FONT).ZIndex=78
		local line=K.text(card,node.shows or "",UDim2.fromOffset(14,42),UDim2.new(1,-28,0,32),13,ink,K.BODY_FONT)
		line.TextWrapped=true;line.TextYAlignment=Enum.TextYAlignment.Top;line.ZIndex=78
		local tag=if isChosen then "YOUR NATURE" elseif node.status=="off" then "LEARNED  •  CHOOSE IT" elseif node.status=="learn" then "LEARN  •  "..node.cost.." PTS" elseif node.status=="short" then node.cost.." PTS" else "LOCKED"
		local band=K.frame(card,UDim2.new(0,0,1,-24),UDim2.new(1,0,0,24),if isChosen then M.ink else M.paper,0);band.ZIndex=78
		K.text(band,tag,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),13,if isChosen then M.cream else M.ink,STRONG,Enum.TextXAlignment.Center).ZIndex=79
		card.Activated:Connect(function() self.selected=node.id;self:draw() end)
		pcall(function()
			card.MouseEnter:Connect(function() self:detail(node.id) end)
			card.MouseLeave:Connect(function() self:detail() end)
		end)
		self.tiles[node.id]=card
	end
	g.CanvasSize=UDim2.fromOffset(TREE_W-12,62+math.ceil(#layout.natures/2)*112)
	pcall(function() g.CanvasPosition=Vector2.new(0,0) end)
	if not self.selected then
		for _,node in layout.natures do if not self.selected and (node.status=="learn" or node.status=="off") then self.selected=node.id end end
		self.selected=self.selected or (layout.natures[1] and layout.natures[1].id)
	end
	self:detail()
end

-- `shown`: a seal under the pointer (told, not picked); else the picked one.
function Panel:detail(shown)
	local ninja=self.tab=="ninja"
	local id=shown or self.selected
	local d=id and (if ninja then Panel.ninjaDetail(self:ninjaView() or NinjaTree.view(nil,0),id) else TreeView.detail(self.kitId,self:state(),id))
	-- (step 2) the technique it unlocks, big
	local node=if not ninja and id then TreeView.node(self.kitId,id) else nil
	self.unlock.Visible=node~=nil and node.Unlock~=nil
	if self.unlock.Visible then
		self.unlockName.Text=if node.Unlock=="Awakening" then Text.upper(node.Name) else techName(Fighters[self.kitId],node.Unlock)
		self.unlockIcon.Image=Panel.icon(node) or ""
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
		for _,need in other.Requires or {} do if need==id then table.insert(opens,Text.upper(other.Name)) end end
	end
	local note=d.note or ""
	if #opens>0 then note=(if note~="" then note.."\n" else "").."OPENS NEXT: "..table.concat(opens,", ") end
	self.note.Text=note
	-- the button acts on the picked seal: a seal only pointed at shows none
	if shown and shown~=self.selected then self.action.Visible=false;return end
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
