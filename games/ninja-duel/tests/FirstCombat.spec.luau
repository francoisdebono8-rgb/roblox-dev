-- The first combat (21/11, DEC-047): a beginner who only walks to him,
-- mashes the strike and now and then presses his signature beats the novice
-- (AI "first", Server/Coach's handicap) for every kit of the beta, in one
-- round of under 90 s, and meets at least three of the coach's prompts on the
-- way. The OUTILLEUR's robot débutant measures the same in Studio.
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
H.load("Shared/Config").DamageScale=H.GameDamageScale
local AI=H.load("Server/AI")
local Coach=H.load("Server/Coach")
local FirstMinute=H.load("Shared/FirstMinute")
local passed=0
for _,me in {"Lion","Legion","Leaf","Flashstep","Mirage","GentleFist","Copycat","Sand"} do
 local rival=FirstMinute.rival(me)
 local c,a,b,match=H.duel(me,rival)
 c:relocate(a,V.new(0,3,12));c:relocate(b,V.new(0,3,-12))
 local s={human=a,bot=b,combat=c}
 Coach.new(s,c.now)
 local ai=AI.new(c,b,7,"first")
 local t,presses=0,0
 local seen={}
 while match.phase=="Duel" and t<120 do
  ai:update(c.now)
  -- a beginner: walks to him, mashes the strike when close, sometimes the jutsu
  local d=b.root.Position-a.root.Position
  local flat=V.new(d.X,0,d.Z)
  if flat.Magnitude>3.6 then a.move=flat.Unit else a.move=V.zero end
  if flat.Magnitude<4.5 and math.floor(t/.25)~=math.floor((t-.02)/.25) then c:request(a,"Attack");presses+=1 end
  if math.floor(t/4)~=math.floor((t-.02)/4) then c:request(a,"Technique2",b.root.Position) end
  Coach.update(s,c.now,.02)
  if s.coach.current then seen[s.coach.current.id]=true end
  H.step(c,.02);t+=.02
 end
 local ids={} for id in seen do table.insert(ids,id) end
 table.sort(ids)
 local line=string.format("%-10s vs %-10s %5.1fs  winner %s  me %.0f/%.0f  him %.0f  prompts %s",me,rival,t,tostring(match.winner),a.health,a.def.Health,b.health,table.concat(ids,","))
 assert(match.winner=="A",line..": the beginner did not win")
 assert(t<90,line..": the first combat is too long")
 assert(t>15,line..": too short for the prompts")
 assert(#ids>=3,line..": fewer than three prompts")
 passed+=1
 print("PASS "..line)
end
print(string.format("NinjaDuel the first combat (DEC-047): %d PASS",passed))
-- With the reduced start (DEC-045) the prompt names a technique he has.
do
	local SkillBuilds=H.load("Server/SkillBuilds")
	for _,me in {"Lion","Legion","Leaf"} do
		local kit=assert(SkillBuilds.build(me,{},{gated=true}))
		local c,a=H.duel(me,FirstMinute.rival(me),{A=kit})
		local spec=Coach.signature(a)
		assert(spec and not spec.Locked,me..": the coach names a technique still to learn")
	end
	print("PASS the coach's signature is a technique of the reduced start")
end
