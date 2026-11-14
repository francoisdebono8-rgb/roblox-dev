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
}
-- (Lee's weights get their look once their Blender model exists.)
Shop.SlotOrder={"kunai","shuriken","tanto","gourd","headband"}

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
}
local byId={}
for _,item in Shop.Items do byId[item.id]=item end
function Shop.item(id) return byId[id] end
-- What each slot wears when the player chose nothing.
function Shop.default(slot)
	for _,item in Shop.Items do if item.slot==slot and item.base and not item.none then return item end end
	return nil
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
