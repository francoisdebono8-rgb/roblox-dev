-- SyphoDev's UI checks (.claude/skills/roblox-ui: verify_ui) on the REAL screen, in a Play
-- session, instead of on a spec: run as Client through the Studio MCP (execute_luau,
-- datamodel Client), after robloxstudio-mcp set_device_simulator has picked the device.
-- It measures what the player sees at that size, in pixels:
--   * touch targets under 44 px (Apple / Roblox thumb guideline) among visible buttons;
--   * text under 11 px once TextScaled and UIScale are applied;
--   * visible elements cut by the screen edge or by the Roblox top bar (GuiInset);
--   * solid blocks of the same ScreenGui that overlap each other;
--   * the outline (UIStroke) thicknesses in use, after UIScale, to spot a mixed set.
-- 19/11, first run on the Konoha HUD (iPhone 13 landscape): see docs/tools/METHODE_SYPHODEV.md.
local GuiService=game:GetService("GuiService")
local gui=game.Players.LocalPlayer:WaitForChild("PlayerGui")
local cam=workspace.CurrentCamera
local vp=cam.ViewportSize
local inset=GuiService:GetGuiInset()
local MIN_TOUCH,MIN_TEXT=44,11

local function shown(o)
	local x=o
	while x and x~=gui do
		if x:IsA("LayerCollector") and not x.Enabled then return false end
		if x:IsA("GuiObject") and not x.Visible then return false end
		x=x.Parent
	end
	return true
end
local function scaleOf(o)
	local s,x=1,o
	while x and x~=gui do
		local u=x:FindFirstChildOfClass("UIScale")
		if u then s*=u.Scale end
		x=x.Parent
	end
	return s
end
local function label(o)
	local t=(o:IsA("TextButton") or o:IsA("TextLabel")) and o.Text~="" and (" «"..o.Text:sub(1,20).."»") or ""
	return o.Name..t
end

local small,tiny,cut,strokes,blocks={}, {}, {}, {}, {}
local buttons,texts=0,0
for _,o in gui:GetDescendants() do
	if o:IsA("GuiObject") and shown(o) and o.AbsoluteSize.X>1 and o.AbsoluteSize.Y>1 then
		local p,s=o.AbsolutePosition,o.AbsoluteSize
		if o:IsA("GuiButton") then
			buttons+=1
			if math.min(s.X,s.Y)<MIN_TOUCH then table.insert(small,("%s %dx%d"):format(label(o),s.X,s.Y)) end
		end
		if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text~="" and o.TextTransparency<1 then
			texts+=1
			local px=(if o.TextScaled then math.min(s.Y,o.TextBounds.Y) else o.TextSize*scaleOf(o))
			if px<MIN_TEXT then table.insert(tiny,("%s %.0fpx"):format(label(o),px)) end
		end
		local ignore=o:FindFirstAncestorWhichIsA("ScreenGui")
		local top=(ignore and ignore.IgnoreGuiInset) and inset.Y or 0
		if p.X<-1 or p.Y<-top-1 or p.X+s.X>vp.X+1 or p.Y+s.Y>vp.Y-top+1 then
			table.insert(cut,("%s at (%d,%d) %dx%d"):format(label(o),p.X,p.Y,s.X,s.Y))
		end
		local solid=o.BackgroundTransparency<.5
		if solid then table.insert(blocks,o) end
	end
	if o:IsA("UIStroke") and o.Enabled and o.Parent and o.Parent:IsA("GuiObject") and shown(o.Parent) then
		local px=math.round(o.Thickness*scaleOf(o.Parent)*10)/10
		strokes[px]=(strokes[px] or 0)+1
	end
end
-- overlaps between solid blocks that are not nested (outermost blocks only)
local outer={}
for _,b in blocks do
	local inner=false
	for _,c in blocks do
		if c~=b and b:IsDescendantOf(c) then inner=true;break end
	end
	if not inner then table.insert(outer,b) end
end
local over={}
for i=1,#outer do for j=i+1,#outer do
	local a,b=outer[i],outer[j]
	if a:FindFirstAncestorWhichIsA("LayerCollector")==b:FindFirstAncestorWhichIsA("LayerCollector") then
		local ap,as,bp,bs=a.AbsolutePosition,a.AbsoluteSize,b.AbsolutePosition,b.AbsoluteSize
		local ox=math.min(ap.X+as.X,bp.X+bs.X)-math.max(ap.X,bp.X)
		local oy=math.min(ap.Y+as.Y,bp.Y+bs.Y)-math.max(ap.Y,bp.Y)
		if ox>1 and oy>1 then table.insert(over,("%s / %s (%dx%d)"):format(label(a),label(b),ox,oy)) end
	end
end end
local sk={}
for px,n in strokes do table.insert(sk,("%gpx x%d"):format(px,n)) end
table.sort(sk)
return table.concat({
	("viewport %dx%d, inset %d; %d buttons, %d texts"):format(vp.X,vp.Y,inset.Y,buttons,texts),
	("touch targets < %dpx: %d  %s"):format(MIN_TOUCH,#small,table.concat(small,"; ")),
	("text < %dpx: %d  %s"):format(MIN_TEXT,#tiny,table.concat(tiny,"; ")),
	("cut by the screen or the top bar: %d  %s"):format(#cut,table.concat(cut,"; ")),
	("overlapping blocks: %d  %s"):format(#over,table.concat(over,"; ")),
	"outlines: "..table.concat(sk,", "),
},"\n")
