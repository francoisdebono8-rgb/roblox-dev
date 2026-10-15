"""Fault injection against the production MarketEngine, including persistent reloads."""
from pathlib import Path
import os, subprocess
root=Path(__file__).resolve().parent.parent
source=(root/'src/Server/MarketEngine.luau').read_text()
for name in ('Config','Economy','Actions','Collection'):
 source=source.replace(f'require(Shared.{name})',f"require('../src/Shared/{name}')")
source=source.replace('local Shared=game.ReplicatedStorage.WFT','')
harness='''
local P=require('../src/Shared/Profile')
local C=require('../src/Shared/Config')
local function clone(v) if type(v)~='table' then return v end local t={} for k,x in pairs(v) do t[k]=clone(x) end return t end
local Engine=(function()
'''+source+'''
end)()
local records,profiles,sessions={}, {}, {}; local seq=0; local now=1000
local failSaveAt,saveCalls,failStore,failAfterCommit=nil,0,false,false
local store={update=function(id,callback)
 if failStore then return false end
 local v=callback(clone(records[id])); if v then records[id]=clone(v) end
 if failAfterCommit and v and v.State=='Sold' then failAfterCommit=false; return false end
 return clone(v)
end}
local function save(player)
 saveCalls+=1
 if saveCalls==failSaveAt then return false end
 profiles[player.UserId]=clone(sessions[player].Data); return true
end
local function guid() seq+=1; return 'id-'..seq end
local market=Engine.new(store,save,guid,function() return now end)
local function player(id)
 local p={UserId=id,Name='Player'..id}; sessions[p]={Data=P.new(now),PaidTradingAllowed=true}; return p,sessions[p]
end
local function freshSeller(id)
 local p,s=player(id); s.Data.Inventory={{Id='weapon-'..id,Blueprint=3,Rarity=4,Mutation=2,Material=2,Locked=false,Displayed=false}}; return p,s
end
local function buyer(id,coins)
 local p,s=player(id); s.Data.Coins=coins or 1000; s.Data.MarketFunds=s.Data.Coins; return p,s
end
local function list(p,s,price)
 local w=s.Data.Inventory[1]; assert(market.list(p,s,w.Id,price or 100)); local id=next(s.Data.Listings); assert(id); return id,w.Id
end
local function reload(p,s)
 s.Data=P.load(clone(profiles[p.UserId]),now); s.MarketBusy=false
end
local seller,ss=freshSeller(1); local id,wid=list(seller,ss,101)
assert(#ss.Data.Inventory==0 and profiles[1].Listings[id])
assert(not market.buy(seller,ss,id),'self-purchase')
local full,fs=buyer(2); for i=1,30 do fs.Data.Inventory[i]={Id='full'..i,Blueprint=1,Rarity=1,Mutation=1} end
assert(not market.buy(full,fs,id)); assert(fs.Data.Coins==1000)
local poor,ps=buyer(3,100); assert(not market.buy(poor,ps,id)); assert(ps.Data.Coins==100)
local paid,paidS=buyer(4); paidS.Data.MarketFunds=0; assert(not market.buy(paid,paidS,id),'Robux coin pack paid seller')
local one,bs=buyer(5); local two,ts=buyer(6)
assert(market.buy(one,bs,id)); assert(bs.Data.Coins==899 and #bs.Data.Inventory==1 and bs.Data.Inventory[1].Id==wid)
assert(not market.buy(two,ts,id)); assert(ts.Data.Coins==1000 and #ts.Data.Inventory==0)
-- Offline seller is absent from online sessions; escrow journal persists independently.
local copy=ss; sessions[seller]=nil
sessions[seller]=copy; reload(seller,ss); assert(market.recover(seller,ss))
assert(ss.Data.Coins==92 and ss.Data.Stats.MarketSales==92 and ss.Data.MarketResults.Count==1)
assert(next(ss.Data.Listings)==nil); assert(market.recover(seller,ss)); assert(ss.Data.Coins==92)
reload(one,bs); assert(#bs.Data.Inventory==1 and bs.Data.Coins==899)
print('PASS market: escrow, self-buy, full inventory, insufficient earned funds, exact tax, transfer, double buyer, offline seller, durable payout')
for _,field in ipairs({'Locked','Displayed','Equipped'}) do
 local p,s=freshSeller(20+seq); if field=='Equipped' then s.Data.Equipped=s.Data.Inventory[1].Id else s.Data.Inventory[1][field]=true end
 assert(not market.list(p,s,s.Data.Inventory[1].Id,100)); assert(#s.Data.Inventory==1)
end
local p,s=freshSeller(30); for _,price in ipairs({0,-1,0/0,math.huge,1.5,C.MarketMaxPrice+1}) do assert(not market.list(p,s,s.Data.Inventory[1].Id,price)) end
s.Data.Inventory[1].Paid=true; s.PaidTradingAllowed=false; assert(not market.list(p,s,s.Data.Inventory[1].Id,100))
print('PASS market: equipped/displayed/locked, invalid prices, paid item policy')
local p,s=freshSeller(40); local cancel=list(p,s); assert(market.cancel(p,s,cancel)); assert(#s.Data.Inventory==1); assert(not market.buy(two,ts,cancel)); assert(market.recover(p,s)); assert(#s.Data.Inventory==1)
local p2,s2=freshSeller(41); local expired=list(p2,s2); now+=C.MarketExpiry+1; assert(not market.buy(two,ts,expired)); assert(market.recover(p2,s2)); assert(#s2.Data.Inventory==1)
print('PASS market: cancellation, stale/deleted offers, expiration, no repeated return')
-- Fail every profile-save boundary in a purchase; reconnect from durable snapshots.
for boundary=1,4 do
 local p,s=freshSeller(100+boundary); local offer=list(p,s)
 local b,session=buyer(200+boundary); save(b)
 saveCalls=0; failSaveAt=boundary
 market.buy(b,session,offer)
 failSaveAt=nil
 -- Simulate buyer disconnect and a new server process (empty discovery cache).
 reload(b,session)
 market=Engine.new(store,save,guid,function() return now end)
 assert(market.recover(b,session)); assert(market.recover(p,s))
 local sold=records[offer].State=='Sold'
 assert(session.Data.Coins==(sold and 900 or 1000))
 assert(#session.Data.Inventory==(sold and 1 or 0))
 assert(s.Data.Coins==(sold and 92 or 0)); assert(session.Data.Coins>=0)
 assert(market.recover(b,session)); assert(market.recover(p,s))
 assert(#session.Data.Inventory==(sold and 1 or 0))
end
print('PASS market: buyer disconnect/reload at every debit/commit/delivery save boundary, idempotent recovery')
local p,s=freshSeller(300); local offer=list(p,s); local b,session=buyer(301); save(b)
failAfterCommit=true; assert(not market.buy(b,session,offer)); assert(session.MarketBusy)
reload(b,session); assert(market.recover(b,session)); assert(#session.Data.Inventory==1 and session.Data.Coins==900)
assert(market.recover(p,s)); assert(s.Data.Coins==92)
print('PASS market: lost commit response recovers sale instead of refunding a committed purchase')
-- Stale discovery on another buyer cannot decide a second sale.
local p,s=freshSeller(400); local offer=list(p,s); local stale=clone(market.Offers[offer])
local b,session=buyer(401); assert(market.buy(b,session,offer)); market.Offers[offer]=stale
local b2,session2=buyer(402); assert(not market.buy(b2,session2,offer)); assert(session2.Data.Coins==1000 and #session2.Data.Inventory==0)
print('PASS market: concurrent stale offer loses conditional commit and receives exact refund')
local p,s=freshSeller(500); local weapon=s.Data.Inventory[1]; failStore=true; assert(not market.list(p,s,weapon.Id,100)); assert(s.MarketBusy and #s.Data.Inventory==0)
failStore=false; reload(p,s); assert(market.recover(p,s)); local offer=next(s.Data.Listings); assert(market.Offers[offer])
print('PASS market: interrupted publication restores escrow without duplicate inventory item')
'''
p=root/'tests/.market.generated.luau'
try:
 p.write_text(harness)
 subprocess.run([os.environ.get('LUAU','luau'),str(p)],check=True)
finally: p.unlink(missing_ok=True)

# The Roblox adapter must not touch DataStoreService in an unpublished local QA place.
adapter=(root/'src/Server/MarketService.luau').read_text().replace('local Engine=require(script.Parent.MarketEngine)',"local Engine={new=function() return {Ready=true} end}")
adapter_harness='''
local game={PlaceId=0,GetService=function(_,key)
 if key=='DataStoreService' then return {GetDataStore=function() error('unpublished place must not access DataStore') end} end
 return {}
end}
local workspace={GetAttribute=function() return true end}
local Service=(function()
'''+adapter+'''
end)()
local instance=Service.new({save=function() return true end})
assert(instance.Ready and Service.new({})==instance)
print('PASS market Roblox adapter: unpublished Studio starts without a DataStore request; native QA shares the runtime instance')
'''
p=root/'tests/.market-adapter.generated.luau'
try:
 p.write_text(adapter_harness)
 subprocess.run([os.environ.get('LUAU','luau'),str(p)],check=True)
finally: p.unlink(missing_ok=True)
