local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local Input={}; Input.__index=Input
function Input.new(send,getState,toggleLock)
	local self=setmetatable({send=send,getState=getState,keys={}},Input)
	local function bind(name,key,action)
		CAS:BindActionAtPriority("Ninja"..name,function(_,state)
			if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			local duel=getState() and getState().phase=="Duel"
			if state==Enum.UserInputState.Begin and duel then action(true)
			elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then action(false) end
			return if duel then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
		end,false,3000,key)
	end
	for _,key in {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D} do
		bind(key.Name,key,function(down) self.keys[key.Name]=down end)
	end
	bind("Attack",Enum.UserInputType.MouseButton1,function(down) if down then send("Attack") end end)
	bind("Guard",Enum.KeyCode.F,function(down) send(if down then "Guard" else "GuardOff") end)
	bind("Dodge",Enum.KeyCode.Q,function(down) if down then send("Dodge") end end)
	bind("Jump",Enum.KeyCode.Space,function(down) send(if down then "Jump" else "JumpOff") end)
	bind("Sprint",Enum.KeyCode.LeftControl,function(down) self.sprinting=down end)
	bind("Pursuit",Enum.KeyCode.E,function(down) if down then send("Pursuit") end end)
	for i,key in {Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three} do
		bind("Technique"..i,key,function(down) if down then send("Technique"..i) end end)
	end
	bind("Lock",Enum.KeyCode.LeftShift,function(down) if down then toggleLock() end end)
	UIS.WindowFocusReleased:Connect(function() table.clear(self.keys); self.sprinting=false; send("GuardOff"); send("Move",Vector3.zero) end)
	return self
end
function Input:direction(camera)
	local x=(if self.keys.D then 1 else 0)-(if self.keys.A then 1 else 0)
	local z=(if self.keys.W then 1 else 0)-(if self.keys.S then 1 else 0)
	local look=camera.CFrame.LookVector; look=Vector3.new(look.X,0,look.Z)
	if look.Magnitude<0.01 then look=-Vector3.zAxis end
	look=look.Unit
	local right=Vector3.new(-look.Z,0,look.X)
	local v=right*x+look*z
	return if v.Magnitude>1 then v.Unit else v
end
return Input
