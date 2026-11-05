-- Each prodigy's chakra (DEC-032, user 03/11: "le chakra pour l'instant c'est
-- nul, tu frappes plus fort mais pas de trucs"): his nature, and what his
-- infused light, heavy, leap and dash BECOME (docs/characters/KITS_V2.md,
-- table 1). The server plays them (Server/ChakraFlow); (05/11, user on the
-- pad: L2 pressed alone 26 times in one evening) the HUD names them while the
-- chakra button is held, on the jutsu row (Client/UI).
local ChakraMoves={}
-- Unlisted: plain chakra.
ChakraMoves.Nature={
	Lion="Lightning",Copycat="Lightning",Mirage="Fire",Legion="Wind",Gale="Wind",
	Sand="Sand",GentleFist="GentleFist",Leaf="Strength",Flashstep="Chakra",
}
ChakraMoves.Label={Lightning="RAITON",Fire="KATON",Wind="FUTON",Sand="SAND",GentleFist="GENTLE FIST",Strength="STRENGTH",Chakra="CHAKRA"}
-- nil: the nature's common effect only.
ChakraMoves.Signature={
	Lion={light="Nagashi",heavy="FireJet"},             -- Chidori Nagashi through the guard; a jet of fire past the kick
	Legion={light="CloneStrike",heavy="Uzumaki"},       -- a clone pops beside him and follows up; U-ZU-MA-KI sends him up
	Sand={light="SandFist",heavy="SandGrip"},           -- the sand reaches far; the sand hand grips the legs
	Leaf={light="Flurry",heavy="GuardCrush",leap="Lotus",dash="AfterImage"}, -- the "patates"; the whirlwind through the guard
	GentleFist={heavy="Vacuum",dash="Rotation"},        -- (light: the Juken closes a point) the palm at range; a short Kaiten
	Mirage={light="Crows",heavy="FireJet",dash="CrowScatter"}, -- crows from the impact; he scatters into crows
	Flashstep={heavy="Rasengan",dash="FlyingThunder"},  -- (light: the seal) the Rasengan to the body; he flashes behind
	Copycat={heavy="EarthSpike",dash="Headhunter"},     -- Doton: a spike under him; under the ground and out behind
}
ChakraMoves.SigLabel={Nagashi="CHIDORI NAGASHI",FireJet="FIRE JET",CloneStrike="SHADOW CLONE",Uzumaki="U-ZU-MA-KI",
	SandFist="SAND FIST",SandGrip="SAND GRIP",Flurry="LEAF FLURRY",GuardCrush="GUARD CRUSH",Lotus="LOTUS LEAP",
	AfterImage="AFTERIMAGE",Vacuum="VACUUM PALM",Rotation="ROTATION",Crows="CROWS",CrowScatter="CROW SCATTER",
	Rasengan="RASENGAN",FlyingThunder="FLYING THUNDER GOD",EarthSpike="DOTON • EARTH SPIKE",Headhunter="DOTON • HEADHUNTER"}
-- The HUD's chakra page: the five presses the chakra button infuses, in the
-- order of the jutsu row (pad □ △ × ○ R2, keyboard LMB RMB SPACE Q R).
ChakraMoves.Slots={"light","heavy","leap","dash","tool"}
local PLAIN={light="STRIKE",heavy="HEAVY",leap="LEAP",dash="DASH",tool="KUNAI"}
-- Infused lights that are no signature move but do a thing of their own
-- (Server/ChakraFlow.hit: Minato seals the body, Neji closes a point).
local OWN={Flashstep={light="SEAL STRIKE"},GentleFist={light="CHAKRA POINT"}}
function ChakraMoves.name(fighterId,slot)
	local sig=ChakraMoves.Signature[fighterId] and ChakraMoves.Signature[fighterId][slot]
	if sig then return ChakraMoves.SigLabel[sig] end
	local own=OWN[fighterId] and OWN[fighterId][slot]
	if own then return own end
	return ChakraMoves.Label[ChakraMoves.Nature[fighterId] or "Chakra"].." "..PLAIN[slot]
end
return ChakraMoves
