-- SyphoDev's step "read the real joints straight out of Studio through the MCP", for a
-- Ninja Duel fighter as the game builds it (World.rig + the look, e.g. Looks.form moves
-- the shoulders in and the head up). Run on the SERVER of a Play session after
-- studio_parity.py's proof (it reads workspace.SyphoProof), then:
--   python3 tools/syphodev/rig_from_studio.py <this output>.json tools/syphodev/rig.json > tools/syphodev/rig_prodigy.json
local model=workspace.SyphoProof:FindFirstChildWhichIsA("Model")
local BODY={LowerTorso=1,UpperTorso=1,Head=1,LeftUpperArm=1,LeftLowerArm=1,LeftHand=1,RightUpperArm=1,RightLowerArm=1,RightHand=1,LeftUpperLeg=1,LeftLowerLeg=1,LeftFoot=1,RightUpperLeg=1,RightLowerLeg=1,RightFoot=1}
local function r(x) return math.round(x*1e4)/1e4 end
local function cf(c) local a={c:GetComponents()} return {pos={r(a[1]),r(a[2]),r(a[3])},rows={{r(a[4]),r(a[5]),r(a[6])},{r(a[7]),r(a[8]),r(a[9])},{r(a[10]),r(a[11]),r(a[12])}}} end
local joints,sizes={},{}
for _,m in model:GetDescendants() do
	if m:IsA("Motor6D") and BODY[m.Part1.Name] then
		table.insert(joints,{name=m.Name,part0=m.Part0.Name,part1=m.Part1.Name,c0=cf(m.C0),c1=cf(m.C1)})
		sizes[m.Part1.Name]={r(m.Part1.Size.X),r(m.Part1.Size.Y),r(m.Part1.Size.Z)}
	end
end
local hum=model:FindFirstChildOfClass("Humanoid")
return game:GetService("HttpService"):JSONEncode({joints=joints,sizes=sizes,hip=hum and hum.HipHeight,root=model.HumanoidRootPart.Size.Y})
