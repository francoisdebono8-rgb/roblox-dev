-- TEST ONLY, in the running server of a LAB copy (robloxstudio-mcp
-- eval_server_runtime), never in a source file (OUTILLEUR, Studio 19/11).
-- Studio's test players have negative UserIds (-1, -2); Server/Lobby drops a
-- challenge whose `to` is not above 0 (`payload.to>0`), so in a multiplayer
-- playtest no challenge is ever sent. This passes a negative `to` on to
-- Lobby:challenge with the same checks as Lobby:request (the op gap, the
-- fighter of the beta roster). To remove once the DEV accepts Studio's ids.
local Lobby=require(game:GetService("ServerScriptService").NinjaDuelServer.Lobby)
if not Lobby.__duoPatched then
	local original=Lobby.request
	Lobby.request=function(self,player,payload)
		if type(payload)=="table" and payload.op=="challenge" and type(payload.to)=="number" and payload.to<0 then
			local p=self.players[player.UserId]
			if not p then return end
			local now=self.svc.now()
			if now-p.lastOp<0.25 then return end
			p.lastOp=now
			local BetaRoster=require(game:GetService("ReplicatedStorage").NinjaDuel.BetaRoster)
			local fighter=if type(payload.fighter)=="string" and table.find(BetaRoster,payload.fighter) then payload.fighter else nil
			return self:challenge(p,math.floor(payload.to),fighter,now)
		end
		return original(self,player,payload)
	end
	Lobby.__duoPatched=true
end
return "patched"
