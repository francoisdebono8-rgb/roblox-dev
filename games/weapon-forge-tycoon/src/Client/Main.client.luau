local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local GuiService=game:GetService('GuiService')
local Tween=game:GetService('TweenService')
local Marketplace=game:GetService('MarketplaceService')
local PPS=game:GetService('ProximityPromptService')
local Run=game:GetService('RunService')
local B=require(game.ReplicatedStorage:WaitForChild('WFT').Collection)
local CAS=game:GetService('ContextActionService')
local player=Players.LocalPlayer
local Shared=game.ReplicatedStorage:WaitForChild('WFT')
local C=require(Shared.Config)
local E=require(Shared.Economy)
local W=require(Shared.WeaponModel)
local O=require(Shared.Odds)
local Effects=require(script.Parent.Effects)
local ForgeVisual=require(script.Parent.ForgeVisual)
local request=Shared:WaitForChild('Request')
local state=Shared:WaitForChild('State')
local data,page,selected,token,mergeItems,mergeRarity,prestigeToken
local reveal,forgeRunning,forgeGeneration=nil,false,0
local prices,shopTab={},'PERMANENT'
local warm=Color3.fromRGB(255,165,48)
local green=Color3.fromRGB(65,208,113)
local blue=Color3.fromRGB(63,154,244)
local purple=Color3.fromRGB(169,102,246)
local red=Color3.fromRGB(239,76,91)
local spins={}
local clockOffset=0
local revealGeneration=0
local started=os.clock()
local suggestionShown=false
local ink=Color3.fromRGB(26,28,48)
local text=Color3.fromRGB(255,249,230)
local muted=Color3.fromRGB(181,173,161)
local gui=Instance.new('ScreenGui'); gui.Name='ForgeAndFlex'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.IgnoreGuiInset=false; gui.Parent=player:WaitForChild('PlayerGui')
local function make(cls,parent,props)
 local obj=Instance.new(cls); for k,v in pairs(props or {}) do obj[k]=v end; obj.Parent=parent; return obj
end
local function corner(obj,r) make('UICorner',obj,{CornerRadius=UDim.new(0,r or 10)}) end
local function label(parent,copy,size,color)
 return make('TextLabel',parent,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,size+12),Font=Enum.Font.GothamBold,Text=copy,TextSize=size,TextColor3=color or text,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local function button(parent,copy,callback,primary)
 local b=make('TextButton',parent,{Size=UDim2.new(1,0,0,52),BackgroundColor3=primary and warm or Color3.fromRGB(61,76,117),AutoButtonColor=false,Text=copy,Font=Enum.Font.GothamBold,TextSize=17,TextColor3=text,Selectable=true})
 corner(b,12)
 make('UIStroke',b,{Color=Color3.fromRGB(14,18,34),Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
 make('UIGradient',b,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(157,157,173)),Rotation=90})
 b.TextStrokeTransparency=.5; b.TextStrokeColor3=Color3.fromRGB(33,24,27)
 b.Activated:Connect(function() Effects.sound('button_click'); callback() end)
 b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.16),{BackgroundColor3=primary and Color3.fromRGB(255,196,117) or Color3.fromRGB(72,64,55)}):Play() end)
 b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.16),{BackgroundColor3=primary and warm or Color3.fromRGB(61,76,117)}):Play() end)
 return b
