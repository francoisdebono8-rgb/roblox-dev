-- Receive current authority immediately, draw one coherent fight timeline.
local H=require('./Harness')
local V=H.V
local count=0
local function test(name,fn)
 local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));count+=1;print('PASS '..name)
end
local function fixture(fn)
 local _,restore=H.stubScene()
 local P=H.load('Client/Presentation');local p=P.new()
 local played={};p.fx.sync=function() end
 p.fx.impact=function(_,hit) table.insert(played,hit.serial) end
 local ok,err=pcall(fn,p,played);restore();assert(ok,err)
end
local function snap(t,serial,epoch)
 return {phase='Duel',epoch=epoch or 1,serverNow=t,impactSerial=serial or 0,impacts={},human={state='Neutral'}}
end
test('body states wait for the same timeline as release and contact',function()
 fixture(function(p)
  local a,b=snap(100),snap(100.05)
  b.human={state='Active',attackName='Light1'}
  p:receive(a);p:receive(b)
  assert(p:frameData(b,100.02)==a,'new active state led visual root/projectile')
  assert(p:frameData(b,100.05)==b,'action never entered the visual timeline')
  local old=snap(99.9);p:receive(old)
  assert(p:frameData(b,100.06)==b,'jitter rewound the body')
 end)
end)
test('close tool contact waits for release and never repeats',function()
 fixture(function(p,played)
  local s=snap(100,1);s.impacts={{serial=1,at=100,style='afterimage',position=V.zero,projectile=7}}
  p:receive(s);p:receive(s)
  p:flushImpacts(s,nil,99.99);assert(#played==0,'contact before blade release')
  p:flushImpacts(s,nil,100);assert(#played==1 and played[1]==1,'missing or duplicate contact')
  p:flushImpacts(s,nil,101);assert(#played==1,'contact replayed on next frame')
 end)
end)
test('a round change discards the old fight and its queued contacts',function()
 fixture(function(p,played)
  local a=snap(100,1);a.impacts={{serial=1,at=101,style='afterimage',position=V.zero}}
  p:receive(a)
  local b=snap(100.1,1,2);b.impacts={{serial=1,at=100.1,style='afterimage',position=V.zero}}
  p:receive(b);p:flushImpacts(b,nil,102)
  assert(#played==1,'previous round contact survived reset')
  assert(#p.frames==1 and p.frames[1]==b,'previous round body survived reset')
 end)
end)
test('the killing contact survives the result transition',function()
 fixture(function(p,played)
  local duel=snap(100,1);duel.impacts={{serial=1,at=100,style='afterimage',position=V.zero}}
  p:receive(duel)
  local result=snap(100.02,1);result.phase='Result';p:receive(result)
  assert(p:frameData(result,100.01)==duel,'result cut off the final reaction')
  p:flushImpacts(result,nil,100.03)
  assert(#played==1,'killing contact lost on result')
  p:receive(result);p:flushImpacts(result,nil,101);assert(#played==1,'killing contact replayed')
 end)
end)
test('paused render queues stay bounded and selection clears them',function()
 fixture(function(p)
  for i=1,120 do
   local s=snap(100+i*.01,i);s.impacts={{serial=i,at=s.serverNow,style='afterimage',position=V.zero}};p:receive(s)
  end
  assert(#p.frames<=8 and #p.pendingImpacts<=96,'unbounded render queue')
  local selection={phase='Selection',epoch=1};p:receive(selection)
  assert(#p.frames==0 and #p.pendingImpacts==0,'selection retained fight events')
  assert(p:frameData(selection)==selection,'menu incorrectly delayed')
 end)
end)
print('NinjaDuel presentation continuity: '..count..' PASS')
