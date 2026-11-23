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
-- (23/11, step 5, DEC-049; the OUTILLEUR's new-player robot: « 2 combats
-- donnent 215 Ryō, l'apparence la moins chère en coûte 250 ») the day's first
-- win ×3 (it was ×2): a newcomer buys his first look after his first two
-- duels, and coming back each day pays.
Shop.Ryo={Finished=20,Won=30,FirstWinOfDay=3,MasterWon=150,Champion=300,Finalist=150}
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
	-- (19/11, vague 2) the accessories, over a set or the pieces (Server/Outfit)
	mask={name="MASK",kind="style",outfit=true,accessory=true},
	cape={name="CAPE",kind="style",outfit=true,accessory=true},
	back={name="ON THE BACK",kind="style",outfit=true,accessory=true},
	-- (21/11, étape 3 DEV 2, DEC-047) the ninja's personalization beyond the
	-- outfit (Shared/CatalogStyle; the ANIMATEUR's models and clips in Catalog)
	hair={name="HAIR STYLE",kind="style",personal=true},
	hairColor={name="HAIR COLOUR",kind="style",personal=true},
	chakra={name="CHAKRA COLOUR",kind="style",personal=true},
	victory={name="VICTORY POSE",kind="style",personal=true},
	emote={name="EMOTE",kind="style",personal=true},
	aura={name="AURA",kind="style",personal=true},
	title={name="TITLE",kind="style",personal=true},
	frame={name="FACE-CAM FRAME",kind="style",personal=true},
}
-- (Lee's weights get their look once their Blender model exists.)
Shop.SlotOrder={"kunai","shuriken","tanto","gourd","headband","set","top","bottom","arms","feet","mask","cape","back",
	"hair","hairColor","chakra","victory","emote","aura","title","frame"}
-- (21/11, DEC-047) The shop's tabs, one per kind of personalization (the
-- DESIGN's screen): the slots each shows, in order.
Shop.Tabs={
	{id="Outfit",name="OUTFIT",slots={"set","top","bottom","arms","feet","mask","cape","back","headband"}},
	{id="Hair",name="HAIR",slots={"hair","hairColor"}},
	{id="Chakra",name="CHAKRA",slots={"chakra"}},
	{id="Victory",name="POSES & EMOTES",slots={"victory","emote"}},
	{id="Aura",name="AURAS",slots={"aura"}},
	{id="Weapons",name="WEAPONS",slots={"kunai","shuriken","tanto","gourd"}},
	{id="Titles",name="TITLES",slots={"title"}},
	{id="Frames",name="FACE-CAM FRAMES",slots={"frame"}},
}
Shop.OutfitSlots={"top","bottom","arms","feet"}
Shop.AccessorySlots={"mask","cape","back"}

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
-- (19/11, vague 2 DEV 2) The looks themselves are Shared/Catalog: data the
-- ANIMATEUR fills; this module keeps the rules.
-- (21/11, DEC-047) with the DEV's personalization looks (Shared/CatalogStyle).
Shop.Items=table.clone(require(script.Parent.Catalog).Items)
for _,item in require(script.Parent.CatalogStyle).Items do table.insert(Shop.Items,item) end
local byId={}
for _,item in Shop.Items do assert(not byId[item.id],"look listed twice: "..item.id);byId[item.id]=item end
function Shop.item(id) return byId[id] end
-- Where a look is sold: "shop" (Robux), "market" (Ryō), nil (free or earned).
function Shop.counter(item)
	if item.robux then return "shop" elseif item.ryo then return "market" end
	return nil
end
-- (21/11, DEC-047) Whether a look is earned, never sold (Shared/CatalogStyle).
function Shop.earnedOnly(item) return item~=nil and item.earned~=nil end
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
	-- (23/11, DEC-049) EARLY ACCESS (no 9th prodigy yet) and MORE BUILDS (8
	-- builds a kit are free) are not sold: out of the list, out of the shop.
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
	-- (21/11, DEC-047) a look to earn says how
	if item.earned then return {kind="earn",label="EARN",how=item.how} end
	return {kind="soon",label="SOON"}
end

return Shop
