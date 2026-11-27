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
Panel.CLOSE={X=W-156,Y=22,W=132,H=58}
local CARD_H=124 -- the kit's card, over the KIT tab's grid
local NATURE_H=132 -- the natures, over the NINJA tab's grid
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
	self.legend=text(card,"INK: YOURS  •  RED RING: ON  •  RED DOT: YOU CAN LEARN IT  •  GREY: NOT YET  •  POINT AT A SEAL TO READ IT",
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
	self.enteredFor=nil -- (27/11) reopened, the tree rises again
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
	self.drawn={};self.tiles={};self.scales={}
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
	-- (step 2) the kit's card
	local top=self:drawCard(Panel.kitCard(self.kitId))
	self:drawTree(layout,top,Panel.kitCard(self.kitId))
end

-- ------------------------------------------------------------------ the tree
-- (DESIGN 27/11, third pass. François: « l'arbre est devenu brouillon, va
-- chercher des menus de compétences sur internet ».) Looked at: Ghost of
-- Tsushima's Techniques (small groups of small round seals on a quiet ink
-- page, a title and one line over each group, the picked one told in a
-- fixed panel, never over the tree), Sekiro's skill trees (each tree read
-- left to right, the root at the left, right-angled lines to what a skill
-- opens) and Roblox's Jujutsu Infinite (one look per branch, the locked
-- ones with a padlock). What they share and ours lacked: a quiet page, one
-- group per branch, small seals all alike, thin straight lines, no words
-- on the tree but the branch's name, and nothing that moves unless he acts.
-- So: one group per branch on the paper (three a row), its tiers I, II, III
-- read left to right, its seals in columns, a line where a seal needs
-- another; the name, the effect and the price go to the panel on the right,
-- shown on hover and on a pick.
Panel.TREE={COLS=3,GAP=26,HEAD=72,STEP=60,SEAL=40,BIG=50,PADX=44,BOTTOM=22}
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
-- Where everything sits (pure): a group per branch, three a row, all the
-- groups of a row as tall as its fullest; in a group, a column per tier, its
-- seals stacked and centred; the lines between a seal and the one it needs.
function Panel.treeLayout(layout,width,top)
	local T=Panel.TREE
	local n=#layout.branches
	local cols=math.max(1,math.min(T.COLS,n))
	local w=(width-(cols-1)*T.GAP)/cols
	local tiers=#layout.tiers
	local groups,at,links={},{},{}
	local y=top
	local b=1
	while b<=n do
		local most=1
		for k=b,math.min(n,b+cols-1) do
			for t=1,tiers do most=math.max(most,#(layout.tiers[t].cells[k] or {})) end
		end
		local h=T.HEAD+most*T.STEP+T.BOTTOM
		for k=b,math.min(n,b+cols-1) do
			local x=((k-b)%cols)*(w+T.GAP)
			local g={b=k,x=x,y=y,w=w,h=h,name=layout.branches[k].name,count=#layout.branches[k].nodes,mine=0,columns={}}
			local step=if tiers>1 then (w-2*T.PADX)/(tiers-1) else 0
			for t=1,tiers do
				local cx=x+T.PADX+(t-1)*step
				local cells=layout.tiers[t].cells[k] or {}
				g.columns[t]={x=cx,open=layout.tiers[t].open,name=layout.tiers[t].name,need=layout.tiers[t].need}
				local body=y+T.HEAD+(most*T.STEP)/2
				for i,node in cells do
					local ny=body+(i-(#cells+1)/2)*T.STEP
					at[node.id]={x=cx,y=ny,b=k,t=t,node=node,big=node.major or node.transform}
					if node.status=="active" or node.status=="off" then g.mine+=1 end
				end
			end
			groups[k]=g
		end
		y+=h+T.GAP
		b+=cols
	end
	for id,p in at do
		for _,need in p.node.requires or {} do
			local q=at[need]
			if q and q.b==p.b then table.insert(links,{from=need,to=id}) end
		end
	end
	return {groups=groups,at=at,links=links,height=y-top-T.GAP,top=top}
end
-- A tween that cannot break a draw (TweenService missing in the tests).
function Panel.tween(object,time,goal,style,repeats,reverses,delay)
	pcall(function()
		local TS=game:GetService("TweenService")
		TS:Create(object,TweenInfo.new(time,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out,repeats or 0,reverses or false,delay or 0),goal):Play()
	end)
end
local function bar(self,x,y,w,h,color,alpha,z)
	local f=self.kit.frame(self.grid,UDim2.fromOffset(x,y),UDim2.fromOffset(w,h),color,alpha or 0)
	f.BorderSizePixel=0;f.ZIndex=z or 77
	table.insert(self.drawn,f)
	return f
end
function Panel:drawTree(layout,top,card)
	local K,M=self.kit,self.M
	local T=Panel.TREE
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local width=GRID_W-12
	local L=Panel.treeLayout(layout,width,top)
	local function add(item) table.insert(self.drawn,item);return item end
	self.groupFrames={}
	for _,g in L.groups do
		-- the group: its name in the brush, a red stroke, one line
		local name=add(K.text(self.grid,g.name,UDim2.fromOffset(g.x,g.y),UDim2.fromOffset(g.w,30),26,M.ink,K.TITLE_FONT))
		name.ZIndex=78
		local stroke=bar(self,g.x+1,g.y+30,64,4,M.red,0,78);K.corner(stroke,2)
		local line=add(K.text(self.grid,string.format("%d SKILLS  •  %d YOURS",g.count,g.mine),UDim2.fromOffset(g.x,g.y+36),UDim2.fromOffset(g.w,16),12,M.brown,STRONG))
		line.ZIndex=78
		table.insert(self.groupFrames,{name,stroke,line})
		-- the tiers: a numeral over each column, a closed one says its price
		for t,col in g.columns do
			local label=if col.open then col.name else col.name.."  "..tostring(col.need)
			local numeral=add(K.text(self.grid,label,UDim2.fromOffset(col.x-40,g.y+T.HEAD-16),UDim2.fromOffset(80,14),11,if col.open then M.off else M.red,STRONG,Enum.TextXAlignment.Center))
			numeral.ZIndex=78
			if t>1 then
				-- a hairline between the columns, as on the page of a scroll
				local px=(g.columns[t-1].x+col.x)/2
				bar(self,px,g.y+T.HEAD+4,1,g.h-T.HEAD-T.BOTTOM,M.ink,.9,76)
			end
		end
	end
	-- the lines: out of the seal it needs, a right angle, into the seal
	for _,link in L.links do
		local a,b=L.at[link.from],L.at[link.to]
		local lit=a.node.status=="active" or a.node.status=="off"
		local color=if lit then M.ink else M.off
		local mid=(a.x+b.x)/2
		local thick=if lit then 3 else 2
		bar(self,math.min(a.x,mid),a.y-thick/2,math.abs(mid-a.x),thick,color,0,77)
		bar(self,mid-thick/2,math.min(a.y,b.y)-thick/2,thick,math.abs(b.y-a.y)+thick,color,0,77)
		bar(self,math.min(mid,b.x),b.y-thick/2,math.abs(b.x-mid),thick,color,0,77)
	end
	for id,p in L.at do
		local def=if self.tab=="ninja" then nil else TreeView.node(self.kitId,id)
		self:seal(p.node,p.x,p.y,def,p.big)
	end
	self.grid.CanvasSize=UDim2.fromOffset(GRID_W-12,top+L.height+16)
	local key=tostring(self.kitId)..tostring(self.tab)
	if self.scrolledFor~=key then
		self.scrolledFor=key
		pcall(function() self.grid.CanvasPosition=Vector2.new(0,0) end)
	end
	if not self.selected then
		for _,p in L.at do if not self.selected and p.node.status=="learn" then self.selected=p.node.id end end
		self.selected=self.selected or (layout.branches[1] and layout.branches[1].nodes[1] and layout.branches[1].nodes[1].id)
	end
	self:animateTree(L)
	self:detail()
	return L
end
-- A node as a small round seal, all alike: ink when his (a red ring when
-- on), paper ringed in ink with a red dot when he can learn it, faded when
-- out of reach; its pictogram inside; nothing written around it.
function Panel:seal(node,x,y,def,big)
	local K,M=self.kit,self.M
	local T=Panel.TREE
	local r=(if big then T.BIG else T.SEAL)/2
	local st=node.status
	local mine=st=="active" or st=="off"
	local faded=st=="locked" or st=="tier" or st=="short"
	local b=K.create("TextButton",self.grid,{Text="",Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(r*2,r*2),AnchorPoint=Vector2.new(.5,.5),
		BackgroundColor3=if mine then M.ink else M.paper,BackgroundTransparency=0,BorderSizePixel=0,AutoButtonColor=false,ZIndex=80})
	b.Name="Seal_"..tostring(node.id)
	table.insert(self.drawn,b);K.corner(b,r)
	K.create("UIStroke",b,{Color=if st=="active" then M.red elseif mine then M.ink elseif st=="learn" then M.ink else M.off,
		Thickness=if st=="active" then 3 else 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local icon=Panel.sealIcon(node,def)
	if icon and icon~="" then
		K.create("ImageLabel",b,{Image=icon,Size=UDim2.fromScale(.58,.58),Position=UDim2.fromScale(.21,.21),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,
			ImageColor3=if mine then M.cream else M.ink,ImageTransparency=if faded then .6 else 0,ZIndex=81})
	else
		K.text(b,string.sub(Text.upper(node.name),1,1),UDim2.fromScale(0,0),UDim2.fromScale(1,1),r,if mine then M.cream else M.ink,K.TITLE_FONT,Enum.TextXAlignment.Center).ZIndex=81
	end
	if st=="learn" then
		local dot=K.frame(b,UDim2.new(1,-6,0,-2),UDim2.fromOffset(12,12),M.red,0);dot.ZIndex=82;K.corner(dot,6)
		K.create("UIStroke",dot,{Color=M.paper,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	end
	if self.selected==node.id then
		local sel=K.frame(b,UDim2.fromScale(.5,.5),UDim2.new(1,12,1,12),M.ink,1);sel.AnchorPoint=Vector2.new(.5,.5);sel.ZIndex=79;K.corner(sel,r+6)
		K.create("UIStroke",sel,{Color=M.red,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	end
	local scale=K.create("UIScale",b,{Scale=1})
	-- under the pointer: it grows a little and the panel tells it
	pcall(function()
		b.MouseEnter:Connect(function() Panel.tween(scale,.1,{Scale=1.12});self:detail(node.id) end)
		b.MouseLeave:Connect(function() Panel.tween(scale,.1,{Scale=1});self:detail() end)
	end)
	b.Activated:Connect(function() self.pressed=node.id;self.selected=node.id;self:draw() end)
	self.tiles[node.id]=b
	self.scales[node.id]=scale
	return b
end
-- The movements, only when he acts: opened, the groups come up from the
-- paper one after the other; a seal pressed gives under the finger; a seal
-- just learned takes the ink with one ring.
function Panel:animateTree(L)
	local key=tostring(self.kitId)..tostring(self.tab)
	local status={}
	for id,p in L.at do status[id]=p.node.status end
	local before=if self.statusFor==key then self.lastStatus else nil
	self.statusFor=key;self.lastStatus=status
	if self.enteredFor~=key then
		self.enteredFor=key
		for id,p in L.at do
			local s=self.scales[id]
			if s then s.Scale=.6;Panel.tween(s,.22,{Scale=1},Enum.EasingStyle.Back,0,false,(p.b-1)*.05+(p.t-1)*.04) end
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
				local f=self.kit.frame(self.grid,UDim2.fromOffset(p.x,p.y),UDim2.fromOffset(44,44),self.M.red,1)
				f.AnchorPoint=Vector2.new(.5,.5);f.ZIndex=83;self.kit.corner(f,60);table.insert(self.drawn,f)
				local ring=self.kit.create("UIStroke",f,{Color=self.M.red,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
				Panel.tween(f,.5,{Size=UDim2.fromOffset(96,96)});Panel.tween(ring,.5,{Transparency=1})
			end
		end
	end
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
		K.text(card,Text.upper(node.nature),UDim2.fromOffset(10,6),UDim2.new(1,-20,0,34),30,ink,K.TITLE_FONT).ZIndex=78
		local line=K.text(card,node.shows or "",UDim2.fromOffset(10,40),UDim2.new(1,-20,0,32),12,ink,K.BODY_FONT)
		line.TextWrapped=true;line.TextYAlignment=Enum.TextYAlignment.Top;line.ZIndex=78
		local tag=if chosen then "YOUR NATURE" elseif node.status=="off" then "LEARNED • CHOOSE" elseif node.status=="learn" then "LEARN • "..node.cost elseif node.status=="short" then node.cost.." POINTS" else "LOCKED"
		local band=K.frame(card,UDim2.new(0,0,1,-22),UDim2.new(1,0,0,22),if chosen then M.ink else M.paper,0);band.ZIndex=78
		K.text(band,tag,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),13,if chosen then M.cream else M.ink,STRONG,Enum.TextXAlignment.Center).ZIndex=79
		card.Activated:Connect(function() self.selected=node.id;self:detail() end)
		self.tiles[node.id]=card
	end
	if not self.selected and not layout.nature then
		for _,node in layout.natures do if not self.selected and (node.status=="learn" or node.status=="off") then self.selected=node.id end end
	end
	self:drawTree(layout,NATURE_H+10,nil)
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
