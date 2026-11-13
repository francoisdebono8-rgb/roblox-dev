--!nocheck
-- Assistant de tournage (F4) — place FILM seulement (build.py --capture).
--
-- Demandé le 13/11/2026 : un outil dans Studio pour que le CM tourne ses clips
-- sans défaut d'image, d'éclairage, de cadrage ni de caméra, et qu'il voie
-- tout de suite les erreurs qu'il fait. Revu le 13/11 après la relecture du CM
-- (claude/revue-outil-f4-par-le-cm-2026-11-13).
--
-- Il ne change pas le jeu : il lit la caméra, les deux corps (vivants ou
-- fantômes du replay NDReplay), la lumière et l'écran, et signale ce qui abîme
-- une prise, avec qui doit corriger : cadrage, réglage, machine, jeu.
-- Pendant une prise (REC), chaque défaut est daté ; à l'arrêt, le résumé donne
-- les plages propres, scène par scène, et un journal image par image.
--
-- Rien de ce qu'il dessine n'entre dans la bande 9:16 que garde OBS : panneau
-- dans la marge gauche, compteur d'images dans la marge droite, traits de
-- couleur à 24 points de la bande (cachés pendant une prise).
--
-- Tout se pilote aussi par des attributs de workspace, lisibles d'un script du
-- CM quel que soit l'endroit où il tourne (barre de commande, Studio MCP) :
--   NDRec   = "nom de la prise" démarre une prise ; false/nil l'arrête
--   NDAct   = "A" | "B" | "AB"  qui agit / doit être vu (sinon : l'état du duel)
--   NDScene = "B_chidori"       la scène en cours (sinon : NDBeat de ClipKit)
--   NDShot  = "T2"              la caméra / la prise en cours (sinon : NDTake)
--   NDClock = 12.34             le temps de la scène (replay), noté image par image
--   NDCut   = true              écran noir entre deux scènes : rien n'est jugé
-- et NDWarmup, écrit par « Préparer l'image » (os.clock()) pour qu'un script de
-- scène lance son préchauffage des effets.
--
-- Agents (Studio MCP, côté Client, pendant le Play) :
--   local r=game.Players.LocalPlayer.PlayerGui.ClipAssistPanel.Report
--   print(r:Invoke())                    état JSON
--   r:Invoke("rec","start","M1") / r:Invoke("rec","stop")   (comme NDRec)
--   r:Invoke("frames",{from=1,count=600}) le journal image par image de la dernière prise
--   r:Invoke("prepare") / r:Invoke("restore")
--   r:Invoke("actors",{a,b},{"Sasuke","Kakashi"})  les deux corps (replay) et leurs noms ; nil = le duel
--   r:Invoke("quality",12)               le niveau de qualité réglé (si la lecture se trompe)
--   r:Invoke("set",{clean=0.5,back=120}) régler un seuil (voir T)
--   r:Invoke("ignore",{"A:inside","sun"}) ne plus signaler ces défauts (préfixes d'id)
--   r:Invoke("show",true) · ("guides",false) · ("allowHud",true) · ("counter",false) · ("linesDuringRec",true)
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local HttpService=game:GetService("HttpService")
local LogService=game:GetService("LogService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")

local Sight=nil
pcall(function() Sight=require(script.Parent:WaitForChild("ClipSight",2)) end)

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
	hitch=0.05,             -- a frame longer than this, and 3x the mean, is a frozen image
	fpsWarn=50,fpsErr=32,   -- a 30 fps video needs 32
	lens=2.2,               -- studs in front of the lens
	sun=35,                 -- degrees between the lens and the sun
	cutMove=6,cutTurn=30,   -- more than this in one frame: a cut
	jumpMove=0.9,jumpTurn=8,-- a jump: more than this, 4x the recent motion and 2.5x the bodies' own motion
	cutGap=0.5,             -- two cuts closer than this
	clean=0.5,              -- shortest clean range listed (FILM09 shots: 0.7 to 1.2 s)
	inside=1.0,             -- two roots closer than this
	bodyLight=1.5,          -- a coloured light on a body this long is a fault
	fxLight=4,              -- a technique's light this long is a fault
	lines=24,               -- the band's side lines, this far outside it (points)
}
-- Server states in which a fighter is doing something (Matches:view `state`).
local ACT={Startup=true,Active=true,Recovery=true,Rush=true,Pursuit=true,Dodging=true,
	TechniqueChannel=true,TechniqueActive=true,TechniqueRecovery=true}
local FX_ROOTS={"NinjaDuelFX","Effects","NinjaUltimateFX","VfxMesh","WorldMemory"}
local DEV_GUIS={NinjaDuelDevPanel="F6",DevVisualPanel="F7",DevVisualHud="F7"}

local function fmt(t) return (string.format("%.2f",t):gsub("0$",""):gsub("%.",",")) end
local function r3(x) return math.floor(x*1000+0.5)/1000 end
local function flat(v) return V(v.X,0,v.Z) end
local function isHead(n) return n=="Head" or n:sub(1,6)=="Head__" end
local function hex(c) return string.format("#%02X%02X%02X",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)) end
local function esc(s) return (tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
local function hueName(c)
	local h,s=c:ToHSV()
	if s<0.25 then return "blanche" end
	h*=360
	if h<15 or h>=345 then return "rouge" elseif h<40 then return "orange" elseif h<70 then return "jaune"
	elseif h<165 then return "verte" elseif h<255 then return "bleue" elseif h<300 then return "violette" else return "rose" end
end
local function attr(name)
	local v=workspace:GetAttribute(name)
	if v~=nil then return v end
	local o=workspace:FindFirstChild(name)
	if o and o:IsA("ValueBase") then return o.Value end
	return nil
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
-- Head, torso, hands, eyes and every visible body part of a model (cached 0.5 s).
-- The rig's own parts give the geometry (the look meshes Head__*, *__Fist ride
-- on them and may be rotated); a rig part may be invisible, its place is right.
local partCache=setmetatable({},{__mode="k"})
local function partsOf(m)
	local e=partCache[m]
	local now=os.clock()
	if e and now-e.t<0.5 then return e end
	e={t=now,head=nil,torso=nil,hands={},eyes={},all={}}
	local looks,faceEyes,eyeStrip={},{},nil
	for _,d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then
			local n=d.Name
			if d.Transparency<0.9 and d.Size.Magnitude>0.3 then table.insert(e.all,d) end
			if n=="Head" then e.head=d
			elseif isHead(n) then looks[n]=d
			elseif n=="UpperTorso" or (n=="Torso" and not e.torso) then e.torso=d
			elseif n=="LeftHand" or n=="RightHand" or n=="Left Arm" or n=="Right Arm" then table.insert(e.hands,d)
			elseif n=="FaceEye" then table.insert(faceEyes,d)
			elseif n=="Eyes" then eyeStrip=d end
		end
	end
	e.head=e.head or looks.Head__Skin or select(2,next(looks))
	e.eyes=#faceEyes>0 and faceEyes or (eyeStrip and {eyeStrip} or {})
	partCache[m]=e
	return e
