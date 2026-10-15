local Shared=game.ReplicatedStorage.WFT
local C=require(Shared.Config)
local E=require(Shared.Economy)
local A=require(Shared.Actions)
local World={}
local function part(parent,name,size,pos,color,material)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Position=pos; p.Color=color; p.Material=material or Enum.Material.Slate; p.Anchored=true; p.Parent=parent; return p
end
local function sign(p,copy,color,distance)
 local gui=Instance.new('BillboardGui'); gui.Size=UDim2.fromOffset(260,76); gui.StudsOffset=Vector3.new(0,5,0); gui.MaxDistance=distance or 120; gui.Parent=p
 local t=Instance.new('TextLabel'); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=copy; t.Font=Enum.Font.GothamBlack; t.TextSize=20; t.TextColor3=color; t.TextStrokeTransparency=.15; t.TextWrapped=true; t.Parent=gui
end
function World.init(Plot,Data,push)
 local folder=Instance.new('Folder'); folder.Name='Destinations'; folder.Parent=Plot.Root
 local market=part(folder,'Market Board',Vector3.new(18,10,2),Vector3.new(0,6,28),Color3.fromRGB(30,40,70),Enum.Material.WoodPlanks)
 sign(market,'PLAYER MARKET\nList • Buy • 8% tax',Color3.fromRGB(255,205,88))
 for _,x in ipairs({-10,10}) do part(folder,'Market pillar',Vector3.new(2,14,3),Vector3.new(x,7,28),Color3.fromRGB(139,92,54),Enum.Material.Wood) end
 local crown=part(folder,'Market crown',Vector3.new(24,1,4),Vector3.new(0,13,28),Color3.fromRGB(255,187,72),Enum.Material.Neon); crown.CanCollide=false
 local prompt=Instance.new('ProximityPrompt'); prompt.Name='MarketPrompt'; prompt.ActionText='Browse player weapons'; prompt.ObjectText='SERVER MARKET'; prompt.MaxActivationDistance=16; prompt.RequiresLineOfSight=false; prompt.Parent=market
 for _,x in ipairs({-12,12}) do
  local stall=part(folder,'Trading stall',Vector3.new(7,3,4),Vector3.new(x,1.5,17),Color3.fromRGB(81,65,54),Enum.Material.WoodPlanks)
  part(folder,'Stall awning',Vector3.new(8,.5,5),stall.Position+Vector3.new(0,4,0),Color3.fromRGB(54,142,156),Enum.Material.Fabric)
 end
 for zone=1,3 do
  local center=Vector3.new((zone-2)*70,0,-123)
  local color=Color3.fromRGB(unpack(C.Zones[zone].Color))
  part(folder,'Resource island '..zone,Vector3.new(62,5,57),center+Vector3.new(0,-3,0),zone==1 and Color3.fromRGB(75,98,67) or zone==2 and Color3.fromRGB(47,39,41) or Color3.fromRGB(60,54,85))
  local bridge=part(folder,'Resource bridge '..zone,Vector3.new(10,.8,40),center+Vector3.new(0,-.2,43),Color3.fromRGB(112,94,72),Enum.Material.WoodPlanks)
  local gate=part(folder,'Destination '..zone,Vector3.new(26,1.5,3),center+Vector3.new(0,11,21),color,Enum.Material.Neon)
  for _,side in ipairs({-1,1}) do part(folder,'Destination arch',Vector3.new(2,12,3),center+Vector3.new(side*12,5.5,21),Color3.fromRGB(81,74,75)) end
  sign(gate,(zone==1 and 'VILLAGE MINE' or string.upper(C.Zones[zone].Name))..'\n'..(zone==1 and 'IRON • STEEL' or 'UNLOCK '..C.Zones[zone].Cost..' COINS'),color,180)
  for j=1,7 do
   local rock=part(folder,'Rock ridge',Vector3.new(7+j%3*2,7+j%4*2,7),center+Vector3.new((j-4)*8,3,-23),Color3.fromRGB(70,68,73),Enum.Material.Rock)
   rock.CFrame*=CFrame.Angles(.1,j*.5,.2)
  end
  if zone==2 then
   for j=1,4 do local lava=part(folder,'Lava seam',Vector3.new(2,.15,28),center+Vector3.new(-25+j*10,.1,-4),color,Enum.Material.Neon); lava.CanCollide=false end
  elseif zone==3 then
   for _,x in ipairs({-22,22}) do part(folder,'Ruined column',Vector3.new(4,14,4),center+Vector3.new(x,7,-5),Color3.fromRGB(86,79,114),Enum.Material.Marble) end
  end
 end
 local cooldowns={}
 for material,m in ipairs(C.Materials) do
  local center=Vector3.new((m.Zone-2)*70,0,-123)
  -- Material identities get separate silhouettes, paired deposits for starter and magma.
  local x=(material==1 or material==3) and -11 or 11
  if material==5 then x=0 end
  local node=part(folder,m.Name..' deposit',Vector3.new(6,5,6),center+Vector3.new(x,2.5,0),Color3.fromRGB(unpack(m.Color)),material>=4 and Enum.Material.Neon or Enum.Material.Metal)
  node.CFrame*=CFrame.Angles(0,.3,.15)
  sign(node,string.upper(m.Name)..'\nCOLLECT → RETURN TO FORGE',Color3.fromRGB(255,240,211),55)
  for j=1,4 do part(folder,'Ore shard',Vector3.new(1.3,3+j%2,1.3),node.Position+Vector3.new(math.cos(j*1.57)*3,1,math.sin(j*1.57)*3),node.Color,material>=4 and Enum.Material.Neon or Enum.Material.Metal) end
  local p=Instance.new('ProximityPrompt'); p.Name='CollectPrompt'; p.ActionText='Collect '..m.Name; p.ObjectText='Requires '..C.Zones[m.Zone].Name; p.HoldDuration=1; p.MaxActivationDistance=12; p.RequiresLineOfSight=false; p.Parent=node
  p.Triggered:Connect(function(player)
   local s=Data.Sessions[player]; local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
   if not s or s.Busy or s.MarketBusy or s.Closing or not root or (root.Position-node.Position).Magnitude>14 then return end
   cooldowns[player]=cooldowns[player] or {}
   local now=os.clock(); local untilTime=cooldowns[player][material] or 0
   if now<untilTime then push(player,'error','Deposit recovering: '..math.ceil(untilTime-now)..'s'); return end
   local ok,n,delay=A.collect(s.Data,material,os.time())
   if ok then cooldowns[player][material]=now+delay; push(player,'collected',{Material=material,Amount=n}) else push(player,'error',n) end
  end)
 end
 game:GetService('Players').PlayerRemoving:Connect(function(player) cooldowns[player]=nil end)
 World.Boards={}
 for i,copy in ipairs({'HIGHEST WEAPON VALUE','TOTAL MARKET SALES','PRESTIGE'}) do
  local board=part(folder,copy,Vector3.new(15,8,1),Vector3.new((i-2)*17,5,62),Color3.fromRGB(31,35,54),Enum.Material.WoodPlanks)
  local gui=Instance.new('SurfaceGui'); gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(600,360); gui.Parent=board
  local t=Instance.new('TextLabel'); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.TextColor3=Color3.fromRGB(255,229,159); t.TextSize=28; t.Font=Enum.Font.GothamBold; t.Text=copy..'\nThis server'; t.Parent=gui
  World.Boards[i]=t
 end
end
function World.update(Data)
 for i,key in ipairs({'BestValue','MarketSales','Prestige'}) do
  local rows={}
  for player,s in pairs(Data.Sessions) do table.insert(rows,{Name=player.DisplayName,Value=key=='Prestige' and s.Data.Prestige or s.Data.Stats[key] or 0}) end
  table.sort(rows,function(a,b) return a.Value>b.Value end)
  local lines={({'HIGHEST WEAPON VALUE','TOTAL MARKET SALES','PRESTIGE'})[i]..'\nTHIS SERVER'}
  for rank,v in ipairs(rows) do table.insert(lines,rank..'. '..v.Name..'   '..math.floor(v.Value)) end
  if World.Boards[i] then World.Boards[i].Text=table.concat(lines,'\n') end
 end
end
return World
