-- The catalogue of looks (19/11, plan « vague 2 », DEV 2): the data the
-- ANIMATEUR fills, apart from the shop's logic (Shared/Shop, DEV), so that
-- adding a piece never touches a rule. One entry per look:
--   id       stable, saved in profiles: never rename or recycle it
--   slot     one of Shared/Shop.Slots (kunai, shuriken, tanto, gourd,
--            headband, set, top, bottom, arms, feet, mask, cape, back)
--   name     shown in the shop, the market and MY NINJA (capitals)
--   price    `ryo` = Ryō at Konoha's market, or `robux` = the key of a
--            Developer Product in Config.Shop.Products (no id there: SOON);
--            `base` = everyone has it; `none` = « nothing in this slot »
--   kit      (weapon looks) the kit whose object it paints
--   colors   the look's colour slots: how Client/Effects paints a weapon
--            (Blade, Grip, Ring, Body), Server/Headband a band (Band, Plate),
--            Server/Outfit and Client/OutfitDress a piece (any name the
--            pieces use)
--   pieces   (outfit slots) what Server/Outfit builds on the body, until a
--            modelled piece of the same item (Shared/OutfitMeshes, by item
--            name) replaces it on screen: {on=<body part>, kind=shell | band
--            | collar | shoulders | vest | sash | tail | cape | scroll,
--            c=<colour slot>, y0, h}
-- A look is never a number (DEC-039). New looks: add them here, an icon
-- (tools/icons) and, when modelled, their pieces in OutfitMeshes.
local Catalog={}

Catalog.Items={
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
	{id="SetLee",slot="set",kit="Leaf",name="LEE'S GREEN SUIT",robux="SetLee",colors={Green={46,140,60},Orange={230,120,40},Red={190,40,36},Wrap={226,222,212},Plate={200,204,210}},
		pieces={{on="UpperTorso",c="Green"},{on="LowerTorso",c="Green"},{on="LowerTorso",kind="band",c="Red",y0=.05,h=.22},{on="UpperArm",c="Green"},{on="LowerArm",c="Green"},{on="UpperLeg",c="Green"},{on="LowerLeg",c="Orange",pad=.12},{on="Foot",c="Green",pad=.05}}},
	{id="SetNeji",slot="set",kit="GentleFist",name="NEJI'S ROBE",robux="SetNeji",colors={Robe={226,222,208},Dark={60,56,64},Wrap={226,222,212}},
		pieces={{on="UpperTorso",c="Robe"},{on="LowerTorso",c="Robe"},{on="LowerTorso",kind="tail",c="Robe",h=.9},{on="UpperArm",c="Robe"},{on="LowerArm",c="Robe",h=.6},{on="UpperLeg",c="Dark"},{on="LowerLeg",kind="band",c="Wrap",y0=.05,h=.6},{on="Foot",c="Dark",pad=.05}}},
	{id="SetGaara",slot="set",kit="Sand",name="GAARA'S COAT",robux="SetGaara",colors={Coat={110,34,36},Sash={206,196,170},Dark={44,40,46},Plate={200,204,210}},
		pieces={{on="UpperTorso",c="Coat"},{on="UpperTorso",kind="sash",c="Sash"},{on="LowerTorso",c="Coat"},{on="LowerTorso",kind="tail",c="Coat",h=1.2},{on="UpperArm",c="Coat"},{on="LowerArm",c="Coat",h=.8},{on="UpperLeg",c="Dark"},{on="LowerLeg",c="Dark"},{on="Foot",c="Dark",pad=.05}}},
	{id="SetKakashi",slot="set",kit="Copycat",name="KAKASHI'S FLAK VEST",robux="SetKakashi",colors={Navy={36,42,66},Vest={86,98,70},Wrap={226,222,212},Guard={190,194,200}},
		pieces={{on="UpperTorso",c="Navy"},{on="UpperTorso",kind="vest",c="Vest"},{on="UpperTorso",kind="collar",c="Navy",h=.22},{on="LowerTorso",c="Navy"},{on="UpperArm",c="Navy"},{on="LowerArm",c="Navy"},{on="UpperLeg",c="Navy"},{on="LowerLeg",c="Navy"},{on="LowerLeg",kind="band",c="Wrap",y0=.5,h=.3},{on="Foot",c="Navy",pad=.05}}},
	{id="SetItachi",slot="set",kit="Mirage",name="ITACHI'S ANBU GEAR",robux="SetItachi",colors={Black={26,26,32},Grey={150,152,158},Guard={176,180,186}},
		pieces={{on="UpperTorso",c="Black"},{on="UpperTorso",kind="vest",c="Grey"},{on="LowerTorso",c="Black"},{on="UpperArm",c="Black",h=.5},{on="LowerArm",c="Guard",y0=.2,h=.65,pad=.1,mat="Metal"},{on="UpperLeg",c="Black"},{on="LowerLeg",c="Black"},{on="Foot",c="Black",pad=.05}}},
	{id="SetMinato",slot="set",kit="Flashstep",name="MINATO'S JACKET",robux="SetMinato",colors={Blue={40,70,130},Navy={30,36,60},Wrap={226,222,212},Coat={238,236,230},Flame={196,48,34},Vest={86,98,70}},
		pieces={{on="UpperTorso",c="Blue"},{on="UpperTorso",kind="collar",c="Blue",h=.16},{on="LowerTorso",c="Navy"},{on="UpperArm",c="Blue"},{on="LowerArm",c="Blue",h=.8},{on="UpperLeg",c="Navy"},{on="LowerLeg",c="Navy",h=.7},{on="LowerLeg",kind="band",c="Wrap",y0=.62,h=.2},{on="Foot",c="Navy",pad=.05}}},
	-- (19/11, vague 2) The accessories, worn over a set or the pieces: a mask
	-- under the eyes, a cape off the shoulders, what he carries on his back.
	-- First looks of each, in cloth until the ANIMATEUR models them.
	{id="MaskNone",slot="mask",name="NO MASK",base=true,none=true},
	{id="MaskCloth",slot="mask",name="CLOTH MASK",ryo=250,colors={Cloth={40,44,62}},
		pieces={{on="Head",kind="shell",c="Cloth",y0=.5,h=.5,pad=.04}}},
	{id="CapeNone",slot="cape",name="NO CAPE",base=true,none=true},
	{id="CapeTravel",slot="cape",name="TRAVEL CAPE",ryo=300,colors={Cloth={138,48,40},Cape={138,48,40},Trim={236,200,80}},
		pieces={{on="UpperTorso",kind="cape",c="Cloth"}}},
	{id="BackNone",slot="back",name="NOTHING ON THE BACK",base=true,none=true},
	{id="BackScroll",slot="back",name="SUMMONING SCROLL",ryo=300,colors={Roll={226,214,180},Cap={150,40,36},Paper={226,214,180},Wood={120,80,50},Strap={150,40,36}},
		pieces={{on="UpperTorso",kind="scroll",c="Roll"}}},
}

return Catalog
