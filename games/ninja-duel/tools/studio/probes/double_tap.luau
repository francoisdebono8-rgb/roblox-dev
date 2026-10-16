-- Client: a real double tap through the Action remote (anti-cheat included):
-- two Attack packets GAP s apart, then the light names the snapshots show.
local GAP=.1
local remote=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("Action")
local epoch,names,last=nil,{},nil
local conn=remote.OnClientEvent:Connect(function(data)
	if type(data)~="table" then return end
	epoch=data.epoch or epoch
	local h=data.human
	local name=h and h.attackName
	if name and name~=last then table.insert(names,name) end
	last=name
end)
local t0=os.clock()
while not epoch and os.clock()-t0<3 do task.wait() end
if not epoch then conn:Disconnect();return "no snapshot" end
local function press() remote:FireServer({action="Attack",epoch=epoch,clientTime=workspace:GetServerTimeNow(),direction=Vector3.zero,sprint=false}) end
press()
task.wait(GAP)
press()
task.wait(1.2)
conn:Disconnect()
return string.format("double tap %.2f s apart -> %s",GAP,table.concat(names," > "))
