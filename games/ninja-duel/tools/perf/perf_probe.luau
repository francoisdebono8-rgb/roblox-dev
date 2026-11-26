-- The fluidity probe (OUTILLEUR, 23/11; étape 5, DEC-049: « la fluidité sur
-- téléphone : la matrice d'appareils de Studio sur le village et sur un duel,
-- en images/s et en mémoire, avant et après »).
--
-- A client module, injected in a Play of the game (DEC-052), while the device simulator
-- shows a phone (robloxstudio-mcp set_device_simulator). It measures, over a
-- few seconds, from where the camera is:
--   frames      the frame times (RenderStepped): images/s on average, the
--               worst 1 % and 5 % of frames, frames over 33 ms (under 30/s);
--   memory      the client's total memory and its largest tags (Stats);
--   scene       triangles and draw calls the renderer sends (Stats, when the
--               engine gives them), parts and meshes in the workspace;
--   quality     the graphics quality the client runs at.
-- The Mac's Studio is not a phone: the images/s are the Mac's at the phone's
-- screen size. What carries over to a phone is the scene's weight
-- (triangles, draw calls, parts, memory), compared with the budgets in
-- tools/perf/README.md.
--
--   _G.NDPerfProbe.measure({seconds=8, label="village"})  (python3 tools/robots/inject.py perf first)
--   -> stored in Players.LocalPlayer attribute NDPerfLog (JSON list)
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Stats=game:GetService("Stats")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer

local Probe={}
local function r1(x) return math.floor(x*10+.5)/10 end
local function prop(obj,name)
	local ok,v=pcall(function() return obj[name] end)
	return if ok then v else nil
end
local function scene()
	local parts,meshes,unions,triangles=0,0,0,0
	for _,d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			parts+=1
			if d:IsA("MeshPart") then meshes+=1 elseif d:IsA("UnionOperation") then unions+=1 end
		end
	end
	return {parts=parts,meshes=meshes,unions=unions}
