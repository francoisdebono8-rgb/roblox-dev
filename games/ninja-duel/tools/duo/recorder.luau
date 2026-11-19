-- The two-player run's recorder (OUTILLEUR, 19/11, vague 2 OUTILLEUR 3): run
-- it in EACH client of a Studio multiplayer playtest (robloxstudio-mcp
-- multiplayer_playtest, then eval_client_runtime on client-1 and client-2),
-- in a LAB copy of ND-JEU, never in another discussion's place. It notes, at
-- the server's time (workspace:GetServerTimeNow, the same on both clients):
--   lobby   what the lobby says (sent, invite, closed, status and its text)
--   phase   Selection, Pick, Duel, Result...; with the online mode, the
--           opponent, the site of the duel (street or stadium) and its origin
--   round   the rounds won on each side; `hp` each time the opponent loses health
--   body    the player's body: in Konoha (NinjaHubBody) or the duel's rig,
--           with where it stands
--   in      every input (a `*` = taken by a screen)
--   shared.NDDuo.json()     the record, for tools/duo/report.py
--   shared.NDDuo.pilot(on)  (client 1 only) fights the duel on its own: moves
--           to the opponent and strikes through the same Action remote the
--           keyboard uses, so a duel ends without hundreds of driven clicks;
--           the challenge, the answer and the way back are real inputs
--   shared.NDDuo.button(text)  where a visible button is on screen (to click it)
--   shared.NDDuo.stop()
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local GuiService=game:GetService("GuiService")
if shared.NDDuo and shared.NDDuo.stop then shared.NDDuo.stop() end
local me=Players.LocalPlayer
local rec={who=me.Name,id=me.UserId,events={},conns={},last={}}
shared.NDDuo=rec
local function now() return math.floor(workspace:GetServerTimeNow()*1000)/1000 end
local function note(kind,data) table.insert(rec.events,{t=now(),k=kind,d=data}) end
local function v3(v) return if typeof(v)=="Vector3" then {math.floor(v.X),math.floor(v.Y),math.floor(v.Z)} else nil end
local Shared=RS:WaitForChild("NinjaDuel")
local HubMap=require(Shared:WaitForChild("HubMap"))
-- the street of Konoha a duel's origin is in (HubMap.Streets), if any
local function streetAt(origin)
	if typeof(origin)~="Vector3" then return nil end
	for _,street in HubMap.Streets or {} do
		local centre=HubMap.Origin+street.at
		if (Vector3.new(centre.X,0,centre.Z)-Vector3.new(origin.X,0,origin.Z)).Magnitude<(street.radius or 20)+5 then return street.key end
	end
	return nil
end
rec.note=note
local L=rec.last
table.insert(rec.conns,Shared:WaitForChild("Lobby").OnClientEvent:Connect(function(data)
	if type(data)~="table" or data.kind=="list" then return end
	note("lobby",{kind=data.kind,text=data.text,from=data.from,to=data.to,id=data.id})
end))
table.insert(rec.conns,Shared:WaitForChild("Action").OnClientEvent:Connect(function(data)
	if type(data)~="table" then return end
	L.epoch=data.epoch or L.epoch
	L.data=data
	if data.phase~=L.phase then
		local o=data.online
		local site=data.site
		note("phase",{phase=data.phase,mode=o and o.mode,opponent=o and o.opponent,me=o and o.me,them=o and o.them,
			site=site and site.key,street=site and site.street==true,place=site and site.place,origin=v3(data.origin),
			inStreet=streetAt(data.origin)})
		L.phase=data.phase
	end
	local w=data.wins
	local key=w and (tostring(w.human).."-"..tostring(w.bot)) or nil
	if key and key~=L.wins then note("round",{round=data.round,wins=key});L.wins=key end
	local b=data.bot
	if b and b.health and L.bh and b.health<L.bh and data.phase=="Duel" then note("hp",b.health) end
	L.bh=b and b.health
	if data.notice and data.notice~=L.notice then note("notice",data.notice) end
	L.notice=data.notice
end))
table.insert(rec.conns,UIS.InputBegan:Connect(function(input,gp)
	local name=input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode.Name or input.UserInputType.Name
	if name~="MouseMovement" then note("in",name..(if gp then "*" else "")) end
end))
-- the body: in Konoha or in the duel, and where
table.insert(rec.conns,RunService.Heartbeat:Connect(function()
	local c=me.Character
	local hub=c and c:GetAttribute("NinjaHubBody")==true
	local root=c and c:FindFirstChild("HumanoidRootPart")
	local state=if not c then "none" elseif hub then "konoha" else "duel"
	if state~=L.body and root then
		note("body",{state=state,at=v3(root.Position),street=streetAt(root.Position)})
		L.body=state
	elseif not c and L.body~="none" then
		note("body",{state="none"});L.body="none"
	end
end))

