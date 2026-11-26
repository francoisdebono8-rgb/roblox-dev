-- The rogue ninjas of Konoha, as this screen sees them (24/11, passe commune 1, DEC-051;
-- the DEV's Server/Thugs: a few rogues stand by the street-duel places and rack the walkers).
-- The server's rogue is a statue (a kit's portrait, darkened, tagged NinjaThug); here it is
-- hidden and drawn as the duel's rig (KonohaFolkFX.rig) in the rogue's own look (SetRogue,
-- Shared/OutfitMeshes: a dark coat on a blood-red robe, the cloth mask, the struck-through headband),
-- playing the ANIMATEUR's clips (tools/blender/p1_clips.py, AuthoredJutsu20):
--   Rogue.Idle     by the duel place, arms crossed, looking about
--   Rogue.Racket   while he racks THIS walker (the remote NinjaDuel.Racket names him): he turns
--                  to him, leans in, one hand out for the Ryō
--   Rogue.Taunt    the racket panel closes and he is still there: a fight is coming
--   Rogue.Leave    the server takes him away (paid or beaten): a leap back, then he fades
-- Presentation only, on this client; never solid, never queried. Nothing reaches the server.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")

local Rogue={}
Rogue.NEAR=300          -- studs from the camera within which they move
Rogue.LOOK="SetRogue"   -- their look (Shared/OutfitMeshes; never in the shop: outfit_models.NPC_SETS)
-- its colours, slot by slot (tools/blender/wardrobe_models.py SETS.SetRogue)
Rogue.COLORS={HaoriCloth={34,34,40},HaoriUnder={110,30,32},HaoriTrim={150,146,140},WrapPantsCloth={40,40,48},
	WrapPantsWrap={128,122,112},ArmWarmersCloth={52,50,56},WrappedFeetWrap={128,122,112},MaskClothCloth={26,26,30},
	HeadbandScratchedBand={26,26,30},HeadbandScratchedPlate={170,172,178}}
Rogue.SKIN=Color3.fromRGB(214,170,134)
Rogue.live={}           -- server model -> entry

local function hide(model)
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end
		if d:IsA("Decal") then d.Transparency=1 end
	end
end

-- (pure) Which clip he plays and from when: the state, the time it began, now.
function Rogue.clipAt(state,since,now)
	if state=="racket" then return "Rogue.Racket",now-since end
	if state=="taunt" then return "Rogue.Taunt",now-since end
	if state=="leave" then return "Rogue.Leave",now-since end
	return "Rogue.Idle",now+since
end
-- (pure) The street key a server rogue stands for ("Thug_<key>").
function Rogue.keyOf(name)
	return string.match(tostring(name or ""),"^Thug_(.+)$")
end