end
local function send(action,arg) request:FireServer(action,arg) end
local hud=make('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local coinBox=make('Frame',hud,{Size=UDim2.fromOffset(164,48),Position=UDim2.fromOffset(10,8),BackgroundColor3=ink}); corner(coinBox,15)
make('UIStroke',coinBox,{Color=warm,Thickness=3})
local money=label(coinBox,'◉ 0',20,warm); money.Size=UDim2.new(1,0,0,26); money.TextXAlignment=Enum.TextXAlignment.Center
local materialHud=label(coinBox,'IRON 4',11); materialHud.Position=UDim2.fromOffset(4,26); materialHud.Size=UDim2.new(1,-8,0,18); materialHud.TextXAlignment=Enum.TextXAlignment.Center
local goalBox=make('Frame',hud,{Size=UDim2.new(.43,0,0,58),Position=UDim2.new(.49,0,0,6),AnchorPoint=Vector2.new(.5,0),BackgroundColor3=ink,BackgroundTransparency=.08}); corner(goalBox,12)
local progress=label(goalBox,'LIGHT YOUR FIRST FORGE',14); progress.Size=UDim2.new(1,-16,0,36); progress.Position=UDim2.fromOffset(8,0); progress.TextXAlignment=Enum.TextXAlignment.Center
local goalTrack=make('Frame',goalBox,{Size=UDim2.new(1,-16,0,10),Position=UDim2.fromOffset(8,42),BackgroundColor3=Color3.fromRGB(12,17,31),BorderSizePixel=0}); corner(goalTrack,5)
local goalFill=make('Frame',goalTrack,{Size=UDim2.fromScale(0,1),BackgroundColor3=warm,BorderSizePixel=0}); corner(goalFill,5)
local tutorial=make('TextButton',gui,{Position=UDim2.new(.5,0,0,74),AnchorPoint=Vector2.new(.5,0),Size=UDim2.new(.65,0,0,40),BackgroundTransparency=1,TextColor3=text,TextSize=17,Font=Enum.Font.GothamBlack,TextWrapped=true,Text='▼ FORGE YOUR FIRST WEAPON',TextStrokeTransparency=.2,AutoButtonColor=false})
local toast=label(gui,'',15,warm); toast.Size=UDim2.new(.9,0,0,48); toast.Position=UDim2.new(.5,0,0,110); toast.AnchorPoint=Vector2.new(.5,0); toast.TextXAlignment=Enum.TextXAlignment.Center; toast.TextStrokeTransparency=.3
local toastVersion=0
local function notify(copy)
 toastVersion+=1; local v=toastVersion; toast.Text=tostring(copy or '')
 task.delay(4,function() if toastVersion==v then toast.Text='' end end)
end
local render,show
local forgeButton=button(gui,'⚒  FORGE A WEAPON',function() if forgeRunning then send('Hammer') elseif data then show('Forge') end end,true)
forgeButton.Size=UDim2.new(.6,0,0,56); forgeButton.Visible=false; forgeButton.Position=UDim2.new(.5,0,1,-78); forgeButton.AnchorPoint=Vector2.new(.5,1)
make('UISizeConstraint',forgeButton,{MaxSize=Vector2.new(420,52)})
local forgeBar=make('Frame',forgeButton,{Size=UDim2.new(0,0,0,4),Position=UDim2.new(0,0,1,-4),BackgroundColor3=Color3.fromRGB(255,237,190),BorderSizePixel=0})
corner(forgeBar,2)
local nav=make('Frame',gui,{Size=UDim2.new(.64,0,0,58),Position=UDim2.new(.5,0,1,-10),AnchorPoint=Vector2.new(.5,1),BackgroundTransparency=1})
make('UISizeConstraint',nav,{MinSize=Vector2.new(340,58),MaxSize=Vector2.new(600,58)})
make('UIListLayout',nav,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})
local panel=make('Frame',gui,{Size=UDim2.new(.9,0,.76,0),Position=UDim2.new(.5,0,.47,0),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=ink,Visible=false})
corner(panel,18); make('UIStroke',panel,{Color=Color3.fromRGB(102,137,211),Thickness=4})
make('UIGradient',panel,{Color=ColorSequence.new(Color3.fromRGB(71,78,119),Color3.fromRGB(20,23,42)),Rotation=80})
make('UISizeConstraint',panel,{MaxSize=Vector2.new(1000,720)})
local panelScale=make('UIScale',panel,{Scale=1})
local title=label(panel,'ARMORY',21,warm); title.Position=UDim2.fromOffset(16,10); title.Size=UDim2.new(1,-80,0,40)
local close=button(panel,'×',function() page=nil; panel.Visible=false; nav.Visible=true; forgeButton.Visible=forgeRunning end)
close.Size=UDim2.fromOffset(48,48); close.Position=UDim2.new(1,-54,0,6); close.BackgroundColor3=red
local scroller=make('ScrollingFrame',panel,{Position=UDim2.fromOffset(14,60),Size=UDim2.new(1,-28,1,-76),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=warm,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
local forgeAction=button(panel,'HEAT IRON • FREE',function() send('Forge') end,true); forgeAction.Size=UDim2.new(1,-28,0,52); forgeAction.Position=UDim2.new(0,14,1,-64); forgeAction.Visible=false
local mergeHeader=button(panel,'MERGE 3 → 1',function() send('MergePreview') end); mergeHeader.Position=UDim2.new(1,-230,0,6); mergeHeader.Size=UDim2.fromOffset(166,48); mergeHeader.BackgroundColor3=purple; mergeHeader.Visible=false; mergeHeader.TextSize=14
local marketDraftId,marketBuyId,inspection
local showReward
local function clear()
 forgeAction.Visible=false; mergeHeader.Visible=false; scroller.Size=UDim2.new(1,-28,1,-76)
 for _,child in ipairs(scroller:GetChildren()) do child:Destroy() end
 make('UIListLayout',scroller,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
 make('UIPadding',scroller,{PaddingBottom=UDim.new(0,16),PaddingRight=UDim.new(0,6)})
end
local function row(copy,size,color) return label(scroller,copy,size or 14,color) end
local function viewport(parent,w,height,silhouette)
 local frame=make('ViewportFrame',parent,{Size=UDim2.new(1,0,0,height),BackgroundTransparency=1,Ambient=Color3.fromRGB(180,171,161),LightColor=Color3.fromRGB(255,226,190),LightDirection=Vector3.new(-1,-1,-1)})
 local world=make('WorldModel',frame)
 local model=W.build(w,world,CFrame.Angles(0,math.rad(-15),math.rad(-18)),1,silhouette)
 local box,size=model:GetBoundingBox(); local center=box.Position
 local distance=math.max(size.Y,size.X)*1.55
 local camera=make('Camera',frame,{CFrame=CFrame.lookAt(center+Vector3.new(.2,.12,distance),center),FieldOfView=35}); frame.CurrentCamera=camera
 table.insert(spins,{Frame=frame,Model=model,Base=model:GetPivot(),Angle=0})

 return frame
end
local function itemName(w) return C.Weapons[w.Blueprint].Name..' • '..C.Rarities[w.Rarity].Name..(w.Mutation>1 and ' / '..C.Mutations[w.Mutation].Name or '') end
local function get(id) for _,w in ipairs(data.Inventory) do if w.Id==id then return w end end end
show=function(nextPage)
 if UIS.TouchEnabled then panel.Size=UDim2.new(.98,0,1,-8); panel.Position=UDim2.fromScale(.5,.5); nav.Visible=false else panel.Size=UDim2.new(.9,0,.76,0); panel.Position=UDim2.fromScale(.5,.47) end
 page=nextPage; selected=nil; scroller.CanvasPosition=Vector2.new(0,0); panel.Visible=true; forgeButton.Visible=false; render()
 panelScale.Scale=.97; Tween:Create(panelScale,TweenInfo.new(.18,Enum.EasingStyle.Quad),{Scale=1}):Play()
 if UIS.GamepadEnabled then GuiService.SelectedObject=close end
end
local function rackPosition()
 local root=workspace:FindFirstChild('ForgeAndFlex'); local plot=root and root:FindFirstChild('Workshop '..tostring(player:GetAttribute('Plot')))
 return plot and plot:FindFirstChild('Anvil')
end
local function impact(big)
 local a=rackPosition(); if a then Effects.impact(a.Position+Vector3.new(0,1,0),warm,big) end
end
local function weaponActions(w)
 row(itemName(w),17,Color3.fromRGB(unpack(C.Rarities[w.Rarity].Color)))
 local compact=scroller.AbsoluteSize.Y<310
 viewport(scroller,w,compact and 130 or 210)
 row(tostring(E.value(data,w))..' coins  •  '..(w.Displayed and 'On display' or 'In inventory')..(w.Locked and '  •  Locked' or ''))
 local choices=make('Frame',scroller,{Size=UDim2.new(1,0,0,48),BackgroundTransparency=1})
 make('UIListLayout',choices,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)})
 local sell=button(choices,'SELL',function()
  if w.Locked or w.Displayed then notify('Store and unlock this weapon before selling.'); return end
  send('Sell',w.Id); selected=nil; reveal=nil; page='Inventory'
 end,true); sell.Size=UDim2.new(1/3,-4,0,46)
 local display=button(choices,w.Displayed and 'STORE' or 'DISPLAY',function() send('Display',w.Id); reveal=nil; page='Inventory' end); display.Size=UDim2.new(1/3,-4,0,46)
 local keep=button(choices,'KEEP',function() send('Keep',w.Id); reveal=nil; page=nil; panel.Visible=false; nav.Visible=true end); keep.Size=UDim2.new(1/3,-4,0,46)
 local stats=E.properties(w)
 row(string.format('MINING ×%.2f   •   FORGE LUCK +%.1f%%',stats.Mining,stats.Luck*100),16,green)
 button(scroller,data.Equipped==w.Id and 'UNEQUIP' or 'EQUIP • ONE MAIN WEAPON',function() send('Equip',w.Id) end)
 button(scroller,'LIST ON MARKET',function() marketDraftId=w.Id; show('MarketList') end,true)
 button(scroller,w.Locked and 'UNLOCK WEAPON' or 'LOCK — PROTECT FROM SELL / MERGE',function() send('Lock',w.Id) end)
 row(C.Materials[w.Material or 1].Name..' • '..C.Parts.Blade[w.Blade or 1]..' blade • '..C.Parts.Guard[w.Guard or 1]..' guard • '..C.Parts.Handle[w.Handle or 1]..' grip'..(w.Perfect and ' • Perfect +12%' or ''),13,muted)
end

local function rarityCard(parent,w,height,silhouette,callback)
 local color=Color3.fromRGB(unpack(C.Rarities[w.Rarity].Color))
 local card=make('Frame',parent,{BackgroundColor3=color:Lerp(ink,.65),Size=UDim2.new(1,0,0,height)}); corner(card,12)
 make('UIStroke',card,{Color=silhouette and Color3.fromRGB(75,86,120) or color,Thickness=3})
 make('UIGradient',card,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(87,90,129)),Rotation=90})
 local view=viewport(card,w,height-76,silhouette); view.Position=UDim2.fromOffset(0,16)
 local rarity=label(card,silhouette and 'UNDISCOVERED' or string.upper(C.Rarities[w.Rarity].Name),12,color); rarity.Size=UDim2.new(1,-12,0,20); rarity.Position=UDim2.fromOffset(6,0); rarity.TextXAlignment=Enum.TextXAlignment.Center
 local name=label(card,silhouette and '???' or C.Weapons[w.Blueprint].Name,14); name.Position=UDim2.new(0,6,1,-64); name.Size=UDim2.new(1,-12,0,24); name.TextXAlignment=Enum.TextXAlignment.Center
 local mutation=label(card,silhouette and C.Zones[C.Weapons[w.Blueprint].Zone].Name or (w.Secret and '✦ ECLIPSE SECRET' or w.Mutation>1 and C.Mutations[w.Mutation].Name or C.Materials[w.Material or 1].Name),12,w.Mutation>1 and Color3.fromRGB(unpack(C.Mutations[w.Mutation].Color)) or text); mutation.Position=UDim2.new(0,6,1,-42); mutation.Size=UDim2.new(1,-12,0,20); mutation.TextXAlignment=Enum.TextXAlignment.Center
 local price=label(card,silhouette and 'FIND AT THE FORGE' or ('◉ '..E.value(data,w)..(w.Locked and '  LOCKED' or w.Displayed and '  ON DISPLAY' or '')),13,warm); price.Position=UDim2.new(0,6,1,-22); price.Size=UDim2.new(1,-12,0,20); price.TextXAlignment=Enum.TextXAlignment.Center
 if callback then local hit=make('TextButton',card,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text='',Selectable=true}); hit.Activated:Connect(callback) end
 return card
