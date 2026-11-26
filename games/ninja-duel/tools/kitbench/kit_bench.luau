-- The kits' bench (OUTILLEUR, passe commune 3, 26/11; DEC-055: « le banc des
-- kits : un robot joue chaque coup de chaque kit dans la place, et sort une
-- planche et une courte vidéo par kit. C'est le juge commun de l'ANIMATEUR,
-- du DEV et du CM »).
--
-- The street's moves (Shared/HubFight.Moves: the light chain, the heavy blow,
-- the air strike, the dash, the guard) on the walker's own body, posed by
-- the game itself (Client/HubBody through HubFightClient.current, the DEV's
-- :hold), each kit in turn. The pose's time steps through each clip; a label
-- at the top says which kit, which move, which instant, and whether the clip
-- is the kit's own or borrowed (HubBody.clipName falls back to Lion's). The
-- screen's other panels are hidden; the camera is held fixed beside him.
--
-- A client module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py bench               (eval_client_runtime)
--   _G.NDKitBench.clips()            for each kit and move: the clip played
--                                    and whether it is the kit's own (JSON)
--   _G.NDKitBench.camera(view)       "side" | "front" | "back": the camera held
--   _G.NDKitBench.play(kit, from, n, hold)  poses n frames of the kit's
--                                    timeline from frame `from`, each held
--                                    `hold` s (then capture_screenshot frames=n,
--                                    interval_ms=hold*1000, grid=true)
--   _G.NDKitBench.timeline(kit)      the frames: {move, t, clip}
--   _G.NDKitBench.release()          the camera, the panels, his kit back
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer

local Bench={}
Bench.KITS={"Lion","Legion","Sand","Leaf","GentleFist","Mirage","Copycat","Flashstep"}
Bench.NAMES={Lion="Sasuke",Legion="Naruto",Sand="Gaara",Leaf="Lee",GentleFist="Neji",Mirage="Itachi",Copycat="Kakashi",Flashstep="Minato"}
Bench.MOVES={"Light1","Light2","Light3","Heavy","Air","Dodge","Guard"}
-- The clip time between two frames (s): about 30 instants per kit, two sheets.
Bench.STEP=.13
local HOLD="NDKitBenchCam"
local state={running=false}
-- (HubBody.MOTOR: the clips name the shoulders Right and Left)
local MOTOR={Right="RightShoulder",Left="LeftShoulder"}

local function client()
	local ps=player:WaitForChild("PlayerScripts")
	local Authored=require(ps:FindFirstChild("AuthoredMotion",true))
	local HubBody=require(ps:FindFirstChild("HubBody",true))
	local Fight=require(ps:FindFirstChild("HubFightClient",true))
	local Rules=require(game:GetService("ReplicatedStorage").NinjaDuel.HubFight)
	return Authored,HubBody,Fight,Rules
end

