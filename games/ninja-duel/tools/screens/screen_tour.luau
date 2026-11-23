--!nocheck
-- NDScreenTour (OUTILLEUR, passe commune 1, DEC-051): the screens of the
-- player's path, one after the other, with what the output writes in red.
-- François, 23/11: « les UI ne sont pas assez jolies et il y a des erreurs ».
--
-- In a Play of a LAB copy (tools/lab/lab_place.py), Client. The tour itself is
-- driven from outside, as a player: a click (robloxstudio-mcp
-- simulate_mouse_input, at the centre this module gives) or a key, then a
-- capture of the viewport. This module says what is on the screen and what
-- went red since the last look:
--   Tour.look()       the buttons (text, centre in viewport pixels), the big
--                     texts, the open screens, the new red lines of the client
--   Tour.find(text)   the centre of a visible button whose text holds `text`
--   Tour.errors()     every red line of the client since the Play began
local Players=game:GetService("Players")
local LogService=game:GetService("LogService")
local GuiService=game:GetService("GuiService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer

local Tour={}
Tour.seen=0       -- the log lines already given

local function shown(d)
	local x=d
	while x and not x:IsA("LayerCollector") do
		if x:IsA("GuiObject") and not x.Visible then return false end
		x=x.Parent
	end
	if not x then return false end
	if x:IsA("ScreenGui") and not x.Enabled then return false end
	return x:IsA("ScreenGui")
end
local function onScreen(d,vp)
	local p,s=d.AbsolutePosition,d.AbsoluteSize
	return s.X>2 and s.Y>2 and p.X+s.X>0 and p.Y+s.Y>-60 and p.X<vp.X and p.Y<vp.Y
end
local function words(d)
	local t=""
	if d:IsA("TextButton") or d:IsA("TextLabel") then t=d.ContentText ~= "" and d.ContentText or d.Text end
	if t=="" then
		for _,c in d:GetDescendants() do
			if (c:IsA("TextLabel") or c:IsA("TextButton")) and c.Visible and c.Text~="" then t=c.ContentText ~= "" and c.ContentText or c.Text;break end
		end
	end
	t=string.gsub(t,"<[^>]+>","")
	t=string.gsub(t,"%s+"," ")
	return string.sub(t,1,40)
end

-- The red lines (MessageError) of this side, from `from` on.
function Tour.red(from)
	local out={}
	local all=LogService:GetLogHistory()
	for i=from or 1,#all do
		local m=all[i]
		if m.messageType==Enum.MessageType.MessageError then table.insert(out,string.sub(m.message,1,300)) end
	end
	return out,#all
end
function Tour.errors() return (Tour.red(1)) end

function Tour.look()
	local vp=workspace.CurrentCamera.ViewportSize
	local inset=GuiService:GetGuiInset()
	local pg=player:WaitForChild("PlayerGui")
	local buttons,texts,guis={}, {}, {}
	for _,g in pg:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then table.insert(guis,g.Name) end
	end
	for _,d in pg:GetDescendants() do
		if not d:IsA("GuiObject") or not shown(d) or not onScreen(d,vp) then continue end
		if d:IsA("GuiButton") and d.Active then
			local w=words(d)
			local c=d.AbsolutePosition+d.AbsoluteSize/2+inset
			table.insert(buttons,{t=w,x=math.floor(c.X),y=math.floor(c.Y),w=math.floor(d.AbsoluteSize.X),h=math.floor(d.AbsoluteSize.Y),gui=d:FindFirstAncestorWhichIsA("ScreenGui").Name})
		elseif d:IsA("TextLabel") and d.Text~="" and d.TextTransparency<.9 and (d.TextBounds.Y>=18 or d.AbsoluteSize.Y>=26) then
			table.insert(texts,words(d))
		end
	end
	local red,n=Tour.red(Tour.seen+1)
	Tour.seen=n
	return HttpService:JSONEncode({vp={math.floor(vp.X),math.floor(vp.Y)},inset={inset.X,inset.Y},guis=guis,
		phase=player:GetAttribute("NinjaPhase") or player:GetAttribute("NDPhase"),buttons=buttons,texts=texts,red=red})
end

-- The centre (viewport pixels) of the first visible button whose text holds `text`.
function Tour.find(text)
	local vp=workspace.CurrentCamera.ViewportSize
	local inset=GuiService:GetGuiInset()
	local needle=string.upper(text)
	for _,d in player.PlayerGui:GetDescendants() do
		if d:IsA("GuiButton") and d.Active and shown(d) and onScreen(d,vp) and string.find(string.upper(words(d)),needle,1,true) then
			local c=d.AbsolutePosition+d.AbsoluteSize/2+inset
			return math.floor(c.X),math.floor(c.Y),words(d)
		end
	end
	return nil
end

return Tour
