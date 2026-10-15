local Shared=game.ReplicatedStorage.WFT
local C=require(Shared.Config)
local W=require(Shared.WeaponModel)
local E=require(Shared.Economy)
local B=require(Shared.Collection)
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
  local sell=part(m,'Sell counter',Vector3.new(6,2,3),base*CFrame.new(13,1,-7),wood,Enum.Material.Wood)
  label(sell,'ARMORY')
  local sellPrompt=Instance.new('ProximityPrompt'); sellPrompt.Name='InventoryPrompt'; sellPrompt.ActionText='Manage weapons'; sellPrompt.ObjectText='Sell • Keep • Display'; sellPrompt.Parent=sell
  local up=part(m,'Upgrade bench',Vector3.new(6,2,3),base*CFrame.new(13,1,1),stone)
  label(up,'UPGRADES')
  local upgradePrompt=Instance.new('ProximityPrompt'); upgradePrompt.Name='UpgradePrompt'; upgradePrompt.ActionText='Upgrade forge'; upgradePrompt.Parent=up
  for zone=2,3 do
   local gate=part(m,'Zone gate '..zone,Vector3.new(8,5,1),base*CFrame.new(zone==2 and 0 or 17,5,-23),Color3.fromRGB(55,49,47),Enum.Material.Metal)
   gate.Transparency=.92; gate.CanCollide=false
   local gateColor=Color3.fromRGB(unpack(C.Zones[zone].Color))
   for _,side in ipairs({-1,1}) do part(m,'Gateway pillar',Vector3.new(1.3,10,1.5),gate.CFrame*CFrame.new(side*4,0,0),stone,Enum.Material.Basalt) end
   part(m,'Gateway crown',Vector3.new(10,1.4,2),gate.CFrame*CFrame.new(0,5,0),gateColor,Enum.Material.Neon)
   local gatePrompt=Instance.new('ProximityPrompt'); gatePrompt.Name='UpgradePrompt'; gatePrompt.ActionText='View next forge'; gatePrompt.Parent=gate
   label(gate,C.Zones[zone].Name..'\n'..C.Zones[zone].Cost..' coins')
  end
  for _,pos in ipairs({Vector3.new(-18,1,0),Vector3.new(-16,1,7)}) do
   part(m,'Supply crate',Vector3.new(3,2,3),base*CFrame.new(pos),wood,Enum.Material.WoodPlanks)
  end
  -- Composition: forge left, hero vitrine right, next-zone vista behind.
  part(m,'Armory backboard',Vector3.new(12,7,1),base*CFrame.new(12,3.5,-14),wood,Enum.Material.WoodPlanks)
  part(m,'Armory crown',Vector3.new(14,.6,2),base*CFrame.new(12,7,-14),Color3.fromRGB(194,136,61),Enum.Material.Metal)
  part(m,'Quench vat',Vector3.new(3,2.5,3),base*CFrame.new(-9,1.25,-4),stone,Enum.Material.Metal)
  part(m,'Quench water',Vector3.new(2.6,.15,2.6),base*CFrame.new(-9,2.5,-4),Color3.fromRGB(80,160,186),Enum.Material.Glass)
  for j=1,4 do
   part(m,'Supply ingot',Vector3.new(1.7,.45,.8),base*CFrame.new(-16,1+j*.42,-1),Color3.fromRGB(157,170,179),Enum.Material.Metal)
  end
  for _,dx in ipairs({-20,20}) do
   local lamp=part(m,'Workshop lantern',Vector3.new(.8,1.3,.8),base*CFrame.new(dx,5,-4),Color3.fromRGB(255,192,92),Enum.Material.Neon)
   local light=Instance.new('PointLight'); light.Range=10; light.Brightness=.6; light.Color=lamp.Color; light.Parent=lamp
   part(m,'Lantern post',Vector3.new(.4,4,.4),base*CFrame.new(dx,2,-4),wood,Enum.Material.Wood)
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
   part(details,'Foundry back wall',Vector3.new(35,9,2),p.Base*CFrame.new(-2,4.5,-20),Color3.fromRGB(37,35,43),Enum.Material.Basalt)
   part(details,'Lava basin',Vector3.new(11,.2,8),p.Base*CFrame.new(-12,.1,-12),color,Enum.Material.Neon)
   for j=1,5 do part(details,'Magma channel',Vector3.new(.8,.08,15),p.Base*CFrame.new(-18+j*2,.05,-9),color,Enum.Material.Neon) end
   for _,x in ipairs({-18,-8}) do part(details,'Foundry exhaust',Vector3.new(2,9,2),p.Base*CFrame.new(x,4.5,-15),stone,Enum.Material.DiamondPlate) end
  elseif d.Zone==3 then
   for _,x in ipairs({-20,-3}) do part(details,'Arcane spire',Vector3.new(2,13,2),p.Base*CFrame.new(x,6.5,-16),Color3.fromRGB(59,55,88),Enum.Material.Marble); part(details,'Spire crown',Vector3.new(2.3,3,2.3),p.Base*CFrame.new(x,14,-16)*CFrame.Angles(0,0,.2),color,Enum.Material.Neon) end
   part(details,'Floating energy bridge',Vector3.new(20,1.3,3),p.Base*CFrame.new(-11.5,12,-16),color,Enum.Material.Neon)
   for j=1,5 do
    local crystal=part(details,'Arcane crystal',Vector3.new(1.2,3+j*.3,1.2),p.Base*CFrame.new(-19+j*2,2,-12)*CFrame.Angles(0,0,(j-3)*.12),color,Enum.Material.Neon)
    crystal.Shape=Enum.PartType.Cylinder
   end
   part(details,'Runic arch',Vector3.new(14,1,2),p.Base*CFrame.new(-12,8,-10),color,Enum.Material.Slate)
  end
 end
  local buildSignature=d.Zone..':'..d.Upgrades.Speed..':'..d.Upgrades.Luck..':'..E.slots(d)..':'..tostring(B.rewards(d).Skin)..tostring(B.rewards(d).Master)
 if p.BuildSignature~=buildSignature then
  p.BuildSignature=buildSignature
  local old=p.Model:FindFirstChild('PhysicalUpgrades'); if old then old:Destroy() end
  local f=Instance.new('Folder'); f.Name='PhysicalUpgrades'; f.Parent=p.Model
  local color=Color3.fromRGB(unpack(C.Zones[d.Zone].Color))
  local dark=Color3.fromRGB(43,45,55)
  if d.Upgrades.Speed>=5 or d.Zone>=2 then
   part(f,'Second burner',Vector3.new(4,5,5),p.Base*CFrame.new(-17,2.5,-12),dark,Enum.Material.DiamondPlate)
   part(f,'Second fire mouth',Vector3.new(2.5,2,.2),p.Base*CFrame.new(-17,2.3,-9.4),color,Enum.Material.Neon)
   part(f,'Steam stack',Vector3.new(1.4,9,1.4),p.Base*CFrame.new(-17,7,-13),dark,Enum.Material.Metal)
  end
  if d.Upgrades.Speed>=10 then
   for _,x in ipairs({-16,-8}) do part(f,'Reinforced forge column',Vector3.new(1,9,1),p.Base*CFrame.new(x,4.5,-11),dark,Enum.Material.DiamondPlate) end
   part(f,'Reinforced forge bridge',Vector3.new(10,1.3,2),p.Base*CFrame.new(-12,9,-11),dark,Enum.Material.DiamondPlate)
  end
  for j=1,math.min(d.Upgrades.Luck,6) do
   part(f,'Luck charm',Vector3.new(.5,.8,.25),p.Base*CFrame.new(-15+j,6.5,-9)*CFrame.Angles(0,0,math.pi/4),Color3.fromRGB(159,233,211),Enum.Material.Neon)
  end
  for slot=1,E.slots(d) do
   local x=slot==1 and 11 or 5.5+(slot-2)%3*4.5
   local z=slot==1 and -3 or -10-math.floor((slot-2)/3)*4
   part(f,'Display plinth '..slot,Vector3.new(slot==1 and 5 or 3.5,slot==1 and 1.8 or .8,3),p.Base*CFrame.new(x,slot==1 and .9 or .4,z),dark,Enum.Material.Marble)
   part(f,'Rarity rail '..slot,Vector3.new(slot==1 and 5.1 or 3.6,.15,3.1),p.Base*CFrame.new(x,slot==1 and 1.7 or .7,z),color,Enum.Material.Neon)
  end
  if B.rewards(d).Master then
   local aura=part(f,'Master forge aura',Vector3.new(10,.2,10),p.Base*CFrame.new(-12,6,-12),Color3.fromRGB(181,136,255),Enum.Material.Neon); aura.CanCollide=false; aura.Transparency=.45
   local sparkles=Instance.new('Sparkles'); sparkles.SparkleColor=aura.Color; sparkles.Parent=aura
  end
  if B.rewards(d).Skin then part(f,'Collector forge crest',Vector3.new(5,1.2,.3),p.Base*CFrame.new(-12,5.8,-9.3),Color3.fromRGB(122,230,209),Enum.Material.Neon) end
 end
 local signature=buildSignature
 for _,w in ipairs(d.Inventory) do if w.Displayed then signature..=w.Id end end
 if signature~=p.Signature then
  p.Signature=signature; p.Racks:ClearAllChildren(); local slot=0
  local display={}; for _,w in ipairs(d.Inventory) do if w.Displayed then table.insert(display,w) end end
  table.sort(display,function(a,b) return E.value(d,a)>E.value(d,b) end)
  for _,w in ipairs(display) do
   slot+=1
   local x=slot==1 and 11 or 5.5+(slot-2)%3*4.5
   local z=slot==1 and -3 or -10-math.floor((slot-2)/3)*4
   local model=W.build(w,p.Racks,p.Base*CFrame.new(x,slot==1 and 4.8 or 3.1,z)*CFrame.Angles(0,0,math.rad(-12)),slot==1 and 1.1 or .65)
   local anchor=model:FindFirstChildWhichIsA('BasePart')
   anchor:SetAttribute('OwnerId',player.UserId); anchor:SetAttribute('WeaponId',w.Id)
   local inspect=Instance.new('ProximityPrompt'); inspect.Name='InspectPrompt'; inspect.ActionText='Inspect weapon'; inspect.ObjectText=player.DisplayName..'’s armory'; inspect.MaxActivationDistance=12; inspect.RequiresLineOfSight=false; inspect.Parent=anchor
   label(anchor,C.Weapons[w.Blueprint].Name..'\n'..C.Rarities[w.Rarity].Name..(w.Mutation>1 and ' • '..C.Mutations[w.Mutation].Name or ''),Color3.fromRGB(unpack(C.Rarities[w.Rarity].Color)))
  end
 end
 local equipped=E.equipped(d)
 local character=player.Character
 if character and character:GetAttribute('ShownWeapon')~=(d.Equipped or '') then
  character:SetAttribute('ShownWeapon',d.Equipped or '')
  local old=character:FindFirstChild('EquippedForgeWeapon'); if old then old:Destroy() end
  local torso=character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso')
  if equipped and torso then
   local model=W.build(equipped,character,torso.CFrame*CFrame.new(.8,0,.65)*CFrame.Angles(0,0,-.5),.6); model.Name='EquippedForgeWeapon'
   for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then part.Anchored=false; part.Massless=true; local weld=Instance.new('WeldConstraint'); weld.Part0=torso; weld.Part1=part; weld.Parent=part end end
  end
 end
 local accent=p.Model:FindFirstChild('Founder accent')
 if d.Owned.Starter and not accent then part(p.Model,'Founder accent',Vector3.new(7,.25,5),p.Base*CFrame.new(-12,5.15,-12),Color3.fromRGB(235,188,85),Enum.Material.Metal) end
 p.Owner.Text=(B.rewards(d).Master and 'MASTER • ' or B.rewards(d).Title and 'COLLECTOR • ' or '')..player.DisplayName..'’s '..C.Zones[d.Zone].Name..(d.Prestige>0 and ' ★'..d.Prestige or '')
