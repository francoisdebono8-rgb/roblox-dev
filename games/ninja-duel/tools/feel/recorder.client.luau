-- Mission FEEL (issue #44): client-side recorder for the Studio takes,
-- installed in Play through Studio's execute_luau (Client), or required as a
-- ModuleScript placed by the tool (it returns `install`). Nothing here ships
-- in a build.
-- _G.FEEL = {inputs, snaps, cam, marks}: server-clock times relative to t0,
-- so the timeline lines up with the server flight log and with OBS footage
-- (t0 is a Unix time: video time = t0 + t - recording start).
--   inputs  every key/button begin and end (mouse movement excluded)
--   snaps   one entry per snapshot packet (~30 Hz): states, cues, the quiet
--           refusal line, heights and positions
--   cam     one entry per rendered frame: dt, FOV, lens distance, and whether
--           each fighter is on screen (0 off, 1 near the edge, 2 well inside)
--   marks   scene labels pushed by the tool driving the take
-- F.report() sums up everything since the last mark.
-- Buffers stop growing at their cap (no O(n) removal on every frame).
local function install()
	local RS=game:GetService("ReplicatedStorage")
	local UIS=game:GetService("UserInputService")
	local Run=game:GetService("RunService")
	if _G.FEEL and _G.FEEL.conns then for _,c in _G.FEEL.conns do c:Disconnect() end end
	local F={inputs={},snaps={},cam={},marks={},conns={},t0=workspace:GetServerTimeNow()}
	_G.FEEL=F
	local function now() return workspace:GetServerTimeNow()-F.t0 end
	local function push(l,x,max) if #l<max then table.insert(l,x) end end
	function F.mark(label) table.insert(F.marks,{t=now(),label=label}) end
	local remote=RS:WaitForChild("NinjaDuel"):WaitForChild("Action")
	table.insert(F.conns,remote.OnClientEvent:Connect(function(d)
		if type(d)~="table" then return end
		F.epoch=d.epoch or F.epoch
		if not d.human then return end
		local h,b=d.human,d.bot
		push(F.snaps,{t=now(),phase=d.phase,hs=h.state,ha=h.attackName,hv=h.attackVariant,hr=h.reaction,cue=h.cue,quiet=h.quiet,
			bs=b and b.state,ba=b and b.attackName,br=b and b.reaction,hp=h.health,bhp=b and b.health,
			hy=h.position and h.position.Y,by=b and b.position and b.position.Y,
			hx=h.position and h.position.X,hz=h.position and h.position.Z,bx=b and b.position and b.position.X,bz=b and b.position and b.position.Z,
			air=h.airborne,wall=h.wall,combo=h.combo},20000)
	end))
	local function name(i)
		if i.KeyCode~=Enum.KeyCode.Unknown then return i.KeyCode.Name end
		return i.UserInputType.Name
	end
	table.insert(F.conns,UIS.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseMovement then return end
		push(F.inputs,{t=now(),k="+"..name(i)},5000)
	end))
	table.insert(F.conns,UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseMovement then return end
		push(F.inputs,{t=now(),k="-"..name(i)},5000)
	end))
	local function fighters()
		local duels=workspace:FindFirstChild("NinjaDuels")
		local duel=duels and duels:FindFirstChildWhichIsA("Folder")
		if not duel then return nil,nil end
		local me,foe=duel:FindFirstChild("PlayerFighter"),duel:FindFirstChild("AIFighter")
		return me and me:FindFirstChild("HumanoidRootPart"),foe and foe:FindFirstChild("HumanoidRootPart")
	end
	table.insert(F.conns,Run.RenderStepped:Connect(function(dt)
		local cam=workspace.CurrentCamera
		local me,foe=fighters()
		local vp=cam.ViewportSize
		local function onScreen(part)
			if not part then return -1 end
			local p,vis=cam:WorldToViewportPoint(part.Position)
			if not vis then return 0 end
			if p.X<0 or p.Y<0 or p.X>vp.X or p.Y>vp.Y then return 0 end
			if p.X<vp.X*.05 or p.Y<vp.Y*.05 or p.X>vp.X*.95 or p.Y>vp.Y*.95 then return 1 end
			return 2
		end
		push(F.cam,{t=now(),dt=dt,me=onScreen(me),foe=onScreen(foe),fov=cam.FieldOfView,
			dist=me and (cam.CFrame.Position-me.Position).Magnitude or nil},60000)
	end))
	function F.report(states)
		local m=F.marks[#F.marks].t
		local out={F.marks[#F.marks].label}
		local maxBy,launched=0,false
		local prev=""
		local quiet={}
		for _,s in F.snaps do if s.t>=m then
			maxBy=math.max(maxBy,s.by or 0) if s.br=="Launched" then launched=true end
			if s.quiet and quiet[#quiet]~=s.quiet then table.insert(quiet,s.quiet) end
			if states then
				local k=string.format("h=%s/%s q=%s cue=%s air=%s wall=%s | b=%s r=%s",tostring(s.hs),tostring(s.ha),tostring(s.quiet),tostring(s.cue),tostring(s.air),tostring(s.wall),tostring(s.bs),tostring(s.br))
				if k~=prev then table.insert(out,string.format("%.2f %s pos=(%.0f,%.1f,%.0f) by=%.1f",s.t-m,k,s.hx or 0,s.hy or 0,s.hz or 0,s.by or -1)) prev=k end
			end
		end end
		local foeOff,meOff,meEdge,foeEdge,n,big=0,0,0,0,0,{}
		local runs={} local cur
		for _,c in F.cam do if c.t>=m then n+=1
			if c.foe==0 then foeOff+=1 if not cur then cur={c.t-m,c.t-m} else cur[2]=c.t-m end else if cur then table.insert(runs,string.format("%.2f-%.2f",cur[1],cur[2])) cur=nil end end
			if c.foe==1 then foeEdge+=1 end if c.me==0 then meOff+=1 end if c.me==1 then meEdge+=1 end
			if c.dt>.05 then table.insert(big,string.format("%.2f:%d",c.t-m,math.floor(c.dt*1000))) end end end
		if cur then table.insert(runs,string.format("%.2f-%.2f",cur[1],cur[2])) end
		table.insert(out,string.format("launched=%s maxBotY=%.1f frames=%d foeOff=%d foeEdge=%d meOff=%d meEdge=%d foeOffRuns=%s hitches=%s quiet=%s",
			tostring(launched),maxBy,n,foeOff,foeEdge,meOff,meEdge,table.concat(runs," "),table.concat(big," "),table.concat(quiet," | ")))
		return table.concat(out,"\n")
	end
	return F
end
return install
