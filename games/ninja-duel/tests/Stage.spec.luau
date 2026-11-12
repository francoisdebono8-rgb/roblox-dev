-- The lane's stadium between duels (Server/Stage, QA test of b822ee5 12/11:
-- « gel à chaque début de duel », 0.9 s frozen then 1 s of stutter at BEGIN,
-- 6 out of 6). Every start rebuilt the whole stadium (some two thousand
-- parts and meshes) and every client received it in the same frame as the
-- two bodies. Checked here on a small fake instance tree: a duel's damage is
-- undone and only what changed is written; a missing piece asks for a
-- rebuild; the first stadium arrives a few pieces a frame, floor first, with
-- Building set until the last one; the real Matches builds a lane's stadium
-- once (on the roster) and keeps it through rematches, the roster and the
-- cup. It proves the logic, NOT Studio's replication or the frame times
-- (to measure in Studio, micro-profiler at BEGIN).
local H=require("./Harness")
local V,C=H.V,H.C
local Color3=H.roblox.Color3

-- A small instance tree: Parent kept in a registry, children computed.
local all={}
local Fake={}
Fake.__index=Fake
local function fake(class,name,parent)
	local o=setmetatable({ClassName=class,Name=name or class,attrs={},destroyed=false},Fake)
	rawset(o,"_parent",nil)
	table.insert(all,o)
	if parent then o.Parent=parent end
	return o
end
Fake.__index=function(t,k)
	if k=="Parent" then return rawget(t,"_parent") end
	return Fake[k]
end
Fake.__newindex=function(t,k,v)
	if k=="Parent" then rawset(t,"_parent",v);return end
	rawset(t,k,v)
