-- The village sounds (26/11, passe 3, DEC-055, AMB-001; François : « son
-- ambiance et tout, ça y est pas » ; his choice: « musique douce + sons de
-- rue »). What is heard is what he does and where he stands:
--   * a music per state (the forest, Konoha, a duel, the final), drawn from
--     its playlist (Shared/SoundBank), crossfaded when the state changes;
--   * the street's ambience, looped layers (birds, the crowd's walla, wind
--     chimes, the woods, the hall's crowd) mixed by the place he stands in
--     (HubMap.placeAt), eased as he walks from one to the next; under a duel,
--     the street goes quieter;
--   * the street cheers when a duel ends in front of it.
-- Two SoundGroups, NinjaMusic and NinjaAmbience, follow the player's settings
-- (the LocalPlayer's attributes NinjaMusicVolume and NinjaAmbienceVolume, 0 to
-- 1, 1 when unset: the DESIGN's settings write them).
-- Presentation only: nothing here reaches the server.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local SoundBank=require(Shared.SoundBank)
local HubMap=require(Shared.HubMap)

local Soundscape={}
Soundscape.__index=Soundscape

-- A state's music fades in and the last one out over this long (seconds).
Soundscape.FADE=2.5
-- The ambience eases toward its place's mix at this rate (per second).
Soundscape.EASE=.8
-- Under a duel, the street at this share of its level.
Soundscape.DUEL_STREET=.45
-- The ambience of each place (HubMap.Places ids): each layer's share.
Soundscape.Mix={
	Forest={woods=1},
	Gate={birds=.8,walla=.15},
	Street={birds=.5,walla=.7},
	Ichiraku={birds=.4,walla=.8},
	Plaza={birds=.6,walla=.45},
	Hall={birds=.3,hall=.6},
	Training={birds=1},
	Memorial={birds=.9,chimes=.6},
	Hyuga={birds=.8,chimes=.9},
	Uchiha={birds=.7,chimes=.5},
	Rooftops={birds=.7,walla=.25},
	Faces={birds=1},
	Market={birds=.4,walla=1},
	Residences={birds=.9,chimes=1},
	Alleys={birds=.5,walla=.35},
}
Soundscape.DEFAULT_MIX={birds=.8}

-- (pure) The music's state for a snapshot `data` and the intro's stage
-- `intro` (the player attribute NinjaIntro: nil once in Konoha).
function Soundscape.state(data,intro)
	local phase=data and data.phase
	local site=data and data.site
	if data and (data.final==true or (site and site.final==true)) and (phase=="Duel" or phase=="Result") then return "final" end
	if phase=="Duel" or phase=="Result" then return "duel" end
	if intro~=nil and intro~="" then return "forest" end
	return "konoha"
end

-- (pure) Each ambience layer's target share for the place `placeId` and the
-- state (a duel lowers the street; the forest's intro is the woods).
function Soundscape.mix(placeId,state)
	local mix=if state=="forest" then Soundscape.Mix.Forest else (Soundscape.Mix[placeId or ""] or Soundscape.DEFAULT_MIX)
	local out={}
	for key in SoundBank.Ambience do out[key]=mix[key] or 0 end
	if state=="duel" or state=="final" then for key,v in out do out[key]=v*Soundscape.DUEL_STREET end end
	return out
end

-- (pure) `current` moved toward `target` by `rate` per second over `dt`.
function Soundscape.ease(current,target,dt,rate)
	local step=math.max(0,dt)*rate
	if math.abs(target-current)<=step then return target end
	return current+(if target>current then step else -step)
end

-- (pure) The next track of a playlist: never the one just played when there
-- is another. `roll` in [0,1).
function Soundscape.draw(list,last,roll)
	local n=#list
	if n==0 then return nil end
	if n==1 then return list[1] end
	local pool={}
	for _,t in list do if t~=last then table.insert(pool,t) end end
	return pool[math.clamp(math.floor((roll or 0)*#pool)+1,1,#pool)]
end

-- A player setting (0 to 1), 1 when unset.
local function setting(name)
	local v=Players.LocalPlayer and Players.LocalPlayer:GetAttribute(name)
	return if type(v)=="number" then math.clamp(v,0,1) else 1
end

local function group(name)
	local g=SoundService:FindFirstChild(name)
	if not (g and g:IsA("SoundGroup")) then
		g=Instance.new("SoundGroup");g.Name=name;g.Parent=SoundService
	end
	return g
end

function Soundscape.new()
	local self=setmetatable({},Soundscape)
	self.music=group("NinjaMusic")
	self.ambience=group("NinjaAmbience")
	self.state=nil
	self.channels={}     -- the music playing or fading: {sound, track, gain, target}
	self.last={}         -- per state, the track last played
	self.layers={}       -- the ambience: key -> {sound, gain}
	self.data=nil
	self.rng=Random.new()
	for key,t in SoundBank.Ambience do
		local s=Instance.new("Sound")
		s.Name="Ambience_"..key;s.SoundId=t.id;s.Looped=true;s.Volume=0;s.SoundGroup=self.ambience
		s.Parent=self.ambience
		self.layers[key]={sound=s,gain=0,track=t}
	end
	return self
end

-- A track of the state, faded in; what played fades out.
function Soundscape:play(state)
	local list=SoundBank.Music[state]
	local t=list and Soundscape.draw(list,self.last[state],self.rng:NextNumber())
	for _,ch in self.channels do ch.target=0 end
	if not t then return end
	self.last[state]=t
	local s=Instance.new("Sound")
	s.Name="Music_"..state;s.SoundId=t.id;s.Volume=0;s.SoundGroup=self.music;s.Parent=self.music
	local ch={sound=s,track=t,gain=0,target=1,state=state}
	table.insert(self.channels,ch)
	-- a track at its end: the next one of the same state
	s.Ended:Connect(function()
		if self.state==state and ch.target>0 then self:play(state) end
	end)
	s:Play()
end

-- The last snapshot (Client/Main, on every one): the state may change, the
-- street cheers at a duel's end.
function Soundscape:render(data)
	local was=self.data
	self.data=data
	local intro=Players.LocalPlayer and Players.LocalPlayer:GetAttribute("NinjaIntro")
	local state=Soundscape.state(data,intro)
	if state~=self.state then
		self.state=state
		self:play(state)
	end
	-- a street duel just ended: the street cheers
	if data and data.phase=="Result" and (not was or was.phase~="Result") and data.site and data.site.street then
		local t=SoundBank.Shots.cheer
		local s=Instance.new("Sound")
		s.SoundId=t.id;s.Volume=t.volume;s.SoundGroup=self.ambience;s.Parent=self.ambience
		s.Ended:Connect(function() s:Destroy() end)
		s:Play()
		task.delay(t.length+1,function() if s.Parent then s:Destroy() end end)
	end
end

-- Every frame: the fades, the place's ambience, the settings.
function Soundscape:step(dt)
	self.music.Volume=setting("NinjaMusicVolume")
	self.ambience.Volume=setting("NinjaAmbienceVolume")
	for i=#self.channels,1,-1 do
		local ch=self.channels[i]
		ch.gain=Soundscape.ease(ch.gain,ch.target,dt,1/Soundscape.FADE)
		ch.sound.Volume=ch.track.volume*ch.gain
		if ch.target==0 and ch.gain<=0 then ch.sound:Destroy();table.remove(self.channels,i) end
	end
	-- where he stands (his body's root; at the menu, nowhere: the default)
	local character=Players.LocalPlayer and Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local place=root and HubMap.placeAt(root.Position)
	local mix=Soundscape.mix(place and place.id,self.state or "konoha")
	for key,layer in self.layers do
		layer.gain=Soundscape.ease(layer.gain,mix[key] or 0,dt,Soundscape.EASE)
		layer.sound.Volume=layer.track.volume*layer.gain
		if layer.gain>0 and not layer.sound.IsPlaying then
			-- each loop starts somewhere else, not all on their first second
			pcall(function() layer.sound.TimePosition=self.rng:NextNumber()*math.max(0,layer.track.length-1) end)
			layer.sound:Play()
		elseif layer.gain<=0 and layer.sound.IsPlaying then
			layer.sound:Stop()
		end
	end
end

function Soundscape:start()
	RunService.RenderStepped:Connect(function(dt) pcall(self.step,self,dt) end)
	return self
end

return Soundscape
