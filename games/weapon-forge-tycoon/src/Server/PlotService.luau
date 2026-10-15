local Shared=game.ReplicatedStorage.WFT
local C=require(Shared.Config)
local W=require(Shared.WeaponModel)
local P={Plots={}}
local stone=Color3.fromRGB(103,108,115)
local wood=Color3.fromRGB(89,56,40)
local function part(parent,name,size,cf,color,material)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color; p.Material=material or Enum.Material.Slate; p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent; return p
end
local function label(p,text,color)
 local gui=Instance.new('BillboardGui'); gui.Size=UDim2.fromOffset(220,54); gui.StudsOffset=Vector3.new(0,3,0); gui.MaxDistance=36; gui.Parent=p
 local t=Instance.new('TextLabel'); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextSize=16; t.TextColor3=color or Color3.fromRGB(255,231,192); t.TextStrokeTransparency=.35; t.Text=text; t.Parent=gui
 return t
end
function P.init()
 local root=Instance.new('Folder'); root.Name='ForgeAndFlex'; root.Parent=workspace; P.Root=root
 part(root,'Island foundation',Vector3.new(200,5,190),CFrame.new(0,-3,0),Color3.fromRGB(47,58,54))
 part(root,'Village square',Vector3.new(45,.3,130),CFrame.new(0,-.25,0),Color3.fromRGB(104,96,82),Enum.Material.Cobblestone)
 for i=-2,2 do part(root,'Path inlay',Vector3.new(.3,.1,120),CFrame.new(i*6,0,0),Color3.fromRGB(144,128,99)) end
 local monument=part(root,'Forge & Flex',Vector3.new(9,4,7),CFrame.new(0,2,0),stone)
 label(monument,'FORGE & FLEX\nCraft • Collect • Become a master')
 W.build({Blueprint=9,Rarity=5,Mutation=4},root,CFrame.new(0,8,0),1.8)
 for _,x in ipairs({-90,90}) do for _,z in ipairs({-78,-26,26,78}) do
  part(root,'Tree trunk',Vector3.new(2,7,2),CFrame.new(x,3,z),wood,Enum.Material.Wood)
  local crown=part(root,'Low-poly canopy',Vector3.new(10,10,10),CFrame.new(x,10,z),Color3.fromRGB(60,90,66),Enum.Material.Grass); crown.Shape=Enum.PartType.Ball
 end end
 part(root,'Island edge',Vector3.new(210,2,200),CFrame.new(0,-5,0),Color3.fromRGB(66,83,77))
 for i=1,6 do
  local x=i<=3 and -52 or 52; local z=((i-1)%3-1)*53
  local m=Instance.new('Model'); m.Name='Workshop '..i; m.Parent=root
  local base=CFrame.new(x,0,z)*(x>0 and CFrame.Angles(0,math.pi,0) or CFrame.new())
  local floor=part(m,'Workshop stone',Vector3.new(46,1,46),base*CFrame.new(0,-.5,0),Color3.fromRGB(105,98,84),Enum.Material.Cobblestone)
  for _,dx in ipairs({-21,21}) do
   part(m,'Timber post',Vector3.new(1.3,10,1.3),base*CFrame.new(dx,5,-19),wood,Enum.Material.Wood)
   part(m,'Stone curb',Vector3.new(1,1,44),base*CFrame.new(dx,0,0),stone)
  end
  for _,side in ipairs({-1,1}) do
   part(m,'Sloped workshop awning',Vector3.new(12,.6,13),base*CFrame.new(side*5.5,11,-14)*CFrame.Angles(0,0,side*math.rad(-17)),Color3.fromRGB(84,59,52),Enum.Material.WoodPlanks)
  end
  part(m,'Timber lintel',Vector3.new(44,1.2,1.4),base*CFrame.new(0,10,-19),wood,Enum.Material.Wood)
  local owner=label(m:FindFirstChild('Timber lintel'),'Unclaimed workshop')
  owner.Parent.StudsOffset=Vector3.new(0,1,0)
  local forge=part(m,'Furnace',Vector3.new(7,5,5),base*CFrame.new(-12,2.5,-12),stone,Enum.Material.Brick)
  part(m,'Chimney',Vector3.new(2.5,7,2.8),base*CFrame.new(-12,8,-13),stone,Enum.Material.Brick)
  local heat=part(m,'Hot coals',Vector3.new(5,2.4,.15),base*CFrame.new(-12,2.3,-9.4),Color3.fromRGB(255,123,48),Enum.Material.Neon)
  local light=Instance.new('PointLight'); light.Color=heat.Color; light.Range=17; light.Brightness=1.8; light.Parent=heat
  local anvil=part(m,'Anvil',Vector3.new(4,1.1,2),base*CFrame.new(-4,2,-6),Color3.fromRGB(84,91,101),Enum.Material.Metal)
  part(m,'Anvil pedestal',Vector3.new(2.5,1.5,2.5),base*CFrame.new(-4,.75,-6),wood,Enum.Material.Wood)
  local horn=Instance.new('WedgePart'); horn.Size=Vector3.new(2,1,2); horn.CFrame=base*CFrame.new(-7,2,-6)*CFrame.Angles(0,0,math.pi); horn.Color=anvil.Color; horn.Anchored=true; horn.Parent=m
  local prompt=Instance.new('ProximityPrompt'); prompt.Name='ForgePrompt'; prompt.ActionText='Forge a weapon'; prompt.ObjectText='Your anvil'; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX; prompt.HoldDuration=0; prompt.Parent=anvil
  local racks=Instance.new('Folder'); racks.Name='DisplayedWeapons'; racks.Parent=m
  for slot=1,6 do
   local dx=(slot-3.5)*5.6
   part(m,'Display plinth '..slot,Vector3.new(4,.7,3),base*CFrame.new(dx,.35,-18),wood,Enum.Material.Wood)
  end
  local sell=part(m,'Sell counter',Vector3.new(6,2,3),base*CFrame.new(13,1,-7),wood,Enum.Material.Wood)
  label(sell,'SELL / KEEP / DISPLAY')
  local sellPrompt=Instance.new('ProximityPrompt'); sellPrompt.Name='InventoryPrompt'; sellPrompt.ActionText='Manage weapons'; sellPrompt.ObjectText='Sell • Keep • Display'; sellPrompt.Parent=sell
  local up=part(m,'Upgrade bench',Vector3.new(6,2,3),base*CFrame.new(13,1,1),stone)
  label(up,'UPGRADE YOUR FORGE')
  local upgradePrompt=Instance.new('ProximityPrompt'); upgradePrompt.Name='UpgradePrompt'; upgradePrompt.ActionText='Upgrade forge'; upgradePrompt.Parent=up
  for zone=2,3 do
   local gate=part(m,'Zone gate '..zone,Vector3.new(8,5,1),base*CFrame.new(zone==2 and -11 or 10,2.5,18),Color3.fromRGB(55,49,47),Enum.Material.Metal)
   local gatePrompt=Instance.new('ProximityPrompt'); gatePrompt.Name='UpgradePrompt'; gatePrompt.ActionText='View next forge'; gatePrompt.Parent=gate
   label(gate,C.Zones[zone].Name..'\n'..C.Zones[zone].Cost..' coins')
  end
  for _,pos in ipairs({Vector3.new(-18,1,0),Vector3.new(-16,1,7)}) do
   part(m,'Supply crate',Vector3.new(3,2,3),base*CFrame.new(pos),wood,Enum.Material.WoodPlanks)
  end
  local spawn=Instance.new('SpawnLocation'); spawn.Name='Workshop spawn'; spawn.Size=Vector3.new(4,.2,4); spawn.CFrame=base*CFrame.new(-4,.15,3); spawn.Transparency=1; spawn.CanCollide=false; spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0; spawn.Parent=m
  P.Plots[i]={Spawn=spawn,Model=m,Base=base,Owner=owner,Forge=forge,Heat=heat,Light=light,Racks=racks,Anvil=anvil,Zone=0,Signature=''}
 end
 local lighting=game:GetService('Lighting'); lighting.ClockTime=16; lighting.Brightness=2.5; lighting.Ambient=Color3.fromRGB(119,112,102); lighting.OutdoorAmbient=Color3.fromRGB(138,143,155); lighting.GlobalShadows=true
 local bloom=Instance.new('BloomEffect'); bloom.Intensity=.18; bloom.Size=18; bloom.Threshold=1.5; bloom.Parent=lighting
 local correction=Instance.new('ColorCorrectionEffect'); correction.Saturation=.08; correction.Contrast=.06; correction.Parent=lighting
 local atmosphere=Instance.new('Atmosphere'); atmosphere.Density=.22; atmosphere.Color=Color3.fromRGB(226,207,181); atmosphere.Decay=Color3.fromRGB(133,130,150); atmosphere.Parent=lighting