end
local marketFilters={Rarity=0,Mutation=0,Material=0,Price=0,Sort=1,Owner=0}
local function market()
 row('PLAYER MARKET  •  THIS SERVER',20,warm)
 row('3 free offers • 8% tax • Earned Coins: '..math.floor(data.MarketFunds or 0)..(data.MarketBusy and ' • SETTLING…' or ''),13)
 local filters=make('Frame',scroller,{Size=UDim2.new(1,0,0,108),BackgroundTransparency=1})
 local items={
  {'Rarity',marketFilters.Rarity==0 and 'ALL RARITIES' or C.Rarities[marketFilters.Rarity].Name,6},
  {'Mutation',marketFilters.Mutation==0 and 'ALL MUTATIONS' or C.Mutations[marketFilters.Mutation].Name,5},
  {'Material',marketFilters.Material==0 and 'ALL METALS' or C.Materials[marketFilters.Material].Name,5},
  {'Price',marketFilters.Price==0 and 'ANY PRICE' or 'MAX '..({100,1000,10000,100000})[marketFilters.Price],4},
  {'Sort',({'CHEAPEST','RAREST','NEWEST'})[marketFilters.Sort],3},
  {'Owner',marketFilters.Owner==0 and 'ALL SELLERS' or 'OWNER ONLY',0},
 }
 for i,f in ipairs(items) do
  local b=button(filters,f[2],function()
   if f[1]=='Sort' then marketFilters.Sort=marketFilters.Sort%3+1 elseif f[1]=='Owner' then marketFilters.Owner=0 else marketFilters[f[1]]=(marketFilters[f[1]]+1)%(f[3]+1) end
   render()
  end); b.Size=UDim2.new(1/3,-6,0,48); b.Position=UDim2.new((i-1)%3/3,0,0,math.floor((i-1)/3)*56); b.TextSize=12
 end
 local mine={}; for id,l in pairs(data.Listings or {}) do table.insert(mine,l) end
 if #mine>0 then
  row('MY OFFERS  '..#mine..' / '..(data.Owned.MarketListings and 5 or 3),16)
  for _,l in ipairs(mine) do button(scroller,'CANCEL  '..C.Weapons[l.Weapon.Blueprint].Name..' • '..l.Price..' COINS',function() send('MarketCancel',l.Id) end) end
 end
 button(scroller,'SALES & PURCHASE HISTORY',function() show('MarketHistory') end)
 button(scroller,'+ LIST A WEAPON FROM INVENTORY',function() show('Inventory'); notify('Choose a stored weapon, then LIST ON MARKET.') end,true)
 local offers={}
 for _,l in ipairs(data.Market or {}) do
  local w=l.Weapon
  if (marketFilters.Rarity==0 or w.Rarity==marketFilters.Rarity) and (marketFilters.Mutation==0 or w.Mutation==marketFilters.Mutation) and (marketFilters.Material==0 or (w.Material or 1)==marketFilters.Material) and (marketFilters.Owner==0 or l.Seller==marketFilters.Owner) and (marketFilters.Price==0 or l.Price<=({100,1000,10000,100000})[marketFilters.Price]) then table.insert(offers,l) end
 end
 table.sort(offers,function(a,b)
  if marketFilters.Sort==2 and a.Weapon.Rarity~=b.Weapon.Rarity then return a.Weapon.Rarity>b.Weapon.Rarity end
  if marketFilters.Sort==3 and a.Created~=b.Created then return a.Created>b.Created end
  if a.Price==b.Price then return a.Id<b.Id end
  return a.Price<b.Price
 end)
 if #offers==0 then row('NO MATCHING OFFERS YET\nForge something worth showing, then set your price. Invite another player to browse your armory.',18) end
 local grid=make('Frame',scroller,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
 local cols=panel.AbsoluteSize.X<650 and 2 or 3
 make('UIGridLayout',grid,{CellSize=UDim2.new(1/cols,-10,0,322),CellPadding=UDim2.fromOffset(10,12)})
 for _,l in ipairs(offers) do
  local w=l.Weapon; local color=Color3.fromRGB(unpack(C.Rarities[w.Rarity].Color)); local stats=E.properties(w)
  local card=make('Frame',grid,{BackgroundColor3=color:Lerp(ink,.72)}); corner(card,14); make('UIStroke',card,{Color=color,Thickness=3})
  local name=label(card,C.Weapons[w.Blueprint].Name,16); name.Position=UDim2.fromOffset(8,4); name.Size=UDim2.new(1,-16,0,36); name.TextXAlignment=Enum.TextXAlignment.Center
  local view=viewport(card,w,116); view.Position=UDim2.fromOffset(0,40)
  local info=label(card,C.Rarities[w.Rarity].Name..' • '..C.Mutations[w.Mutation].Name..'\n'..C.Materials[w.Material or 1].Name,13,color); info.Position=UDim2.fromOffset(8,156); info.Size=UDim2.new(1,-16,0,36); info.TextXAlignment=Enum.TextXAlignment.Center
  local statsLabel=label(card,string.format('Mining ×%.2f • Luck +%.1f%%',stats.Mining,stats.Luck*100),12); statsLabel.Position=UDim2.fromOffset(8,194); statsLabel.Size=UDim2.new(1,-16,0,24); statsLabel.TextXAlignment=Enum.TextXAlignment.Center
  local owner=label(card,'@'..l.SellerName..' • BASE '..(l.BaseValue or E.value(data,w))..'\n'..math.max(0,math.ceil((l.Expires-(data.Unix or os.time()))/3600))..'h left',12,muted); owner.Position=UDim2.fromOffset(8,214); owner.Size=UDim2.new(1,-16,0,42); owner.TextXAlignment=Enum.TextXAlignment.Center
  local buy=button(card,(l.Seller==player.UserId and 'YOUR OFFER' or 'BUY')..' • '..l.Price,function() if l.Seller~=player.UserId then marketBuyId=l.Id; show('MarketBuy') end end,true); buy.Position=UDim2.new(0,8,1,-60); buy.Size=UDim2.new(1,-16,0,50); buy.TextSize=15
 end
end
local function marketList()
 local w=get(marketDraftId)
 if not w then row('Weapon is no longer in your inventory.',18); return end
 row('SET YOUR ASKING PRICE',21,warm); viewport(scroller,w,150)
 row(itemName(w),16); row('NPC base: '..E.value(data,w)..' Coins • Your price is your choice.',14)
 local entry=make('TextBox',scroller,{Size=UDim2.new(1,0,0,52),BackgroundColor3=Color3.fromRGB(247,239,210),TextColor3=ink,Text=tostring(E.value(data,w)*2),PlaceholderText='Whole Coins price',ClearTextOnFocus=false,Font=Enum.Font.GothamBold,TextSize=24}); corner(entry,10)
 local net=row('',15,green)
 local function updateNet() local n=tonumber(entry.Text); net.Text=n and n==math.floor(n) and n>=1 and n<=C.MarketMaxPrice and ('YOU RECEIVE '..(n-math.ceil(n*C.MarketTax))..' COINS AFTER 8% TAX') or 'Enter 1–100,000,000 Coins, whole numbers only.' end
 entry:GetPropertyChangedSignal('Text'):Connect(updateNet); updateNet()
 button(scroller,'CONFIRM LISTING • 24 HOURS',function() send('MarketList',{Id=w.Id,Price=tonumber(entry.Text)}) end,true)
 row('The weapon leaves your inventory while listed. You can cancel before it sells. Offers are hosted by this server; saved offers return when you rejoin.',13)
end
local function marketBuy()
 local listing
 for _,l in ipairs(data.Market or {}) do if l.Id==marketBuyId then listing=l end end
 if not listing then row('THIS OFFER IS NO LONGER AVAILABLE',20,red); button(scroller,'BACK TO MARKET',function() show('Market') end); return end
 viewport(scroller,listing.Weapon,180); row(itemName(listing.Weapon),18)
 row('Seller @'..listing.SellerName..'\nPAY EXACTLY '..listing.Price..' COINS',20,warm)
 button(scroller,'CONFIRM BUY • '..listing.Price..' COINS',function() send('MarketBuy',listing.Id) end,true)
 button(scroller,'CANCEL',function() show('Market') end)
end

local function inventory()
 if selected then local w=get(selected); if w then weaponActions(w); button(scroller,'← ALL WEAPONS',function() selected=nil; render() end); return end; selected=nil end
 row(#data.Inventory..' / '..data.Capacity..' weapons • '..data.Slots..' showcases • Forged '..data.Stats.Forged..' • Mythics '..(data.Stats.Mythics or 0),14)
 row('BEST ◉ '..(data.Stats.BestValue or 0)..' • MARKET SALES ◉ '..(data.Stats.MarketSales or 0)..' • PRESTIGE '..data.Prestige,13,warm)
 mergeHeader.Visible=true
 if #data.Inventory==0 then row('Your first discovery is waiting. Choose a metal at the forge!',18) end
 local grid=make('Frame',scroller,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
 local columns=panel.AbsoluteSize.X<650 and 3 or 4
 local h=scroller.AbsoluteSize.Y<310 and 174 or 228
 make('UIGridLayout',grid,{CellSize=UDim2.new(1/columns,-10,0,h),CellPadding=UDim2.fromOffset(10,10),SortOrder=Enum.SortOrder.LayoutOrder})
 for _,w in ipairs(data.Inventory) do rarityCard(grid,w,h,false,function() selected=w.Id; render() end) end
end
local bookCategory,bookSelected=1,nil
local function bookName(category,index)
 if category.Key=='Blueprint' then return C.Weapons[index].Name elseif category.Key=='Material' then return C.Materials[index].Name elseif category.Key=='Rarity' then return C.Rarities[index].Name elseif category.Key=='Mutation' then return C.Mutations[index].Name end
 return index==1 and 'Perfect Forge' or 'Secret Eclipse'
end
local function bookSample(category,index)
 if category.Key=='Blueprint' then return {Blueprint=index,Rarity=1,Mutation=1,Material=C.Weapons[index].Zone==3 and 5 or C.Weapons[index].Zone==2 and 3 or 1} end
 return {Blueprint=category.Key=='Mutation' and 7 or 2,Rarity=category.Key=='Rarity' and index or 1,Mutation=category.Key=='Mutation' and index or 1,Material=category.Key=='Material' and index or 1,Perfect=category.Key=='Variant' and index==1,Secret=category.Key=='Variant' and index==2}
end
local function collection()
 local found,total,p=B.progress(data)
 row('COLLECTION '..math.floor(p*100)..'%  •  '..found..' / '..total,20,warm)
 local progressTrack=make('Frame',scroller,{Size=UDim2.new(1,0,0,14),BackgroundColor3=Color3.fromRGB(12,17,31)}); corner(progressTrack,7)
 local fill=make('Frame',progressTrack,{Size=UDim2.fromScale(p,1),BackgroundColor3=purple,BorderSizePixel=0}); corner(fill,7)
 local category=B.Categories[bookCategory]
 local tabs=make('Frame',scroller,{Size=UDim2.new(1,0,0,108),BackgroundTransparency=1})
 for i,c in ipairs(B.Categories) do
  local b=button(tabs,c.Name,function() bookCategory=i; bookSelected=nil; render() end,i==bookCategory)
  b.Position=UDim2.new((i-1)%3/3,0,0,math.floor((i-1)/3)*56); b.Size=UDim2.new(1/3,-6,0,48); b.TextSize=13
 end
 if bookSelected then
  local index=bookSelected; local key=category.Key..':'..index; local entry=data.Book and data.Book[key]; local discovered=data.Discoveries[key]
  local sample=entry and entry.Weapon or bookSample(category,index)
  row(bookName(category,index),21,discovered and warm or muted)
  viewport(scroller,sample,scroller.AbsoluteSize.Y<300 and 140 or 220,not discovered)
  local zone=C.Weapons[sample.Blueprint].Zone
  row('SOURCE: '..(category.Key=='Material' and (index<=2 and 'Village Mine' or index<=4 and 'Magma Quarry' or 'Arcane Ruins') or C.Zones[zone].Name..' forge'),15)
  if entry then
   row('FIRST FOUND '..os.date('!%Y-%m-%d %H:%M UTC',entry.FirstFound)..'\nBEST FOUND VALUE ◉ '..entry.BestValue,16,green)
   row('BEST ROLL • '..itemName(sample)..'\n'..C.Materials[sample.Material or 1].Name..(sample.Perfect and ' • Perfect' or '')..(sample.Secret and ' • Eclipse' or ''),15)
   local stats=E.properties(sample); row(string.format('Mining ×%.2f • Forge luck +%.1f%%',stats.Mining,stats.Luck*100),14)
  elseif discovered then row('Discovered in an earlier version. Find another roll to record its date and best value.',15)
  else row(category.Key=='Variant' and (index==1 and 'Land all three gold hammer hits.' or 'An exceptionally rare independent forge variant. Keep exploring your collection.') or 'Forge with materials from the source zone to discover this entry.',16) end
  button(scroller,'BACK TO '..string.upper(category.Name),function() bookSelected=nil; render() end)
  return
 end
 local grid=make('Frame',scroller,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
 local cols=panel.AbsoluteSize.X<650 and 3 or 4
 make('UIGridLayout',grid,{CellSize=UDim2.new(1/cols,-10,0,208),CellPadding=UDim2.fromOffset(10,12)})
 for i=category.Start or 1,category.Count do
  local key=category.Key..':'..i; local foundEntry=data.Discoveries[key]; local entry=data.Book and data.Book[key]
  local sample=entry and entry.Weapon or bookSample(category,i)
  local color=foundEntry and Color3.fromRGB(unpack(C.Rarities[sample.Rarity].Color)) or Color3.fromRGB(76,88,125)
  local card=make('Frame',grid,{BackgroundColor3=color:Lerp(ink,.7)}); corner(card,12); make('UIStroke',card,{Color=color,Thickness=3})
  local view=viewport(card,sample,126,not foundEntry); view.Position=UDim2.fromOffset(0,8)
  local name=label(card,bookName(category,i),14,foundEntry and text or muted); name.Position=UDim2.fromOffset(5,134); name.Size=UDim2.new(1,-10,0,34); name.TextXAlignment=Enum.TextXAlignment.Center
  local info=label(card,not foundEntry and 'UNDISCOVERED' or entry and ('BEST ◉ '..entry.BestValue) or 'DISCOVERED',12,foundEntry and warm or muted); info.Position=UDim2.fromOffset(5,171); info.Size=UDim2.new(1,-10,0,26); info.TextXAlignment=Enum.TextXAlignment.Center
  local hit=make('TextButton',card,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text='',Selectable=true}); hit.Activated:Connect(function() bookSelected=i; render() end)
 end
 row('COLLECTION REWARDS',18,warm)
 for i,palier in ipairs(B.Paliers) do
  local earned=(data.CollectionMilestones or {})[tostring(i)] or p>=palier.At
  row((earned and '✓ ' or tostring(math.floor(palier.At*100))..'%  ')..palier.Name,16,earned and green or muted)
 end
 row('Discoveries and best rolls remain after selling, merging and prestige. Rewards unlock automatically and permanently.',13)
end

local function upgrades()
 if data.Zone<3 then
  local zone=C.Zones[data.Zone+1]
  row('NEXT: '..string.upper(zone.Name),22,Color3.fromRGB(unpack(zone.Color)))
  row('New metals • new parts • new mutations',14)
  button(scroller,'UNLOCK  ◉ '..zone.Cost,function() send('Zone') end,true)
 end
 local cues={Speed='Double burner at level 5 • Reinforced forge at 10',Value='Every sale pays more',Luck='Adds glowing charms to your forge',Display='Your showcased weapons earn more',Capacity='Keep more discoveries before selling'}
 for _,key in ipairs({'Speed','Value','Luck','Display','Capacity'}) do
  local u=C.Upgrades[key]; local level=data.Upgrades[key]
  local card=make('Frame',scroller,{Size=UDim2.new(1,0,0,116),BackgroundColor3=Color3.fromRGB(43,54,84)}); corner(card,12); make('UIStroke',card,{Color=Color3.fromRGB(85,109,160),Thickness=2})
  local t=label(card,string.upper(u.Name)..'  LV.'..level,18,warm); t.Position=UDim2.fromOffset(12,6); t.Size=UDim2.new(.65,-16,0,28)
  local desc=label(card,u.Description..'\n'..cues[key],13); desc.Position=UDim2.fromOffset(12,36); desc.Size=UDim2.new(.6,-16,0,66)
  local b=button(card,level>=u.Max and 'MAX' or ('UPGRADE\n◉ '..E.cost(key,level)),function() send('Upgrade',key) end,true); b.Size=UDim2.new(.37,-12,0,64); b.Position=UDim2.new(.63,0,.5,-32)
 end
 row('MASTER FORGE  ★ '..data.Prestige,20,warm)
 button(scroller,'REVIEW PRESTIGE • ARCANE + ◉ '..E.prestigeCost(data),function() send('PrestigePreview') end)
end
local function forgeMenu()
 forgeAction.Visible=true; scroller.Size=UDim2.new(1,-28,1,-140)
 local selectedMaterial=C.Materials[data.Material or 1]
 forgeAction.Text='⚒ HEAT '..string.upper(selectedMaterial.Name)..'  '..('• STOCK '..(data.Materials[selectedMaterial.Name] or 0))
 row('CHOOSE METAL → HEAT → 3 STRIKES',18,warm)
 local grid=make('Frame',scroller,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
 local compact=scroller.AbsoluteSize.Y<270
 local cols=compact and 1 or panel.AbsoluteSize.X<550 and 2 or 3
 make('UIGridLayout',grid,{CellSize=UDim2.new(1/cols,-10,0,compact and 90 or 198),CellPadding=UDim2.fromOffset(10,10)})
 for i,m in ipairs(C.Materials) do
  local unlocked=m.Zone<=data.Zone
  local card=make('Frame',grid,{BackgroundColor3=Color3.fromRGB(unpack(m.Color)):Lerp(ink,.7)}); corner(card,12); make('UIStroke',card,{Color=Color3.fromRGB(unpack(m.Color)),Thickness=data.Material==i and 4 or 2})
  local view=make('ViewportFrame',card,{Size=UDim2.new(1,0,0,76),Position=UDim2.fromOffset(0,4),BackgroundTransparency=1,Ambient=Color3.new(.8,.8,.8),LightDirection=Vector3.new(-1,-1,-1)})
  make('Part',view,{Size=Vector3.new(2,.7,1),Color=Color3.fromRGB(unpack(m.Color)),Material=i>=4 and Enum.Material.Neon or Enum.Material.Metal,CFrame=CFrame.Angles(.4,.5,.15),Anchored=true})
  local camera=make('Camera',view,{CFrame=CFrame.lookAt(Vector3.new(0,1,5),Vector3.new()),FieldOfView=35}); view.CurrentCamera=camera
  local t=label(card,m.Name,17); t.Position=UDim2.fromOffset(4,78); t.Size=UDim2.new(1,-8,0,24); t.TextXAlignment=Enum.TextXAlignment.Center
  local desc=label(card,'×'..m.Multiplier..' value  •  '..('STOCK '..(data.Materials[m.Name] or 0))..'\n'..(unlocked and (m.Parts..' part styles') or C.Zones[m.Zone].Name),12); desc.Position=UDim2.fromOffset(4,104); desc.Size=UDim2.new(1,-8,0,38); desc.TextXAlignment=Enum.TextXAlignment.Center
  local b=button(card,not unlocked and 'LOCKED' or data.Material==i and 'SELECTED' or 'CHOOSE',function() if unlocked then send('Material',i) else notify('Unlock '..C.Zones[m.Zone].Name) end end,unlocked and data.Material==i); b.Position=UDim2.new(0,6,1,-52); b.Size=UDim2.new(1,-12,0,48); b.TextSize=14
  if compact then
   view.Size=UDim2.fromOffset(80,76); view.Position=UDim2.fromOffset(0,5)
   t.Position=UDim2.fromOffset(88,5); t.Size=UDim2.new(1,-210,0,24); t.TextXAlignment=Enum.TextXAlignment.Left
   desc.Position=UDim2.fromOffset(88,31); desc.Size=UDim2.new(1,-210,0,48); desc.TextXAlignment=Enum.TextXAlignment.Left
   b.Position=UDim2.new(1,-116,.5,-24); b.Size=UDim2.fromOffset(108,48)
  end
 end
 button(scroller,'VIEW LIVE ROLL ODDS',function() show('Odds') end)
 row('Aim for gold. Perfect hits improve value and luck. No penalty for a late strike.',13)
end
local function fetchPrice(key)
 local p=C.Monetization[key]
 if not p.Id or prices[key] then return end
 prices[key]={Loading=true}
 task.spawn(function()
  local ok,info=pcall(Marketplace.GetProductInfoAsync,Marketplace,p.Id,p.Kind=='Pass' and Enum.InfoType.GamePass or Enum.InfoType.Product)
  prices[key]=ok and info or {Unavailable=true}
  if page=='Shop' then render() end
 end)
end
local function shop()
 row('MAKE YOUR FORGE WORK YOUR WAY',19,warm)
 button(scroller,'VIEW LIVE ROLL ODDS',function() show('Odds') end)
 local tabs=make('Frame',scroller,{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1})
 make('UIListLayout',tabs,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})
 for _,tab in ipairs({'PERMANENT','BOOSTS & COINS'}) do local b=button(tabs,tab,function() shopTab=tab; render() end,shopTab==tab); b.Size=UDim2.new(.5,-4,0,48) end
 local keys=shopTab=='PERMANENT' and {'DoubleCoins','AutoForge','AutoMerge','DisplaySlots','MarketListings','Starter'} or {'Small','Medium','Large','LuckyForge','ResourceBoost'}
 local grid=make('Frame',scroller,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
 local cols=panel.AbsoluteSize.X<550 and 1 or 2
 make('UIGridLayout',grid,{CellSize=UDim2.new(1/cols,-10,0,210),CellPadding=UDim2.fromOffset(10,10)})
 local emblems={MarketListings='+2',ResourceBoost='ORE',DoubleCoins='2×',AutoForge='⚒',AutoMerge='3→1',DisplaySlots='+2',LuckyForge='✦',Starter='START',Small='◉',Medium='◉◉',Large='◉◉◉'}
 for index,key in ipairs(keys) do
  local p=C.Monetization[key]; fetchPrice(key)
  local color=({warm,blue,purple,green})[(index-1)%4+1]
  local card=make('Frame',grid,{BackgroundColor3=color:Lerp(ink,.7)}); corner(card,14); make('UIStroke',card,{Color=color,Thickness=3})
  make('UIGradient',card,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(106,113,153)),Rotation=90})
  local icon=label(card,emblems[key],36,color); icon.Position=UDim2.fromOffset(12,8); icon.Size=UDim2.fromOffset(90,56); icon.TextXAlignment=Enum.TextXAlignment.Center; icon.Font=Enum.Font.GothamBlack
  local heading=label(card,p.Name,19); heading.Position=UDim2.fromOffset(110,8); heading.Size=UDim2.new(1,-120,0,56)
  local desc=label(card,(key=='Starter' and ('◉ '..E.starterCoins(data)..' + 10m luck. Gold trim + a Rare/Epic gift.') or p.Benefit) or ('◉ '..E.coinPack(data,key)..' now • '..p.Minutes..' minutes of current income'),14); desc.Position=UDim2.fromOffset(12,68); desc.Size=UDim2.new(1,-24,0,68)
  local info=prices[key]
  local restricted=key=='Starter' or key=='LuckyForge' or key=='Small' or key=='Medium' or key=='Large' or key=='ResourceBoost'
  local available=p.Id and info and info.PriceInRobux and info.IsForSale~=false and not data.Memory and (not restricted or data.PaidRandomAllowed)
  local copy=data.Owned[key] and '✓ OWNED' or available and ('BUY • R$ '..info.PriceInRobux) or 'UNAVAILABLE'
  local buy=button(card,copy,function() if available and not data.Owned[key] then send('PurchasePrompt',key) else notify('This offer is unavailable. Your forge is still free to play.') end end,available)
  buy.Position=UDim2.new(0,10,1,-60); buy.Size=UDim2.new(1,-20,0,50); buy.BackgroundColor3=available and color or Color3.fromRGB(67,73,94)
 end
 row('Starter weapon: Rare 85% / Epic 15%; current-zone blueprints 1/3 each; blade styles 1/2 each, guard/grip style 2; no mutation or secret. Gift waits safely for inventory space.',12)
 row('Luck boost: +50% rare weight for 10 minutes. Live odds include existing luck, collection and events. Check the roll odds above.',12)
end
local function odds()
 local now=data.Unix or os.time()
 local event=data.Event and C.Events[data.Event.Index]
 local luck=O.luck(data,now,event,false)
 local base=O.percent(C.Rarities,luck)
 local boosted=O.percent(C.Rarities,O.luck(data,now,event,false,true))
 local perfect=O.percent(C.Rarities,O.luck(data,now,event,true))
 row('LIVE FORGE ODDS',22,warm)
 row('Current / with luck boost / Perfect (3 gold hits)',14)
 for i,r in ipairs(C.Rarities) do row(r.Name..string.format('   %.4f%% / %.4f%% / %.4f%%',base[i],boosted[i],perfect[i]),16,Color3.fromRGB(unpack(r.Color))) end
 local pool=O.mutations(data.Material,event); local percents=O.percent(pool)
 row(C.Materials[data.Material or 1].Name..' MUTATIONS',19,warm)
 for i,v in ipairs(pool) do row(C.Mutations[v.Index].Name..string.format('   %.4f%%',percents[i]),15) end
 row('Blueprints: '..(data.Stats.Forged==0 and 'first forge Iron Saber 100%' or 'three selected-material-zone blueprints, 33.3333% each')..'. Every blade / guard / grip style in this material: '..string.format('%.4f%%',100/C.Materials[data.Material or 1].Parts)..' independently.',14)
 row('Secret Eclipse: 0.05% independently. Standard variant: 99.95%. Perfect quality: 3 correctly timed manual hits; Auto Forge has no Perfect bonus. Multiply independent component probabilities for a complete combination.',14)
end
local function settings()
 for _,key in ipairs({'Music','SFX','LowVFX','CameraShake','QuickMerge','AutoForge','AutoMerge'}) do
  button(scroller,key..'  •  '..(data.Settings[key] and 'ON' or 'OFF'),function() send('Setting',{Key=key,Value=not data.Settings[key]}) end)
 end
 row('Auto Merge consumes unlocked, stored weapons only. Result keeps the first input’s silhouette and mutation.',14,muted)
 button(scroller,'Auto Merge input limit: '..C.Rarities[data.Settings.MergeThreshold].Name,function() send('Setting',{Key='MergeThreshold',Value=data.Settings.MergeThreshold%5+1}) end)

end
render=function()
 if not data or not page then return end
 clear()
 title.Text=page=='Reveal' and 'FRESH FROM THE FORGE' or page=='PrestigeConfirm' and 'CONFIRM PRESTIGE' or string.upper(page)
 if page=='Forge' then forgeMenu()
 elseif page=='Inventory' then inventory()
 elseif page=='Market' then market()
 elseif page=='MarketList' then marketList()
 elseif page=='MarketBuy' then marketBuy()
 elseif page=='MarketHistory' then
  row('LAST 20 TRANSACTIONS',20,warm)
  if #(data.MarketHistory or {})==0 then row('Your first player sale or purchase will appear here.',16) end
  for _,entry in ipairs(data.MarketHistory or {}) do
   row(string.upper(entry.Kind)..' • '..entry.Name,17,entry.Kind=='Sold' and green or blue)
   row(os.date('!%m-%d %H:%M UTC',entry.At)..' • '..entry.Price..' COINS'..(entry.Kind=='Sold' and ' • NET '..entry.Net or ''),14)
  end
  button(scroller,'BACK TO MARKET',function() show('Market') end)
 elseif page=='Inspect' and inspection then
  local w=inspection.Weapon; viewport(scroller,w,190); row(itemName(w),19)
  row('OWNER @'..inspection.Owner..' • VALUE '..inspection.Value..' COINS',16,warm)
  row(C.Materials[w.Material or 1].Name..' • FOUND '..os.date('!%Y-%m-%d',w.FoundAt or os.time()),14)
  local stats=E.properties(w); row(string.format('Mining ×%.2f • Forge Luck +%.1f%%',stats.Mining,stats.Luck*100),15,green)
  button(scroller,'VIEW OWNER MARKET',function() marketFilters.Owner=inspection.OwnerId; send('MarketOpen'); show('Market') end,true)
 elseif page=='Collection' then collection()
 elseif page=='Upgrades' then upgrades()
 elseif page=='Shop' then shop()
 elseif page=='Odds' then odds()
 elseif page=='Settings' then settings()
 elseif page=='Reveal' and reveal then showReward(reveal)
 elseif page=='Merge' then
  row('3 WEAPONS → '..string.upper(C.Rarities[mergeRarity].Name),20,purple)
  local cards=make('Frame',scroller,{Size=UDim2.new(1,0,0,180),BackgroundTransparency=1})
  local inputs={}; local valid=true
  for i,id in ipairs(mergeItems) do
   local w=get(id)
   if w then local card=rarityCard(cards,w,176,false); card.Position=UDim2.new((i-1)/3,5,0,2); card.Size=UDim2.new(1/3,-12,0,176); table.insert(inputs,card) else valid=false end
  end
  row('Keeps the first weapon’s parts and mutation. Consumes these three weapons.',13)
  if valid then
   local confirming=false
   local b=button(scroller,'CONFIRM MERGE',function()
    if confirming then return end; confirming=true
    local duration=data.Settings.QuickMerge and .12 or .6
    for _,card in ipairs(inputs) do Tween:Create(card,TweenInfo.new(duration,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.new(.5,-20,.5,-20),Size=UDim2.fromOffset(40,40),Rotation=25,BackgroundTransparency=1}):Play() end
    task.delay(duration,function() send('MergeConfirm',token); page=nil; panel.Visible=false end)
   end,true); b.BackgroundColor3=purple
  else row('Items changed. Review a new merge.') end
 elseif page=='Prestige' then
  row('BECOME A MASTER FORGER',20,warm)
  row('RESETS: all coins, upgrade levels, material stock and zone access. This cannot be undone.',16)
  row('KEEPS: all weapons, listings, discovered collection, lifetime sales, purchases and cosmetics.',15)
  row('GAIN: diminishing production bonus (up to +100%), a small luck/speed bonus, and extra starting Steel.',15)
  button(scroller,'I UNDERSTAND — FINAL CONFIRMATION',function()
   page='PrestigeConfirm'; render()
  end)
 elseif page=='PrestigeConfirm' then
  row('Coins, zones and main upgrades reset. Your weapons and market listings stay.',18,warm)
  button(scroller,'RESET & PRESTIGE',function() send('PrestigeConfirm',prestigeToken); page='Upgrades' end,true)
  button(scroller,'CANCEL',function() show('Upgrades') end)
 end
end
for i,name in ipairs({'Inventory','Collection','Market','Upgrades'}) do
 local colors={blue,purple,warm,green}
 local b=button(nav,'',function() if data then if name=='Market' then send('MarketOpen') end; show(name) end end,name=='Market')
 b.BackgroundColor3=colors[i]; b.LayoutOrder=i; b.Size=UDim2.new(.25,-5,1,0)
 local icon=make('Frame',b,{Size=UDim2.fromOffset(24,24),Position=UDim2.new(.5,-12,0,5),BackgroundTransparency=1})
 local function bar(size,pos,rotation)
  local f=make('Frame',icon,{Size=UDim2.fromOffset(size[1],size[2]),Position=UDim2.fromOffset(pos[1],pos[2]),Rotation=rotation or 0,BackgroundColor3=text,BorderSizePixel=0}); corner(f,2); return f
 end
 if i==1 then for x=0,1 do for y=0,1 do bar({9,9},{x*13,y*13}) end end
 elseif i==2 then bar({10,21},{0,1},-5); bar({10,21},{13,1},5); bar({2,24},{11,0})
 elseif i==3 then bar({24,5},{0,2}); bar({20,4},{2,18}); bar({3,16},{3,4}); bar({3,16},{18,4})
 else bar({5,21},{9,3}); bar({14,5},{1,4},-45); bar({14,5},{10,4},45) end
 local caption=label(b,name,13); caption.Size=UDim2.new(1,0,0,20); caption.Position=UDim2.new(0,0,1,-23); caption.TextXAlignment=Enum.TextXAlignment.Center

end
for i,name in ipairs({'Shop','Settings'}) do
 local b=button(hud,name=='Shop' and 'SHOP' or '⚙',function() if data then if name=='Shop' then send('Shop') end; show(name) end end)
 b.Size=UDim2.fromOffset(name=='Shop' and 66 or 48,48); b.Position=UDim2.new(1,-(i==1 and 130 or 56),0,8); b.TextSize=15; b.BackgroundColor3=i==1 and green or blue
end
local tutorialCopy={
 [0]='1 / 5  •  FORGE YOUR FIRST WEAPON  —  tap the orange button',
 [1]='SELL your first weapon',
 [2]='↑ Buy your first SPEED upgrade',
 [3]='⚒ Forge another discovery',
 [4]='DISPLAY a favorite • KEEP 3 to MERGE • Tap to continue',
}
tutorial.Activated:Connect(function()
 if not data then return end
 if data.Tutorial==4 then send('TutorialDone')
 elseif data.Tutorial==2 then show('Upgrades')
 elseif data.Tutorial==1 then show('Inventory')
 elseif data.Tutorial<4 then show('Forge')
 else show('Upgrades') end
end)
local rewardLayer=make('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(8,8,24),BackgroundTransparency=.18,Visible=false,ZIndex=20})
local rewardBody
local function closeReward()
 revealGeneration+=1; rewardLayer.Visible=false; if rewardBody then rewardBody:Destroy(); rewardBody=nil end
 hud.Visible=true; nav.Visible=true; tutorial.Visible=data and data.Tutorial<5; forgeButton.Visible=forgeRunning
end
showReward=function(w,merged)
 if not w or not data then return end
 closeReward(); local gen=revealGeneration
 page=nil; panel.Visible=false; hud.Visible=false; nav.Visible=false; tutorial.Visible=false; forgeButton.Visible=false
 rewardLayer.Visible=true
 rewardBody=make('Frame',rewardLayer,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
 local body=rewardBody
 local color=Color3.fromRGB(unpack(C.Rarities[w.Rarity].Color))
 local big=w.Rarity>=5
 local title=label(body,(merged and 'MERGED!  ' or 'NEW WEAPON!  ')..string.upper(C.Rarities[w.Rarity].Name),big and 32 or 26,color); title.Size=UDim2.new(.9,0,0,40); title.Position=UDim2.new(.5,0,0,4); title.AnchorPoint=Vector2.new(.5,0); title.TextXAlignment=Enum.TextXAlignment.Center; title.Font=Enum.Font.GothamBlack; title.TextStrokeTransparency=.25
 local scale=make('UIScale',title,{Scale=.65}); Tween:Create(scale,TweenInfo.new(.5,Enum.EasingStyle.Back),{Scale=1}):Play()
 if big and not data.Settings.LowVFX then
  for i=1,12 do
   local ray=make('Frame',body,{Size=UDim2.new(0,8,.56,0),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.45),Rotation=i*30,BackgroundColor3=color,BackgroundTransparency=.77,BorderSizePixel=0}); corner(ray,8)
   Tween:Create(ray,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=.92}):Play()
  end
 end
 local view=viewport(body,w,100); view.Size=UDim2.new(.8,0,1,-198); view.Position=UDim2.new(.5,0,0,46); view.AnchorPoint=Vector2.new(.5,0)
 local name=label(body,C.Weapons[w.Blueprint].Name,22); name.Position=UDim2.new(.5,0,1,-150); name.AnchorPoint=Vector2.new(.5,0); name.Size=UDim2.new(.95,0,0,30); name.TextXAlignment=Enum.TextXAlignment.Center
 local value=label(body,'',20,warm); value.Position=UDim2.new(.5,0,1,-122); value.AnchorPoint=Vector2.new(.5,0); value.Size=UDim2.new(.95,0,0,28); value.TextXAlignment=Enum.TextXAlignment.Center
 local mutation=label(body,'',16,color); mutation.Position=UDim2.new(.5,0,1,-92); mutation.AnchorPoint=Vector2.new(.5,0); mutation.Size=UDim2.new(.95,0,0,26); mutation.TextXAlignment=Enum.TextXAlignment.Center
 local decisions=make('Frame',body,{Size=UDim2.new(.8,0,0,52),Position=UDim2.new(.5,0,1,-12),AnchorPoint=Vector2.new(.5,1),BackgroundTransparency=1})
 make('UIListLayout',decisions,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,10)})
 for i,choice in ipairs({'SELL NPC','KEEP','DISPLAY','MARKET','MERGE'}) do
  local b=button(decisions,choice,function()
   if choice=='SELL NPC' then send('Sell',w.Id) elseif choice=='DISPLAY' then send('Display',w.Id) elseif choice=='KEEP' then send('Keep',w.Id) end
   closeReward()
   if choice=='MARKET' then marketDraftId=w.Id; show('MarketList') elseif choice=='MERGE' then send('MergePreview') end
  end,choice=='SELL NPC'); b.Size=UDim2.new(1/5,-8,0,52); b.TextSize=12; b.BackgroundColor3=({green,blue,purple,warm,purple})[i]
 end
 Effects.sound(big and 'legendary_reveal' or 'rarity_reveal')
 task.delay(.45,function() if gen==revealGeneration and value.Parent then value.Text='◉ '..E.value(data,w)..(w.Perfect and '  •  PERFECT FORGE +12%' or '') end end)
 task.delay(.9,function() if gen==revealGeneration and mutation.Parent then mutation.Text=w.Secret and 'SECRET ECLIPSE VARIANT' or w.Mutation>1 and (string.upper(C.Mutations[w.Mutation].Name)..' MUTATION') or (C.Materials[w.Material or 1].Name..'  •  '..C.Parts.Blade[w.Blade or 1]..' blade  •  '..C.Parts.Handle[w.Handle or 1]..' grip') end end)
end
local timingTrack=make('Frame',forgeButton,{Position=UDim2.new(0,8,0,-20),Size=UDim2.new(1,-16,0,14),BackgroundColor3=ink,BorderSizePixel=0}); corner(timingTrack,6)
local sweet=make('Frame',timingTrack,{Size=UDim2.fromScale(.18,1),Position=UDim2.fromScale(.41,0),BackgroundColor3=warm,BorderSizePixel=0}); corner(sweet,5)
local cursor=make('Frame',timingTrack,{Size=UDim2.new(0,5,1,4),Position=UDim2.fromOffset(0,-2),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0})
Run.RenderStepped:Connect(function(dt)
 local touch=player.PlayerGui:FindFirstChild('TouchGui'); if touch then touch.Enabled=not panel.Visible and not rewardLayer.Visible end
 if data and not data.Craft and not panel.Visible and not rewardLayer.Visible then
  local a=rackPosition(); local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  forgeButton.Visible=a and root and (root.Position-a.Position).Magnitude<=16 or false
  forgeButton.Text='FORGE • CHOOSE MATERIAL'; timingTrack.Visible=false; forgeBar.Size=UDim2.new()
 end
 for i=#spins,1,-1 do
  local spin=spins[i]
  if not spin.Frame.Parent or not spin.Frame:IsDescendantOf(gui) then table.remove(spins,i)
  elseif spin.Frame.Visible and (rewardLayer.Visible and spin.Frame:IsDescendantOf(rewardLayer) or panel.Visible and spin.Frame:IsDescendantOf(panel)) then
   spin.Angle+=dt*.45; local angle=spin.Frame:IsDescendantOf(rewardLayer) and spin.Angle or math.sin(spin.Angle)*.4
   spin.Model:PivotTo(spin.Base*CFrame.Angles(0,angle,0))
  end
 end
 if data and data.Craft then
  local c=data.Craft; local now=os.clock()+clockOffset
  if now<c.HeatEnd then
   forgeBar.Size=UDim2.new(math.clamp((now-c.Started)/(c.HeatEnd-c.Started),0,1),0,0,4)
   forgeButton.Text='HEATING '..math.floor(math.clamp((now-c.Started)/(c.HeatEnd-c.Started),0,1)*100)..'%'
   timingTrack.Visible=false
  elseif c.Automatic then forgeBar.Size=UDim2.new(math.clamp((now-c.Started)/c.Duration,0,1),0,0,4); forgeButton.Text='AUTO FORGING…'; timingTrack.Visible=false
  else
   forgeBar.Size=UDim2.new(c.Hits/3,0,0,4)
   local period=c.Duration*.58/3
   local t=(now-c.HeatEnd-period*c.Hits)/period
   cursor.Position=UDim2.new(math.clamp(t,0,1),-2,0,-2)
   sweet.Size=UDim2.fromScale(math.min(1,2*C.PerfectWindow/period),1); sweet.Position=UDim2.fromScale(math.max(0,.5-C.PerfectWindow/period),0)
   timingTrack.Visible=c.Hits<3
   forgeButton.Text=c.Hits<3 and ('⚒ STRIKE '..(c.Hits+1)..' / 3  •  TAP') or 'QUENCHING…'
  end
 end
end)
local lastSignature=''
state.OnClientEvent:Connect(function(snapshot,event,result)
 if snapshot then
  local before=data and B.rewards(data)
  data=snapshot; Effects.Settings=data.Settings
  if before then local after=B.rewards(data); if before.Slots<after.Slots then notify('COLLECTION 25% • EXTRA SHOWCASE SLOT!') elseif not before.Skin and after.Skin then notify('COLLECTION 50% • COLLECTOR FORGE SKIN!') elseif before.Luck<after.Luck then notify('COLLECTION 10% • LUCK +10%!') end end
  local music=game:GetService('SoundService'):FindFirstChild('WFTMusic')
  if not music and C.Sounds.music then music=make('Sound',game:GetService('SoundService'),{Name='WFTMusic',SoundId='rbxassetid://'..C.Sounds.music,Looped=true,Volume=.2}) end
  if music then if data.Settings.Music and not music.IsPlaying then music:Play() elseif not data.Settings.Music then music:Pause() end end
  if snapshot.Clock then clockOffset=snapshot.Clock-os.clock() end
  money.Text='◉ '..math.floor(data.Coins)
  local selectedMetal=C.Materials[data.Material or 1]; materialHud.Text=string.upper(selectedMetal.Name)..' '..(data.Materials[selectedMetal.Name] or 0)
  if (data.Materials[selectedMetal.Name] or 0)==0 then progress.Text='COLLECT '..string.upper(selectedMetal.Name)..' → FORGE' end
  local zone=data.Zone<3 and C.Zones[data.Zone+1] or {Name='Master Forge',Cost=E.prestigeCost(data)}
  progress.Text=((data.Materials[C.Materials[data.Material].Name] or 0)==0 and 'COLLECT MATERIALS • ' or '')..'NEXT: '..string.upper(zone.Name)..'\n'..math.floor(data.Coins)..' / '..zone.Cost
  goalFill.Size=UDim2.fromScale(math.clamp(data.Coins/zone.Cost,0,1),1)
  tutorial.Text=data.Tutorial==0 and '▼ FORGE YOUR FIRST WEAPON' or (tutorialCopy[data.Tutorial] or '')
  tutorial.Visible=data.Tutorial<5 and not panel.Visible and not forgeRunning and not rewardLayer.Visible
  forgeRunning=data.Craft~=nil
  local anvil=rackPosition(); local prompt=anvil and anvil:FindFirstChild('ForgePrompt'); if prompt then prompt.Enabled=not forgeRunning and not rewardLayer.Visible end
  if not panel.Visible then forgeButton.Visible=forgeRunning end
  local signature=game:GetService('HttpService'):JSONEncode({data.Inventory,data.Upgrades,data.Settings,data.Zone,data.Owned,data.Material,data.Materials,data.Equipped,data.Listings,data.Market})
  if page and signature~=lastSignature then render() end
  lastSignature=signature
 end
 if event=='error' then notify(result); if data and data.Craft and os.clock()-started>240 and not suggestionShown and not data.Owned.AutoForge then suggestionShown=true; notify('Want a hands-free forge? Auto Forge is in SHOP. Keep playing manually for Perfect bonuses.') end
 elseif event=='welcome' then
  local results=data.MarketResults or {Count=0,Coins=0}
  if results.Count>0 then
   show('Market'); notify('MARKET RESULTS • '..results.Count..' SOLD • +'..results.Coins..' COINS'); send('MarketResultsSeen')
   if result and result>0 then task.delay(4.5,function() notify('OFFLINE FORGE INCOME • +'..result..' COINS') end) end
  elseif result and result>0 then notify('OFFLINE FORGE INCOME • +'..result..' COINS') end
 elseif event=='MarketList' or event=='MarketBuy' or event=='MarketCancel' then notify(result); show('Market')
 elseif event=='market_sale' then notify('YOUR WEAPON SOLD! • +'..result.Coins..' COINS')
 elseif event=='collected' then notify('+'..result.Amount..' '..string.upper(C.Materials[result.Material].Name)..' • RETURN TO FORGE'); Effects.sound('coins')
 elseif event=='inspect' then inspection=result; show('Inspect')
 elseif event=='forge_start' then
  forgeRunning=true; if data then data.Craft=result end
  page=nil; panel.Visible=false; nav.Visible=true; forgeButton.Visible=true; tutorial.Visible=false
  Effects.sound('forge_fire'); ForgeVisual.begin(rackPosition(),result.Duration,impact)
 elseif event=='hammer' then impact(false); ForgeVisual.strike(); notify(result and 'PERFECT HIT!' or 'GOOD HIT')
 elseif event=='reveal' or event=='starter_weapon' then
  forgeRunning=false; forgeButton.Visible=false
  Effects.sound('quench'); ForgeVisual.reveal(rackPosition(),result); impact(result.Rarity>=4)
  if not data.Settings.AutoForge then showReward(result) else notify(itemName(result)..'  •  Added to inventory') end
 elseif event=='merge_preview' then token=result.Token; mergeItems=result.Ids; mergeRarity=result.Rarity; show('Merge')
 elseif event=='prestige_preview' then prestigeToken=result; show('Prestige')
 elseif event=='Sell' then Effects.sound('coins'); local fly=label(gui,'◉ +'..tostring(result),26,warm); fly.Position=UDim2.fromScale(.5,.5); fly.Size=UDim2.fromOffset(180,40); Tween:Create(fly,TweenInfo.new(.7),{Position=UDim2.fromOffset(20,10),TextTransparency=1}):Play(); game:GetService('Debris'):AddItem(fly,.8); notify('+ '..tostring(result)..' coins'); if page then render() end
 elseif event=='MergeConfirm' then impact(true); showReward(result,true)
 elseif event=='auto_merge' then impact(false); notify('AUTO MERGE • '..itemName(result))
 elseif event=='Upgrade' then Effects.sound('upgrade'); notify('Forge upgraded'); if page then render() end
 elseif event=='event' then local e=C.Events[result.Index]; notify(string.upper(e.Name)..'  •  5 MINUTES OF BOOSTED FORGING')
 elseif event=='Zone' then Effects.sound('zone_unlock'); impact(true); notify('NEW FORGE UNLOCKED'); if page then render() end
 elseif event=='PrestigeConfirm' then notify('MASTER FORGE ★ '..data.Prestige); if page then render() end
 elseif event=='purchase_prompt' then
  local p=C.Monetization[result]
  if p and p.Id then
   local ok=pcall(function() if p.Kind=='Pass' then Marketplace:PromptGamePassPurchase(player,p.Id) else Marketplace:PromptProductPurchase(player,p.Id) end end)
   if not ok then notify('Purchase unavailable. Please try again later.') end
  end
 end
end)
PPS.PromptTriggered:Connect(function(prompt,who)
 if who~=player then return end
 local a=rackPosition()
 if prompt.Name=='MarketPrompt' then send('MarketOpen'); show('Market'); return
 elseif prompt.Name=='InspectPrompt' then send('Inspect',{Owner=prompt.Parent:GetAttribute('OwnerId'),Id=prompt.Parent:GetAttribute('WeaponId')}); return end
 if a and prompt.Parent==a then if forgeRunning then send('Hammer') else show('Forge') end
 elseif a and prompt:IsDescendantOf(a.Parent) then
  if prompt.Name=='InventoryPrompt' then show('Inventory') elseif prompt.Name=='UpgradePrompt' then show('Upgrades') end
 end
end)
CAS:BindAction('ForgeWeapon',function(_,input)
 if input==Enum.UserInputState.Begin and not panel.Visible then if forgeRunning then send('Hammer') else local a=rackPosition(); local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart'); if a and root and (root.Position-a.Position).Magnitude<=16 then show('Forge') end end end
 return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.ButtonR2)
CAS:BindAction('OpenArmory',function(_,input) if input==Enum.UserInputState.Begin and data then show('Inventory') end; return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.ButtonY)
CAS:BindAction('CloseForgeMenu',function(_,input) if input==Enum.UserInputState.Begin then closeReward(); page=nil; panel.Visible=false; forgeButton.Visible=forgeRunning end; return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.ButtonB)
send('Ready')
task.spawn(function() while not data do task.wait(2); send('Ready') end end)
