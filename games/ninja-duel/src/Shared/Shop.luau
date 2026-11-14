-- The shop and the Ryō (13/11, user: « on voit tout ce qui est boutique, UI,
-- design, […] les armes »; design board « Ninja Duel : boutique, arbres et
-- armes »). One rule, from DEC-024 and DEC-037: the shop sells time and style,
-- never the duel. Two money:
--   * Ryō, earned by playing (Shop.Ryo): looks — weapon looks and the ninja
--     pieces worn over the player's own avatar;
--   * Robux: time (a kit at once, 2x mastery), status (VIP), early access,
--     the rarest looks, and Ryō packs. The Roblox ids are created by the
--     owner on the game's page (Config.Shop); until then those offers are
--     shown "SOON" and nothing is sold.
-- Never sold: a win, a tree point, a kit by chance. A look changes no number.
-- Shared: the server prices and grants (Server/ProfileSchema, Progression),
-- the client draws the shop (Client/ShopPanel) and the looks (Effects).
local Shop={}

-- Ryō earned by a decided duel (not practice, not a watched match).
Shop.Ryo={Finished=20,Won=30,FirstWinOfDay=2,MasterWon=150,Champion=300,Finalist=150}
Shop.MaxRyo=100000000

-- Slots: what a look dresses. Weapon looks follow the kit (a gourd look shows
-- only on Gaara's kit); `kit` names the kit a look is for.
Shop.Slots={
	kunai={name="KUNAI",kind="weapon"},
	shuriken={name="SHURIKEN",kind="weapon"},
	tanto={name="TANTO",kind="weapon",kit="Copycat"},
	gourd={name="GOURD",kind="weapon",kit="Sand"},
	headband={name="HEADBAND",kind="style"},
	-- (DEC-040, user 14/11: « il arrive genre nu et on ait un petit truc de
	-- customisation de personnage ») The ninja outfit over his own avatar
	-- (Server/Outfit): nothing until he chooses (`outfit`: no default piece);
	-- a master's outfit (`set`) dresses the whole body over the others.
	set={name="INSPIRATION'S OUTFIT",kind="style",outfit=true},
	top={name="TOP",kind="style",outfit=true},
	bottom={name="BOTTOM",kind="style",outfit=true},
	arms={name="ARMS",kind="style",outfit=true},
	feet={name="FEET",kind="style",outfit=true},
}
-- (Lee's weights get their look once their Blender model exists.)
Shop.SlotOrder={"kunai","shuriken","tanto","gourd","headband","set","top","bottom","arms","feet"}
Shop.OutfitSlots={"top","bottom","arms","feet"}

-- (14/11, François: « tout ce qu'il y a dans la boutique, c'est des Robux. Et
-- on va créer une boutique propre au jeu avec des Ryō […] la boutique, c'est
-- vraiment pour que je gagne de l'argent ») Two counters: the SHOP sells for
-- Robux (`robux`); the market of Konoha sells for Ryō (`ryo`), what a player
-- earns in duels. A look has one price, so one counter (Shop.counter).
-- The catalogue. `ryo` = price in Ryō; `robux` = the key of a Developer
-- Product in Config.Shop.Products (no id there: not on sale yet); `base` =
-- what everyone has from the start. `colors` = how the look paints the
-- object's parts (Client/Effects.paint: Blade, Grip, Ring; the gourd's Body;
-- the headband's Band and Plate, Server/Headband).
Shop.Items={
	{id="KunaiSteel",slot="kunai",name="KONOHA STEEL",base=true,colors={Blade={200,204,210},Grip={58,53,64},Ring={200,204,210}}},
	{id="KunaiBlack",slot="kunai",name="BLACK KUNAI",ryo=1500,colors={Blade={42,40,48},Grip={190,40,36},Ring={42,40,48}}},
	{id="KunaiVermilion",slot="kunai",name="VERMILION KUNAI",ryo=1200,colors={Blade={190,40,36},Grip={240,232,212},Ring={190,40,36}}},
	{id="KunaiGold",slot="kunai",name="MARKED GOLD KUNAI",robux="KunaiGold",colors={Blade={230,184,86},Grip={18,16,22},Ring={230,184,86}}},
	{id="ShurikenSteel",slot="shuriken",name="STEEL SHURIKEN",base=true,colors={Blade={200,204,210}}},
	{id="ShurikenBlack",slot="shuriken",name="BLACK SHURIKEN",ryo=1500,colors={Blade={42,40,48}}},
	{id="TantoWhite",slot="tanto",name="WHITE LIGHT",base=true,colors={Blade={236,240,246},Grip={40,40,46}}},
	{id="TantoShadow",slot="tanto",name="SHADOW EDGE",robux="TantoShadow",colors={Blade={58,52,72},Grip={18,16,22}}},
	{id="GourdClay",slot="gourd",name="CLAY GOURD",base=true,colors={Body={176,120,78}}},
	{id="GourdLacquer",slot="gourd",name="LACQUERED GOURD",ryo=2000,colors={Body={142,42,34}}},
	{id="HeadbandBlue",slot="headband",name="KONOHA HEADBAND",base=true,colors={Band={46,64,120},Plate={200,204,210}}},
	{id="HeadbandBlack",slot="headband",name="BLACK HEADBAND",ryo=800,colors={Band={24,22,28},Plate={200,204,210}}},
	{id="HeadbandRed",slot="headband",name="RED HEADBAND",ryo=800,colors={Band={170,40,34},Plate={200,204,210}}},
	{id="HeadbandNone",slot="headband",name="NO HEADBAND",base=true,none=true},
	-- (DEC-040) The outfit. `pieces` (Server/Outfit): what each piece covers
	-- of the avatar's body, `on` a part (UpperArm = both sides), `h` the share
	-- of its height from the top (`y0` where it starts), `pad` how far out.
	-- Free pieces to start (`base`), one colour each.
	{id="TopTunicNavy",slot="top",name="GENIN TUNIC • NAVY",base=true,colors={Cloth={40,48,78}},
		pieces={{on="UpperTorso",c="Cloth"},{on="LowerTorso",c="Cloth",h=.6},{on="UpperArm",c="Cloth",h=.55}}},
	{id="TopTunicBlack",slot="top",name="GENIN TUNIC • BLACK",base=true,colors={Cloth={30,30,36}},
		pieces={{on="UpperTorso",c="Cloth"},{on="LowerTorso",c="Cloth",h=.6},{on="UpperArm",c="Cloth",h=.55}}},
	{id="TopTunicGreen",slot="top",name="GENIN TUNIC • FOREST",base=true,colors={Cloth={52,74,52}},
		pieces={{on="UpperTorso",c="Cloth"},{on="LowerTorso",c="Cloth",h=.6},{on="UpperArm",c="Cloth",h=.55}}},
	{id="TopHighCollar",slot="top",name="HIGH COLLAR",base=true,colors={Cloth={34,44,92},Collar={34,44,92}},
		pieces={{on="UpperTorso",c="Cloth"},{on="LowerTorso",c="Cloth",h=.6},{on="UpperArm",c="Cloth",h=.4},{on="UpperTorso",kind="collar",c="Collar"}}},
	{id="TopSleeveless",slot="top",name="SLEEVELESS TOP",base=true,colors={Cloth={70,66,64},Belt={150,40,36}},
		pieces={{on="UpperTorso",c="Cloth"},{on="LowerTorso",c="Cloth",h=.45},{on="LowerTorso",kind="band",c="Belt",y0=.4,h=.2}}},
	{id="BottomPantsDark",slot="bottom",name="TIED PANTS • DARK",base=true,colors={Cloth={36,38,50},Tie={210,206,196}},
		pieces={{on="LowerTorso",c="Cloth",y0=.4,h=.6},{on="UpperLeg",c="Cloth"},{on="LowerLeg",c="Cloth"},{on="LowerLeg",kind="band",c="Tie",y0=.72,h=.18}}},
	{id="BottomPantsSand",slot="bottom",name="TIED PANTS • SAND",base=true,colors={Cloth={150,132,104},Tie={60,58,70}},
		pieces={{on="LowerTorso",c="Cloth",y0=.4,h=.6},{on="UpperLeg",c="Cloth"},{on="LowerLeg",c="Cloth"},{on="LowerLeg",kind="band",c="Tie",y0=.72,h=.18}}},
	{id="BottomShorts",slot="bottom",name="WRAPPED SHORTS",base=true,colors={Cloth={42,42,52},Wrap={226,222,212}},
		pieces={{on="LowerTorso",c="Cloth",y0=.4,h=.6},{on="UpperLeg",c="Cloth",h=.75},{on="LowerLeg",kind="band",c="Wrap",y0=.1,h=.75}}},
	{id="ArmsWraps",slot="arms",name="ARM WRAPS",base=true,colors={Wrap={226,222,212}},
		pieces={{on="LowerArm",kind="band",c="Wrap",y0=.15,h=.8}}},
	{id="ArmsGuards",slot="arms",name="ARM GUARDS",base=true,colors={Guard={120,124,132},Strap={36,36,44}},
		pieces={{on="LowerArm",c="Guard",y0=.2,h=.65,pad=.1,mat="Metal"},{on="LowerArm",kind="band",c="Strap",y0=.3,h=.12}}},
	{id="ArmsNone",slot="arms",name="BARE ARMS",base=true,none=true},
	{id="FeetSandals",slot="feet",name="NINJA SANDALS",base=true,colors={Sandal={40,48,78}},
		pieces={{on="Foot",c="Sandal",pad=.05},{on="LowerLeg",kind="band",c="Sandal",y0=.82,h=.18}}},
	{id="FeetBlack",slot="feet",name="BLACK SANDALS",base=true,colors={Sandal={26,26,32}},
		pieces={{on="Foot",c="Sandal",pad=.05},{on="LowerLeg",kind="band",c="Sandal",y0=.82,h=.18}}},
	{id="FeetNone",slot="feet",name="BARE FEET",base=true,none=true},
	-- The masters' outfits on his own avatar (« les skins des mentors »): their
	-- colours from the anime at 12-14; the ANIMATEUR's models replace these
	-- pieces when they exist (OutfitMeshes).
	{id="SetNone",slot="set",name="MY OWN PIECES",base=true,none=true},
	{id="SetNaruto",slot="set",kit="Legion",name="NARUTO'S JUMPSUIT",robux="SetNaruto",colors={Orange={236,120,30},Blue={34,44,92},White={232,230,224}},
		pieces={{on="UpperTorso",c="Orange"},{on="UpperTorso",kind="shoulders",c="Blue"},{on="UpperTorso",kind="collar",c="White",h=.12},{on="LowerTorso",c="Orange"},{on="UpperArm",c="Orange"},{on="LowerArm",c="Orange",h=.85},{on="UpperLeg",c="Orange"},{on="LowerLeg",c="Orange",h=.7},{on="LowerLeg",kind="band",c="White",y0=.62,h=.12},{on="Foot",c="Blue",pad=.05}}},
	{id="SetSasuke",slot="set",kit="Lion",name="SASUKE'S HIGH COLLAR",robux="SetSasuke",colors={Navy={30,40,86},White={232,230,224},Wrap={226,222,212}},
		pieces={{on="UpperTorso",c="Navy"},{on="UpperTorso",kind="collar",c="Navy",h=.3},{on="LowerTorso",c="White"},{on="UpperArm",c="Navy",h=.4},{on="LowerArm",kind="band",c="Navy",y0=.1,h=.8},{on="UpperLeg",c="White",h=.7},{on="LowerLeg",kind="band",c="Wrap",y0=.1,h=.75},{on="Foot",c="Navy",pad=.05}}},
	{id="SetLee",slot="set",kit="Leaf",name="LEE'S GREEN SUIT",robux="SetLee",colors={Green={46,140,60},Orange={230,120,40},Red={190,40,36}},
		pieces={{on="UpperTorso",c="Green"},{on="LowerTorso",c="Green"},{on="LowerTorso",kind="band",c="Red",y0=.05,h=.22},{on="UpperArm",c="Green"},{on="LowerArm",c="Green"},{on="UpperLeg",c="Green"},{on="LowerLeg",c="Orange",pad=.12},{on="Foot",c="Green",pad=.05}}},
	{id="SetNeji",slot="set",kit="GentleFist",name="NEJI'S ROBE",robux="SetNeji",colors={Robe={226,222,208},Dark={60,56,64},Wrap={226,222,212}},
		pieces={{on="UpperTorso",c="Robe"},{on="LowerTorso",c="Robe"},{on="LowerTorso",kind="tail",c="Robe",h=.9},{on="UpperArm",c="Robe"},{on="LowerArm",c="Robe",h=.6},{on="UpperLeg",c="Dark"},{on="LowerLeg",kind="band",c="Wrap",y0=.05,h=.6},{on="Foot",c="Dark",pad=.05}}},
	{id="SetGaara",slot="set",kit="Sand",name="GAARA'S COAT",robux="SetGaara",colors={Coat={110,34,36},Sash={206,196,170},Dark={44,40,46}},
		pieces={{on="UpperTorso",c="Coat"},{on="UpperTorso",kind="sash",c="Sash"},{on="LowerTorso",c="Coat"},{on="LowerTorso",kind="tail",c="Coat",h=1.2},{on="UpperArm",c="Coat"},{on="LowerArm",c="Coat",h=.8},{on="UpperLeg",c="Dark"},{on="LowerLeg",c="Dark"},{on="Foot",c="Dark",pad=.05}}},
	{id="SetKakashi",slot="set",kit="Copycat",name="KAKASHI'S FLAK VEST",robux="SetKakashi",colors={Navy={36,42,66},Vest={86,98,70},Wrap={226,222,212}},
		pieces={{on="UpperTorso",c="Navy"},{on="UpperTorso",kind="vest",c="Vest"},{on="UpperTorso",kind="collar",c="Navy",h=.22},{on="LowerTorso",c="Navy"},{on="UpperArm",c="Navy"},{on="LowerArm",c="Navy"},{on="UpperLeg",c="Navy"},{on="LowerLeg",c="Navy"},{on="LowerLeg",kind="band",c="Wrap",y0=.5,h=.3},{on="Foot",c="Navy",pad=.05}}},
	{id="SetItachi",slot="set",kit="Mirage",name="ITACHI'S ANBU GEAR",robux="SetItachi",colors={Black={26,26,32},Grey={150,152,158},Guard={176,180,186}},
		pieces={{on="UpperTorso",c="Black"},{on="UpperTorso",kind="vest",c="Grey"},{on="LowerTorso",c="Black"},{on="UpperArm",c="Black",h=.5},{on="LowerArm",c="Guard",y0=.2,h=.65,pad=.1,mat="Metal"},{on="UpperLeg",c="Black"},{on="LowerLeg",c="Black"},{on="Foot",c="Black",pad=.05}}},
	{id="SetMinato",slot="set",kit="Flashstep",name="MINATO'S JACKET",robux="SetMinato",colors={Blue={40,70,130},Navy={30,36,60},Wrap={226,222,212}},
		pieces={{on="UpperTorso",c="Blue"},{on="UpperTorso",kind="collar",c="Blue",h=.16},{on="LowerTorso",c="Navy"},{on="UpperArm",c="Blue"},{on="LowerArm",c="Blue",h=.8},{on="UpperLeg",c="Navy"},{on="LowerLeg",c="Navy",h=.7},{on="LowerLeg",kind="band",c="Wrap",y0=.62,h=.2},{on="Foot",c="Navy",pad=.05}}},
}
local byId={}
for _,item in Shop.Items do byId[item.id]=item end
function Shop.item(id) return byId[id] end
-- Where a look is sold: "shop" (Robux), "market" (Ryō), nil (free).
function Shop.counter(item)
	if item.robux then return "shop" elseif item.ryo then return "market" end
	return nil
end
-- What a counter shows of a slot: what it sells, the free looks, and what he
-- owns from the other counter (so he can wear it from either).
function Shop.atCounter(slot,counter,style)
	local out={}
	for _,item in Shop.inSlot(slot) do
		local sold=Shop.counter(item)
		local owned=style and style.owned and style.owned[item.id]
		if sold==counter or sold==nil or owned then table.insert(out,item) end
	end
	return out
end
-- What each slot wears when the player chose nothing (the outfit: nothing,
-- DEC-040).
function Shop.default(slot)
	if Shop.Slots[slot] and Shop.Slots[slot].outfit then return nil end
	for _,item in Shop.Items do if item.slot==slot and item.base and not item.none then return item end end
	return nil
end
-- (DEC-040) Whether he has chosen his outfit (a top, or a master's outfit):
-- until then the character screen opens on his arrival.
function Shop.dressed(style)
	local e=style and style.equipped
	if not e then return false end
	local set=e.set and Shop.item(e.set)
	return e.top~=nil or (set~=nil and not set.none)
end
function Shop.inSlot(slot)
	local out={}
	for _,item in Shop.Items do if item.slot==slot then table.insert(out,item) end end
	return out
end

-- The passes (Roblox game passes: Config.Shop.Passes / Config.Progression).
Shop.Passes={
	{id="MasteryPass",name="2X MASTERY",note="Every duel counts double for mastery: masters and tree points come twice as fast."},
	{id="VIP",name="VIP",note="A golden name and a cape in Konoha, the VIP tag over your head."},
	{id="EarlyAccess",name="EARLY ACCESS",note="The next prodigy before everyone, in training and against the AI."},
	{id="BuildSlots",name="MORE BUILDS",note="Three saved builds per kit, switched in one click between duels."},
}

-- Ryō for a decided duel. r = {won, firstWinToday, master}.
function Shop.duelRyo(r)
	local R=Shop.Ryo
	local n=R.Finished+(if r.won then R.Won else 0)
	if r.won and r.firstWinToday then n*=R.FirstWinOfDay end
	if r.won and r.master then n+=R.MasterWon end
	return n
end

-- What the shop shows for one look: owned · equipped · ryo price · robux
-- (on sale or soon) · base. `style` = the profile's {owned, equipped}.
function Shop.state(style,item,ryo,products)
	local owned=item.base or (style and style.owned and style.owned[item.id]==true)
	local equipped=style and style.equipped and style.equipped[item.slot]
	local wearing=if equipped~=nil then equipped==item.id else (item.base and not item.none)
	if wearing then return {kind="equipped",label="EQUIPPED"} end
	if owned then return {kind="owned",label="EQUIP"} end
	if item.ryo then
		return {kind="ryo",label=item.ryo.." RYŌ",price=item.ryo,afford=(ryo or 0)>=item.ryo}
	end
	if item.robux then
		local product=products and products[item.robux]
		if product and product>0 then return {kind="robux",label="BUY",product=product} end
		return {kind="soon",label="SOON"}
	end
	return {kind="soon",label="SOON"}
end

return Shop
