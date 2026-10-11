-- Read the actual shared definitions. No duel is started, no data is mutated.
local H=require("../tests/Harness")
local serde=require("@lune/serde")
local function plain(v)
 if typeof(v)=="Vector3" then return {x=v.X,y=v.Y,z=v.Z} end
 if type(v)=="table" then local out={};for k,item in v do out[k]=plain(item) end;return out end
 if type(v)=="function" then return nil end
 return v
end
print(serde.encode("json",plain({fighters=H.fighters,attacks=H.Attacks,graphs=H.load("Shared/MoveGraphs")})))
