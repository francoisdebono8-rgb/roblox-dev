-- The game's music and ambience (26/11, passe 3, DEC-055; François : « son
-- ambiance et tout, ça y est pas » ; his choice: a soft music and the street's
-- sounds). Data only, played by Client/Soundscape.
--
-- Every sound is a free audio of the Roblox Creator Store licensed for use in
-- experiences: the music from the DistroKid and APM libraries (Roblox's
-- licensed music), the ambiences from Pro Sound Effects. Each was found by the
-- Studio's asset search and proven in Studio (26/11, place commune, client of
-- a Play): loaded, its length measured, its loudness measured silently (a
-- SoundGroup at volume 0, `Sound.PlaybackLoudness` sampled at five places of
-- the track). `volume` brings each one to its layer's level from that
-- measure (`SoundBank.level`), so a track swapped keeps the mix.
-- (27/11) Samurai Sword Echoes, Moeru Kodou, the chimes and the cheers carry
-- the OUTILLEUR's measure (tools/sounds, 26/11: they sat at 41/55, 56/70,
-- 2.4/3 and 38/30 of their levels with the first one).
local SoundBank={}

-- The level of each layer: measured loudness × volume (the combat's hits peak
-- between 100 and 300 at their own volumes: the music stays under them).
SoundBank.LEVEL={forest=35,konoha=40,duel=55,final=70,bed=6,walla=9,chimes=3,cheer=30,hall=12}

-- (pure) The volume that brings a sound measured at `loudness` to `level`,
-- kept within Roblox's range.
function SoundBank.level(loudness,level)
	if type(loudness)~="number" or loudness<=0 then return 0 end
	return math.clamp(level/loudness,0,10)
end

local function track(id,name,source,length,loudness,layer)
	return {id="rbxassetid://"..id,name=name,source=source,length=length,loudness=loudness,layer=layer,volume=SoundBank.level(loudness,SoundBank.LEVEL[layer])}
end

-- The music, a playlist per state (Client/Soundscape draws the next one, never
-- the same twice in a row).
SoundBank.Music={
	-- the forest of the way in: calm, wind and bamboo
	forest={
		track(81439427476164,"Sacred Bamboo Wind","DistroKid",179.8,165.4,"forest"),
		track(137172521077350,"Biwa Lake Fog (Japanese Ambient Music)","DistroKid",290,114.3,"forest"),
	},
	-- Konoha in the afternoon: koto, light, warm
	konoha={
		track(140728100397638,"Kyoto Arpeggios","DistroKid",230.9,161.5,"konoha"),
		track(107401137151251,"Shimmering Koto Dreams","DistroKid",194.8,164.3,"konoha"),
		track(114993170766267,"Winter Sparrow Koto Ambient","DistroKid",158.7,182.4,"konoha"),
	},
	-- a duel: taiko and drive
	duel={
		track(74553068502659,"Taiko Battle March","DistroKid",89.1,107.3,"duel"),
		track(116766988040383,"Skyfall Duel","DistroKid",164.6,144.5,"duel"),
		track(140311746751125,"Samurai Sword Echoes","DistroKid",217.4,119.8,"duel"),
	},
	-- the final against the Ōtsutsuki (STORY-001)
	final={
		track(138614247392811,"Moeru Kodou (Blazing Heartbeat)","DistroKid",187.5,207.6,"final"),
		track(82510161326753,"Echoes Of Kabuki","DistroKid",169.6,156.8,"final"),
	},
}

-- The ambience, looped layers mixed by where he stands (Soundscape.Mix).
SoundBank.Ambience={
	birds=track(9112749254,"Birds Park 1","Pro Sound Effects",36,1.5,"bed"),
	woods=track(9112806424,"Jungle Dawn 1 (woods, birds, insects)","Pro Sound Effects",36,1.8,"bed"),
	walla=track(9112885014,"Theater Crowd 1 (Japanese walla)","Pro Sound Effects",36,21.5,"walla"),
	chimes=track(9120750072,"Wind Chimes 2","Pro Sound Effects",31.1,2.2,"chimes"),
	-- (27/11, OUTILLEUR passe 3: « Festival Of Fools » had parade horns) a
	-- large audience talking before the show, measured in Studio 27/11
	hall=track(9112885867,"Theater Walla 2 (audience before the show)","Pro Sound Effects",36,7.2,"hall"),
}

-- One-shots: the street cheers when a duel ends in front of it.
SoundBank.Shots={
	cheer=track(9120973900,"Wrestling Crowd 2 (short cheers)","Pro Sound Effects",20.8,89,"cheer"),
}

-- Every sound of the bank (the tests and the OUTILLEUR's sound check).
function SoundBank.all()
	local out={}
	for state,list in SoundBank.Music do for _,t in list do table.insert(out,{key="music."..state,sound=t}) end end
	for key,t in SoundBank.Ambience do table.insert(out,{key="ambience."..key,sound=t}) end
	for key,t in SoundBank.Shots do table.insert(out,{key="shot."..key,sound=t}) end
	return out
end

return SoundBank