end
local function eyePoints(parts)
	local list={}
	for _,x in parts.eyes do if x.Parent then table.insert(list,x.Position) end end
	if #list==0 and parts.head then
		local h=parts.head
		for _,s in {-1,1} do table.insert(list,(h.CFrame*CFrame.new(s*0.2*h.Size.X,0,-0.55*h.Size.Z)).Position) end
	end
	return list
end
local function quality()
	local level,auto=nil,nil
	for _,prop in {"EditQualityLevel","QualityLevel"} do
		pcall(function()
			local q=settings().Rendering[prop]
			if q==Enum.QualityLevel.Automatic then auto=auto or true else level=level or tonumber(tostring(q):match("(%d+)$")) end
		end)
		if level then auto=false;break end
	end
	if level==nil and auto==nil then
		pcall(function()
			local q=UserSettings():GetService("UserGameSettings").SavedQualityLevel
			if q==Enum.SavedQualitySetting.Automatic then auto=true else level=tonumber(tostring(q):match("(%d+)$")) end
		end)
	end
	return level,auto
end
-- Is this error the game's own (not a filming script, a Studio command, a plugin, a dev tool)?
local function gameError(message)
	if string.find(message,"NDFactory",1,true) or string.find(message,"ClipAssist",1,true) then return false end
	if string.find(message,"NinjaDuelClient%.Dev") or string.find(message,"NinjaDuelServer%.Dev") then return false end
	return string.find(message,"NinjaDuelClient.",1,true)~=nil or string.find(message,"NinjaDuelServer.",1,true)~=nil
		or string.find(message,"ReplicatedStorage.NinjaDuel.",1,true)~=nil
end

