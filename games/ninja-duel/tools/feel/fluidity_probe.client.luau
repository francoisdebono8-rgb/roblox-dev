-- Fluidity probe for any duel (Studio, Client datamodel, installed through
-- execute_luau; nothing here ships in a build). The tutorial probe's measures
-- (Client/TutorialProbe), for BOTH fighters and outside the tutorial, plus the
-- frame time and the limbs:
--   pop       the drawn body jumps between two frames (not a declared warp)
--   freeze    the server moves the body, the drawn body stands still
--   slide     drawn ground speed far from the server's own speed
--   snap      the drawn velocity changes brutally in a free move
--   limb      a hand or a foot jumps relative to the torso (an animation
--             cut: a clip starting or ending without a blend)
--   camera    the lens jumps (position or angle) more than the body it follows
--   offscreen a fighter's head out of the view for 0.3 s
--   late      a strike reaches the screen late (server start -> first seen)
--   frame     a rendered frame over 50 ms
-- _G.FLUID.report(label) lists the defects per kind and fighter: the worst
-- example, then "where:" the four most frequent state transitions (from ->
-- to, state + move + reaction + air) it happened in. _G.FLUID.reset() clears.
-- Used for the fluidity audit of 05/11 (docs/reports/fluidite-2026-11-05).
-- Caveats measured there: "limb" is relative to the torso, so a foot planted
-- on the floor while the body turns counts too; "slide" compares with the
-- server's locomotion speed, which stays high while the body is blocked.
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
if _G.FLUID and _G.FLUID.conns then for _,c in _G.FLUID.conns do c:Disconnect() end end
local P={conns={},kinds={},frames=0,dts={},cur=nil,st={human={},bot={}},started=os.clock()}
_G.FLUID=P
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function note(key,kind,value,example,where)
	local k=P.kinds[key.."."..kind]
	if not k then k={n=0,worst={},where={}};P.kinds[key.."."..kind]=k end
	k.n+=1
	if where then k.where[where]=(k.where[where] or 0)+1 end
	table.insert(k.worst,{v=value,e=example})
	table.sort(k.worst,function(a,b) return a.v>b.v end)
	while #k.worst>4 do table.remove(k.worst) end
end
local function context(a)
	if not a then return "?" end
	return string.format("%s%s%s%s%s",a.state or "?",if a.attackName and a.state~="Neutral" then ":"..a.attackName else "",
		if a.reaction then " r:"..a.reaction else "",if a.airborne then " air" else "",if a.wall then " wall" else "")
end
table.insert(P.conns,RS:WaitForChild("NinjaDuel"):WaitForChild("Action").OnClientEvent:Connect(function(d)
	if type(d)=="table" and d.human then P.cur=d end
end))
local function fighters()
	local duels=workspace:FindFirstChild("NinjaDuels")
	local duel=duels and duels:FindFirstChildWhichIsA("Folder")
	if not duel then return nil end
	return {human=duel:FindFirstChild("PlayerFighter"),bot=duel:FindFirstChild("AIFighter")}
