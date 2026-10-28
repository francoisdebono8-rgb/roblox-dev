-- Air combat (Partie 10, user 28/10: "quand je me bats en l'air, ça marche
-- pas bien"): from a jump's height the fight still reaches the opponent.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,pa,pb)
 c:relocate(a,pa);c:relocate(b,pb)
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
 b.root.CFrame=H.C.lookAt(b.root.Position,V.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
end

test("air dive: high above a grounded body and out of reach, the air opener lunges down onto him and lands",function()
 for _,id in {"Lion","Legion","Leaf","Mirage"} do
  local c,a,b=H.duel(id,"Flashstep")
  place(c,a,b,V.new(0,3,10),V.new(0,3,-2))
  b.ai=nil
  -- the top of a jump: 14 studs up, 12 away
  c:relocate(a,V.new(0,17,10));a.airborne=true
  local health=b.health
  assert(c:request(a,"Attack"),id..": the air opener was refused")
  assert(a.attackName=="WallDive",id..": the air opener is "..tostring(a.attackName).." (it passes over him)")
  for _=1,120 do H.step(c,.01) end
  assert(b.health<health,id..": the dive did not reach him")
 end
end)

test("air dive: close above, or with an air string alive, the air strike stays the air string",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,3),V.new(0,3,-2))
 c:relocate(a,V.new(0,5.5,2.5));a.airborne=true
 assert(c:request(a,"Attack"))
 assert(a.attackName~="WallDive","a dive from arm's length ("..tostring(a.attackName)..")")
 -- a body in the air: no dive at it
 local c2,x,y=H.duel("Lion","Flashstep")
 place(c2,x,y,V.new(0,3,10),V.new(0,3,-2))
 c2:relocate(x,V.new(0,17,10));x.airborne=true
 c2:relocate(y,V.new(0,8,-2));y.airborne=true
 assert(c2:request(x,"Attack"))
 assert(x.attackName~="WallDive","a dive at a body in the air")
end)

test("final blow: the last hit throws the body, slow first, then it comes to rest in the KO pose",function()
 local c,a,b=H.duel("Lion","Mirage")
 place(c,a,b,V.new(0,3,4),V.new(0,3,0))
 b.ai=nil
 local finished=false
 c.match.finish=function() finished=true end
 local Config=H.load("Shared/Config")
 local F=Config.FinalBlow
 b.health=1
 local start=b.root.Position
 c:damage(a,b,20,true)
 assert(finished and b.state=="Defeated","no KO")
 assert(b.koFlight and b.reaction=="Knockdown","the body was not thrown ("..tostring(b.reaction)..")")
 -- the freeze, then the slow part of the flight, then full speed
 for _=1,22 do H.step(c,.01) end
 local p0=b.root.Position
 for _=1,15 do H.step(c,.01) end
 local slow=(b.root.Position-p0).Magnitude
 for _=1,math.floor(F.SlowFor*100)-15+math.floor(F.Ease*100) do H.step(c,.01) end
 local p1=b.root.Position
 for _=1,15 do H.step(c,.01) end
 local fast=(b.root.Position-p1).Magnitude
 assert(slow>0 and fast>slow*1.8,string.format("no slow motion: %.2f then %.2f studs per 0.15 s",slow,fast))
 for _=1,400 do H.step(c,.01);if not b.koFlight then break end end
 assert(not b.koFlight and b.reaction==nil,"the body never came to rest")
 local flat=V.new(b.root.Position.X-start.X,0,b.root.Position.Z-start.Z)
 assert(flat.Magnitude>5 and flat:Dot(V.new(0,0,-1))>0,string.format("thrown %.1f studs, the wrong way?",flat.Magnitude))
end)

print("NinjaDuel air combat: "..passed.." PASS")
