-- Client: record projectiles (kind/infusion) and the human's state names from snapshots for DUR s.
local DUR=4
local remote=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("Action")
shared.NdProj={};shared.NdStates={}
local seen,last={},nil
local conn=remote.OnClientEvent:Connect(function(data)
	if type(data)~="table" then return end
	for _,p in data.projectiles or {} do
		if not seen[p.id] then seen[p.id]=true;table.insert(shared.NdProj,tostring(p.kind)..":"..tostring(p.infusion)) end
	end
	local st=data.human and data.human.state
	if st and st~=last then table.insert(shared.NdStates,st);last=st end
end)
task.delay(DUR,function() conn:Disconnect() end)
return "recording"
