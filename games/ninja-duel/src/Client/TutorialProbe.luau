-- Debug/QA places only (build.py DEBUG_SOURCES). The tutorial as a test of the
-- game (user 02/11: "the tutorial must serve the game": find what keeps it
-- from being fluid). Every rendered frame of a tutorial step it measures what
-- the player sees, per fighter and per step, and keeps the worst examples:
--   pop       the drawn body jumps between two frames (not a declared warp)
--   freeze    the server wants the body to move, the drawn body does not
--   slide     the drawn body moves while the server says it stands, or runs
--             far slower/faster than the server's own speed
--   snap      the drawn velocity changes brutally out of a free move
--             (run -> jump, wall -> air, landing): the "cut" a player feels
--   camera    the camera jumps (position or angle) more than the body it follows
--   offscreen the fighter's head leaves the view
--   late      a strike or a jump reaches the screen late (server start -> seen)
-- Read it with LocalPlayer.NinjaDuelProbe:Invoke("report") (or "totals") from
-- the Client command bar or the Studio MCP Client datamodel. Measures only: changes nothing in the game.
local RunService=game:GetService("RunService")
local Probe={}

local function flat(v) return Vector3.new(v.X,0,v.Z) end
local KINDS={"pop","freeze","slide","snap","camera","offscreen","late"}