end
function Fake:IsA(class) return class==self.ClassName or (class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart")) end
function Fake:GetChildren()
	local out={}
	for _,o in all do if not o.destroyed and rawget(o,"_parent")==self then table.insert(out,o) end end
	return out
end
function Fake:GetDescendants()
	local out={}
	local function walk(node) for _,c in node:GetChildren() do table.insert(out,c);walk(c) end end
	walk(self)
	return out
end
function Fake:FindFirstChild(name) for _,c in self:GetChildren() do if c.Name==name then return c end end return nil end
function Fake:Destroy() self.destroyed=true;self.Parent=nil;for _,c in self:GetChildren() do c:Destroy() end end
function Fake:ClearAllChildren() for _,c in self:GetChildren() do c:Destroy() end end
function Fake:FindFirstChildOfClass(class) for _,c in self:GetChildren() do if c:IsA(class) then return c end end return nil end
function Fake:GetFullName() return self.Name end
function Fake:GetAttribute(k) return self.attrs[k] end
function Fake:SetAttribute(k,v) self.attrs[k]=v end
local function part(class,name,parent,position,color)
	local p=fake(class,name,parent)
	p.Size=V.new(2,2,2);p.CFrame=C.new(position or V.zero);p.Color=color or Color3.fromRGB(200,200,200)
	p.Transparency=0;p.CanCollide=true;p.Material=H.roblox.Enum.Material.SmoothPlastic
	return p
end
-- A stadium: the floor, wall panels, a breakable trunk carrying its tree mesh,
-- and decor (meshes, spectator models).
local function stadium(parent)
	local yard=fake("Folder","Courtyard",parent)
	local decor=fake("Folder","Decor",yard)
	part("Part","Training floor",yard,V.new(0,-1,0))
	for k=1,6 do part("Part","Boundary",yard,V.new(k*10,20,0)) end
	local trunk=part("Part","Field tree",yard,V.new(30,7,30))
	trunk.Size=V.new(2,14,2);trunk:SetAttribute("WorldBreakable",true)
	part("MeshPart","Tree_Crown",trunk,V.new(30,16,30))
	for k=1,30 do part("MeshPart","Bush_Leaves",decor,V.new(k,0,140)) end
	for k=1,20 do
		local m=fake("Model","SpectatorFigure",decor)
		part("Part","Spectator",m);part("Part","SpectatorHead",m)
	end
	return yard,trunk
end

local Stage=H.load("Server/Stage")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end

test("a duel's damage is undone and only what changed is written",function()
	local lane=fake("Folder","Duel_1")
	local yard,trunk=stadium(lane)
	local record=Stage.remember(yard)
	local panel=yard:FindFirstChild("Boundary")
	local colour,size,cf=panel.Color,trunk.Size,trunk.CFrame
	local crown=trunk:FindFirstChild("Tree_Crown");local crownCF=crown.CFrame
	-- WorldReaction: a cracked panel, a felled trunk (cut to a stump, its crown tipped over).
	panel.Color=Color3.new(0,0,0);panel:SetAttribute("WorldState","Cracked");panel:SetAttribute("WorldIntegrity",.3)
	trunk.Size=V.new(2,1.2,2);trunk.CFrame=C.new(30,.6,30);trunk:SetAttribute("WorldState","Broken")
	crown.CFrame=C.new(40,1,30);crown.CanCollide=false
	local log=part("Part","Fallen Field tree",trunk,V.new(35,1,30))
	local whole,changed=Stage.restore(record)
	assert(whole,"the stadium lost a piece it still has")
	assert(changed==4,"restore wrote "..changed.." instances, want 4 (panel, trunk, crown, the stray log)")
	assert(panel.Color==colour and panel:GetAttribute("WorldState")==nil and panel:GetAttribute("WorldIntegrity")==nil,"the cracked panel stayed cracked")
	assert(trunk.Size==size and trunk.CFrame==cf and trunk:GetAttribute("WorldState")==nil,"the felled trunk stayed a stump")
	assert(crown.CFrame==crownCF and crown.CanCollide==true,"the tree's crown stayed on the ground")
	assert(log.destroyed and log.Parent==nil,"the duel's fallen log stayed in the stadium")
	assert(trunk:GetAttribute("WorldBreakable")==true,"the trunk's own attribute was cleared")
	-- Nothing broke this time: nothing is written (nothing replicates).
	local again,none=Stage.restore(record)
	assert(again and none==0,"an untouched stadium wrote "..none.." instances")
end)

test("a stadium that lost a piece asks to be rebuilt",function()
	local yard=stadium(fake("Folder","Duel_2"))
	local record=Stage.remember(yard)
	yard:FindFirstChild("Decor"):FindFirstChild("Bush_Leaves"):Destroy()
	assert(not Stage.restore(record),"a stadium with a destroyed piece was called whole")
	local gone=stadium(nil)
	local goneRecord=Stage.remember(gone)
	assert(not Stage.restore(goneRecord),"a stadium out of the world was called whole")
end)

-- The reveal runs its frames at once here: task.spawn runs, task.wait counts.
local frames=0
H.envBase.task={spawn=function(fn,...) fn(...) end,defer=function() end,delay=function() end,wait=function() frames+=1;return 0 end}

test("the first stadium arrives a few pieces a frame, the floor first",function()
	local lane=fake("Folder","Duel_3")
	local holder=fake("Folder","Holder")
	local yard=stadium(holder)
	local total=#yard:GetDescendants()
	local seenFloorFirst,maxStep,doneCount=nil,0,0
	local saved=Stage.PER_FRAME
	Stage.PER_FRAME=12
	local before=0
	local origStep=Stage.step
	Stage.step=function(y,budget)
		if seenFloorFirst==nil then
			seenFloorFirst=y:FindFirstChild("Training floor")~=nil and y:GetAttribute("Building")==true and #y:GetDescendants()<=3
		end
		local done=origStep(y,budget)
		local now=#y:GetDescendants()
		maxStep=math.max(maxStep,now-before);before=now
		return done
	end
	frames=0
	Stage.reveal(yard,lane,function() doneCount+=1 end)
	Stage.step=origStep;Stage.PER_FRAME=saved
	assert(seenFloorFirst,"the stadium did not start from its floor (Building set, nothing else)")
	assert(yard.Parent==lane and #yard:GetDescendants()==total,"the stadium is not whole after its reveal")
	assert(yard:GetAttribute("Building")==nil and doneCount==1,"Building stays set or done ran "..doneCount.." times")
	assert(frames>=5,"the stadium arrived in "..frames.." frames")
	assert(maxStep<=12+3,"one frame brought "..maxStep.." instances (budget 12)")
end)

test("a duel that starts during the reveal gets the rest at once",function()
	local lane=fake("Folder","Duel_4")
	local yard=stadium(fake("Folder","Holder"))
	local total=#yard:GetDescendants()
	local spawnSaved=H.envBase.task.spawn
	H.envBase.task.spawn=function() end -- the reveal's frames have not run yet
	Stage.reveal(yard,lane,nil)
	H.envBase.task.spawn=spawnSaved
	assert(Stage.building(yard) and yard:GetAttribute("Building")==true)
	assert(Stage.finish(yard) and #yard:GetDescendants()==total and yard:GetAttribute("Building")==nil,"finish left the stadium half built")
end)

-- The real Matches: a lane builds its stadium once and keeps it.
local clock=3000
H.workspace.GetServerTimeNow=function() return clock end
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	if class=="Folder" then return fake("Folder","Folder") end
	return baseNew(class)
end}
local World=H.load("Server/World")
local builds=0
World.arena=function(parent) builds+=1;return (stadium(parent)) end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local ArenaMeshes=H.load("Server/ArenaMeshes")
local Matches=H.load("Server/Matches")
local remote={FireClient=function() end}

test("a lane builds its stadium on the roster and keeps it through every duel",function()
	ArenaMeshes.state="idle"
	local m=Matches.new(remote)
	local player={UserId=77,Name="P77",DisplayName="P77",Parent=H.Players}
	m:selection(player)
	local s=m.sessions[player]
	assert(builds==1 and s.stage and s.stage.Parent==s.folder and s.stageRecord,"the roster did not build the lane's stadium ahead")
	local stage=s.stage
	assert(m:start(player,"Lion","Sand"),"the duel did not start")
	assert(builds==1 and s.stage==stage,"the first duel rebuilt the stadium")
	local effects=s.effects
	-- A cracked panel in this duel, a rematch: the same stadium, mended; the
	-- last duel's effects folder gone.
	local panel=stage:FindFirstChild("Boundary");local colour=panel.Color
	panel.Color=Color3.new(0,0,0)
	assert(m:start(player,"Lion","Sand"))
	assert(builds==1 and s.stage==stage and panel.Color==colour,"the rematch rebuilt the stadium or kept its crack")
	assert(effects.destroyed and s.effects~=effects and s.effects.Parent==s.folder,"the last duel's effects stayed")
	-- Back on the roster: the stadium stays, nothing else of the duel.
	m:selection(player)
	assert(builds==1 and stage.Parent==s.folder and not stage.destroyed,"the roster took the stadium away")
	for _,child in s.folder:GetChildren() do assert(child==stage,"the roster kept "..child.Name) end
	assert(m:start(player,"Sand","Lion") and builds==1,"a new duel after the roster rebuilt the stadium")
	-- A stadium that lost a piece is rebuilt.
	stage:FindFirstChild("Decor"):FindFirstChild("Bush_Leaves"):Destroy()
	assert(m:start(player,"Lion","Sand") and builds==2 and s.stage~=stage and stage.destroyed,"a broken stadium was reused")
	-- Built with the part decor before the meshes came in: rebuilt once they are.
	ArenaMeshes.state="ready"
	local partBuilt=s.stage
	assert(m:start(player,"Lion","Sand") and builds==3 and partBuilt.destroyed,"the part-built stadium stayed after the meshes came in")
	assert(m:start(player,"Lion","Sand") and builds==3,"the dressed stadium was rebuilt")
	ArenaMeshes.state="idle"
	-- The player leaves: the lane and its stadium go.
	local folder=s.folder
	m:remove(player)
	assert(folder.destroyed and s.stage==nil,"the lane outlived its player")
end)

print(string.format("NinjaDuel stage (the lane's stadium, QA 12/11): %d PASS",passed))
