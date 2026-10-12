-- Local visual primitives; workflow and engine state belong to View.
local UI = {}
local function make(class, parent, props)
	local item = Instance.new(class)
	for key, value in pairs(props or {}) do item[key] = value end
	item.Parent = parent
	return item
end
UI.make = make
function UI.new(root, accent)
	local ui = { colors = {}, root = root }
	local c = ui.colors
	function ui.theme()
		local bg = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		local light = bg.R + bg.G + bg.B > 1.5
		c.bg = light and Color3.fromRGB(246,247,247) or Color3.fromRGB(24,26,28)
		c.text = light and Color3.fromRGB(36,39,41) or Color3.fromRGB(232,234,236)
		c.muted = light and Color3.fromRGB(102,108,111) or Color3.fromRGB(158,163,166)
		c.line = light and Color3.fromRGB(221,224,223) or Color3.fromRGB(47,51,53)
		c.field = light and Color3.fromRGB(237,240,240) or Color3.fromRGB(34,36,38)
		c.hover = light and Color3.fromRGB(226,231,233) or Color3.fromRGB(40,44,46)
		c.error = light and Color3.fromRGB(175,53,46) or Color3.fromRGB(239,106,98)
		c.warning = light and Color3.fromRGB(143,96,25) or Color3.fromRGB(229,168,77)
		c.accent = accent; c.selected = c.bg:Lerp(accent, light and 0.14 or 0.18)
		c.viewport = light and Color3.fromRGB(231,235,237) or Color3.fromRGB(20,22,24)
		root.BackgroundColor3 = c.bg
	end
	ui.theme()
	function ui.stack(parent, gap)
		return make("UIListLayout", parent, {Padding=UDim.new(0,gap or 6), SortOrder=Enum.SortOrder.LayoutOrder})
	end
	function ui.label(parent, text, size, color, height)
		return make("TextLabel",parent,{Text=text,Font=Enum.Font.BuilderSans,TextSize=size or 13,TextColor3=color or c.text,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 0),AutomaticSize=height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
			TextWrapped=not height,TextTruncate=height and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
			TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
	end
	function ui.tip(control, text)
		local bubble
		control.MouseEnter:Connect(function()
			if control:IsA("TextLabel") and control.Text==text and control.TextFits then return end
			bubble=ui.label(root,text,12,c.text)
			bubble.Name="Tooltip"; bubble.ZIndex=50; bubble.BackgroundTransparency=0; bubble.BackgroundColor3=c.field
			bubble.Size=UDim2.fromOffset(math.min(260,root.AbsoluteSize.X-24),0)
			local pos=control.AbsolutePosition-root.AbsolutePosition
			bubble.Position=UDim2.fromOffset(math.clamp(pos.X,12,math.max(12,root.AbsoluteSize.X-272)),math.max(0,math.min(pos.Y+control.AbsoluteSize.Y+4,root.AbsoluteSize.Y-72)))
			make("UIPadding",bubble,{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)})
		end)
		local function clear() if bubble then bubble:Destroy(); bubble=nil end end
		control.MouseLeave:Connect(clear); control.Destroying:Connect(clear)
	end
	function ui.button(parent, name, text, callback, style)
		local primary, selected = style=="primary", style=="selected"
		local base=primary and c.accent or selected and c.selected or c.bg
		local b=make("TextButton",parent,{Name=name,Text=text,Font=Enum.Font.BuilderSansMedium,TextSize=13,
			TextColor3=primary and Color3.new(1,1,1) or c.text,BackgroundColor3=base,BackgroundTransparency=style and 0 or 1,
			BorderSizePixel=0,Size=UDim2.new(1,0,0,30),TextTruncate=Enum.TextTruncate.AtEnd,AutoButtonColor=false})
		make("UICorner",b,{CornerRadius=UDim.new(0,4)})
		b.MouseEnter:Connect(function() if b.Active then b.BackgroundTransparency=0; b.BackgroundColor3=primary and c.accent:Lerp(Color3.new(1,1,1),0.12) or c.hover end end)
		b.MouseLeave:Connect(function() if b.Active then b.BackgroundTransparency=style and 0 or 1; b.BackgroundColor3=base end end)
		b.MouseButton1Down:Connect(function() if b.Active then b.BackgroundColor3=base:Lerp(c.text,0.1) end end)
		b.MouseButton1Up:Connect(function() if b.Active then b.BackgroundColor3=base end end)
		b.Activated:Connect(function() if b.Active then callback() end end)
		return b
	end
	function ui.disable(button)
		button.Active, button.Selectable = false, false
		button.BackgroundTransparency, button.BackgroundColor3, button.TextColor3 = 0, c.field, c.muted
	end
	function ui.row(parent, count, height)
		local r=make("Frame",parent,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 30)})
		make("UIGridLayout",r,{CellSize=UDim2.new(1/count,-5,1,0),CellPadding=UDim2.fromOffset(4,0),SortOrder=Enum.SortOrder.LayoutOrder})
		return r
	end
	function ui.scroll(parent, name, position, size)
		local s=make("ScrollingFrame",parent,{Name=name,Position=position,Size=size,BackgroundTransparency=1,BorderSizePixel=0,
			CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=c.muted})
		make("UIPadding",s,{PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,8)})
		ui.stack(s,7); return s
	end
	function ui.section(parent, text)
		local t=ui.label(parent,text,11,c.muted,24); t.Font=Enum.Font.BuilderSansMedium; return t
	end
	function ui.rule(parent)
		return make("Frame",parent,{Size=UDim2.new(1,0,0,1),BorderSizePixel=0,BackgroundColor3=c.line})
	end
	function ui.input(parent, name, text, invalidate, commit)
		local box=make("TextBox",parent,{Name=name,Text=text,ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=13,
			TextColor3=c.text,BackgroundColor3=c.field,BorderSizePixel=0,Size=UDim2.new(1,0,0,30)})
		make("UICorner",box,{CornerRadius=UDim.new(0,4)})
		local line=make("UIStroke",box,{Color=c.accent,Transparency=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		box.Focused:Connect(function() line.Transparency=0 end)
		box:GetPropertyChangedSignal("Text"):Connect(invalidate)
		box.FocusLost:Connect(function() line.Transparency=1; commit(box.Text) end)
		return box
	end
	function ui.toggle(parent, name, title, value, callback)
		local b=ui.button(parent,name,"",callback)
		local box=make("Frame",b,{Position=UDim2.fromOffset(1,7),Size=UDim2.fromOffset(16,16),BackgroundColor3=value and c.accent or c.field,BorderSizePixel=0})
		make("UICorner",box,{CornerRadius=UDim.new(0,3)})
		make("UIStroke",box,{Color=value and c.accent or c.line})
		if value then local tick=ui.label(box,"\u{2713}",13,Color3.new(1,1,1),16); tick.TextXAlignment=Enum.TextXAlignment.Center end
		local text=ui.label(b,title,13,c.text,30); text.Position=UDim2.fromOffset(24,0); text.Size=UDim2.new(1,-24,1,0)
		return b
	end
	function ui.header(product, context, subtitle, compact)
		local h=make("Frame",root,{Name="Header",Size=UDim2.new(1,0,0,compact and 64 or 88),BackgroundTransparency=1})
		local mark=make("Frame",h,{Name="ForgeMark",Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(20,26.25),BackgroundTransparency=1})
		-- RLE alpha mask copied from the canonical SVG raster used by SchemaForge.
		local raster=require(script.Parent.ForgeMark)
		local y=0
		for line in (raster.."\n"):gmatch("([^\n]*)\n") do
			for x,width,alpha in line:gmatch("(%d+),(%d+),(%d+)") do
				make("Frame",mark,{Position=UDim2.fromScale(tonumber(x)/32,y/42),Size=UDim2.fromScale(tonumber(width)/32,1/42),BackgroundColor3=c.text,BackgroundTransparency=1-tonumber(alpha)/255,BorderSizePixel=0})
			end
			y+=1
		end
		local name=ui.label(h,product,13,c.text,22); name.Font=Enum.Font.BuilderSansBold; name.Position=UDim2.fromOffset(38,7); name.Size=UDim2.fromOffset(98,22)
		local maker=ui.label(h,"Forge Studio 0.2.5",11,c.muted,22); maker.Position=UDim2.fromOffset(137,7); maker.Size=UDim2.new(1,-145,0,22)
		local title=ui.label(h,context,18,c.text,26); title.Font=Enum.Font.BuilderSansBold; title.Position=UDim2.fromOffset(12,34); title.Size=UDim2.new(1,-24,0,26); ui.tip(title,context)
		local sub=ui.label(h,subtitle,12,c.muted,18); sub.Position=UDim2.fromOffset(12,62); sub.Size=UDim2.new(1,-24,0,18)
		sub.Visible=not compact
		local line=ui.rule(h); line.Position=UDim2.new(0,0,1,-1)
	end
	function ui.viewport(parent, model, bounds, points, selected)
		local v=make("ViewportFrame",parent,{Name="GeometryPreview",Size=UDim2.fromScale(1,1),BackgroundColor3=c.viewport,BorderSizePixel=0,
			Ambient=Color3.fromRGB(190,195,205),LightDirection=Vector3.new(-1,-2,-1),LightColor=Color3.fromRGB(255,246,228)})
		local world=make("WorldModel",v,{}); model.Parent=world
		local cf,size=model:GetBoundingBox()
		if bounds then cf,size=bounds.boundsCFrame,bounds.boundsSize end
		local camera=make("Camera",v,{FieldOfView=38}); v.CurrentCamera=camera
		local markers={}
		for i in ipairs(points or {}) do
			local marker=ui.label(v,tostring(i),12,c.text,20)
			marker.Name="PointMarker"..i; marker.Size=UDim2.fromOffset(20,20); marker.AnchorPoint=Vector2.new(0.5,0.5)
			marker.BackgroundTransparency=0; marker.BackgroundColor3=i==selected and c.accent or c.field
			marker.TextXAlignment=Enum.TextXAlignment.Center; marker.ZIndex=2
			make("UICorner",marker,{CornerRadius=UDim.new(0,4)}); markers[i]=marker
		end
		local function frame()
			local aspect=math.max(v.AbsoluteSize.X,1)/math.max(v.AbsoluteSize.Y,1)
			local direction=Vector3.new(0.65,0.55,1).Unit
			local basis=CFrame.lookAt(cf.Position,cf.Position-direction)
			local tangent=math.tan(math.rad(19))
			local distance=2
			-- Fit all eight bounding-box corners to the actual viewport aspect ratio.
			for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
				local p=basis:PointToObjectSpace(cf:PointToWorldSpace(size*Vector3.new(x,y,z)/2))
				distance=math.max(distance,p.Z+math.abs(p.Y)/tangent,p.Z+math.abs(p.X)/(tangent*aspect))
			end end end
			camera.CFrame=CFrame.lookAt(cf.Position+direction*distance*1.12,cf.Position)
			for i,position in ipairs(points or {}) do
				local p=camera.CFrame:PointToObjectSpace(position)
				markers[i].Visible=p.Z<0
				if p.Z<0 then markers[i].Position=UDim2.fromScale(0.5+p.X/(-p.Z*tangent*aspect*2),0.5-p.Y/(-p.Z*tangent*2)) end
			end
		end
		v:GetPropertyChangedSignal("AbsoluteSize"):Connect(frame); frame(); return v
	end
	return ui
end
return UI
