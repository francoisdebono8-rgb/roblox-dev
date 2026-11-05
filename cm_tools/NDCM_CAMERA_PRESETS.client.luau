-- CM capture helper. LOCAL STUDIO CLIENT ONLY, never ship in game.
-- Run in Client command bar during a Debug build Play test.
-- Change PRESET, re-run. To stop: shared.CM_CAMERA_STOP()
local PRESET="threequarter" -- wide | threequarter | low | portrait | impact
local HIDE_HUD=true
local RS=game:GetService("RunService")
local P=game:GetService("Players").LocalPlayer
assert(P,"Open the CLIENT command bar, not the server one")
if shared.CM_CAMERA_STOP then shared.CM_CAMERA_STOP() end
local C=workspace.CurrentCamera
local previousType,previousFov=C.CameraType,C.FieldOfView
local saved={}
if HIDE_HUD then
 local gui=P:FindFirstChildOfClass("PlayerGui")
 if gui then
  for _,g in gui:GetChildren() do
   if g:IsA("ScreenGui") then saved[g]=g.Enabled;g.Enabled=false end
  end
 end
end
local modes={
 wide={22,8,6,54},threequarter={17,7,5,50},
 low={13,5,2.2,50},portrait={8,3,3,38},impact={11,5,3,46}
}
local opt=assert(modes[PRESET],"bad preset")
C.CameraType=Enum.CameraType.Scriptable
RS:BindToRenderStep("NDCM_Cam",Enum.RenderPriority.Camera.Value+25,function(dt)
 local me=P.Character
 local bot=me and me.Parent and me.Parent:FindFirstChild("AIFighter")
 local a=me and me:FindFirstChild("HumanoidRootPart")
 local b=bot and bot:FindFirstChild("HumanoidRootPart")
 if not (a and b) then return end
 local diff=b.Position-a.Position
 local flat=Vector3.new(diff.X,0,diff.Z)
 local dir=flat.Magnitude>.1 and flat.Unit or Vector3.new(0,0,-1)
 local side=dir:Cross(Vector3.yAxis).Unit
 local mid=(a.Position+b.Position)/2+Vector3.new(0,1,0)
 if PRESET=="portrait" then mid=a.Position+Vector3.new(0,1.6,0) end
 local at=mid-dir*opt[1]+side*opt[2]+Vector3.new(0,opt[3],0)
 local goal=CFrame.lookAt(at,mid)
 C.CFrame=C.CFrame:Lerp(goal,math.clamp(dt*9,0,1))
 C.FieldOfView=opt[4]
 C.Focus=CFrame.new(mid)
end)
shared.CM_CAMERA_STOP=function()
 RS:UnbindFromRenderStep("NDCM_Cam")
 C.CameraType=previousType;C.FieldOfView=previousFov
 for gui,enabled in saved do if gui.Parent then gui.Enabled=enabled end end
 shared.CM_CAMERA_STOP=nil
 print("[NDCM] restored")
end
print("[NDCM] preset:",PRESET,"-- stop with shared.CM_CAMERA_STOP()")
