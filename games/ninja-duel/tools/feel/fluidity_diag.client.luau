-- Fluidity diagnostics (Studio, Client datamodel, installed through
-- execute_luau after tools/feel/fluidity_probe.client.luau: it reads the
-- snapshot that probe keeps in _G.FLUID.cur). Nothing here ships in a build.
-- Written for the fluidity audit of 05/11 (docs/reports/fluidite-2026-11-05)
-- to find WHY the probe's defects happen:
--   joint     a Motor6D turning more than 35 deg in one frame (the motion
--             engine's own cap is 2200 deg/s, ~37-44 deg per frame: above
--             45 deg something bypassed it)
--   facing    the drawn body's yaw turning more than 15 deg in one frame
--   handWorld a hand moving more than 1.4 studs in one frame in the world,
--             the body's own translation removed
--   cam.jump  the lens moving 2.5 studs more than the player's body in one
--             frame, with the lens-body distance before and after and what
--             the line from the body to the old lens hits (an occluder?)
--   track     at every snapshot, how far the drawn track's anchor (the
--             snapshot position carried forward by its velocity, as
--             Presentation.snapshotRoot does) moves in that single frame
-- _G.DIAG.report() / _G.DIAG.reset().
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
if _G.DIAG and _G.DIAG.conns then for _,c in _G.DIAG.conns do c:Disconnect() end end
pcall(function() Run:UnbindFromRenderStep("NDDiagProbe") end)
local D={conns={},tally={},examples={},frames=0,st={human={},bot={}},jumps={human={},bot={}},gaps={},drawnSnaps={human=0,bot=0}}
_G.DIAG=D
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function note(kind,ex,v)
	D.tally[kind]=(D.tally[kind] or 0)+1
	local e=D.examples[kind] or {};D.examples[kind]=e
	table.insert(e,{v=v,e=ex});table.sort(e,function(a,b) return a.v>b.v end);while #e>3 do table.remove(e) end
end
local function ctx(a)
	if not a then return "?" end
	return (a.state or "?")..(if a.attackName and a.state~="Neutral" then ":"..a.attackName else "")..(if a.reaction then " r:"..a.reaction else "")..(if a.airborne then " air" else "")
