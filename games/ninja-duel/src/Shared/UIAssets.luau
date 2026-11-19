--!strict
-- (DESIGN, DA v3, 15/11) The images of the manga page: paper, ink frames,
-- brush strokes, stamps and the jutsu pictograms. Their PNGs live in
-- games/ninja-duel/assets/ui (made by generate_ui_assets.py and
-- generate_icons.py). For them to show, each is imported once on François's
-- Roblox account (Studio, Asset Manager > Import; his agreement: 14/11) and
-- its id written below as "rbxassetid://…". An empty id means "not
-- imported yet": every screen then draws a plain fallback (flat colour,
-- UIStroke, a short word in place of a pictogram), so nothing breaks.
local UIAssets={}

UIAssets.Ids={
	paper_9s="",paper_tag_9s="",ink_frame_9s="",ink_band="",brush_bar_9s="",
	brush_circle="",brush_underline="",halftone_tile="",stamp_done="",stamp_approved="",
	icon_kunai="",icon_bolt="",icon_mark="",icon_wind="",icon_flash="",icon_fire="",icon_spiral="",
	icon_clone="",icon_sand="",icon_eye="",icon_palm="",icon_water="",icon_whirl="",icon_shuriken="",
	icon_fist="",icon_weights="",icon_hound="",icon_wire="",icon_scroll="",
}

-- The 9-slice centre of each frame image (ScaleType Slice, SliceCenter).
-- (Rect is absent from the headless tests: no slice there, no image either)
local function rect(a:number,b:number,c:number,d:number):any
	local R=(Rect::any)
	return if R then R.new(a,b,c,d) else nil
end
UIAssets.Slice={
	paper_9s=rect(32,32,224,224),
	paper_tag_9s=rect(24,24,104,232),
	ink_frame_9s=rect(32,32,224,224),
	ink_band=rect(48,0,464,96),
	brush_bar_9s=rect(28,0,228,40),
}

-- Each jutsu's pictogram (no kanji: François, 14/11). A jutsu not listed
-- takes the scroll.
UIAssets.TechniqueIcon={
	MarkedBlade="kunai",NeedleFan="shuriken",SandShuriken="shuriken",WireTrap="wire",
	LightningStrike="bolt",LightningCut="bolt",LightningBlade="bolt",Chidori="bolt",
	Flashstep="mark",MirageCast="eye",Read="eye",ByakuganSight="eye",
	WindCut="wind",GreatGust="wind",Kamaitachi="wind",Cyclone="whirl",LeafGreatWhirlwind="whirl",Rotation="whirl",ProtectiveTrigrams="whirl",
	FireBloom="fire",PhoenixFlower="fire",CloneRasengan="spiral",
	ShadowClone="clone",MassShadowClone="clone",
	SandArmor="sand",SandCoffin="sand",DesertWave="sand",
	VacuumPalm="palm",SixtyFourPalms="palm",
	WaterDragon="water",TrackingFang="hound",RemoveWeights="weights",
	NarutoRendan="fist",PrimaryLotus="fist",TwinLionFists="fist",DynamicEntry="fist",
}

-- The id of an image, or nil while it is not imported.
function UIAssets.id(name:string):string?
	local id=UIAssets.Ids[name]
	if type(id)=="string" and id~="" then return id end
	return nil
end

function UIAssets.iconName(techniqueId:string?):string
	return "icon_"..((techniqueId and UIAssets.TechniqueIcon[techniqueId]) or "scroll")
end

return UIAssets
