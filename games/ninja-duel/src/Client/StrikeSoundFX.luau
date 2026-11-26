-- The sound of each blow at its clip's instant (26/11, passe 3, DEV: « le son
-- de chaque coup au bon instant du clip : la musique et les ambiances tournent
-- déjà, les coups doivent passer au-dessus »). One identity layer installed
-- into Effects (like NarutoFX). Presentation only, nothing reaches the server.
--
-- 1. The swing. Client/VelmoraMotionEngine puts the clip's contact frame on the
--    server's end of startup (attackElapsed + LEAD reaches the move's startup,
--    scaled by the fighter's AttackProfile). The swing's whoosh is started a
--    little before (its own attack, Whoosh.lead) so its peak lands on that
--    frame: heavier and lower for a heavy blow, a kick, a slam; a steel swish
--    on top when a weapon is in the hand. Once per strike (attackSerial).
-- 2. Over the music. Every combat sound (this layer's, Effects', the hit
--    feedback's) goes into the SoundGroup NinjaHits, whose sounds are heard
--    flat over the duel's distances (no roll-off inside the arena), and a
--    compressor on the music and ambience groups (Client/Soundscape's
--    NinjaMusic, NinjaAmbience) ducks them under it while a blow sounds.
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Fighters=require(Shared.Fighters)

local Strike={}
Strike.LEAD=.03          -- VelmoraMotionEngine's LEAD (the clip runs a hair ahead of the server)
-- the whooshes (Roblox's licensed Pro Sound Effects, already in the game: Effects.SOUND)
Strike.Whoosh={id="rbxassetid://5835032207",lead=.07}
Strike.Swish={id="rbxassetid://9126284094",lead=.05}
-- what makes a blow heavy (its name), and its sound
Strike.HEAVY={Heavy=true,Slam=true,Light3=true,DashAttack=true,AirDrive=true,Launcher=true,Finisher=true,Riposte=true,WallDive=true}
Strike.SOUND={light={volume=.55,pitch=1.35},heavy={volume=.8,pitch=.82},kick={volume=.7,pitch=1.02}}
-- the anchors combat sounds are hung on (Effects' SoundAnchor, the hit feedback's LocalImpact)
Strike.ANCHORS={SoundAnchor=true,LocalImpact=true}
-- the ducking: how far the music and ambience go under a blow
Strike.DUCK={Threshold=-30,Ratio=5,Attack=.01,Release=.35}

-- (pure) The move's startup on this fighter, the moment its clip's contact frame plays.
function Strike.startup(name,fighterId)
	local spec=Attacks[name]
	if not spec or type(spec.startup)~="number" then return nil end
	local fighter=Fighters[fighterId]
	local profile=fighter and fighter.AttackProfile and (fighter.AttackProfile[name] or fighter.AttackProfile[spec.clip or ""])
	return spec.startup*(profile and profile.startup or 1)
end
-- (pure) The weight of a blow: "heavy", "kick" or "light".
function Strike.weight(name)
	name=tostring(name or "")
	if Strike.HEAVY[name] then return "heavy" end
	if string.find(name,"Kick") or string.find(name,"Heel") or string.find(name,"Sweep") then return "kick" end
	return "light"
end
-- (pure) Is it time to start the whoosh of a strike `elapsed` into it?
function Strike.due(elapsed,startup,lead)
	return type(elapsed)=="number" and startup~=nil and elapsed+Strike.LEAD+(lead or 0)>=startup
end

-- The group every combat sound plays in, and the ducking of the others.
function Strike.group()
	local g=SoundService:FindFirstChild("NinjaHits")
	if not g then
		g=Instance.new("SoundGroup");g.Name="NinjaHits";g.Volume=1;g.Parent=SoundService
	end
	for _,name in {"NinjaMusic","NinjaAmbience"} do
		local under=SoundService:FindFirstChild(name)
		if under and under:IsA("SoundGroup") and not under:FindFirstChild("DuckUnderHits") then
			local c=Instance.new("CompressorSoundEffect");c.Name="DuckUnderHits"
			for k,v in Strike.DUCK do c[k]=v end
			c.SideChain=g;c.Parent=under
		end
	end
	return g
end
-- A combat sound joins the group and is heard flat over a duel's distances.
function Strike.adopt(sound)
	if not sound:IsA("Sound") then return end
	local g=Strike.group()
	sound.SoundGroup=g
	sound.RollOffMinDistance=math.max(sound.RollOffMinDistance,40)
	sound.RollOffMaxDistance=math.max(sound.RollOffMaxDistance,220)
end

local function play(parent,spec,volume,pitch)
	local s=Instance.new("Sound")
	s.Name="StrikeSwing";s.SoundId=spec.id;s.Volume=volume;s.PlaybackSpeed=pitch
	pcall(Strike.adopt,s)   -- (headless tests: no SoundService to group in)
	s.Parent=parent
	pcall(function() s:Play() end)
	Debris:AddItem(s,2)
	return s
end

local seen=setmetatable({},{__mode="k"})   -- model -> the strike already heard
local function fighter(fx,model,actor,dt)
	if not (model and actor and actor.attackName) then return end
	if actor.state~="Startup" and actor.state~="Active" then return end
	local serial=actor.attackSerial or actor.attackName
	if seen[model]==serial then return end
	local startup=Strike.startup(actor.attackName,actor.fighterId)
	local lead=Strike.Whoosh.lead
	if actor.state=="Startup" and not Strike.due(actor.attackElapsed,startup,lead) then return end
	seen[model]=serial
	local root=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not root then return end
	local weight=Strike.weight(actor.attackName)
	local s=Strike.SOUND[weight]
	play(root,Strike.Whoosh,s.volume,s.pitch*(.95+math.random()*.1))
	if actor.armed then
		task.delay(math.max(0,lead-Strike.Swish.lead),function()
			if root.Parent then play(root,Strike.Swish,.45,1.25+math.random()*.15) end
		end)
	end
	Strike.last={model=model.Name,move=actor.attackName,at=os.clock(),weight=weight}
end

function Strike.install(FX,kit)
	table.insert(FX.layers,{name="StrikeSound",fighter=fighter})
	-- the other combat sounds join the group as they are made
	task.defer(function()
		pcall(Strike.group)
		workspace.DescendantAdded:Connect(function(d)
			if d:IsA("Sound") and d.Parent and Strike.ANCHORS[d.Parent.Name] then pcall(Strike.adopt,d) end
		end)
		-- Soundscape makes its groups when the game starts: duck them once they exist
		SoundService.ChildAdded:Connect(function(c) if c:IsA("SoundGroup") and c.Name~="NinjaHits" then pcall(Strike.group) end end)
	end)
end

return Strike
