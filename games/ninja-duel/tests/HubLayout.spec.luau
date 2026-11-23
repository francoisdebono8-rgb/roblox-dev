-- Konoha's HUD at every window size (14/11, the new player's walk; Client/
-- HubLayout). Headless: the place box, the goal and the shop box under
-- Roblox's top bar and apart from each other; the master's card inside the
-- window and clear of them; with touch, a RUN button beside Roblox's jump
-- button and the card clear of both; text kept at a readable scale.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local L=H.load("Client/HubLayout")

local SIZES={
	{1920,1080,false},{2560,1440,false},{1600,900,false},{1366,768,false},{1280,720,false},{1024,600,false},
	{1024,768,true},{844,390,true},{932,430,true},{667,375,true},{390,844,true},{360,640,true},
}
local INSETS={36,58}
local function v(x,y) return {X=x,Y=y} end
local function fmt(r) return string.format("%.0f..%.0f x %.0f..%.0f",r.x,r.x+r.w,r.y,r.y+r.h) end
local function inside(r,X,Y,what,size)
	assert(r.x>=0 and r.y>=0 and r.x+r.w<=X+.5 and r.y+r.h<=Y+.5,string.format("%s off a %dx%d window: %s",what,X,Y,fmt(r)))
end
local function apart(a,b,what,size)
	assert(not L.overlap(a,b),string.format("%s overlap at %dx%d: %s / %s",what,size[1],size[2],fmt(a),fmt(b)))
end

test("the top row: under Roblox's bar, inside the window, nothing over anything",function()
	for _,size in SIZES do for _,inset in INSETS do
		local X,Y=size[1],size[2]
		local o=L.compute(v(X,Y),inset,size[3])
		for _,name in {"hud","shop","goal"} do
			inside(o[name],X,Y,name,size)
			assert(o[name].y>=inset,string.format("%s under Roblox's top bar at %dx%d (inset %d): y %.0f",name,X,Y,inset,o[name].y))
		end
		apart(o.hud,o.shop,"place box and shop",size)
		apart(o.hud,o.goal,"place box and goal",size)
		apart(o.shop,o.goal,"shop and goal",size)
	end end
end)

test("the goal under the place box, out of the view's middle; the minimap clear of the thumbstick",function()
	for _,size in SIZES do
		local o=L.compute(v(size[1],size[2]),58,size[3])
		assert(o.goal.x==o.hud.x and o.goal.y>o.hud.y,"the goal under the place box at "..size[1])
		inside(o.map,size[1],size[2],"minimap",size)
		apart(o.map,o.goal,"minimap and goal",size)
		apart(o.map,o.shop,"minimap and shop",size)
		if o.run then apart(o.map,o.run,"minimap and RUN",size) end
	end
end)

test("the master's card: inside the window, under the top row, clear of the keys",function()
	for _,size in SIZES do for _,inset in INSETS do
		local X,Y=size[1],size[2]
		local o=L.compute(v(X,Y),inset,size[3])
		inside(o.card,X,Y,"card",size)
		assert(o.card.y>=inset,"the card under Roblox's top bar at "..X)
		-- (with touch the place box and the shop step aside while he talks)
		if not o.card.overTop then
			apart(o.card,o.hud,"card and place box",size)
			apart(o.card,o.shop,"card and shop",size)
		else assert(size[3],"the card covers the top row without touch at "..X) end
		if o.keys then inside(o.keys,X,Y,"key line",size);apart(o.card,o.keys,"card and key line",size) end
		assert(o.card.scale>=.6,string.format("the card is unreadable at %dx%d: scale %.2f",X,Y,o.card.scale))
	end end
end)

test("touch: RUN beside the jump button, the card clear of both, no key line",function()
	for _,size in SIZES do if size[3] then for _,inset in INSETS do
		local X,Y=size[1],size[2]
		local o=L.compute(v(X,Y),inset,true)
		assert(o.run and o.jump and not o.keys,"touch controls missing at "..X)
		inside(o.run,X,Y,"RUN",size)
		apart(o.run,o.jump,"RUN and jump",size)
		assert(math.abs(o.run.y-o.jump.y)<1 and o.run.w==o.jump.w,"RUN not beside the jump button at "..X)
		apart(o.card,o.jump,"card and jump button",size)
		apart(o.card,o.run,"card and RUN",size)
		for _,name in {"hud","shop","goal"} do apart(o[name],o.run,name.." and RUN",size) end
		assert(o.scale>=.7,"touch text below a readable scale at "..X)
	end end end
	-- Roblox's own jump button, as PlayerModule places it
	local small=L.jump(v(844,390));assert(small.w==70 and small.x==749 and small.y==300,"small jump "..fmt(small))
	local big=L.jump(v(1024,768));assert(big.w==120 and big.x==1024-170 and big.y==768-210,"big jump "..fmt(big))
end)