function Assist.install(ctx,dev)
	if not RunService:IsStudio() then return nil end
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local self={shown=false,guides=true,allowHud=false,counterOn=true,linesDuringRec=false,actorsOverride=nil,
		declaredQuality=nil,ignore={},check={},T=T}
	local installedAt=os.clock()
	local frameNo=0
	local live={}        -- id -> condition {id,group,sev,owner,text,since,seen,open,minDur}
	local recent={}      -- instant events {t,sev,owner,text}
	local take=nil       -- the take being recorded
	local last=nil       -- the last take's summary (with spans, events, frames)
	local saved=nil      -- what "prepare" changed, for "restore"
	local band={x0=0,x1=0,w=0,h=0}

	local function rel(t) return take and (t-take.start) or 0 end
	local function ignored(id)
		for prefix in self.ignore do if string.sub(id,1,#prefix)==prefix then return true end end
		return false
	end
	local function closeSpan(c,at)
		if take and c.open then
			local t0,t1=r3(math.max(0,rel(c.since))),r3(math.max(0,rel(at or c.seen)))
			-- a fault that ended before the take began (seen once at its very start) is not part of it
			if t1>t0 then table.insert(take.spans,{id=c.id,sev=c.sev,owner=c.owner,text=c.text,t0=t0,t1=t1}) end
		end
	end
	local function hold(group,stamp,id,sev,owner,text,minDur)
		if ignored(id) then return end
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
	local function event(id,sev,owner,text,now)
		if ignored(id) then return end
		table.insert(recent,{t=now,sev=sev,owner=owner,text=text})
		while #recent>40 do table.remove(recent,1) end
		if take then table.insert(take.events,{id=id,t=r3(rel(now)),sev=sev,owner=owner,text=text}) end
	end

	-- Which two bodies, who they are, who is acting.
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
		if self.actorNames and self.actorNames[key=="A" and 1 or 2] then return tostring(self.actorNames[key=="A" and 1 or 2]) end
		local d=data and data[key=="A" and "human" or "bot"]
		if d and d.fighter then return tostring(d.fighter) end
		if m then return tostring(m:GetAttribute("Fighter") or m.Name) end
		return key
	end
	-- true = acting (must be seen), false = not, nil = unknown (a replay with no NDAct)
	local function actingOf(key,data)
		local act=attr("NDAct")
		if type(act)=="string" and act~="" then return string.find(act,key,1,true)~=nil end
		local d=data and data[key=="A" and "human" or "bot"]
		if not d then return nil end
		return ACT[d.state]==true and d.reaction==nil
	end

	-- Other bodies near the fighters (clones, live or replayed), refreshed twice a second.
	local extraAt,extraParts=0,{}
	local function otherBodies(A,B)
		local now=os.clock()
		if now-extraAt<0.5 then return extraParts end
		extraAt=now;extraParts={}
		local ra=rootOf(A)
		if not ra then return extraParts end
		local seen={}
		for _,n in {"NinjaDuels","NinjaDuelBodies","NDReplay","NinjaDuelFX"} do
			local root=workspace:FindFirstChild(n)
			for _,d in root and root:GetDescendants() or {} do
				if d:IsA("Humanoid") then
					local m=d.Parent
					if m and m~=A and m~=B and not seen[m] and not (A and A:IsDescendantOf(m)) and not (B and B:IsDescendantOf(m)) then
						seen[m]=true
						local r=rootOf(m)
						if r and (r.Position-ra.Position).Magnitude<40 then
							for _,p in partsOf(m).all do table.insert(extraParts,p) end
						end
					end
				end
			end
		end
		return extraParts
	end

	local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude
	-- The nearest thing between `from` and `to`: queryable world (raycast), the
	-- unqueryable decor (Sight), and the given body parts (live or replay ghosts).
	local function firstBlocker(from,to,ignore,bodies)
		local exclude={}
		for _,x in ignore do table.insert(exclude,x) end
		local dir=to-from
		local len=dir.Magnitude
		if len<1e-3 then return nil end
		local best,bestT,bestHit=nil,1,nil
		for _=1,6 do
			rayParams.FilterDescendantsInstances=exclude
			local hit=workspace:Raycast(from,dir,rayParams)
			if not hit then break end
			local p=hit.Instance
			if p.Transparency<0.6 and p.LocalTransparencyModifier<0.6 then
				best,bestT,bestHit=p,(hit.Position-from).Magnitude/len,hit
				break
			end
			table.insert(exclude,p)
		end
		if Sight then
			local p,t=Sight.decor(from,to,0.03)
			if p and t<bestT then best,bestT,bestHit=p,t,nil end
			if bodies and #bodies>0 then
				local q,u=Sight.parts(from,to,bodies,0.03)
				if q and u<bestT then best,bestT,bestHit=q,u,nil end
			end
		end
		return best,bestHit
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
		local m=p:FindFirstAncestorWhichIsA("Model")
		while m and m~=workspace do
			if m:FindFirstChildOfClass("Humanoid") then return "clone",m.Name end
			m=m.Parent and m.Parent:IsA("Model") and m.Parent or nil
		end
		if underFx(p) then return "effet",p.Name end
		local holder=p:FindFirstAncestorWhichIsA("Model")
		return "décor",(holder and holder~=workspace and holder.Name or p.Name)
	end

	--------------------------------------------------------------------
	-- Interface.
	--------------------------------------------------------------------
	local gui=Instance.new("ScreenGui");gui.Name="ClipAssistPanel";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true
	gui.DisplayOrder=1100;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Enabled=true;gui.Parent=playerGui
	-- ClipKit's NDHideUI hides every ScreenGui: this one stays (nothing of it is in the band).
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
	local lineL=frame(gui,{Name="BandLeft",BackgroundColor3=OK_COLOR,Size=UDim2.new(0,3,1,0)})
	local lineR=frame(gui,{Name="BandRight",BackgroundColor3=OK_COLOR,Size=UDim2.new(0,3,1,0)})
	local guides=frame(gui,{Name="Guides",BackgroundTransparency=1})
	for i=1,2 do
		frame(guides,{BackgroundColor3=rgb(255,255,255),BackgroundTransparency=0.7,Size=UDim2.new(0,1,1,0),Position=UDim2.new(i/3,0,0,0)})
		frame(guides,{BackgroundColor3=rgb(255,255,255),BackgroundTransparency=0.7,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,i/3,0)})
	end
	-- What TikTok and Shorts lay over the video: the caption at the bottom, the buttons on the right.
	frame(guides,{BackgroundColor3=rgb(255,90,90),BackgroundTransparency=0.88,Size=UDim2.new(1,0,0.2,0),Position=UDim2.new(0,0,0.8,0)})
	frame(guides,{BackgroundColor3=rgb(255,90,90),BackgroundTransparency=0.88,Size=UDim2.new(0.16,0,0.5,0),Position=UDim2.new(0.84,0,0.3,0)})

	-- The frame counter, in the right margin: digits for people, 24 bits for a script
	-- (white = 1, least significant bit first, between a white and a black guard cell).
	local BITS,CELL=24,8
	local counter=frame(gui,{Name="FrameCounter",BackgroundColor3=rgb(0,0,0),Size=UDim2.fromOffset((BITS+2)*CELL+8,CELL+30),Visible=false})
	local counterText=label(counter,{Text="",Font=Enum.Font.Code,TextSize=18,TextColor3=rgb(255,255,255),Size=UDim2.new(1,-8,0,20),Position=UDim2.fromOffset(4,2)})
	local cells={}
	for i=0,BITS+1 do
		cells[i]=frame(counter,{BackgroundColor3=rgb(0,0,0),Size=UDim2.fromOffset(CELL,CELL),Position=UDim2.fromOffset(4+i*CELL,24)})
	end
	cells[0].BackgroundColor3=rgb(255,255,255)

	local panel=frame(gui,{Name="Panel",BackgroundColor3=rgb(20,23,30),BackgroundTransparency=0.08,Position=UDim2.fromOffset(8,8),Visible=false})
	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,6);corner.Parent=panel
	local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10);pad.PaddingTop=UDim.new(0,8);pad.PaddingBottom=UDim.new(0,8);pad.Parent=panel
	local scroll=Instance.new("ScrollingFrame");scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.Size=UDim2.fromScale(1,1)
	scroll.ScrollBarThickness=4;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.Parent=panel
	local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,6);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
	local order=0
	local function row(h)
		order+=1
		return frame(scroll,{BackgroundTransparency=1,Size=UDim2.new(1,-6,0,h),LayoutOrder=order})
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
	local sceneText=block()
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
		.."• OBS filme aussi le compteur d'images (marge droite) ; CapCut recadre sur la bande.\n"
		.."• Personne ne touche le Mac pendant la prise."

	local chip=button(gui,"🎬 F4",function() self:show(true) end,{Name="Chip",Size=UDim2.fromOffset(64,26),Position=UDim2.fromOffset(8,8),Visible=true})

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
		workspace:SetAttribute("NDWarmup",os.clock())
		if saved then return end
		saved={guis={},effects={},mouse=UIS.MouseIconEnabled,core={}}
		for _,t in Enum.CoreGuiType:GetEnumItems() do
			if t~=Enum.CoreGuiType.All then
				local ok,on=pcall(function() return StarterGui:GetCoreGuiEnabled(t) end)
				if ok then saved.core[t]=on end
			end
		end
		pcall(function() if dev and dev.toggle then dev:toggle(false) end end)
		pcall(function() if dev and dev.visual and dev.visual.setMode then dev.visual:setMode(0) end end)
		for _,g in playerGui:GetChildren() do
			if g:IsA("ScreenGui") and g~=gui and g.Enabled and not DEV_GUIS[g.Name] and string.sub(g.Name,1,2)~="ND" then saved.guis[g]=true;g.Enabled=false end
		end
		for _,root in {Lighting,workspace.CurrentCamera} do
			for _,e in root:GetChildren() do
				if (e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect")) and e.Enabled then saved.effects[e]=true;e.Enabled=false end
			end
		end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end)
		UIS.MouseIconEnabled=false
	end
	-- The game turns its look and its HUD back on (a new round, WorldLook): while
	-- the image is prepared, keep them off (8 times a second) until « Rétablir ».
	local function enforce()
		if not saved then return end
		for _,g in playerGui:GetChildren() do
			if g:IsA("ScreenGui") and g~=gui and g.Enabled and not DEV_GUIS[g.Name] and string.sub(g.Name,1,2)~="ND" then saved.guis[g]=true;g.Enabled=false end
		end
		for _,root in {Lighting,workspace.CurrentCamera} do
			for _,e in root:GetChildren() do
				if (e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect")) and e.Enabled then saved.effects[e]=true;e.Enabled=false end
			end
		end
		if UIS.MouseIconEnabled then UIS.MouseIconEnabled=false end
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
	local function clean(bad,a,b)
		local out,at={},a
		for _,r in merge(bad) do
			if r[2]>a and r[1]<b then
				if r[1]-at>=T.clean then table.insert(out,{r3(at),r3(r[1])}) end
				at=math.max(at,r[2])
			end
		end
		if b-at>=T.clean then table.insert(out,{r3(at),r3(b)}) end
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
			if e.sev>=ERR then table.insert(bad,{e.t-0.05,e.t+0.05}) end
			if e.sev>=WARN then table.insert(soft,{e.t-0.05,e.t+0.05}) end
		end
		local byText={}
		local function note(sev,owner,text,t0,t1)
			local key=text:gsub("%d+[,.]?%d*","#")
			local e=byText[key]
			if not e then e={sev=sev,owner=owner,text=text,total=0,at={}};byText[key]=e end
			e.sev=math.max(e.sev,sev);e.total=r3(e.total+math.max(0,t1-t0))
			table.insert(e.at,{r3(t0),r3(t1)})
		end
		for _,s in tk.spans do note(s.sev,s.owner,s.text,s.t0,s.t1) end
		for _,e in tk.events do note(e.sev,e.owner,e.text,e.t,e.t) end
		local faults={}
		for _,e in byText do table.insert(faults,e) end
		table.sort(faults,function(a,b) if a.sev~=b.sev then return a.sev>b.sev end;return a.total>b.total end)
		local counts={err=0,warn=0,info=0}
		for _,f in faults do if f.sev>=ERR then counts.err+=1 elseif f.sev>=WARN then counts.warn+=1 else counts.info+=1 end end
		-- Scene by scene (NDScene / NDBeat), from the frame log.
		local scenes,cur={},nil
		for _,f in tk.frames do
			if f.black or not f.scene then cur=nil;continue end
			local key=(f.scene or "")..(f.shot and ("|"..f.shot) or "")
			if not cur or cur.key~=key then
				if cur then cur.t1=f.w end
				cur={key=key,scene=f.scene,shot=f.shot,t0=f.w,t1=f.w,st0=f.st}
				table.insert(scenes,cur)
			end
			cur.t1=f.w;cur.st1=f.st
		end
		for _,s in scenes do
			s.key=nil
			s.clean=clean(bad,s.t0,s.t1)
			local cleanTime=0
			for _,r in s.clean do cleanTime+=r[2]-r[1] end
			s.cleanShare=r3(s.t1>s.t0 and cleanTime/(s.t1-s.t0) or 0)
			local errs=0
			for _,r in merge(bad) do if r[2]>s.t0 and r[1]<s.t1 then errs+=1 end end
			s.errors=errs
		end
		return {label=tk.label,duration=r3(dur),build=tk.build,clean=clean(bad,0,dur),cleanStrict=clean(soft,0,dur),counts=counts,
			faults=faults,scenes=scenes,cuts=tk.cuts,hitches=tk.hitches,spans=tk.spans,events=tk.events,frames=tk.frames,
			counter={first=tk.firstFrame,last=frameNo,bits=BITS}}
	end
	local function startTake(name)
		if take then return end
		take={label=name or ("prise "..os.date("%H:%M:%S")),start=os.clock(),spans={},events={},cuts={},hitches=0,frames={},firstFrame=frameNo+1,build=buildLine()}
		print("[NinjaDuelClip] REC "..take.label.." | frame "..(frameNo+1).." | "..take.build)
	end
	local function public(s)
		if not s then return nil end
		return {label=s.label,duration=s.duration,build=s.build,clean=s.clean,cleanStrict=s.cleanStrict,counts=s.counts,faults=s.faults,
			scenes=s.scenes,cuts=s.cuts,hitches=s.hitches,spans=s.spans,events=s.events,counter=s.counter,frames=#s.frames}
	end
	local function stopTake()
		if not take then return last end
		local now=os.clock()
		for _,c in live do closeSpan(c,now) end
		last=summarize(take,now)
		take=nil
		print("[NinjaDuelClip] "..HttpService:JSONEncode(public(last)))
		return last
	end

	--------------------------------------------------------------------
	-- Checks.
	--------------------------------------------------------------------
	local fpsWin={}
	local lastCam=nil
	local motion={move=0.3,turn=1.5}
	local lastCut=-math.huge
	local lastRoots={}
	local flashSince=setmetatable({},{__mode="k"})
	local lightSince=setmetatable({},{__mode="k"})
	local lights={}
	local highlights={}

	local function project(cam,p)
		local v=cam:WorldToViewportPoint(p)
		return v,(v.Z>0 and v.X>=band.x0 and v.X<=band.x1 and v.Y>=0 and v.Y<=band.h)
	end
	local function uv(cam,p)
		local v=cam:WorldToViewportPoint(p)
		if v.Z<=0 then return nil end
		return {r3((v.X-band.x0)/math.max(1,band.w)),r3(v.Y/math.max(1,band.h))}
	end

	local function tickChecks(now)
		local G="tick"
		local cam=workspace.CurrentCamera
		local camPos,look=cam.CFrame.Position,cam.CFrame.LookVector
		local data=duelData()
		local A,B=actors()
		local info={}
		for _,key in {"A","B"} do
			local m=key=="A" and A or B
			if m and m.Parent then
				local parts=partsOf(m)
				local cf=pivotOf(m)
				if parts.head and cf then
					info[key]={m=m,name=nameOf(key,m,data),acting=actingOf(key,data),parts=parts,root=rootOf(m),cf=cf}
				end
			end
		end
		local extra=otherBodies(A,B)
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
			local top=x.parts.head.Position+V(0,x.parts.head.Size.Y*0.9,0) -- the hair above the rig's head
			local feet=(x.root and x.root.Position or x.cf.Position)-V(0,3,0)
			local topV=cam:WorldToViewportPoint(top)
			local feetV=cam:WorldToViewportPoint(feet)
			if headV.Z>0 then shares[key]=math.abs(feetV.Y-topV.Y)/math.max(1,band.h) end
			-- Out of the band.
			if not headIn and not torsoIn then
				if x.acting==true then hold(G,now,id.."out",ERR,"cadrage",name.." agit hors du cadre")
				elseif other and other.acting==true and attr("NDAct")==nil then hold(G,now,id.."out",WARN,"cadrage","l'action à deux n'est cadrée qu'à moitié : "..name.." hors du cadre",0.3) end
			elseif headIn and topV.Z>0 and topV.Y<0 then
				hold(G,now,id.."top",WARN,"cadrage","tête de "..name.." coupée en haut",0.3)
			end
			-- The other body right in front of the lens (an over-the-shoulder too close).
			if x.acting~=true and (headIn or torsoIn) then
				local dist=((x.root and x.root.Position or x.cf.Position)-camPos).Magnitude
				if dist<4.5 then hold(G,now,id.."front",WARN,"cadrage",name.." au premier plan, à "..fmt(dist).." studs de l'objectif (il bouche une partie de l'image)",0.3) end
			end
			if headIn or torsoIn then
				-- Seen from behind while acting.
				local fwd=flat(x.cf.LookVector)
				local toCam=flat(camPos-x.cf.Position)
				if fwd.Magnitude>0.1 and toCam.Magnitude>0.1 then
					local ang=math.deg(math.acos(math.clamp(fwd.Unit:Dot(toCam.Unit),-1,1)))
					if ang>T.back then
						if x.acting==true then hold(G,now,id.."back",ERR,"cadrage",name.." filmé de dos pendant son action ("..math.floor(ang).."°)")
						elseif x.acting==nil then hold(G,now,id.."back",WARN,"cadrage",name.." de dos ("..math.floor(ang).."°)",0.5) end
					end
				end
				-- Something between the lens and the body.
				local bodies={}
				if other then for _,p in other.parts.all do table.insert(bodies,p) end end
				for _,p in extra do table.insert(bodies,p) end
				local ignore={x.m}
				local hb=firstBlocker(camPos,x.parts.head.Position,ignore,bodies)
				local tb=nil
				if x.parts.torso then tb=firstBlocker(camPos,x.parts.torso.Position,ignore,bodies) end
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
					for _,h in x.parts.hands do if firstBlocker(camPos,h.Position,ignore,bodies) then hidden+=1 end end
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
			if (info.A.root.Position-info.B.root.Position).Magnitude<T.inside then hold(G,now,"inside",WARN,"jeu","corps l'un dans l'autre ("..info.A.name.." / "..info.B.name..")",0.4) end
		end
		-- Something stuck on the lens.
		local cf=cam.CFrame
		local all={}
		for _,x in info do for _,p in x.parts.all do table.insert(all,p) end end
		for _,p in extra do table.insert(all,p) end
		for _,d in {cf.LookVector,(cf*CFrame.Angles(0,math.rad(12),0)).LookVector,(cf*CFrame.Angles(0,math.rad(-12),0)).LookVector,(cf*CFrame.Angles(math.rad(8),0,0)).LookVector,(cf*CFrame.Angles(math.rad(-8),0,0)).LookVector} do
			local p,hit=firstBlocker(camPos,camPos+d*T.lens,{},all)
			if p and not (hit and hit.Normal.Y>=0.8) then
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
						if kind=="effet" then hold(G,now,"insidecam",WARN,"cadrage","caméra dans un effet ("..what..")",0.2)
						else hold(G,now,"insidecam",ERR,"cadrage","caméra dans "..(kind=="décor" and ("le décor ("..what..")") or what),0.1) end
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
				for _,x in info do if target==x.m or (target and target:IsDescendantOf(x.m)) then who=x.name end end
				if who then
					flashSince[h]=flashSince[h] or now
					if now-flashSince[h]>0.3 then hold(G,now,"flash:"..who,WARN,"jeu","flash plein corps sur "..who.." (surexpose)",0) end
				end
			else
				flashSince[h]=nil
			end
		end
		-- A coloured light that stays on a fighter (the pink Kakashi of FILM04):
		-- a body light over T.bodyLight s, a technique's light over T.fxLight s.
		for _,l in lights do
			local hot=false
			if l.Parent and l.Enabled and l.Brightness>1 then
				local _,s=l.Color:ToHSV()
				local at=(l.Parent:IsA("BasePart") and l.Parent.Position) or (l.Parent:IsA("Attachment") and l.Parent.WorldPosition) or nil
				if at and s>0.45 then
					local range=(l:IsA("PointLight") or l:IsA("SpotLight")) and l.Range or 8
					for _,x in info do
						if (x.parts.head.Position-at).Magnitude<range*0.8 then
							hot=true
							lightSince[l]=lightSince[l] or now
							local onBody=l:IsDescendantOf(x.m)
							local limit=onBody and T.bodyLight or T.fxLight
							if now-lightSince[l]>limit then
								hold(G,now,"light:"..x.name,WARN,"jeu","lumière "..hueName(l.Color).." qui reste sur "..x.name.." (teinte la peau et le sol)"..(onBody and "" or " — lumière d'effet"),0)
							end
						end
					end
				end
			end
			if not hot then lightSince[l]=nil end
		end
		self.info=info
		sweep(G,now)
	end

	local function guiCovers(g)
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
		local sum=0
		for _,f in fpsWin do sum+=f[2] end
		local fps=#fpsWin>10 and sum>0 and #fpsWin/sum or nil
		self.fps=fps
		if fps then check.fps=fps>=T.fpsWarn end
		if fps and now-installedAt>5 then
			if fps<T.fpsErr then hold(G,now,"fps",take and ERR or WARN,"machine",string.format("Studio à %d i/s : fenêtre au premier plan ? autre place en Play ? Mac occupé ?",math.floor(fps)),0)
			elseif fps<T.fpsWarn then hold(G,now,"fps",WARN,"machine",string.format("Studio à %d i/s (assez pour 30 i/s, mais sans marge)",math.floor(fps)),0) end
		end
		-- Graphics quality: declared by the CM if the reading is wrong in Studio.
		local level,auto=quality()
		if self.declaredQuality then level,auto=self.declaredQuality,false end
		self.quality=auto and "Automatique" or level
		if auto then check.quality=false elseif level then check.quality=true end
		if auto then hold(G,now,"quality",WARN,"reglage","qualité graphique lue « Automatique » : mettre un niveau fixe (si la lecture est fausse, Report:Invoke(\"quality\",N))",0) end
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
		-- What is drawn over the band: the game's HUD, the dev panels (filming overlays ND* excepted).
		local hud,panels=false,{}
		for _,g in playerGui:GetChildren() do
			if g:IsA("ScreenGui") and g~=gui and g.Enabled and (DEV_GUIS[g.Name] or string.sub(g.Name,1,2)~="ND") then
				if guiCovers(g) then
					if DEV_GUIS[g.Name] then panels[DEV_GUIS[g.Name]]=true else hud=true end
				end
			end
		end
		check.hud=not hud or self.allowHud
		check.panels=next(panels)==nil
		if hud and not self.allowHud then hold(G,now,"hud",WARN,"reglage","HUD du jeu dans l'image (« Préparer l'image » le cache)",0) end
		for k in panels do hold(G,now,"panel"..k,ERR,"reglage","panneau "..k.." ouvert dans l'image",0) end
		local mouse=UIS:GetMouseLocation()
		local cursor=UIS.MouseIconEnabled and mouse.X>band.x0 and mouse.X<band.x1
		check.cursor=not cursor
		if cursor then hold(G,now,"cursor",WARN,"reglage","curseur de la souris dans l'image",0.5) end
		-- Lights and highlights near the fighters, checked 15 times a second by tickChecks.
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
		self.check=check
		sweep(G,now)
	end

	--------------------------------------------------------------------
	-- The game's own errors while filming (not the CM's scripts, Studio commands or plugins).
	--------------------------------------------------------------------
	LogService.MessageOut:Connect(function(message,kind)
		if kind==Enum.MessageType.MessageError and gameError(message) then
			event("error",ERR,"jeu","erreur de script (client) : "..string.sub(message,1,140),os.clock())
		end
	end)
	task.spawn(function()
		local log=ReplicatedStorage:WaitForChild("NinjaDuelDevLog",15)
		if not log then return end
		log.OnClientEvent:Connect(function(kind,payload)
			if kind=="serverlog" and type(payload)=="table" and payload.k=="error" and gameError(tostring(payload.m)) then
				event("error",ERR,"jeu","erreur de script (serveur) : "..string.sub(tostring(payload.m),1,140),os.clock())
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
		for id,c in live do if c.open then table.insert(list,{id=id,sev=c.sev,owner=c.owner,text=c.text,dur=now-c.since}) end end
		for _,e in recent do if now-e.t<4 then table.insert(list,{sev=e.sev,owner=e.owner,text=e.text,ago=now-e.t}) end end
		table.sort(list,function(a,b) if a.sev~=b.sev then return a.sev>b.sev end;return (a.dur or 0)>(b.dur or 0) end)
		return list
	end
	local function layoutBand()
		local vp=workspace.CurrentCamera.ViewportSize
		local w=math.min(vp.X,vp.Y*CROPW)
		band.x0=(vp.X-w)/2;band.x1=band.x0+w;band.w=w;band.h=vp.Y
		lineL.Position=UDim2.fromOffset(band.x0-T.lines-3,0)
		lineR.Position=UDim2.fromOffset(band.x1+T.lines,0)
		guides.Position=UDim2.fromOffset(band.x0,0);guides.Size=UDim2.new(0,w,1,0)
		counter.Position=UDim2.fromOffset(band.x1+T.lines+12,8)
		local margin=band.x0-T.lines-16
		panel.Size=UDim2.new(0,math.clamp(margin,240,380),1,-16)
		self.narrow=margin<240
		self.counterGeometry={x=band.x1+T.lines+12+4,y=8+24,cell=CELL,bits=BITS,
			layout="points from the top-left of the viewport (x2 on Retina): cell 0 white guard, cells 1..24 the frame number (white=1, least significant first), cell 25 black guard"}
	end
	local function drawCounter()
		counterText.Text=string.format("%07d",frameNo%10000000)
		local n=frameNo
		for i=1,BITS do
			cells[i].BackgroundColor3=(n%2==1) and rgb(255,255,255) or rgb(0,0,0)
			n=n//2
		end
		cells[BITS+1].BackgroundColor3=rgb(0,0,0)
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
		local w=worst()
		local color=w>=ERR and SEVCOLOR[ERR] or w>=WARN and SEVCOLOR[WARN] or OK_COLOR
		lineL.BackgroundColor3=color;lineR.BackgroundColor3=color
		lineL.Visible=take==nil or self.linesDuringRec;lineR.Visible=lineL.Visible
		guides.Visible=self.guides and take==nil
		panel.Visible=self.shown and not (take and self.narrow)
		chip.Visible=not self.shown
		if not self.shown then return end
		warnNarrow.Text=self.narrow and '<font color="#F0AA3C">Fenêtre étroite : le panneau couvre la bande 9:16 ; il se cache pendant une prise.</font>' or ""
		warnNarrow.Visible=self.narrow==true
		local scene,shot,act=attr("NDScene") or attr("NDBeat"),attr("NDShot") or attr("NDTake"),attr("NDAct")
		sceneText.Text=string.format('<font color="#8A94A3">scène</font> %s  <font color="#8A94A3">caméra</font> %s  <font color="#8A94A3">qui agit</font> %s',
			esc(scene or "—"),esc(shot or "—"),esc(act or "état du duel"))
		timer.Text=take and string.format('<font color="#EB5050">● %s</font>',fmt(now-take.start)) or ""
		recButton.Text=take and "■ STOP" or "● REC"
		recButton.BackgroundColor3=take and rgb(150,40,40) or rgb(52,58,70)
		local ck=self.check or {}
		local function item(ok,text,detail)
			local mark=ok==nil and '<font color="#8A94A3">?</font>' or ok and '<font color="#5AC878">✓</font>' or '<font color="#EB5050">×</font>'
			return mark.." "..text..(detail and (' <font color="#8A94A3">'..detail.."</font>") or "")
		end
		checkText.Text=table.concat({
			item(ck.duel,"Combat trouvé",self.actorsOverride and "(corps choisis à la main)" or nil),
			item(ck.quality,"Qualité graphique fixe",self.quality and ("("..tostring(self.quality)..(self.declaredQuality and ", déclarée" or "")..")") or nil),
			item(ck.fps,"Image fluide (≥ "..T.fpsWarn.." i/s)",self.fps and ("("..math.floor(self.fps).." i/s)") or nil),
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
			table.insert(lines,tag.." "..esc(e.text)..'<font color="#8A94A3"> · '..OWNER[e.owner]..when..(e.id and (" · "..e.id) or "").."</font>")
		end
		liveText.Text=#lines>0 and table.concat(lines,"\n") or '<font color="#5AC878">Rien à signaler.</font>'
		if last then
			local f={}
			table.insert(f,string.format("<b>%s</b> · %s s · %d erreur(s), %d à voir",esc(last.label),fmt(last.duration),last.counts.err,last.counts.warn))
			table.insert(f,'<font color="#5AC878">Plages propres :</font> '..ranges(last.clean))
			table.insert(f,'<font color="#8A94A3">Sans rien « à voir » : '..ranges(last.cleanStrict).."</font>")
			for i,s in last.scenes do
				if i>8 then break end
				if s.scene or s.shot then
					table.insert(f,string.format('<font color="#8A94A3">scène</font> %s %s · %d %% propre',esc(s.scene or "—"),esc(s.shot or ""),math.floor(s.cleanShare*100)))
				end
			end
			for i,x in last.faults do
				if i>8 then break end
				local at={}
				for j,r in x.at do if j<=5 then table.insert(at,fmt(r[1])) end end
				table.insert(f,string.format('<font color="%s">%s</font> %s <font color="#8A94A3">· %s · à %s s</font>',hex(SEVCOLOR[x.sev]),SEVNAME[x.sev],esc(x.text),OWNER[x.owner],table.concat(at,", ")))
			end
			if #last.cuts>0 then
				local cuts={}
				for i,t in last.cuts do if i<=12 then table.insert(cuts,fmt(t)) end end
				table.insert(f,'<font color="#8A94A3">Coupes caméra à '..table.concat(cuts,", ").." s</font>")
			end
			lastText.Text=table.concat(f,"\n")
		else
			lastText.Text='<font color="#8A94A3">Pas encore de prise. « ● REC » au moment où OBS démarre (ou workspace.NDRec), « ■ STOP » à l\'arrêt.</font>'
		end
		drawPlan()
	end

	--------------------------------------------------------------------
	-- The per-frame loop: counter, camera, frozen frames, frame log.
	--------------------------------------------------------------------
	recButton=button(head,"● REC",function() if take then stopTake() else startTake() end end,{Size=UDim2.fromOffset(84,26),Position=UDim2.new(1,-90,0,1)})
	button(buttons,"Préparer l'image",prepare,{Size=UDim2.fromOffset(122,26)})
	button(buttons,"Rétablir",restore,{Size=UDim2.fromOffset(70,26)})
	button(buttons,"Repères",function() self.guides=not self.guides end,{Size=UDim2.fromOffset(70,26)})
	button(buttons,"×",function() self:show(false) end,{Size=UDim2.fromOffset(28,26)})
	function self:show(on) self.shown=on==true end
	UIS.InputBegan:Connect(function(key,processed)
		if not processed and key.KeyCode==Enum.KeyCode.F4 then self:show(not self.shown) end
	end)
	-- workspace.NDRec: a scene script starts and stops takes without a click.
	workspace:GetAttributeChangedSignal("NDRec"):Connect(function()
		local v=workspace:GetAttribute("NDRec")
		if v and v~="" then startTake(type(v)=="string" and v or nil) else stopTake() end
	end)

	local function logFrame(now,cam)
		local f={f=frameNo,w=r3(now-take.start),dt=r3(fpsWin[#fpsWin] and fpsWin[#fpsWin][2] or 0)}
		if attr("NDCut")==true then f.black=true end
		local st=attr("NDClock")
		if type(st)=="number" then f.st=r3(st) end
		f.scene=attr("NDScene") or attr("NDBeat");f.shot=attr("NDShot") or attr("NDTake");f.act=attr("NDAct")
		local cf=cam.CFrame
		f.cam={r3(cf.Position.X),r3(cf.Position.Y),r3(cf.Position.Z),r3(cf.LookVector.X),r3(cf.LookVector.Y),r3(cf.LookVector.Z),r3(cam.FieldOfView)}
		local open={}
		for id,c in live do if c.open and c.sev>=WARN then table.insert(open,id) end end
		if #open>0 then f.def=open end
		for key,x in self.info or {} do
			if x.m.Parent and x.parts.head then
				local e={face=uv(cam,(x.parts.head.CFrame*CFrame.new(0,0,-0.5*x.parts.head.Size.Z)).Position),head=uv(cam,x.parts.head.Position)}
				local eyes={}
				for _,p in eyePoints(x.parts) do table.insert(eyes,uv(cam,p) or false) end
				e.eyes=eyes
				local hands={}
				for _,h in x.parts.hands do if h.Parent then table.insert(hands,uv(cam,h.Position) or false) end end
				e.hands=hands
				f[key]=e
			end
		end
		table.insert(take.frames,f)
	end

	local tickAcc,slowAt,drawAt=0,0,0
	RunService:BindToRenderStep("NinjaDuelClipAssist",Enum.RenderPriority.Last.Value+400,function(dt)
		local now=os.clock()
		frameNo+=1
		table.insert(fpsWin,{now,dt})
		while fpsWin[1] and now-fpsWin[1][1]>2 do table.remove(fpsWin,1) end
		counter.Visible=self.counterOn and (take~=nil or self.shown)
		if counter.Visible then drawCounter() end
		-- A frozen image: a frame much longer than the ones around it.
		if now-installedAt>3 and dt>T.hitch then
			local sum=0
			for _,f in fpsWin do sum+=f[2] end
			local mean=#fpsWin>0 and sum/#fpsWin or dt
			if dt>3*mean or dt>0.1 then
				event("hitch",take and ERR or WARN,"machine",string.format("image figée (%d ms)",math.floor(dt*1000)),now)
				if take then take.hitches+=1 end
			end
		end
		-- The camera: a cut, or a jump inside a shot that the bodies' own motion does not explain.
		local cam=workspace.CurrentCamera
		local cf=cam.CFrame
		local pos,look,fov=cf.Position,cf.LookVector,cam.FieldOfView
		local bodyMove=0
		for key,x in self.info or {} do
			local p=x.root and x.root.Position or (x.m.Parent and x.cf.Position)
			if p and lastRoots[key] then bodyMove=math.max(bodyMove,(p-lastRoots[key]).Magnitude) end
			lastRoots[key]=p
		end
		if lastCam then
			local move=(pos-lastCam.pos).Magnitude
			local turn=math.deg(math.acos(math.clamp(look:Dot(lastCam.look),-1,1)))
			if attr("NDCut")==true then
				-- inside a black gap: no cut, no jump
			-- A cut: more than the bodies themselves could explain in this frame (a slow
			-- frame at 15 i/s carries four frames of motion).
			elseif move>math.max(T.cutMove*math.max(1,dt*60),3*bodyMove+2) or turn>T.cutTurn*math.max(1,dt*30) or math.abs(fov-lastCam.fov)>6 then
				if take then table.insert(take.cuts,r3(now-take.start)) end
				if now-lastCut<T.cutGap then event("cuts",WARN,"cadrage","deux coupes en "..fmt(now-lastCut).." s",now) end
				lastCut=now
			elseif (move>T.jumpMove and move>4*motion.move and move>2.5*bodyMove+0.3) or (turn>T.jumpTurn and turn>4*motion.turn and bodyMove<0.5) then
				event("jump",WARN,"cadrage",string.format("saut de caméra (%s studs, %d°)",fmt(move),math.floor(turn)),now)
			else
				motion.move=motion.move*0.9+move*0.1;motion.turn=motion.turn*0.9+turn*0.1
			end
		end
		lastCam={pos=pos,look=look,fov=fov}
		tickAcc+=dt
		local black=attr("NDCut")==true
		if black then
			-- A black gap between two beats of a program: nothing to judge.
			for id,c in live do if c.group=="tick" then closeSpan(c);live[id]=nil end end
			tickAcc=0
		elseif tickAcc>=T.tick then
			tickAcc=0
			local ok,err=pcall(tickChecks,now)
			if not ok then warn("[NinjaDuelClip] tick: "..tostring(err)) end
		end
		if take then
			local ok,err=pcall(logFrame,now,cam)
			if not ok then warn("[NinjaDuelClip] frame: "..tostring(err)) end
		end
		if now-slowAt>=1 then
			slowAt=now
			local ok,err=pcall(slowChecks,now)
			if not ok then warn("[NinjaDuelClip] slow: "..tostring(err)) end
		end
		if now-drawAt>=1/8 then
			drawAt=now
			local ok,err=pcall(function() enforce();layoutBand();render(now) end)
			if not ok then warn("[NinjaDuelClip] draw: "..tostring(err)) end
		end
	end)

	--------------------------------------------------------------------
	-- For agents and scene scripts.
	--------------------------------------------------------------------
	local function snapshot()
		local now=os.clock()
		local list={}
		for _,e in liveLines(now) do table.insert(list,{id=e.id,severity=SEVNAME[e.sev],owner=OWNER[e.owner],text=e.text,seconds=e.dur,ago=e.ago}) end
		return {shown=self.shown,recording=take~=nil,takeSeconds=take and (now-take.start) or nil,label=take and take.label or nil,frame=frameNo,
			check=self.check,quality=self.quality,fps=self.fps,narrow=self.narrow,band={x0=band.x0,x1=band.x1,height=band.h},
			counter=self.counterGeometry,thresholds=T,ignore=self.ignore,now=list,last=public(last),build=buildLine()}
	end
	local bindable=Instance.new("BindableFunction");bindable.Name="Report";bindable.Parent=gui
	bindable.OnInvoke=function(op,arg,extra)
		if op=="rec" then
			if arg=="start" then startTake(extra) elseif arg=="stop" then stopTake() end
		elseif op=="frames" then
			local src=take or last
			local list=src and src.frames or {}
			local from=type(arg)=="table" and tonumber(arg.from) or 1
			local count=type(arg)=="table" and tonumber(arg.count) or 600
			local out={}
			for i=from,math.min(#list,from+count-1) do table.insert(out,list[i]) end
			return HttpService:JSONEncode({total=#list,from=from,frames=out,counter=self.counterGeometry})
		elseif op=="prepare" then prepare()
		elseif op=="restore" then restore()
		elseif op=="actors" then
			self.actorsOverride=(type(arg)=="table" and arg[1] and arg[2]) and {arg[1],arg[2]} or nil
			self.actorNames=type(extra)=="table" and extra or nil
		elseif op=="quality" then self.declaredQuality=tonumber(arg)
		elseif op=="set" and type(arg)=="table" then for k,v in arg do if T[k]~=nil and type(v)=="number" then T[k]=v end end
		elseif op=="ignore" then
			if type(arg)=="table" then for _,id in arg do self.ignore[tostring(id)]=true end else table.clear(self.ignore) end
		elseif op=="show" then self:show(arg~=false)
		elseif op=="guides" then self.guides=arg~=false
		elseif op=="allowHud" then self.allowHud=arg==true
		elseif op=="counter" then self.counterOn=arg~=false
		elseif op=="linesDuringRec" then self.linesDuringRec=arg==true
		end
		return HttpService:JSONEncode(snapshot())
	end
	self.prepare=prepare;self.restore=restore;self.startTake=startTake;self.stopTake=stopTake;self.snapshot=snapshot
	_G.NDClipAssist=self
	print("[NinjaDuelClip] assistant de tournage prêt (F4) | "..buildLine())
	return self
end

return Assist
