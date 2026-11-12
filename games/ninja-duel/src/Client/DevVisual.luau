-- Studio visual tool (F7): light, shadows, how visible every effect is, and a
-- live list of everything that breaks during a fight (requested 08/11/2026:
-- « un outil sur la visibilité des effets, lumières, ombres du jeu et tout ce
-- qui bug »).
--
-- F7 cycles: closed → panel (combat input held, like F6) → small HUD that
-- leaves the fight playable → closed.
--   * Lumière : the game's look (Client/WorldLook) or a test preset, hour,
--     exposure, global shadows, post-effects; live readout of the lighting.
--   * Effets  : hide or show each family of effects on this screen only
--     (particles, beams and trails, lights, highlights, 2D sprites, effect
--     shapes, ground marks, post-effects), outlines round every live effect,
--     particles frozen or slowed, live counters against the engine's limits.
--   * Problèmes : script errors and warnings (client and server), images that
--     do not load, effects that cast shadows, never disappear or float, too
--     many lights or highlights, the camera inside an effect, bodies left
--     invisible, animations not loaded, frame spikes. Click a line to see the
--     object in the world; « Rapport » prints everything to Output.
-- Nothing here changes the game: lighting and visibility are changed on this
-- client only and « Remettre le jeu » (or closing the tool) puts them back.
-- Debug/QA places only (build.py DEBUG_SOURCES), loaded by DevClient.
local Visual={}

local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local LogService=game:GetService("LogService")
local ContentProvider=game:GetService("ContentProvider")
local Stats=game:GetService("Stats")
local UserInputService=game:GetService("UserInputService")

local TAG="[NinjaDuelVisual]"
local OWN="DevVisual"
local HIGHLIGHT_LIMIT=31
-- Containers the game draws its effects in. WorldMemory holds the arena's
-- ground marks (Server/WorldReaction); "Effects" is the match folder the
-- server uses for hitboxes and contact markers (Combat:effect).
local FX_ROOTS={NinjaDuelFX=true,VfxMesh=true,NinjaUltimateFX=true,Effects=true,LocalImpact=true}
local MARK_ROOTS={WorldMemory=true}
local MARK_NAMES={"Scar","Mark","Crater","Crack","Scorch","Burn","Rubble","Furrow","Trench","Slab"}
local HITBOX={BanglaHitbox=true}
-- The menu's 3D sets are lit and filmed only in the menu: not the duel's picture.
local SKIP_ROOTS={NinjaDuelMenuStage=true,NinjaDuelPortraitStage=true}
-- Solid pieces of broken ground (Client/GroundFX) belong with the ground marks.
local GROUND_PIECES={GroundBlock=true}

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
-- Lighting.Technology is not readable by game scripts (Studio sets it); kept
-- behind a pcall so the readout says so instead of breaking.
local function techName()
	local ok,name=pcall(function() return Lighting.Technology.Name end)
	return if ok then name else "non lisible en jeu"
end
local SEV={erreur={order=1,color=rgb(255,96,86),label="ERREUR"},voir={order=2,color=rgb(255,190,80),label="À VOIR"},info={order=3,color=rgb(170,180,196),label="INFO"}}

-- Test lighting. Values for « Fin d'après-midi » are the filming setup of
-- 06/11 (claude/prepa-tournage-lee-itachi). Post-effects are left to the toggle.
local PRESETS={
	{key="jeu",name="Jeu (d'origine)"},
	{key="film",name="Fin d'après-midi (film)",light={ClockTime=16.8,GeographicLatitude=35,Brightness=3.4,ExposureCompensation=-.1,Ambient=rgb(96,90,100),OutdoorAmbient=rgb(140,124,112),EnvironmentDiffuseScale=.8,EnvironmentSpecularScale=.4}},
	{key="midi",name="Midi plein soleil",light={ClockTime=12.5,GeographicLatitude=30,Brightness=3,ExposureCompensation=0,Ambient=rgb(120,120,126),OutdoorAmbient=rgb(150,150,156),ColorShift_Top=rgb(255,255,255),ColorShift_Bottom=rgb(120,120,140)}},
	{key="contre",name="Contre-jour",light={ClockTime=17.7,GeographicLatitude=36,Brightness=3.8,ExposureCompensation=0,Ambient=rgb(70,66,84),OutdoorAmbient=rgb(100,94,116)}},
	{key="nuit",name="Nuit",light={ClockTime=0.5,GeographicLatitude=36,Brightness=1,ExposureCompensation=0,Ambient=rgb(36,40,58),OutdoorAmbient=rgb(54,60,86),ColorShift_Top=rgb(150,170,255),ColorShift_Bottom=rgb(40,44,70)}},
	{key="gris",name="Gris neutre (juger un effet)",light={ClockTime=14,GeographicLatitude=30,Brightness=2,ExposureCompensation=0,Ambient=rgb(128,128,128),OutdoorAmbient=rgb(128,128,128),EnvironmentDiffuseScale=0,EnvironmentSpecularScale=0,ColorShift_Top=rgb(0,0,0),ColorShift_Bottom=rgb(0,0,0)},post=false},
}
local FAMILIES={
	{key="particles",name="Particules"},
	{key="beams",name="Faisceaux / traînées"},
	{key="lights",name="Lumières"},
	{key="highlights",name="Surbrillances (contours)"},
	{key="sprites",name="Sprites 2D"},
	{key="shapes",name="Formes d'effet"},
	{key="marks",name="Marques au sol"},
	{key="post",name="Post-effets"},
}

local function path(inst)
	if not inst then return "?" end
	local ok,full=pcall(function() return inst:GetFullName() end)
	return if ok then full else inst.Name
