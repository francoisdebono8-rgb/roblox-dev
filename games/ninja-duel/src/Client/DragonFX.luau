-- (13/11, user: « les dragons ça va pas trop, cherche des modèles de dragons
-- en 3D ») Kakashi's Water Dragon and Earth Dragon as modelled meshes:
-- tools/blender/fx_models.py's eastern dragon (a long angular skull under a
-- heavy brow, glaring slit eyes, the mouth open on rows of fangs, horns swept
-- far back, a mane of blades down the neck, long whiskers; a serpent body of
-- scaled segments with a dorsal crest), built by Client/MeshKit at run time.
-- Until the meshes are ready (or headless) build() returns nil and FamilyFX
-- keeps its part-built dragon.
local MeshKit=require(script.Parent.MeshKit)
local DragonFX={}
DragonFX.HEAD_WIDTH=1.3   -- the modelled skull's width for a look of size[1]=1
DragonFX.SEG_SCALE=1.1    -- the first segment against the head
DragonFX.TAPER=.62        -- the last segment is this much thinner

local function absorb(into,model)
	for _,c in model:GetChildren() do c.Parent=into end
	model:Destroy()
end

-- The serpent model FamilyFX's path pose drives: the head (PrimaryPart, its
-- pieces welded to it) and `n` segments, Segment1..n, each an anchored root
-- with its pieces welded.
function DragonFX.build(style,look,n)
	if not (MeshKit.has(style.."DragonHead") and MeshKit.has(style.."DragonSeg")) then return nil end
	local k=look.size[1]/DragonFX.HEAD_WIDTH
	local m=Instance.new("Model");m.Name="FamilySerpent"
	if style=="Earth" then pcall(m.SetAttribute,m,"KeepShadow",true) end
	local head=MeshKit.model(style.."DragonHead")
	head:ScaleTo(k)
	local root=head.PrimaryPart
	root.Name="Head"
	absorb(m,head)
	m.PrimaryPart=root
	for i=1,n do
		local seg=MeshKit.model(style.."DragonSeg")
		seg:ScaleTo(k*DragonFX.SEG_SCALE*(1-(i/n)*DragonFX.TAPER))
		seg:PivotTo(CFrame.new(0,0,i*look.size[3]/(n+1)))
		seg.PrimaryPart.Name="Segment"..i
		absorb(m,seg)
	end
	for _,p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Name~="Head" and not p.Name:match("^Segment") then
			if style=="Water" and p.Material==Enum.Material.Glass then p.Transparency=.14;p.Reflectance=.1 end
			if style=="Earth" then p.CastShadow=p.Material~=Enum.Material.Neon end
		end
	end
	return m
end
return DragonFX
