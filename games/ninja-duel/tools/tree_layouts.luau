-- (DESIGN 27/11) Dumps every painted tree's layout (Client/TreePanel.treeLayout,
-- the very points the seals sit on) for assets/ui/generate_tree.py.
-- Run from games/ninja-duel: lune run tools/tree_layouts.luau
local H=require("../tests/Harness")
local Tree=H.load("Client/TreePanel")
local TV=H.load("Shared/TreeView")
local Trees=H.load("Shared/SkillTrees")
local NT=H.load("Shared/NinjaTree")
local serde=require("@lune/serde")
local fs=require("@lune/fs")
local out={}
local function dump(key,layout,starts)
	local L=Tree.treeLayout(layout,1024,0,if starts>0 then Tree.TREE.ROOTS else 60)
	local nodes={}
	for id,p in L.at do
		table.insert(nodes,{id=id,x=p.x,y=p.y,crown=p.crown==true,major=p.node.major==true,fx=p.from and p.from.x,fy=p.from and p.from.y,b=p.b})
	end
	local bands={}
	for t,b in L.bands do bands[t]={top=b.top,bottom=b.bottom} end
	local boughs={}
	for b,pts in L.boughs do boughs[tostring(b)]=pts end
	out[key]={height=L.height,ground=L.ground,trunkX=L.trunkX,crownY=L.crownY,nodes=nodes,boughs=boughs,bands=bands,starts=starts}
end
for kit in Trees do
	local layout=TV.layout(kit,{unlocked={},active={},points=0,free=0,mastery=0})
	local card=Tree.kitCard(kit)
	if layout then dump(kit,layout,#((card and card.starts) or {})) end
end
dump("Ninja",Tree.ninjaLayout(NT.view(NT.new(),0)),0)
fs.writeFile("assets/ui/tree_layouts.json",serde.encode("json",out,true))
print("tree layouts written")
