-- Recoverable local-market settlement. Store.update must be atomic per listing key.
-- No cross-profile atomicity is assumed: durable reservation precedes commit.
local Shared=game.ReplicatedStorage.WFT
local C=require(Shared.Config)
local E=require(Shared.Economy)
local A=require(Shared.Actions)
local B=require(Shared.Collection)
local Engine={}
function Engine.new(store,save,guid,clock)
 local self={Offers={},Locks={}}
 local function history(d,kind,record,net)
  d.MarketHistory=d.MarketHistory or {}
  table.insert(d.MarketHistory,1,{Kind=kind,Name=C.Weapons[record.Weapon.Blueprint].Name,Price=record.Price,Net=net or 0,At=record.SoldAt or clock()})
  while #d.MarketHistory>20 do table.remove(d.MarketHistory) end
 end
 local function persist(player,s)
  if not save(player) then s.MarketBusy=true; return false end
  return true
 end
 local function read(id) return store.update(id,function(old) return old end) end
 function self.recover(player,s)
  s.MarketBusy=true
  local d=s.Data
  -- Always persist current reservation/finalization before making another decision.
  if not persist(player,s) then return false end
  local pending=d.PendingMarket
  if pending then
   local record=store.update(pending.Listing,function(old)
    if not old then return nil end
    if old.State=='Open' and old.Expires>clock() and old.Price==pending.Price and old.Seller~=player.UserId then
     old.State='Sold'; old.Buyer=player.UserId; old.Transaction=pending.Transaction; old.SoldAt=clock()
    end
    return old
   end)
   if record==false then return false end
   if record and record.State=='Sold' and record.Buyer==player.UserId and record.Transaction==pending.Transaction then
    local weapon=table.clone(record.Weapon); weapon.Displayed=false; weapon.Locked=false
    -- Pending reservation owns exactly one delivery; it is cleared in the same profile write.
    if not A.find(d,weapon.Id) then table.insert(d.Inventory,weapon); B.mark(d,weapon,E.value(d,weapon)); history(d,'Bought',record) end
    d.Stats.BestValue=math.max(d.Stats.BestValue,E.value(d,weapon))
    d.Flags=d.Flags or {}; d.Flags.MarketPurchase=true
   else
    d.Coins+=pending.Price; d.MarketFunds+=pending.Price -- refund the exact reserved amount, never a client amount
   end
   d.PendingMarket=nil; self.Offers[pending.Listing]=nil
   if not persist(player,s) then return false end
  end
  local changed=false
  for id,escrow in pairs(d.Listings) do
   local record=store.update(id,function(old) return old or escrow end)
   if record==false then return false end
   if record.State=='Open' and (record.Expires<=clock() or record.Weapon.Paid and not s.PaidTradingAllowed) then
    record=store.update(id,function(old) if old and old.State=='Open' then old.State='Cancelled' end; return old end)
    if record==false then return false end
   end
   if record.State=='Sold' then
    local net=record.Price-math.ceil(record.Price*C.MarketTax)
    d.MarketWallet=(d.MarketWallet or 0)+net
    d.Stats.MarketSales+=net; d.Stats.MarketCount+=1
    history(d,'Sold',record,net)
    d.MarketResults.Count+=1; d.MarketResults.Coins+=net
    d.Listings[id]=nil; self.Offers[id]=nil; changed=true
   elseif record.State=='Cancelled' then
    self.Offers[id]=nil
    if #d.Inventory<E.capacity(d) then table.insert(d.Inventory,table.clone(escrow.Weapon)); d.Listings[id]=nil; changed=true end
   else self.Offers[id]=record end
  end
  local credit=math.min(d.MarketWallet or 0,C.MaxCoins-d.Coins)
  if credit>0 then A.credit(d,credit); d.MarketWallet-=credit; changed=true end
  if changed and not persist(player,s) then return false end
  s.MarketBusy=false; return true
 end
 function self.list(player,s,weaponId,price)
  if s.MarketBusy or s.Busy or s.Closing then return false,'Saving a market operation. Try again shortly.' end
  if type(price)~='number' or price~=price or price~=math.floor(price) or price<1 or price>C.MarketMaxPrice then return false,'Enter a whole Coins price from 1 to 100,000,000.' end
  local d=s.Data; local w,index=A.find(d,weaponId)
  if not w or w.Locked or w.Displayed or w.Id==d.Equipped then return false,'Unequip, store and unlock this weapon first.' end
  if w.Paid and not s.PaidTradingAllowed then return false,'Paid item trading is unavailable for this account.' end
  local count=0; for _ in pairs(d.Listings) do count+=1 end
  if count>=3+(d.Owned.MarketListings and 2 or 0) then return false,'All listing slots are occupied.' end
  local id=guid(); local record={Id=id,Seller=player.UserId,SellerName=player.Name,Price=price,BaseValue=E.value(d,w),Weapon=table.clone(w),Created=clock(),Expires=clock()+C.MarketExpiry,State='Open'}
  table.remove(d.Inventory,index); d.Listings[id]=record; s.MarketBusy=true
  if not persist(player,s) then return false,'Saving your offer. It will appear after recovery.' end
  if not self.recover(player,s) then return false,'Offer secured; market is reconnecting.' end
  return true,'Listed for '..price..' Coins. Net '..(price-math.ceil(price*C.MarketTax))..'.'
 end
 function self.buy(player,s,id)
  if s.MarketBusy or s.Busy or s.Closing then return false,'A save is already in progress.' end
  local record=self.Offers[id]
  if not record or record.State~='Open' or record.Expires<=clock() then return false,'This offer is no longer available.' end
  if record.Seller==player.UserId then return false,'You cannot buy your own weapon.' end
  if record.Weapon.Paid and not s.PaidTradingAllowed then return false,'Paid item trading is unavailable for this account.' end
  if #s.Data.Inventory>=E.capacity(s.Data) then return false,'Make room in your inventory first.' end
  if math.min(s.Data.Coins,s.Data.MarketFunds or 0)<record.Price then return false,'You need more earned Coins. Coin packs cannot pay other players.' end
  s.MarketBusy=true
  s.Data.PendingMarket={Listing=id,Price=record.Price,Transaction=guid()}
  s.Data.Coins-=record.Price; s.Data.MarketFunds-=record.Price
  if not persist(player,s) then return false,'Coins reserved. Reconnecting to finish your purchase.' end
  if not self.recover(player,s) then return false,'Purchase secured. Delivery is recovering.' end
  if A.find(s.Data,record.Weapon.Id) then return true,'Purchased! Your weapon is in Inventory.' end
  return false,'Another player bought this weapon. Your reserved Coins were returned.'
 end
 function self.cancel(player,s,id)
  if s.MarketBusy or s.Busy or s.Closing or not s.Data.Listings[id] then return false,'Offer is unavailable.' end
  s.MarketBusy=true
  local record=store.update(id,function(old)
   if old and old.Seller==player.UserId and old.State=='Open' then old.State='Cancelled' end
   return old
  end)
  if record==false then return false,'Cancellation is reconnecting. Please wait.' end
  self.Offers[id]=nil
  if not self.recover(player,s) then return false,'Recovering the cancelled weapon.' end
  return true,record and record.State=='Sold' and 'Already sold; proceeds collected.' or 'Cancelled. A full inventory keeps the weapon safely in escrow.'
 end
 function self.snapshot()
  local offers={}
  for id,record in pairs(self.Offers) do if record.State=='Open' and record.Expires>clock() then table.insert(offers,record) else self.Offers[id]=nil end end
  return offers
 end
 return self
end
return Engine
