-- Impact presentation. Adapted from Velmora src/client/Combat/HitFeedback.luau
-- (Copyright (c) 2026 Yashveer Singh, MIT), extended with a style hierarchy so
-- small hits, finishers, launchers and slams do not feel identical.
-- Every effect is driven by a server-reported contact, never by a button press.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Feedback={}
-- Audio stays on assets already imported and verified by this project; extra
-- cues are declared here so adding one later is a one-line change.
local AUDIO={light="rbxassetid://8595980577",heavy="rbxassetid://9117969717",whiff="rbxassetid://5835032207"}
local LOOPED={}
-- style -> shard count, light range, colour, pitch, volume, tint of the target
local look={
 light   ={shards=5, range=7,  color=Color3.fromRGB(255,214,170),pitch=1.18,volume=.32,hit=Color3.fromRGB(255,238,214)},
 finisher={shards=6, range=9,  color=Color3.fromRGB(255,186,120),pitch=0.94,volume=.42,hit=Color3.fromRGB(255,220,180)},
 launcher={shards=5, range=9,  color=Color3.fromRGB(196,226,255),pitch=0.86,volume=.40,hit=Color3.fromRGB(226,240,255)},
 air     ={shards=6, range=8,  color=Color3.fromRGB(212,232,255),pitch=1.06,volume=.34,hit=Color3.fromRGB(232,244,255)},
 slam    ={shards=9,range=13, color=Color3.fromRGB(255,158,96),pitch=0.72,volume=.52,hit=Color3.fromRGB(255,206,168)},
 block   ={shards=8, range=9,  color=Color3.fromRGB(226,206,150),pitch=1.32,volume=.34,hit=Color3.fromRGB(240,228,190)},
 parry   ={shards=7,range=11, color=Color3.fromRGB(255,244,168),pitch=1.42,volume=.46,hit=Color3.fromRGB(255,250,214)},
 jutsu   ={shards=6,range=11, color=Color3.fromRGB(255,146,92),pitch=0.9, volume=.44,hit=Color3.fromRGB(255,196,150)},
 kunai   ={shards=4, range=6,  color=Color3.fromRGB(206,216,226),pitch=1.34,volume=.26,hit=Color3.fromRGB(230,236,242)},
 shuriken={shards=4, range=6,  color=Color3.fromRGB(198,210,224),pitch=1.5, volume=.24,hit=Color3.fromRGB(230,236,242)},
 dodge   ={shards=5, range=6,  color=Color3.fromRGB(168,206,238),pitch=1.26,volume=.22,hit=Color3.fromRGB(206,226,242)},
 substitute={shards=7,range=8, color=Color3.fromRGB(196,196,214),pitch=1.0, volume=.30,hit=Color3.fromRGB(226,226,240)},
 whiff   ={shards=2, range=4,  color=Color3.fromRGB(176,188,200),pitch=1.6, volume=.14,hit=Color3.fromRGB(200,208,218)},
 landing ={shards=6, range=7,  color=Color3.fromRGB(170,158,132),pitch=0.8, volume=.26,hit=Color3.fromRGB(206,196,172)},
 wall    ={shards=5, range=8,  color=Color3.fromRGB(184,178,158),pitch=0.86,volume=.30,hit=Color3.fromRGB(214,208,186)},
 wallbounce={shards=8,range=12,color=Color3.fromRGB(255,206,150),pitch=0.74,volume=.48,hit=Color3.fromRGB(255,224,190)},
 clash   ={shards=9, range=12, color=Color3.fromRGB(255,240,190),pitch=1.25,volume=.5, hit=Color3.fromRGB(255,250,224)},
 walltech={shards=4, range=6,  color=Color3.fromRGB(206,222,255),pitch=1.3, volume=.22,hit=Color3.fromRGB(226,236,255)},
 pin     ={shards=3, range=5,  color=Color3.fromRGB(220,224,232),pitch=1.5, volume=.22,hit=Color3.fromRGB(236,240,246)},
 ember   ={shards=4, range=7,  color=Color3.fromRGB(255,170,90),pitch=1.1, volume=.26,hit=Color3.fromRGB(255,214,170)},
 palm    ={shards=3, range=6,  color=Color3.fromRGB(196,212,255),pitch=1.3, volume=.26,hit=Color3.fromRGB(226,234,255)},
 flow    ={shards=4, range=7,  color=Color3.fromRGB(214,232,255),pitch=1.45,volume=.3, hit=Color3.fromRGB(236,244,255)},
 awaken  ={shards=8, range=14, color=Color3.fromRGB(255,236,190),pitch=0.7, volume=.5, hit=Color3.fromRGB(255,244,220)},
 palmburst={shards=6,range=10, color=Color3.fromRGB(214,226,255),pitch=0.9, volume=.38,hit=Color3.fromRGB(232,238,255)},
 deflect ={shards=4, range=6,  color=Color3.fromRGB(226,236,255),pitch=1.5, volume=.22,hit=Color3.fromRGB(240,244,255)},
 repel   ={shards=7, range=11, color=Color3.fromRGB(200,216,255),pitch=0.84,volume=.44,hit=Color3.fromRGB(228,236,255)},
 rotation={shards=2, range=10, color=Color3.fromRGB(200,216,255),pitch=0.7, volume=.2, hit=Color3.fromRGB(228,236,255)},
 trigram ={shards=0, range=9,  color=Color3.fromRGB(200,216,255),pitch=0.8, volume=.16,hit=Color3.fromRGB(228,236,255)},
}
local function anchorAt(position)
	local anchor=Instance.new("Part")
	anchor.Name="LocalImpact";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false
	anchor.Transparency=1;anchor.Size=Vector3.one;anchor.Position=position;anchor.Parent=workspace
	return anchor
