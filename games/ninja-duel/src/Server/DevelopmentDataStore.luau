-- Optional REAL adapter, restricted to Studio + fixed development namespace.
-- Creation itself is gated; default tools use memory and never touch this adapter.
local Adapter={};Adapter.__index=Adapter
function Adapter.new(cfg)
 if not game:GetService("RunService"):IsStudio() or cfg.DevDataStoreEnabled~=true then return nil,"Development DataStore disabled" end
 if cfg.StoreName~="NinjaDuel_DEV_Progression" or cfg.StoreScope~="development_v1" then return nil,"Development namespace required" end
 local store=game:GetService("DataStoreService"):GetDataStore(cfg.StoreName,cfg.StoreScope)
 return setmetatable({store=store},Adapter)
end
local function keyValid(key) return type(key)=="string" and #key<=50 and key:match("^p_dev_[%w_%-]+$")~=nil end
function Adapter:update(key,transform)
 assert(keyValid(key),"Development key required")
 return self.store:UpdateAsync(key,transform)
end
function Adapter:read(key)
 assert(keyValid(key),"Development key required")
 local options=Instance.new("DataStoreGetOptions");options.UseCache=false
 return self.store:GetAsync(key,options)
end
return Adapter
