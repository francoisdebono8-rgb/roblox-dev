-- The challenge by a blow (DESIGN, passe 3): a player strikes another in
-- Konoha; for 5 s a hit back starts the duel. A red manga stamp
-- « CHALLENGE! » over the other one's head (the target for the one who
-- struck, the striker for the one struck), and on the struck player's screen
-- the prompt to hit back, its fuse burning down. Replaces Roblox's
-- notification. Called by Client/HubFightClient on a "challenge" hit.
local Players=game:GetService("Players")
local Text=require(game:GetService("ReplicatedStorage").NinjaDuel.Text)

local C={}
C.WINDOW=5

-- The prompt's words (pure): for the struck one, for the striker.
function C.words(struck,name,left)
	if struck then return "CHALLENGE!",string.format("%s HIT YOU. HIT BACK TO FIGHT  •  %d",Text.upper(name or ""),math.ceil(left)) end
	return "CHALLENGE!",string.format("WAITING FOR %s TO HIT BACK  •  %d",Text.upper(name or ""),math.ceil(left))
end

local function stamp(character)
	-- (the ninja body may hide the avatar's head: fall back on the root)
	local head=character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
	if not head then return nil end
	local old=head:FindFirstChild("NinjaChallenge")
	if old then old:Destroy() end
	local bill=Instance.new("BillboardGui")
	bill.Name="NinjaChallenge";bill.Size=UDim2.fromScale(6,1.8);bill.StudsOffset=Vector3.new(0,3.2,0)
	bill.AlwaysOnTop=true;bill.LightInfluence=0;bill.MaxDistance=120
	local t=Instance.new("TextLabel")
	t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=Color3.fromRGB(195,18,29);t.BorderSizePixel=0;t.Rotation=-6
	t.Text="CHALLENGE!";t.Font=Enum.Font.Bangers;t.TextScaled=true;t.TextColor3=Color3.fromRGB(255,248,236)
	local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(20,16,17);s.Thickness=3;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=t
	t.Parent=bill
	bill.Parent=head
	return bill
end

-- The struck player's prompt, low on the screen.
local function prompt()
	local gui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not gui then return nil end
	local sg=gui:FindFirstChild("NinjaChallengePrompt")
	if sg then sg:Destroy() end
	sg=Instance.new("ScreenGui");sg.Name="NinjaChallengePrompt";sg.ResetOnSpawn=false;sg.DisplayOrder=40
	local band=Instance.new("Frame");band.AnchorPoint=Vector2.new(.5,1);band.Position=UDim2.new(.5,0,1,-150);band.Size=UDim2.fromOffset(620,74)
	band.BackgroundColor3=Color3.fromRGB(20,16,17);band.BorderSizePixel=0;band.Rotation=-1.5;band.Parent=sg
	local head=Instance.new("TextLabel");head.BackgroundTransparency=1;head.Position=UDim2.fromOffset(16,4);head.Size=UDim2.new(1,-32,0,34)
	head.Font=Enum.Font.Bangers;head.TextScaled=true;head.TextColor3=Color3.fromRGB(232,60,60);head.TextXAlignment=Enum.TextXAlignment.Left;head.Name="Head";head.Parent=band
	local line=Instance.new("TextLabel");line.BackgroundTransparency=1;line.Position=UDim2.fromOffset(16,38);line.Size=UDim2.new(1,-32,0,24)
	line.Font=Enum.Font.BuilderSansExtraBold;line.TextScaled=true;line.TextColor3=Color3.fromRGB(255,248,236);line.TextXAlignment=Enum.TextXAlignment.Left;line.Name="Line";line.Parent=band
	local fuse=Instance.new("Frame");fuse.Position=UDim2.new(0,0,1,-6);fuse.Size=UDim2.new(1,0,0,6);fuse.BorderSizePixel=0
	fuse.BackgroundColor3=Color3.fromRGB(195,18,29);fuse.Name="Fuse";fuse.Parent=band
	sg.Parent=gui
	return sg,band
end

-- A challenge hit: `struck` true when the local player was the one struck.
function C.show(struck,other)
	local name=other and other.DisplayName or ""
	local bill=stamp(other and other.Character)
	local sg,band=nil,nil
	pcall(function() sg,band=prompt() end)
	local t0=os.clock()
	task.spawn(function()
		while os.clock()-t0<C.WINDOW do
			local left=C.WINDOW-(os.clock()-t0)
			if band then
				local h,l=C.words(struck,name,left)
				band.Head.Text=h;band.Line.Text=l
				band.Fuse.Size=UDim2.new(left/C.WINDOW,0,0,6)
			end
			task.wait(.1)
		end
		if bill then bill:Destroy() end
		if sg then sg:Destroy() end
	end)
end
-- The duel started (or the window passed): clear it.
function C.clear()
	pcall(function()
		local gui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		local sg=gui and gui:FindFirstChild("NinjaChallengePrompt")
		if sg then sg:Destroy() end
		for _,p in Players:GetPlayers() do
			local head=p.Character and p.Character:FindFirstChild("Head")
			local b=head and head:FindFirstChild("NinjaChallenge")
			if b then b:Destroy() end
		end
	end)
end

return C
