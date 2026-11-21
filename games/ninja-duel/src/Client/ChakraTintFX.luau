-- The colour of his chakra (21/11, étape 3 ANIMATEUR 2, DEC-047; François: « la couleur de ton
-- chakra et de tes jutsu »). The shop sells a chakra colour (slot "chakra", Shared/CatalogStyle);
-- the server puts it on the player (attribute NinjaChakra, a Color3). This layer recolours HIS
-- chakra with it: every effect drawn in the game's chakra blue (the charge round his body, his
-- mantle, the dash wake, the Rasengan, the chakra on his hands and weapons, his infusion's
-- trails...) takes his colour's hue, keeping its own light and shade, so the look stays the
-- effect's and only the colour is his. What is not chakra keeps its colour: a fire jutsu stays
-- fire, sand stays sand, lightning stays white-blue unless it was drawn in the chakra band.
--
-- Whose effect it is: an effect hung on a body is that body's; one drawn in the duel's folder
-- is the fighter it was born next to (within 7 studs), the one casting or striking first.
-- Presentation only.
local Players=game:GetService("Players")

local Tint={}
Tint.BASE=Color3.fromRGB(110,180,255)    -- LEAF BLUE, the base colour: nothing to change
Tint.BAND={.50,.72}                      -- the hues the game draws chakra in (cyan to blue)
Tint.MIN_SAT=.22                         -- below that a colour is white/grey: left alone
Tint.REACH=7

-- One colour moved to his hue (its own saturation and brightness mostly kept; a dark chakra
-- like BLACK FLAME darkens it, a pale one like FROST whitens it).
function Tint.shift(c,target)
	local h,s,v=c:ToHSV()
	if s<Tint.MIN_SAT or h<Tint.BAND[1] or h>Tint.BAND[2] then return c,false end
	local th,ts,tv=target:ToHSV()
	local ns=math.clamp(s*.35+ts*.65,0,1)
	local nv=math.clamp(v*(.45+.55*tv)+(if tv<.3 then 0 else 0),0,1)
	return Color3.fromHSV(th,ns,nv),true
end
local function seq(cs,target)
	local keys,changed={},false
	for _,k in cs.Keypoints do
		local c,ok=Tint.shift(k.Value,target)
		changed=changed or ok
		table.insert(keys,ColorSequenceKeypoint.new(k.Time,c))
	end
	return ColorSequence.new(keys),changed
end
-- Recolour one instance (an emitter, a trail, a beam, a light, a glowing part). Returns true
-- when it was chakra and took the colour.
function Tint.apply(x,target)
	if not target or x:GetAttribute("ChakraTinted") then return false end
	local changed=false
	if x:IsA("ParticleEmitter") or x:IsA("Trail") or x:IsA("Beam") then
		local cs;cs,changed=seq(x.Color,target)
		if changed then x.Color=cs end
	elseif x:IsA("PointLight") or x:IsA("SpotLight") or x:IsA("SurfaceLight") then
		local c;c,changed=Tint.shift(x.Color,target)
		if changed then x.Color=c end
	elseif x:IsA("BasePart") and (x.Material==Enum.Material.Neon or x.Material==Enum.Material.ForceField or x.Material==Enum.Material.Glass) then
		local c;c,changed=Tint.shift(x.Color,target)
		if changed then x.Color=c end
	end
	if changed then x:SetAttribute("ChakraTinted",true) end
	return changed
end
function Tint.applyAll(root,target)
	local n=0
	if Tint.apply(root,target) then n+=1 end
	for _,x in root:GetDescendants() do if Tint.apply(x,target) then n+=1 end end
	return n
end
local function same(a,b) return a and b and math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B)<.02 end

-- The colour of a fighter: his player's NinjaChakra. In the duel the local player's body is
-- "PlayerFighter"; any other body names its player (UserId attribute, or a character).
function Tint.colorOf(model)
	if not model then return nil end
	local own=model:GetAttribute("NinjaChakra")
	if typeof(own)=="Color3" then return own end
	-- (each lookup guarded: the headless test scenes stub Players)
	local player
	pcall(function() player=Players:GetPlayerFromCharacter(model) end)
	if not player and model.Name=="PlayerFighter" then pcall(function() player=Players.LocalPlayer end) end
	if not player then
		local uid=tonumber(model:GetAttribute("UserId") or model.Name)
		if uid then pcall(function() player=Players:GetPlayerByUserId(uid) end) end
	end
	local c
	pcall(function() c=player and player:GetAttribute("NinjaChakra") end)
	if typeof(c)=="Color3" and not same(c,Tint.BASE) then return c end
	return nil
end

-- ------------------------------------------------------------------ in the duel and in Konoha
local function position(x)
	local p=x
	while p and not p:IsA("BasePart") and not p:IsA("Attachment") do p=p.Parent end
	if not p then return nil end
	return if p:IsA("Attachment") then p.WorldPosition else p.Position
end
function Tint.install(FX)
	local layer={name="ChakraTint",bodies=setmetatable({},{__mode="k"})}
	local function watchBody(model)
		if layer.bodies[model] then return end
		layer.bodies[model]={}
		local c=Tint.colorOf(model)
		if c then Tint.applyAll(model,c) end
		layer.bodies[model].conn=model.DescendantAdded:Connect(function(x)
			local col=Tint.colorOf(model)
			if col then task.defer(function() if x.Parent then Tint.apply(x,col) end end) end
		end)
	end
	local function watchFolder(fx)
		if layer.folder==fx.folder or not fx.folder then return end
		layer.folder=fx.folder
		if layer.folderConn then layer.folderConn:Disconnect() end
		layer.folderConn=fx.folder.DescendantAdded:Connect(function(x)
			task.defer(function()
				if not x.Parent then return end
				local at=position(x)
				if not at then return end
				local best,score
				for model,st in layer.bodies do
					local root=model.Parent and model:FindFirstChild("HumanoidRootPart")
					if root then
						local d=(root.Position-at).Magnitude
						if d<=Tint.REACH then
							local s=d-(if st.busy then 5 else 0)
							if not score or s<score then best,score=model,s end
						end
					end
				end
				local col=best and Tint.colorOf(best)
				if col then Tint.apply(x,col) end
			end)
		end)
	end
	-- (never throws: Effects calls the layers' fighter unguarded on one of its paths)
	layer.fighter=function(self,model,actor)
		if not model then return end
		pcall(function()
			watchBody(model)
			layer.bodies[model].busy=actor.castId~=nil or actor.attackName~=nil
			watchFolder(self)
		end)
	end
	-- Konoha: every player's character (his chakra on his own body: auras, emote effects)
	function layer.start()
		local function track(player)
			player.CharacterAdded:Connect(function(ch) watchBody(ch) end)
			if player.Character then watchBody(player.Character) end
			player:GetAttributeChangedSignal("NinjaChakra"):Connect(function()
				local ch=player.Character
				local c=ch and Tint.colorOf(ch)
				if ch and c then
					for _,x in ch:GetDescendants() do x:SetAttribute("ChakraTinted",nil) end
					Tint.applyAll(ch,c)
				end
			end)
		end
		for _,p in Players:GetPlayers() do task.spawn(track,p) end
		Players.PlayerAdded:Connect(track)
	end
	table.insert(FX.layers,layer)
	return layer
end

return Tint
