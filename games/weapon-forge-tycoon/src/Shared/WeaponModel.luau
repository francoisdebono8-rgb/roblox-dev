local C=require('./Config')
local W={}
local function rgb(a) return Color3.fromRGB(a[1],a[2],a[3]) end
function W.build(w,parent,cf,scale,silhouette)
 local bp=C.Weapons[w.Blueprint]; local model=Instance.new('Model'); model.Name=bp.Name
 local metal=silhouette and Color3.fromRGB(44,45,49) or rgb(C.Rarities[w.Rarity].Color)
 local glow=not silhouette and w.Mutation>1 and rgb(C.Mutations[w.Mutation].Color) or metal
 scale=scale or 1; cf=cf or CFrame.new()
 local function part(name,size,pos,color,shape,angle,material)
  local p=Instance.new(shape=='Wedge' and 'WedgePart' or 'Part'); p.Name=name
  p.Size=size*scale; p.CFrame=cf*CFrame.new(pos*scale)*(angle or CFrame.new())
  p.Color=color; p.Material=material or Enum.Material.Metal
  if shape=='Cylinder' then p.Shape=Enum.PartType.Cylinder end
  p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=true; p.Parent=model; return p
 end
 local brown=silhouette and metal or Color3.fromRGB(82,45,35)
 part('Leather grip',Vector3.new(.22,1.2,.25),Vector3.new(0,-1.2,0),brown)
 part('Pommel',Vector3.new(.4,.3,.36),Vector3.new(0,-1.88,0),metal)
 local shape=bp.Shape
 if shape=='Hammer' then
  part('Haft',Vector3.new(.25,2,.25),Vector3.new(0,.1,0),brown)
  part('Forged head',Vector3.new(2.2,1.1,.9),Vector3.new(0,1.45,0),metal)
  for _,x in ipairs({-1.15,1.15}) do part('Ember face',Vector3.new(.12,.85,.7),Vector3.new(x,1.45,0),glow,nil,nil,Enum.Material.Neon) end
 elseif shape=='Axe' or shape=='Scythe' then
  part('Long haft',Vector3.new(.23,3,.23),Vector3.new(0,.5,0),brown)
  part('Blade',Vector3.new(shape=='Scythe' and 2.3 or 1.2,1.1,.22),Vector3.new(.65,1.8,0),metal,'Wedge',CFrame.Angles(0,math.pi/2,0))
  if shape=='Axe' then part('Back blade',Vector3.new(.9,.8,.22),Vector3.new(-.55,1.8,0),metal,'Wedge',CFrame.Angles(0,-math.pi/2,0))
  else part('Hook tip',Vector3.new(.22,1,.22),Vector3.new(1.8,1.2,0),glow,'Wedge') end
 else
  local length=shape=='Dagger' and 1.5 or shape=='Shortsword' and 2.2 or shape=='Greatsword' and 3.7 or 3.1
  local width=(shape=='Greatsword' or shape=='Runic') and .8 or shape=='Katana' and .25 or .45
  part('Guard',Vector3.new(shape=='Dagger' and .8 or 1.25,.18,.34),Vector3.new(0,-.5,0),metal)
  local lean=(shape=='Saber' or shape=='Katana') and -.13 or 0
  part('Blade',Vector3.new(width,length,.18),Vector3.new(.1,length/2-.4,0),metal,nil,CFrame.Angles(0,0,lean))
  part('Edge point',Vector3.new(width,.65,.18),Vector3.new(.1-lean*length/2,length-.1,0),metal,'Wedge',CFrame.Angles(0,math.pi/2,0))
  if shape=='Runic' then
   for i=1,4 do part('Rune',Vector3.new(.18,.18,.20),Vector3.new(.1,i*.6,0),glow,nil,CFrame.Angles(0,0,math.pi/4),Enum.Material.Neon) end
  elseif shape=='Saber' then part('Knuckle bow',Vector3.new(.15,1,.2),Vector3.new(.5,-1,0),metal) end
 end
 if not silhouette and (w.Rarity>=4 or w.Mutation>1) then
  local p=model:FindFirstChild('Blade') or model:FindFirstChild('Forged head')
  if p then local l=Instance.new('PointLight'); l.Color=glow; l.Range=5; l.Brightness=.35; l.Parent=p end
 end
 model.Parent=parent
 return model
end
return W