end
local function memory()
	local out={total=r1(Stats:GetTotalMemoryUsageMb())}
	local tags={}
	for _,tag in Enum.DeveloperMemoryTag:GetEnumItems() do
		local ok,mb=pcall(function() return Stats:GetMemoryUsageMbForTag(tag) end)
		if ok and mb and mb>=1 then table.insert(tags,{tag=tag.Name,mb=r1(mb)}) end
	end
	table.sort(tags,function(a,b) return a.mb>b.mb end)
	for i=1,math.min(8,#tags) do out[tags[i].tag]=tags[i].mb end
	return out
end
local function quality()
	-- settings() needs the Plugin capability: a game script cannot call it, so
	-- only the player's saved level (UserGameSettings) is read.
	local q=nil
	pcall(function() q=UserSettings():GetService("UserGameSettings").SavedQualityLevel end)
	return {saved=q and q.Name or nil}
end

function Probe.measure(options)
	options=options or {}
	local seconds=options.seconds or 8
	local frames={}
	local camera=workspace.CurrentCamera
	local conn=RunService.RenderStepped:Connect(function(dt) table.insert(frames,dt) end)
	local tris,draws={},{}
	local t0=os.clock()
	while os.clock()-t0<seconds do
		task.wait(.5)
		local t=prop(Stats,"SceneTriangleCount");if t then table.insert(tris,t) end
		local d=prop(Stats,"SceneDrawcallCount");if d then table.insert(draws,d) end
	end
	conn:Disconnect()
	table.sort(frames,function(a,b) return a>b end)
	local sum=0 for _,dt in frames do sum+=dt end
	local function worst(share)
		local n=math.max(1,math.floor(#frames*share))
		local s=0 for i=1,n do s+=frames[i] end
		return r1(1/(s/n))
	end
	local slow=0 for _,dt in frames do if dt>1/30 then slow+=1 end end
	local function mean(list) local s=0 for _,v in list do s+=v end return if #list>0 then math.floor(s/#list) else nil end
	local function top(list) local m=nil for _,v in list do m=if m then math.max(m,v) else v end return m end
	local vp=camera and camera.ViewportSize or Vector2.zero
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local rec={label=options.label or "?",seconds=seconds,frames=#frames,
		fps=if sum>0 then r1(#frames/sum) else nil,low1=worst(.01),low5=worst(.05),
		under30=r1(100*slow/math.max(1,#frames)),
		viewport={math.floor(vp.X),math.floor(vp.Y)},
		triangles=mean(tris),trianglesMax=top(tris),drawcalls=mean(draws),drawcallsMax=top(draws),
		memory=memory(),scene=scene(),quality=quality(),
		at=root and {math.floor(root.Position.X),math.floor(root.Position.Y),math.floor(root.Position.Z)} or nil,
		phase=player:GetAttribute("NDPhase"),streaming=workspace.StreamingEnabled}
	local log={}
	pcall(function() log=HttpService:JSONDecode(player:GetAttribute("NDPerfLog") or "[]") end)
	table.insert(log,rec)
	pcall(function() player:SetAttribute("NDPerfLog",HttpService:JSONEncode(log)) end)
	return rec
end

-- Point the camera from the player's body over the village (a slow turn), as a
-- player looks around; the probe measures while it turns.
function Probe.lookAround(seconds)
	local camera=workspace.CurrentCamera
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not camera or not root then return end
	local t0=os.clock()
	local was=camera.CameraType
	camera.CameraType=Enum.CameraType.Scriptable
	local conn=RunService.RenderStepped:Connect(function()
		local a=(os.clock()-t0)/seconds*math.pi*2
		local at=root.Position+Vector3.new(math.cos(a)*18,9,math.sin(a)*18)
		camera.CFrame=CFrame.lookAt(at,root.Position+Vector3.new(0,3,0))
	end)
	task.delay(seconds,function() conn:Disconnect();camera.CameraType=was end)
end
-- (26/11, passe commune 2, DEC-054: « la fluidité (images par seconde et
-- à-coups) dans la ville et en duel, avant et après la passe ») A measure
-- that runs while the robots play, without holding the client (a blocking
-- call freezes the bodies): start, let the duel or the walk go, stop.
-- Besides the frames, the hitches (frames over 50 and 100 ms, the worst), the
-- simulation's own steps (Heartbeat), and the bodies' jerks: the rival's
-- body (in a duel) and his own, frame by frame. A jerk is a frame where a body
-- that moves stops dead or jumps: its step under a quarter or over three
-- times the mean of the steps around it.
local live=nil
local function stats(list)
	local n=#list
	if n==0 then return {} end
	local sum,worst,o33,o50,o100=0,0,0,0,0
	for _,dt in list do
		sum+=dt;worst=math.max(worst,dt)
		if dt>1/30 then o33+=1 end
		if dt>.05 then o50+=1 end
		if dt>.1 then o100+=1 end
	end
	local sorted=table.clone(list)
	table.sort(sorted,function(a,b) return a>b end)
	local function low(share)
		local k=math.max(1,math.floor(n*share))
		local s=0 for i=1,k do s+=sorted[i] end
		return r1(1/(s/k))
	end
	return {frames=n,perSecond=r1(n/sum),low1=low(.01),low5=low(.05),worstMs=r1(worst*1000),over33=o33,over50=o50,over100=o100}
end
local function jerks(track)
	-- track: {dt, position} per drawn frame
	local steps={}
	for i=2,#track do
		local a,b=track[i-1],track[i]
		if b.p and a.p and b.dt>0 then table.insert(steps,(b.p-a.p).Magnitude/b.dt) end
	end
	local moving,jerk=0,0
	for i=2,#steps-1 do
		local around=(steps[i-1]+steps[i+1])/2
		if around>4 then
			moving+=1
			if steps[i]<around*.25 or steps[i]>around*3 then jerk+=1 end
		end
	end
	return {moving=moving,jerks=jerk,share=if moving>0 then r1(100*jerk/moving) else nil}
end
local function bodiesNow()
	local me=player.Character
	local root=me and me:FindFirstChild("HumanoidRootPart")
	local him=me and me.Parent and me.Parent:FindFirstChild("AIFighter")
	local hisRoot=him and him:FindFirstChild("HumanoidRootPart")
	return root,hisRoot
end
function Probe.start(options)
	options=options or {}
	if live then Probe.stop() end
	local rec={label=options.label or "?",t0=os.clock(),render={},beat={},tris={},draws={},me={},him={}}
	live=rec
	rec.c1=RunService.RenderStepped:Connect(function(dt)
		table.insert(rec.render,dt)
		local a,b=bodiesNow()
		table.insert(rec.me,{dt=dt,p=a and a.Position})
		table.insert(rec.him,{dt=dt,p=b and b.Position})
	end)
	rec.c2=RunService.Heartbeat:Connect(function(dt) table.insert(rec.beat,dt) end)
	task.spawn(function()
		while live==rec do
			task.wait(.5)
			local t=prop(Stats,"SceneTriangleCount");if t then table.insert(rec.tris,t) end
			local d=prop(Stats,"SceneDrawcallCount");if d then table.insert(rec.draws,d) end
		end
	end)
	return "mesure en route : "..rec.label
end
function Probe.stop()
	local rec=live
	if not rec then return nil end
	live=nil
	rec.c1:Disconnect();rec.c2:Disconnect()
	local function mean(list) local s=0 for _,v in list do s+=v end return if #list>0 then math.floor(s/#list) else nil end
	local function top(list) local m=nil for _,v in list do m=if m then math.max(m,v) else v end return m end
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local out={label=rec.label,seconds=r1(os.clock()-rec.t0),kind="live",render=stats(rec.render),simulation=stats(rec.beat),
		jerksMe=jerks(rec.me),jerksRival=jerks(rec.him),
		triangles=mean(rec.tris),trianglesMax=top(rec.tris),drawcalls=mean(rec.draws),drawcallsMax=top(rec.draws),
		memory=memory(),scene=scene(),quality=quality(),phase=player:GetAttribute("NDPhase"),
		at=root and {math.floor(root.Position.X),math.floor(root.Position.Y),math.floor(root.Position.Z)} or nil}
	out.fps=out.render.perSecond
	local log={}
	pcall(function() log=HttpService:JSONDecode(player:GetAttribute("NDPerfLog") or "[]") end)
	table.insert(log,out)
	pcall(function() player:SetAttribute("NDPerfLog",HttpService:JSONEncode(log)) end)
	return out
end
return Probe
