-- (12/11) The game casts shadows now (DEV light pass). Light does not cast a
-- shadow: a fireball, a bolt, a sand stream in the air, a halo or an aura
-- that throws a black shape on the floor reads as a solid object. Rocks and
-- debris do (they are solid, their shadow is what puts them on the floor).
--
-- One rule for every effect, whatever module made it:
--   * every BasePart under the effects folder (workspace.NinjaDuelFX) gets
--     CastShadow = false the moment it is parented there - the parts made
--     through Effects' block() already were, the guard catches the ones made
--     by hand (Instance.new / K.new("Part") default to true);
--   * unless it, or a model it is in, carries the attribute KeepShadow: rocks,
--     pebbles, debris, slabs, the earth spike, the substitution log, the ninja
--     hounds. ShadowFX.keep(part) sets the attribute and the shadow.
-- Parts an effect puts on a fighter's body go through block() (no shadow);
-- the body itself is never touched (it is not under the effects folder).
local ShadowFX={}
ShadowFX.ATTRIBUTE="KeepShadow"
local function kept(part,root)
	local node=part
	while node and node~=root do
		if node:GetAttribute(ShadowFX.ATTRIBUTE) then return true end
		node=node.Parent
	end
	return false
end
function ShadowFX.apply(part,root)
	if not part:IsA("BasePart") then return end
	local keep=kept(part,root)
	if part.CastShadow~=keep then part.CastShadow=keep end
end
-- A solid effect (rock, debris): it keeps its shadow.
function ShadowFX.keep(part)
	if typeof(part)~="Instance" then return part end
	pcall(function()
		part:SetAttribute(ShadowFX.ATTRIBUTE,true)
		if part:IsA("BasePart") then part.CastShadow=true end
		for _,d in part:GetDescendants() do if d:IsA("BasePart") then d.CastShadow=true end end
	end)
	return part
end
-- A light effect made outside the effects folder (anchors under workspace).
function ShadowFX.light(part)
	if typeof(part)=="Instance" and part:IsA("BasePart") then part.CastShadow=false end
	return part
end
local watched=setmetatable({},{__mode="k"})
function ShadowFX.watch(root)
	if not root or watched[root] then return end
	watched[root]=true
	for _,d in root:GetDescendants() do ShadowFX.apply(d,root) end
	pcall(function()
		root.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then ShadowFX.apply(d,root) end
		end)
	end)
	return root
end
return ShadowFX
