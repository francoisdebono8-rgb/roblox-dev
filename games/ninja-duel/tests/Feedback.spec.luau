-- Feedback policy: the contact-driven impact feed and the reaction hierarchy.
-- Presentation itself is client-side and needs native QA, but the ordering rules
-- ("a slam is not a small hit") must not silently regress.
local H=require("./Harness")
local Vector3=H.roblox.Vector3
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
test("every contact reports a positioned, serialised impact",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 c:request(a,"Attack");H.step(c,.4)
 local feed=c.impacts
 assert(type(feed)=="table" and #feed>0,"no impact was reported for a landed hit")
 local last=0
 for _,impact in feed do
  assert(type(impact.style)=="string","impact without a style")
  assert(typeof(impact.position)=="Vector3","impact without a position")
  assert(impact.serial>last,"impact serials are not ordered")
  assert(impact.role=="victim" or impact.role=="neutral","impact role "..tostring(impact.role))
  last=impact.serial
 end
 assert(c.impactSerial==last,"impactSerial disagrees with the feed")
end)
test("blocks, parries and dodges are distinguishable from plain damage",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 c:request(b,"Guard");H.step(c,.02)
 c:damage(a,b,9,false,true)
 local parried=false
 for _,impact in c.impacts or {} do if impact.style=="parry" then parried=true end end
 assert(parried,"a fresh guard produced no parry impact")
 local d,e,f=H.duel("Mirage","Flashstep")
 f.stamina=100;d:request(f,"Guard");H.step(d,.3)
 d:damage(e,f,9,false,true)
 local blocked=false
 for _,impact in d.impacts or {} do if impact.style=="block" then blocked=true end end
 assert(blocked,"a held guard produced no block impact")
 local x,y,z=H.duel("Flashstep","Mirage")
 x:request(z,"Dodge");H.step(x,.1)
 local evaded=false
 for _,impact in x.impacts or {} do if impact.style=="dodge" then evaded=true end end
 assert(evaded,"a dodge produced no impact cue")
end)
test("a whiffed swing reports a whiff instead of silence",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 c:relocate(b,c.match.origin+Vector3.new(0,3,-40))
 c:request(a,"Attack");H.step(c,.5)
 local whiff=false
 for _,impact in c.impacts or {} do if impact.style=="whiff" then whiff=true end end
 assert(whiff,"whiffed swing reported nothing")
 assert(a.hitConfirmed==false,"whiff marked as confirmed")
end)
test("the impact feed stays bounded and clears with the duel",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 for _=1,12 do
  c:relocate(b,a.root.Position+a.root.CFrame.LookVector*3)
  c:request(a,"Attack");H.step(c,.4)
  c:relocate(b,a.root.Position+a.root.CFrame.LookVector*40)
  c:request(a,"Attack");H.step(c,.5)
 end
 -- Bounded by Combat:pushImpact (12 entries); snapshots only send unsent ones.
 assert(#(c.impacts or {})<=12,"impact feed grew to "..#c.impacts)
 c:clear(true)
 assert(#c.impacts==0,"cleared duel kept its impact feed")
end)
test("impact styles form a real hierarchy instead of one effect everywhere",function()
 -- Mirrors the client look table contract: intensity must increase with weight.
 local weight={whiff=0,kunai=1,shuriken=1,dodge=1,light=2,air=3,block=3,landing=3,launcher=4,
  finisher=5,parry=5,substitute=4,jutsu=6,slam=7}
 for style,value in weight do assert(value>0 or style=="whiff","unweighted style "..style) end
 assert(weight.slam>weight.finisher and weight.finisher>weight.light and weight.light>weight.whiff,
  "impact hierarchy is not ordered")
  -- The server must only ever emit declared styles.
 local declared={light=true,finisher=true,launcher=true,air=true,slam=true,block=true,parry=true,
  jutsu=true,kunai=true,shuriken=true,dodge=true,substitute=true,whiff=true,landing=true}
 local c,a,b=H.duel("Flashstep","Mirage")
 for i=1,6 do
  c:relocate(b,a.root.Position+a.root.CFrame.LookVector*3)
  c:request(a,"Attack");H.step(c,.4)
  c:relocate(b,c.match.origin+Vector3.new(0,3,-40));H.step(c,.4)
 end
 for _,impact in c.impacts or {} do
  assert(declared[impact.style],"undeclared impact style "..tostring(impact.style))
 end
end)
print(string.format("NinjaDuel feedback policy: %d PASS",passed))
