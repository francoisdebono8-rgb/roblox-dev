local RS=game:GetService("RunService")
local M={}
function M.at(focus,eye,fov)
	pcall(function() RS:UnbindFromRenderStep("NdLook") end)
	M.focus,M.eye=focus,eye
	RS:BindToRenderStep("NdLook",Enum.RenderPriority.Camera.Value+7,function()
		local cam=workspace.CurrentCamera
		cam.CFrame=CFrame.lookAt(M.eye,M.focus);cam.FieldOfView=fov or 55
	end)
end
function M.off() pcall(function() RS:UnbindFromRenderStep("NdLook") end) end
function M.hud(on)
	local pg=game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
	for _,g in pg and pg:GetChildren() or {} do if g:IsA("ScreenGui") then g.Enabled=on end end
end
return M
