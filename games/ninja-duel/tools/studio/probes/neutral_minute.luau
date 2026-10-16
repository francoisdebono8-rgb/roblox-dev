-- Server: 60 s AI-vs-AI fight metrics (space use, phases, verbs). FIGHTERS / DUR edited per call.
local A,B="Flashstep","Mirage"
local DUR=60
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
workspace:SetAttribute("NdCapGen",(workspace:GetAttribute("NdCapGen") or 0)+1)
dev:Invoke("start",A,B)
local t0=os.clock()
repeat task.wait(.25) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
dev:Invoke("scripted",false);dev:Invoke("freezeBot",false);dev:Invoke("autopilot",true)
dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
local function evs(st,key) return table.clone(st[key] or {}) end
local s0=dev:Invoke("state")
local e0={human=evs(s0,"events"),bot=evs(s0,"botEvents")}
local samples=0
local dist={close=0,mid=0,far=0,vfar=0}
local air,wall,nearWall,center={human=0,bot=0},{human=0,bot=0},{human=0,bot=0},{human=0,bot=0}
local states={}
local projectiles=0
local maxProj=0
local exchanges=0
local lastClose=false
local resets=0
local hp0={human=s0.human.health,bot=s0.bot.health}
local tEnd=os.clock()+DUR
local rounds=0
local lastPhase=s0.phase
while os.clock()<tEnd do
 task.wait(.1)
 local s=dev:Invoke("state")
 if type(s)~="table" or not s.human or not s.bot then continue end
 if s.phase~=lastPhase then if s.phase~="Duel" then rounds+=1 end lastPhase=s.phase end
 if s.phase~="Duel" then continue end
 -- Keep both alive without touching chakra or cooldowns (refill would).
 if s.human.health<80 then dev:Invoke("health","human",400) end
 if s.bot.health<80 then dev:Invoke("health","bot",400) end
 samples+=1
 local d=(Vector3.new(s.human.position.X,0,s.human.position.Z)-Vector3.new(s.bot.position.X,0,s.bot.position.Z)).Magnitude
 if d<7 then dist.close+=1 elseif d<16 then dist.mid+=1 elseif d<36 then dist.far+=1 else dist.vfar+=1 end
 local close=d<9
 if close and not lastClose then exchanges+=1 end
 if not close and lastClose then resets+=1 end
 lastClose=close
 for _,k in {"human","bot"} do
  local a=s[k]
  if a.airborne then air[k]+=1 end
  if a.wall then wall[k]+=1 end
  local r=Vector3.new(a.position.X,0,a.position.Z).Magnitude
  if r>85 then nearWall[k]+=1 end
  if r<35 then center[k]+=1 end
  states[a.state]=(states[a.state] or 0)+1
 end
 projectiles+=#s.projectiles;maxProj=math.max(maxProj,#s.projectiles)
end
dev:Invoke("autopilot",false)
local s1=dev:Invoke("state")
local out={string.format("%s vs %s, %d samples (10 Hz), rounds ended=%d",A,B,samples,rounds)}
local n=math.max(samples,1)
table.insert(out,string.format("distance: close<7 %.0f%%  mid7-16 %.0f%%  far16-36 %.0f%%  vfar>36 %.0f%%",dist.close/n*100,dist.mid/n*100,dist.far/n*100,dist.vfar/n*100))
table.insert(out,string.format("engagements (enter <9)=%d  disengagements=%d  projectile-samples avg=%.2f max=%d",exchanges,resets,projectiles/n,maxProj))
for _,k in {"human","bot"} do
 table.insert(out,string.format("%s: air %.0f%%  wall %.0f%%  nearWall(r>85) %.0f%%  center(r<35) %.0f%%",k,air[k]/n*100,wall[k]/n*100,nearWall[k]/n*100,center[k]/n*100))
end
local sl={}
for st,c in states do table.insert(sl,{st,c}) end
table.sort(sl,function(x,y) return x[2]>y[2] end)
local parts={}
for _,p in sl do table.insert(parts,string.format("%s %.0f%%",p[1],p[2]/(n*2)*100)) end
table.insert(out,"states: "..table.concat(parts,", "))
for _,k in {"human","bot"} do
 local now=s1[if k=="human" then "events" else "botEvents"] or {}
 local diff={}
 for name,c in now do local d=c-(e0[k][name] or 0) if d>0 then table.insert(diff,name.."="..d) end end
 table.sort(diff)
 table.insert(out,k.." events: "..table.concat(diff," "))
end
return table.concat(out,"\n")
