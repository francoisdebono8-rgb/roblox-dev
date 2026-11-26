-- The server's side of the street robot (OUTILLEUR, passe commune 3, 26/11;
-- DEC-055). What each street blow met (Server/HubFight.land), each challenge
-- between two players (HubFight.strikePlayer: "challenge", "accept", "wait",
-- "busy"), each player's session as it changes (Selection, a duel, which
-- folder, where), and the props broken then put back (WorldReaction, after
-- Shared/HubFight.RESTORE s of calm).
--
-- A server module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py --server streetlog      (eval_server_runtime)
--   _G.NDStreetLog.start()      wraps HubFight.land and strikePlayer (the
--                               module's own fields: nothing else changes)
--   _G.NDStreetLog.read()       the rows, as JSON
--   _G.NDStreetLog.world()      the village's broken props now (WorldReaction)
--   _G.NDStreetLog.stop()
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Server=game:GetService("ServerScriptService"):WaitForChild("NinjaDuelServer")

local Log={rows={}}
local watching=false
local function now() return math.floor(workspace:GetServerTimeNow()*100)/100 end
local function v3(v) return if typeof(v)=="Vector3" then {math.floor(v.X*10)/10,math.floor(v.Y*10)/10,math.floor(v.Z*10)/10} else nil end

function Log.start()
	local HF=require(Server.HubFight)
	Log.rows={}
	if not HF._ndLand then HF._ndLand=HF.land end
	if not HF._ndStrike then HF._ndStrike=HF.strikePlayer end
	HF.land=function(player,character,move,t,dir)
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local result=HF._ndLand(player,character,move,t,dir)
		table.insert(Log.rows,{t=now(),kind="land",who=player.Name,move=move,result=tostring(result),at=v3(root and root.Position)})
		return result
	end
	HF.strikePlayer=function(player,other,t)
		local result=HF._ndStrike(player,other,t)
		table.insert(Log.rows,{t=now(),kind="strike",who=player.Name,other=other.Name,result=tostring(result)})
		return result
	end
	watching=true
	task.spawn(function()
		local last={}
		while watching do
			local m=HF.matches
			for _,p in Players:GetPlayers() do
				local s=m and m.sessions and m.sessions[p]
				local c=p.Character
				local key=string.format("%s|%s|%s",tostring(s and s.phase),tostring(c and c.Name),tostring(c and c.Parent and c.Parent.Name))
				if last[p]~=key then
					last[p]=key
					local r=c and c:FindFirstChild("HumanoidRootPart")
					local row={t=now(),kind="state",who=p.Name,state=key,at=v3(r and r.Position)}
					local d=s and s.online and s.online.duel
					if d then
						row.site=d.site and d.site.key
						row.quick=d.quick
						row.kits={}
						for _,seat in ipairs(d.seats or {}) do table.insert(row.kits,tostring(seat.fighter)) end
					end
					table.insert(Log.rows,row)
				end
			end
			local c=HF.context and HF.context()
			local broken=c and c.world~=nil
			if broken~=Log.broken then
				Log.broken=broken
				table.insert(Log.rows,{t=now(),kind="world",broken=broken,calm=math.floor((os.clock()-HF.lastBreak)*10)/10})
			end
			task.wait(.1)
		end
	end)
	return "journal de rue en route"
end

function Log.world()
	local HF=require(Server.HubFight)
	local c=HF.context()
	local w=c.world
	if not w then return "rien de cassé" end
	return string.format("cassé : %d fissures, %d gravats ; dernier coup il y a %.1f s",#(w.scars or {}),#(w.rubble or {}),os.clock()-HF.lastBreak)
end

function Log.read() return HttpService:JSONEncode(Log.rows) end

function Log.stop()
	watching=false
	local HF=require(Server.HubFight)
	if HF._ndLand then HF.land=HF._ndLand;HF._ndLand=nil end
	if HF._ndStrike then HF.strikePlayer=HF._ndStrike;HF._ndStrike=nil end
	return "ok"
end

return Log
