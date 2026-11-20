-- (20/11, étape 1 ANIMATEUR 3) The merit auras (Client/MeritAuraFX): three tiers on a real R15
-- body, each richer than the last, at the feet and the outline (never on the face), quieter in
-- a duel, gone without a trace when removed, and nothing for tier 0 or a model without a body.
local H=require("./Harness")
local roblox=require("@lune/roblox")
for _,k in {"Instance","Vector3","Color3","CFrame","Enum","ColorSequence","ColorSequenceKeypoint","NumberSequence",
	"NumberSequenceKeypoint","NumberRange","Vector2"} do H.envBase[k]=roblox[k] end
local Aura=H.load("Client/MeritAuraFX")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end

local PARTS={HumanoidRootPart={2,2,1},Head={1.2,1.2,1.2},UpperTorso={2,1.6,1},LowerTorso={2,.4,1},
	RightUpperArm={1,1.169,1},LeftUpperArm={1,1.169,1},RightLowerArm={1,1.052,1},LeftLowerArm={1,1.052,1},
	RightHand={1,.3,1},LeftHand={1,.3,1},RightUpperLeg={1,1.217,1},LeftUpperLeg={1,1.217,1},
	RightLowerLeg={1,1.193,1},LeftLowerLeg={1,1.193,1},RightFoot={1,.3,1},LeftFoot={1,.3,1}}
local function body()
	local m=roblox.Instance.new("Model")
	for name,s in PARTS do
		local p=roblox.Instance.new("Part");p.Name=name;p.Size=roblox.Vector3.new(s[1],s[2],s[3]);p.Parent=m
	end
	return m
end
local function count(m)
	local n,on={},{}
	for _,d in m:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			table.insert(n,d)
			local host=if d.Parent:IsA("Attachment") then d.Parent.Parent else d.Parent
			on[host.Name]=true
		end
	end
	return n,on
end

test("three tiers, each with more on the body than the last, never on the head",function()
	local last=0
	for t=1,3 do
		local m=body()
		assert(Aura.wear(m,t),"tier "..t.." built nothing")
		local list,on=count(m)
		assert(#list>last,("tier %d: %d emitters, not more than tier %d (%d)"):format(t,#list,t-1,last))
		assert(not on.Head,"tier "..t.." puts chakra on the face")
		assert(on.RightFoot and on.LeftFoot,"tier "..t..": the feet carry it")
		assert(m:GetAttribute("MeritAura")==Aura.TIERS[t].id)
		last=#list
	end
	assert(#Aura.TIERS==3)
	assert(Aura.TIERS[1].suggestedWins<Aura.TIERS[2].suggestedWins and Aura.TIERS[2].suggestedWins<Aura.TIERS[3].suggestedWins)
end)

test("quiet in a duel: a third of the particles, the full rate back after",function()
	local m=body()
	Aura.wear(m,3)
	local list=count(m)
	local full={}
	for i,e in list do full[i]=e.Rate end
	Aura.setQuiet(m,true)
	for i,e in list do assert(math.abs(e.Rate-full[i]*Aura.QUIET)<1e-3,"not quieter") end
	Aura.setQuiet(m,false)
	for i,e in list do assert(math.abs(e.Rate-full[i])<1e-3,"rate not restored") end
	local q=body()
	Aura.wear(q,2,true)
	for _,e in count(q) do assert(e.Rate<=(e:GetAttribute("MeritRate") or 0)*Aura.QUIET+1e-3,"worn quiet") end
end)

test("removed or replaced: nothing left on the body",function()
	local m=body()
	Aura.wear(m,3)
	Aura.wear(m,1)
	local list=count(m)
	local one=body();Aura.wear(one,1)
	assert(#list==#count(one),"a lower tier kept the higher one's pieces")
	Aura.remove(m)
	assert(#count(m)==0,"emitters left after remove")
	for _,d in m:GetDescendants() do assert(not d:IsA("PointLight") and not d:IsA("Attachment"),"left "..d.ClassName) end
	assert(m:GetAttribute("MeritAura")==nil)
	assert(Aura.wear(body(),0)==nil and Aura.wear(nil,2)==nil)
end)

print(("NinjaDuel merit auras: %d PASS"):format(passed))
