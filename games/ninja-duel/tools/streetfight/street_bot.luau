-- The street's blows, played by a robot (OUTILLEUR, passe commune 3, 26/11;
-- DEC-055: « son kit partout dans Konoha, et un coup sur un joueur lance le
-- duel sur place »). The DEV's own keys (Client/HubFightClient: the light
-- chain, the heavy blow, the dash, the guard) pressed as a player presses
-- them, from where a player would stand, the camera looking a little beside
-- the target: does the blow turn to it (Shared/HubFight.aim: 7 studs, 65°),
-- and what does it meet (the server's side: tools/streetfight/street_log).
--
-- A client module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py street            (eval_client_runtime)
-- then, in the same Play:
--   _G.NDStreetBot.stand(target, dist, side, turn)   his body `dist` studs from
--        `target` (Vector3), on the side `side` (degrees around it), turned
--        `turn` degrees away from it
--   _G.NDStreetBot.press(target, move, look)         the camera `look` degrees
--        beside the target, the key pressed: "Light", "Heavy", "Dodge"
--        (HubFightClient:press). Returns {move, live, dist, before, after}:
--        the body's angle to the target before and after the press
--   _G.NDStreetBot.targets()                         where the street's targets
--        stand now: the dummy, the crates, the rogues, the challenger, the
--        Ōtsutsuki
--   _G.NDStreetBot.armRiposte(delay)                 (the second client of a
--        two-player Play) hits back `delay` s after a challenge struck him
--   _G.NDStreetBot.log                               every press
local Players=game:GetService("Players")
local player=Players.LocalPlayer

local Street={log={}}

local function fight()
	local ps=player:WaitForChild("PlayerScripts")
	local module=ps:FindFirstChild("HubFightClient",true)
	return module and require(module).current
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function angle(a,b)
	a,b=flat(a),flat(b)
	if a.Magnitude<.01 or b.Magnitude<.01 then return nil end
	return math.floor(math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit),-1,1)))+.5)
end
local function root()
	local c=player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

function Street.stand(target,dist,side,turn)
	local r=root()
	if not r then return false end
	local d=Vector3.new(math.cos(math.rad(side or 0)),0,math.sin(math.rad(side or 0)))
	local at=Vector3.new(target.X,r.Position.Y,target.Z)+d*dist
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={player.Character}
	local ray=workspace:Raycast(at+Vector3.new(0,20,0),Vector3.new(0,-60,0),params)
	local y=if ray then ray.Position.Y+3 else at.Y
	local to=flat(target-at).Unit
	local face=CFrame.Angles(0,math.rad(turn or 0),0)*to
	r.AssemblyLinearVelocity=Vector3.zero
	r.CFrame=CFrame.lookAt(Vector3.new(at.X,y,at.Z),Vector3.new(at.X,y,at.Z)+face)
	return true
end

function Street.press(target,move,look)
	local r=root()
	local f=fight()
	if not r or not f then return {move=move,error="no body or no HubFightClient.current"} end
	local to=flat(target-r.Position).Unit
	local dir=CFrame.Angles(0,math.rad(look or 0),0)*to
	-- the camera where a player would have it: behind him, looking `look` beside the target
	workspace.CurrentCamera.CFrame=CFrame.lookAt(r.Position-dir*10+Vector3.new(0,4,0),r.Position+dir*10)
	local before=angle(r.CFrame.LookVector,to)
	local live=f:live()
	f:press(move)
	local row={move=move,live=live,look=look,dist=math.floor(flat(target-r.Position).Magnitude*10)/10,
		before=before,after=angle(r.CFrame.LookVector,target-r.Position),t=workspace:GetServerTimeNow()}
	table.insert(Street.log,row)
	return row
end

function Street.targets()
	local out={}
	local hub=workspace:FindFirstChild("NinjaDuelHub")
	if not hub then return out end
	for _,d in hub:GetDescendants() do
		if d:IsA("BasePart") and d.Name=="Dummy" then table.insert(out,{kind="dummy",at=d.Position}) end
	end
	local crates=0
	for _,d in hub:GetChildren() do
		if d.Name=="Crate" and crates<4 then
			local p=d:FindFirstChild("Crate")
			if p then crates+=1;table.insert(out,{kind="crate",at=p.Position}) end
		end
	end
	local thugs=hub:FindFirstChild("Thugs")
	for _,m in (if thugs then thugs:GetChildren() else {}) do
		if m:IsA("Model") then table.insert(out,{kind="thug",name=m.Name,at=m:GetPivot().Position}) end
	end
	local masters=hub:FindFirstChild("Masters")
	for _,m in (if masters then masters:GetChildren() else {}) do
		if m:GetAttribute("NinjaChallenge") then table.insert(out,{kind="challenger",kit=m:GetAttribute("NinjaChallenge"),at=m:GetPivot().Position}) end
		if m:GetAttribute("NinjaBoss") then table.insert(out,{kind="boss",at=m:GetPivot().Position}) end
	end
	return out
end

-- (the second client) a challenge struck him: he hits back after `delay` s
function Street.armRiposte(delay)
	local remote=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("HubImpact")
	if Street.riposte then Street.riposte:Disconnect() end
	Street.riposteState={armed=true}
	Street.riposte=remote.OnClientEvent:Connect(function(p)
		if type(p)~="table" or p.kind~="challenge" or p.to~=player.UserId or not Street.riposteState.armed then return end
		Street.riposteState.armed=false
		Street.riposteState.got=workspace:GetServerTimeNow()
		task.delay(delay or 1,function()
			local by=Players:GetPlayerByUserId(p.by)
			local c=by and by.Character
			local his=c and c:FindFirstChild("HumanoidRootPart")
			if his then Street.riposteState.row=Street.press(his.Position,"Light",-25) end
		end)
	end)
	return "riposte armée"
end

return Street
