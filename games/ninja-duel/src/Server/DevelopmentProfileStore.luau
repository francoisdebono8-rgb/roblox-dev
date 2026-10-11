-- Deterministic UpdateAsync stand-in. Copies emulate serialization boundaries.
local S=require(script.Parent.ProfileSchema)
local Store={};Store.__index=Store
function Store.new(data) return setmetatable({data=S.copy(data or {}),failBefore=0,failAfter=0,repeatTransform=false,calls=0},Store) end
function Store:update(key,transform)
 self.calls+=1
 if self.failBefore>0 then self.failBefore-=1;error("Simulated store unavailable") end
 local old=S.copy(self.data[key]);local value=transform(old)
 if self.repeatTransform then value=transform(S.copy(self.data[key])) end
 if value==nil then return nil end
 assert(S.serializable(value),"Invalid serialized record")
 self.data[key]=S.copy(value)
 if self.failAfter>0 then self.failAfter-=1;error("Simulated ambiguous commit") end
 return S.copy(value)
end
function Store:read(key)
 if self.failBefore>0 then self.failBefore-=1;error("Simulated read unavailable") end
 return S.copy(self.data[key])
end
return Store