end
local function playSound(parent,id,pitch,volume)
	if not id then return end
	local sound=Instance.new("Sound")
	sound.SoundId=id;sound.Volume=volume or .3;sound.PlaybackSpeed=pitch or 1
	sound.RollOffMaxDistance=120;sound.Parent=parent
	sound:Play()
	Debris:AddItem(sound,2)
end
function Feedback.burst(position,color,damage,blocked)
	local anchor=anchorAt(position)
	local light=Instance.new("PointLight");light.Color=color;light.Brightness=(if blocked then 5 else 3);light.Range=(if blocked then 11 else 8);light.Parent=anchor
	TweenService:Create(light,TweenInfo.new(.2),{Brightness=0}):Play()
	for i=1,(if blocked then 10 else 7) do
		local shard=Instance.new("Part");shard.Anchored=true;shard.CanCollide=false;shard.CanQuery=false;shard.Material=Enum.Material.Neon;shard.Color=color;shard.Size=Vector3.new(.08,.08,math.random(5,11)/10);shard.CFrame=CFrame.lookAt(position,position+Vector3.new(math.random()-0.5,math.random()-0.5,math.random()-0.5));shard.Parent=workspace
		TweenService:Create(shard,TweenInfo.new(.18,Enum.EasingStyle.Quad),{CFrame=shard.CFrame*CFrame.new(0,0,-math.random(2,5)),Transparency=1}):Play();Debris:AddItem(shard,.22)
	end
	if damage and damage>0 then
		local bill=Instance.new("BillboardGui");bill.Size=UDim2.fromOffset(80,40);bill.StudsOffset=Vector3.new(0,2.5,0);bill.AlwaysOnTop=true;bill.Parent=anchor
		local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=string.format("-%d",math.floor(damage+.5));label.TextColor3=color;label.TextStrokeTransparency=.15;label.Font=Enum.Font.GothamBlack;label.TextScaled=true;label.Parent=bill
		TweenService:Create(bill,TweenInfo.new(.45),{StudsOffset=Vector3.new(0,4.5,0)}):Play();TweenService:Create(label,TweenInfo.new(.45),{TextTransparency=1,TextStrokeTransparency=1}):Play()
	end
	Debris:AddItem(anchor,.55)
