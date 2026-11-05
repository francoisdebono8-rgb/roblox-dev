-- Mission FEEL (issue #44), pass A: client-side recorder, installed in Play
-- through Studio's execute_luau (Client). Nothing here ships in a build.
-- _G.FEEL = {inputs, snaps, cam, marks}: server-clock times relative to t0,
-- so the timeline lines up with the server flight log and with OBS footage
-- (t0 is a Unix time: video time = t0 + t - recording start).
--   inputs  every key/button begin and end (mouse movement excluded)
--   snaps   one entry per snapshot packet (~30 Hz): states, cues, heights
--   cam     one entry per rendered frame: dt, FOV, and whether each fighter
--           is on screen (0 off, 1 near the edge, 2 well inside)
--   marks   scene labels pushed by the tool driving the take
-- Buffers stop growing at their cap (no O(n) removal on every frame).
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local P=game:GetService("Players").LocalPlayer
if _G.FEEL and _G.FEEL.conns then for _,c in _G.FEEL.conns do c:Disconnect() end end
local F={inputs={},snaps={},cam={},marks={},conns={},t0=workspace:GetServerTimeNow()}
_G.FEEL=F
local function now() return workspace:GetServerTimeNow()-F.t0 end
local function push(l,x,max) if #l<max then table.insert(l,x) end end
function F.mark(label) table.insert(F.marks,{t=now(),label=label}) end
local remote=RS:WaitForChild("NinjaDuel"):WaitForChild("Action")
table.insert(F.conns,remote.OnClientEvent:Connect(function(d)
	if type(d)~="table" then return end
	F.epoch=d.epoch or F.epoch
	if not d.human then return end
	local h,b=d.human,d.bot
	push(F.snaps,{t=now(),phase=d.phase,hs=h.state,ha=h.attackName,hv=h.attackVariant,hr=h.reaction,cue=h.cue,
		bs=b and b.state,ba=b and b.attackName,br=b and b.reaction,hp=h.health,bhp=b and b.health,
		hy=h.position and h.position.Y,by=b and b.position and b.position.Y,
		hx=h.position and h.position.X,hz=h.position and h.position.Z,bx=b and b.position and b.position.X,bz=b and b.position and b.position.Z,
		air=h.airborne,wall=h.wall,combo=h.combo},20000)
end))
local function name(i)
	if i.KeyCode~=Enum.KeyCode.Unknown then return i.KeyCode.Name end
	return i.UserInputType.Name
end
table.insert(F.conns,UIS.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseMovement then return end
	push(F.inputs,{t=now(),k="+"..name(i)},5000)
end))
table.insert(F.conns,UIS.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseMovement then return end
	push(F.inputs,{t=now(),k="-"..name(i)},5000)
end))
local function fighters()
	local duels=workspace:FindFirstChild("NinjaDuels")
	local duel=duels and duels:FindFirstChildWhichIsA("Folder")
	if not duel then return nil,nil end
	local me,foe=duel:FindFirstChild("PlayerFighter"),duel:FindFirstChild("AIFighter")
	return me and me:FindFirstChild("HumanoidRootPart"),foe and foe:FindFirstChild("HumanoidRootPart")
end
table.insert(F.conns,Run.RenderStepped:Connect(function(dt)
	local cam=workspace.CurrentCamera
	local me,foe=fighters()
	local vp=cam.ViewportSize
	local function onScreen(part)
		if not part then return -1 end
		local p,vis=cam:WorldToViewportPoint(part.Position)
		if not vis then return 0 end
		if p.X<0 or p.Y<0 or p.X>vp.X or p.Y>vp.Y then return 0 end
		if p.X<vp.X*.05 or p.Y<vp.Y*.05 or p.X>vp.X*.95 or p.Y>vp.Y*.95 then return 1 end
		return 2
	end
	push(F.cam,{t=now(),dt=dt,me=onScreen(me),foe=onScreen(foe),fov=cam.FieldOfView,
		dist=me and (cam.CFrame.Position-me.Position).Magnitude or nil},60000)
end))
return "recording"
