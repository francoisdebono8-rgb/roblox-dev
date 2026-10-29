-- Blender-made looks (user 29/10 14:37: "produis les designs sur Blender").
-- tools/blender/look_<name>.py models each costume piece in the rig's rest
-- pose; Studio's 3D importer uploads them; tools/blender/looks_to_luau.py
-- writes Server/LookMeshData (mesh id, body part, rest offset, size, colour)
-- from what Studio imported. At server start each mesh is made once
-- (AssetService:CreateMeshPartAsync); a fighter is dressed by cloning them
-- onto his body parts, and the body parts they replace are hidden.
-- Until the meshes are ready (or where none exist, or headless), the fighter
-- keeps his part-built look (Server/Looks).
local LookMeshes={templates={},state={}}
local ok,Data=pcall(require,script.Parent.LookMeshData)
if not ok then Data={} end
LookMeshes.Data=Data

-- Rest-pose centres of the body parts (matches tools/blender/nd_look.REST).
LookMeshes.Rest={
	LowerTorso=Vector3.new(0,0,0),UpperTorso=Vector3.new(0,1.15,0),Head=Vector3.new(0,2.75,0),
	LeftUpperArm=Vector3.new(-1.24,1.1,0),RightUpperArm=Vector3.new(1.24,1.1,0),
	LeftLowerArm=Vector3.new(-1.24,.1,0),RightLowerArm=Vector3.new(1.24,.1,0),
	LeftHand=Vector3.new(-1.24,-.63,0),RightHand=Vector3.new(1.24,-.63,0),
	LeftUpperLeg=Vector3.new(-.5,-1.05,0),RightUpperLeg=Vector3.new(.5,-1.05,0),
	LeftLowerLeg=Vector3.new(-.5,-2.1,0),RightLowerLeg=Vector3.new(.5,-2.1,0),
	LeftFoot=Vector3.new(-.5,-2.8,-.15),RightFoot=Vector3.new(.5,-2.8,-.15),
}

-- Full detail at any distance (the automatic level of detail thins the hair
-- shells at fighting distance); no physics shape (they never collide).
local OPTIONS=nil
pcall(function() OPTIONS={RenderFidelity=Enum.RenderFidelity.Precise,CollisionFidelity=Enum.CollisionFidelity.Box} end)
-- Make every mesh once, in the background.
function LookMeshes.preload()
	local okService,AssetService=pcall(function() return game:GetService("AssetService") end)
	if not okService or not AssetService or not AssetService.CreateMeshPartAsync then return end
	for fighter,look in Data do
		if LookMeshes.state[fighter] then continue end
		LookMeshes.state[fighter]="loading"
		local made,left,failed={},#look.pieces,false
		for _,piece in look.pieces do
			task.spawn(function()
				local good,part=pcall(function() return AssetService:CreateMeshPartAsync(piece.mesh,OPTIONS) end)
				if not good or not part then
					warn("[LookMeshes] "..fighter.."/"..piece.name..": "..tostring(part))
					failed=true
				else
					made[piece.name]=part
				end
				left-=1
				if left==0 then
					LookMeshes.templates[fighter]=made
					LookMeshes.state[fighter]=if failed then "failed" else "ready"
				end
			end)
		end
	end
end

function LookMeshes.ready(fighter)
	return LookMeshes.state[fighter]=="ready"
end

local KEEP={CurseMark=true,ByakuganVein=true,FaceEye=true,FaceMouth=true,TearLine=true,LoveMark=true}
-- Dress `model` with the meshes of `fighter`. Returns true when it did.
function LookMeshes.dress(model,fighter)
	local look=Data[fighter]
	local made=LookMeshes.templates[fighter]
	if not look or not made then return false end
	for _,piece in look.pieces do
		local body=model:FindFirstChild(piece.body)
		local template=made[piece.name]
		if body and template then
			local p=template:Clone()
			p.Name=piece.name
			p.Size=piece.size
			p.Color=piece.color
			p.Material=Enum.Material[piece.material or "SmoothPlastic"] or Enum.Material.SmoothPlastic
			p.Reflectance=piece.reflectance or 0
			p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true
			p.CastShadow=piece.body~="Head"
			p.CFrame=body.CFrame*CFrame.new(piece.offset)
			local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=p;weld.Parent=p
			p.Parent=model
		end
	end
	-- The body parts the meshes replace (their own meshes stay for hits).
	for _,name in look.hide or {} do
		local part=model:FindFirstChild(name)
		if part and part:IsA("BasePart") then part.Transparency=1 end
	end
	-- The part-built costume underneath goes, except what effects drive
	-- (curse marks, Byakugan veins) and the drawn face.
	for _,p in model:GetChildren() do
		if p:GetAttribute("LookPiece") and not KEEP[p.Name] then p:Destroy() end
	end
	model:SetAttribute("LookMeshes",fighter)
	return true
end

return LookMeshes
