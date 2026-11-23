-- Repeatable continuous fights. Debug-only driver; never bundled in a place.
-- Set SCENARIO A/B/C/D/E and fighter IDs. One placement at setup, none in fight.
local SCENARIO="A"
local A,B="Flashstep","Mirage"
local DURATION=20
local dev=game:GetService('ServerStorage'):WaitForChild('NinjaDuelDev',10)
dev:Invoke('start',A,B)
local start=os.clock()
repeat task.wait(.1) local r=dev:Invoke('act','human','GuardOff') until (type(r)=='table' and r.reason~='Intro') or os.clock()-start>12
dev:Invoke('autopilot',false);dev:Invoke('freezeBot',true);dev:Invoke('scripted',true)
dev:Invoke('health','human',800);dev:Invoke('health','bot',800)
local nearWall=SCENARIO=='D'
dev:Invoke('place',Vector3.new(if nearWall then 125 else 0,3,if nearWall then 12 else 14),Vector3.new(if nearWall then 132 else 0,3,0))
local runId=(workspace:GetAttribute('NdFightRun') or 0)+1;workspace:SetAttribute('NdFightRun',runId)
shared.NdFightQA={scenario=SCENARIO,fighters={A,B},duration=DURATION,done=false,actions={},samples={},fingerprint=game.ReplicatedStorage.NinjaDuel.BuildFingerprint.Value}
local result=shared.NdFightQA
local last={};local fired={}
local function act(who,action,aim,period)
 local key=who..action;local now=os.clock()
 if now-(last[key] or -math.huge)<(period or .25) then return end
 last[key]=now
 local r=dev:Invoke('act',who,action,aim)
 table.insert(result.actions,{t=now-(result.start or now),who=who,action=action,ok=type(r)=='table' and r.ok,reason=type(r)=='table' and r.reason or r})
end
local function once(key,fn) if not fired[key] then fired[key]=true;fn() end end
local function move(who,v) dev:Invoke('move',who,v,.25) end
local function pressure(who,s,route)
 local me,other=if who=='human' then s.human else s.bot,if who=='human' then s.bot else s.human
 local d=other.position-me.position;local flat=Vector3.new(d.X,0,d.Z);local gap=flat.Magnitude
 move(who,if gap>5.5 or route then flat.Unit else Vector3.zero)
 if gap<9 then act(who,'Attack',nil,if who=='bot' then .37 else .23) end
 if other.airborne and gap<40 then act(who,'Pursuit',nil,1) end
end
task.spawn(function()
 task.wait(5);result.start=os.clock()
 while workspace:GetAttribute('NdFightRun')==runId and os.clock()-result.start<DURATION do
  local t=os.clock()-result.start;local s=dev:Invoke('state')
  if s.phase~='Duel' then result.ended=s.phase;break end
  local d=s.bot.position-s.human.position;local flat=Vector3.new(d.X,0,d.Z)
  local toward=if flat.Magnitude>.01 then flat.Unit else Vector3.new(0,0,-1)
  local side=Vector3.new(-toward.Z,0,toward.X)
  if SCENARIO=='A' then
   if t<4 then pressure('human',s,false)
   elseif t<5 then move('human',side*.25);act('human','Guard',nil,.2)
   elseif t<7 then move('human',side*.25);act('human','Guard',nil,.3);pressure('bot',s,false)
   elseif t<8 then act('human','GuardOff',nil,.2);move('human',side);act('human','Dodge',nil,.5)
   elseif t<13 then pressure('human',s,true)
   elseif t<15 then pressure('bot',s,false);pressure('human',s,false)
   elseif t<17 then move('human',-toward);act('human','Jump',nil,.6)
   elseif t<18 then pressure('human',s,false)
   else move('human',-toward*.5);act('human','Tool',s.bot.position,.7) end
  elseif SCENARIO=='B' then
   if t<4 then move('human',side*.5);act('human','Tool',s.bot.position,.8);act('bot','Tool',s.human.position,1)
   elseif t<7 then move('human',toward*.4);act('human','Technique1',s.bot.position,2.3);act('bot','Technique1',s.human.position,2)
   elseif t<10 then act('human','Technique2',s.bot.position,1.7);move('human',side*.5)
   elseif t<12 then pressure('human',s,false);act('bot','Technique1',s.human.position,2)
   elseif t<15 then pressure('bot',s,false);move('human',side);act('human','Dodge',nil,1.4)
   else pressure('human',s,true) end
  elseif SCENARIO=='C' then
   if t<7 then pressure('human',s,true)
   elseif t<12 then once('jump',function()act('human','Jump')end);pressure('human',s,false)
   else pressure('bot',s,true);pressure('human',s,false) end
  elseif SCENARIO=='D' then
   if t<3 then move('human',Vector3.new(1,0,-.6).Unit);dev:Invoke('sprint','human',true)
   elseif t<5 then move('human',Vector3.new(1,0,-.6).Unit);act('human','Jump',nil,.9)
   elseif t<9 then act('human','Attack',nil,.35);act('human','Jump',nil,1.2);move('human',-toward)
   elseif t<14 then pressure('human',s,false)
   elseif t<17 then pressure('bot',s,false)
   else pressure('human',s,false) end
  else
   if t<4 then move('human',side*.6);act('human','Attack',nil,.45)
   elseif t<8 then pressure('human',s,false);move('bot',-side);act('bot','Dodge',nil,1.2)
   elseif t<12 then pressure('bot',s,false);move('human',side);act('human','Dodge',nil,1.2)
   else pressure('human',s,false);pressure('bot',s,false) end
  end
  table.insert(result.samples,{t=t,gap=flat.Magnitude,human=s.human,bot=s.bot})
  task.wait(.1)
 end
 move('human',Vector3.zero);move('bot',Vector3.zero);act('human','GuardOff');act('bot','GuardOff')
 result.final=dev:Invoke('state');result.done=true
end)
return 'fight '..SCENARIO..' staged; starts in 5s, '..DURATION..'s continuous'
