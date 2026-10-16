-- Server: pose loops for visual comparison captures. MODE is replaced per call.
local MODE="idle"
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local s=dev:Invoke("state")
if type(s)~="table" or s.phase~="Duel" then
 dev:Invoke("start","Flashstep","Mirage")
 local t0=os.clock()
 repeat task.wait(.25) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
end
local gen=(workspace:GetAttribute("NdCapGen") or 0)+1
workspace:SetAttribute("NdCapGen",gen)
local function alive() return workspace:GetAttribute("NdCapGen")==gen end
dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
dev:Invoke("move","human",Vector3.zero);dev:Invoke("move","bot",Vector3.zero);dev:Invoke("act","human","GuardOff");dev:Invoke("act","bot","GuardOff")
local far=MODE=="run" or MODE=="sprint"
dev:Invoke("place",Vector3.new(0,3,if far then 34 elseif MODE=="idle" or MODE=="strafe" or MODE=="jump" then 12 else 6),Vector3.new(0,3,if far then -34 else -2))
if MODE=="stop" then return "stopped" end
task.spawn(function()
 task.wait(.6)
 while alive() do
  dev:Invoke("refill")
  if MODE=="strafe" then
   dev:Invoke("move","human",Vector3.new(1,0,0),.5);task.wait(1.6)
   dev:Invoke("move","human",Vector3.new(-1,0,0),.5);task.wait(1.6)
  elseif MODE=="run" or MODE=="sprint" then
   -- A lane across the arena, the opponent far off to the side.
   dev:Invoke("place",Vector3.new(-50,3,20),Vector3.new(0,3,-45));task.wait(.3)
   dev:Invoke("move","human",Vector3.new(1,0,0),3)
   if MODE=="sprint" then dev:Invoke("sprint","human",true) end
   task.wait(if MODE=="sprint" then 1.9 else 3.2);dev:Invoke("move","human",Vector3.zero);task.wait(.4)
  elseif MODE=="retreat" then
   dev:Invoke("place",Vector3.new(0,3,6),Vector3.new(0,3,-4));task.wait(.3)
   dev:Invoke("move","human",Vector3.new(0,0,1),3);task.wait(1.4)
   dev:Invoke("move","human",Vector3.zero);task.wait(.4)
  elseif MODE=="zigzag" then
   dev:Invoke("move","human",Vector3.new(1,0,-.3).Unit,.5);task.wait(.7)
   dev:Invoke("move","human",Vector3.new(-1,0,-.3).Unit,.5);task.wait(.7)
   dev:Invoke("move","human",Vector3.new(0,0,1),.5);task.wait(.6)
  elseif MODE=="circle" or MODE=="circlerun" then
   -- One continuous lap: no re-placement inside the probe window.
   dev:Invoke("place",Vector3.new(55,3,0),Vector3.new(0,3,0));task.wait(.3)
   local t0=os.clock()
   while alive() and os.clock()-t0<20 do
    local st=dev:Invoke("state")
    local p=st.human.position-Vector3.new(0,0,0)
    local origin=st.human.position
    local flat=Vector3.new(p.X,0,p.Z)
    local tangent=Vector3.new(-flat.Z,0,flat.X).Unit
    local inward=-flat.Unit*math.clamp((flat.Magnitude-55)/20,-.5,.5)
    dev:Invoke("move","human",(tangent+inward).Unit,.3)
    if MODE=="circle" then dev:Invoke("sprint","human",true) end
    task.wait(.1)
   end
  elseif MODE=="jump" then
   dev:Invoke("act","human","Jump");task.wait(1.5)
  elseif MODE=="runjump" then
   dev:Invoke("place",Vector3.new(-50,3,20),Vector3.new(0,3,-45));task.wait(.3)
   dev:Invoke("move","human",Vector3.new(1,0,0),3);task.wait(.6)
   dev:Invoke("act","human","Jump");task.wait(1.3);dev:Invoke("move","human",Vector3.zero);task.wait(.4)
  elseif MODE=="jab" then
   dev:Invoke("act","human","Attack");task.wait(.9)
  elseif MODE=="combo" then
   for _=1,5 do dev:Invoke("act","human","Attack");task.wait(.22) end;task.wait(1.2)
  elseif MODE=="heavy" then
   dev:Invoke("act","human","Heavy");task.wait(1.6)
  elseif MODE=="air" then
   dev:Invoke("act","human","Jump");task.wait(.3)
   for _=1,4 do dev:Invoke("act","human","Attack");task.wait(.25) end;task.wait(1.2)
  elseif MODE=="guard" then
   dev:Invoke("act","human","Guard");dev:Invoke("act","bot","Attack");task.wait(.9)
  elseif MODE=="tool" then
   dev:Invoke("act","human","Tool");task.wait(1.4)
  else task.wait(.5) end
 end
 dev:Invoke("move","human",Vector3.zero);dev:Invoke("act","human","GuardOff")
end)
return "mode "..MODE.." gen "..gen
