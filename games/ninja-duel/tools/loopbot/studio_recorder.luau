-- The loop's recorder in Studio (OUTILLEUR, 19/11, plan § 4 OUTILLEUR 3): run
-- in the playtest CLIENT (robloxstudio-mcp eval_client_runtime, or the client
-- command bar) right after the player appears at the gate, then play the
-- journey with real inputs (keys, clicks, taps). It notes, with the time since
-- it started: every input (a `*` = taken by a screen), the phase, the first
-- minute's stage and prompt, the kit chosen, the notices, each time the
-- partner loses health, and the distance walked.
--   shared.NDLoop.dump()   the record, one line per event
--   shared.NDLoop.stop()   disconnects it
-- The time an AI driver takes between two inputs is its own, not a player's:
-- read the game's part (the gap between an input and what it caused).
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
if shared.NDLoop and shared.NDLoop.stop then shared.NDLoop.stop() end
local rec={t0=os.clock(),events={},walk=0,conns={}}
shared.NDLoop=rec
local function now() return math.floor((os.clock()-rec.t0)*100)/100 end
local function note(kind,data) table.insert(rec.events,{t=now(),k=kind,d=data}) end
local last={}
local remote=RS:WaitForChild("NinjaDuel"):WaitForChild("Action")
table.insert(rec.conns,remote.OnClientEvent:Connect(function(data)
	if type(data)~="table" then return end
	if data.phase~=last.phase then note("phase",tostring(data.phase));last.phase=data.phase end
	if data.first~=last.first then note("first",tostring(data.first));last.first=data.first end
	local tid=data.tutorial and data.tutorial.id
	if tid~=last.tid then note("prompt",tostring(tid));last.tid=tid end
	if data.kits and data.kits.selected~=last.kit then note("kit",tostring(data.kits.selected));last.kit=data.kits.selected end
	if data.notice and data.notice~=last.notice then note("notice",tostring(data.notice)) end
	last.notice=data.notice
	local b=data.bot
	if b and b.health and last.bh and b.health<last.bh then note("bothp",b.health) end
	last.bh=b and b.health
end))
table.insert(rec.conns,UIS.InputBegan:Connect(function(input,gp)
	local name=input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode.Name or input.UserInputType.Name
	if name~="MouseMovement" then note("in",name..(if gp then "*" else "")) end
end))
local lastPos=nil
table.insert(rec.conns,RunService.Heartbeat:Connect(function()
	local c=Players.LocalPlayer.Character
	local r=c and c:FindFirstChild("HumanoidRootPart")
	if r then
		local p=Vector3.new(r.Position.X,0,r.Position.Z)
		if lastPos then local d=(p-lastPos).Magnitude;if d<8 then rec.walk+=d end end
		lastPos=p
	end
end))
function rec.stop() for _,c in rec.conns do c:Disconnect() end end
function rec.dump()
	local out={}
	for _,e in rec.events do table.insert(out,string.format("%.2f %s %s",e.t,e.k,tostring(e.d))) end
	return table.concat(out,"\n").."\nwalk "..math.floor(rec.walk)
end
-- The buttons on screen and their size (the plan asks 44 px at least on a phone).
function rec.buttons()
	local out={}
	for _,o in Players.LocalPlayer.PlayerGui:GetDescendants() do
		if o:IsA("GuiButton") and o.Visible and o.AbsoluteSize.X>0 then
			local shown=true
			local q=o.Parent
			while q and q:IsA("GuiObject") do if not q.Visible then shown=false;break end;q=q.Parent end
			local sg=o:FindFirstAncestorWhichIsA("LayerCollector")
			if shown and sg and sg.Enabled and sg:IsA("ScreenGui") then
				local s=o.AbsoluteSize
				local label=if o:IsA("TextButton") and o.Text~="" then o.Text else o.Name
				table.insert(out,string.format("%s %dx%d%s",label,s.X,s.Y,if s.X<44 or s.Y<44 then "  <44" else ""))
			end
		end
	end
	return out
end
return "recording"
