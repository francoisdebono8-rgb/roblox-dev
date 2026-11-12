-- Server Authority trial, client side: the same simulation (predicted), a
-- fixed camera (W = -Z), and a probe that times each input to the first frame
-- the body visibly answers it. Read by Studio MCP:
--   _G.SATrialProbe.report()  -> {dodges={ms...}, moves={ms...}, mode=...}
--   _G.SATrialProbe.press(name, seconds)   presses an action (InputAction:Fire)
--   _G.SATrialProbe.predict(on)            prediction on / off for this body
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local SATrial=require(ReplicatedStorage:WaitForChild("SATrial"))
SATrial.Initialize()

local player=Players.LocalPlayer
local ctx=player:WaitForChild(SATrial.ContextName)
local camera=workspace.CurrentCamera

local probe={dodges={},moves={},mode="default",log={}}
local pendingDodge,pendingMove=nil,nil
ctx.Dodge.Pressed:Connect(function() pendingDodge=os.clock() end)
ctx.Move.StateChanged:Connect(function(value)
	if typeof(value)=="Vector2" and value.Magnitude>.2 and not pendingMove then pendingMove=os.clock() end
end)

RunService.RenderStepped:Connect(function()
	local char=player.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,14,20),root.Position)
	local v=root.AssemblyLinearVelocity
	local speed=Vector3.new(v.X,0,v.Z).Magnitude
	-- What the player sees: the first rendered frame where the body answers.
	if pendingDodge and speed>40 then
		table.insert(probe.dodges,math.floor((os.clock()-pendingDodge)*1000+.5));pendingDodge=nil
	end
	if pendingMove and speed>3 then
		table.insert(probe.moves,math.floor((os.clock()-pendingMove)*1000+.5));pendingMove=nil
	end
end)

function probe.report()
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local status=nil
	pcall(function() status=tostring(RunService:GetPredictionStatus(root)) end)
	return {dodges=probe.dodges,moves=probe.moves,mode=probe.mode,prediction=status,
		authority=tostring(workspace.AuthorityMode),dodgesCounted=root and root:GetAttribute("Dodges")}
end
function probe.reset() probe.dodges={};probe.moves={} end
-- A press the way the keyboard would make it (the action's own state).
function probe.press(name,seconds,value)
	local action=ctx:FindFirstChild(name)
	if not action then return "no action "..tostring(name) end
	action:Fire(if value~=nil then value else true)
	task.delay(seconds or .1,function() action:Fire(if action.Type==Enum.InputActionType.Bool then false else Vector2.zero) end)
	return "ok"
end
-- The A/B: this body predicted or not (Enum.PredictionMode items are listed
-- in the result, the API is young).
function probe.predict(on)
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local items={}
	for _,item in Enum.PredictionMode:GetEnumItems() do table.insert(items,item.Name) end
	local wanted=nil
	for _,item in Enum.PredictionMode:GetEnumItems() do
		if on and (item.Name=="On" or item.Name=="AlwaysPredict" or item.Name=="Always") then wanted=item end
		if not on and (item.Name=="Off" or item.Name=="NeverPredict" or item.Name=="Never") then wanted=item end
	end
	if not wanted then return {error="no matching PredictionMode",items=items} end
	local ok,err=pcall(function() RunService:SetPredictionMode(player.Character,wanted) end)
	probe.mode=wanted.Name
	return {ok=ok,err=err,set=wanted.Name,items=items,root=root~=nil}
end
_G.SATrialProbe=probe
print("[SATrial] client ready")