end
local LIMBS={"RightHand","LeftHand","RightFoot","LeftFoot"}
pcall(function() Run:UnbindFromRenderStep("NinjaDuelFluidProbe") end)
-- Measured after everything moved this frame (the camera and the drawn bodies).
Run:BindToRenderStep("NinjaDuelFluidProbe",Enum.RenderPriority.Last.Value,function(dt)
	local cur=P.cur
	if not cur or cur.phase~="Duel" or (cur.intro or 0)>0 or cur.ko or dt<=0 then for _,s in P.st do s.last=nil end;return end
	P.frames+=1
	table.insert(P.dts,dt)
	if dt>.05 then note("all","frame",dt*1000,string.format("%.0f ms (%s | %s)",dt*1000,context(cur.human),context(cur.bot))) end
	if dt>.1 then return end
	local models=fighters()
	if not models then return end
	local cam=workspace.CurrentCamera
	local now=os.clock()
	for key,model in models do
		local a=cur[key]
		local torso=model and (model:FindFirstChild("LowerTorso") or model:FindFirstChild("Torso"))
		local head=model and model:FindFirstChild("Head")
		local s=P.st[key]
		if not a or not torso or not head then s.last=nil;continue end
		local p=torso.Position
		local ctx=context(a)
		local last=s.last
		if last and (a.warpSerial or 0)~=last.warp then last=nil;s.settle=now+.3 end
		local settling=now<(s.settle or 0)
		local limbs={}
		for _,name in LIMBS do
			local part=model:FindFirstChild(name)
			if part then limbs[name]=torso.CFrame:PointToObjectSpace(part.Position) end
		end
		if last and not settling then
			local move=p-last.p
			local v=move/dt
			local vFlat=flat(v).Magnitude
			local serverSpeed=math.max(a.speed or 0,flat(a.velocity or Vector3.zero).Magnitude)
			local allowed=math.max(1.2,(math.max(serverSpeed,last.vFlat or 0,80))*dt*1.6)
			local where=last.ctx.." -> "..ctx
			if move.Magnitude>allowed then note(key,"pop",move.Magnitude,string.format("%.2f studs in %.0f ms (%s)",move.Magnitude,dt*1000,where),where) end
			local free=a.state=="Neutral" and not a.reaction and not a.wall and not a.airborne
			if free and (a.speed or 0)>6 and vFlat<.5 then s.stillFor=(s.stillFor or 0)+dt else s.stillFor=0 end
			if s.stillFor>=.25 and not s.freezeOpen then s.freezeOpen=true;note(key,"freeze",s.stillFor,string.format("server %.1f studs/s, drawn 0 (%s)",a.speed or 0,ctx),where) end
			if s.stillFor==0 then s.freezeOpen=false end
			if free then
				local gap=math.abs(vFlat-(a.speed or 0))
				if gap>8 then s.slideFor=(s.slideFor or 0)+dt else s.slideFor=0 end
				if s.slideFor>=.2 and not s.slideOpen then s.slideOpen=true;note(key,"slide",gap,string.format("drawn %.1f / server %.1f studs/s (%s)",vFlat,a.speed or 0,ctx),where) end
				if s.slideFor==0 then s.slideOpen=false end
			end
			if last.v then
				local acc=(v-last.v).Magnitude/dt
				local committed=(a.state~="Neutral" and a.state~="Guarding") or a.reaction~=nil
				if acc>650 and not committed and v.Magnitude<120 then note(key,"snap",acc,string.format("%.0f studs/s² (%s)",acc,where),where) end
			end
			-- limb: a hand or a foot moving relative to the torso faster than a
			-- limb can (25 studs in a frame-second ~ a strike's fist is ~60/s).
			-- One note per frame and fighter: the worst limb.
			if last.limbs then
				local worst,worstName=0,nil
				for name,lp in limbs do
					local was=last.limbs[name]
					if was then
						local jump=(lp-was).Magnitude
						if jump>worst then worst,worstName=jump,name end
					end
				end
				if worstName and worst>math.max(.9,75*dt) then note(key,"limb",worst,string.format("%s %.2f studs in %.0f ms (%s)",worstName,worst,dt*1000,where),where) end
			end
			last.v=v;last.vFlat=vFlat
			if key=="human" and last.cam then
				local cf=cam.CFrame
				local camMove=(cf.Position-last.cam.Position).Magnitude
				local angle=math.deg(math.acos(math.clamp(cf.LookVector:Dot(last.cam.LookVector),-1,1)))
				if camMove>move.Magnitude+2.5 then note("cam","jump",camMove,string.format("lens %.1f studs vs body %.1f (%s)",camMove,move.Magnitude,ctx),where) end
				if angle>18 and not a.ultClip then note("cam","turn",angle,string.format("lens turned %.0f° in one frame (%s)",angle,ctx),where) end
			end
		end
		-- offscreen
		local screen,visible=cam:WorldToViewportPoint(head.Position)
		local size=cam.ViewportSize
		if not visible or screen.X<0 or screen.X>size.X or screen.Y<0 or screen.Y>size.Y*.86 then
			s.offFor=(s.offFor or 0)+dt
			if s.offFor>=.3 and not s.offOpen then s.offOpen=true;note(key,"offscreen",s.offFor,string.format("head at %.0f,%.0f (%s)",screen.X,screen.Y,ctx),ctx) end
		else s.offFor=0;s.offOpen=false end
		-- late strike
		if (a.attackSerial or 0)~=(s.attackSerial or 0) then
			if s.attackSerial~=nil and a.attackElapsed and a.attackName then
				local ms=a.attackElapsed*1000
				if ms>120 then note(key,"late",ms,string.format("%s first seen %.0f ms after it began",a.attackName,ms),a.attackName) end
			end
			s.attackSerial=a.attackSerial or 0
		end
		s.last={p=p,warp=a.warpSerial or 0,ctx=ctx,cam=cam.CFrame,v=last and last.v,vFlat=last and last.vFlat,limbs=limbs}
	end
end)
function P.report(label)
	local out={}
	local sorted=table.clone(P.dts);table.sort(sorted)
	local function pct(q) return (sorted[math.max(1,math.ceil(#sorted*q))] or 0)*1000 end
	local spikes50,spikes100=0,0
	local played=0
	for _,d in P.dts do played+=d;if d>.05 then spikes50+=1 end if d>.1 then spikes100+=1 end end
	-- (fps over the duel's own frames: the time between duels is not counted)
	table.insert(out,string.format((if label then "["..label.."] " else "").."frames %d over %.0f s of duel, fps %.1f, dt p50 %.1f p95 %.1f p99 %.1f max %.0f ms, >50 ms %d, >100 ms %d",
		P.frames,played,P.frames/math.max(played,1e-3),pct(.5),pct(.95),pct(.99),(sorted[#sorted] or 0)*1000,spikes50,spikes100))
	local keys={}
	for k in P.kinds do table.insert(keys,k) end
	table.sort(keys,function(a,b) return P.kinds[a].n>P.kinds[b].n end)
	for _,k in keys do
		local e=P.kinds[k]
		local where={}
		for w,n in e.where do table.insert(where,{w=w,n=n}) end
		table.sort(where,function(a,b) return a.n>b.n end)
		local top={}
		for i,w in where do if i<=4 then table.insert(top,w.w.." x"..w.n) end end
		table.insert(out,string.format("%s x%d | worst: %s | where: %s",k,e.n,e.worst[1] and e.worst[1].e or "?",table.concat(top,", ")))
	end
	return table.concat(out,"\n")
end
function P.reset() table.clear(P.kinds);table.clear(P.dts);P.frames=0;P.started=os.clock() end
return "fluid probe on"
