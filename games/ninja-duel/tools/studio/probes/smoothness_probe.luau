-- Smoothness probe (Server datamodel, debug build): client-side visual spikes while
-- walking, sprinting and in an AI-vs-AI exchange. Uses Codex's DevHooks probe.
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local Http=game:GetService("HttpService")
local out={}
dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
dev:Invoke("place",Vector3.new(0,3,40),Vector3.new(0,3,-70))
task.wait(.8)
dev:Invoke("probe")
dev:Invoke("move","human",Vector3.new(0,0,-1),5)
task.wait(3)
out.walk=dev:Invoke("probe")
dev:Invoke("place",Vector3.new(0,3,40),Vector3.new(0,3,-70));task.wait(.5);dev:Invoke("probe")
dev:Invoke("move","human",Vector3.new(0,0,-1),5);dev:Invoke("sprint","human",true)
task.wait(2.5)
out.sprint=dev:Invoke("probe")
dev:Invoke("move","human",Vector3.zero);dev:Invoke("sprint","human",false)
dev:Invoke("place",Vector3.new(0,3,7),Vector3.new(0,3,-7));dev:Invoke("refill")
dev:Invoke("freezeBot",false);dev:Invoke("scripted",false);dev:Invoke("autopilot",true)
task.wait(.3);dev:Invoke("probe")
task.wait(12)
out.fight=dev:Invoke("probe")
out.clientlog=dev:Invoke("clientlog",true)
dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true)
for _,k in {"walk","sprint","fight"} do
 local p=out[k]
 if type(p)=="table" then
  p.trace=nil
  if p.frames and p.frames>0 then p.headSpikePct=math.floor(p.headSpikes/p.frames*1000)/10;p.rootSpikePct=math.floor(p.rootSpikes/p.frames*1000)/10 end
 end
end
return Http:JSONEncode(out)
