-- Server: sample the human's route intent every frame for DUR s (async), into shared.NdIntent.
local DUR=5
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
shared.NdIntent={}
task.spawn(function()
	local t0=os.clock();local last
	while os.clock()-t0<DUR do
		local i=dev:Invoke("intent","human")
		local key=string.format("%s/%s dir=%s mem=%s combo=%s gap=%.1f open=%s",tostring(i.state),tostring(i.attack),tostring(i.dir),i.memory and i.memory.dir or "-",tostring(i.combo),i.gap,tostring(i.chainOpen))
		if key~=last then table.insert(shared.NdIntent,string.format("%.2f %s",os.clock()-t0,key));last=key end
		task.wait()
	end
end)
return "sampling"