end
-- The anchor of the drawn track jumps when a snapshot arrives (ground only).
table.insert(D.conns,RS:WaitForChild("NinjaDuel"):WaitForChild("Action").OnClientEvent:Connect(function(d)
	if type(d)~="table" or not d.human or d.phase~="Duel" or not d.serverNow then return end
	local now=workspace:GetServerTimeNow()
	local prev=D.prev
	if prev and prev.epoch==d.epoch then
		table.insert(D.gaps,(d.serverNow-prev.serverNow)*1000)
		for _,key in {"human","bot"} do
			local a,b=prev[key],d[key]
			if a and b and a.position and b.position and (a.warpSerial or 0)==(b.warpSerial or 0) and not a.airborne and not b.airborne then
				local va=if typeof(a.velocity)=="Vector3" then flat(a.velocity) else Vector3.zero
				local vb=if typeof(b.velocity)=="Vector3" then flat(b.velocity) else Vector3.zero
				local oldAt=flat(a.position)+va*math.clamp(now-prev.serverNow,0,.1)
				local newAt=flat(b.position)+vb*math.clamp(now-d.serverNow,0,.1)
				local err=flat(b.position)-(flat(a.position)+va*(d.serverNow-prev.serverNow))
				table.insert(D.jumps[key],{j=(newAt-oldAt).Magnitude,e=err.Magnitude,dv=(vb-va).Magnitude,age=(now-d.serverNow)*1000})
			end
		end
	end
	D.prev={epoch=d.epoch,serverNow=d.serverNow,human=d.human,bot=d.bot}
end))
local lastCam
Run:BindToRenderStep("NDDiagProbe",Enum.RenderPriority.Last.Value,function(dt)
	local cur=_G.FLUID and _G.FLUID.cur
	if not cur or cur.phase~="Duel" or cur.ko or (cur.intro or 0)>0 or dt>.05 then for _,s in D.st do s.t=nil;s.v=nil;s.p=nil end lastCam=nil return end
	local duels=workspace:FindFirstChild("NinjaDuels");local duel=duels and duels:FindFirstChildWhichIsA("Folder")
	if not duel then return end
	D.frames+=1
	local cam=workspace.CurrentCamera
	for key,name in {human="PlayerFighter",bot="AIFighter"} do
		local m=duel:FindFirstChild(name);local a=cur[key];local s=D.st[key]
		local hrp=m and m:FindFirstChild("HumanoidRootPart")
		local torso=m and (m:FindFirstChild("LowerTorso") or m:FindFirstChild("Torso"))
		if hrp and torso and a then
			if not s.motors or s.model~=m then
				s.model=m;s.motors={}
				for _,d in m:GetDescendants() do if d:IsA("Motor6D") then table.insert(s.motors,d) end end
				s.t=nil
			end
			local t={}
			for _,mo in s.motors do t[mo]=mo.Transform end
			local c=ctx(a)
			local warp=a.warpSerial or 0
			if s.t and s.warp==warp then
				for mo,cf in t do
					local was=s.t[mo]
					if was then
						local _,ang=(was:Inverse()*cf):ToAxisAngle()
						ang=math.deg(math.abs(ang))
						if ang>35 then note(key..".joint "..mo.Name,string.format("%.0f° in %.0f ms (%s)",ang,dt*1000,c),ang) end
					end
				end
				local yaw=math.deg(math.acos(math.clamp(hrp.CFrame.LookVector:Dot(s.look),-1,1)))
				if yaw>15 then note(key..".facing",string.format("%.0f° in %.0f ms (%s -> %s)",yaw,dt*1000,s.ctx,c),yaw) end
				for _,hn in {"RightHand","LeftHand"} do
					local h=m:FindFirstChild(hn)
					if h and s.hands and s.hands[hn] then
						local d=((h.Position-s.hands[hn])-(hrp.Position-s.hrp)).Magnitude
						if d>1.4 then note(key..".handWorld",string.format("%s %.2f studs (%s -> %s)",hn,d,s.ctx,c),d) end
					end
				end
				-- Velocity breaks of the drawn body in every state (compare with
				-- tools/feel/fluidity_server.server.luau on the server's own path).
				local p=torso.Position
				if s.p then
					local v=(p-s.p)/dt
					if s.v then
						local acc=(v-s.v).Magnitude/dt
						if acc>650 and v.Magnitude<120 then D.drawnSnaps[key]+=1 end
					end
					s.v=v
				end
			else s.v=nil end
			s.p=torso.Position
			s.t=t;s.warp=warp;s.look=hrp.CFrame.LookVector;s.ctx=c;s.hrp=hrp.Position
			s.hands={}
			for _,hn in {"RightHand","LeftHand"} do local h=m:FindFirstChild(hn) if h then s.hands[hn]=h.Position end end
		end
	end
	local me=duel:FindFirstChild("PlayerFighter");local upper=me and me:FindFirstChild("UpperTorso")
	if upper and lastCam and D.st.human.lastTorso then
		local body=(upper.Position-D.st.human.lastTorso).Magnitude
		local move=(cam.CFrame.Position-lastCam.Position).Magnitude
		if move>body+2.5 then
			local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={duel}
			local before=lastCam.Position-upper.Position
			local hit=workspace:Raycast(upper.Position,before,params)
			local after=(cam.CFrame.Position-upper.Position).Magnitude
			note("cam.jump",string.format("%.1f studs; lens-body %.1f -> %.1f; old line hits %s (%s)",move,before.Magnitude,after,
				if hit then hit.Instance:GetFullName() else "nothing",ctx(cur.human)),move)
		end
	end
	if upper then D.st.human.lastTorso=upper.Position end
	lastCam=cam.CFrame
end)
function D.report()
	local function q(list,f,p)
		local t={}
		for _,x in list do table.insert(t,f(x)) end
		table.sort(t)
		if #t==0 then return 0 end
		return t[math.max(1,math.ceil(#t*p))]
	end
	local id=function(x) return x end
	local out={string.format("frames %d, snapshots %d, server gap p50 %.1f p95 %.1f ms",D.frames,#D.gaps,q(D.gaps,id,.5),q(D.gaps,id,.95))}
	for _,key in {"human","bot"} do
		local J=D.jumps[key];local over=0
		for _,x in J do if x.j>.18 then over+=1 end end
		table.insert(out,string.format("%s: drawn velocity breaks (all states) %d | track jump at a snapshot p50 %.2f p90 %.2f max %.2f studs, >0.18 in %d of %d | constant-velocity error p50 %.2f p90 %.2f | dv p90 %.1f | age p50 %.0f ms",
			key,D.drawnSnaps[key],q(J,function(x) return x.j end,.5),q(J,function(x) return x.j end,.9),q(J,function(x) return x.j end,1),over,#J,
			q(J,function(x) return x.e end,.5),q(J,function(x) return x.e end,.9),q(J,function(x) return x.dv end,.9),q(J,function(x) return x.age end,.5)))
	end
	local keys={}
	for k in D.tally do table.insert(keys,k) end
	table.sort(keys,function(a,b) return D.tally[a]>D.tally[b] end)
	for _,k in keys do
		local ex={}
		for _,e in D.examples[k] do table.insert(ex,e.e) end
		table.insert(out,string.format("%s x%d | %s",k,D.tally[k],table.concat(ex," || ")))
	end
	return table.concat(out,"\n")
end
function D.reset()
	D.tally={};D.examples={};D.frames=0;D.jumps={human={},bot={}};D.gaps={};D.drawnSnaps={human=0,bot=0}
end
return "fluidity diag on"
