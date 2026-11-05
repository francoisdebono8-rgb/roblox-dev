-- NINJA DUEL: CM directed shot helper for Studio Debug/QA only.
-- Run in Studio PLAY -> SERVER Command Bar. Never include in public build.
-- Change SCENE and rerun for each take; capture a separate real-input proof.
local SCENE="preflight" -- preflight | mark | teleport_counter | itachi_mirage | neji_rotation
local LEAD=4 -- seconds to switch to OBS/client and start recording
local dev=game:GetService("ServerStorage"):FindFirstChild("NinjaDuelDev")
assert(dev,"Open the CURRENT NinjaDuel-Debug.rbxlx; start Play and use SERVER Command Bar.")
local function act(who,name,aim)
 local r=dev:Invoke("act",who,name,aim)
 print("[NDCM]",who,name,typeof(r)=="table" and tostring(r.ok) or "?",typeof(r)=="table" and tostring(r.reason) or tostring(r))
 return typeof(r)=="table" and r.ok==true
end
local function setup(first,second,gap)
 local started=dev:Invoke("start",first,second,true)
 assert(started~=false and started~="start refused","Start failed: "..tostring(started))
 local t0=os.clock()
 repeat
  task.wait(.25)
  if dev:Invoke("state").phase=="Duel" then break end
 until os.clock()-t0>12
 assert(dev:Invoke("state").phase=="Duel","Duel phase not reached")
 dev:Invoke("autopilot",false)
 dev:Invoke("freezeBot",true)
 dev:Invoke("scripted",true)
 dev:Invoke("refill")
 dev:Invoke("place",Vector3.new(0,3,gap/2),Vector3.new(0,3,-gap/2))
 task.wait(.4)
 print("[NDCM] Ready: "..first.." vs "..second)
end
if SCENE=="itachi_mirage" then
 setup("Mirage","Copycat",11)
 print("[NDCM] OBS READY in",LEAD,"seconds")
 task.wait(LEAD)
 act("human","Technique3")
 task.wait(3)
 print("[NDCM] Check visually: did the mirage actually appear?")
elseif SCENE=="neji_rotation" then
 setup("GentleFist","Flashstep",9)
 print("[NDCM] OBS READY in",LEAD,"seconds")
 task.wait(LEAD)
 act("human","Technique3")
 task.wait(2.5)
 print("[NDCM] This shot proves the Rotation animation, NOT a successful counter.")
else
 setup("Flashstep","GentleFist",15)
 local state=dev:Invoke("state")
 -- Aim off to Neji's right, and slightly down: verify a planted floor mark.
 local aim=state.bot.position+Vector3.new(3.4,-2.4,0)
 print("[NDCM] OBS READY in",LEAD,"seconds; aim",aim)
 task.wait(LEAD)
 assert(act("human","Technique1",aim),"Marked Kunai refused; stop this take")
 local count=0
 for _=1,20 do
  task.wait(.15)
  local s=dev:Invoke("state")
  count=s.human.seals or 0
  if count>0 then break end
 end
 print("[NDCM] Planted seals:",count)
 assert(count>0,"No seal planted! STOP; change aim & check projectile trajectory.")
 if SCENE=="mark" then
  task.wait(3)
  print("[NDCM] MARK shot complete; inspect floor mark and crop")
 else
  -- The real seal expires after ~12 s, so don't pause here too long.
  task.wait(.35)
  local moved=act("human","Technique3")
  assert(moved,"FTG refused; stop this take")
  task.wait(.27)
  local s=dev:Invoke("state")
  local d=(s.human.position-s.bot.position).Magnitude
  print("[NDCM] arrival distance:",d)
  if d>9 then warn("[NDCM] Arrival too far from Neji; DO NOT USE the take") end
  -- These actions may be rejected by state/cooldowns: log before using footage.
  act("human","Attack")
  task.wait(.075)
  act("bot","Technique3") -- Neji Rotation, if reaction state permits
  task.wait(2)
  local endState=dev:Invoke("state")
  print("[NDCM] phase",endState.phase,"human",endState.human.state,"bot",endState.bot.state)
  print("[NDCM] Human visual check still required: real impact and real counter?")
 end
end
print("[NDCM] Finished",SCENE,"; log success != visually accepted shot.")
