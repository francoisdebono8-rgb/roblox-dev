local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local GuiService=game:GetService('GuiService')
local Tween=game:GetService('TweenService')
local Marketplace=game:GetService('MarketplaceService')
local PPS=game:GetService('ProximityPromptService')
local CAS=game:GetService('ContextActionService')
local player=Players.LocalPlayer
local Shared=game.ReplicatedStorage:WaitForChild('WFT')
local C=require(Shared.Config)
local E=require(Shared.Economy)
local W=require(Shared.WeaponModel)
local Effects=require(script.Parent.Effects)
local ForgeVisual=require(script.Parent.ForgeVisual)
local request=Shared:WaitForChild('Request')
local state=Shared:WaitForChild('State')
local data,page,selected,token,mergeItems,mergeRarity,prestigeToken
local reveal,forgeRunning,forgeGeneration=nil,false,0
local prices,shopTab={},'PERMANENT'
local warm=Color3.fromRGB(255,176,78)
local ink=Color3.fromRGB(25,24,28)
local text=Color3.fromRGB(247,235,215)
local muted=Color3.fromRGB(181,173,161)
local gui=Instance.new('ScreenGui'); gui.Name='ForgeAndFlex'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.IgnoreGuiInset=false; gui.Parent=player:WaitForChild('PlayerGui')
local function make(cls,parent,props)
 local obj=Instance.new(cls); for k,v in pairs(props or {}) do obj[k]=v end; obj.Parent=parent; return obj
end
local function corner(obj,r) make('UICorner',obj,{CornerRadius=UDim.new(0,r or 10)}) end
local function label(parent,copy,size,color)
 return make('TextLabel',parent,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,size+12),Font=Enum.Font.GothamMedium,Text=copy,TextSize=size,TextColor3=color or text,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local function button(parent,copy,callback,primary)
 local b=make('TextButton',parent,{Size=UDim2.new(1,0,0,46),BackgroundColor3=primary and warm or Color3.fromRGB(53,49,48),AutoButtonColor=false,Text=copy,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=primary and ink or text,Selectable=true})
 corner(b,8)
 b.Activated:Connect(function() Effects.sound('button_click'); callback() end)
 b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.16),{BackgroundColor3=primary and Color3.fromRGB(255,196,117) or Color3.fromRGB(72,64,55)}):Play() end)
 b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.16),{BackgroundColor3=primary and warm or Color3.fromRGB(53,49,48)}):Play() end)
 return b
end
local function send(action,arg) request:FireServer(action,arg) end
local hud=make('Frame',gui,{Size=UDim2.new(1,-24,0,60),Position=UDim2.fromOffset(12,8),BackgroundColor3=ink,BackgroundTransparency=.08})
corner(hud)
local money=label(hud,'FORGE & FLEX',20,warm); money.Size=UDim2.new(.46,-16,1,0); money.Position=UDim2.fromOffset(14,0)
local progress=label(hud,'Loading your workshop…',13); progress.Position=UDim2.new(.46,0,0,0); progress.Size=UDim2.new(.54,-12,1,0); progress.TextXAlignment=Enum.TextXAlignment.Right
local tutorial=make('TextButton',gui,{Position=UDim2.new(.5,0,0,78),AnchorPoint=Vector2.new(.5,0),Size=UDim2.new(.94,0,0,52),BackgroundColor3=Color3.fromRGB(54,41,28),TextColor3=text,TextSize=14,Font=Enum.Font.GothamBold,TextWrapped=true,Text='Light the forge. Your first weapon awaits.',AutoButtonColor=false}); corner(tutorial)
local toast=label(gui,'',15,warm); toast.Size=UDim2.new(.9,0,0,48); toast.Position=UDim2.new(.5,0,0,138); toast.AnchorPoint=Vector2.new(.5,0); toast.TextXAlignment=Enum.TextXAlignment.Center; toast.TextStrokeTransparency=.3
local toastVersion=0
local function notify(copy)
 toastVersion+=1; local v=toastVersion; toast.Text=tostring(copy or '')
 task.delay(4,function() if toastVersion==v then toast.Text='' end end)
