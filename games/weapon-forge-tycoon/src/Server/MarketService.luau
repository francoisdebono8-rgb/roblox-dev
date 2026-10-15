local DSS=game:GetService('DataStoreService')
local Http=game:GetService('HttpService')
local Engine=require(script.Parent.MarketEngine)
local Service={}
function Service.new(Data)
 if Service.Instance then return Service.Instance end
 local memory={}; local persistent
 local store={}
 function store.update(id,transform)
  if workspace:GetAttribute('WFT_LocalQA') or game.PlaceId==0 then
   local old=memory[id] and Http:JSONDecode(Http:JSONEncode(memory[id]))
   local result=transform(old); memory[id]=result; return result
  end
  local ok,result=pcall(function()
   persistent=persistent or DSS:GetDataStore('WeaponForgeMarket_v1')
   return persistent:UpdateAsync('l_'..id,transform) end)
  if not ok then warn('WFT market storage unavailable; settlement paused'); return false end
  return result
 end
 Service.Instance=Engine.new(store,function(player) return Data.save(player,false) end,function() return Http:GenerateGUID(false) end,os.time)
 return Service.Instance
end
return Service
