-- The human robot's witness, on the client (OUTILLEUR, 27/11; François: « simule
-- des comportements humains partout : clique plusieurs fois pour choisir des
-- tenues, ouvre et ferme des menus, mouvements illogiques pour un robot, les
-- clics dans la boutique, les menus, en combat… »).
--
-- The hands are Studio's own input tools, playing in the Play and never on the
-- Mac (Roblox Studio MCP user_mouse_input / user_keyboard_input: a list of
-- clicks, keys and waits in one call, prepared by tools/humanbot/chaos.py).
-- This witness, injected in the client (python3 tools/robots/inject.py human),
-- sees everything a player would see go wrong while those hands play:
--   every input (key, click and what was under the mouse) and every button
--   that answered (GuiButton.Activated)  -> the steps before each bug;
--   a click on a button that did not answer                  -> « clic mort »
--   a red line (LogService)                                  -> « erreur rouge »
--   a frame longer than HITCH s                              -> « à-coup »
--   the body walked by the keys that does not move           -> « corps bloqué »
--   the body under the map, thrown, or with nothing below    -> « chute », « projeté »
--   two menus open at once, or a menu open with the mouse
--   locked in the centre (nothing can be clicked)            -> « menus ensemble », « souris bloquée »
--   a button out of the screen, a text cut, in an open menu  -> « hors écran », « texte coupé »
--   two outfits or two sets of cloth on the body, a body with
--   no top or no bottom, the cloth not the one equipped      -> « tenue en double », « corps nu », « tenue fausse »
-- Each bug keeps the last inputs before it (the way to reproduce it) and the
-- state then (stage, kit, open menus, mouse).
--
--   _G.NDHumanWatch.start(fresh)   the witness on; the journal goes on across a new
--                                  version of the witness (fresh: a new journal)
--   _G.NDHumanWatch.scan()         the buttons a player can click now (JSON):
--                                  label (text @ centre), x and y for
--                                  user_mouse_input, menu, covered (another
--                                  object on top of its centre)
--   _G.NDHumanWatch.note(text)     a line in the journal (the scene played)
--   _G.NDHumanWatch.fists(s,seed)  the street's blows for s seconds, a human's rhythm
--                                  (through the game's client: see README)
--   _G.NDHumanWatch.outfit(equipped)  the cloth check now (equipped: the
--                                  server's slots, from NDHumanServer.equipped())
--   _G.NDHumanWatch.read()         the journal (JSON) for tools/humanbot/report.py
--   _G.NDHumanWatch.stop()
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local LogService=game:GetService("LogService")
local GuiService=game:GetService("GuiService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer

local W={}
-- A frame this long (s) is a hitch a player feels.
W.HITCH=.25
-- The keys walk the body this long (s) without it moving: blocked.
W.STUCK=1.5
-- A click on a button that answers nothing within this (s): a dead click.
W.ANSWER=.4
-- Faster than this (studs/s): thrown.
W.THROWN=220
-- The inputs kept before a bug.
W.STEPS=10
-- Warnings that are not the game's (Studio's own, assets a Studio account
-- cannot load): counted, not bugs.
W.KNOWN={"ContentId: ","failed to load","Animation Spoofer","AnalyticsService"}
-- The menus: a visible frame of the HUD that covers the screen and has buttons.
W.MENU_SIZE=.85

-- The journal outlives a new version of the witness sent into the same Play
-- (start(true) begins a fresh one).
local J=_G.NDHumanJournal or {rows={},bugs={},seen={},t0=os.clock()}
_G.NDHumanJournal=J
local rows,bugs,seen=J.rows,J.bugs,J.seen
local conns={}
local running=false
local t0=J.t0
local function now() return math.floor((os.clock()-t0)*100)/100 end
local function r1(x) return math.floor(x*10+.5)/10 end
local function rel(inst)
	local s=inst:GetFullName()
	s=s:gsub("^Players%."..player.Name:gsub("%p","%%%0").."%.","LocalPlayer.")
	return s
end

-- A button's name for a human: its text, or its own name, and where it sits
-- (the HUD's frames are all called "Frame": a path alone names several).
local function label(b)
	local text=if b:IsA("TextButton") and b.Text~="" then b.Text:gsub("%s+"," "):sub(1,32) else nil
	if not text then
		for _,d in b:GetDescendants() do
			if d:IsA("TextLabel") and d.Text~="" then text=d.Text:gsub("%s+"," "):sub(1,32) break end
		end
	end
	local name=if b.Name~="TextButton" and b.Name~="ImageButton" then b.Name else nil
	return string.format("%s @%d,%d",text or name or b.ClassName,math.floor(b.AbsolutePosition.X+b.AbsoluteSize.X/2),math.floor(b.AbsolutePosition.Y+b.AbsoluteSize.Y/2))
end
W.label=label
local function hud() return player.PlayerGui:FindFirstChild("NinjaDuelHUD") end
local function shown(g)
	local pg=player.PlayerGui
	local x=g
	while x and x~=pg do
		if x:IsA("GuiObject") and not x.Visible then return false end
		if x:IsA("LayerCollector") and not x.Enabled then return false end
		x=x.Parent
	end
	return x==pg
end
-- A menu's name: its own name, or the first big title inside it.
local function title(frame)
	if frame.Name~="Frame" then return frame.Name end
	local best,size=nil,0
	for _,d in frame:GetDescendants() do
		-- one line only (a vertical banner of kanji is not the menu's title)
		if d:IsA("TextLabel") and d.Text~="" and not d.Text:find("\n") and shown(d) and d.TextBounds.Y>size and #d.Text<=40 then best,size=d.Text,d.TextBounds.Y end
	end
	return best and ("« "..best.." »") or "menu sans titre"
end
function W.menus()
	local h=hud()
	local out={}
	if not h then return out end
	local vp=workspace.CurrentCamera.ViewportSize
	for _,c in h:GetChildren() do
		if c:IsA("GuiObject") and c.Visible and c.AbsoluteSize.X>=vp.X*W.MENU_SIZE and c.AbsoluteSize.Y>=vp.Y*W.MENU_SIZE then
			local buttons=0
			for _,d in c:GetDescendants() do if d:IsA("GuiButton") and d.Visible then buttons+=1;if buttons>0 then break end end end
			if buttons>0 then table.insert(out,{frame=c,name=title(c)}) end
		end
	end
	return out
end
local function menuNames()
	local n={}
	for _,m in W.menus() do table.insert(n,m.name) end
	return n
end
local function state()
	local c=player.Character
	local r=c and c:FindFirstChild("HumanoidRootPart")
	return {stage=player:GetAttribute("NinjaIntro"),kit=player:GetAttribute("NinjaKit"),menus=menuNames(),
		mouse=UIS.MouseBehavior.Name,at=r and {r1(r.Position.X),r1(r.Position.Y),r1(r.Position.Z)} or nil}
end
local function steps()
	local out={}
	for i=#rows,1,-1 do
		local r=rows[i]
		if r.kind=="in" or r.kind=="act" or r.kind=="note" then table.insert(out,1,r) end
		if #out>=W.STEPS then break end
	end
	return out
end
-- A bug, once per kind and place (key), with the steps before it.
local function bug(kind,key,detail)
	local k=kind.."|"..tostring(key)
	if seen[k] then seen[k].count+=1 return end
	local b={t=now(),kind=kind,key=tostring(key),detail=detail,count=1,state=state(),steps=steps()}
	seen[k]=b
	table.insert(bugs,b)
end
W.bug=bug

-- What is under a point of the screen (GetMouseLocation's space).
local function under(pos)
	local inset=GuiService:GetGuiInset()
	local list=player.PlayerGui:GetGuiObjectsAtPosition(pos.X,pos.Y-inset.Y)
	return list
end
local function buttonOf(list)
	for _,g in list do
		if g:IsA("GuiButton") and g.Active~=false then return g end
		local b=g:FindFirstAncestorWhichIsA("GuiButton")
		if b then return b end
	end
	return nil
end

local answered={}
local function watchButton(b)
	if not b:IsA("GuiButton") or answered[b]~=nil then return end
	answered[b]=0
	table.insert(conns,b.Activated:Connect(function()
		answered[b]=os.clock()
		local text=if b:IsA("TextButton") then b.Text else ""
		table.insert(rows,{t=now(),kind="act",on=label(b),text=text})
	end))
end

local function inputRow(i,began)
	local key=if i.UserInputType==Enum.UserInputType.Keyboard then i.KeyCode.Name else i.UserInputType.Name
	if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Focus then return end
	local row={t=now(),kind="in",key=key,down=began}
	if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.MouseButton2 then
		local pos=UIS:GetMouseLocation()
		row.at={math.floor(pos.X),math.floor(pos.Y)}
		if began then
			local b=buttonOf(under(pos))
			if b then row.on=label(b) end
			if b and i.UserInputType==Enum.UserInputType.MouseButton1 then
				local asked=os.clock()
				task.delay(W.ANSWER,function()
					-- a button the game rebuilt at the click (a tile redrawn) answered: its own
				-- connections went with it, the witness's too
				if not running then return end
				if not b.Parent then table.insert(rows,{t=now(),kind="act",on=row.on,rebuilt=true}) return end
				if not shown(b) then return end
					local a=answered[b]
					if a==nil or a<asked then
						bug("clic mort",label(b),{path=rel(b),at=row.at})
					end
				end)
			end
		end
	end
	if began or row.at then table.insert(rows,row) end
end

local function isKnown(msg)
	for _,k in W.KNOWN do if msg:find(k,1,true) then return true end end
	return false
end

local function cloth(equipped)
	local c=player.Character
	if not c then return end
	local holders,folders={},{}
	for _,d in c:GetChildren() do
		if d.Name=="NinjaOutfit" and d:IsA("Model") then table.insert(holders,d) end
		if d.Name=="NinjaOutfitMesh" then table.insert(folders,d) end
	end
	if #holders>1 then bug("tenue en double","holder",{holders=#holders}) end
	if #folders>1 then bug("tenue en double","pièces",{sets=#folders}) end
	local ids=holders[1] and holders[1]:GetAttribute("NinjaOutfit") or ""
	local stage=player:GetAttribute("NinjaIntro")
	-- the arrival is in his own clothes; after the gate he always wears a top and a bottom
	if stage==nil or stage=="done" then
		if #holders==0 then bug("corps nu","sans tenue",{})
		elseif #folders==0 and ids~="" then bug("corps nu","tenue sans pièces",{ids=ids}) end
	end
	if equipped then
		local have={}
		for _,id in string.split(ids,",") do have[id]=true end
		for slot,id in equipped do
			if type(id)=="string" and id~="" and not have[id] then bug("tenue fausse",slot,{equipped=id,worn=ids}) end
		end
	end
	return {holders=#holders,sets=#folders,ids=ids}
end
function W.outfit(equipped)
	if type(equipped)=="string" then equipped=HttpService:JSONDecode(equipped) end
	return HttpService:JSONEncode(cloth(equipped) or {})
end

local function sweepMenus()
	local list=W.menus()
	if #list>=2 then
		local n={}
		for _,m in list do table.insert(n,m.name) end
		table.sort(n)
		bug("menus ensemble",table.concat(n," + "),{})
	end
	local vp=workspace.CurrentCamera.ViewportSize
	-- AbsolutePosition starts under Roblox's top bar (a HUD that ignores the
	-- inset has negative y up there): the screen is that plus the inset.
	local inset=GuiService:GetGuiInset()
	for _,m in list do
		for _,d in m.frame:GetDescendants() do
			-- a list that scrolls holds buttons below the screen on purpose
			if d:IsA("GuiButton") and shown(d) and d.AbsoluteSize.X>2 and not d:FindFirstAncestorWhichIsA("ScrollingFrame") then
				local cx=d.AbsolutePosition.X+d.AbsoluteSize.X/2
				local cy=d.AbsolutePosition.Y+d.AbsoluteSize.Y/2+inset.Y
				if cx<0 or cy<0 or cx>vp.X or cy>vp.Y then bug("hors écran",label(d),{menu=m.name,path=rel(d)}) end
			end
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and shown(d) and not d.TextScaled and not d.TextWrapped and d.Text~="" and not d.TextFits then
				bug("texte coupé",d.Text:sub(1,40),{menu=m.name,path=rel(d)})
			end
		end
	end
	return list
end

function W.start(fresh)
	W.stop()
	if fresh then
		J.rows,J.bugs,J.seen,J.t0={},{},{},os.clock()
		rows,bugs,seen,t0=J.rows,J.bugs,J.seen,J.t0
	end
	answered={}
	running=true
	for _,d in player.PlayerGui:GetDescendants() do watchButton(d) end
	table.insert(conns,player.PlayerGui.DescendantAdded:Connect(watchButton))
	table.insert(conns,UIS.InputBegan:Connect(function(i) inputRow(i,true) end))
	table.insert(conns,UIS.InputEnded:Connect(function(i) inputRow(i,false) end))
	table.insert(conns,LogService.MessageOut:Connect(function(msg,kind)
		if kind==Enum.MessageType.MessageError and not isKnown(msg) then
			bug("erreur rouge",msg:sub(1,120),{line=msg:sub(1,400)})
		elseif kind==Enum.MessageType.MessageWarning and not isKnown(msg) and not msg:find("NDHuman",1,true) then
			table.insert(rows,{t=now(),kind="warn",text=msg:sub(1,200)})
		end
	end))
	-- the attributes the game moves when the scene changes
	-- the body's place: a duel's folder (Duel_1, Online_3…) or the village
	local lastPlace=nil
	task.spawn(function()
		while running do
			local c=player.Character
			local place=c and c.Parent and c.Parent.Name or "-"
			if place~=lastPlace then
				lastPlace=place
				table.insert(rows,{t=now(),kind="scene",what="place",value=place})
			end
			task.wait(.25)
		end
	end)
	for _,a in {"NinjaIntro","NinjaKit"} do
		table.insert(conns,player:GetAttributeChangedSignal(a):Connect(function()
			table.insert(rows,{t=now(),kind="scene",what=a,value=tostring(player:GetAttribute(a))})
		end))
	end
	local still,lastMenus,lockedSince,sweepAt,clothAt=0,"",nil,0,0
	table.insert(conns,RunService.Heartbeat:Connect(function(dt)
		if dt>W.HITCH then
			table.insert(rows,{t=now(),kind="hitch",dt=r1(dt*1000)/1000})
			if dt>W.HITCH*2 then bug("à-coup",math.floor(dt*10)/10,{ms=math.floor(dt*1000)}) end
		end
		local c=player.Character
		local hum=c and c:FindFirstChildOfClass("Humanoid")
		local r=c and c:FindFirstChild("HumanoidRootPart")
		local open=#W.menus()
		if hum and r and hum.Health>0 then
			local v=r.AssemblyLinearVelocity
			local flat=Vector3.new(v.X,0,v.Z).Magnitude
			-- the body asked to move (W and S held together ask nothing): the Humanoid's own direction
			local walking=hum.MoveDirection.Magnitude>.5
			if walking and open==0 and not r.Anchored and hum.WalkSpeed>0 and flat<.5 then
				still+=dt
				if still>W.STUCK then
					bug("corps bloqué",string.format("%d,%d",math.floor(r.Position.X/8)*8,math.floor(r.Position.Z/8)*8),{at={r1(r.Position.X),r1(r.Position.Y),r1(r.Position.Z)},speed=hum.WalkSpeed,state=hum:GetState().Name})
					still=-3
				end
			else
				still=math.max(0,still)
				if not walking then still=0 end
			end
			if v.Magnitude>W.THROWN then bug("projeté",math.floor(v.Magnitude/50)*50,{speed=math.floor(v.Magnitude),at={r1(r.Position.X),r1(r.Position.Y),r1(r.Position.Z)}}) end
			if r.Position.Y<workspace.FallenPartsDestroyHeight+60 then bug("chute","sous la carte",{y=r1(r.Position.Y)}) end
		end
		-- a menu open, the mouse locked in the centre: no button can be aimed
		if open>0 and UIS.MouseBehavior==Enum.MouseBehavior.LockCenter then
			lockedSince=lockedSince or os.clock()
			if os.clock()-lockedSince>.6 then bug("souris bloquée",table.concat(menuNames()," + "),{}) end
		else
			lockedSince=nil
		end
		local t=os.clock()
		if t-sweepAt>.5 then
			sweepAt=t
			local names=table.concat(menuNames()," + ")
			if names~=lastMenus then
				lastMenus=names
				table.insert(rows,{t=now(),kind="menus",open=names})
			end
			sweepMenus()
		end
		if t-clothAt>2 then clothAt=t;pcall(cloth,nil) end
	end))
	-- a fall into the void: nothing under the body for 300 studs
	task.spawn(function()
		while running do
			local c=player.Character
			local r=c and c:FindFirstChild("HumanoidRootPart")
			if r then
				local p=RaycastParams.new();p.FilterDescendantsInstances={c};p.FilterType=Enum.RaycastFilterType.Exclude
				local hit=workspace:Raycast(r.Position,Vector3.new(0,-300,0),p)
				if not hit and r.AssemblyLinearVelocity.Y<-5 then bug("chute","dans le vide",{at={r1(r.Position.X),r1(r.Position.Y),r1(r.Position.Z)}}) end
			end
			task.wait(.5)
		end
	end)
	return "témoin en route"
end

-- The buttons a player can click now: path (user_mouse_input instance_path),
-- text, the menu they belong to, and whether something else covers their
-- centre (a human's click would land on that instead).
function W.scan()
	local out={}
	local inset=GuiService:GetGuiInset()
	local vp=workspace.CurrentCamera.ViewportSize
	local menus=W.menus()
	for _,d in player.PlayerGui:GetDescendants() do
		if d:IsA("GuiButton") and shown(d) and d.AbsoluteSize.X>4 and d.AbsoluteSize.Y>4 then
			local g=d:FindFirstAncestorWhichIsA("LayerCollector")
			local gname=g and g.Name or "?"
			if gname=="ClipAssistPanel" or gname=="Freecam" or gname:find("^NinjaDuelDev") or gname:find("^DevVisual") or gname=="NinjaDuelCombatInspector" then continue end
			local cx=d.AbsolutePosition.X+d.AbsoluteSize.X/2
			local cy=d.AbsolutePosition.Y+d.AbsoluteSize.Y/2
			local menu=nil
			for _,m in menus do if d:IsDescendantOf(m.frame) then menu=m.name end end
			local top=player.PlayerGui:GetGuiObjectsAtPosition(cx,cy)[1]
			local covered=top~=nil and top~=d and not top:IsDescendantOf(d)
			-- x, y: user_mouse_input's coordinates, the GUI's (under Roblox's top
			-- bar: the screen's y less the inset; measured 27/11)
			table.insert(out,{label=label(d),menu=menu,
				x=math.floor(cx),y=math.floor(cy),w=math.floor(d.AbsoluteSize.X),h=math.floor(d.AbsoluteSize.Y),
				covered=covered and rel(top) or nil,onScreen=cx>=0 and cy+inset.Y>=0 and cx<=vp.X and cy+inset.Y<=vp.Y})
		end
	end
	return HttpService:JSONEncode({menus=menuNames(),mouse=UIS.MouseBehavior.Name,stage=player:GetAttribute("NinjaIntro"),buttons=out})
end

-- (27/11, François : « envoyer des coups, se battre ») The street's blows,
-- pressed through the game's own client (Client/HubFightClient:press, what
-- its click handler calls): Studio's hands arrive « already processed » and
-- the street's handler leaves those (see the README). A human's rhythm:
-- bursts of light blows, a heavy now and then, a dodge, pauses. Runs beside
-- the hands (the walk, the menus) for `seconds`; each press is a row
-- "fist:<move>".
W.FISTS={"Light","Light","Light","Heavy","Dodge","Light","Heavy"}
function W.fists(seconds,seed)
	local ps=player:WaitForChild("PlayerScripts")
	local module=ps:FindFirstChild("HubFightClient",true)
	if not module then return "pas de HubFightClient" end
	local rng=Random.new(seed or 1)
	local stopAt=os.clock()+(seconds or 30)
	W.fisting=true
	task.spawn(function()
		while W.fisting and os.clock()<stopAt do
			local f=require(module).current
			local burst=rng:NextInteger(1,4)
			for _=1,burst do
				local move=W.FISTS[rng:NextInteger(1,#W.FISTS)]
				local ok=f~=nil and pcall(function() f:press(move) end)
				table.insert(rows,{t=now(),kind="in",key="fist:"..move,down=true,live=f~=nil and f:live() or false,ok=ok})
				task.wait(rng:NextNumber(.12,.35))
			end
			task.wait(rng:NextNumber(.3,1.6))
		end
		W.fisting=false
	end)
	return "coups pendant "..tostring(seconds or 30).." s"
end

function W.note(text)
	table.insert(rows,{t=now(),kind="note",text=tostring(text)})
	return "ok"
end

function W.read()
	local inputs,acts=0,0
	for _,r in rows do
		if r.kind=="in" and r.down then inputs+=1 end
		if r.kind=="act" then acts+=1 end
	end
	return HttpService:JSONEncode({inputs=inputs,answers=acts,seconds=now(),bugs=bugs,rows=rows})
end

function W.stop()
	running=false
	for _,c in conns do c:Disconnect() end
	conns={}
	return "ok"
end

return W
