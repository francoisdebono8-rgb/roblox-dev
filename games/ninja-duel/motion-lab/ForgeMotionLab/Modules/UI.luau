-- Visual thesis: a quiet slate motion workspace with a large lit R15 canvas.
-- Content: source collection, live body, contextual mixer/DNA, editable phrase.
-- Interaction: fast preview, restrained hover, selected blocks and immediate sliders.
local UI={}
local studio=settings().Studio
local function palette()
 local light=studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground).R>.6
 return if light then {bg=Color3.fromRGB(244,246,249),panel=Color3.fromRGB(235,239,244),hover=Color3.fromRGB(221,229,239),text=Color3.fromRGB(28,39,54),muted=Color3.fromRGB(96,112,132),line=Color3.fromRGB(208,217,228),accent=Color3.fromRGB(55,113,174),onAccent=Color3.new(1,1,1),canvas=Color3.fromRGB(224,233,243)} else {bg=Color3.fromRGB(22,28,37),panel=Color3.fromRGB(29,37,49),hover=Color3.fromRGB(43,56,73),text=Color3.fromRGB(232,239,247),muted=Color3.fromRGB(144,162,184),line=Color3.fromRGB(47,61,79),accent=Color3.fromRGB(104,181,230),onAccent=Color3.fromRGB(15,30,43),canvas=Color3.fromRGB(21,30,43)}
end
function UI.new(widget)
 local self={widget=widget,colors=palette(),styles=setmetatable({}, {__mode="k"}),connections={}}
 function self:connect(signal,fn) local c=signal:Connect(fn);table.insert(self.connections,c);return c end
 function self:paint(obj,property,role) obj[property]=self.colors[role];self.styles[obj]=self.styles[obj] or {};self.styles[obj][property]=role end
 function self:make(class,parent,props)
  local obj=Instance.new(class);for k,v in props or {} do obj[k]=v end;obj.Parent=parent;return obj
 end
 function self:frame(parent,props,role) local f=self:make("Frame",parent,props);f.BorderSizePixel=0;self:paint(f,"BackgroundColor3",role or "bg");return f end
 function self:label(parent,text,props,role)
  local t=self:make("TextLabel",parent,{Text=text,BackgroundTransparency=1,TextSize=14,Font=Enum.Font.BuilderSans,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
  self:paint(t,"TextColor3",role or "text");for k,v in props or {} do t[k]=v end;return t
 end
 function self:button(parent,text,props,fn,primary)
  local b=self:make("TextButton",parent,{Text=text,TextSize=13,Font=Enum.Font.BuilderSansMedium,BorderSizePixel=0,AutoButtonColor=false})
  self:paint(b,"BackgroundColor3",primary and "accent" or "panel");self:paint(b,"TextColor3",primary and "onAccent" or "text")
  self:make("UICorner",b,{CornerRadius=UDim.new(0,5)});for k,v in props or {} do b[k]=v end
  self:connect(b.MouseEnter,function() if not primary then b.BackgroundColor3=self.colors.hover end end);self:connect(b.MouseLeave,function() b.BackgroundColor3=self.colors[primary and "accent" or "panel"] end)
  if fn then self:connect(b.Activated,fn) end;return b
 end
 function self:input(parent,text,props,callback)
  local b=self:make("TextBox",parent,{Text=text,ClearTextOnFocus=false,TextSize=13,Font=Enum.Font.BuilderSans,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left})
  self:paint(b,"BackgroundColor3","panel");self:paint(b,"TextColor3","text");self:paint(b,"PlaceholderColor3","muted");self:make("UICorner",b,{CornerRadius=UDim.new(0,5)});self:make("UIPadding",b,{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9)})
  for k,v in props or {} do b[k]=v end;if callback then self:connect(b.FocusLost,function()callback(b.Text)end) end;return b
 end
 function self:scroll(parent,props)
  local s=self:make("ScrollingFrame",parent,{BorderSizePixel=0,BackgroundTransparency=1,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
  self:paint(s,"ScrollBarImageColor3","line");for k,v in props or {} do s[k]=v end;return s
 end
 function self:slider(parent,label,min,max,value,y,callback,onBegin)
  local row=self:frame(parent,{Size=UDim2.new(1,-8,0,58),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1})
  self:label(row,label,{Size=UDim2.new(1,-62,0,22),TextSize=13})
  local box=self:input(row,string.format("%.2f",value),{Position=UDim2.new(1,-60,0,0),Size=UDim2.fromOffset(58,22)})
  local track=self:frame(row,{Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,0,5)},"line")
  local fill=self:frame(track,{Size=UDim2.fromScale((value-min)/(max-min),1)},"accent")
  local hit=self:make("TextButton",row,{Position=UDim2.fromOffset(0,26),Size=UDim2.new(1,0,0,24),Text="",BackgroundTransparency=1,AutoButtonColor=false})
  local drag=false
  local function update(v) value=math.clamp(v,min,max);fill.Size=UDim2.fromScale((value-min)/(max-min),1);box.Text=string.format("%.2f",value);callback(value) end
  local function mouse()
   local p=widget:GetRelativeMousePosition();local x=p.X-(hit.AbsolutePosition.X-widget.AbsolutePosition.X)
   update(min+math.clamp(x/math.max(1,hit.AbsoluteSize.X),0,1)*(max-min))
  end
  self:connect(hit.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;self.drag=mouse;self.dragOwner=hit;if onBegin then onBegin() end;mouse();self:connect(input.Changed,function()if input.UserInputState==Enum.UserInputState.End then drag=false;self.drag=nil;self.dragOwner=nil end end)end end)
  self:connect(box.FocusLost,function()local n=tonumber(box.Text);if n and n==n then if onBegin then onBegin() end;update(n)else box.Text=string.format("%.2f",value)end end)
  return row
 end
 function self:dispose() for _,c in self.connections do c:Disconnect() end;self.connections={};self.styles={} end
 self:connect(studio.ThemeChanged,function()self.colors=palette();for obj,roles in self.styles do if obj.Parent then for property,role in roles do obj[property]=self.colors[role] end end end end)
 self:connect(game:GetService("RunService").RenderStepped,function() if self.drag and self.dragOwner.Parent and widget.Enabled then self.drag() end end)
 return self
end
return UI
