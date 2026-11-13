-- (13/11) Gamakichi (Client/ToadFX, parts from tools/blender/fx_toad.py):
-- the timeline the server's shot lands in, and every part in the model.
local H=require("./Harness")
local roblox=require("@lune/roblox")
H.envBase.Instance=roblox.Instance
local ToadFX=H.load("Client/ToadFX")
local Model=H.load("Client/ToadModel")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
test("it hops in, lands, spits on the shot, blinks, and sits still",function()
 assert(ToadFX.pose(.05).lift>.5,"no hop")
 assert(ToadFX.pose(.2).lift<.05,"not landed by the spit")
 assert(ToadFX.pose(.12).cheek>1.4,"cheeks not full before the spit")
 assert(ToadFX.pose(.2).jaw>30,"the jaw does not open on the spit")
 assert(ToadFX.pose(.5).jaw==0,"mouth still open")
 assert(ToadFX.pose(.75).lid==1 and ToadFX.pose(.9).lid==0,"no blink")
 assert(math.abs(ToadFX.pose(1).sy-1)<1e-6,"still squashed")
end)
test("its parts: head, eyes with pupils, cheeks, jaw, vest, four limbs",function()
 local names={}
 for _,p in Model.parts do names[p[1]]=p[2] end
 for _,n in {"Body","Head","Jaw","CheekL","CheekR","EyeL","EyeR","PupilL","PupilR","LidL","LidR","Vest","ArmL","ArmR","ThighL","ThighR","FootL","FootR"} do
  assert(names[n],"missing "..n)
 end
 assert(#Model.parts>=30,"too few parts: "..#Model.parts)
 local cf,size=ToadFX.place(Model.parts[1],ToadFX.pose(1))
 assert(size.X>2 and cf.Position.Y>.5,"the body is not where it stands")
end)
print(passed.." passed")
