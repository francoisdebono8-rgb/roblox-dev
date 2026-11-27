-- The human robot's witness, on the server (OUTILLEUR, 27/11). What the
-- player's clicks asked of the server and what it answered: every profile
-- command (Progression.run: buy, equip, choose, learn…) with its result and
-- the Ryō before and after, the red lines of the server, and the money that
-- goes wrong:
--   a payment taken twice for one thing      -> « payé deux fois »
--   Ryō below zero or above the purse        -> « Ryō faux »
--   a command refused, then the same one at once accepted (or the reverse):
--   kept as rows; the report counts the refusals by reason.
--   (27/11 après-midi) a request the screen sent and the server refused
--   without a word to the player (a method of H.SILENT returning false: the
--   tournament entered with a kit he does not own)  -> « refus muet »
--
-- A server module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py --server humanserver   (eval_server_runtime)
--   _G.NDHumanServer.start()      wraps Progression.run (the module's own field)
--   _G.NDHumanServer.equipped()   the slots the profile says he wears (JSON),
--                                 for NDHumanWatch.outfit on the client
--   _G.NDHumanServer.ryo()        his Ryō now
--   _G.NDHumanServer.read()       the rows and bugs (JSON)
--   _G.NDHumanServer.stop()
local Players=game:GetService("Players")
local LogService=game:GetService("LogService")
local HttpService=game:GetService("HttpService")
local Server=game:GetService("ServerScriptService"):WaitForChild("NinjaDuelServer")

local H={rows={},bugs={}}
local seen={}
local conns={}
local t0=os.clock()
local function now() return math.floor((os.clock()-t0)*100)/100 end
H.KNOWN={"ContentId: ","failed to load","AnalyticsService","Animation Spoofer"}
-- Commands that cost something: the same paid twice in this time (s) is a double payment.
H.TWICE=3
-- Server methods that answer a click and return false when they refuse it,
-- with nothing sent to the player: {module, method}. Wrapped on the module's
-- table (the instances find them through __index).
H.SILENT={{"Tournament","start"}}

local function P() return require(Server.Progression) end
local function wallet(player)
	local h=P().handles[player]
	return h and h.data and h.data.wallet and h.data.wallet.ryo
end
local function bug(kind,key,detail)
	local k=kind.."|"..tostring(key)
	if seen[k] then seen[k].count+=1 return end
	local b={t=now(),kind=kind,key=tostring(key),detail=detail,count=1}
	seen[k]=b
	table.insert(H.bugs,b)
end
local function short(v)
	if type(v)=="table" then
		local ok,s=pcall(HttpService.JSONEncode,HttpService,v)
		return if ok then s:sub(1,160) else "table"
	end
	return tostring(v):sub(1,160)
end

function H.start()
	H.stop()
	H.rows,H.bugs,seen={},{},{}
	t0=os.clock()
	local Prog=P()
	if not Prog._ndRun then Prog._ndRun=Prog.run end
	local paid={}
	Prog.run=function(player,kind,args)
		local before=wallet(player)
		local ok,result=Prog._ndRun(player,kind,args)
		local after=wallet(player)
		local row={t=now(),kind="cmd",who=player.Name,cmd=tostring(kind),args=short(args),ok=ok==true,result=if ok then nil else short(result),ryo={before,after}}
		table.insert(H.rows,row)
		if type(after)=="number" and (after<0 or after~=after) then bug("Ryō faux",kind,{ryo=after}) end
		if ok and type(before)=="number" and type(after)=="number" and after<before then
			local what=kind..":"..short(args)
			local last=paid[what]
			if last and os.clock()-last<H.TWICE then bug("payé deux fois",what,{ryo={before,after}}) end
			paid[what]=os.clock()
		end
		return ok,result
	end
	for _,pair in H.SILENT do
		local okModule,mod=pcall(require,Server:FindFirstChild(pair[1]))
		local name=pair[2]
		if okModule and type(mod)=="table" and type(mod[name])=="function" and not mod["_nd"..name] then
			local orig=mod[name]
			mod["_nd"..name]=orig
			mod[name]=function(self,player,...)
				local res=table.pack(orig(self,player,...))
				if res[1]==false then
					local first=select(1,...)
					table.insert(H.rows,{t=now(),kind="refus",who=player and player.Name,cmd=pair[1].."."..name,args=short(first),ok=false,result=short(res[2] or "sans raison")})
					bug("refus muet",pair[1].."."..name..":"..short(first),{why=short(res[2] or "sans raison")})
				end
				return table.unpack(res,1,res.n)
			end
		end
	end
	table.insert(conns,LogService.MessageOut:Connect(function(msg,kind)
		if kind~=Enum.MessageType.MessageError then return end
		for _,k in H.KNOWN do if msg:find(k,1,true) then return end end
		bug("erreur rouge (serveur)",msg:sub(1,120),{line=msg:sub(1,400)})
	end))
	return "témoin serveur en route"
end

function H.equipped()
	local p=Players:GetPlayers()[1]
	local h=p and P().handles[p]
	local st=h and h.data and h.data.style
	-- the slots that put something on the body: an id "…None" wears nothing,
	-- the hair colour paints the hair (no piece of its own)
	local out={}
	for slot,id in (st and st.equipped or {}) do
		if type(id)=="string" and id~="" and not id:find("None$") and slot~="hairColor" then out[slot]=id end
	end
	return HttpService:JSONEncode(out)
end
function H.ryo()
	local p=Players:GetPlayers()[1]
	return p and wallet(p)
end
function H.read() return HttpService:JSONEncode({rows=H.rows,bugs=H.bugs}) end

-- (27/11 soir, passe 4, François : « le robot humain sur les murs ») The walls,
-- read only: in the village each pose his client sends (HubPose: climb,
-- wallstand, siderunR/L, leap, kick, vault), in a duel each fighter's wall mode,
-- state and health when one changes, and every house opened
-- (WorldReaction.breach: a body thrown into it, or a blow that hit it).
H.WALLS={pose={},duel={},breach={},t0=os.clock()}
local wallsOn=false
function H.walls()
	if wallsOn then return "déjà en route" end
	wallsOn=true
	local W=H.WALLS
	W.pose,W.duel,W.breach,W.t0={},{},{},os.clock()
	local function at() return math.floor((os.clock()-W.t0)*100)/100 end
	local function v3(p) return string.format("%.0f,%.0f,%.0f",p.X,p.Y,p.Z) end
	local remote=game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuel")
	remote=remote and remote:FindFirstChild("HubPose")
	if remote then
		table.insert(conns,remote.OnServerEvent:Connect(function(player,pose)
			local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			table.insert(W.pose,{t=at(),who=player.Name,pose=tostring(pose),at=root and v3(root.Position) or ""})
		end))
	end
	local okWR,WR=pcall(require,Server:FindFirstChild("WorldReaction"))
	if okWR and type(WR)=="table" and WR.breach and not WR._ndbreach then
		WR._ndbreach=WR.breach
		WR.breach=function(c,part,position,normal,energy,direction)
			table.insert(W.breach,{t=at(),part=part and part:GetFullName():sub(-48) or "?",at=typeof(position)=="Vector3" and v3(position) or "",energy=math.floor((tonumber(energy) or 0)*10)/10})
			return WR._ndbreach(c,part,position,normal,energy,direction)
		end
	end
	task.spawn(function()
		local okF,F=pcall(require,Server:FindFirstChild("Forest"))
		local last={}
		while wallsOn do
			for _,player in Players:GetPlayers() do
				local s=okF and F.matches and F.matches:session(player)
				local c=s and s.combat
				for _,a in (c and c.actors or {}) do
					local mode=a.wall and a.wall.mode or "-"
					local hp=math.floor(a.health or -1)
					local key=player.Name.."/"..tostring(a.id)
					local sig=mode.."|"..tostring(a.state).."|"..hp
					if last[key]~=sig then
						last[key]=sig
						table.insert(W.duel,{t=at(),who=tostring(a.id),mode=mode,state=tostring(a.state),hp=hp,
							y=a.root and math.floor(a.root.Position.Y*10)/10 or -1})
					end
				end
			end
			task.wait(.1)
		end
	end)
	return "murs suivis"
end
-- What the walls did: the stands and how they ended, the houses opened.
function H.wallsRead()
	return HttpService:JSONEncode(H.WALLS)
end
function H.stop()
	local Prog=P()
	if Prog._ndRun then Prog.run=Prog._ndRun;Prog._ndRun=nil end
	for _,pair in H.SILENT do
		local okModule,mod=pcall(require,Server:FindFirstChild(pair[1]))
		local name=pair[2]
		if okModule and type(mod)=="table" and mod["_nd"..name] then mod[name]=mod["_nd"..name];mod["_nd"..name]=nil end
	end
	wallsOn=false
	local okWR,WR=pcall(require,Server:FindFirstChild("WorldReaction"))
	if okWR and type(WR)=="table" and WR._ndbreach then WR.breach=WR._ndbreach;WR._ndbreach=nil end
	for _,c in conns do c:Disconnect() end
	conns={}
	return "ok"
end

return H
