-- The Ōtsutsuki, as this screen sees him (26-27/11, passe 3; DEV: « l'Ōtsutsuki est dans le
-- jeu avec le corps d'Itachi »; François: « fais entièrement Otsutsuki comme un vrai perso »,
-- his four reference images). The server's bodies are the stand-in kit's rig (Story.BOSS.kit)
-- marked NinjaBoss="Otsutsuki": the one waiting in the exam hall's court (Server/StoryPlay)
-- and his duel's body (Server/Matches). Here each is drawn as himself: his whole body modelled
-- like the eight's (tools/blender/look_otsutsuki.py -> Client/BossMeshData), the stand-in
-- hidden, his drawn eyes both Rinnegan. Presentation only, on this client.
local Boss={}
Boss.SKIN=Color3.fromRGB(246,238,238)
-- the eyes: both Rinnegan, pale lilac, the rings a darker lilac (his reference)
Boss.RINNE=Color3.fromRGB(226,220,240)
Boss.RINNE_RING=Color3.fromRGB(140,124,176)
Boss.BROW=Color3.fromRGB(232,232,240)

local function new(class,props,parent)
	local x=Instance.new(class)
	for k,v in props do x[k]=v end
	if parent then x.Parent=parent end
	return x
end

-- Both eyes Rinnegan; the mouth hidden under the mask.
function Boss.eyes(model)
	local head=model:FindFirstChild("Head")
	if not head then return end
	for _,p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name=="FaceMouth" then
			p.LocalTransparencyModifier=1
			local gui=p:FindFirstChildOfClass("SurfaceGui");if gui then gui.Enabled=false end
		elseif p:IsA("BasePart") and p.Name=="FaceEye" and not p:GetAttribute("BossEye") then
			p:SetAttribute("BossEye",true)
			local gui=p:FindFirstChildOfClass("SurfaceGui")
			local white=gui and gui:FindFirstChild("White")
			local iris=white and white:FindFirstChild("Iris")
			local brow=gui and gui:FindFirstChild("Brow");if brow then brow.BackgroundColor3=Boss.BROW end
			local lid=white and white:FindFirstChild("Lid");if lid then lid.BackgroundColor3=Boss.SKIN end
			if iris then
				local grad=iris:FindFirstChildOfClass("UIGradient")
				local pupil=iris:FindFirstChild("Pupil")
				iris.BackgroundColor3=Boss.RINNE
				if grad then grad.Color=ColorSequence.new(Boss.RINNE:Lerp(Boss.RINNE_RING,.25),Boss.RINNE) end
				if pupil then pupil.Size=UDim2.fromScale(.14,.14);pupil.BackgroundColor3=Boss.RINNE_RING:Lerp(Color3.new(),.3) end
				for _,t in iris:GetChildren() do if t.Name=="Tomoe" and t:IsA("GuiObject") then t.Visible=false end end
				for k,sz in {.82,.6,.38} do
					local r=new("Frame",{Name="RinneRing"..k,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.fromScale(sz,sz),
						BackgroundTransparency=1,ZIndex=2},iris)
					new("UICorner",{CornerRadius=UDim.new(.5,0)},r)
					new("UIStroke",{Thickness=2,Color=Boss.RINNE_RING},r)
				end
			end
		end
	end
end

-- (27/11, François: « fais entièrement Otsutsuki comme un vrai perso ») His whole body is
-- modelled like the eight's (tools/blender/look_otsutsuki.py, on the duel rig's rest pose):
-- Client/BossMeshData, built here once (MeshKit, nothing to upload). Each piece goes on its
-- body part at its rest offset; every part of the stand-in is hidden but its drawn eyes.
Boss.LOOK_DATA="Look_Otsutsuki"
local templates=nil
local function build(MeshKit)
	if templates then
		while templates==false do task.wait() end
		return templates
	end
	templates=false
	local made={}
	local okData,Data=pcall(require,script.Parent.BossMeshData)
	for _,spec in (okData and Data[Boss.LOOK_DATA]) or {} do
		local ok,part=pcall(MeshKit.build,spec)
		if ok and part then table.insert(made,{part=part,on=spec.on,o=Vector3.new(spec.o[1],spec.o[2],spec.o[3])}) end
	end
	templates=made
	return made
end
Boss.build=build

local dressed=setmetatable({},{__mode="k"})
function Boss.dress(model,MeshKit)
	if dressed[model] then return false end
	dressed[model]=true
	local list=build(MeshKit)
	if #list==0 then dressed[model]=nil return false end
	local folder=Instance.new("Folder");folder.Name="BossLook"
	for _,entry in list do
		local on=model:FindFirstChild(entry.on)
		if on and on:IsA("BasePart") then
			local p=entry.part:Clone()
			p.CFrame=on.CFrame*CFrame.new(entry.o)
			p.Anchored=false;p.Massless=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=true
			local w=Instance.new("WeldConstraint");w.Part0=on;w.Part1=p;w.Parent=p
			p:SetAttribute("BossPiece",true)
			p.Parent=folder
		end
	end
	-- (27/11, DEV: the same as the outfits' cloth boxes and the bandit's
	-- prodigy pieces) the body's fades (BodyViews, the lenses, Roblox's own
	-- camera) give LocalTransparencyModifier back 0: the stand-in's pieces are
	-- hidden by their own Transparency here, held there
	local function hide(d)
		if not d:IsA("BasePart") or d:GetAttribute("BossPiece") or d.Name=="FaceEye" or d.Name=="HumanoidRootPart" then return end
		d.LocalTransparencyModifier=1
		if d.Transparency<1 then d.Transparency=1 end
		pcall(function()
			d:GetPropertyChangedSignal("Transparency"):Connect(function() if d.Transparency<1 then d.Transparency=1 end end)
		end)
		if d.Name=="FaceMouth" then local gui=d:FindFirstChildOfClass("SurfaceGui");if gui then gui.Enabled=false end end
	end
	for _,d in model:GetDescendants() do hide(d) end
	-- what the server adds later (a weapon drawn, an aura) stays hidden too; his own pieces stay
	model.DescendantAdded:Connect(function(d) task.defer(function() if d.Parent then hide(d) end end) end)
	folder.Parent=model
	pcall(Boss.eyes,model)
	return true
end

function Boss.start()
	if Boss.started then return end
	Boss.started=true
	task.spawn(function()
		local okK,MeshKit=pcall(require,script.Parent.MeshKit)
		if not okK then return end
		local function seen(d)
			if d:IsA("Model") and d:GetAttribute("NinjaBoss") and not dressed[d] then task.spawn(function() pcall(Boss.dress,d,MeshKit) end) end
		end
		for _,d in workspace:GetDescendants() do seen(d) end
		workspace.DescendantAdded:Connect(function(d)
			if d:IsA("Model") then task.defer(function() if d.Parent then seen(d) end end) end
		end)
		-- the attribute may come after the model (the duel's body is marked once built)
		while true do
			task.wait(.5)
			local duels=workspace:FindFirstChild("NinjaDuels")
			-- (27/11) the duels' bodies only (Duel_n.<fighter>), not every
			-- effect's part under them (the OUTILLEUR's 0.45 s frames)
			if duels then for _,duel in duels:GetChildren() do for _,d in duel:GetChildren() do seen(d) end end end
		end
	end)
end

return Boss