end
-- One contact, one coherent reaction. Only the layers the style warrants.
function Feedback.impact(style,position)
	local spec=look[style] or look.light
	local anchor=anchorAt(position)
	local cue=(if style=="light" then "light" elseif style=="whiff" then "whiff" else "heavy")
	playSound(anchor,AUDIO[cue],spec.pitch,spec.volume)
	local light=Instance.new("PointLight")
	light.Color=spec.color;light.Brightness=(if style=="parry" or style=="slam" then 8 else 4)
	light.Range=spec.range;light.Parent=anchor
	TweenService:Create(light,TweenInfo.new(if style=="slam" then .28 else .17),{Brightness=0}):Play()
	local spread=if style=="slam" then 1.1 elseif style=="whiff" then 2.4 else .7
	local distance=if style=="whiff" then 2 else math.max(1.4,spec.range*.32)
	for _=1,spec.shards do
		local direction=Vector3.new(math.random()-0.5,math.random()-0.5,math.random()-0.5)
		if direction.Magnitude<.01 then direction=Vector3.yAxis end
		local shard=Instance.new("Part")
		shard.Anchored=true;shard.CanCollide=false;shard.CanQuery=false;shard.Material=Enum.Material.Neon
		shard.Color=spec.color;shard.Size=Vector3.new(.08,.08,math.random(5,12)/10)
		shard.CFrame=CFrame.lookAt(position,position+direction.Unit)*CFrame.Angles(0,0,math.random()*math.pi)
		shard.Parent=workspace
		local travel=CFrame.new(direction.Unit*(distance*(0.6+math.random()*.8)*spread))
		TweenService:Create(shard,TweenInfo.new(if style=="slam" then .26 else .18,Enum.EasingStyle.Quad),{CFrame=shard.CFrame*travel,Transparency=1}):Play()
		Debris:AddItem(shard,.3)
	end
	if style=="wall" then
		-- Wall dust: a flat puff pushed away from the surface, no screen shake.
		for i=1,7 do
			local puff=Instance.new("Part")
			puff.Anchored=true;puff.CanCollide=false;puff.CanQuery=false
			puff.Material=Enum.Material.Slate;puff.Color=Color3.fromRGB(176,170,152)
			puff.Size=Vector3.new(.3,.3,.3);puff.Transparency=.35
			puff.CFrame=CFrame.new(position+Vector3.new((math.random()-.5)*2,(math.random()-.5)*2,(math.random()-.5)*2))
			puff.Parent=workspace
			TweenService:Create(puff,TweenInfo.new(.32,Enum.EasingStyle.Quad),
				{Size=Vector3.new(1.6,1.6,1.6),Transparency=1}):Play()
			Debris:AddItem(puff,.38)
		end
	end
	if style=="slam" or style=="landing" then
		local ring=Instance.new("Part")
		ring.Anchored=true;ring.CanCollide=false;ring.CanQuery=false;ring.Material=Enum.Material.Neon
		ring.Color=spec.color;ring.Shape=Enum.PartType.Cylinder;ring.Size=Vector3.new(.12,3,3)
		ring.CFrame=CFrame.new(position-Vector3.new(0,2.4,0))*CFrame.Angles(0,0,math.pi/2)
		ring.Transparency=.25;ring.Parent=workspace
		TweenService:Create(ring,TweenInfo.new(.28,Enum.EasingStyle.Quad),{Size=Vector3.new(.12,13,13),Transparency=1}):Play()
		Debris:AddItem(ring,.34)
	end
	Debris:AddItem(anchor,.45)
	return spec
end
-- Hitstop-scaled impulse; the camera reads this instead of re-deriving it.
function Feedback.impulse(style)
	local spec=look[style] or look.light
	return {shake=spec.range/26, fov=(spec.range-6)*.42}
end
return Feedback
