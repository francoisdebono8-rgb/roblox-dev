local MPS=game:GetService('MarketplaceService')
local Players=game:GetService('Players')
local Shared=game.ReplicatedStorage.WFT
local C=require(Shared.Config)
local A=require(Shared.Actions)
local Analytics=require(script.Parent.Analytics)
local M={}
function M.init(Data,push)
 local pending={}
 MPS.ProcessReceipt=function(receipt)
  local player=Players:GetPlayerByUserId(receipt.PlayerId)
  local s=player and Data.Sessions[player]
  if not s or s.Busy or s.Closing or s.Memory or pending[player] then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local key
  for k,p in pairs(C.Monetization) do if p.Kind=='Product' and p.Id and p.Id==receipt.ProductId then key=k end end
  if not key then return Enum.ProductPurchaseDecision.NotProcessedYet end
  pending[player]=true
  local first=not s.Data.Receipts[receipt.PurchaseId]
  A.receipt(s.Data,receipt.PurchaseId,key)
  -- Grant and receipt marker share one durable profile transaction. Never ACK before save.
  local saved=Data.save(player,false)
  pending[player]=nil
  if not saved then return Enum.ProductPurchaseDecision.NotProcessedYet end
  if first then Analytics.event(player,'purchase_success') end
  push(player,'purchase')
  return Enum.ProductPurchaseDecision.PurchaseGranted
 end
 MPS.PromptGamePassPurchaseFinished:Connect(function(player,id,bought)
  if bought then M.refresh(player,Data,push) end
 end)
end
function M.refresh(player,Data,push)
 for key,p in pairs(C.Monetization) do
  if p.Kind=='Pass' and p.Id and p.Id>0 then
   local ok,owned=pcall(MPS.UserOwnsGamePassAsync,MPS,player.UserId,p.Id)
   local s=Data.Sessions[player]
   if ok and owned and s and not s.Closing then
    while s.Busy do task.wait(0.1) end
    A.pass(s.Data,key,os.time()); push(player,'pass')
   end
  end
 end
end
return M
