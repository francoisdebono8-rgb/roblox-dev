-- Optional lobby / matchmaking lifecycle. No Instances, listeners or boot call.
-- createPair(entryA,entryB,epoch) is a future server arena adapter returning a
-- validated OnlineMatch. Local Matches and its client are not compatible adapters.
local Protocol=require(game:GetService("ReplicatedStorage").NinjaDuel.OnlineProtocol)
local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
local Queue=require(script.Parent.OnlineQueue)
local Host={};Host.__index=Host
function Host.new(config,createPair)
 if not config or config.Enabled~=true then return nil,"Online disabled" end
 assert(type(createPair)=="function","A server-owned two-player arena factory is required")
 return setmetatable({queue=Queue.new(Protocol.QueueLimit),createPair=createPair,matches={},byPlayer={},epoch=0},Host)
end
function Host:join(player,fighter)
 if self.byPlayer[player] then return false,"Already in match" end
 if type(fighter)~="string" or not Fighters[fighter] then return false,"Unknown fighter" end
 return self.queue:join(player,fighter)
end
function Host:pair()
 local a,b=self.queue:pair();if not a then return nil end
 self.epoch+=1
 local ok,match=pcall(function()
  local result=self.createPair(a,b,self.epoch)
  assert(result and result.byPlayer[a.player] and result.byPlayer[b.player],"Factory returned wrong participants")
  return result
 end)
 if not ok or not match then self.queue:join(a.player,a.fighter);self.queue:join(b.player,b.fighter);return nil,"Arena factory failed" end
 self.matches[match]=true;self.byPlayer[a.player]=match;self.byPlayer[b.player]=match;return match
end
function Host:remove(player)
 self.queue:leave(player);local match=self.byPlayer[player]
 if match then match:disconnect(player);self:release(match) end
end
function Host:release(match)
 if not self.matches[match] then return end
 self.matches[match]=nil
 for _,p in match.players do self.byPlayer[p]=nil end
 -- Arena ownership stays with the supplied factory; host announces termination.
 if match.cleanup then match:cleanup() end
end
return Host
