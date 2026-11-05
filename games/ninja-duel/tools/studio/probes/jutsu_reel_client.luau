-- Client: the jutsu reel's overlay and camera (jutsu pass, 05/11).
-- Watches workspace attribute NDShot ("index|fighter|action|label|cam"):
-- each new shot opens on a black title card (0.4 s, found later by
-- ffmpeg blackdetect to cut the recording), then a small caption stays at
-- the top for the contact sheets. cam="side" frames both fighters from a
-- three-quarter view in front of the caster; cam="game" leaves the game's
-- own camera (ultimates keep their cinematic).
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
local gui=Players.LocalPlayer:WaitForChild("PlayerGui")
local old=gui:FindFirstChild("NDShotGui");if old then old:Destroy() end
pcall(function() RS:UnbindFromRenderStep("NdShotCam") end)
if shared.NdShotConn then shared.NdShotConn:Disconnect();shared.NdShotConn=nil end
if workspace:GetAttribute("NDShotOff") then return "reel overlay off" end

local sg=Instance.new("ScreenGui");sg.Name="NDShotGui";sg.IgnoreGuiInset=true;sg.DisplayOrder=1000;sg.ResetOnSpawn=false
local card=Instance.new("Frame");card.Size=UDim2.fromScale(1,1);card.BackgroundColor3=Color3.new(0,0,0);card.BorderSizePixel=0;card.Visible=false;card.Parent=sg
local title=Instance.new("TextLabel");title.Size=UDim2.fromScale(1,.12);title.Position=UDim2.fromScale(0,.44);title.BackgroundTransparency=1
title.TextColor3=Color3.fromRGB(70,70,70);title.Font=Enum.Font.GothamBold;title.TextScaled=true;title.Parent=card
local cap=Instance.new("TextLabel");cap.Size=UDim2.new(1,0,0,30);cap.Position=UDim2.new(0,0,0,92);cap.BackgroundTransparency=.35;cap.BackgroundColor3=Color3.new(0,0,0)
cap.TextColor3=Color3.new(1,1,1);cap.Font=Enum.Font.GothamBold;cap.TextSize=22;cap.Text="";cap.Parent=sg
sg.Parent=gui

local mode="game";local axis,dist,focus=nil,14,nil
local function roots()
	local me=Players.LocalPlayer.Character
	local bot=me and me.Parent and me.Parent:FindFirstChild("AIFighter")
	return me and me:FindFirstChild("HumanoidRootPart"),bot and bot:FindFirstChild("HumanoidRootPart")
end
local function frame()
	local a,b=roots();if not a or not b then return end
	local d=(b.Position-a.Position)*Vector3.new(1,0,1)
	local gap=math.max(d.Magnitude,1);d=d/gap
	local side=d:Cross(Vector3.yAxis)
	axis=(side*.95+d*.18).Unit
	dist=7+gap*.9
	focus=a.Position*.58+b.Position*.42
end
RS:BindToRenderStep("NdShotCam",Enum.RenderPriority.Camera.Value+5,function()
	if mode~="side" or not axis then return end
	local a,b=roots();if not a or not b then return end
	local mid=a.Position*.58+b.Position*.42
	focus=focus:Lerp(mid,.12)
	local cam=workspace.CurrentCamera
	cam.CFrame=CFrame.lookAt(focus+axis*dist+Vector3.new(0,3.2,0),focus+Vector3.new(0,.6,0))
	cam.FieldOfView=52
end)
local function onShot()
	local raw=workspace:GetAttribute("NDShot")
	if type(raw)~="string" or raw=="" then cap.Text="";mode="game";return end
	local parts=string.split(raw,"|")
	local label=string.format("%s  %s  ·  %s",parts[1] or "",parts[2] or "",parts[4] or parts[3] or "")
	title.Text=label;cap.Text=label
	mode=parts[5] or "side"
	card.Visible=true
	task.delay(.42,function() frame();card.Visible=false end)
end
shared.NdShotConn=workspace:GetAttributeChangedSignal("NDShot"):Connect(onShot)
return "reel overlay on"
