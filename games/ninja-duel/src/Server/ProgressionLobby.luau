-- Optional future online lobby adapter. No listeners, networking or combat.
local Roster=require(script.Parent.ProgressionRoster)
local Queue=require(script.Parent.OnlineQueue)
local Lobby={};Lobby.__index=Lobby
function Lobby.new(cfg,lookup)
 if cfg.Enabled~=true then return nil,"Progression online disabled" end
 assert(type(lookup)=="function","Server-owned profile lookup required")
 return setmetatable({cfg=cfg,lookup=lookup,queues={},queued={}},Lobby)
end
function Lobby:join(player,mode,region,id)
 if not self.cfg.Regions[region] then return false,"Unknown configured region" end
 if self.queued[player] then return false,"Already queued" end
 local profile,ready=self.lookup(player);if not ready then return false,"Profile unavailable" end
 if mode~="Ranked" and mode~="ProgressionBattles" then return false,"Unknown matchmaking mode" end
 local plan,reason=Roster.select(self.cfg,profile,mode,id);if not plan then return false,reason end
 local ok,key=pcall(Roster.queueKey,mode,region);if not ok then return false,"Invalid region" end
 self.queues[key]=self.queues[key] or Queue.new(32)
 local joined,err=self.queues[key]:join(player,id);if not joined then return false,err end
 self.queued[player]={key=key,mode=mode,character=id};return true,plan
end
function Lobby:leave(player)
 local entry=self.queued[player]
 if entry then
  local queue=self.queues[entry.key];queue:leave(player);self.queued[player]=nil
  if #queue.entries==0 then self.queues[entry.key]=nil end
 end
end
function Lobby:pair(key)
 local queue=self.queues[key];if not queue then return nil end
 -- Revalidate ownership/loading at dequeue, never trust the entry snapshot.
 for _,entry in table.clone(queue.entries) do
  local p,ready=self.lookup(entry.player);local queued=self.queued[entry.player]
  if not ready or not queued or not Roster.select(self.cfg,p,queued.mode,entry.fighter) then self:leave(entry.player) end
 end
 local a,b=queue:pair();if #queue.entries==0 then self.queues[key]=nil end;if not a then return nil end
 local mode=self.queued[a.player].mode;self.queued[a.player]=nil;self.queued[b.player]=nil
 return {mode=mode,a=a,b=b,combatApplicationEnabled=false}
end
return Lobby