test("narrow: the goal's places one a line",function()
	local o=L.compute(v(390,844),58,true)
	assert(o.goal.stack,"a portrait phone keeps the places on one line")
	assert(o.shop.y>o.hud.y,"the shop box stays beside the place box on a portrait phone")
end)

-- The Konoha client itself (Client/HubClient) over the real UI: the layout
-- applied, the goal of a new player then of his first duel, the phone's RUN
-- button and the card over the top row, the pad's focus and B.
test("Konoha's HUD: placed by the layout, the goal follows the player, touch and pad",function()
	local roblox=H.roblox
	H.envBase.UDim2=roblox.UDim2;H.envBase.UDim=roblox.UDim;H.envBase.Vector2=roblox.Vector2
	H.workspace.GetAttribute=function() return nil end
	local Enum=roblox.Enum
	local last=Enum.UserInputType.Keyboard
	local began={}
	local selected={value=nil}
	local baseGet=H.envBase.game.GetService
	local gui={GetGuiInset=function() return roblox.Vector2.new(0,58),roblox.Vector2.zero end}
	setmetatable(gui,{__index=function(_,k) if k=="SelectedObject" then return selected.value end end,
		__newindex=function(_,k,v) if k=="SelectedObject" then selected.value=v else rawset(gui,k,v) end end})
	H.envBase.game.GetService=function(g,name)
		if name=="ProximityPromptService" then return {PromptTriggered={Connect=function() end}} end
		if name=="GuiService" then return gui end
		if name=="UserInputService" then
			local u=baseGet(g,name)
			u.JumpRequest={Connect=function() end}
			u.InputBegan={Connect=function(_,fn) table.insert(began,fn) end}
			u.GetLastInputType=function() return last end
			u.TouchEnabled=false;u.KeyboardEnabled=true;u.GamepadEnabled=true
			u.IsKeyDown=function() return false end
			return u
		end
		return baseGet(g,name)
	end
	local deferred={}
	local savedTask=H.envBase.task
	H.envBase.task={spawn=function() end,delay=function() end,wait=function() return 0 end,defer=function(fn) table.insert(deferred,fn) end}
	local camera={ViewportSize=roblox.Vector2.new(1280,720),GetPropertyChangedSignal=function() return {Connect=function() end} end}
	H.workspace.CurrentCamera=camera
	local baseNew=H.envBase.Instance.new
	local savedInstance=H.envBase.Instance
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		function x:IsDescendantOf(root)
			local node=rawget(self,"Parent")
			while type(node)=="table" do if node==root then return true end node=rawget(node,"Parent") end
			return false
		end
		return x
	end}
	local ok,err=pcall(function()
		local Config=H.load("Shared/Config")
		local hubWas=Config.Hub;Config.Hub={Enabled=true}
		local UI=H.load("Client/UI")
		local sent={}
		local ui=UI.new(H.envBase.Instance.new("PlayerGui"),function(action,payload) table.insert(sent,{action,payload}) end)
		local Hub=H.load("Client/HubClient")
		local hub=Hub.new(ui,{},function(action,payload) table.insert(sent,{action,payload}) end,{Enable=function() end,Disable=function() end})
		local new={state="ready",owned={},mastery={},masters={},needStarter=true,trees={},ryo=0,style={owned={},equipped={}}}
		hub:render({phase="Selection",kits=new})
		-- a laptop: the place box under Roblox's bar, the goal under the top row
		assert(hub.hud.Visible and hub.hud.Position.Y.Offset==66 and hub.hud.Position.X.Offset==16,"the place box: "..tostring(hub.hud.Position))
		assert(hub.goal.Visible and hub.goalHead.Text=="CHOOSE YOUR INSPIRATION","a new player's goal: "..hub.goalHead.Text)
		assert(hub.goalSub.Text~="" and hub.goal.Position.X.Offset<40,"the goal's places, under the place box: "..hub.goalSub.Text)
		assert(not hub.runButton.Visible and hub.keys.Visible,"keys: no RUN button, the key line")
		-- (14/11) the training dummy: no kit yet, Lee's (his ground)
		hub:train()
		assert(#sent==1 and sent[1][1]=="Tutorial" and sent[1][2].player=="Leaf","a new player trains with Lee's kit")
		-- his first kit taken: the goal points at the first duel
		local mine={state="ready",owned={Leaf=true},mastery={Leaf=0},starter="Leaf",selected="Leaf",masters={},trees={Leaf={points=0,free=0}},ryo=0,style={owned={},equipped={}}}
		hub:render({phase="Selection",kits=mine})
		assert(hub.goalHead.Text=="YOUR FIRST DUEL" and string.find(hub.goalSub.Text,"THE HARD WORKER",1,true),"after the first kit: "..hub.goalHead.Text)
		mine.selected="Lion";mine.owned.Lion=true
		hub:train()
		assert(sent[2][2].player=="Lion" and sent[2][2].bot~=nil,"he trains with his own kit: "..tostring(sent[2][2].player))
		mine.selected="Leaf";mine.owned.Lion=nil
		-- talking to a master: the goal steps aside, the card is on screen
		hub:showCard("Leaf")
		assert(hub.card.Visible and not hub.goal.Visible,"the card and the goal")
		assert(hub.primary.Text=="YOUR FIRST DUEL","the card's first duel")
		hub:hideCard()
		assert(hub.goal.Visible,"the goal is back")
		-- a phone: RUN beside the jump button, no key line; the card takes the top row
		last=Enum.UserInputType.Touch
		camera.ViewportSize=roblox.Vector2.new(844,390)
		hub:layout();hub:refreshHud()
		assert(hub.runButton.Visible and not hub.keys.Visible,"touch: the RUN button")
		assert(hub.runButton.Position.X.Offset==665 and hub.runButton.Position.Y.Offset==300,"RUN beside the jump button: "..tostring(hub.runButton.Position))
		hub.runButton.click()
		assert(hub.move.runLatch,"RUN latches the run (Client/HubMove)")
		hub:showCard("Leaf")
		assert(hub.card.Visible and not hub.hud.Visible and not hub.shopBox.Visible,"a phone's card takes the top row")
		assert(hub.cardScale.Scale>=.75,"the phone's card scale: "..hub.cardScale.Scale)
		hub:hideCard()
		assert(hub.hud.Visible and hub.shopBox.Visible,"the top row is back")
		-- a pad: the card's first button takes the focus, B closes, Y opens the shop
		last=Enum.UserInputType.Gamepad1
		camera.ViewportSize=roblox.Vector2.new(1920,1080)
		hub:layout()
		hub:showCard("Leaf")
		for _,fn in deferred do fn() end
		assert(selected.value==hub.primary,"the pad's focus on TAKE / FIRST DUEL")
		for _,fn in began do fn({KeyCode=Enum.KeyCode.ButtonB}) end
		assert(not hub.card.Visible and selected.value==nil,"B closes the card and gives the focus back")
		for _,fn in began do fn({KeyCode=Enum.KeyCode.ButtonY}) end
		assert(ui.shopPanel:shown(),"Y opens the shop")
		ui.shopPanel:hide()
		for _,fn in began do fn({KeyCode=Enum.KeyCode.ButtonL3}) end
		assert(hub.move.runLatch==false,"L3 toggles the latch (it was on)")
		assert(string.find(hub.keys.Text,"Y SHOP",1,true) and string.find(hub.keys.Text,"R1 DUELS",1,true),"the pad's key line: "..hub.keys.Text)
		-- (14/11) the board of duels from anywhere: R1, the keyboard's B (not
		-- while typing), the DUELS button; never over a master's card
		for _,fn in began do fn({KeyCode=Enum.KeyCode.ButtonR1}) end
		assert(hub.board,"R1 opens the board of duels")
		hub:closeBoard()
		for _,fn in began do fn({KeyCode=Enum.KeyCode.B},true) end
		assert(not hub.board,"B typed in the chat opened the board")
		for _,fn in began do fn({KeyCode=Enum.KeyCode.B},false) end
		assert(hub.board,"B opens the board of duels")
		hub:closeBoard()
		hub:showCard("Leaf")
		for _,fn in began do fn({KeyCode=Enum.KeyCode.ButtonR1}) end
		assert(not hub.board,"R1 opened the board over the card")
		hub:hideCard()
		hub.duelsButton.click()
		assert(hub.board and not hub.shopBox.Visible,"the DUELS button opens the board")
		hub:closeBoard()
		assert(hub.shopBox.Visible and hub.duelsButton.Text=="DUELS","the top right is back")
		Config.Hub=hubWas
	end)
	H.envBase.game.GetService=baseGet
	H.envBase.task=savedTask
	H.envBase.Instance=savedInstance
	H.workspace.CurrentCamera={ViewportSize=roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
	assert(ok,err)
end)

-- (19/11, vague 2 DEV 1) The screen (HubClient, DESIGN) and the walk
-- (HubMove, DEV) in their own files: the screen never drives the body.
test("the village's screen and the walk are two files: HubClient draws, HubMove moves",function()
	local fs=require("@lune/fs")
	local screen=fs.readFile("src/Client/HubClient.luau")
	-- (the inspirations' moods still pose their own models: model:PivotTo)
	for _,word in {"WalkSpeed","JumpPower","AssemblyLinearVelocity","character:PivotTo"} do
		assert(not string.find(screen,word,1,true),"HubClient still moves the body ("..word..")")
	end
	local walk=fs.readFile("src/Client/HubMove.luau")
	for _,word in {"WalkSpeed","JumpPower","AssemblyLinearVelocity","character:PivotTo"} do
		assert(string.find(walk,word,1,true),"HubMove does not do "..word)
	end
	assert(not string.find(walk,"Instance.new",1,true),"HubMove draws something")
end)

print(string.format("NinjaDuel Konoha HUD layout: %d PASS",passed))