end
function P.release(player)
 local p=P.Plots[player:GetAttribute('Plot') or 0]; if p then p.Player=nil; p.Owner.Text='Unclaimed workshop'; p.Racks:ClearAllChildren(); p.Signature=''; p.Zone=0; p.BuildSignature=nil; local upgrades=p.Model:FindFirstChild('PhysicalUpgrades'); if upgrades then upgrades:Destroy() end; local equipped=E.equipped(d)
 local character=player.Character
 if character and character:GetAttribute('ShownWeapon')~=(d.Equipped or '') then
  character:SetAttribute('ShownWeapon',d.Equipped or '')
  local old=character:FindFirstChild('EquippedForgeWeapon'); if old then old:Destroy() end
  local torso=character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso')
  if equipped and torso then
   local model=W.build(equipped,character,torso.CFrame*CFrame.new(.8,0,.65)*CFrame.Angles(0,0,-.5),.6); model.Name='EquippedForgeWeapon'
   for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then part.Anchored=false; part.Massless=true; local weld=Instance.new('WeldConstraint'); weld.Part0=torso; weld.Part1=part; weld.Parent=part end end
  end
 end
 local accent=p.Model:FindFirstChild('Founder accent'); if accent then accent:Destroy() end; local details=p.Model:FindFirstChild('ZoneDetails'); if details then details:Destroy() end end
end
return P
