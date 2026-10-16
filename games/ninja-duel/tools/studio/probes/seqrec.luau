-- Client: record the human's attack names and states from the snapshots for DUR s (async).
local DUR=6
local remote=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("Action")
shared.NdSeq={}
local last
local conn
conn=remote.OnClientEvent:Connect(function(data)
	if type(data)~="table" or not data.human then return end
	local h=data.human
	local key=tostring(h.attackName or "-")
	if h.attackName and key~=last then table.insert(shared.NdSeq,key) end
	last=if h.attackName then key else nil
end)
task.delay(DUR,function() conn:Disconnect() end)
return "recording"
