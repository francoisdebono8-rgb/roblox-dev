-- The tournament's scenes in bubbles (DESIGN, passe 3, STORY-001): a scene
-- not yet seen (the player's NinjaStoryScene) plays as manga bubbles, one at
-- a time, over the village — the speaker's name on an ink tab, his line in
-- a white balloon, a red « ▶ » to go on, SKIP to pass it all. At its end (or
-- skipped) the client sends "StorySeen" {scene}. Never during a fight: the
-- hub only calls it while he walks (Client/HubClient).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Story=require(Shared.Story)
local Text=require(Shared.Text)
local okB,Banter=pcall(function() return require(Shared.Banter) end)
if not okB then Banter=nil end

local S={}
S.__index=S

-- A scene's bubbles (pure): {who, line} each.
function S.lines(id) return Story.lines(id,Banter) end

function S.new(kit,gui,send)
	local self=setmetatable({kit=kit,send=send},S)
	local M=kit.MANGA
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	local root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,1)
	root.ZIndex=74;root.Visible=false;root.Name="StoryScene"
	self.root=root
	-- the black bars of a cut scene, top and bottom
	kit.frame(root,UDim2.fromScale(0,0),UDim2.new(1,0,.09,0),M.ink,0).ZIndex=74
	kit.frame(root,UDim2.new(0,0,.91,0),UDim2.new(1,0,.09,0),M.ink,0).ZIndex=74
	-- (seen in the game 26/11: too wide over his ninja) low, narrower, the words bigger
	local bubble=kit.frame(root,UDim2.new(.5,0,.76,0),UDim2.fromOffset(600,124),M.paper,0)
	bubble.AnchorPoint=Vector2.new(.5,.5);bubble.ZIndex=75;kit.corner(bubble,54)
	kit.create("UIStroke",bubble,{Color=M.ink,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.pop=kit.create("UIScale",bubble,{Scale=1})
	local scale=kit.create("UIScale",root,{Scale=1})
	pcall(function()
		local function fit() local v=workspace.CurrentCamera.ViewportSize;self.pop.Scale=math.min(1,(v.X-24)/620) end
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
	end)
	local tail=kit.frame(bubble,UDim2.new(.18,0,1,-8),UDim2.fromOffset(40,40),M.paper,0);tail.Rotation=40;tail.ZIndex=74
	kit.create("UIStroke",tail,{Color=M.ink,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local tab=kit.frame(bubble,UDim2.fromOffset(40,-22),UDim2.fromOffset(280,40),M.ink,0);tab.ZIndex=76;tab.Rotation=-2
	self.who=kit.text(tab,"",UDim2.fromOffset(12,2),UDim2.new(1,-24,1,-4),26,M.cream,kit.TITLE_FONT);self.who.ZIndex=77
	self.line=kit.text(bubble,"",UDim2.fromOffset(30,24),UDim2.new(1,-110,1,-34),40,M.ink,kit.VOICE_FONT or kit.BODY_FONT,Enum.TextXAlignment.Center)
	self.line.TextScaled=true;self.line.ZIndex=76
	kit.create("UITextSizeConstraint",self.line,{MaxTextSize=42,MinTextSize=16})
	self.nextButton=kit.button(bubble,"▶",UDim2.new(1,-74,1,-74),UDim2.fromOffset(60,60),function() self:advance() end,M.red)
	self.nextButton.TextColor3=M.cream;self.nextButton.TextSize=30;self.nextButton.ZIndex=77
	self.skip=kit.button(root,"SKIP",UDim2.new(1,-150,.09,10),UDim2.fromOffset(130,48),function() self:finish() end,M.paper)
	self.skip.TextColor3=M.ink;self.skip.TextSize=24;self.skip.Font=kit.TITLE_FONT;self.skip.ZIndex=77
	kit.create("UIStroke",self.skip,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.title=kit.text(root,"",UDim2.new(0,24,0,8),UDim2.new(.6,0,.07,0),40,M.cream,kit.TITLE_FONT);self.title.ZIndex=76
	self.title.TextScaled=true
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
			if processed or not root.Visible then return end
			local k=input.KeyCode
			if k==Enum.KeyCode.Space or k==Enum.KeyCode.Return or k==Enum.KeyCode.E or k==Enum.KeyCode.ButtonA
				or input.UserInputType==Enum.UserInputType.MouseButton1 then self:advance()
			elseif k==Enum.KeyCode.Escape or k==Enum.KeyCode.ButtonB then self:finish() end
		end)
	end)
	return self
end

function S:shown() return self.root.Visible end
function S:play(id,chapterName)
	self.id=id
	self.lines=S.lines(id)
	self.at=1
	if #self.lines==0 then self:finish() return false end
	self.title.Text=Text.upper(chapterName or "")
	self.root.Visible=true
	self:draw()
	return true
end
function S:draw()
	local l=self.lines[self.at]
	if not l then return end
	self.who.Text=Text.upper(l.who or "")
	self.line.Text=l.line or ""
	self.pop.Scale=self.pop.Scale*.85
	pcall(function()
		local v=workspace.CurrentCamera.ViewportSize
		game:GetService("TweenService"):Create(self.pop,TweenInfo.new(.16,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=math.min(1,(v.X-24)/620)}):Play()
	end)
end
function S:advance()
	if not self.root.Visible then return end
	self.at+=1
	if self.at>#self.lines then self:finish() else self:draw() end
end
function S:finish()
	if self.id then self.send("StorySeen",{scene=self.id}) end
	self.done=self.id
	self.id=nil
	self.root.Visible=false
	if self.onHide then self.onHide() end
end

return S
