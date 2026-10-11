-- Recipient-specific reliable snapshot envelope. Independent impact cursors.
-- Explicit send acknowledgement: building a packet must not lose impacts.
local Protocol=require(game:GetService("ReplicatedStorage").NinjaDuel.OnlineProtocol)
local Replication={};Replication.__index=Replication
function Replication.new(match) return setmetatable({match=match,cursors={},serials={}},Replication) end
function Replication:packet(player,serializeActor)
 local m=self.match;if not m.byPlayer[player] then return nil end
 local cursor=self.cursors[player] or 0;local feed={}
 for _,impact in m.combat.impacts do if impact.serial>cursor then table.insert(feed,table.clone(impact)) end end
 local actors={};for i,a in m.actors do actors[i]=serializeActor(a);actors[i].ownerUserId=m.players[i].UserId end
 return {version=Protocol.Version,epoch=m.epoch,sequence=(self.serials[player] or 0)+1,serverNow=m.combat.now,
  phase=m.phase,selfActor=m.byPlayer[player].id,actors=actors,impacts=feed,impactSerial=m.combat.impactSerial or 0,winner=m.winner and m.winner.UserId,reason=m.reason}
end
function Replication:sent(player,packet)
 if packet.epoch~=self.match.epoch or not self.match.byPlayer[player] then return false end
 if packet.selfActor~=self.match.byPlayer[player].id or packet.sequence~=(self.serials[player] or 0)+1 then return false end
 self.serials[player]=packet.sequence;self.cursors[player]=packet.impactSerial;return true
end
return Replication
