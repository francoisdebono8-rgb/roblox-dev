-- The first seconds behind a curtain (14/11, François: « toutes les textures
-- n'apparaissent pas au même moment… surtout dans l'écran d'accueil… même au
-- début du match »). Measured in Studio on a first arrival: the roster's
-- fighters, the arena and the player's own avatar came in piece by piece,
-- each mesh and image 0.4 to 1.4 s after it was shown; the village changed
-- in waves for 12 s as its models were built.
--
-- The screen stays dark (the game's name) while ContentProvider fetches what
-- the first screens show and MeshKit builds the models (the village is then
-- dressed in one go, Client/HubDress), MAX seconds at most; then it fades.
-- The effects' images and the replicated assets are fetched after, in the
-- background, so a first impact or a first jutsu shows whole.
-- Presentation only.
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Curtain={}
Curtain.MAX=8
Curtain.FADE=.4
-- What the first screens show (each optional).
Curtain.FIRST={"NinjaDuelPortraitStage","NinjaDuelMenuStage","NinjaDuels"}

-- The ids and instances to fetch for the effects (Client/Effects TEX, the
-- replicated VFX), skipping the engine's own rbxasset:// files.
function Curtain.later(fx,shared)
	local list={}
	for _,id in (fx and fx.TEX) or {} do
		if type(id)=="string" and string.find(id,"^rbxassetid://") then table.insert(list,id) end
	end
	if shared then table.insert(list,shared) end
	return list
end

-- True once nothing is left to wait for (pure: the suite reads it).
function Curtain.ready(state)
	local meshes=state.meshes==nil or state.meshes=="ready" or state.meshes=="failed"
	local dressed=not state.hub or state.dressed==true
	return state.fetched==true and meshes and dressed
end

function Curtain.start(playerGui,options)
	options=options or {}
	local gui=Instance.new("ScreenGui")
	gui.Name="NinjaDuelCurtain";gui.IgnoreGuiInset=true;gui.DisplayOrder=1000;gui.ResetOnSpawn=false
	local back=Instance.new("Frame")
	back.Size=UDim2.fromScale(1,1);back.BackgroundColor3=Color3.fromRGB(14,12,18);back.BorderSizePixel=0;back.Parent=gui
	local title=Instance.new("TextLabel")
	title.AnchorPoint=Vector2.new(.5,.5);title.Position=UDim2.fromScale(.5,.5);title.Size=UDim2.fromScale(.5,.12)
	title.BackgroundTransparency=1;title.Font=Enum.Font.Bangers;title.TextScaled=true
	title.TextColor3=Color3.fromRGB(236,190,90);title.Text="NINJA DUEL";title.Parent=back
	gui.Parent=playerGui
	local CP=game:GetService("ContentProvider")
	local state={fetched=false,hub=options.hub==true}
	task.spawn(function()
		local list={}
		for _,name in Curtain.FIRST do
			local x=workspace:WaitForChild(name,3)
			if x then table.insert(list,x) end
		end
		-- the player's own avatar, when he walks the village (3 s at most)
		if state.hub then
			local t=os.clock()
			while not Players.LocalPlayer.Character and os.clock()-t<3 do task.wait(.1) end
			if Players.LocalPlayer.Character then table.insert(list,Players.LocalPlayer.Character) end
		end
		pcall(function() CP:PreloadAsync(list) end)
		state.fetched=true
	end)
	task.spawn(function()
		local t0=os.clock()
		while os.clock()-t0<Curtain.MAX do
			local MeshKit=options.meshKit
			state.meshes=MeshKit and MeshKit.state or nil
			state.dressed=options.hubDress and options.hubDress.dressed
			if Curtain.ready(state) then break end
			task.wait(.1)
		end
		TweenService:Create(back,TweenInfo.new(Curtain.FADE),{BackgroundTransparency=1}):Play()
		TweenService:Create(title,TweenInfo.new(Curtain.FADE),{TextTransparency=1}):Play()
		task.delay(Curtain.FADE+.05,function() gui:Destroy() end)
		-- after: the effects' images and the replicated assets
		pcall(function() CP:PreloadAsync(Curtain.later(options.effects,options.shared)) end)
	end)
	return gui
end

return Curtain
