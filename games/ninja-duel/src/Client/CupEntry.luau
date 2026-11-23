-- The tournament's entry (DESIGN, step 4, DEC-048; Server/Tournament): he
-- enters with his kit and a build of the cup's budget (100 points), the
-- whole tree open. A page of the manga: the kit's name, the budget as a red
-- bar, the tree's nodes as chips by branch (ink when taken), and three
-- buttons: CLEAR, BEST BUILD (the server's own build: its default) and ENTER.
-- A chip whose node needs another says so; a chip over the budget is greyed.
-- The server judges (Tournament.admit); this page only proposes.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local TreeView=require(Shared.TreeView)
local KitTexts=require(Shared.KitTexts)
local Text=require(Shared.Text)

local E={}
E.__index=E
E.BUDGET=100
E.W,E.H=1060,680

-- ------------------------------------------------------------------ pure
local function byId(kit)
	local out={}
	for _,n in TreeView.tree(kit) do out[n.Id]=n end
	return out
end
-- What a build spends.
function E.spent(kit,nodes)
	local all,sum=byId(kit),0
	for _,id in nodes or {} do sum+=(all[id] and all[id].Cost or 0) end
	return sum
end
-- Can this node be added? (nil, or why not in words)
function E.why(kit,nodes,id,budget)
	local all=byId(kit)
	local node=all[id]
	if not node then return "NOT IN THIS TREE" end
	local have={}
	for _,n in nodes do have[n]=true end
	for _,need in node.Requires or {} do
		if not have[need] then return "NEEDS "..Text.upper(all[need] and all[need].Name or need) end
	end
	if E.spent(kit,nodes)+node.Cost>(budget or E.BUDGET) then return "OVER THE BUDGET" end
	return nil
end
-- Take or drop a node; dropping drops what needs it.
function E.toggle(kit,nodes,id,budget)
	local i=table.find(nodes,id)
	if i then
		table.remove(nodes,i)
		local all=byId(kit)
		local changed=true
		while changed do
			changed=false
			for j=#nodes,1,-1 do
				local n=all[nodes[j]]
				for _,need in (n and n.Requires) or {} do
					if not table.find(nodes,need) then table.remove(nodes,j);changed=true;break end
				end
			end
		end
		return true
	end
	if E.why(kit,nodes,id,budget) then return false end
	table.insert(nodes,id)
	return true
end
-- His own build (the tree's active nodes), cut to the budget in its order.
function E.fromState(kit,state,budget)
	local nodes={}
	for _,id in (state and state.active) or {} do
		if not E.why(kit,nodes,id,budget) then table.insert(nodes,id) end
	end
	return nodes
end

-- ------------------------------------------------------------------ page
function E.new(kit,gui,send)
	local self=setmetatable({kit=kit,send=send,drawn={},nodes={},budget=E.BUDGET},E)
	local M=kit.MANGA
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=78;self.root.Visible=false;self.root.Active=true;self.root.Name="CupEntry"
	local card=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(E.W,E.H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=79
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local scale=kit.create("UIScale",card,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=kit.fitScale(Vector2.new(v.X,v.Y-58),E.W+24,E.H+24,1.1)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	local function z(o,d) o.ZIndex=80+(d or 0);return o end
	z(kit.text(card,"TOURNAMENT ENTRY",UDim2.fromOffset(28,10),UDim2.fromOffset(640,64),58,M.ink,kit.TITLE_FONT))
	z(kit.frame(card,UDim2.fromOffset(28,70),UDim2.fromOffset(240,6),M.red,0))
	self.who=z(kit.text(card,"",UDim2.fromOffset(28,82),UDim2.fromOffset(700,24),18,M.brown or M.ink,STRONG))
	self.close=z(kit.button(card,"X",UDim2.fromOffset(E.W-88,14),UDim2.fromOffset(68,68),function() self:hide() end,M.ink),2)
	self.close.TextColor3=M.cream;self.close.TextSize=34
	-- the budget
	local track=z(kit.frame(card,UDim2.fromOffset(28,116),UDim2.fromOffset(E.W-56,30),M.back or M.paper,0))
	kit.create("UIStroke",track,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.fill=z(kit.frame(track,UDim2.fromOffset(0,0),UDim2.new(0,0,1,0),M.red,0),1)
	self.spentText=z(kit.text(track,"",UDim2.fromOffset(10,0),UDim2.new(1,-20,1,0),18,M.ink,STRONG),2)
	self.body=z(kit.frame(card,UDim2.fromOffset(28,160),UDim2.fromOffset(E.W-56,E.H-260),M.paper,1))
	self.note=z(kit.text(card,"",UDim2.fromOffset(28,E.H-92),UDim2.fromOffset(E.W-56,24),16,M.red,STRONG))
	self.clear=z(kit.button(card,"CLEAR",UDim2.fromOffset(28,E.H-64),UDim2.fromOffset(180,52),function() table.clear(self.nodes);self:draw() end,M.paper),1)
	self.clear.TextColor3=M.ink;self.clear.TextSize=24
	kit.create("UIStroke",self.clear,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.best=z(kit.button(card,"BEST BUILD",UDim2.fromOffset(220,E.H-64),UDim2.fromOffset(240,52),function() self:enter(nil) end,M.paper),1)
	self.best.TextColor3=M.ink;self.best.TextSize=24
	kit.create("UIStroke",self.best,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.go=z(kit.button(card,"ENTER",UDim2.fromOffset(E.W-28-300,E.H-64),UDim2.fromOffset(300,52),function() self:enter(self.nodes) end,M.red),1)
	self.go.TextColor3=M.cream;self.go.TextSize=30
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			if input.KeyCode==Enum.KeyCode.ButtonB or (input.KeyCode==Enum.KeyCode.Escape and not processed) then self:hide() end
		end)
	end)
	return self
end

function E:shown() return self.root.Visible end
function E:hide() self.root.Visible=false end
function E:show(fighter,state)
	self.fighter=fighter
	self.nodes=E.fromState(fighter,state,self.budget)
	self.who.Text=Text.upper(KitTexts.name(fighter)).."  •  THE WHOLE TREE IS OPEN  •  "..self.budget.." POINTS TO SPEND"
	self.root.Visible=true
	self:draw()
end
function E:enter(nodes)
	self.send("CupStart",{player=self.fighter,nodes=if nodes then table.clone(nodes) else nil})
	self:hide()
end

function E:draw()
	local kit,M=self.kit,self.M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	for _,d in self.drawn do d:Destroy() end
	table.clear(self.drawn)
	local layout=TreeView.layout(self.fighter,nil)
	local spent=E.spent(self.fighter,self.nodes)
	self.fill.Size=UDim2.new(math.clamp(spent/self.budget,0,1),0,1,0)
	self.spentText.Text=string.format("%d / %d POINTS  •  %d NODES",spent,self.budget,#self.nodes)
	self.chips={}
	if not layout then return end
	local n=#layout.branches
	local colW=math.floor((E.W-56-(n-1)*12)/n)
	for b,branch in layout.branches do
		local x=(b-1)*(colW+12)
		local head=kit.text(self.body,branch.name,UDim2.fromOffset(x,0),UDim2.fromOffset(colW,24),20,M.ink,kit.TITLE_FONT,Enum.TextXAlignment.Center)
		head.ZIndex=81;table.insert(self.drawn,head)
		for i,node in branch.nodes do
			local taken=table.find(self.nodes,node.id)~=nil
			local why=if taken then nil else E.why(self.fighter,self.nodes,node.id,self.budget)
			local chip=kit.button(self.body,"",UDim2.fromOffset(x,30+(i-1)*46),UDim2.fromOffset(colW,40),function()
				if E.toggle(self.fighter,self.nodes,node.id,self.budget) then self.note.Text="" else self.note.Text=E.why(self.fighter,self.nodes,node.id,self.budget) or "" end
				self:draw()
			end,if taken then M.ink else M.paper)
			chip.ZIndex=82;table.insert(self.drawn,chip)
			kit.create("UIStroke",chip,{Color=if node.major then M.red else M.ink,Thickness=if node.major then 3 else 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
			chip.BackgroundTransparency=if why and not taken then .45 else 0
			local ink=if taken then M.cream else M.ink
			local name=kit.text(chip,Text.upper(node.name),UDim2.fromOffset(8,0),UDim2.new(1,-50,1,0),15,ink,STRONG)
			name.ZIndex=83;name.TextScaled=true
			kit.create("UITextSizeConstraint",name,{MaxTextSize=15,MinTextSize=9})
			kit.text(chip,tostring(node.cost),UDim2.new(1,-40,0,0),UDim2.fromOffset(32,40),20,if taken then M.cream else M.red,kit.TITLE_FONT,Enum.TextXAlignment.Right).ZIndex=83
			self.chips[node.id]=chip
		end
	end
end

return E