function Rogue.start()
	if Rogue.started then return end
	Rogue.started=true
	task.spawn(function()
		local RS=game:GetService("ReplicatedStorage")
		local shared=RS:WaitForChild("NinjaDuel",30)
		if not shared then return end
		local okC,Config=pcall(require,shared:WaitForChild("Config",10))
		if okC and Config and Config.Hub and Config.Hub.Enabled~=true then return end
		local okD,Dress=pcall(require,script.Parent.OutfitDress)
		local okA,Authored=pcall(require,script.Parent.AuthoredMotion)
		local okF,Folk=pcall(require,script.Parent.KonohaFolkFX)
		if not (okD and okA and okF and Authored.has("Rogue.Idle")) then return end
		local colors={}
		for slot,c in Rogue.COLORS do colors[slot]=Color3.fromRGB(c[1],c[2],c[3]) end
		local folder=Instance.new("Folder");folder.Name="KonohaRogues";folder.Parent=workspace

		local function joints(model)
			local j={}
			for _,d in model:GetDescendants() do if d:IsA("Motor6D") then j[d.Name]=d end end
			return j
		end
		local MOTOR={Right="RightShoulder",Left="LeftShoulder"}
		local function pose(j,p)
			if not p then return end
			for name,cf in p do
				local m=j[MOTOR[name] or name]
				if m then m.Transform=cf end
			end
		end
		local function fade(entry,alpha)
			for _,d in entry.rig:GetDescendants() do
				if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then d.LocalTransparencyModifier=alpha end
			end
		end

		local function add(model)
			if Rogue.live[model] or not model:IsA("Model") or not model:GetAttribute("NinjaThug") then return end
			local root=model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local dark=Color3.fromRGB(34,34,40)
			local rig=Folk.rig(Rogue.SKIN,dark,dark)
			rig.Name="Rogue_"..model.Name
			rig.Parent=folder
			task.spawn(function() pcall(Folk.dress,rig,Dress,{Rogue.LOOK},colors) end)
			local entry={server=model,rig=rig,root=rig.PrimaryPart,j=joints(rig),key=Rogue.keyOf(model.Name),
				at=root.CFrame,state="idle",since=math.random()*3}
			Rogue.live[model]=entry
			hide(model)
			model.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end end)
			model.AncestryChanged:Connect(function(_,parent)
				if parent then return end
				-- the server took him away: a leap back, then gone
				entry.state,entry.since="leave",os.clock()
				task.delay((Authored.length("Rogue.Leave") or .9)+.35,function()
					Rogue.live[model]=nil
					rig:Destroy()
				end)
			end)
		end
		-- (26/11, passe 2, seen in Studio: the forest's bandit and the rackets'
		-- rogues fought as the prodigy whose moves they use, green jumpsuit and
		-- all) A duel's body the server marks NinjaRogueLook (Matches.forestFight,
		-- thugFight) wears the rogue's look here: the prodigy's costume pieces
		-- hidden, the body in the rogue's colours, the rogue's modelled pieces on.
		local BODY={Head=true,UpperTorso=true,LowerTorso=true,LeftUpperArm=true,RightUpperArm=true,LeftLowerArm=true,RightLowerArm=true,
			LeftHand=true,RightHand=true,LeftUpperLeg=true,RightUpperLeg=true,LeftLowerLeg=true,RightLowerLeg=true,LeftFoot=true,RightFoot=true,HumanoidRootPart=true}
		local dressedDuel=setmetatable({},{__mode="k"})
		local function dressDuel(model)
			if dressedDuel[model] then return end
			dressedDuel[model]=true
			local dark=Color3.fromRGB(34,34,40)
			for _,d in model:GetDescendants() do
				if d:IsA("BasePart") then
					if not BODY[d.Name] then d.LocalTransparencyModifier=1
					elseif d.Name=="Head" or d.Name=="LeftHand" or d.Name=="RightHand" then d.Color=Rogue.SKIN
					elseif d.Name~="HumanoidRootPart" then d.Color=dark end
				end
			end
			task.spawn(function() pcall(Folk.dress,model,Dress,{Rogue.LOOK},colors) end)
		end
		task.spawn(function()
			while true do
				task.wait(.4)
				local duels=workspace:FindFirstChild("NinjaDuels")
				if duels then
					for _,d in duels:GetDescendants() do
						if d:IsA("Model") and d:GetAttribute("NinjaRogueLook") and not dressedDuel[d] then pcall(dressDuel,d) end
					end
				end
			end
		end)
		local function scan(node) for _,d in node:GetDescendants() do if d:IsA("Model") and d:GetAttribute("NinjaThug") then add(d) end end end
		scan(workspace)
		workspace.DescendantAdded:Connect(function(d)
			if d:IsA("Model") then task.defer(function() if d.Parent and d:GetAttribute("NinjaThug") then add(d) end end) end
		end)

		-- the racket: the server names the rogue who stops this walker
		local remote=shared:WaitForChild("Racket",30)
		if remote then
			remote.OnClientEvent:Connect(function(offer)
				local now=os.clock()
				for _,e in Rogue.live do
					if type(offer)=="table" and offer.id==e.key and e.state~="leave" then
						if e.state~="racket" then e.state,e.since="racket",now end
					elseif e.state=="racket" then
						e.state,e.since="taunt",now
					end
				end
			end)
		end

		local acc=0
		RunService.Heartbeat:Connect(function(dt)
			acc+=dt
			if acc<1/30 then return end
			acc=0
			local now=os.clock()
			local cam=workspace.CurrentCamera
			local eye=cam and cam.CFrame.Position or Vector3.zero
			local me=Players.LocalPlayer and Players.LocalPlayer.Character
			local mine=me and me:FindFirstChild("HumanoidRootPart")
			-- (26/11, DEC-054) the forest's bandit waits only for a player still
			-- walking to him (Server/Forest): in his duel the duel's body is him,
			-- after it he is beaten, before (in the village) nobody meets him
			local stage=Players.LocalPlayer and Players.LocalPlayer:GetAttribute("NinjaIntro")
			for model,e in Rogue.live do
				if model:GetAttribute("NinjaForestBandit") then
					local gone=stage~="forest"
					if gone~=e.gone then
						e.gone=gone
						fade(e,if gone then 1 else 0)
						local r=model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
						local tag=r and r:FindFirstChild("ThugTag")
						if tag then tag.Enabled=not gone end
					end
				end
				if e.state~="leave" and model.Parent then
					local r=model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
					if r then e.at=r.CFrame end
				end
				if (e.at.Position-eye).Magnitude<Rogue.NEAR or not e.placed then
					e.placed=true
					local cf=e.at
					if (e.state=="racket" or e.state=="taunt") and mine then   -- he faces his mark
						local to=Vector3.new(mine.Position.X,cf.Position.Y,mine.Position.Z)
						if (to-cf.Position).Magnitude>.5 then cf=CFrame.lookAt(cf.Position,to) end
					end
					e.root.CFrame=cf
					if e.state=="taunt" and now-e.since>(Authored.length("Rogue.Taunt") or 1.1)+1.5 then e.state,e.since="idle",math.random()*3 end
					local clip,t=Rogue.clipAt(e.state,e.since,now)
					pcall(function() pose(e.j,Authored.sample(clip,t)) end)
					if e.state=="leave" then
						local puff=.6
						fade(e,math.clamp((now-e.since-puff)/.3,0,1))
					end
				end
			end
		end)
	end)
end

return Rogue