end
local function isOwn(inst)
	local node=inst
	while node do
		if string.sub(node.Name,1,#OWN)==OWN or node.Name=="DevObservedVolume" or node.Name=="NinjaDuelDevPanel" then return true end
		node=node.Parent
	end
	return false
end
local function rootOf(inst,set)
	local node=inst.Parent
	while node and node~=game do
		if set[node.Name] then return node end
		node=node.Parent
	end
	return nil
end
local function fighterOf(inst)
	local node=inst.Parent
	while node and node~=workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then return node end
		node=node.Parent
	end
	return nil
end
local function isMarkName(name)
	if string.find(name,"Marked",1,true) then return false end -- Minato's marked kunai is a weapon, not a mark
	for _,prefix in MARK_NAMES do if string.find(name,prefix,1,true) then return true end end
	return false
end
-- Marks drawn flat on the ground or a wall (server ground damage, scars,
-- craters, scorches): only these must touch a surface. Seals, glyphs and
-- burning pieces can stand or float by design.
local FLAT_MARKS={"Scar","Crater","Crack","Scorch","FXGround"}
local function flatMark(inst)
	local node=inst
	while node and node~=workspace do
		if MARK_ROOTS[node.Name] then return true end
		if FX_ROOTS[node.Name] then return false end
		for _,word in FLAT_MARKS do if string.find(node.Name,word,1,true) then return true end end
		node=node.Parent
	end
	return false
end
-- Highlights that are meant to stay (ink outline, chakra rims, auras).
local function deliberate(name)
	for _,word in {"Ink","Rim","Aura","Outline","Line","Mode"} do if string.find(name,word,1,true) then return true end end
	return false
end
-- A ground mark is often a model of plain parts (FireScorch made of Wedges):
-- the name that says « mark » can be on any ancestor below the effect folder.
local function markAncestor(inst)
	local node=inst
	while node and node~=workspace and not FX_ROOTS[node.Name] do
		if isMarkName(node.Name) or node.Name=="FXGround" or GROUND_PIECES[node.Name] then return true end
		node=node.Parent
	end
	return false
end
local function visiblePart(p)
	return p.Transparency<.9 and p.LocalTransparencyModifier<.9 and p.Size.Magnitude>.15
end

function Visual.install(ctx,dev)
	if not RunService:IsStudio() then return nil end
	local player=ctx.player
	local playerGui=player:WaitForChild("PlayerGui")
	local camera=workspace.CurrentCamera
	local okLook,WorldLook=pcall(require,script.Parent.WorldLook)
	if not okLook then WorldLook=nil end
	local self={mode=0,blocking=false,tab="problemes"}

	-- ------------------------------------------------------------ tracking
	-- Every effect-like object is followed from its birth (age, family, where).
	local tracked=setmetatable({},{__mode="k"})
	local function classify(inst)
		if isOwn(inst) or rootOf(inst,SKIP_ROOTS) then return nil end
		if inst:IsA("ParticleEmitter") then return "particles"
		elseif inst:IsA("Beam") or inst:IsA("Trail") then return "beams"
		elseif inst:IsA("Light") then return "lights"
		elseif inst:IsA("Highlight") then return "highlights"
		elseif inst:IsA("BillboardGui") or (inst:IsA("SurfaceGui") and inst.Adornee) then return "sprites"
		elseif inst:IsA("Decal") then
			if rootOf(inst,MARK_ROOTS) or markAncestor(inst) then return "marks" end
			if rootOf(inst,FX_ROOTS) then return "shapes" end
			return nil
		elseif inst:IsA("BasePart") then
			if HITBOX[inst.Name] or inst:IsA("Terrain") then return nil end
			if rootOf(inst,MARK_ROOTS) or (markAncestor(inst) and not fighterOf(inst)) then return "marks" end
			if rootOf(inst,FX_ROOTS) or inst.Name=="LocalImpact" then return "shapes" end
			return nil
		end
		return nil
	end
	local function track(inst)
		if tracked[inst] then return end
		local family=classify(inst)
		if family then
			local body=fighterOf(inst)
			tracked[inst]={family=family,born=os.clock(),body=body,fx=body~=nil or rootOf(inst,FX_ROOTS)~=nil or inst.Parent==workspace.Terrain or (inst.Parent~=nil and inst.Parent.Parent==workspace.Terrain)}
		end
	end

	-- ------------------------------------------------------------ issues
	local issues={}
	local order={}
	local dirty=true
	local showInfo=true
	local function report(sev,title,detail,inst,key)
		key=key or (title.."|"..(if inst then path(inst) else detail or ""))
		local now=os.clock()
		local entry=issues[key]
		if entry then
			entry.count+=1;entry.last=now;entry.clock=os.date("%H:%M:%S");entry.detail=detail or entry.detail
			if inst then entry.inst=inst end
		else
			if #order>=240 then
				local oldest=table.remove(order,#order);issues[oldest.key]=nil
			end
			entry={key=key,sev=sev,title=title,detail=detail or "",path=if inst then path(inst) else "",count=1,first=now,last=now,clock=os.date("%H:%M:%S"),inst=inst}
			setmetatable(entry,{__mode="v"})
			issues[key]=entry
			table.insert(order,1,entry)
		end
		dirty=true
		return entry
	end

	-- Script errors and warnings of this client, and of the server (DevHooks
	-- relays them on NinjaDuelDevLog as "serverlog").
	LogService.MessageOut:Connect(function(message,kind)
		if string.find(message,TAG,1,true) then return end
		if kind==Enum.MessageType.MessageError then
			report("erreur","Erreur de script (client)",string.sub(message,1,300),nil,"errc|"..string.sub(message,1,160))
		elseif kind==Enum.MessageType.MessageWarning then
			report("info","Avertissement (client)",string.sub(message,1,300),nil,"warnc|"..string.sub(message,1,160))
		end
	end)
	task.spawn(function()
		local log=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuelDevLog",15)
		if not log then return end
		log.OnClientEvent:Connect(function(kind,value)
			if kind~="serverlog" or type(value)~="table" or type(value.m)~="string" then return end
			if string.find(value.m,TAG,1,true) then return end
			if value.k=="error" then
				report("erreur","Erreur de script (serveur)",string.sub(value.m,1,300),nil,"errs|"..string.sub(value.m,1,160))
			else
				report("info","Avertissement (serveur)",string.sub(value.m,1,300),nil,"warns|"..string.sub(value.m,1,160))
			end
		end)
	end)

	-- Images and meshes: a texture that fails to load draws nothing (or a
	-- white square for an emitter without a texture).
	local assetSeen={}
	local function assetOf(inst)
		if inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail") or inst:IsA("Decal") then return inst.Texture
		elseif inst:IsA("MeshPart") then return inst.TextureID ~= "" and inst.TextureID or inst.MeshId
		end
		return nil
	end
	local function checkAsset(inst)
		local id=assetOf(inst)
		if id==nil then return end
		if id=="" then
			if inst:IsA("ParticleEmitter") then report("voir","Particules sans image (carré blanc)",inst.Name,inst) end
			return
		end
		local seen=assetSeen[id]
		if seen and seen.ok then return end
		local now=os.clock()
		if seen and now-seen.at<4 then
			report("erreur","Image ou maillage qui ne charge pas",id,inst,"asset|"..id)
			return
		end
		local ok,status=pcall(function() return ContentProvider:GetAssetFetchStatus(id) end)
		if not ok then return end
		if status==Enum.AssetFetchStatus.Success then
			assetSeen[id]={ok=true,at=now}
			-- Failed first, loaded later (Roblox « content representation is
			-- being generated »): the effect was invisible the first times only.
			local entry=issues["asset|"..id]
			if entry and entry.sev=="erreur" then
				entry.sev="voir";entry.title="Image qui a d'abord échoué, puis s'est chargée";entry.detail=id.." (l'effet était invisible au début)";dirty=true
			end
		elseif status==Enum.AssetFetchStatus.Failure or status==Enum.AssetFetchStatus.TimedOut then
			assetSeen[id]={ok=false,at=now}
			report("erreur","Image ou maillage qui ne charge pas",id,inst,"asset|"..id)
		end
	end

	-- ------------------------------------------------------------ visibility
	-- Hidden families: each object's own value is kept and given back.
	local hidden={}
	local saved=setmetatable({},{__mode="k"})
	local INVISIBLE=NumberSequence.new(1)
	local postSaved={}
	local function postEffects()
		local list={}
		for _,e in Lighting:GetChildren() do
			if e:IsA("PostEffect") or e:IsA("Atmosphere") then table.insert(list,e) end
		end
		if camera then for _,e in camera:GetChildren() do if e:IsA("PostEffect") then table.insert(list,e) end end end
		return list
	end
	local function hide(inst,family)
		if saved[inst]~=nil then return end
		pcall(function()
			if family=="particles" then saved[inst]=inst.Transparency;inst.Transparency=INVISIBLE
			elseif family=="beams" or family=="lights" or family=="highlights" or family=="sprites" then saved[inst]=inst.Enabled;inst.Enabled=false
			elseif inst:IsA("BasePart") or inst:IsA("Decal") then saved[inst]=inst.LocalTransparencyModifier;inst.LocalTransparencyModifier=1 end
		end)
	end
	local function show(inst,family)
		local value=saved[inst]
		if value==nil then return end
		saved[inst]=nil
		pcall(function()
			if family=="particles" then inst.Transparency=value
			elseif family=="beams" or family=="lights" or family=="highlights" or family=="sprites" then inst.Enabled=value
			else inst.LocalTransparencyModifier=value end
		end)
	end
	local function setFamily(family,isHidden)
		hidden[family]=isHidden or nil
		if family=="post" then
			if isHidden then
				for _,e in postEffects() do
					if postSaved[e]==nil then
						if e:IsA("Atmosphere") then postSaved[e]=e.Parent;e.Parent=nil else postSaved[e]=e.Enabled;e.Enabled=false end
					end
				end
			else
				for e,value in postSaved do
					pcall(function() if e:IsA("Atmosphere") then e.Parent=value else e.Enabled=value end end)
				end
				table.clear(postSaved)
			end
			return
		end
		for inst,info in tracked do
			if info.family==family and inst.Parent then
				if isHidden then hide(inst,family) else show(inst,family) end
			end
		end
	end

	-- Lighting: the game's look lives in Client/WorldLook, which re-applies it
	-- every second unless it is « borrowed » (Client/MenuStage does the same).
	local preset="jeu"
	local function applyPreset(key)
		preset=key
		if key=="jeu" then
			if WorldLook then WorldLook.borrowed=false;pcall(WorldLook.apply) end
			if hidden.post then setFamily("post",false) end
			return
		end
		local def
		for _,p in PRESETS do if p.key==key then def=p end end
		if not def then return end
		if WorldLook then WorldLook.borrowed=true end
		for k,v in def.light do pcall(function() (Lighting::any)[k]=v end) end
		if def.post==false then setFamily("post",true) end
	end
	local function nudge(prop,delta,lo,hi)
		if WorldLook then WorldLook.borrowed=true end
		if preset=="jeu" then preset="perso" end
		local value=(Lighting::any)[prop]+delta
		if prop=="ClockTime" then value=value%24 else value=math.clamp(value,lo,hi) end
		pcall(function() (Lighting::any)[prop]=value end)
	end

	-- Outlines round every live effect (and in red round the ones in trouble).
	local outlines={}
	local outlinesOn=false
	local flagged=setmetatable({},{__mode="k"})
	local function clearOutlines() for _,b in outlines do b:Destroy() end;table.clear(outlines) end
	local function updateOutlines()
		if not outlinesOn then if next(outlines) then clearOutlines() end return end
		local wanted={}
		local n=0
		for inst,info in tracked do
			if n>=80 then break end
			local part=if inst:IsA("BasePart") then inst elseif inst.Parent and inst.Parent:IsA("BasePart") then inst.Parent elseif inst.Parent and inst.Parent:IsA("Attachment") and inst.Parent.Parent and inst.Parent.Parent:IsA("BasePart") then inst.Parent.Parent else nil
			if part and part.Parent and not wanted[part] then wanted[part]=flagged[inst] or flagged[part] or false;n+=1 end
		end
		for part,box in outlines do if wanted[part]==nil or not part.Parent then box:Destroy();outlines[part]=nil end end
		for part,bad in wanted do
			local box=outlines[part]
			if not box then
				box=Instance.new("SelectionBox");box.Name="DevVisualOutline";box.Adornee=part;box.LineThickness=.04;box.Parent=playerGui;outlines[part]=box
			end
			box.Color3=if bad then rgb(255,70,60) else rgb(80,220,255)
		end
	end
	local function focus(inst)
		if not inst or not inst.Parent then print(TAG,"objet disparu");return end
		local part=if inst:IsA("BasePart") then inst else inst:FindFirstAncestorWhichIsA("BasePart")
		if inst:IsA("Model") then part=inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart") end
		print(TAG,"objet :",path(inst),inst.ClassName)
		if part then
			local box=Instance.new("SelectionBox");box.Name="DevVisualFocus";box.Adornee=part;box.Color3=rgb(255,240,80);box.LineThickness=.08;box.Parent=playerGui
			task.delay(3,function() box:Destroy() end)
		end
	end

	-- ------------------------------------------------------------ scan
	local counters={}
	local fps=60
	local frameSpikes=0
	local worstFrame=0
	local bodySince=setmetatable({},{__mode="k"})
	local highlightSince=setmetatable({},{__mode="k"})
	local trackSince=setmetatable({},{__mode="k"})
	local markChecked=setmetatable({},{__mode="k"})
	local blockedSince=nil
	local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude
	local function floorUnder(position,exclude)
		rayParams.FilterDescendantsInstances=exclude
		return workspace:Raycast(position+Vector3.new(0,3,0),Vector3.new(0,-40,0),rayParams)
	end
	local function fighters()
		local list={}
		local me=player.Character
		if me then table.insert(list,me) end
		local data=ctx.state and ctx.state()
		local folder=me and me.Parent
		local other=folder and data and data.bot and folder:FindFirstChild(data.bot.id or "")
		if other then table.insert(list,other) end
		return list,folder
	end
	local function scan()
		local now=os.clock()
		table.clear(flagged)
		local c={particles=0,particlesOn=0,beams=0,lights=0,fxLights=0,lightsShadow=0,highlights=0,sprites=0,shapes=0,marks=0,total=0}
		local bodies=fighters()
		-- The floor probe skips bodies, effects and the marks themselves.
		local exclude={}
		for _,b in bodies do table.insert(exclude,b) end
		for _,name in {"NinjaDuelFX","VfxMesh","NinjaUltimateFX"} do local f=workspace:FindFirstChild(name);if f then table.insert(exclude,f) end end
		for inst,info in tracked do
			if info.family=="marks" then
				local r=rootOf(inst,MARK_ROOTS)
				if r and not table.find(exclude,r) then table.insert(exclude,r) end
			end
		end
		local camPos=camera and camera.CFrame.Position
		local neonArea=0
		for inst,info in tracked do
			if not inst.Parent then tracked[inst]=nil;continue end
			if isOwn(inst) then tracked[inst]=nil;continue end
			c.total+=1
			if info.family=="shapes" and markAncestor(inst) then info.family="marks" end
			local family=info.family
			local age=now-info.born
			if hidden[family] then hide(inst,family) end
			if family=="particles" then
				c.particles+=1
				if inst.Enabled and inst.Rate>0 then
					c.particlesOn+=1
					if not info.body and age>12 and rootOf(inst,FX_ROOTS) then flagged[inst]=true;report("voir","Émetteur resté allumé",string.format("%s, %.0f s",inst.Name,age),inst) end
				end
				checkAsset(inst)
			elseif family=="beams" then c.beams+=1;checkAsset(inst)
			elseif family=="lights" then
				if inst.Enabled then
					c.lights+=1
					if info.fx then
						c.fxLights+=1
						if inst.Shadows then c.lightsShadow+=1;flagged[inst]=true;report("voir","Lumière d'effet avec ombres (coûteux, ombres qui tremblent)",inst.Name,inst) end
						if inst.Brightness>10 then flagged[inst]=true;report("voir","Lumière très forte (éblouit)",string.format("%s, luminosité %.0f",inst.Name,inst.Brightness),inst) end
					end
				end
			elseif family=="highlights" then
				if inst.Enabled then
					c.highlights+=1
					if not deliberate(inst.Name) and inst.FillTransparency<.95 then
						local since=highlightSince[inst] or now;highlightSince[inst]=since
						if now-since>4 then flagged[inst]=true;report("voir","Surbrillance restée allumée",string.format("%s sur %s, %.0f s",inst.Name,inst.Parent and inst.Parent.Name or "?",now-since),inst) end
					else
						highlightSince[inst]=nil
					end
				end
			elseif family=="sprites" then
				if inst.Enabled then c.sprites+=1 end
				if inst:IsA("BillboardGui") and inst.Enabled and not inst.Adornee and not inst.Parent:IsA("BasePart") and not inst.Parent:IsA("Attachment") then
					report("info","Sprite 2D sans support (ne s'affiche nulle part)",inst.Name,inst)
				end
			elseif family=="shapes" or family=="marks" then
				if family=="shapes" then c.shapes+=1 else c.marks+=1 end
				if inst:IsA("BasePart") then
					local p=inst.Position
					if p~=p or p.Magnitude>20000 then report("voir","Effet perdu (position folle)",inst.Name,inst);continue end
					local vis=visiblePart(inst)
					if family=="shapes" then
						if inst.CanCollide and not inst:FindFirstAncestorWhichIsA("Model") then flagged[inst]=true;report("erreur","Effet qui bloque les corps (CanCollide)",inst.Name,inst) end
						local glowing=inst.Material==Enum.Material.Neon or inst.Material==Enum.Material.ForceField or inst.Material==Enum.Material.Glass
						if vis and inst.CastShadow and glowing then flagged[inst]=true;report("voir","Effet lumineux qui projette une ombre",string.format("%s (%s)",inst.Name,inst.Material.Name),inst)
						elseif vis and inst.CastShadow and inst.Transparency>.2 then report("info","Objet qui s'efface en gardant toute son ombre",string.format("%s (%s, transparence %.2f)",inst.Name,inst.Material.Name,inst.Transparency),inst) end
						if vis and inst.Material==Enum.Material.Neon then
							local s=inst.Size;local dims={s.X,s.Y,s.Z};table.sort(dims)
							local area=dims[2]*dims[3]*(1-inst.Transparency)
							neonArea+=area
							if area>80 then flagged[inst]=true;report("voir","Grande surface Néon (éblouit)",string.format("%s, %.0f studs²",inst.Name,area),inst) end
						end
						if vis and age>20 and not inst:GetAttribute("Persistent") then flagged[inst]=true;report("voir","Effet qui ne disparaît pas",string.format("%s, %.0f s",inst.Name,age),inst) end
						if vis and camPos and inst.Size.Magnitude>4 then
							local rel=inst.CFrame:PointToObjectSpace(camPos);local h=inst.Size/2
							if math.abs(rel.X)<h.X and math.abs(rel.Y)<h.Y and math.abs(rel.Z)<h.Z then report("voir","La caméra est dans un effet (écran couvert)",inst.Name,inst) end
						end
					elseif vis and (not markChecked[inst] or now-markChecked[inst]>5) and age>.5 and not GROUND_PIECES[inst.Name] then
						markChecked[inst]=now
						local probe=table.clone(exclude);table.insert(probe,inst)
						local hit=floorUnder(p,probe)
						-- Thin axis = the side the mark is drawn on (floor or wall):
						-- it has to touch a surface there, within half a stud.
						local s=inst.Size;local cf=inst.CFrame
						local axis,thick=cf.RightVector,s.X
						if s.Y<thick then axis,thick=cf.UpVector,s.Y end
						if s.Z<thick then axis,thick=cf.LookVector,s.Z end
						rayParams.FilterDescendantsInstances=probe
						local reach=thick/2+.6
						local touch=workspace:Raycast(p,axis*reach,rayParams) or workspace:Raycast(p,-axis*reach,rayParams)
						if not touch and hit and p.Y-hit.Position.Y>.6 and flatMark(inst) then
							flagged[inst]=true
							report("voir","Marque au sol en l'air",string.format("%s, %.1f studs au-dessus du sol, aucune surface sous sa face",inst.Name,p.Y-hit.Position.Y),inst)
						end
						if hit then
							local half=.5*(math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z)
							if p.Y+half<hit.Position.Y-.4 then report("info","Marque enterrée (invisible)",inst.Name,inst) end
						end
					end
				end
				checkAsset(inst)
			end
		end
		if c.highlights>HIGHLIGHT_LIMIT-6 then
			report("erreur","Trop de surbrillances",string.format("%d sur %d : au-delà, Roblox n'en dessine plus (les contours des corps disparaissent)",c.highlights,HIGHLIGHT_LIMIT),nil,"highlight-limit")
		end
		if c.fxLights>10 then report("voir","Trop de lumières d'effet en même temps",tostring(c.fxLights),nil,"light-count") end
		if c.total>800 then report("voir","Trop d'objets d'effet en même temps",tostring(c.total),nil,"fx-count") end
		c.neonArea=neonArea
		-- Bodies: invisible for long, or an animation that never loaded.
		for _,body in bodies do
			local sum,n=0,0
			for _,part in body:GetChildren() do
				if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then sum+=math.max(part.Transparency,part.LocalTransparencyModifier);n+=1 end
			end
			local faded=n>0 and sum/n>.6
			if faded then
				local since=bodySince[body] or now;bodySince[body]=since
				if now-since>3 then report("info","Corps presque invisible depuis plus de 3 s",body.Name,body,"faded|"..body.Name) end
			else bodySince[body]=nil end
			local hum=body:FindFirstChildOfClass("Humanoid")
			local animator=hum and hum:FindFirstChildOfClass("Animator")
			if animator then
				for _,t in animator:GetPlayingAnimationTracks() do
					if t.Length==0 then
						local since=trackSince[t] or now;trackSince[t]=since
						if now-since>.6 then report("voir","Animation pas chargée",t.Animation and t.Animation.AnimationId or t.Name,body,"anim|"..(t.Animation and t.Animation.AnimationId or t.Name)) end
					end
				end
			end
		end
		-- Decor between the camera and the player's fighter (a trunk, a wall):
		-- the player loses sight of himself.
		local me=player.Character
		local head=me and (me:FindFirstChild("Head") or me:FindFirstChild("HumanoidRootPart"))
		if head and camPos then
			rayParams.FilterDescendantsInstances=exclude
			local hitCam=workspace:Raycast(camPos,head.Position-camPos,rayParams)
			if hitCam and hitCam.Instance.Transparency<.5 and not fighterOf(hitCam.Instance) then
				blockedSince=blockedSince or now
				if now-blockedSince>.8 then report("voir","Le décor cache le joueur",string.format("%s, depuis %.1f s",hitCam.Instance.Name,now-blockedSince),hitCam.Instance,"occlusion|"..hitCam.Instance.Name) end
			else
				blockedSince=nil
			end
		end
		-- Lighting the tool did not set.
		if preset=="jeu" then
			if not Lighting.GlobalShadows then report("voir","Ombres globales coupées (Lighting.GlobalShadows)","",nil,"light-globalshadows") end
			if math.abs(Lighting.ExposureCompensation)>1 then report("info","Exposition inhabituelle",string.format("%.2f",Lighting.ExposureCompensation),nil,"light-exposure") end
		end
		local tech=techName()
		if tech=="Voxel" or tech=="Compatibility" then report("info","Ombres grossières : technologie "..tech,"",nil,"light-tech") end
		counters=c
	end

	-- ------------------------------------------------------------ interface
	local gui=Instance.new("ScreenGui");gui.Name="DevVisualPanel";gui.ResetOnSpawn=false;gui.DisplayOrder=111;gui.Enabled=false;gui.IgnoreGuiInset=false
	gui.Parent=playerGui
	-- Fits small Studio viewports: as tall as the screen allows, 590 px at most.
	local panel=Instance.new("Frame");panel.Name="DevVisualFrame";panel.AnchorPoint=Vector2.new(0,.5);panel.Size=UDim2.new(0,420,1,-48);panel.Position=UDim2.new(0,16,.5,0)
	local cap=Instance.new("UISizeConstraint");cap.MaxSize=Vector2.new(420,590);cap.Parent=panel
	panel.BackgroundColor3=rgb(18,22,28);panel.BackgroundTransparency=.04;panel.BorderSizePixel=0;panel.Parent=gui
	local function label(parent,text,size,pos,textSize,bold)
		local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Size=size;l.Position=pos;l.TextColor3=rgb(236,238,244);l.TextSize=textSize or 13
		l.Font=if bold then Enum.Font.GothamBold else Enum.Font.Gotham;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Top
		l.TextWrapped=true;l.RichText=true;l.Text=text;l.Parent=parent
		return l
	end
	local function button(parent,text,pos,size,callback)
		local b=Instance.new("TextButton");b.Position=pos;b.Size=size;b.BackgroundColor3=rgb(43,51,65);b.BorderSizePixel=0
		b.TextColor3=rgb(240,240,245);b.TextSize=12;b.Font=Enum.Font.Gotham;b.TextWrapped=true;b.Text=text;b.AutoButtonColor=true;b.Parent=parent
		b.Activated:Connect(callback)
		return b
	end
	label(panel,"VISUEL / F7 — lumière, ombres, effets, bugs",UDim2.new(1,-16,0,20),UDim2.fromOffset(8,6),15,true)
	local hint=label(panel,"F7 : panneau → bandeau (on peut jouer) → fermé",UDim2.new(1,-16,0,16),UDim2.fromOffset(8,26),11)
	hint.TextColor3=rgb(150,160,176)
	local pages={}
	local tabButtons={}
	local function page(key)
		local f=Instance.new("Frame");f.Name="Page_"..key;f.BackgroundTransparency=1;f.Size=UDim2.new(1,-16,1,-84);f.Position=UDim2.fromOffset(8,80);f.Visible=false;f.Parent=panel
		pages[key]=f
		return f
	end
	local function selectTab(key)
		self.tab=key
		for k,f in pages do f.Visible=k==key end
		for k,b in tabButtons do b.BackgroundColor3=if k==key then rgb(70,96,140) else rgb(43,51,65) end
		dirty=true
	end
	for i,t in {{"lumiere","Lumière"},{"effets","Effets"},{"problemes","Problèmes"}} do
		tabButtons[t[1]]=button(panel,t[2],UDim2.fromOffset(8+(i-1)*136,46),UDim2.fromOffset(130,28),function() selectTab(t[1]) end)
	end

	-- Lumière
	local light=page("lumiere")
	local lightText=label(light,"",UDim2.new(1,0,0,170),UDim2.fromOffset(0,0),12)
	local presetButtons={}
	for i,p in PRESETS do
		local col=(i-1)%2;local row=math.floor((i-1)/2)
		presetButtons[p.key]=button(light,p.name,UDim2.fromOffset(col*204,176+row*32),UDim2.fromOffset(198,28),function() applyPreset(p.key) end)
	end
	local y=176+math.ceil(#PRESETS/2)*32+6
	local tools={
		{"Heure −1 h",function() nudge("ClockTime",-1) end},{"Heure +1 h",function() nudge("ClockTime",1) end},
		{"Exposition −",function() nudge("ExposureCompensation",-.25,-3,3) end},{"Exposition +",function() nudge("ExposureCompensation",.25,-3,3) end},
		{"Luminosité −",function() nudge("Brightness",-.5,0,10) end},{"Luminosité +",function() nudge("Brightness",.5,0,10) end},
		{"Ombres globales ON / OFF",function() if WorldLook then WorldLook.borrowed=true end;if preset=="jeu" then preset="perso" end;Lighting.GlobalShadows=not Lighting.GlobalShadows end},
		{"Post-effets ON / OFF",function() setFamily("post",not hidden.post) end},
	}
	for i,t in tools do
		local col=(i-1)%2;local row=math.floor((i-1)/2)
		button(light,t[1],UDim2.fromOffset(col*204,y+row*32),UDim2.fromOffset(198,28),t[2])
	end

	-- Effets
	local fx=page("effets")
	local fxText=label(fx,"",UDim2.new(1,0,0,150),UDim2.fromOffset(0,0),12)
	local familyButtons={}
	for i,f in FAMILIES do
		local col=(i-1)%2;local row=math.floor((i-1)/2)
		familyButtons[f.key]=button(fx,"",UDim2.fromOffset(col*204,156+row*32),UDim2.fromOffset(198,28),function()
			setFamily(f.key,not hidden[f.key]);dirty=true
		end)
	end
	local frozen=nil
	local function particleTime(scale)
		frozen=scale
		for inst,info in tracked do if info.family=="particles" and inst.Parent then pcall(function() inst.TimeScale=scale or 1 end) end end
	end
	local y2=156+math.ceil(#FAMILIES/2)*32+6
	local fxTools={
		{"Contours des effets ON / OFF",function() outlinesOn=not outlinesOn;updateOutlines() end},
		{"Tout afficher",function() for _,f in FAMILIES do setFamily(f.key,false) end end},
		{"Particules figées",function() particleTime(if frozen==0 then nil else 0) end},
		{"Particules au ralenti ×0,2",function() particleTime(if frozen==.2 then nil else .2) end},
		{"Couper les ombres des effets",function()
			for inst,info in tracked do if info.family=="shapes" and inst:IsA("BasePart") then pcall(function() inst.CastShadow=false end) end end
			print(TAG,"ombres des effets coupées sur cet écran (essai seulement : la correction se fait dans src/)")
		end},
		{"Remettre le jeu",function() Visual.restore(self) end},
	}
	for i,t in fxTools do
		local col=(i-1)%2;local row=math.floor((i-1)/2)
		button(fx,t[1],UDim2.fromOffset(col*204,y2+row*32),UDim2.fromOffset(198,28),t[2])
	end

	-- Problèmes
	local probs=page("problemes")
	local probSummary=label(probs,"",UDim2.new(1,0,0,34),UDim2.fromOffset(0,0),12)
	local list=Instance.new("ScrollingFrame");list.Name="DevVisualList";list.Size=UDim2.new(1,0,1,-80);list.Position=UDim2.fromOffset(0,38)
	list.BackgroundColor3=rgb(12,15,20);list.BorderSizePixel=0;list.ScrollBarThickness=6;list.CanvasSize=UDim2.new();list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.Parent=probs
	local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,2);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=list
	local rows={}
	local function rebuildList()
		for _,r in rows do r:Destroy() end;table.clear(rows)
		local sorted={}
		for _,e in order do if showInfo or e.sev~="info" then table.insert(sorted,e) end end
		table.sort(sorted,function(a,b)
			if SEV[a.sev].order~=SEV[b.sev].order then return SEV[a.sev].order<SEV[b.sev].order end
			return a.last>b.last
		end)
		for i,e in sorted do
			if i>120 then break end
			local r=Instance.new("TextButton");r.LayoutOrder=i;r.Size=UDim2.new(1,-8,0,0);r.AutomaticSize=Enum.AutomaticSize.Y
			r.BackgroundColor3=rgb(26,31,40);r.BorderSizePixel=0;r.TextXAlignment=Enum.TextXAlignment.Left;r.TextWrapped=true;r.RichText=true
			r.Font=Enum.Font.Gotham;r.TextSize=12;r.TextColor3=rgb(225,228,235)
			local c=SEV[e.sev].color
			r.Text=string.format('<font color="#%s"><b>%s</b></font> %s ×%d  <b>%s</b>%s',c:ToHex(),SEV[e.sev].label,e.clock,e.count,e.title,
				if e.detail~="" then "<br/>"..string.gsub(string.gsub(e.detail,"<","‹"),">","›") else "")
			local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,6);pad.PaddingTop=UDim.new(0,3);pad.PaddingBottom=UDim.new(0,3);pad.Parent=r
			r.Activated:Connect(function()
				print(TAG,SEV[e.sev].label,e.title,"|",e.detail,"|",e.path,"| ×"..e.count)
				focus(e.inst)
			end)
			r.Parent=list
			table.insert(rows,r)
		end
	end
	local probTools={
		{"Effacer la liste",function() table.clear(issues);table.clear(order);dirty=true end},
		{"Rapport → Output",function() Visual.report(self) end},
		{"Infos ON / OFF",function() showInfo=not showInfo;dirty=true end},
	}
	for i,t in probTools do
		button(probs,t[1],UDim2.new(0,(i-1)*136,1,-36),UDim2.fromOffset(130,30),t[2])
	end

	-- Small HUD (mode 2): counters and the latest problems, never in the way of input.
	local hud=Instance.new("ScreenGui");hud.Name="DevVisualHud";hud.ResetOnSpawn=false;hud.DisplayOrder=111;hud.Enabled=false;hud.Parent=playerGui
	local hudText=label(hud,"",UDim2.fromOffset(470,20),UDim2.new(0,16,0,64),12)
	hudText.AutomaticSize=Enum.AutomaticSize.Y
	hudText.BackgroundTransparency=.35;hudText.BackgroundColor3=rgb(10,12,16);hudText.TextStrokeTransparency=.6
	local hudPad=Instance.new("UIPadding");hudPad.PaddingLeft=UDim.new(0,6);hudPad.PaddingTop=UDim.new(0,4);hudPad.Parent=hudText

	local function color(n,warn,bad) return if n>=bad then "#ff6056" elseif n>=warn then "#ffbe50" else "#9be29b" end
	local function refresh()
		local c=counters
		if not c.total then return end
		local nErr,nVoir,nInfo=0,0,0
		for _,e in order do if e.sev=="erreur" then nErr+=1 elseif e.sev=="voir" then nVoir+=1 else nInfo+=1 end end
		local partMem=0
		pcall(function() partMem=Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsParticles) end)
		local line=string.format('FPS <font color="%s">%d</font> · effets %d · particules %d (%d allumés) · lumières d’effet <font color="%s">%d</font> · surbrillances <font color="%s">%d/%d</font>',
			color(60-fps,15,30),fps,c.total,c.particles,c.particlesOn,color(c.fxLights,8,11),c.fxLights,color(c.highlights,20,25),c.highlights,HIGHLIGHT_LIMIT)
		local problems=string.format('<font color="#ff6056">%d erreur(s)</font> · <font color="#ffbe50">%d à voir</font> · %d info',nErr,nVoir,nInfo)
		if self.mode==2 then
			local recent={}
			for i,e in order do if i>3 then break end;table.insert(recent,string.format('<font color="#%s">%s</font> %s',SEV[e.sev].color:ToHex(),e.clock,e.title)) end
			hudText.Text="<b>F7</b> "..line.."<br/>"..problems..(if #recent>0 then "<br/>"..table.concat(recent,"<br/>") else "")
			return
		end
		if self.tab=="lumiere" then
			local post={}
			for _,e in postEffects() do
				local state=if e:IsA("Atmosphere") then "air" elseif e.Enabled then "ON" else "off"
				table.insert(post,e.Name.." "..state)
			end
			lightText.Text=string.format(
				"<b>Éclairage %s</b>%s<br/>Heure %.1f h · latitude %.0f° · luminosité %.2f · exposition %.2f<br/>Ombres globales <b>%s</b> · douceur %.2f · technologie <b>%s</b><br/>Ambiance %s · extérieur %s<br/>Diffus %.2f · spéculaire %.2f<br/>Post-effets : %s<br/>Lumières allumées : %d, dont %d d'effet (%d avec ombres) · surface Néon visible %.0f studs²",
				if preset=="jeu" then "du jeu (Client/WorldLook)" else "de test : "..preset,
				if WorldLook and WorldLook.borrowed then " — <font color=\"#ffbe50\">le jeu ne le réimpose pas tant que l'outil le tient</font>" else "",
				Lighting.ClockTime,Lighting.GeographicLatitude,Lighting.Brightness,Lighting.ExposureCompensation,
				if Lighting.GlobalShadows then "ON" else "OFF",Lighting.ShadowSoftness,techName(),
				Lighting.Ambient:ToHex(),Lighting.OutdoorAmbient:ToHex(),Lighting.EnvironmentDiffuseScale,Lighting.EnvironmentSpecularScale,
				if #post>0 then table.concat(post,", ") else "aucun",c.lights,c.fxLights,c.lightsShadow,c.neonArea or 0)
			for k,b in presetButtons do b.BackgroundColor3=if k==preset then rgb(70,96,140) else rgb(43,51,65) end
		elseif self.tab=="effets" then
			fxText.Text=string.format("%s<br/>Émetteurs de particules %d (%d allumés) · mémoire particules %.1f Mo<br/>Faisceaux / traînées %d · sprites 2D %d<br/>Formes d'effet %d · marques au sol %d<br/>Instances du jeu %d · saccades (&gt;60 ms) %d, pire %.0f ms%s",
				line,c.particles,c.particlesOn,partMem,c.beams,c.sprites,c.shapes,c.marks,Stats.InstanceCount,frameSpikes,worstFrame*1000,
				if frozen then string.format('<br/><font color="#ffbe50">Particules à ×%.1f</font>',frozen) else "")
			for _,f in FAMILIES do
				local b=familyButtons[f.key]
				b.Text=f.name.." : "..(if hidden[f.key] then "CACHÉ" else "visible")
				b.BackgroundColor3=if hidden[f.key] then rgb(120,60,50) else rgb(43,51,65)
			end
		elseif self.tab=="problemes" then
			probSummary.Text=problems.."<br/>Cliquer une ligne : l'objet s'entoure en jaune 3 s et son chemin part dans Output."..(if showInfo then "" else " (infos cachées)")
			if dirty then rebuildList();dirty=false end
		end
	end

	-- Input: the panel holds combat input like F6 (DevClient computes
	-- panelOpen from both); the HUD does not.
	local function release()
		pcall(function()
			local jumping=next(ctx.input.jumps)~=nil
			ctx.input:reset();ctx.send("GuardOff");if jumping then ctx.send("JumpOff") end;ctx.send("Move",Vector3.zero)
		end)
	end
	function self:setMode(mode)
		self.mode=mode
		gui.Enabled=mode==1
		hud.Enabled=mode==2
		self.blocking=mode==1
		if dev and dev.refreshBlocking then dev:refreshBlocking() end
		if mode==1 then release();selectTab(self.tab) end
		if mode==0 then outlinesOn=false;clearOutlines() end
	end
	UserInputService.InputBegan:Connect(function(key,processed)
		if not processed and key.KeyCode==Enum.KeyCode.F7 then self:setMode((self.mode+1)%3) end
	end)

	self.hidden=hidden;self.issues=order;self.setFamily=setFamily;self.applyPreset=applyPreset;self.particleTime=particleTime
	self.counters=function() return counters end
	self.lightingState=function()
		return {preset=preset,borrowed=WorldLook and WorldLook.borrowed or false,clock=Lighting.ClockTime,latitude=Lighting.GeographicLatitude,brightness=Lighting.Brightness,
			exposure=Lighting.ExposureCompensation,globalShadows=Lighting.GlobalShadows,technology=techName(),ambient=Lighting.Ambient:ToHex(),outdoor=Lighting.OutdoorAmbient:ToHex()}
	end

	-- Agents read the same report from Studio (execute_luau on the client):
	-- PlayerGui.DevVisualPanel.Report:Invoke() → JSON.
	local bindable=Instance.new("BindableFunction");bindable.Name="Report";bindable.Parent=gui
	bindable.OnInvoke=function(op,arg)
		if op=="preset" then applyPreset(arg) elseif op=="hide" then setFamily(arg,true) elseif op=="show" then setFamily(arg,false)
		elseif op=="mode" then self:setMode(tonumber(arg) or 0) elseif op=="restore" then Visual.restore(self) elseif op=="clear" then table.clear(issues);table.clear(order)
		elseif op=="tab" and pages[arg] then selectTab(arg) end
		return HttpService:JSONEncode(Visual.snapshot(self))
	end

	-- Follow every effect from now on.
	-- (QA 12/11, gel au BEGIN) What arrives is queued and classified at most
	-- TRACK_BUDGET a frame: a duel's start brought some two thousand objects
	-- in one frame, each walked up to the workspace several times (60,000
	-- reads in one frame in the micro-profiler).
	local TRACK_BUDGET=150
	local queue,head,tail={},1,0
	for _,root in {workspace,playerGui} do
		for _,d in root:GetDescendants() do track(d) end
		root.DescendantAdded:Connect(function(d) tail+=1;queue[tail]=d end)
	end
	local function drain()
		local budget=TRACK_BUDGET
		while head<=tail and budget>0 do
			local d=queue[head];queue[head]=nil;head+=1;budget-=1
			-- A frame later at least: the game names and places what it creates after parenting it.
			if d.Parent then
				track(d)
				local info=tracked[d]
				if info then
					if hidden[info.family] then hide(d,info.family) end
					if info.family=="particles" and frozen then pcall(function() d.TimeScale=frozen end) end
				end
			end
		end
		if head>tail then head,tail=1,0 end
	end
	Lighting.ChildAdded:Connect(function(e) if hidden.post and (e:IsA("PostEffect") or e:IsA("Atmosphere")) then task.defer(setFamily,"post",true) end end)
	local acc,last=0,0
	local installedAt=os.clock()
	local frames,frameClock=0,os.clock()
	RunService.RenderStepped:Connect(function(dt)
		pcall(drain)
		frames+=1
		if dt>.06 and dt<2 and os.clock()-installedAt>10 then
			frameSpikes+=1;worstFrame=math.max(worstFrame,dt)
			if dt>.12 then report("info","Saccade : une image a duré "..math.floor(dt*1000).." ms",string.format("%d objets d'effet vivants",counters.total or 0),nil,"spike") end
		end
		local t=os.clock()
		if t-frameClock>=1 then fps=math.floor(frames/(t-frameClock)+.5);frames=0;frameClock=t end
		acc+=dt
		if acc<.5 then return end
		acc=0
		local ok,err=pcall(scan)
		if not ok and t-last>10 then last=t;warn(TAG.." scan: "..tostring(err)) end
		if self.mode~=0 then pcall(refresh);pcall(updateOutlines) end
	end)
	self.gui=gui
	print(TAG,"F7 : outil visuel prêt (lumière, ombres, effets, problèmes)")
	return self
end

-- Everything back as the game set it: the game's lighting, every hidden family,
-- particle time.
function Visual.restore(self)
	for _,f in FAMILIES do if self.hidden[f.key] then self.setFamily(f.key,false) end end
	self.particleTime(nil)
	self.applyPreset("jeu")
end

function Visual.snapshot(self)
	local list={}
	for i,e in self.issues do
		if i>150 then break end
		table.insert(list,{sev=e.sev,title=e.title,detail=e.detail,path=e.path,count=e.count,at=e.clock})
	end
	local hiddenList={}
	for k in self.hidden do table.insert(hiddenList,k) end
	return {counters=self.counters(),lighting=self.lightingState(),hidden=hiddenList,issues=list}
end

function Visual.report(self)
	local snap=Visual.snapshot(self)
	print(TAG,"begin",HttpService:JSONEncode({counters=snap.counters,lighting=snap.lighting,hidden=snap.hidden}))
	for _,e in snap.issues do print(TAG,HttpService:JSONEncode(e)) end
	print(TAG,"end",#snap.issues.." problème(s)")
end

return Visual