-- The clip a kit plays for a move, and whether it is its own.
function Bench.clip(kit,move)
	local Authored,HubBody,_,Rules=client()
	local spec=Rules.Moves[move]
	local name=HubBody.clipName(Authored,kit,spec and spec.clip or move,nil,false)
	local own=name~=nil and string.sub(name,1,#kit+1)==kit.."."
	return name,own,(name and Authored.length(name)) or 0
end

function Bench.clips()
	local out={}
	for _,kit in Bench.KITS do
		out[kit]={}
		for _,move in Bench.MOVES do
			local name,own,len=Bench.clip(kit,move)
			out[kit][move]={clip=name,own=own,length=math.floor(len*100)/100}
		end
	end
	return HttpService:JSONEncode(out)
end

function Bench.timeline(kit)
	local frames={}
	for _,move in Bench.MOVES do
		local name,own,len=Bench.clip(kit,move)
		local span=if move=="Guard" then .3 else math.max(len,.2)
		local t=0
		while t<=span+1e-6 do
			table.insert(frames,{move=move,t=math.floor(t*100)/100,clip=name,own=own})
			t+=Bench.STEP
		end
	end
	return frames
end

local function label(text)
	local gui=player.PlayerGui:FindFirstChild("NDKitBenchLabel")
	if not gui then
		gui=Instance.new("ScreenGui");gui.Name="NDKitBenchLabel";gui.IgnoreGuiInset=true;gui.DisplayOrder=1000
		local t=Instance.new("TextLabel");t.Name="Text";t.Size=UDim2.new(1,0,0,34);t.BackgroundTransparency=.35
		t.BackgroundColor3=Color3.new(0,0,0);t.TextColor3=Color3.new(1,1,1);t.Font=Enum.Font.GothamBold;t.TextSize=22;t.Parent=gui
		gui.Parent=player.PlayerGui
	end
	gui.Text.Text=text
end

function Bench.camera(view)
	local c=player.Character
	local r=c and c:FindFirstChild("HumanoidRootPart")
	if not r then return "pas de corps" end
	state.hidden=state.hidden or {}
	for _,g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name~="NDKitBenchLabel" then g.Enabled=false;table.insert(state.hidden,g) end
	end
	local base=r.CFrame
	local offset=if view=="front" then base.LookVector*9 elseif view=="back" then -base.LookVector*9 else base.RightVector*9+base.LookVector*3
	local at=r.Position+offset+Vector3.new(0,1.4,0)
	local cf=CFrame.lookAt(at,r.Position+Vector3.new(0,.6,0))
	pcall(function() RunService:UnbindFromRenderStep(HOLD) end)
	RunService:BindToRenderStep(HOLD,Enum.RenderPriority.Last.Value+10,function()
		local cam=workspace.CurrentCamera
		if cam then cam.CameraType=Enum.CameraType.Scriptable;cam.CFrame=cf;cam.FieldOfView=50 end
	end)
	return "caméra "..tostring(view or "side")
end

-- Poses `n` frames of the kit's timeline from `from`, each held `hold` s.
function Bench.play(kit,from,n,hold)
	local _,_,Fight,Rules=client()
	local f=Fight.current
	if not f then return "pas de HubFightClient.current" end
	if state.kit0==nil then state.kit0=player:GetAttribute("NinjaKit") or false end
	-- (local only: his body here plays this kit's clips; the server's kit is not changed)
	player:SetAttribute("NinjaKit",kit)
	local frames=Bench.timeline(kit)
	from=from or 1
	local last=math.min(#frames,from+(n or 16)-1)
	state.running=true
	task.spawn(function()
		for i=from,last do
			local fr=frames[i]
			local spec=Rules.Moves[fr.move]
			local untilAt=os.clock()+(hold or .5)
			label(string.format("%s (%s) · %s · t = %.2f s · %s", Bench.NAMES[kit] or kit, kit, fr.move, fr.t,
				if fr.own then "clip du kit" else "clip emprunté : "..tostring(fr.clip)))
			while os.clock()<untilAt do
				f.act,f.actAt=spec.clip,os.clock()-fr.t
				task.wait()
			end
		end
		f.act=nil
		state.running=false
	end)
	return string.format("%s : images %d à %d sur %d",kit,from,last,#frames)
end

function Bench.running() return state.running end

-- (26/11) The sheet: 16 instants of the kit's timeline side by side, each one
-- a copy of his body (his avatar, his outfit) in its own ViewportFrame, posed
-- by the game's clip at that instant (HubBody.clipName, Authored.sample, the
-- joints HubBody.joints writes). One screenshot is the whole sheet: the
-- instants are exact, whatever the Studio's frame rate (a capture of the live
-- walker every 0,45 s came every 1,8 s on a loaded Mac).
--   _G.NDKitBench.sheet(kit, from, n, view, cols)   view: "side" (3/4 front,
--        the default), "front", "back"; cols: images per row (8; the plates of
--        the 26/11 are n=30, cols=10); then wait 3 s (a viewport captured
--        sooner can still be empty) and capture_screenshot (one frame)
--   _G.NDKitBench.clearSheet()
-- The eye stands far enough for a leap or a kick to stay in its cell, and the
-- sheet sits above the ClipAssistPanel (DisplayOrder 1100).
Bench.VIEWS={side=Vector3.new(11.5,5.4,-11.5),front=Vector3.new(0,4.8,-15),back=Vector3.new(0,4.8,15)}
Bench.SHEET_ORDER=5000
function Bench.sheet(kit,from,n,view,cols)
	local Authored,HubBody=client()
	Bench.clearSheet()
	local frames=Bench.timeline(kit)
	from=from or 1
	local last=math.min(#frames,from+(n or 16)-1)
	cols=cols or 8
	local rows=math.max(1,math.ceil((last-from+1)/cols))
	local c=player.Character
	if not c then return "pas de corps" end
	local was=c.Archivable
	c.Archivable=true
	local template=c:Clone()
	c.Archivable=was
	for _,d in template:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("Animator") or d:IsA("BillboardGui") then d:Destroy() end
	end
	local hum=template:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
	state.hidden=state.hidden or {}
	for _,g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name~="NDKitSheet" then g.Enabled=false;table.insert(state.hidden,g) end
	end
	local gui=Instance.new("ScreenGui");gui.Name="NDKitSheet";gui.IgnoreGuiInset=true;gui.DisplayOrder=Bench.SHEET_ORDER
	local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(28,30,36);bg.BorderSizePixel=0;bg.Parent=gui
	local grid=Instance.new("UIGridLayout");grid.CellSize=UDim2.new(1/cols,-4,1/rows,-4);grid.CellPadding=UDim2.fromOffset(4,4);grid.Parent=bg
	local eye=Bench.VIEWS[view or "side"] or Bench.VIEWS.side
	for i=from,last do
		local fr=frames[i]
		local vf=Instance.new("ViewportFrame");vf.BackgroundColor3=Color3.fromRGB(74,78,88)
		vf.Ambient=Color3.fromRGB(165,165,165);vf.LightColor=Color3.new(1,1,1);vf.LightDirection=Vector3.new(-1,-1,.6);vf.LayoutOrder=i;vf.Parent=bg
		local wm=Instance.new("WorldModel");wm.Parent=vf
		local m=template:Clone();m.Parent=wm
		local root=m:FindFirstChild("HumanoidRootPart")
		if root then root.Anchored=true;root.CFrame=CFrame.new(0,3,0) end
		local pose=fr.clip and Authored.sample(fr.clip,fr.t)
		local j=HubBody.joints(m)
		for joint,cf in pose or {} do
			local jj=j[MOTOR[joint] or joint]
			if jj then jj.Transform=cf end
		end
		local cam=Instance.new("Camera");cam.FieldOfView=42;cam.CFrame=CFrame.lookAt(eye,Vector3.new(0,3,0));cam.Parent=vf;vf.CurrentCamera=cam
		local t=Instance.new("TextLabel");t.BackgroundTransparency=.4;t.BackgroundColor3=Color3.new(0,0,0);t.Size=UDim2.new(1,0,0,40)
		t.TextColor3=Color3.new(1,1,1);t.Font=Enum.Font.GothamBold;t.TextSize=15;t.TextWrapped=true
		t.Text=string.format("%s · %s · %.2f s%s",Bench.NAMES[kit] or kit,fr.move,fr.t,if fr.own then "" else "\n(clip de "..tostring(fr.clip)..")")
		t.Parent=vf
	end
	gui.Parent=player.PlayerGui
	template:Destroy()
	return string.format("%s : images %d à %d sur %d",kit,from,last,#frames)
end
function Bench.clearSheet()
	local old=player.PlayerGui:FindFirstChild("NDKitSheet")
	if old then old:Destroy() end
	return "ok"
end

function Bench.release()
	pcall(function() RunService:UnbindFromRenderStep(HOLD) end)
	local cam=workspace.CurrentCamera
	if cam then cam.CameraType=Enum.CameraType.Custom;cam.FieldOfView=70 end
	for _,g in state.hidden or {} do g.Enabled=true end
	state.hidden=nil
	local l=player.PlayerGui:FindFirstChild("NDKitBenchLabel")
	if l then l:Destroy() end
	if state.kit0~=nil then player:SetAttribute("NinjaKit",state.kit0 or nil);state.kit0=nil end
	Bench.clearSheet()
	return "ok"
end

return Bench
