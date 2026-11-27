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

-- (DEV 21/11) imported on François's account from Studio (Asset Manager,
-- Bulk Import of assets/ui as of 19/11 21:34 and the ranks of 20/11).
UIAssets.Ids={
	paper_9s="rbxassetid://96557098673588",paper_tag_9s="rbxassetid://128518797984833",ink_frame_9s="rbxassetid://110463142050487",ink_band="rbxassetid://73718153326665",brush_bar_9s="rbxassetid://116254489320257",
	brush_circle="rbxassetid://99363250241517",brush_underline="rbxassetid://139920188372939",halftone_tile="rbxassetid://110397643533757",stamp_done="rbxassetid://134849824022175",stamp_approved="rbxassetid://92849872134248",
	icon_kunai="rbxassetid://107771325383116",icon_bolt="rbxassetid://138667456418512",icon_mark="rbxassetid://132652472551085",icon_wind="rbxassetid://121068638488224",icon_flash="rbxassetid://82486091204126",icon_fire="rbxassetid://90908948208435",icon_spiral="rbxassetid://121718194314485",
	icon_clone="rbxassetid://77991194608108",icon_sand="rbxassetid://119363163246440",icon_eye="rbxassetid://74790222719132",icon_palm="rbxassetid://72571792235496",icon_water="rbxassetid://117206324242407",icon_whirl="rbxassetid://136664861817810",icon_shuriken="rbxassetid://87250287926119",
	icon_fist="rbxassetid://85528747736674",icon_weights="rbxassetid://98116083608228",icon_hound="rbxassetid://114057950243756",icon_wire="rbxassetid://107945352265218",icon_scroll="rbxassetid://126004677920473",
	-- (DESIGN 20/11, step 1) the six ranks' emblems
	rank_academy="rbxassetid://96672557663526",rank_genin="rbxassetid://76763443822026",rank_chunin="rbxassetid://118229760694098",rank_jonin="rbxassetid://93794886301905",rank_anbu="rbxassetid://118433227657883",rank_kage="rbxassetid://88298397406708",
	-- (DESIGN 26/11, passe 2) Konoha, the drawn map (assets/ui/map_konoha.png, 1160 x 956): to upload
	map_konoha="",
	-- (DESIGN 27/11) the painted skill trees (assets/ui/trees, generate_tree.py), two halves each: to upload
	tree_Copycat_top="",tree_Copycat_bottom="",tree_Flashstep_top="",tree_Flashstep_bottom="",tree_GentleFist_top="",tree_GentleFist_bottom="",tree_Leaf_top="",tree_Leaf_bottom="",tree_Legion_top="",tree_Legion_bottom="",tree_Lion_top="",tree_Lion_bottom="",tree_Mirage_top="",tree_Mirage_bottom="",tree_Sand_top="",tree_Sand_bottom="",tree_Ninja_top="",tree_Ninja_bottom="",
}

-- (DEV 21/11) the shop icons (assets/ui/items, rendered by tools/icons),
-- imported with them: UIAssets.item(itemId).
UIAssets.Items={
	ArmsGuards="rbxassetid://82820226049059",
	ArmsWraps="rbxassetid://81118167398500",
	BottomPantsDark="rbxassetid://92132720668234",
	BottomPantsSand="rbxassetid://107112566014496",
	BottomShorts="rbxassetid://126025901211120",
	FeetBlack="rbxassetid://120433988957607",
	FeetSandals="rbxassetid://92386250951277",
	GourdClay="rbxassetid://85681073710129",
	GourdLacquer="rbxassetid://136087073848819",
	HeadbandBlack="rbxassetid://90231499922763",
	HeadbandBlue="rbxassetid://93184874565785",
	HeadbandRed="rbxassetid://123910486696190",
	KunaiBlack="rbxassetid://116718021531869",
	KunaiGold="rbxassetid://72075370368644",
	KunaiSteel="rbxassetid://131959028856347",
	KunaiVermilion="rbxassetid://86641976469614",
	SetGaara="rbxassetid://77779881926312",
	SetItachi="rbxassetid://84582433603722",
	SetKakashi="rbxassetid://90252767745129",
	SetLee="rbxassetid://98327667614072",
	SetMinato="rbxassetid://75347881081146",
	SetNaruto="rbxassetid://111775631629809",
	SetNeji="rbxassetid://91525411431261",
	SetSasuke="rbxassetid://76358035909454",
	ShurikenBlack="rbxassetid://92077396912337",
	ShurikenSteel="rbxassetid://116948001287956",
	TantoShadow="rbxassetid://115002886108270",
	TantoWhite="rbxassetid://104441377960631",
	TopHighCollar="rbxassetid://118837321053797",
	TopSleeveless="rbxassetid://120806364631465",
	TopTunicBlack="rbxassetid://140613428876910",
	TopTunicGreen="rbxassetid://93560977470474",
	TopTunicNavy="rbxassetid://82681059671888",
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

-- The icon of a shop item, or nil while it is not imported.
function UIAssets.item(itemId:string?):string?
	local id=itemId and UIAssets.Items[itemId]
	if type(id)=="string" and id~="" then return id end
	return nil
end

function UIAssets.iconName(techniqueId:string?):string
	return "icon_"..((techniqueId and UIAssets.TechniqueIcon[techniqueId]) or "scroll")
end

-- (DESIGN 20/11, step 1) The six ranks, lowest first: their name and the
-- emblem's colours (the drawing's fallback while the image is not imported).
UIAssets.Ranks={
	{id="academy",name="ACADEMY",fill=Color3.fromRGB(201,154,91),ink=Color3.fromRGB(20,16,17)},
	{id="genin",name="GENIN",fill=Color3.fromRGB(185,194,204),ink=Color3.fromRGB(20,16,17)},
	{id="chunin",name="CHUNIN",fill=Color3.fromRGB(94,138,74),ink=Color3.fromRGB(244,227,193)},
	{id="jonin",name="JONIN",fill=Color3.fromRGB(47,74,58),ink=Color3.fromRGB(244,227,193)},
	{id="anbu",name="ANBU",fill=Color3.fromRGB(242,239,232),ink=Color3.fromRGB(20,16,17)},
	{id="kage",name="KAGE",fill=Color3.fromRGB(195,18,29),ink=Color3.fromRGB(255,194,61)},
}
-- A rank by its id or its name (any case), or nil.
function UIAssets.rank(key:any):any
	if type(key)=="number" then return UIAssets.Ranks[key] end
	if type(key)=="table" then key=key.id end -- Shared/Ranked's {id="Genin",…}
	if type(key)~="string" then return nil end
	local k=string.lower(key)
	for i,r in UIAssets.Ranks do if r.id==k then return r,i end end
	return nil
end

return UIAssets