-- (client 1) the duel fought on its own, through the keyboard's own remote
local pilot=nil
function rec.pilot(on)
	if pilot then pilot.on=false;pilot=nil end
	if not on then return "pilot off" end
	local remote=Shared:WaitForChild("Action")
	pilot={on=true}
	local p=pilot
	task.spawn(function()
		local nextHit=0
		while p.on do
			local d=L.data
			if d and d.phase=="Duel" and d.human and d.bot and (d.intro or 0)<=0 and not d.ko then
				local mine=d.human.position or (me.Character and me.Character:FindFirstChild("HumanoidRootPart") and me.Character.HumanoidRootPart.Position)
				local theirs=d.bot.position
				if typeof(mine)=="Vector3" and typeof(theirs)=="Vector3" then
					local gap=(theirs-mine)*Vector3.new(1,0,1)
					local dir=if gap.Magnitude>4 then gap.Unit else Vector3.zero
					remote:FireServer({action="Move",epoch=L.epoch,direction=dir,locked=true,sprint=false})
					if gap.Magnitude<=6 and os.clock()>=nextHit then
						remote:FireServer({action="Attack",epoch=L.epoch,clientTime=workspace:GetServerTimeNow()})
						nextHit=os.clock()+.35
					end
				end
			end
			task.wait(.1)
		end
	end)
	return "pilot on"
end

-- a visible button by its text: its centre in viewport points (for a click)
function rec.button(text)
	local inset=GuiService:GetGuiInset()
	for _,o in me.PlayerGui:GetDescendants() do
		if o:IsA("TextButton") and o.Visible and string.find(string.upper(o.Text),string.upper(text),1,true) then
			local shown=true
			local q=o.Parent
			while q and q:IsA("GuiObject") do if not q.Visible then shown=false;break end;q=q.Parent end
			local sg=o:FindFirstAncestorWhichIsA("ScreenGui")
			if shown and sg and sg.Enabled and o.AbsoluteSize.X>0 then
				local c=o.AbsolutePosition+o.AbsoluteSize/2
				local y=c.Y+(if sg.IgnoreGuiInset then 0 else inset.Y)
				return {x=math.floor(c.X),y=math.floor(y),text=o.Text,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y}
			end
		end
	end
	return nil
end

-- the same button as an instance path (Roblox_Studio user_mouse_input clicks
-- by path: "LocalPlayer.PlayerGui....")
function rec.path(text)
	for _,o in me.PlayerGui:GetDescendants() do
		if o:IsA("TextButton") and o.Visible and string.find(string.upper(o.Text),string.upper(text),1,true) then
			local q=o.Parent
			local shown=true
			while q and q:IsA("GuiObject") do if not q.Visible then shown=false;break end;q=q.Parent end
			if shown then return (string.gsub(o:GetFullName(),"^Players%."..me.Name.."%.","LocalPlayer.")) end
		end
	end
	return nil
end

function rec.json() return HttpService:JSONEncode({who=rec.who,id=rec.id,events=rec.events}) end
function rec.stop() rec.pilot(false);for _,c in rec.conns do c:Disconnect() end end
note("start",{who=rec.who,id=rec.id})
return "recording "..rec.who
