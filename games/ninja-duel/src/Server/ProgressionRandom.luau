-- Deterministic simulation generator; not a commercial/randomness service.
local R={};R.__index=R
function R.new(seed)
 assert(type(seed)=="number" and seed%1==0 and seed>0 and seed<2147483647,"Seed out of range")
 return setmetatable({state=seed},R)
end
function R:next() self.state=(self.state*16807)%2147483647;return self.state/2147483647 end
return R
