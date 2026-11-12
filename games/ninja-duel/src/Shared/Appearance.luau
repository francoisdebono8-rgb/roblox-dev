-- The body a fighter is drawn with, apart from the kit it fights with
-- (DEC-036, 12/11: the player's ninja wears a prodigy's kit).
--   * The KIT is the prodigy (Shared/Fighters): stats, moves, jutsu, seals,
--     ultimate, awakening, Blender animations, effects.
--   * The BODY is what the fighter looks like: the costume it is dressed in
--     (Server/Looks, Server/LookMeshes) and its colours. A body is
--     { look = <a prodigy's Name>, skin/hair/outfit/color/iris = optional
--     overrides {r,g,b} }. Every prodigy's own body is his kit's look, so a
--     prodigy is drawn exactly as before.
-- A body for a player's own ninja (the Ōtsutsuki first) comes with AVATAR-001
-- step 3; until then only the prodigies' looks exist.
local Appearance={}

-- The prodigy's own body.
function Appearance.of(def)
	return {look=def.Name}
end

Appearance.COLOURS={"Skin","Hair","Outfit","Color","Iris"}

-- The pieces of a prodigy's look that serve one of his techniques: they go
-- with the KIT, not the body (DEC-036). Matched on the piece's own name
-- (after the body part: "UpperTorso__Gourd" is "Gourd"), by prefix, and only
-- within that prodigy's look. Whether a ninja may use such an item at once or
-- through his build's tree is still to be defined (DEC-036): for now they
-- are only marked (attribute KitItem on the piece).
Appearance.KitItems={
	Sand={"Gourd","Strap"},          -- Gaara's sand comes out of the gourd (and its strap)
	Copycat={"Sheath"},              -- Kakashi's tanto (def.Weapon), sheathed on his back
	Lion={"CurseMark"},              -- Sasuke's curse mark (his awakening spreads it)
	GentleFist={"ByakuganVein"},     -- Neji's Byakugan veins (his eyes' jutsu)
}

local function short(name)
	local tail=string.match(name,"__(.+)$")
	return tail or name
end
function Appearance.isKitItem(kitId,pieceName)
	local list=Appearance.KitItems[kitId]
	if not list or type(pieceName)~="string" then return false end
	local own=short(pieceName)
	for _,prefix in list do
		if string.sub(own,1,#prefix)==prefix then return true end
	end
	return false
end

return Appearance
