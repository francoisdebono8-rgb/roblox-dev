local S=require(game.ServerStorage.NdStage)
local F={}
function F.string(A,B,gap)
	pcall(S.setup,A,B,gap or 5)
	S.dev:Invoke("autopilot",false)
	S.dev:Invoke("freezeBot",true)
	task.wait(.4)
end
function F.go()
	for i=1,3 do S.act("human","Attack") task.wait(.27) end
	task.wait(.35)
	S.act("human","Heavy")
end
return F
