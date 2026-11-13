--!nocheck
-- Assistant de tournage (F4) — place FILM seulement (build.py --capture).
--
-- Demandé le 13/11/2026 : un outil dans Studio pour que le CM tourne ses clips
-- sans défaut d'image, d'éclairage, de cadrage ni de caméra, et qu'il voie
-- tout de suite les erreurs qu'il fait.
--
-- Il ne change pas le jeu. Il lit la caméra, les deux corps, la lumière et
-- l'écran, et signale ce qui abîme une prise :
--   cadrage   le perso qui agit filmé de dos, caché par un corps, un clone ou
--             le décor, hors de la bande 9:16, tête coupée, persos trop petits
--             (surtout pendant l'ouverture), objet collé à l'objectif, caméra
--             dans un mur, face au soleil, saut de caméra, coupes trop serrées ;
--   réglage   qualité graphique Automatique, profondeur de champ, rayons du
--             soleil, ombres coupées, HUD ou panneau F6/F7 dans l'image,
--             curseur dans l'image ;
--   machine   image figée, Studio sous 50 i/s ;
--   jeu       corps l'un dans l'autre, lumière colorée qui teinte un perso,
--             flash plein corps qui dure, erreurs de script : à signaler au
--             DEV ou à l'ANIMATEUR, pas à contourner.
-- Pendant une prise (REC), chaque défaut est noté avec son temps depuis le
-- début de la prise ; à l'arrêt, le résumé donne les plages propres à monter.
--
-- Tout ce qu'il dessine reste hors de la bande 9:16 que garde OBS (même
-- bande que ClipKit, CROPW) : le panneau dans la marge gauche, deux traits de
-- couleur juste à l'extérieur de la bande. Les repères dessinés dans la bande
-- (tiers, zones de l'interface TikTok) disparaissent pendant une prise.
--
-- Agents (Studio MCP, côté Client, pendant le Play) :
--   local r=game.Players.LocalPlayer.PlayerGui.ClipAssistPanel.Report
--   print(r:Invoke())                -- état JSON (liste de contrôle, défauts en cours)
--   r:Invoke("rec","start","M1")     -- début de prise : au moment où OBS démarre
--   print(r:Invoke("rec","stop"))    -- fin : résumé JSON (plages propres, défauts datés)
--   r:Invoke("prepare")              -- prépare l'image (HUD, panneaux, flou, rayons, curseur)
--   r:Invoke("restore")              -- remet l'écran comme avant
--   r:Invoke("actors",{a,b})         -- les deux corps à suivre (replay) ; nil = le duel
--   r:Invoke("acting","A")           -- qui agit : "A", "B", "AB" ; nil = lu dans le duel
--   r:Invoke("show",true)            -- panneau visible ou non
--   r:Invoke("guides",false)         -- repères dans la bande
--   r:Invoke("allowHud",true)        -- prise avec le HUD voulu (preuve de gameplay)
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local HttpService=game:GetService("HttpService")
local LogService=game:GetService("LogService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")

local Assist={}
local V=Vector3.new
local rgb=Color3.fromRGB
-- The kept band, as ClipKit frames it: 9:16, full height, centred.
local CROPW=830/1480
local ERR,WARN,INFO=3,2,1
local SEVNAME={[3]="ERREUR",[2]="À VOIR",[1]="INFO"}
local SEVCOLOR={[3]=rgb(235,80,80),[2]=rgb(240,170,60),[1]=rgb(150,170,190)}
local OK_COLOR=rgb(90,200,120)
local OWNER={cadrage="cadrage",reglage="réglage",machine="machine",jeu="jeu → DEV/ANIM"}
local T={
	tick=1/15,              -- body checks per second
	hold=0.15,              -- a framing fault counts once it lasts this long
	back=115,               -- seen from behind beyond this angle (degrees)
	small=0.18,             -- a body under this share of the image height is small
	opening=2,              -- the first seconds of a take: the hook
	hitch=0.05,             -- a frame longer than this is a frozen image
	lowFps=50,
	lens=2.2,               -- studs in front of the lens
	sun=35,                 -- degrees between the lens and the sun
	cutMove=6,cutTurn=30,   -- more than this in one frame: a cut
	jumpMove=0.9,jumpTurn=8,-- more than this, and 4x the recent motion: a jump
	cutGap=0.5,             -- two cuts closer than this
	clean=1,                -- shortest clean range listed
}
-- Server states in which a fighter is doing something (Matches:view `state`).
local ACT={Startup=true,Active=true,Recovery=true,Rush=true,Pursuit=true,Dodging=true,
	TechniqueChannel=true,TechniqueActive=true,TechniqueRecovery=true}
local FX_ROOTS={"NinjaDuelFX","Effects","NinjaUltimateFX","VfxMesh","WorldMemory"}
local DEV_GUIS={NinjaDuelDevPanel="F6",DevVisualPanel="F7",DevVisualHud="F7"}

local function fmt(t) return (string.format("%.1f",t):gsub("%.",",")) end
local function flat(v) return V(v.X,0,v.Z) end
local function isHead(n) return n=="Head" or n:sub(1,6)=="Head__" end
local function hex(c) return string.format("#%02X%02X%02X",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)) end
local function esc(s) return (tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
local function hueName(c)
	local h,s,v=c:ToHSV()
	if s<0.25 then return "blanche" end
	h*=360
	if h<15 or h>=345 then return "rouge" elseif h<40 then return "orange" elseif h<70 then return "jaune"
	elseif h<165 then return "verte" elseif h<255 then return "bleue" elseif h<300 then return "violette" else return "rose" end
end

local function duelModels()
	local root=workspace:FindFirstChild("NinjaDuels")
	if not root then return nil end
	for _,duel in root:GetChildren() do
		local a,b=duel:FindFirstChild("PlayerFighter"),duel:FindFirstChild("AIFighter")
		if a and b then return a,b end
	end
	return nil
end
local function rootOf(m) return m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart) end
local function pivotOf(m)
	local r=rootOf(m)
	if r then return r.CFrame end
	local ok,cf=pcall(function() return m:GetPivot() end)
	return ok and cf or nil
end
local partCache=setmetatable({},{__mode="k"})
local function partsOf(m)
	local e=partCache[m]
	local now=os.clock()
	if e and now-e.t<0.5 then return e end
	e={t=now,head=nil,torso=nil,hands={},lowY=nil}
	for _,d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency<0.9 and d.Name~="HumanoidRootPart" then
			local n=d.Name
			if isHead(n) and (not e.head or n=="Head") then e.head=d
			elseif (n=="UpperTorso" or n=="Torso") and not e.torso then e.torso=d
			elseif n=="LeftHand" or n=="RightHand" or n=="Left Arm" or n=="Right Arm" then table.insert(e.hands,d) end
		end
	end
	partCache[m]=e
	return e
