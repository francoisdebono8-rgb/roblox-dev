-- The effect lights, kept to a budget (OUTILLEUR, F7 tool, 08/11).
--
-- In a Sasuke-Minato AI duel the F7 tool counted 17 to 19 effect lights lit at
-- once (fire, chakra, awakenings): a cost on every machine and a washed-out
-- image. Every module that lights an effect keeps doing it its own way; this
-- layer watches the lights that appear under the duel's effects and bodies,
-- keeps the MAX that matter most lit (bright, wide, near the camera) and
-- switches the others off until a place frees up. It never lets an effect
-- light cast a shadow. Decor lights (the courtyard, the menu stage) are not
-- touched.
--
-- It owns the lights' Enabled: a module that wants a light out sets its
-- Brightness to 0 (a light at 0 does not take a place).
local RunService=game:GetService("RunService")

local LightBudgetFX={}
LightBudgetFX.MAX=8
LightBudgetFX.PERIOD=.1
LightBudgetFX.enabled=true

-- Where effect lights live; and what is decor inside those places.
local ROOTS={"NinjaDuelFX","NinjaDuels","NinjaDuelBodies"}
local DECOR={Courtyard=true,NinjaDuelMenuStage=true,NinjaDuelArenaDress=true}

local function isEffectLight(light)
	if not light:IsA("Light") then return false end
	local node=light.Parent
	local underRoot=false
	while node and node~=workspace do
		if DECOR[node.Name] then return false end
		if node.Parent==workspace and table.find(ROOTS,node.Name) then underRoot=true end
		node=node.Parent
	end
	return underRoot
end
LightBudgetFX.isEffectLight=isEffectLight

-- Pure: which of these lights stay lit. `lights` are {light=, brightness=,
-- range=, distance=}; returns a set of the kept `light` values.
function LightBudgetFX.choose(lights,max)
	local lit={}
	for _,l in lights do if l.brightness>.01 and l.range>.1 then table.insert(lit,l) end end
	for _,l in lit do l.score=l.brightness*l.range/(1+(l.distance or 0)/30) end
	table.sort(lit,function(a,b) return a.score>b.score end)
	local keep={}
	for i=1,math.min(max,#lit) do keep[lit[i].light]=true end
	return keep
end

local tracked=setmetatable({},{__mode="k"}) -- every effect light seen
local off=setmetatable({},{__mode="k"})     -- the ones this layer switched off
LightBudgetFX.tracked=tracked
LightBudgetFX.off=off

local function track(light)
	if tracked[light] then return end
	if not isEffectLight(light) then return end
	tracked[light]=true
	light.Shadows=false
end
LightBudgetFX.track=track

function LightBudgetFX.step(cameraPosition)
	local list={}
	for light in tracked do
		if light.Parent==nil then tracked[light]=nil;off[light]=nil
		elseif light.Enabled or off[light] then
			light.Shadows=false
			local position
			local parent=light.Parent
			if parent:IsA("Attachment") then position=parent.WorldPosition
			elseif parent:IsA("BasePart") then position=parent.Position end
			table.insert(list,{light=light,brightness=light.Brightness,range=(light::any).Range or 8,
				distance=if position and cameraPosition then (position-cameraPosition).Magnitude else 0})
		end
	end
	local keep=LightBudgetFX.choose(list,LightBudgetFX.MAX)
	local lit=0
	for _,l in list do
		local light=l.light
		if keep[light] then
			if off[light] then off[light]=nil;light.Enabled=true end
			lit+=1
		elseif light.Enabled and l.brightness>.01 then
			off[light]=true;light.Enabled=false
		end
	end
	return lit
end

local started=false
local function start()
	for _,root in ROOTS do
		local folder=workspace:FindFirstChild(root)
		if folder then for _,d in folder:GetDescendants() do if d:IsA("Light") then track(d) end end end
	end
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("Light") then task.defer(track,d) end -- (its parent chain is set by then)
	end)
	local wait=0
	RunService.Heartbeat:Connect(function(dt)
		if not LightBudgetFX.enabled then return end
		wait-=dt
		if wait>0 then return end
		wait=LightBudgetFX.PERIOD
		local camera=workspace.CurrentCamera
		LightBudgetFX.step(camera and camera.CFrame.Position)
	end)
end
function LightBudgetFX.start()
	if started then return end
	started=true
	-- (headless specs load Effects without a real workspace: nothing to watch)
	local ok,err=pcall(start)
	if not ok and RunService:IsStudio() then warn("[LightBudgetFX] "..tostring(err)) end
end
return LightBudgetFX