end
local forgeButton=button(gui,'⚒  FORGE A WEAPON',function() send(forgeRunning and 'Hammer' or 'Forge') end,true)
forgeButton.Size=UDim2.new(UIS.TouchEnabled and .55 or .7,0,0,52); forgeButton.Position=UDim2.new(.5,0,1,-78); forgeButton.AnchorPoint=Vector2.new(.5,1)
make('UISizeConstraint',forgeButton,{MaxSize=Vector2.new(420,52)})
local forgeBar=make('Frame',forgeButton,{Size=UDim2.new(0,0,0,4),Position=UDim2.new(0,0,1,-4),BackgroundColor3=Color3.fromRGB(255,237,190),BorderSizePixel=0})
corner(forgeBar,2)
local nav=make('Frame',gui,{Size=UDim2.new(UIS.TouchEnabled and .72 or 1,-16,0,54),Position=UDim2.new(.5,0,1,-10),AnchorPoint=Vector2.new(.5,1),BackgroundTransparency=1})
make('UIListLayout',nav,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})
local panel=make('Frame',gui,{Size=UDim2.new(.94,0,UIS.TouchEnabled and .76 or .66,0),Position=UDim2.new(.5,0,.48,0),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=ink,Visible=false})
corner(panel,14); make('UIStroke',panel,{Color=Color3.fromRGB(99,79,54),Thickness=1})
make('UISizeConstraint',panel,{MaxSize=Vector2.new(900,680)})
local title=label(panel,'ARMORY',21,warm); title.Position=UDim2.fromOffset(16,10); title.Size=UDim2.new(1,-80,0,40)
local close=button(panel,'×',function() page=nil; panel.Visible=false; forgeButton.Visible=true end)
close.Size=UDim2.fromOffset(44,38); close.Position=UDim2.new(1,-54,0,10)
local scroller=make('ScrollingFrame',panel,{Position=UDim2.fromOffset(14,60),Size=UDim2.new(1,-28,1,-76),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=warm,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
local render
local function clear()
 for _,child in ipairs(scroller:GetChildren()) do child:Destroy() end
 make('UIListLayout',scroller,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
 make('UIPadding',scroller,{PaddingBottom=UDim.new(0,16),PaddingRight=UDim.new(0,6)})
end
local function row(copy,size,color) return label(scroller,copy,size or 14,color) end
local function viewport(parent,w,height,silhouette)
 local frame=make('ViewportFrame',parent,{Size=UDim2.new(1,0,0,height),BackgroundTransparency=1,Ambient=Color3.fromRGB(180,171,161),LightColor=Color3.fromRGB(255,226,190),LightDirection=Vector3.new(-1,-1,-1)})
 local world=make('WorldModel',frame)
 W.build(w,world,CFrame.new()*CFrame.Angles(0,math.rad(-20),math.rad(-20)),1,silhouette)
 local camera=make('Camera',frame,{CFrame=CFrame.lookAt(Vector3.new(0,1,8),Vector3.new(0,.6,0)),FieldOfView=43}); frame.CurrentCamera=camera
 return frame
end
local function itemName(w) return C.Weapons[w.Blueprint].Name..' • '..C.Rarities[w.Rarity].Name..(w.Mutation>1 and ' / '..C.Mutations[w.Mutation].Name or '') end
local function get(id) for _,w in ipairs(data.Inventory) do if w.Id==id then return w end end end
local function show(nextPage)
 page=nextPage; selected=nil; scroller.CanvasPosition=Vector2.new(0,0); panel.Visible=true; forgeButton.Visible=false; render()
 Tween:Create(panel,TweenInfo.new(.18),{BackgroundTransparency=0}):Play()
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
 if not compact then viewport(scroller,w,110) end
 row(tostring(E.value(data,w))..' coins  •  '..(w.Displayed and 'On display' or 'In inventory')..(w.Locked and '  •  Locked' or ''))
 local choices=make('Frame',scroller,{Size=UDim2.new(1,0,0,48),BackgroundTransparency=1})
 make('UIListLayout',choices,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)})
 local sell=button(choices,'SELL',function()
  if w.Locked or w.Displayed then notify('Store and unlock this weapon before selling.'); return end
  send('Sell',w.Id); selected=nil; reveal=nil; page='Inventory'
 end,true); sell.Size=UDim2.new(1/3,-4,0,46)
 local display=button(choices,w.Displayed and 'STORE' or 'DISPLAY',function() send('Display',w.Id); reveal=nil; page='Inventory' end); display.Size=UDim2.new(1/3,-4,0,46)
 local keep=button(choices,'KEEP',function() reveal=nil; page=nil; panel.Visible=false; forgeButton.Visible=true end); keep.Size=UDim2.new(1/3,-4,0,46)
 button(scroller,w.Locked and 'UNLOCK WEAPON' or 'LOCK — PROTECT FROM SELL / MERGE',function() send('Lock',w.Id) end)
 if compact then viewport(scroller,w,70) end
 row('Displayed weapons earn coins over time. Keep three of one rarity for Quick Merge.',12,muted)
end

local function inventory()
 if selected then local w=get(selected); if w then weaponActions(w); button(scroller,'← ALL WEAPONS',function() selected=nil; render() end); return end; selected=nil end
 row(#data.Inventory..' / '..data.Capacity..' stored  •  '..string.format('%.2f',data.Income)..' coins / sec')
 button(scroller,'QUICK MERGE — PREVIEW',function() send('MergePreview') end,true)
 if #data.Inventory==0 then row('Your next great weapon starts at the anvil. Forge one, then sell, keep or display it.',16) end
 local grid=make('Frame',scroller,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
 local columns=panel.AbsoluteSize.X<500 and 2 or 3
 make('UIGridLayout',grid,{CellSize=UDim2.new(1/columns,-8,0,216),CellPadding=UDim2.fromOffset(8,8),SortOrder=Enum.SortOrder.LayoutOrder})
 for _,w in ipairs(data.Inventory) do
  local card=make('Frame',grid,{BackgroundColor3=Color3.fromRGB(39,36,37)}); corner(card,8)
  viewport(card,w,112)
  local name=label(card,C.Weapons[w.Blueprint].Name,12); name.Position=UDim2.fromOffset(8,112); name.Size=UDim2.new(1,-16,0,30)
  local rarity=label(card,C.Rarities[w.Rarity].Name..(w.Mutation>1 and ' · '..C.Mutations[w.Mutation].Name or '')..(w.Locked and ' 🔒' or '')..(w.Displayed and ' ◈' or ''),11,Color3.fromRGB(unpack(C.Rarities[w.Rarity].Color))); rarity.Position=UDim2.fromOffset(8,140); rarity.Size=UDim2.new(1,-16,0,24)
  local b=button(card,E.value(data,w)..' coins  →',function() selected=w.Id; render() end); b.Position=UDim2.new(0,6,1,-48); b.Size=UDim2.new(1,-12,0,44); b.TextSize=12
 end
end
local function collection()
 local found=0; for _ in pairs(data.Collection) do found+=1 end
 row(found..' / 9 blueprints discovered  •  '..math.floor(found/9*100)..'%')
 local grid=make('Frame',scroller,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
 local cols=panel.AbsoluteSize.X<500 and 2 or 3
 make('UIGridLayout',grid,{CellSize=UDim2.new(1/cols,-8,0,172),CellPadding=UDim2.fromOffset(8,8)})
 for i,bp in ipairs(C.Weapons) do
  local discovered=data.Collection[tostring(i)]
  local card=make('Frame',grid,{BackgroundColor3=Color3.fromRGB(39,36,37)}); corner(card)
  viewport(card,{Blueprint=i,Rarity=1,Mutation=1},120,not discovered)
  local t=label(card,discovered and bp.Name or '???  •  '..C.Zones[bp.Zone].Name,12,discovered and text or muted); t.Position=UDim2.fromOffset(8,126); t.Size=UDim2.new(1,-16,0,40)
 end
end
local function upgrades()
 row('A better forge. A bigger collection.',16)
 for _,key in ipairs({'Speed','Value','Luck','Display','Capacity'}) do
  local u=C.Upgrades[key]; local level=data.Upgrades[key]
  row(u.Name..'  '..level..' / '..u.Max,17,warm); row(u.Description)
  button(scroller,level>=u.Max and 'MAX LEVEL' or 'UPGRADE  •  '..E.cost(key,level)..' coins',function() send('Upgrade',key) end,level<u.Max)
 end
 if data.Zone<3 then
  local zone=C.Zones[data.Zone+1]
  row('NEXT FORGE — '..string.upper(zone.Name),18,warm)
  row('Unlock three new weapon blueprints and transform your workshop. '..math.floor(math.min(1,data.Coins/zone.Cost)*100)..'% funded.')
  button(scroller,'UNLOCK  •  '..zone.Cost..' coins',function() send('Zone') end,true)
 else row('All three forges unlocked. Master your craft with Prestige.',16) end
 row('MASTER FORGE / PRESTIGE',18,warm)
 row('Requires Arcane Forge + 150,000 coins. Gain +25% permanent value per prestige. Review the reset before confirming.')
 button(scroller,'REVIEW PRESTIGE',function() send('PrestigePreview') end)
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
 row('Optional convenience. Every forge is free to unlock.',14,muted)
 local tabs=make('Frame',scroller,{Size=UDim2.new(1,0,0,46),BackgroundTransparency=1})
 make('UIListLayout',tabs,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})
 for _,tab in ipairs({'PERMANENT','COINS'}) do local b=button(tabs,tab,function() shopTab=tab; render() end,shopTab==tab); b.Size=UDim2.new(.5,-4,0,44) end
 local keys=shopTab=='PERMANENT' and {'AutoForge','AutoMerge','DoubleCoins','DisplaySlots','Starter'} or {'Small','Medium','Large'}
 for _,key in ipairs(keys) do
  local p=C.Monetization[key]; fetchPrice(key)
  row((p.Kind=='Pass' and '◈  ' or '◉  ')..p.Name,18,warm)
  row(p.Benefit or ('Approximately '..p.Minutes..' minutes of current active income. Now: '..E.coinPack(data,key)..' coins.'))
  local info=prices[key]
  local available=p.Id and info and info.PriceInRobux and info.IsForSale~=false and not data.Memory
  local copy=data.Owned[key] and 'OWNED' or available and ('BUY  •  R$ '..info.PriceInRobux) or 'UNAVAILABLE — NOT CONFIGURED'
  button(scroller,copy,function() if available and not data.Owned[key] then send('PurchasePrompt',key) else notify('This purchase is unavailable. Keep playing for free.') end end,available and not data.Owned[key])
 end
end
local function settings()
 for _,key in ipairs({'Music','SFX','LowVFX','CameraShake','AutoForge','AutoMerge'}) do
  button(scroller,key..'  •  '..(data.Settings[key] and 'ON' or 'OFF'),function() send('Setting',{Key=key,Value=not data.Settings[key]}) end)
 end
 row('Auto Merge consumes unlocked, stored weapons only. Result keeps the first input’s silhouette and mutation.',14,muted)
 button(scroller,'Auto Merge input limit: '..C.Rarities[data.Settings.MergeThreshold].Name,function() send('Setting',{Key='MergeThreshold',Value=data.Settings.MergeThreshold%5+1}) end)
 if data.Memory then row('LOCAL STUDIO TEST — progress is not saved. Purchases are disabled.',14,warm) end
 row('Music and sound hooks remain silent until approved audio IDs are configured.',13,muted)
end
render=function()
 if not data or not page then return end
 clear()
 title.Text=page=='Reveal' and 'FRESH FROM THE FORGE' or string.upper(page)
 if page=='Inventory' then inventory()
 elseif page=='Collection' then collection()
 elseif page=='Upgrades' then upgrades()
 elseif page=='Shop' then shop()
 elseif page=='Settings' then settings()
 elseif page=='Reveal' and reveal then
  local w=get(reveal.Id); if w then weaponActions(w) else page='Inventory'; render() end
 elseif page=='Merge' then
  row('THREE WEAPONS → ONE '..string.upper(C.Rarities[mergeRarity].Name),17,warm)
  local valid=true
  for i,id in ipairs(mergeItems) do local w=get(id); if w then row(i..'. '..itemName(w),14) else valid=false end end
  if valid then
   local first=get(mergeItems[1]); local result={Blueprint=first.Blueprint,Rarity=mergeRarity,Mutation=first.Mutation}
   viewport(scroller,result,130)
   row('Result: '..itemName(result)..'. All three inputs are permanently consumed.',14)
   button(scroller,'CONFIRM MERGE — CONSUME THESE 3',function() send('MergeConfirm',token); page='Inventory' end,true)
  else row('Items changed. Close and review a new merge.') end
 elseif page=='Prestige' then
  row('BECOME A MASTER FORGER',20,warm)
  row('RESETS: all coins, upgrade levels, zones AND every stored/displayed weapon. This cannot be undone.',16)
  row('KEEPS: discovered blueprints, lifetime stats, settings, purchases, cosmetic accent and prestige stars.',15)
  row('GAIN: +25% permanent weapon value and a small luck/speed bonus per prestige.',15)
  button(scroller,'I UNDERSTAND — FINAL CONFIRMATION',function()
   page='PrestigeConfirm'; render()
  end)
 elseif page=='PrestigeConfirm' then
  row('Your current weapons and economy will be reset.',18,warm)
  button(scroller,'RESET & PRESTIGE',function() send('PrestigeConfirm',prestigeToken); page='Upgrades' end,true)
  button(scroller,'CANCEL',function() show('Upgrades') end)
 end
end
for i,name in ipairs({'Inventory','Collection','Upgrades','Shop','Settings'}) do
 local b=button(nav,name,function() if data then if name=='Shop' then send('Shop') end; show(name) end end)
 b.LayoutOrder=i; b.Size=UDim2.new(.2,-5,1,0); b.TextSize=12
end
local tutorialCopy={
 [0]='1 / 5  •  FORGE YOUR FIRST WEAPON  —  tap the orange button',
 [1]='2 / 5  •  SELL your first weapon to earn coins',
 [2]='3 / 5  •  Open UPGRADES and buy Forge speed',
 [3]='4 / 5  •  FORGE a second weapon',
 [4]='5 / 5  •  DISPLAY your favorites for income. KEEP three to MERGE. Tap to begin!',
}
tutorial.Activated:Connect(function()
 if not data then return end
 if data.Tutorial==4 then send('TutorialDone')
 elseif data.Tutorial==2 then show('Upgrades')
 elseif data.Tutorial==1 then show('Inventory')
 elseif data.Tutorial<4 then send('Forge')
 else show('Upgrades') end
end)
local lastSignature=''
state.OnClientEvent:Connect(function(snapshot,event,result)
 if snapshot then
  data=snapshot; Effects.Settings=data.Settings
  local music=game:GetService('SoundService'):FindFirstChild('WFTMusic')
  if not music and C.Sounds.music then music=make('Sound',game:GetService('SoundService'),{Name='WFTMusic',SoundId='rbxassetid://'..C.Sounds.music,Looped=true,Volume=.2}) end
  if music then if data.Settings.Music and not music.IsPlaying then music:Play() elseif not data.Settings.Music then music:Pause() end end
  money.Text='◉ '..math.floor(data.Coins)..' COINS'
  progress.Text=C.Zones[data.Zone].Name..'\n★ '..data.Prestige..'   •   Speed '..data.Upgrades.Speed
  tutorial.Text=tutorialCopy[data.Tutorial] or (data.Zone<3 and ('NEXT: '..C.Zones[data.Zone+1].Name..'  •  '..math.floor(data.Coins)..' / '..C.Zones[data.Zone+1].Cost..' coins') or 'MASTER FORGE  •  150,000 coins + Arcane Forge')
  local signature=game:GetService('HttpService'):JSONEncode({data.Inventory,data.Upgrades,data.Settings,data.Zone,data.Owned})
  if page and signature~=lastSignature then render() end
  lastSignature=signature
 end
 if event=='error' then notify(result)
 elseif event=='welcome' and result and result>0 then notify('YOUR FORGE WORKED WHILE YOU WERE AWAY  + '..result..' coins')
 elseif event=='forge_start' then
  forgeGeneration+=1; local gen=forgeGeneration; forgeRunning=true; forgeButton.Text='HEATING METAL…  TAP TO HAMMER'
  Effects.sound('forge_fire')
  ForgeVisual.begin(rackPosition(),result,impact)
  forgeBar.Size=UDim2.new(0,0,0,4); Tween:Create(forgeBar,TweenInfo.new(result),{Size=UDim2.new(1,0,0,4)}):Play()
  task.spawn(function()
   for hit=1,3 do
    task.wait(result/4)
    if gen~=forgeGeneration or not forgeRunning then return end
    forgeButton.Text='HAMMER '..hit..' / 3  •  TAP TO SPEED UP'
   end
  end)
 elseif event=='hammer' then impact(false)
 elseif event=='reveal' then
  forgeRunning=false; forgeBar.Size=UDim2.new(0,0,0,4); forgeButton.Text='⚒  FORGE ANOTHER WEAPON'
  reveal=result; ForgeVisual.reveal(rackPosition(),result); impact(result.Rarity>=4); Effects.sound(result.Rarity>=5 and 'legendary_reveal' or 'rarity_reveal')
  if not data.Settings.AutoForge then show('Reveal') else notify(itemName(result)..'  •  Added to inventory') end
 elseif event=='merge_preview' then token=result.Token; mergeItems=result.Ids; mergeRarity=result.Rarity; show('Merge')
 elseif event=='prestige_preview' then prestigeToken=result; show('Prestige')
 elseif event=='Sell' then Effects.sound('coins'); notify('+ '..tostring(result)..' coins'); if page then render() end
 elseif event=='MergeConfirm' or event=='auto_merge' then impact(true); notify('MERGE COMPLETE'); if page then render() end
 elseif event=='Upgrade' then Effects.sound('upgrade'); notify('Forge upgraded'); if page then render() end
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
 if a and prompt.Parent==a then send(forgeRunning and 'Hammer' or 'Forge')
 elseif a and prompt:IsDescendantOf(a.Parent) then
  if prompt.Name=='InventoryPrompt' then show('Inventory') elseif prompt.Name=='UpgradePrompt' then show('Upgrades') end
 end
end)
CAS:BindAction('ForgeWeapon',function(_,input)
 if input==Enum.UserInputState.Begin and not panel.Visible then send(forgeRunning and 'Hammer' or 'Forge') end
 return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.ButtonR2)
CAS:BindAction('OpenArmory',function(_,input) if input==Enum.UserInputState.Begin and data then show('Inventory') end; return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.ButtonY)
CAS:BindAction('CloseForgeMenu',function(_,input) if input==Enum.UserInputState.Begin then page=nil; panel.Visible=false; forgeButton.Visible=true end; return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.ButtonB)
send('Ready')
task.spawn(function() while not data do task.wait(2); send('Ready') end end)
