-- Client: fixed camera for arena overviews. VIEW = high | floor | off.
local VIEW="high"
local RS=game:GetService("RunService")
pcall(function() RS:UnbindFromRenderStep("NdOverview") end)
if VIEW=="off" then return "off" end
local cam=workspace.CurrentCamera
local duels=workspace:FindFirstChild("NinjaDuels")
local me=game:GetService("Players").LocalPlayer.Character
local center=Vector3.new(0,0,0)
local root=me and me:FindFirstChild("HumanoidRootPart")
-- The arena origin: the duel's middle (the bodies start around it).
if root then center=Vector3.new(root.Position.X,root.Position.Y-3,root.Position.Z) end
local eye,look
if VIEW=="high" then eye=center+Vector3.new(0,150,230);look=center+Vector3.new(0,0,-20)
elseif VIEW=="floor" then eye=center+Vector3.new(0,6,120);look=center+Vector3.new(0,30,-140)
elseif VIEW=="top" then eye=center+Vector3.new(0,420,1);look=center end
RS:BindToRenderStep("NdOverview",Enum.RenderPriority.Camera.Value+8,function() cam.CFrame=CFrame.lookAt(eye,look);cam.FieldOfView=70 end)
return "overview "..VIEW