end
local function quality()
	-- In Studio the play window follows the Studio rendering level (1-21),
	-- the client setting (1-10) otherwise; Automatic in either is the fault.
	local level,auto=nil,nil
	pcall(function()
		local q=settings().Rendering.QualityLevel
		if q==Enum.QualityLevel.Automatic then auto=true else level=tonumber(tostring(q):match("(%d+)$")) end
	end)
	if level==nil and auto==nil then
		pcall(function()
			local q=UserSettings():GetService("UserGameSettings").SavedQualityLevel
			if q==Enum.SavedQualitySetting.Automatic then auto=true else level=tonumber(tostring(q):match("(%d+)$")) end
		end)
	end
	return level,auto
end

function Assist.install(ctx,dev)
	if not RunService:IsStudio() then return nil end
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local self={shown=false,guides=true,allowHud=false,actorsOverride=nil,actingOverride=nil,check={}}
	local installedAt=os.clock()
	local live={}        -- id -> condition {id,group,sev,owner,text,since,seen,open,minDur}
	local recent={}      -- instant events {t,sev,owner,text}
	local take=nil       -- the take being recorded
	local last=nil       -- the last take's summary
	local saved=nil      -- what "prepare" changed, for "restore"
	local band={x0=0,x1=0,w=0,h=0}

	local function rel(t) return take and (t-take.start) or 0 end
	local function closeSpan(c,at)
		if take and c.open then
			table.insert(take.spans,{id=c.id,sev=c.sev,owner=c.owner,text=c.text,t0=math.max(0,rel(c.since)),t1=math.max(0,rel(at or c.seen))})
		end
	end
	local function hold(group,stamp,id,sev,owner,text,minDur)
		local c=live[id]
		if not c then c={id=id,since=stamp};live[id]=c end
		c.group,c.sev,c.owner,c.text,c.seen,c.minDur=group,sev,owner,text,stamp,minDur or T.hold
		if not c.open and stamp-c.since>=c.minDur then c.open=true end
	end
	local function sweep(group,stamp)
		for id,c in live do
			if c.group==group and c.seen~=stamp then closeSpan(c);live[id]=nil end
		end
	end
	local function event(sev,owner,text,now)
		table.insert(recent,{t=now,sev=sev,owner=owner,text=text})
		while #recent>40 do table.remove(recent,1) end
		if take then table.insert(take.events,{t=rel(now),sev=sev,owner=owner,text=text}) end
	end

	-- Which two bodies, who they are, and who is acting.
	local function actors()
		if self.actorsOverride then
			local a,b=self.actorsOverride[1],self.actorsOverride[2]
			if a and a.Parent and b and b.Parent then return a,b end
			self.actorsOverride=nil
		end
		return duelModels()
	end
	local function duelData()
		local ok,data=pcall(function() return ctx and ctx.state and ctx.state() end)
		if ok and type(data)=="table" and data.phase=="Duel" and not self.actorsOverride then return data end
		return nil
	end
	local function nameOf(key,m,data)
		local d=data and data[key=="A" and "human" or "bot"]
		if d and d.fighter then return tostring(d.fighter) end
		if m then return tostring(m:GetAttribute("Fighter") or m.Name) end
		return key
	end
	-- true = acting, false = not acting, nil = unknown (a replay with no duel state)
	local function actingOf(key,data)
		if self.actingOverride then return string.find(self.actingOverride,key,1,true)~=nil end
		local d=data and data[key=="A" and "human" or "bot"]
		if not d then return nil end
		return ACT[d.state]==true and d.reaction==nil
	end

	local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude
	local function firstBlocker(from,to,ignore)
		local exclude={}
		for _,x in ignore do table.insert(exclude,x) end
		local dir=to-from
		for _=1,6 do
			rayParams.FilterDescendantsInstances=exclude
			local hit=workspace:Raycast(from,dir,rayParams)
			if not hit then return nil end
			local p=hit.Instance
			if p.Transparency<0.6 and p.LocalTransparencyModifier<0.6 then return p,hit end
			table.insert(exclude,p)
		end
		return nil
	end
	local function underFx(p)
		for _,n in FX_ROOTS do
			local r=workspace:FindFirstChild(n)
			if r and p:IsDescendantOf(r) then return true end
		end
		return false
	end
	-- "corps" (a fighter), "clone" (any other body), "effet", or "décor"
	local function classify(p,A,B,data)
		if A and p:IsDescendantOf(A) then return "corps",nameOf("A",A,data) end
		if B and p:IsDescendantOf(B) then return "corps",nameOf("B",B,data) end
		local bodies=workspace:FindFirstChild("NinjaDuelBodies")
		local m=p:FindFirstAncestorWhichIsA("Model")
		while m and m~=workspace do
			if m:FindFirstChildOfClass("Humanoid") or (bodies and m:IsDescendantOf(bodies)) then return "clone",m.Name end
			m=m.Parent and m.Parent:IsA("Model") and m.Parent or nil
		end
		if underFx(p) then return "effet",p.Name end
		local holder=p:FindFirstAncestorWhichIsA("Model")
		return "décor",(holder and holder~=workspace and holder.Name or p.Name)
	end

	--------------------------------------------------------------------
	-- Interface: the panel in the left margin, the band's two side lines,
	-- the guides inside the band (off while recording), the reopen chip.
	--------------------------------------------------------------------
	local gui=Instance.new("ScreenGui");gui.Name="ClipAssistPanel";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true
	gui.DisplayOrder=120;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Enabled=true;gui.Parent=playerGui
	-- ClipKit's NDHideUI hides every ScreenGui: this one stays (it is drawn outside the band).
	gui:GetPropertyChangedSignal("Enabled"):Connect(function() if not gui.Enabled then task.defer(function() gui.Enabled=true end) end end)
	local function frame(parent,props)
		local f=Instance.new("Frame");f.BorderSizePixel=0
		for k,v in props do f[k]=v end
		f.Parent=parent
		return f
	end
	local function label(parent,props)
		local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Font=Enum.Font.Gotham;t.TextSize=13;t.TextColor3=rgb(230,232,236)
		t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Top;t.TextWrapped=true;t.RichText=true
		for k,v in props do t[k]=v end
		t.Parent=parent
		return t
	end
	local function button(parent,text,onClick,props)
		local b=Instance.new("TextButton");b.AutoButtonColor=true;b.BorderSizePixel=0;b.BackgroundColor3=rgb(52,58,70);b.TextColor3=rgb(240,240,240)
		b.Font=Enum.Font.GothamBold;b.TextSize=13;b.Text=text;b.Size=UDim2.fromOffset(100,26)
		for k,v in props or {} do b[k]=v end
		b.Parent=parent
		local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,4);corner.Parent=b
		b.MouseButton1Click:Connect(onClick)
		return b
	end
	local lineL=frame(gui,{Name="BandLeft",BackgroundColor3=OK_COLOR,Size=UDim2.fromOffset(3,0)})
	local lineR=frame(gui,{Name="BandRight",BackgroundColor3=OK_COLOR,Size=UDim2.fromOffset(3,0)})
	local guides=frame(gui,{Name="Guides",BackgroundTransparency=1})
	for i=1,2 do
		frame(guides,{BackgroundColor3=rgb(255,255,255),BackgroundTransparency=0.7,Size=UDim2.new(0,1,1,0),Position=UDim2.new(i/3,0,0,0)})
		frame(guides,{BackgroundColor3=rgb(255,255,255),BackgroundTransparency=0.7,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,i/3,0)})
	end
	-- What TikTok and Shorts lay over the video: the caption at the bottom, the buttons on the right.
	frame(guides,{BackgroundColor3=rgb(255,90,90),BackgroundTransparency=0.88,Size=UDim2.new(1,0,0.2,0),Position=UDim2.new(0,0,0.8,0)})
	frame(guides,{BackgroundColor3=rgb(255,90,90),BackgroundTransparency=0.88,Size=UDim2.new(0.16,0,0.5,0),Position=UDim2.new(0.84,0,0.3,0)})

	local panel=frame(gui,{Name="Panel",BackgroundColor3=rgb(20,23,30),BackgroundTransparency=0.08,Position=UDim2.fromOffset(8,8),Visible=false})
	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,6);corner.Parent=panel
	local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10);pad.PaddingTop=UDim.new(0,8);pad.PaddingBottom=UDim.new(0,8);pad.Parent=panel
	local scroll=Instance.new("ScrollingFrame");scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.Size=UDim2.fromScale(1,1)
	scroll.ScrollBarThickness=4;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.Parent=panel
	local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,6);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
	local order=0
	local function row(h)
		order+=1
		local f=frame(scroll,{BackgroundTransparency=1,Size=UDim2.new(1,-6,0,h),LayoutOrder=order})
		return f
	end
	local function section(title)
		order+=1
		label(scroll,{Text=title,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=rgb(160,170,185),Size=UDim2.new(1,-6,0,16),LayoutOrder=order})
	end
	local function block()
		order+=1
		return label(scroll,{Text="",Size=UDim2.new(1,-6,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=order})
	end
	local head=row(28)
	label(head,{Text="<b>TOURNAGE</b> · F4",TextSize=15,Size=UDim2.new(1,-150,1,0),TextYAlignment=Enum.TextYAlignment.Center})
	local timer=label(head,{Text="",TextSize=14,Size=UDim2.fromOffset(52,28),Position=UDim2.new(1,-150,0,0),TextYAlignment=Enum.TextYAlignment.Center,TextXAlignment=Enum.TextXAlignment.Right})
	local recButton
	local warnNarrow=block()
	section("AVANT DE TOURNER")
	local checkText=block()
	local buttons=row(26)
	local hl=Instance.new("UIListLayout");hl.FillDirection=Enum.FillDirection.Horizontal;hl.Padding=UDim.new(0,6);hl.Parent=buttons
	section("EN CE MOMENT")
	local liveText=block()
	section("PLAN VU DU DESSUS")
	local plan=row(150)
	local planBox=frame(plan,{BackgroundColor3=rgb(32,36,46),Size=UDim2.fromOffset(150,150)})
	label(plan,{Text='<font color="#5AA0FF">●</font> A  <font color="#FF6A6A">●</font> B\n<font color="#FFFFFF">▲</font> caméra\n<font color="#FFD24A">●</font> soleil\ntrait = regard',TextSize=12,
		Size=UDim2.new(1,-160,1,0),Position=UDim2.fromOffset(160,0),TextColor3=rgb(170,178,190)})
	section("DERNIÈRE PRISE")
	local lastText=block()
	section("À FAIRE À LA MAIN")
	local reminders=block()
	reminders.TextColor3=rgb(150,158,170);reminders.TextSize=12
	reminders.Text="• OBS : une prise par enregistrement, puis regarder le fichier en entier.\n"
		.."• OBS sur un autre bureau ; un clic sur la barre de titre de Studio avant de lancer.\n"
		.."• Aucune autre place en Play pendant la prise.\n"
		.."• OBS à 30 i/s, recadré sur la bande 9:16 (les deux traits de couleur).\n"
		.."• Personne ne touche le Mac pendant la prise."

	local chip=button(gui,"🎬 F4",function() self:show(true) end,{Name="Chip",Size=UDim2.fromOffset(64,26),Position=UDim2.fromOffset(8,8),Visible=true})

	-- Plan markers (top-down, north up).
	local function dot(color,size)
		local f=frame(planBox,{BackgroundColor3=color,Size=UDim2.fromOffset(size,size),AnchorPoint=Vector2.new(0.5,0.5),ZIndex=3})
		local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=f
		return f
	end
	local function line(color,thick)
		return frame(planBox,{BackgroundColor3=color,AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(1,thick or 2),ZIndex=2})
	end
	local P={A=dot(rgb(90,160,255),9),B=dot(rgb(255,106,106),9),cam=dot(rgb(255,255,255),7),sun=dot(rgb(255,210,74),9),
		lookA=line(rgb(90,160,255)),lookB=line(rgb(255,106,106)),lookCam=line(rgb(255,255,255),1),fovL=line(rgb(255,255,255),1),fovR=line(rgb(255,255,255),1)}
	local function placeLine(l,a,b)
		local d=b-a
		l.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
		l.Size=UDim2.fromOffset(math.max(1,d.Magnitude),l.Size.Y.Offset)
		l.Rotation=math.deg(math.atan2(d.Y,d.X))
	end

	--------------------------------------------------------------------
	-- Prepare / restore the image (this screen only).
	--------------------------------------------------------------------
	local function prepare()
		if saved then return end
		saved={guis={},effects={},mouse=UIS.MouseIconEnabled,core={}}
		-- The game turns some Roblox panels off itself (health, chat): put back only what was on.
		for _,t in Enum.CoreGuiType:GetEnumItems() do
			if t~=Enum.CoreGuiType.All then
				local ok,on=pcall(function() return StarterGui:GetCoreGuiEnabled(t) end)
				if ok then saved.core[t]=on end
			end
		end
		pcall(function() if dev and dev.toggle then dev:toggle(false) end end)
		pcall(function() if dev and dev.visual and dev.visual.setMode then dev.visual:setMode(0) end end)
		for _,g in playerGui:GetChildren() do
			if g:IsA("ScreenGui") and g~=gui and g.Enabled and not DEV_GUIS[g.Name] then saved.guis[g]=true;g.Enabled=false end
		end
		local cam=workspace.CurrentCamera
		for _,root in {Lighting,cam} do
			for _,e in root:GetChildren() do
				if (e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect")) and e.Enabled then saved.effects[e]=true;e.Enabled=false end
			end
		end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end)
		UIS.MouseIconEnabled=false
	end
	local function restore()
		if not saved then return end
		for g in saved.guis do if g.Parent then g.Enabled=true end end
		for e in saved.effects do if e.Parent then e.Enabled=true end end
		for t,on in saved.core do pcall(function() StarterGui:SetCoreGuiEnabled(t,on) end) end
		UIS.MouseIconEnabled=saved.mouse
		saved=nil
	end

	--------------------------------------------------------------------
	-- The take: start, stop, summary.
	--------------------------------------------------------------------
	local function buildLine()
		local s=ReplicatedStorage:FindFirstChild("NinjaDuel")
		local function v(n) local x=s and s:FindFirstChild(n);return x and x.Value or "?" end
		return "BUILD "..string.sub(tostring(v("BuildFingerprint")),1,12).." | RUNTIME "..string.sub(tostring(v("RuntimeFingerprint")),1,12).." @ "..tostring(v("SourceCommit"))
	end
	local function merge(list)
		table.sort(list,function(a,b) return a[1]<b[1] end)
		local out={}
		for _,r in list do
			local top=out[#out]
			if top and r[1]<=top[2]+0.05 then top[2]=math.max(top[2],r[2]) else table.insert(out,{r[1],r[2]}) end
		end
		return out
	end
	local function clean(bad,dur)
		local out,at={},0
		for _,r in merge(bad) do
			if r[1]-at>=T.clean then table.insert(out,{at,r[1]}) end
			at=math.max(at,r[2])
		end
		if dur-at>=T.clean then table.insert(out,{at,dur}) end
		return out
	end
	local function ranges(list)
		local parts={}
		for _,r in list do table.insert(parts,fmt(r[1]).."–"..fmt(r[2]).." s") end
		return #parts>0 and table.concat(parts," ; ") or "aucune"
	end
	local function summarize(tk,now)
		local dur=math.max(0,now-tk.start)
		local bad,soft={},{}
		for _,s in tk.spans do
			if s.sev>=ERR then table.insert(bad,{s.t0,s.t1}) end
			if s.sev>=WARN then table.insert(soft,{s.t0,s.t1}) end
		end
		for _,e in tk.events do
			if e.sev>=ERR then table.insert(bad,{e.t-0.1,e.t+0.1}) end
			if e.sev>=WARN then table.insert(soft,{e.t-0.1,e.t+0.1}) end
		end
		-- One line per fault: its total time and its first moments.
		local byText={}
		local function note(sev,owner,text,t0,t1)
			local key=text:gsub("%d+[,.]?%d*","#")
			local e=byText[key]
			if not e then e={sev=sev,owner=owner,text=text,total=0,at={}};byText[key]=e end
			e.sev=math.max(e.sev,sev);e.total+=math.max(0,t1-t0)
			if #e.at<6 then table.insert(e.at,t0) end
		end
		for _,s in tk.spans do note(s.sev,s.owner,s.text,s.t0,s.t1) end
		for _,e in tk.events do note(e.sev,e.owner,e.text,e.t,e.t) end
		local faults={}
		for _,e in byText do table.insert(faults,e) end
		table.sort(faults,function(a,b) if a.sev~=b.sev then return a.sev>b.sev end;return a.total>b.total end)
		local counts={err=0,warn=0,info=0}
		for _,f in faults do if f.sev>=ERR then counts.err+=1 elseif f.sev>=WARN then counts.warn+=1 else counts.info+=1 end end
		return {label=tk.label,duration=dur,build=tk.build,clean=clean(bad,dur),cleanStrict=clean(soft,dur),counts=counts,
			faults=faults,cuts=tk.cuts,hitches=tk.hitches,spans=tk.spans,events=tk.events}
	end
	local function startTake(label)
		if take then return end
		take={label=label or ("prise "..os.date("%H:%M:%S")),start=os.clock(),spans={},events={},cuts={},hitches=0,build=buildLine()}
		print("[NinjaDuelClip] REC "..take.label.." | "..take.build)
	end
	local function stopTake()
		if not take then return last end
		local now=os.clock()
		for _,c in live do closeSpan(c,now) end
		last=summarize(take,now)
		take=nil
		print("[NinjaDuelClip] "..HttpService:JSONEncode({label=last.label,duration=last.duration,build=last.build,clean=last.clean,cleanStrict=last.cleanStrict,
			counts=last.counts,faults=last.faults,cuts=last.cuts,hitches=last.hitches}))
		return last
	end

	--------------------------------------------------------------------
	-- Checks.
	--------------------------------------------------------------------
	local fpsWin={}
	local lastCam=nil
	local motion={move=0.3,turn=1.5}
	local lastCut=-math.huge
	local flashSince=setmetatable({},{__mode="k"})
	local lights={}
	local highlights={}

	local function project(cam,p)
		local v=cam:WorldToViewportPoint(p)
		return v,(v.Z>0 and v.X>=band.x0 and v.X<=band.x1 and v.Y>=0 and v.Y<=band.h)
	end

	local function tickChecks(now)
		local G="tick"
		local cam=workspace.CurrentCamera
		local camPos,look=cam.CFrame.Position,cam.CFrame.LookVector
		local data=duelData()
		local A,B=actors()
		self.found=A~=nil and B~=nil
		local info={}
		for _,key in {"A","B"} do
			local m=key=="A" and A or B
			if m and m.Parent then
				local parts=partsOf(m)
				local root=rootOf(m)
				local cf=pivotOf(m)
				if parts.head and cf then
					info[key]={m=m,name=nameOf(key,m,data),acting=actingOf(key,data),parts=parts,root=root,cf=cf}
				end
			end
		end
		local shares={}
		for key,x in info do
			local other=info[key=="A" and "B" or "A"]
			local id=key..":"
			local name=x.name
			local headV,headIn=project(cam,x.parts.head.Position)
			local torsoIn=headIn
			if x.parts.torso then
				local _,inBand=project(cam,x.parts.torso.Position)
				torsoIn=inBand
			end
			local top=x.parts.head.Position+V(0,x.parts.head.Size.Y/2,0)
			local feet=(x.root and x.root.Position or x.cf.Position)-V(0,3,0)
			local topV=cam:WorldToViewportPoint(top)
			local feetV=cam:WorldToViewportPoint(feet)
			if headV.Z>0 then shares[key]=math.abs(feetV.Y-topV.Y)/math.max(1,band.h) end
			-- Out of the band.
			if not headIn and not torsoIn then
				if x.acting==true then hold(G,now,id.."out",ERR,"cadrage",name.." agit hors du cadre")
				elseif other and other.acting==true then hold(G,now,id.."out",WARN,"cadrage","l'action à deux n'est cadrée qu'à moitié : "..name.." hors du cadre",0.3) end
			elseif headIn and topV.Z>0 and topV.Y<0 then
				hold(G,now,id.."top",WARN,"cadrage","tête de "..name.." coupée en haut",0.3)
			end
			-- Seen from behind while acting.
			if headIn or torsoIn then
				local fwd=flat(x.cf.LookVector)
				local toCam=flat(camPos-x.cf.Position)
				if fwd.Magnitude>0.1 and toCam.Magnitude>0.1 then
					local ang=math.deg(math.acos(math.clamp(fwd.Unit:Dot(toCam.Unit),-1,1)))
					if ang>T.back then
						if x.acting==true then hold(G,now,id.."back",ERR,"cadrage",name.." filmé de dos pendant son action ("..math.floor(ang).."°)")
						elseif x.acting==nil then hold(G,now,id.."back",WARN,"cadrage",name.." de dos ("..math.floor(ang).."°)",0.5) end
					end
				end
			end
			-- Something between the lens and the body.
			if headIn or torsoIn then
				local ignore={x.m}
				local hb,hk=firstBlocker(camPos,x.parts.head.Position,ignore)
				local tb,tk=nil,nil
				if x.parts.torso then tb,tk=firstBlocker(camPos,x.parts.torso.Position,ignore) end
				local blocker=hb or tb
				if blocker then
					local kind,what=classify(blocker,A,B,data)
					local full=hb~=nil and (tb~=nil or not x.parts.torso)
					local by=(kind=="corps" and ("le corps de "..what)) or (kind=="clone" and ("un clone ("..what..")")) or (kind=="effet" and ("un effet ("..what..")")) or ("le décor ("..what..")")
					if kind=="effet" then
						if full and x.acting~=false then hold(G,now,id.."hid",WARN,"cadrage",name.." caché par "..by,0.6) end
					elseif full then
						hold(G,now,id.."hid",x.acting==false and WARN or ERR,"cadrage",name.." caché par "..by)
					elseif x.acting~=false then
						hold(G,now,id.."hid",WARN,"cadrage",name.." à moitié caché par "..by,0.25)
					end
				elseif x.acting==true and #x.parts.hands>0 then
					local hidden=0
					for _,h in x.parts.hands do if firstBlocker(camPos,h.Position,ignore) then hidden+=1 end end
					if hidden==#x.parts.hands then hold(G,now,id.."hands",WARN,"cadrage","on ne voit pas les mains de "..name.." (le geste est caché)",0.3) end
				end
			end
			-- The interface TikTok and Shorts put over the video.
			if x.acting==true and headIn then
				local u=(headV.X-band.x0)/math.max(1,band.w)
				local vv=headV.Y/math.max(1,band.h)
				if vv>0.8 or (u>0.84 and vv>0.3 and vv<0.8) then hold(G,now,id.."ui",INFO,"cadrage","visage de "..name.." sous l'interface TikTok",0.5) end
			end
		end
		-- Both small: the hook needs the fighters big.
		if shares.A and shares.B then
			local big=math.max(shares.A,shares.B)
			if big<T.small then
				if take and now-take.start<T.opening then
					hold(G,now,"small",ERR,"cadrage",string.format("ouverture : persos trop petits (%d %% de la hauteur) — les 2 premières secondes décident",math.floor(big*100)),0.1)
				else
					hold(G,now,"small",WARN,"cadrage",string.format("persos petits à l'image (%d %% de la hauteur)",math.floor(big*100)),1.5)
				end
			end
		end
		-- Two bodies in one place: a game fault, filmed as it is.
		if info.A and info.B and info.A.root and info.B.root then
			if (info.A.root.Position-info.B.root.Position).Magnitude<1.8 then hold(G,now,"inside",WARN,"jeu","corps l'un dans l'autre ("..info.A.name.." / "..info.B.name..")",0.2) end
		end
		-- Something stuck on the lens.
		local cf=cam.CFrame
		for _,d in {cf.LookVector,(cf*CFrame.Angles(0,math.rad(12),0)).LookVector,(cf*CFrame.Angles(0,math.rad(-12),0)).LookVector,(cf*CFrame.Angles(math.rad(8),0,0)).LookVector,(cf*CFrame.Angles(math.rad(-8),0,0)).LookVector} do
			local p,hit=firstBlocker(camPos,camPos+d*T.lens,{})
			if p and hit and hit.Normal.Y<0.8 then
				local kind,what=classify(p,A,B,data)
				local sev=(kind=="corps" or kind=="clone" or kind=="décor") and ERR or WARN
				hold(G,now,"lens",sev,"cadrage",(kind=="corps" and ("le corps de "..what) or what).." collé à l'objectif (image bouchée)",0.1)
				break
			end
		end
		-- The lens inside a wall, a tree or an effect.
		local ok,inside=pcall(function() return workspace:GetPartBoundsInRadius(camPos,0.25) end)
		if ok then
			for _,p in inside do
				if not p:IsA("Terrain") and p.Transparency<0.6 and p.LocalTransparencyModifier<0.6 then
					local lp=p.CFrame:PointToObjectSpace(camPos)
					local h=p.Size/2
					if math.abs(lp.X)<h.X and math.abs(lp.Y)<h.Y and math.abs(lp.Z)<h.Z then
						local kind,what=classify(p,A,B,data)
						if kind=="effet" then hold(G,now,"inside-cam",WARN,"cadrage","caméra dans un effet ("..what..")",0.2)
						else hold(G,now,"inside-cam",ERR,"cadrage","caméra dans "..(kind=="décor" and ("le décor ("..what..")") or what),0.1) end
						break
					end
				end
			end
		end
		-- Facing the sun.
		local sun=Lighting:GetSunDirection()
		if sun.Y>0.03 and look:Dot(sun)>math.cos(math.rad(T.sun)) then
			hold(G,now,"sun",WARN,"cadrage","caméra face au soleil (éblouissement) : garder le soleil derrière l'objectif",0.3)
		end
		-- A full-body flash that stays (overexposes the shot).
		for h in highlights do
			if h.Parent and h.Enabled and h.FillTransparency<0.35 then
				local target=h.Adornee or h.Parent
				local who=nil
				for key,x in info do if target==x.m or (target and target:IsDescendantOf(x.m)) then who=x.name end end
				if who then
					flashSince[h]=flashSince[h] or now
					if now-flashSince[h]>0.3 then hold(G,now,"flash:"..who,WARN,"jeu","flash plein corps sur "..who.." (surexpose)",0) end
				end
			else
				flashSince[h]=nil
			end
		end
		self.info=info
		sweep(G,now)
	end

	local function guiCovers(g)
		-- The first visible thing of this ScreenGui inside the band, if any.
		for _,o in g:GetDescendants() do
			if o:IsA("GuiObject") and o.AbsoluteSize.X>4 and o.AbsoluteSize.Y>4 then
				local drawn=(o.BackgroundTransparency<0.95) or ((o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text~="" and o.TextTransparency<0.9) or ((o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image~="" and o.ImageTransparency<0.9)
				if drawn then
					local p,s=o.AbsolutePosition,o.AbsoluteSize
					if p.X<band.x1 and p.X+s.X>band.x0 and p.Y<band.h and p.Y+s.Y>0 then
						local visible=o.Visible
						local a=o.Parent
						while visible and a and a~=g do
							if a:IsA("GuiObject") and not a.Visible then visible=false end
							a=a.Parent
						end
						if visible then return o end
					end
				end
			end
		end
		return nil
	end

	local function slowChecks(now)
		local G="slow"
		local check={}
		-- Frame rate over the last two seconds.
		local sum=0
		for _,f in fpsWin do sum+=f[2] end
		local fps=#fpsWin>10 and sum>0 and #fpsWin/sum or nil
		self.fps=fps
		if fps then check.fps=fps>=55 end
		if fps and fps<T.lowFps and now-installedAt>5 then
			hold(G,now,"fps",take and ERR or WARN,"machine",string.format("Studio à %d i/s : fenêtre au premier plan ? autre place en Play ? Mac occupé ?",math.floor(fps)),0)
		end
		-- Graphics quality.
		local level,auto=quality()
		self.quality=auto and "Automatique" or level
		if auto then check.quality=false elseif level then check.quality=true end
		if auto then hold(G,now,"quality",ERR,"reglage","qualité graphique Automatique : Roblox retire des particules quand le Mac rame (mettre un niveau fixe)",0) end
		-- Post effects.
		local dof,rays=false,false
		for _,root in {Lighting,workspace.CurrentCamera} do
			for _,e in root:GetChildren() do
				if e:IsA("DepthOfFieldEffect") and e.Enabled then dof=true end
				if e:IsA("SunRaysEffect") and e.Enabled and e.Intensity>0.01 then rays=true end
			end
		end
		check.dof=not dof;check.rays=not rays;check.shadows=Lighting.GlobalShadows
		if dof then hold(G,now,"dof",ERR,"reglage","profondeur de champ allumée (elle fait saccader la prise)",0) end
		if rays then hold(G,now,"rays",WARN,"reglage","rayons du soleil allumés (éblouissent)",0) end
		if not Lighting.GlobalShadows then hold(G,now,"shadows",WARN,"reglage","ombres coupées (GlobalShadows)",0) end
		-- What is drawn over the band: the game's HUD, the dev panels.
		local hud,panels=false,{}
		for _,g in playerGui:GetChildren() do
			if g:IsA("ScreenGui") and g~=gui and g.Enabled then
				local o=guiCovers(g)
				if o then
					if DEV_GUIS[g.Name] then panels[DEV_GUIS[g.Name]]=true else hud=true end
				end
			end
		end
		check.hud=not hud or self.allowHud
		check.panels=next(panels)==nil
		if hud and not self.allowHud then hold(G,now,"hud",WARN,"reglage","HUD du jeu dans l'image (« Préparer l'image » le cache)",0) end
		for k in panels do hold(G,now,"panel"..k,ERR,"reglage","panneau "..k.." ouvert dans l'image",0) end
		-- The mouse pointer.
		local mouse=UIS:GetMouseLocation()
		local cursor=UIS.MouseIconEnabled and mouse.X>band.x0 and mouse.X<band.x1
		check.cursor=not cursor
		if cursor then hold(G,now,"cursor",WARN,"reglage","curseur de la souris dans l'image",0.5) end
		-- Lights and highlights near the fighters (refreshed once a second).
		table.clear(lights);table.clear(highlights)
		local A,B=actors()
		check.duel=A~=nil and B~=nil
		local roots={}
		for _,n in FX_ROOTS do local r=workspace:FindFirstChild(n);if r then table.insert(roots,r) end end
		if A then table.insert(roots,A) end
		if B then table.insert(roots,B) end
		for _,r in roots do
			for _,d in r:GetDescendants() do
				if d:IsA("Light") then table.insert(lights,d) elseif d:IsA("Highlight") then highlights[d]=true end
			end
		end
		local info=self.info or {}
		for _,l in lights do
			if l.Enabled and l.Brightness>1 then
				local _,s=l.Color:ToHSV()
				local at=l.Parent and (l.Parent:IsA("BasePart") and l.Parent.Position or (l.Parent:IsA("Attachment") and l.Parent.WorldPosition)) or nil
				if at and s>0.45 then
					for _,x in info do
						local range=(l:IsA("PointLight") or l:IsA("SpotLight")) and l.Range or 8
						if (x.parts.head.Position-at).Magnitude<range*0.8 then
							hold(G,now,"light:"..x.name,WARN,"jeu","lumière "..hueName(l.Color).." forte sur "..x.name.." (teinte la peau et le sol)",0)
						end
					end
				end
			end
		end
		self.check=check
		sweep(G,now)
	end

	--------------------------------------------------------------------
	-- Errors from the game while filming.
	--------------------------------------------------------------------
	LogService.MessageOut:Connect(function(message,kind)
		if kind==Enum.MessageType.MessageError and not string.find(message,"[NinjaDuelClip]",1,true) then
			event(ERR,"jeu","erreur de script (client) : "..string.sub(message,1,120),os.clock())
		end
	end)
	task.spawn(function()
		local log=ReplicatedStorage:WaitForChild("NinjaDuelDevLog",15)
		if not log then return end
		log.OnClientEvent:Connect(function(kind,payload)
			if kind=="serverlog" and type(payload)=="table" and payload.k=="error" then
				event(ERR,"jeu","erreur de script (serveur) : "..string.sub(tostring(payload.m),1,120),os.clock())
			end
		end)
	end)

	--------------------------------------------------------------------
	-- Drawing.
	--------------------------------------------------------------------
	local function worst()
		local w=0
		for _,c in live do if c.open and c.sev>w then w=c.sev end end
		local now=os.clock()
		for _,e in recent do if now-e.t<1.5 and e.sev>w then w=e.sev end end
		return w
	end
	local function liveLines(now)
		local list={}
		for _,c in live do if c.open then table.insert(list,{sev=c.sev,owner=c.owner,text=c.text,dur=now-c.since}) end end
		for _,e in recent do if now-e.t<4 then table.insert(list,{sev=e.sev,owner=e.owner,text=e.text,ago=now-e.t}) end end
		table.sort(list,function(a,b) if a.sev~=b.sev then return a.sev>b.sev end;return (a.dur or 0)>(b.dur or 0) end)
		return list
	end
	local function layoutBand()
		local vp=workspace.CurrentCamera.ViewportSize
		local w=math.min(vp.X,vp.Y*CROPW)
		band.x0=(vp.X-w)/2;band.x1=band.x0+w;band.w=w;band.h=vp.Y
		lineL.Position=UDim2.fromOffset(band.x0-7,0);lineL.Size=UDim2.new(0,3,1,0)
		lineR.Position=UDim2.fromOffset(band.x1+4,0);lineR.Size=UDim2.new(0,3,1,0)
		guides.Position=UDim2.fromOffset(band.x0,0);guides.Size=UDim2.new(0,w,1,0)
		local margin=band.x0-16
		local pw=math.clamp(margin,240,380)
		panel.Size=UDim2.new(0,pw,1,-16)
		self.narrow=margin<240
	end
	local function drawPlan()
		local info=self.info or {}
		local cam=workspace.CurrentCamera
		local pts={cam.CFrame.Position}
		for _,x in info do table.insert(pts,x.cf.Position) end
		local c=V(0,0,0)
		for _,p in pts do c+=p end
		c/=#pts
		local span=12
		for _,p in pts do span=math.max(span,(flat(p-c)).Magnitude*1.25) end
		local s=70/span
		local function at(p) local d=p-c;return Vector2.new(75+d.X*s,75+d.Z*s) end
		for _,key in {"A","B"} do
			local x=info[key]
			P[key].Visible=x~=nil;P["look"..key].Visible=x~=nil
			if x then
				local p=at(x.cf.Position)
				P[key].Position=UDim2.fromOffset(p.X,p.Y)
				local f=flat(x.cf.LookVector);if f.Magnitude>0.1 then f=f.Unit end
				placeLine(P["look"..key],p,p+Vector2.new(f.X,f.Z)*16)
			end
		end
		local cp=at(cam.CFrame.Position)
		P.cam.Position=UDim2.fromOffset(cp.X,cp.Y)
		local l=flat(cam.CFrame.LookVector);if l.Magnitude>0.1 then l=l.Unit end
		local half=math.rad(cam.FieldOfView/2*CROPW)
		local function rot(v,a) return Vector2.new(v.X*math.cos(a)-v.Z*math.sin(a),v.X*math.sin(a)+v.Z*math.cos(a)) end
		placeLine(P.lookCam,cp,cp+Vector2.new(l.X,l.Z)*40)
		placeLine(P.fovL,cp,cp+rot(l,half)*60)
		placeLine(P.fovR,cp,cp+rot(l,-half)*60)
		local sun=flat(Lighting:GetSunDirection())
		P.sun.Visible=sun.Magnitude>0.05
		if sun.Magnitude>0.05 then sun=sun.Unit;P.sun.Position=UDim2.fromOffset(75+sun.X*68,75+sun.Z*68) end
	end
	local function render(now)
		layoutBand()
		local w=worst()
		local color=w>=ERR and SEVCOLOR[ERR] or w>=WARN and SEVCOLOR[WARN] or OK_COLOR
		lineL.BackgroundColor3=color;lineR.BackgroundColor3=color
		guides.Visible=self.guides and take==nil
		panel.Visible=self.shown and not (take and self.narrow)
		chip.Visible=not self.shown
		if not self.shown then return end
		warnNarrow.Text=self.narrow and '<font color="#F0AA3C">Fenêtre étroite : le panneau couvre la bande 9:16 ; il se cache pendant une prise.</font>' or ""
		warnNarrow.Visible=self.narrow==true
		timer.Text=take and string.format('<font color="#EB5050">● %s</font>',fmt(now-take.start)) or ""
		recButton.Text=take and "■ STOP" or "● REC"
		recButton.BackgroundColor3=take and rgb(150,40,40) or rgb(52,58,70)
		local ck=self.check or {}
		local function item(ok,text,detail)
			local mark=ok==nil and '<font color="#8A94A3">?</font>' or ok and '<font color="#5AC878">✓</font>' or '<font color="#EB5050">✗</font>'
			return mark.." "..text..(detail and (' <font color="#8A94A3">'..detail.."</font>") or "")
		end
		checkText.Text=table.concat({
			item(ck.duel,"Combat trouvé",self.actorsOverride and "(corps choisis à la main)" or nil),
			item(ck.quality,"Qualité graphique fixe",self.quality and ("("..tostring(self.quality)..")") or nil),
			item(ck.fps,"Image fluide (≥ 55 i/s)",self.fps and ("("..math.floor(self.fps).." i/s)") or nil),
			item(ck.dof,"Profondeur de champ coupée"),
			item(ck.rays,"Rayons du soleil coupés"),
			item(ck.shadows,"Ombres allumées"),
			item(ck.hud,"HUD du jeu hors de l'image",self.allowHud and "(HUD voulu)" or nil),
			item(ck.panels,"Panneaux F6 / F7 fermés"),
			item(ck.cursor,"Curseur hors de l'image"),
		},"\n")
		local lines={}
		for i,e in liveLines(now) do
			if i>10 then break end
			local tag=string.format('<font color="%s"><b>%s</b></font>',hex(SEVCOLOR[e.sev]),SEVNAME[e.sev])
			local when=e.dur and (" · "..fmt(e.dur).." s") or (" · il y a "..fmt(e.ago).." s")
			table.insert(lines,tag.." "..esc(e.text)..'<font color="#8A94A3"> · '..OWNER[e.owner]..when.."</font>")
		end
		liveText.Text=#lines>0 and table.concat(lines,"\n") or '<font color="#5AC878">Rien à signaler.</font>'
		if last then
			local f={}
			table.insert(f,string.format("<b>%s</b> · %s s · %d erreur(s), %d à voir",esc(last.label),fmt(last.duration),last.counts.err,last.counts.warn))
			table.insert(f,'<font color="#5AC878">Plages propres :</font> '..ranges(last.clean))
			table.insert(f,'<font color="#8A94A3">Sans rien « à voir » : '..ranges(last.cleanStrict).."</font>")
			for i,x in last.faults do
				if i>8 then break end
				local at={}
				for _,t in x.at do table.insert(at,fmt(t)) end
				table.insert(f,string.format('<font color="%s">%s</font> %s <font color="#8A94A3">· %s · à %s s</font>',hex(SEVCOLOR[x.sev]),SEVNAME[x.sev],esc(x.text),OWNER[x.owner],table.concat(at,", ")))
			end
			if #last.cuts>0 then
				local cuts={}
				for i,t in last.cuts do if i<=12 then table.insert(cuts,fmt(t)) end end
				table.insert(f,'<font color="#8A94A3">Coupes caméra à '..table.concat(cuts,", ").." s</font>")
			end
			lastText.Text=table.concat(f,"\n")
		else
			lastText.Text='<font color="#8A94A3">Pas encore de prise. « ● REC » au moment où OBS démarre, « ■ STOP » à l\'arrêt.</font>'
		end
		drawPlan()
	end

	--------------------------------------------------------------------
	-- Buttons, keys, the per-frame loop.
	--------------------------------------------------------------------
	recButton=button(head,"● REC",function() if take then stopTake() else startTake() end end,{Size=UDim2.fromOffset(84,26),Position=UDim2.new(1,-90,0,1)})
	button(buttons,"Préparer l'image",prepare,{Size=UDim2.fromOffset(122,26)})
	button(buttons,"Rétablir",restore,{Size=UDim2.fromOffset(70,26)})
	button(buttons,"Repères",function() self.guides=not self.guides end,{Size=UDim2.fromOffset(70,26)})
	button(buttons,"✕",function() self:show(false) end,{Size=UDim2.fromOffset(28,26)})

	function self:show(on)
		self.shown=on==true
	end
	UIS.InputBegan:Connect(function(key,processed)
		if not processed and key.KeyCode==Enum.KeyCode.F4 then self:show(not self.shown) end
	end)

	local tickAcc,slowAt,drawAt=0,0,0
	RunService:BindToRenderStep("NinjaDuelClipAssist",Enum.RenderPriority.Last.Value+50,function(dt)
		local now=os.clock()
		table.insert(fpsWin,{now,dt})
		while fpsWin[1] and now-fpsWin[1][1]>2 do table.remove(fpsWin,1) end
		-- A frozen image: a frame much longer than the ones around it.
		if now-installedAt>3 and dt>T.hitch then
			local sum=0
			for _,f in fpsWin do sum+=f[2] end
			local mean=#fpsWin>0 and sum/#fpsWin or dt
			if dt>3*mean or dt>0.1 then
				event(take and ERR or WARN,"machine",string.format("image figée (%d ms)",math.floor(dt*1000)),now)
				if take then take.hitches+=1 end
			end
		end
		-- The camera: a cut, or a jump inside a shot.
		local cam=workspace.CurrentCamera
		local cf=cam.CFrame
		local pos,look,fov=cf.Position,cf.LookVector,cam.FieldOfView
		if lastCam then
			local move=(pos-lastCam.pos).Magnitude
			local turn=math.deg(math.acos(math.clamp(look:Dot(lastCam.look),-1,1)))
			if move>T.cutMove or turn>T.cutTurn then
				if take then table.insert(take.cuts,now-take.start) end
				if now-lastCut<T.cutGap then event(WARN,"cadrage","deux coupes en "..fmt(now-lastCut).." s",now) end
				lastCut=now
			elseif (move>T.jumpMove and move>4*motion.move) or (turn>T.jumpTurn and turn>4*motion.turn) or math.abs(fov-lastCam.fov)>6 then
				event(WARN,"cadrage",string.format("saut de caméra (%s studs, %d°)",fmt(move),math.floor(turn)),now)
			else
				motion.move=motion.move*0.9+move*0.1;motion.turn=motion.turn*0.9+turn*0.1
			end
		end
		lastCam={pos=pos,look=look,fov=fov}
		tickAcc+=dt
		if tickAcc>=T.tick then
			tickAcc=0
			local ok,err=pcall(tickChecks,now)
			if not ok then warn("[NinjaDuelClip] tick: "..tostring(err)) end
		end
		if now-slowAt>=1 then
			slowAt=now
			local ok,err=pcall(slowChecks,now)
			if not ok then warn("[NinjaDuelClip] slow: "..tostring(err)) end
		end
		if now-drawAt>=1/8 then
			drawAt=now
			local ok,err=pcall(render,now)
			if not ok then warn("[NinjaDuelClip] draw: "..tostring(err)) end
		end
	end)

	--------------------------------------------------------------------
	-- For agents and scripts (NDDirector, execute_luau).
	--------------------------------------------------------------------
	local function snapshot()
		local now=os.clock()
		local list={}
		for _,e in liveLines(now) do table.insert(list,{severity=SEVNAME[e.sev],owner=OWNER[e.owner],text=e.text,seconds=e.dur,ago=e.ago}) end
		return {shown=self.shown,recording=take~=nil,takeSeconds=take and (now-take.start) or nil,label=take and take.label or nil,
			check=self.check,quality=self.quality,fps=self.fps,narrow=self.narrow,band={x0=band.x0,x1=band.x1,height=band.h},
			now=list,last=last and {label=last.label,duration=last.duration,clean=last.clean,cleanStrict=last.cleanStrict,counts=last.counts,
				faults=last.faults,cuts=last.cuts,hitches=last.hitches} or nil,build=buildLine()}
	end
	local bindable=Instance.new("BindableFunction");bindable.Name="Report";bindable.Parent=gui
	bindable.OnInvoke=function(op,arg,extra)
		if op=="rec" then
			if arg=="start" then startTake(extra) elseif arg=="stop" then stopTake() end
		elseif op=="prepare" then prepare()
		elseif op=="restore" then restore()
		elseif op=="actors" then self.actorsOverride=(type(arg)=="table" and arg[1] and arg[2]) and {arg[1],arg[2]} or nil
		elseif op=="acting" then self.actingOverride=type(arg)=="string" and arg or nil
		elseif op=="show" then self:show(arg~=false)
		elseif op=="guides" then self.guides=arg~=false
		elseif op=="allowHud" then self.allowHud=arg==true
		end
		return HttpService:JSONEncode(snapshot())
	end
	self.prepare=prepare;self.restore=restore;self.startTake=startTake;self.stopTake=stopTake;self.snapshot=snapshot
	_G.NDClipAssist=self
	print("[NinjaDuelClip] assistant de tournage prêt (F4) | "..buildLine())
	return self
end

return Assist
