-- The ninja outfit's modelled pieces on every avatar this screen sees (DEC-040;
-- the ANIMATEUR's models, Shared/OutfitMeshes, PR #111). The server dresses an
-- avatar with cloth pieces (Server/Outfit: a holder "NinjaOutfit" whose
-- attribute lists the items); here each piece the item has a model for is
-- built once (Client/MeshKit, an EditableMesh baked into content: nothing to
-- upload), then put on: scaled by the body part's size over the standard
-- R15 part's (Ref), welded at body.CFrame * (o scaled), painted with the
-- item's colour slot (the vertex colours are shading). The server's cloth
-- pieces then hide on this screen only. No model, or no AssetService
-- (headless, a failed build): the cloth pieces stay.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Shop=require(Shared.Shop)
local okMeshes,OutfitMeshes=pcall(require,Shared.OutfitMeshes)
local MeshKit=require(script.Parent.MeshKit)
local Dress={templates={},building={},dressed=setmetatable({},{__mode="k"})}

local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end

-- (19/11, seen in Studio) Under the game's darker light (12/11) the Fabric
-- material reads near-black whatever its colour: a sand tunic, a green one and
-- Naruto's orange all came out as dark knit, beside prodigies dressed in
-- SmoothPlastic. A cloth piece wears the prodigies' material, its colour shows.
Dress.MATERIAL={[Enum.Material.Fabric]=Enum.Material.SmoothPlastic}
function Dress.material(m) return Dress.MATERIAL[m] or m end
-- An item's colour for a slot: the Shop's, else the model's new slot.
function Dress.color(item,model,slot)
	local c=item and item.colors and item.colors[slot]
	if not c and okMeshes and OutfitMeshes.NewSlots[model] then c=OutfitMeshes.NewSlots[model][slot] end
	return c and rgb(c) or Color3.fromRGB(128,128,128)
end

-- Where a piece goes on `body`: its size and its CFrame (the contract of
-- Shared/OutfitMeshes).
-- (15/11, François: « les tenues ne s'adaptent pas aux personnages », the
-- pieces measured against their parts) A coat's tails, a robe's skirt hang
-- from the hips (LowerTorso) down along the legs, about four times the hips'
-- own height: scaled by the hips alone, they came out one and a half to two
-- and a half times too long on the avatars whose hips are thicker than the
-- standard 0.4 (most bundles), and that far too low. The part of such a piece
-- above the hips' bottom still follows the hips; the part below follows the
-- legs (upper + lower leg against the standard's). `character`: the body's
-- model (its legs); without it, the hips alone, as before.
local LEGS={"RightUpperLeg","RightLowerLeg"}
function Dress.legScale(character)
	if not character or not okMeshes then return nil end
	local have,want=0,0
	for _,name in LEGS do
		local leg=character:FindFirstChild(name)
		local ref=OutfitMeshes.Ref[name]
		if not (leg and leg:IsA("BasePart") and ref) then return nil end
		have+=leg.Size.Y;want+=ref.Y
	end
	return have/want
end
function Dress.place(body,on,size,o,character)
	local ref=okMeshes and OutfitMeshes.Ref[on]
	if not ref then return nil end
	local k=Vector3.new(body.Size.X/ref.X,body.Size.Y/ref.Y,body.Size.Z/ref.Z)
	local bottom=o.Y-size.Y/2+ref.Y/2
	local legs=if bottom<-.05 and on=="LowerTorso" then Dress.legScale(character) else nil
	if not legs then return size*k,body.CFrame*CFrame.new(o*k) end
	-- heights from the hips' bottom (standard units), then on this body
	local top=o.Y+size.Y/2+ref.Y/2
	local newTop=if top>0 then top*k.Y else top*legs
	local newBottom=bottom*legs
	local height=newTop-newBottom
	local y=-body.Size.Y/2+(newTop+newBottom)/2
	return Vector3.new(size.X*k.X,height,size.Z*k.Z),body.CFrame*CFrame.new(o.X*k.X,y,o.Z*k.Z)
end

-- The templates of a model, built once (yields): {part, on, slot, o}, or nil.
function Dress.template(model)
	local t=Dress.templates[model]
	if t then return if t==false then nil else t end
	if Dress.building[model] then
		while Dress.building[model] do task.wait() end
		return Dress.templates[model] or nil
	end
	Dress.building[model]=true
	local made={}
	local ok=pcall(function()
		for _,spec in OutfitMeshes.Models[model] do
			local part=MeshKit.build(spec)
			table.insert(made,{part=part,on=spec.on,slot=spec.slot,o=Vector3.new(spec.o[1],spec.o[2],spec.o[3])})
		end
	end)
	Dress.templates[model]=if ok and #made>0 then made else false
	Dress.building[model]=nil
	return Dress.templates[model] or nil
end

-- Dresses the body that holds `holder` (a server "NinjaOutfit"); returns the
-- number of pieces put on.
function Dress.wear(holder)
	if not okMeshes then return 0 end
	local body=holder.Parent
	if not body then return 0 end
	local ids=string.split(holder:GetAttribute("NinjaOutfit") or "",",")
	local folder=Instance.new("Folder");folder.Name="NinjaOutfitMesh"
	local n=0
	local modelled={}
	for _,id in ids do
		local model=OutfitMeshes.Items[id]
		local item=Shop.item(id)
		local t=model and Dress.template(model)
		if t and holder.Parent==body then
			modelled[id]=true
			for _,entry in t do
				local part=body:FindFirstChild(entry.on)
				if part and part:IsA("BasePart") then
					local size,cf=Dress.place(part,entry.on,entry.part.Size,entry.o,body)
					if size then
						local p=entry.part:Clone()
						p.Size=size;p.CFrame=cf
						p.Anchored=false;p.Massless=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
						p.Color=Dress.color(item,model,entry.slot)
						p.Material=Dress.material(p.Material)
						local w=Instance.new("WeldConstraint");w.Part0=part;w.Part1=p;w.Parent=p
						p.Parent=folder
						n+=1
					end
				end
			end
		end
	end
	if n==0 or holder.Parent~=body then folder:Destroy() return 0 end
	folder.Parent=body
	-- the server's cloth pieces of the items now modelled: hidden here (19/11:
	-- only those; a look without a model, a cape, a scroll, stays in cloth)
	local function hide(piece)
		local of=piece:GetAttribute("NinjaItem")
		if piece:IsA("BasePart") and (of==nil or modelled[of]) then piece.LocalTransparencyModifier=1 end
	end
	for _,piece in holder:GetChildren() do hide(piece) end
	holder.ChildAdded:Connect(hide)
	Dress.dressed[holder]=folder
	-- re-dressed by the server (the old holder goes): this one goes too
	holder.Destroying:Connect(function() if folder.Parent then folder:Destroy() end end)
	holder.AncestryChanged:Connect(function(_,parent) if parent==nil and folder.Parent then folder:Destroy() end end)
	return n
end

-- Watches the world: every outfit holder the server makes is dressed.
function Dress.start()
	if not okMeshes then return end
	local function seen(d)
		if d.Name=="NinjaOutfit" and d:IsA("Model") and d:GetAttribute("NinjaOutfit") and not Dress.dressed[d] then
			Dress.dressed[d]=true
			task.spawn(function() pcall(Dress.wear,d) end)
		end
	end
	workspace.DescendantAdded:Connect(seen)
	for _,d in workspace:GetDescendants() do seen(d) end
end

return Dress
