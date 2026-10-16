-- Client: analysis camera. VIEW = "side" | "front" | "off". Tracks the local fighter
-- (or the bot when WHO="bot") from a fixed side offset after the game camera runs.
local VIEW="side"
local WHO="me"
local DIST=13
local AXIS=nil -- fixed camera offset direction, e.g. Vector3.new(0,0,1)
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
pcall(function() RS:UnbindFromRenderStep("NdSideCam") end)
if VIEW=="off" then return "side cam off" end
local cam=workspace.CurrentCamera
local axis=AXIS
RS:BindToRenderStep("NdSideCam",Enum.RenderPriority.Camera.Value+5,function()
 local me=Players.LocalPlayer.Character
 local m=if WHO=="me" then me else me and me.Parent and me.Parent:FindFirstChild("AIFighter")
 local root=m and m:FindFirstChild("HumanoidRootPart")
 if not root then return end
 if not axis then
  local f=root.CFrame.LookVector;f=Vector3.new(f.X,0,f.Z).Unit
  axis=if VIEW=="side" then f:Cross(Vector3.yAxis).Unit else f
 end
 local target=root.Position+Vector3.new(0,-.3,0)
 cam.CFrame=CFrame.lookAt(target+axis*DIST+Vector3.new(0,1.2,0),target)
 cam.FieldOfView=50
end)
return "side cam "..VIEW.." on "..WHO
