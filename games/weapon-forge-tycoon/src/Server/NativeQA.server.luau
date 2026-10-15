-- Included only in the QA artifact. Does not modify any player profile.
task.wait(3)
assert(game:GetService('RunService'):IsStudio(),'QA scripts must never ship')
local root=workspace:WaitForChild('ForgeAndFlex',10); assert(root)
for i=1,6 do
 local plot=root:FindFirstChild('Workshop '..i); assert(plot and plot:FindFirstChild('Anvil') and plot:FindFirstChild('Furnace'))
 assert(plot:FindFirstChild('Zone gate 2') and plot:FindFirstChild('Zone gate 3'))
end
local S=game.ReplicatedStorage.WFT
local W=require(S.WeaponModel)
local Profile=require(S.Profile)
local Http=game:GetService('HttpService')
local p=Profile.new(os.time()); p.Coins=100; p.Inventory={{Id='native',Blueprint=9,Rarity=6,Mutation=5,Locked=true,Displayed=false}}
local loaded=Profile.load(Http:JSONDecode(Http:JSONEncode(p)),os.time())
assert(loaded.Coins==100 and loaded.Inventory[1].Locked and loaded.Inventory[1].Mutation==5)
local scratch=Instance.new('Folder')
for i=1,9 do
 local m=W.build({Blueprint=i,Rarity=6,Mutation=5},scratch,CFrame.new(),1)
 assert(#m:GetChildren()>=4)
 for _,v in ipairs(m:GetChildren()) do if v:IsA('BasePart') then assert(v.Anchored and not v.CanCollide) end end
end
scratch:Destroy()
for _,player in ipairs(game:GetService('Players'):GetPlayers()) do
 local index=player:GetAttribute('Plot'); local plot=index and root:FindFirstChild('Workshop '..index)
 if plot and player.Character then assert((player.Character:GetPivot().Position-plot:FindFirstChild('Workshop spawn').Position).Magnitude<18,'Player spawned away from assigned forge') end
end
print('WFT_NATIVE_QA PASS: 6 plots, 9 weapon models, safe parts, native JSON save/load')

-- Explicit Studio-only scenario fixtures; excluded from the release by the builder.
local Data=require(script.Parent.DataService)
local A=require(game.ReplicatedStorage.WFT.Actions)
local B=require(game.ReplicatedStorage.WFT.Collection)
local QA=Instance.new('BindableEvent'); QA.Name='WFTQACommand'; QA.Parent=game.ServerScriptService
QA.Event:Connect(function(command,target)
 assert(game:GetService('RunService'):IsStudio() and workspace:GetAttribute('WFT_LocalQA'))
 if command=='MarketTest' then
  local players=game:GetService('Players'):GetPlayers(); assert(#players>=2,'Two native clients required')
  local seller,buyer=players[1],players[2]; local ss,bs=Data.Sessions[seller],Data.Sessions[buyer]
  assert(ss.Memory and bs.Memory)
  while ss.Busy or bs.Busy or ss.MarketWorking or bs.MarketWorking do task.wait(.1) end
  local Market=require(script.Parent.MarketService).new(Data)
  local w={Id=Http:GenerateGUID(false),Blueprint=3,Rarity=4,Mutation=2,Material=2,Blade=3,Guard=2,Handle=2,Locked=false,Displayed=false}
  table.insert(ss.Data.Inventory,w); A.credit(bs.Data,1000)
  local beforeBuyer,beforeSeller=bs.Data.Coins,ss.Data.Coins
  assert(Market.list(seller,ss,w.Id,101))
  local id; for key,l in pairs(ss.Data.Listings) do if l.Weapon.Id==w.Id then id=key end end; assert(id)
  assert(not Market.buy(seller,ss,id)); assert(Market.buy(buyer,bs,id)); assert(not Market.buy(buyer,bs,id))
  assert(Market.recover(seller,ss)); assert(A.find(bs.Data,w.Id) and not A.find(ss.Data,w.Id))
  assert(bs.Data.Coins==beforeBuyer-101 and ss.Data.Coins==beforeSeller+92)
  assert(Market.recover(seller,ss)); assert(ss.Data.Coins==beforeSeller+92)
  print('WFT_NATIVE_MARKET PASS: two real Players, escrow, atomic sale decision, transfer, 8% tax, exact payout, double-buy rejection')
  return
 end
 for player,session in pairs(Data.Sessions) do
  if target and player.Name~=target then continue end
  assert(session.Memory and not session.Busy and not session.Closing,'Fixtures require an idle memory-only session')
  local d=session.Data
  if command=='Inventory' then
   d.Inventory={}; d.Tutorial=5; A.credit(d,10000); d.Equipped=nil; d.Materials={Iron=12,Steel=12,Obsidian=12,Emberstone=12,['Arcane Crystal']=12}
   for i=1,12 do
    local w={Id='qa-'..player.UserId..'-'..i,Blueprint=(i-1)%9+1,Rarity=i<=3 and 1 or math.min(6,i-2),Mutation=i==8 and 5 or i==6 and 2 or 1,Material=i>=7 and 5 or i>=4 and 3 or 1,Blade=(i-1)%3+1,Guard=(i+1)%3+1,Handle=i%3+1,Locked=false,Displayed=i==8,Secret=i==9,Perfect=i==7}
    table.insert(d.Inventory,w); B.mark(d,w)
   end
  elseif command=='Rustic' or command=='Magma' or command=='Arcane' then
   d.Craft=nil; d.Coins=50000; d.Settings.AutoForge=false
   local target=command=='Rustic' and 1 or command=='Magma' and 2 or 3
   d.Zone=1; while d.Zone<target do assert(A.zone(d)) end
   d.Material=target==1 and 1 or target==2 and 4 or 5; d.Tutorial=5
  elseif command=='Speed5' then d.Upgrades.Speed=5
  elseif command=='Speed10' then d.Upgrades.Speed=10; d.Upgrades.Luck=6
  elseif command=='Common' or command=='Rare' or command=='Mythic' then
   local r=command=='Common' and 1 or command=='Rare' and 3 or 6
   local w={Id='qa-reveal-'..command,Blueprint=r==6 and 9 or r==3 and 3 or 2,Rarity=r,Mutation=r==6 and 5 or r==3 and 2 or 1,Material=r==6 and 5 or 1,Blade=3,Guard=3,Handle=3,Locked=false,Displayed=false,Secret=false,Perfect=false}
   if not A.find(d,w.Id) then table.insert(d.Inventory,w); B.mark(d,w) end
   task.delay(2.2,function() game.ReplicatedStorage.WFT.State:FireClient(player,nil,'reveal',w) end)
  elseif command=='TravelMine' then player.Character:PivotTo(CFrame.new(-81,4,-112))
  elseif command=='TravelMarket' then player.Character:PivotTo(CFrame.new(0,4,17))
  elseif command=='TravelForge' then local plot=root:FindFirstChild('Workshop '..player:GetAttribute('Plot')); player.Character:PivotTo(plot:FindFirstChild('Workshop spawn').CFrame+Vector3.new(0,4,0))
  elseif command=='VisitOwner' then
   for other in pairs(Data.Sessions) do if other~=player then local plot=root:FindFirstChild('Workshop '..other:GetAttribute('Plot')); player.Character:PivotTo(plot:FindFirstChild('Sell counter').CFrame+Vector3.new(0,3,5)); break end end
  elseif command=='Reset' then
   local fresh=require(game.ReplicatedStorage.WFT.Profile).new(os.time()); session.Data=fresh
  else error('Unknown QA fixture') end
  print('WFT_V02_FIXTURE '..command..' '..player.Name)
 end
end)

-- Optional native automation uses the same runtime sessions and MarketService instance.
local testService=game:GetService('StudioTestService')
if testService:GetTestArgs()=='WFTMarketSmoke' then
 task.spawn(function()
  local deadline=os.clock()+30
  while #game:GetService('Players'):GetPlayers()<2 and os.clock()<deadline do task.wait(.5) end
  task.wait(3)
  QA:Fire('MarketTest')
 end)
end
