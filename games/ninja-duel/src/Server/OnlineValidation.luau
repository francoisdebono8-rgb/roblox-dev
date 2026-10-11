-- Produces a fresh allowlisted intent; clients cannot write combat state.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Protocol=require(Shared.OnlineProtocol)
local Rules=require(Shared.Rules)
local Validation={}
local function vector(v) return typeof(v)=="Vector3" and Rules.finite(v.X) and Rules.finite(v.Y) and Rules.finite(v.Z) end
function Validation.intent(match,player,payload,now)
 if match.phase~="Duel" or not match.byPlayer[player] then return nil,"Not a participant" end
 if type(payload)~="table" or payload.version~=Protocol.Version or payload.epoch~=match.epoch then return nil,"Stale protocol/epoch" end
 if type(payload.action)~="string" or not Protocol.actions[payload.action] then return nil,"Unknown action" end
 if not Rules.finite(payload.sequence) or payload.sequence%1~=0 or payload.sequence<=0 or payload.sequence<=(match.sequence[player] or 0) then return nil,"Stale sequence" end
 if type(payload.clientTime)~="number" or payload.clientTime~=payload.clientTime or math.abs(payload.clientTime)==math.huge or math.abs(payload.clientTime-now)>1 then return nil,"Stale clock" end
 local clean={action=payload.action,clientTime=payload.clientTime,sequence=payload.sequence}
 if payload.direction~=nil then
  if not vector(payload.direction) or payload.direction.Magnitude>1.01 or math.abs(payload.direction.Y)>.01 then return nil,"Invalid direction" end
  clean.direction=payload.direction
 elseif payload.action=="Move" then return nil,"Missing direction" end
 for _,key in {"sprint","locked"} do
  if payload[key]~=nil then if type(payload[key])~="boolean" then return nil,"Invalid flag" end;clean[key]=payload[key] end
 end
 if payload.aim~=nil then
  local actor=match.byPlayer[player]
  if not vector(payload.aim) or (payload.aim-actor.root.Position).Magnitude>140 then return nil,"Invalid aim" end
  clean.aim=payload.aim
 end
 return clean
end
return Validation
