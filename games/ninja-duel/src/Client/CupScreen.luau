-- The Prodigy Tournament on screen (Server/Tournament): the bracket between
-- matches, the spectator banner on a match the player watches, the champion's
-- card. House ink cards (UI.kit); the server decides every result and every
-- next match, the buttons only send CupFight / CupSkip / CupStart / CupLeave.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
-- (QA 12/11) capitals that keep the long vowels and accents.
local Text=require(Shared.Text)
local Fighters=require(Shared.Fighters)
local Cup={};Cup.__index=Cup

local W,H=300,44
local QF_Y={150,202,302,354,454,506,606,658}
local SF_Y={176,328,480,632}
local F_Y={252,556}
local CHAMP_Y=404
local COLS={110,500,890,1240}

function Cup.new(ui,send,kit)
	local K,P=kit,kit.palette
	local self=setmetatable({ui=ui,send=send,kit=K,plates={}},Cup)
	local root=K.frame(ui.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(8,7,10),.08)
	root.ZIndex=40;root.Visible=false
	self.root=root
	local shell=K.frame(root,UDim2.fromScale(.5,.5),UDim2.fromOffset(1600,900),P.ink,1)
	shell.AnchorPoint=Vector2.new(.5,.5);shell.ZIndex=41
	local scale=K.create("UIScale",shell,{Scale=1})
	local function fit()
		local size=workspace.CurrentCamera.ViewportSize
		scale.Scale=math.min(1.25,size.X/1600,size.Y/900)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
	self.shell=shell
	local title=K.inkTitle(K.text(shell,"PRODIGY TOURNAMENT",UDim2.fromOffset(110,30),UDim2.fromOffset(900,64),60,P.paper,K.TITLE_FONT))
	title.ZIndex=42
	self.subtitle=K.text(shell,"",UDim2.fromOffset(112,92),UDim2.fromOffset(1100,22),16,P.gold,K.BODY_FONT);self.subtitle.ZIndex=42
	for i,name in {"QUARTER-FINALS","SEMI-FINALS","FINAL","CHAMPION"} do
		local head=K.text(shell,name,UDim2.fromOffset(COLS[i],118),UDim2.fromOffset(W,24),18,P.muted,K.TITLE_FONT,Enum.TextXAlignment.Center)
		head.ZIndex=42
	end
	-- 8 + 4 + 2 + 1 plates: a seat's fighter, lit as it advances.
	local function plate(x,y)
		local f=K.frame(shell,UDim2.fromOffset(x,y),UDim2.fromOffset(W,H),Color3.fromRGB(26,23,30),.05)
		K.corner(f,6);f.ZIndex=42
		local edge=K.create("UIStroke",f,{Color=P.paper,Thickness=1.5,Transparency=.75,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local bar=K.frame(f,UDim2.fromOffset(0,0),UDim2.new(0,6,1,0),P.muted,0);bar.ZIndex=43
		local label=K.text(f,"",UDim2.fromOffset(16,0),UDim2.fromOffset(W-70,H),24,P.paper,K.TITLE_FONT);label.ZIndex=43
		local tag=K.text(f,"",UDim2.fromOffset(W-60,0),UDim2.fromOffset(52,H),14,P.gold,K.TITLE_FONT,Enum.TextXAlignment.Right);tag.ZIndex=43
		return {frame=f,edge=edge,bar=bar,label=label,tag=tag}
	end
	self.qf,self.sf,self.f={},{},{}
	for i,y in QF_Y do self.qf[i]=plate(COLS[1],y) end
	for i,y in SF_Y do self.sf[i]=plate(COLS[2],y) end
	for i,y in F_Y do self.f[i]=plate(COLS[3],y) end
	self.champ=plate(COLS[4],CHAMP_Y)
	-- The bracket's lines: each match joins its two plates and runs to the
	-- plate its winner moves to (lit gold along the winner's path, red on the
	-- next match).
	local function seg(x,y,w,h)
		local l=K.frame(shell,UDim2.fromOffset(x,y),UDim2.fromOffset(w,h),P.muted,.55)
		l.BorderSizePixel=0;l.ZIndex=41
		return l
	end
	self.links={}
	local function link(m,x0,ya,yb,x1,yc)
		local mid=x0+math.floor((x1-x0)/2)
		local ca,cb,cc=ya+H/2-1,yb+H/2-1,yc+H/2-1
		self.links[m]={a=seg(x0,ca,mid-x0,2),b=seg(x0,cb,mid-x0,2),
			upA=seg(mid-1,ca,2,cc-ca+2),upB=seg(mid-1,cc,2,cb-cc+2),out=seg(mid,cc,x1-mid,2)}
	end
	for i=1,4 do link(i,COLS[1]+W,QF_Y[2*i-1],QF_Y[2*i],COLS[2],SF_Y[i]) end
	link(5,COLS[2]+W,SF_Y[1],SF_Y[2],COLS[3],F_Y[1])
	link(6,COLS[2]+W,SF_Y[3],SF_Y[4],COLS[3],F_Y[2])
	link(7,COLS[3]+W,F_Y[1],F_Y[2],COLS[4],CHAMP_Y)
	-- The next match: who, the words before it, the buttons.
	local panel=K.inkCard(K.frame(shell,UDim2.fromOffset(110,722),UDim2.fromOffset(1430,150),K.CARD,0),10)
	panel.ZIndex=42
	self.nextTitle=K.inkTitle(K.text(panel,"",UDim2.fromOffset(24,12),UDim2.fromOffset(820,40),34,P.paper,K.TITLE_FONT));self.nextTitle.ZIndex=43
	self.lineA=K.text(panel,"",UDim2.fromOffset(26,58),UDim2.fromOffset(820,36),15,P.text,K.BODY_FONT);self.lineA.ZIndex=43
	self.lineB=K.text(panel,"",UDim2.fromOffset(26,96),UDim2.fromOffset(820,36),15,P.muted,K.BODY_FONT);self.lineB.ZIndex=43
	self.primary=K.button(panel,"FIGHT",UDim2.fromOffset(880,18),UDim2.fromOffset(526,56),function() self:press("primary") end,P.red)
	self.primary.ZIndex=43;self.primary.TextSize=32
	self.secondary=K.button(panel,"SKIP",UDim2.fromOffset(880,84),UDim2.fromOffset(256,48),function() self:press("secondary") end)
	self.secondary.ZIndex=43
	self.leave=K.button(panel,"LEAVE",UDim2.fromOffset(1150,84),UDim2.fromOffset(256,48),function() self:press("leave") end)
	self.leave.ZIndex=43
	-- The champion's card.
	local champion=K.inkCard(K.frame(root,UDim2.fromScale(.5,.5),UDim2.fromOffset(700,420),K.CARD,0))
	champion.AnchorPoint=Vector2.new(.5,.5);champion.ZIndex=50;champion.Visible=false
	-- (Studio 04/11: unscaled, the card filled most of a laptop's play window
	-- and would overflow a phone) fitted to the screen like the banner.
	local championScale=K.create("UIScale",champion,{Scale=1})
	local function fitChampion()
		local size=workspace.CurrentCamera.ViewportSize
		championScale.Scale=math.clamp(math.min(size.X/1100,size.Y/640),.5,1.2)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitChampion);fitChampion()
	self.championCard=champion
	local seal=K.text(champion,"勝",UDim2.fromOffset(700-90,-40),UDim2.fromOffset(120,120),84,P.paper,K.BODY_FONT,Enum.TextXAlignment.Center)
	seal.BackgroundColor3=P.red;seal.BackgroundTransparency=0;seal.Rotation=12;seal.ZIndex=52;K.corner(seal,12)
	K.create("UIStroke",seal,{Color=P.paper,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local ct=K.inkTitle(K.text(champion,"CHAMPION",UDim2.fromOffset(30,40),UDim2.fromOffset(640,90),88,P.gold,K.TITLE_FONT,Enum.TextXAlignment.Center));ct.ZIndex=51
	self.championName=K.text(champion,"",UDim2.fromOffset(30,140),UDim2.fromOffset(640,44),36,P.paper,K.TITLE_FONT,Enum.TextXAlignment.Center);self.championName.ZIndex=51
	local cn=K.text(champion,"Eight prodigies entered the arena. One walks out with the tournament.",UDim2.fromOffset(40,190),UDim2.fromOffset(620,44),16,P.muted,K.BODY_FONT,Enum.TextXAlignment.Center);cn.ZIndex=51
	local again=K.button(champion,"NEW TOURNAMENT",UDim2.fromOffset(40,262),UDim2.fromOffset(620,56),function() self.send("CupStart",{player=self.lastFighter}) end,P.red)
	again.ZIndex=51
	local back=K.button(champion,"BACK TO THE ROSTER",UDim2.fromOffset(40,330),UDim2.fromOffset(620,56),function() self.send("CupLeave") end)
	back.ZIndex=51
	self.championAgain=again
	-- The spectator's banner over a watched match.
	local banner=K.inkCard(K.frame(ui.gui,UDim2.new(.5,0,1,-118),UDim2.fromOffset(640,70),K.CARD,0),10)
	banner.AnchorPoint=Vector2.new(.5,0);banner.ZIndex=45;banner.Visible=false
	local bannerScale=K.create("UIScale",banner,{Scale=1})
	local function fitBanner()
		local size=workspace.CurrentCamera.ViewportSize
		bannerScale.Scale=math.clamp(math.min(size.X/1500,size.Y/860),.55,1.2)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitBanner);fitBanner()
	self.banner=banner
	self.bannerText=K.text(banner,"",UDim2.fromOffset(18,8),UDim2.fromOffset(440,54),20,P.paper,K.TITLE_FONT);self.bannerText.ZIndex=46
	local skip=K.button(banner,"SKIP",UDim2.fromOffset(474,12),UDim2.fromOffset(148,46),function() self.send("CupSkip") end,P.red)
	skip.ZIndex=46
	self.skip=skip
	return self
end
local function nameOf(id)
	local def=Fighters[id or ""]
	return if def then Text.upper(def.Name) else "?"
end
function Cup:press(which)
	local cup=self.cup
	if not cup then return end
	if which=="leave" then self.send("CupLeave");return end
	if cup.over or cup.out then
		if which=="primary" then self.send("CupStart",{player=cup.seats[cup.me]}) else self.send("CupLeave") end
		return
	end
	local n=cup.next
	if not n then return end
	if which=="primary" then self.send("CupFight") elseif not n.mine then self.send("CupSkip") end
end
function Cup:fill(p,seat,cup,alive)
	local P=self.kit.palette
	if not seat then
		p.label.Text="—";p.tag.Text="";p.bar.BackgroundColor3=P.muted;p.label.TextColor3=P.muted;p.edge.Transparency=.85
		return
	end
	local id=cup.seats[seat]
	local def=Fighters[id or ""]
	p.label.Text=nameOf(id)
	p.bar.BackgroundColor3=if def then Color3.fromRGB(table.unpack(def.Color)) else P.muted
	local mine=seat==cup.me
	p.tag.Text=if mine then "YOU" else ""
	p.label.TextColor3=if alive then P.paper else P.muted
	p.frame.BackgroundTransparency=if alive then .05 else .45
	p.edge.Color=if mine then P.gold else P.paper
	p.edge.Transparency=if mine then .1 else .75
end
function Cup:draw(cup)
	self.cup=cup
	self.lastFighter=cup.seats[cup.me]
	local w=cup.winners
	-- A seat is alive until a match it played was lost.
	local lost={}
	local Pair={[1]={1,2},[2]={3,4},[3]={5,6},[4]={7,8}}
	for m=1,4 do if w[m] then for _,seat in Pair[m] do if seat~=w[m] then lost[seat]=true end end end end
	local function sfSeats(m) if m==5 then return w[1],w[2] else return w[3],w[4] end end
	for _,m in {5,6} do if w[m] then local a,b=sfSeats(m);for _,seat in {a,b} do if seat and seat~=w[m] then lost[seat]=true end end end end
	if w[7] then for _,seat in {w[5],w[6]} do if seat and seat~=w[7] then lost[seat]=true end end end
	for i=1,8 do self:fill(self.qf[i],i,cup,not lost[i]) end
	for i=1,4 do self:fill(self.sf[i],w[i],cup,w[i]~=nil and not lost[w[i]]) end
	self:fill(self.f[1],w[5],cup,w[5]~=nil and not lost[w[5]])
	self:fill(self.f[2],w[6],cup,w[6]~=nil and not lost[w[6]])
	self:fill(self.champ,w[7],cup,w[7]~=nil)
	local P=self.kit.palette
	-- (the tournament's winner in gold)
	if w[7] then self.champ.label.TextColor3=P.gold;self.champ.edge.Color=P.gold;self.champ.edge.Transparency=0 end
	local n=cup.next
	-- The lines: the winner's side and the run to the next plate in gold, the
	-- match about to be played in red, the rest faint.
	local function seatsOf(m)
		if m<=4 then return 2*m-1,2*m elseif m==5 then return w[1],w[2] elseif m==6 then return w[3],w[4] end
		return w[5],w[6]
	end
	local live=n and not cup.over and not cup.out and n.match
	for m,l in self.links do
		local a,b=seatsOf(m)
		local won=w[m]
		local function paint(segment,lit)
			local hot=live==m
			segment.BackgroundColor3=if hot then P.red elseif lit then P.gold else P.muted
			segment.BackgroundTransparency=if hot or lit then 0 else .55
		end
		paint(l.a,won~=nil and won==a);paint(l.upA,won~=nil and won==a)
		paint(l.b,won~=nil and won==b);paint(l.upB,won~=nil and won==b)
		paint(l.out,won~=nil)
	end
	if cup.over or cup.out then
		local champion=cup.champion and nameOf(cup.seats[cup.champion]) or "?"
		self.subtitle.Text=if cup.out then "ELIMINATED IN THE "..tostring(cup.eliminatedIn or "").."  •  THE REST OF THE BRACKET WAS PLAYED OUT" else "THE TOURNAMENT IS OVER"
		self.nextTitle.Text="CHAMPION  •  "..champion
		self.lineA.Text=if cup.out then "Even prodigies lose. Learn the opening you missed, then come back to the arena." else ""
		self.lineB.Text=""
		self.primary.Text="NEW TOURNAMENT"
		self.secondary.Text="BACK TO THE ROSTER";self.secondary.Visible=true
		self.leave.Visible=false
	elseif n then
		local a,b=nameOf(cup.seats[n.a]),nameOf(cup.seats[n.b])
		self.subtitle.Text=string.format("%s  •  MATCH %d OF 7  •  FIRST TO TWO ROUNDS",n.roundName or "",n.match or 0)
		self.nextTitle.Text=string.format("%s  •  %s  VS  %s",n.roundName or "",a,b)
		self.lineA.Text=a..":  “"..tostring(n.lineA or "").."”"
		self.lineB.Text=b..":  “"..tostring(n.lineB or "").."”"
		self.primary.Text=if n.mine then "FIGHT" else "WATCH"
		self.secondary.Text="SKIP";self.secondary.Visible=not n.mine
		self.leave.Text="LEAVE";self.leave.Visible=true
		self.primary.BackgroundColor3=P.red
	end
	local nextMatch=n and n.match
	for _,p in {self.qf,self.sf,self.f} do for _,pl in p do pl.frame.Size=UDim2.fromOffset(W,H) end end
	-- The two plates of the next match stand out.
	if n and not cup.over and not cup.out then
		local plates={}
		if nextMatch<=4 then plates={self.qf[n.a],self.qf[n.b]}
		elseif nextMatch==5 then plates={self.sf[1],self.sf[2]} elseif nextMatch==6 then plates={self.sf[3],self.sf[4]}
		else plates={self.f[1],self.f[2]} end
		for _,pl in plates do pl.edge.Color=P.red;pl.edge.Transparency=0 end
	end
end
-- Called with every game packet.
function Cup:render(data)
	local phase=data.phase
	self.root.Visible=phase=="Bracket" or phase=="Champion"
	self.championCard.Visible=phase=="Champion"
	self.shell.Visible=phase=="Bracket"
	if data.cup and (phase=="Bracket" or phase=="Champion") then self:draw(data.cup) end
	-- (pad focus after the UI's own screen change has settled)
	local function focus(target) task.delay(.25,function() pcall(function() game:GetService("GuiService").SelectedObject=target end) end) end
	if phase=="Champion" and data.cup and data.cup.champion then
		self.championName.Text=Text.upper((Fighters[data.cup.seats[data.cup.champion]] or {}).FullName or "")
		if self.lastPhase~="Champion" then focus(self.championAgain) end
	elseif phase=="Bracket" and self.lastPhase~="Bracket" then
		focus(self.primary)
	end
	-- Watching a match: whose, which round, SKIP.
	local watching=phase=="Duel" and data.spectate==true and data.cup~=nil
	-- (Audit 04/11) not over the intro's VS and names, not over the K.O. (the
	-- result on screen is the result); on a pad SKIP takes the focus.
	self.banner.Visible=watching and not data.ko and (data.intro or 0)<=0
	if self.banner.Visible and not self.bannerShown and data.gamepad then focus(self.skip) end
	self.bannerShown=self.banner.Visible
	if watching then
		local n=data.cup.next
		local a,b=nameOf(data.human and data.human.fighterId),nameOf(data.bot and data.bot.fighterId)
		self.bannerText.Text=string.format("SPECTATING  •  %s\n%s  VS  %s",n and n.roundName or "",a,b)
	end
	self.lastPhase=phase
end
return Cup
