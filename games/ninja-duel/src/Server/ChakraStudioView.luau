-- Optional Studio proxy renderer. Only draws its own folder; no camera/UI changes.
local S=require(script.Parent.ProfileSchema)
local View={};View.__index=View
local function vector(v) return Vector3.new(v.x,v.y,v.z) end
local colors={wind=Color3.fromRGB(120,255,200),fire=Color3.fromRGB(255,125,70),lightning=Color3.fromRGB(120,175,255),spatialAnchor=Color3.fromRGB(225,125,255)}
local function part(parent,name,size,cf,color)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.Neon;p.Parent=parent;return p
end
function View.new(cfg,origin)
 assert(game:GetService("RunService"):IsStudio(),"Studio only")
 local folder=Instance.new("Folder");folder.Name="NinjaDuelChakraLab";folder.Parent=workspace
 return setmetatable({cfg=cfg,folder=folder,origin=origin or Vector3.new(0,250,500),objects={},surfaces={}},View)
end
function View:reset()
 self.folder:ClearAllChildren();self.objects={};self.surfaces={}
end
function View:destroy() self.folder:Destroy() end
function View:object(o)
 local model=Instance.new("Model");model.Name=o.id.."_"..o.kind;model.Parent=self.folder
 local color=Color3.fromRGB(195,200,215)
 local root=part(model,"Root",Vector3.new(.14,.14,2),CFrame.new(),color);root.Transparency=1;model.PrimaryPart=root
 local shape=self.cfg.Objects[o.kind].visual
 if shape=="kunai" then
  part(model,"Blade",Vector3.new(.35,.15,1.25),CFrame.new(0,0,-.55),color)
  part(model,"Grip",Vector3.new(.18,.18,.65),CFrame.new(0,0,.4),color)
  local ring=part(model,"Ring",Vector3.new(.35,.12,.35),CFrame.new(0,0,.95),color);ring.Shape=Enum.PartType.Ball
 elseif shape=="shuriken" then
  for i=0,3 do part(model,"Blade"..i,Vector3.new(.2,.08,1.2),CFrame.Angles(0,math.pi*i/2,0)*CFrame.new(0,0,-.35),color) end
 elseif shape=="wire" then part(model,"Wire",Vector3.new(12,.06,.06),CFrame.new(),color)
 else part(model,"Target",Vector3.new(2,3,2),CFrame.new(),color) end
 local gui=Instance.new("BillboardGui");gui.Name="Tags";gui.Adornee=root;gui.Size=UDim2.fromOffset(420,64);gui.StudsOffset=Vector3.new(0,2,0);gui.AlwaysOnTop=true;gui.Parent=root
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=.3;label.BackgroundColor3=Color3.new(0,0,0);label.TextColor3=Color3.new(1,1,1);label.TextSize=14;label.TextWrapped=true;label.Parent=gui
 self.objects[o.id]={model=model,label=label}
 return self.objects[o.id]
end
function View:update(report)
 for id,entry in self.objects do if not report.objects[id] then entry.model:Destroy();self.objects[id]=nil end end
 for id,o in report.objects do
  local entry=self.objects[id] or self:object(o);local p=self.origin+vector(o.position)
  local direction=if vector(o.velocity).Magnitude>.01 then vector(o.velocity).Unit elseif o.anchor then -vector(o.anchor.normal) else Vector3.new(1,0,0)
  local up=if math.abs(direction.Y)>.95 then Vector3.zAxis else Vector3.yAxis
  entry.model:PivotTo(CFrame.lookAt(p,p+direction,up))
  local color=Color3.fromRGB(195,200,215);for _,tag in {"wind","fire","lightning","spatialAnchor"} do if o.tags[tag] then color=colors[tag] end end
  for _,child in entry.model:GetChildren() do if child:IsA("BasePart") then child.Color=color end end
  local active={};for tag in o.tags do table.insert(active,tag) end;table.sort(active)
  entry.label.Text=id.." / "..o.kind.." / "..o.mastery.."\n"..table.concat(active," · ")
 end
 for id,s in report.surfaces do
  if not self.surfaces[id] then
   local p=self.origin+vector(s.position);local n=vector(s.normal);local up=if math.abs(n.Y)>.95 then Vector3.zAxis else Vector3.yAxis
   local surface=part(self.folder,id,Vector3.new(s.radius*2,s.radius*2,.15),CFrame.lookAt(p,p+n,up),Color3.fromRGB(85,100,130));surface.Transparency=.6
   self.surfaces[id]=surface
  end
  if s.tags.ignited then self.surfaces[id].Color=colors.fire end
 end
end
return View