end
function P.assign(player)
 for i,p in ipairs(P.Plots) do if not p.Player then p.Player=player; player.RespawnLocation=p.Spawn; p.Owner.Text=player.DisplayName..'’s forge'; player:SetAttribute('Plot',i); return p end end
end
function P.spawn(player,character)
 local p=P.Plots[player:GetAttribute('Plot') or 0]; if not p then return end
 local root=character:WaitForChild('HumanoidRootPart',10)
 if root then task.wait(.25); if not character.Parent then return end; character:PivotTo(p.Base*CFrame.new(-4,4,3)) end
end
function P.update(player,d)
 local p=P.Plots[player:GetAttribute('Plot') or 0]; if not p then return end
 if p.Zone~=d.Zone then
  p.Zone=d.Zone
  local old=p.Model:FindFirstChild('ZoneDetails'); if old then old:Destroy() end
  local details=Instance.new('Folder'); details.Name='ZoneDetails'; details.Parent=p.Model
  local color=Color3.fromRGB(unpack(C.Zones[d.Zone].Color)); p.Heat.Color=color; p.Light.Color=color
  p.Forge.Material=d.Zone==1 and Enum.Material.Brick or Enum.Material.Basalt
  if d.Zone==2 then
   for j=1,5 do part(details,'Magma channel',Vector3.new(.8,.08,15),p.Base*CFrame.new(-18+j*2,.05,-9),color,Enum.Material.Neon) end
   for _,x in ipairs({-18,-8}) do part(details,'Foundry exhaust',Vector3.new(2,9,2),p.Base*CFrame.new(x,4.5,-15),stone,Enum.Material.DiamondPlate) end
  elseif d.Zone==3 then
   for j=1,5 do
    local crystal=part(details,'Arcane crystal',Vector3.new(1.2,3+j*.3,1.2),p.Base*CFrame.new(-19+j*2,2,-12)*CFrame.Angles(0,0,(j-3)*.12),color,Enum.Material.Neon)
    crystal.Shape=Enum.PartType.Cylinder
   end
   part(details,'Runic arch',Vector3.new(14,1,2),p.Base*CFrame.new(-12,8,-10),color,Enum.Material.Slate)
  end
 end
 local signature=''
 for _,w in ipairs(d.Inventory) do if w.Displayed then signature..=w.Id end end
 if signature~=p.Signature then
  p.Signature=signature; p.Racks:ClearAllChildren(); local slot=0
  for _,w in ipairs(d.Inventory) do if w.Displayed then
   slot+=1
   local model=W.build(w,p.Racks,p.Base*CFrame.new((slot-3.5)*5.6,3.3,-18),.8)
   local anchor=model:FindFirstChildWhichIsA('BasePart')
   label(anchor,C.Weapons[w.Blueprint].Name..'\n'..C.Rarities[w.Rarity].Name..(w.Mutation>1 and ' • '..C.Mutations[w.Mutation].Name or ''),Color3.fromRGB(unpack(C.Rarities[w.Rarity].Color)))
  end end
 end
 local accent=p.Model:FindFirstChild('Founder accent')
 if d.Owned.Starter and not accent then part(p.Model,'Founder accent',Vector3.new(7,.25,5),p.Base*CFrame.new(-12,5.15,-12),Color3.fromRGB(235,188,85),Enum.Material.Metal) end
 p.Owner.Text=player.DisplayName..'’s '..C.Zones[d.Zone].Name..(d.Prestige>0 and ' ★'..d.Prestige or '')
end
function P.release(player)
 local p=P.Plots[player:GetAttribute('Plot') or 0]; if p then p.Player=nil; p.Owner.Text='Unclaimed workshop'; p.Racks:ClearAllChildren(); p.Signature=''; p.Zone=0; local accent=p.Model:FindFirstChild('Founder accent'); if accent then accent:Destroy() end; local details=p.Model:FindFirstChild('ZoneDetails'); if details then details:Destroy() end end
end
return P
