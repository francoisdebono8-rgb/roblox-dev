-- FIFO queue: server-owned Player identities, no client-supplied opponent.
local Queue={};Queue.__index=Queue
function Queue.new(limit) return setmetatable({limit=limit or 32,entries={},members={}},Queue) end
function Queue:join(player,fighter)
 if self.members[player] then return false,"Already queued" end
 if #self.entries>=self.limit then return false,"Queue full" end
 local entry={player=player,fighter=fighter};self.members[player]=entry;table.insert(self.entries,entry);return true
end
function Queue:leave(player)
 self.members[player]=nil
 for i=#self.entries,1,-1 do if self.entries[i].player==player then table.remove(self.entries,i) end end
end
function Queue:pair()
 if #self.entries<2 then return nil end
 local a=table.remove(self.entries,1);local b=table.remove(self.entries,1);self.members[a.player]=nil;self.members[b.player]=nil;return a,b
end
return Queue