function Probe.install(ctx)
	local data={} -- data[fighter][step]={kind={n=,worst=,example=}}
	local order={}
	local st={}
	local function bucket(fighter,step)
		local f=data[fighter];if not f then f={};data[fighter]=f;table.insert(order,fighter) end
		local b=f[step];if not b then b={frames=0};f[step]=b end
		return b
	end
	local function note(b,kind,value,example)
		local k=b[kind];if not k then k={n=0,worst=0};b[kind]=k end
		k.n+=1
		if value>k.worst then k.worst=value;k.example=example end
	end
	local function context(h)
		return string.format("%s%s%s%s%s",h.state or "?",if h.attackName and h.state~="Neutral" then ":"..h.attackName else "",
			if h.reaction then " r:"..h.reaction else "",if h.airborne then " air" else "",if h.wall then " wall:"..tostring(h.wallMode) else "")
	end
	RunService:BindToRenderStep("NinjaDuelTutorialProbe",Enum.RenderPriority.Camera.Value+3,function(dt)
		local cur=ctx.state()
		if not cur or cur.phase~="Duel" or not cur.tutorial or not cur.human or dt<=0 or dt>.1 then st.last=nil;return end
		local h=cur.human
		local model=ctx.player.Character
		local head=model and model:FindFirstChild("Head")
		local torso=model and (model:FindFirstChild("LowerTorso") or model:FindFirstChild("Torso"))
		if not head or not torso then return end
		local fighter=h.fighterId or "?"
		local step=cur.tutorial.id or "?"
		local b=bucket(fighter,step);b.frames+=1
		local cam=workspace.CurrentCamera
		local now=os.clock()
		local p=torso.Position
		local last=st.last
		-- A new step relocates both bodies (Tutorial.enter): not a defect.
		if last and (last.step~=step or last.fighter~=fighter or (h.warpSerial or 0)~=last.warp) then last=nil;st.settle=now+.35 end
		local settling=now<(st.settle or 0)
		local ctxText=context(h)
		if last and not settling then
			local move=p-last.p
			local v=move/dt
			local vFlat=flat(v).Magnitude
			local serverSpeed=math.max(h.speed or 0,flat(h.velocity or Vector3.zero).Magnitude)
			-- pop: more travel in one frame than the fastest the body may go.
			local allowed=math.max(1.2,(math.max(serverSpeed,last.vFlat or 0,80))*dt*1.6)
			if move.Magnitude>allowed then note(b,"pop",move.Magnitude,string.format("%.2f studs in %.0f ms (%s -> %s)",move.Magnitude,dt*1000,last.ctx,ctxText)) end
			local free=h.state=="Neutral" and not h.reaction and not h.wall and not h.airborne and (h.airHold or 0)==0
			-- freeze: the server runs, the screen stands.
			if free and (h.speed or 0)>6 and vFlat<.5 then st.stillFor=(st.stillFor or 0)+dt else st.stillFor=0 end
			if st.stillFor>=.25 and not st.freezeOpen then st.freezeOpen=true;note(b,"freeze",st.stillFor,"server speed "..string.format("%.1f",h.speed or 0).." / drawn 0 ("..ctxText..")") end
			if st.stillFor==0 then st.freezeOpen=false end
			-- slide: drawn speed against the server's own, free on the ground.
			if free and h.state=="Neutral" then
				local gap=math.abs(vFlat-(h.speed or 0))
				if gap>8 then st.slideFor=(st.slideFor or 0)+dt else st.slideFor=0 end
				if st.slideFor>=.2 and not st.slideOpen then st.slideOpen=true;note(b,"slide",gap,string.format("drawn %.1f / server %.1f studs/s (%s)",vFlat,h.speed or 0,ctxText)) end
				if st.slideFor==0 then st.slideOpen=false end
			end
			-- snap: brutal change of the drawn velocity around a free move.
			if last.v then
				local acc=(v-last.v).Magnitude/dt
				local committed=(h.state~="Neutral" and h.state~="Guarding") or h.reaction~=nil
				if acc>650 and not committed and v.Magnitude<120 then
					note(b,"snap",acc,string.format("%.0f studs/s² (%s -> %s)",acc,last.ctx,ctxText))
				end
			end
			-- camera: the view moves much more than the body it follows.
			local cf=cam.CFrame
			if last.cam then
				local camMove=(cf.Position-last.cam.Position).Magnitude
				local angle=math.deg(math.acos(math.clamp(cf.LookVector:Dot(last.cam.LookVector),-1,1)))
				if camMove>move.Magnitude+2.5 then note(b,"camera",camMove,string.format("camera %.1f studs vs body %.1f (%s)",camMove,move.Magnitude,ctxText)) end
				if angle>18 and not h.ultClip then note(b,"camera",angle,string.format("camera turned %.0f° in one frame (%s)",angle,ctxText)) end
			end
			-- offscreen: the head out of the view (or hidden by the HUD's bottom bar).
			local screen,visible=cam:WorldToViewportPoint(head.Position)
			local size=cam.ViewportSize
			if not visible or screen.X<0 or screen.X>size.X or screen.Y<0 or screen.Y>size.Y*.86 then
				st.offFor=(st.offFor or 0)+dt
				if st.offFor>=.3 and not st.offOpen then st.offOpen=true;note(b,"offscreen",st.offFor,"head at "..string.format("%.0f,%.0f",screen.X,screen.Y).." ("..ctxText..")") end
			else st.offFor=0;st.offOpen=false end
			st.lastV=v
			last.v=v;last.vFlat=vFlat
		end
		-- late: how old a strike is when the screen first shows it.
		if (h.attackSerial or 0)~=(st.attackSerial or 0) then
			if st.attackSerial~=nil and h.attackElapsed and h.attackName then
				local ms=h.attackElapsed*1000
				if ms>120 then note(b,"late",ms,string.format("%s seen %.0f ms after it began",h.attackName,ms)) end
			end
			st.attackSerial=h.attackSerial or 0
		end
		-- jump: server airborne -> the drawn body leaves the ground.
		if h.airborne and not st.wasAir then st.airAt=now;st.airFrom=p.Y end
		if st.airAt and p.Y>(st.airFrom or p.Y)+.4 then
			local ms=(now-st.airAt)*1000
			if ms>120 then note(b,"late",ms,string.format("jump drawn %.0f ms after the server's take-off",ms)) end
			st.airAt=nil
		end
		if not h.airborne then st.airAt=nil end
		st.wasAir=h.airborne
		st.last={p=p,step=step,fighter=fighter,warp=h.warpSerial or 0,ctx=ctxText,cam=cam.CFrame,v=last and last.v,vFlat=last and last.vFlat}
	end)
	local api={}
	function api.reset() table.clear(data);table.clear(order) end
	-- One line per fighter and step that has a defect, worst first.
	function api.report(fighter)
		local lines={}
		for _,f in order do
			if not fighter or f==fighter then
				for step,b in data[f] do
					for _,kind in KINDS do
						local k=b[kind]
						if k then table.insert(lines,{score=k.n*(if kind=="freeze" or kind=="pop" then 4 else 1),text=string.format("%s %s %s x%d worst: %s",f,step,kind,k.n,tostring(k.example))}) end
					end
				end
			end
		end
		table.sort(lines,function(a,b) return a.score>b.score end)
		local out={};for i,l in lines do out[i]=l.text end
		return table.concat(out,"\n")
	end
	-- Totals per kind and fighter (a table to compare fighters).
	function api.totals()
		local out={}
		for _,f in order do
			local row={f}
			for _,kind in KINDS do
				local n=0;for _,b in data[f] do if b[kind] then n+=b[kind].n end end
				if n>0 then table.insert(row,kind.."="..n) end
			end
			table.insert(out,table.concat(row," "))
		end
		return table.concat(out,"\n")
	end
	api.data=data
	_G.NinjaDuelProbe=api
	-- Studio tools run in another script context (_G is not shared): a local
	-- BindableFunction answers them (op "report" | "totals" | "reset").
	local hook=Instance.new("BindableFunction");hook.Name="NinjaDuelProbe"
	hook.OnInvoke=function(op,arg) local f=api[op or "report"];return f and f(arg) end
	hook.Parent=ctx.player
	return api
end
return Probe
