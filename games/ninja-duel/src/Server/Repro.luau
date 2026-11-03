-- Repro places (gameplay audit, 03/11). Each bug found by playing gets its
-- own place, built from the Debug place by tools/make_repro_place.py: the
-- place sets the workspace attribute NinjaDuelRepro to the bug's id. On join
-- this module puts the duel in the bug's situation through the dev hooks,
-- shows on a banner what went wrong and what the fix shows, and replays the
-- situation every few seconds (`every`). Debug/QA places only (build.py
-- DEBUG_SOURCES). A case reproduces a situation through the live engine; the
-- regression test of each fix lives in the specs (named in `test`).
local Players=game:GetService("Players")
local Repro={}
-- id -> {title, saw (what went wrong), now (what the fix shows), how (what to
-- do in the place), test (the spec that keeps it fixed), first / second
-- (fighters), tutorial, every (s between replays), setup(dev, s)}
Repro.cases={
	B01={title="Touches du tutoriel en QWERTY sur un clavier AZERTY",
		saw="Le tutoriel et l'aide demandaient Q pour esquiver et Z pour le chakra : les touches d'un clavier QWERTY. Sur un clavier AZERTY on appuie sur A et W.",
		now="Les étiquettes suivent le clavier du joueur : « A esquive », « W + action », « ZQSD se déplacer ».",
		how="Suis le tutoriel et lis la touche demandée à chaque étape.",
		test="tests/Input.spec.luau (B01)",
		first="Lion",second="Mirage",tutorial=true},
}

local function label(parent,name,text,size,y,height,color)
	local t=Instance.new("TextLabel");t.Name=name;t.BackgroundTransparency=1
	t.Position=UDim2.fromOffset(12,y);t.Size=UDim2.new(1,-24,0,height)
	t.Font=Enum.Font.GothamMedium;t.TextSize=size;t.TextWrapped=true
	t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Top
	t.TextColor3=color or Color3.new(1,1,1);t.Text=text;t.Parent=parent
	return t
end

function Repro.banner(player,id,case)
	local gui=Instance.new("ScreenGui");gui.Name="NinjaDuelRepro";gui.ResetOnSpawn=false;gui.DisplayOrder=50
	local box=Instance.new("Frame");box.Name="Box";box.AnchorPoint=Vector2.new(0,1)
	box.Position=UDim2.new(0,16,1,-16);box.Size=UDim2.fromOffset(440,196)
	box.BackgroundColor3=Color3.new(0,0,0);box.BackgroundTransparency=.3;box.Parent=gui
	Instance.new("UICorner",box).CornerRadius=UDim.new(0,8)
	label(box,"Title",id.." — "..case.title,15,10,20,Color3.fromRGB(255,214,120))
	label(box,"Saw","Avant : "..case.saw,12,34,48)
	label(box,"Now","Réparé : "..case.now,12,84,48,Color3.fromRGB(160,235,170))
	label(box,"How","À faire : "..case.how,12,134,32,Color3.fromRGB(200,210,225))
	local count=label(box,"Count","",12,170,16,Color3.fromRGB(150,160,175))
	gui.Parent=player:WaitForChild("PlayerGui")
	return count
end

function Repro.install(matches,dev)
	local id=workspace:GetAttribute("NinjaDuelRepro")
	local case=type(id)=="string" and Repro.cases[id]
	if not case then
		if id~=nil then warn("[NinjaDuelRepro] unknown case "..tostring(id)) end
		return false
	end
	local function stage(player)
		dev("start",case.first,case.second,case.tutorial==true)
		local s=matches.sessions[player]
		if s then
			s.introUntil=nil
			if case.setup then case.setup(dev,s) end
		end
	end
	local function run(player)
		task.spawn(function()
			for _=1,100 do if matches.sessions[player] then break end;task.wait(.1) end
			task.wait(1)
			stage(player)
			local count=Repro.banner(player,id,case)
			while case.every and player.Parent do
				for left=case.every,1,-1 do count.Text="Rejoue dans "..left.." s";task.wait(1) end
				stage(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(run)
	for _,player in Players:GetPlayers() do run(player) end
	return true
end
return Repro
