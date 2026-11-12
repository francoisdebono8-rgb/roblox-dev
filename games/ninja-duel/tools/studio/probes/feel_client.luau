--!nocheck
-- Client (Play, beside feel_audit.luau on the server): what the SCREEN shows
-- of the same two faults (ANIMATEUR, mission « audit feel », 08/11).
--
-- feel_audit.luau reads the server: a body moving fast in a recovery or a
-- guard is a slide there, whatever its legs do on the screen. This probe
-- reads the bodies as drawn, every rendered frame:
--   * glide : the body moves over the floor (> 6 studs/s, feet down) and no
--             foot holds the floor: the slower foot still moves at more than
--             60 % of the body's speed. A step plants a foot; a frozen pose
--             carries both. Episodes over 0.1 s and 1.2 studs, as the server's.
--   * flip  : the drawn body turns more than 45 degrees in one frame.
-- Background: returns at once; shared.NdFeelClient.done after DUR seconds,
-- then shared.NdFeelClient.report. Start it right after feel_audit.luau.
local DUR=60
local RunService=game:GetService("RunService")
local R={done=false,glides={},flips={},counts={glide=0,flip=0,flipBig=0},frames=0}
shared.NdFeelClient=R
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function yawOf(cf) local l=cf.LookVector return math.atan2(-l.X,-l.Z) end
local function angle(a,b) local d=(a-b)%(2*math.pi) if d>math.pi then d-=2*math.pi end return math.abs(math.deg(d)) end
local function bodies()
	local duel=workspace:FindFirstChild("NinjaDuels") and workspace.NinjaDuels:FindFirstChild("Duel_1")
	if not duel then return {} end
	local out={}
	for _,n in {"PlayerFighter","AIFighter"} do
		local m=duel:FindFirstChild(n)
		local root=m and m:FindFirstChild("HumanoidRootPart")
		local lf,rf=m and m:FindFirstChild("LeftFoot"),m and m:FindFirstChild("RightFoot")
		if root and lf and rf then out[n]={root=root,lf=lf,rf=rf} end
	end
	return out
end
local prev,episode={}, {}
local floorY
local t0=os.clock()
local conn
conn=RunService.RenderStepped:Connect(function(dt)
	local t=os.clock()-t0
	if t>DUR then
		conn:Disconnect()
		local lines={string.format("client %d frames in %.0f s (%.0f fps): %d glides (%.1f/min), %d flips >45° (%d >90°)",
			R.frames,DUR,R.frames/DUR,R.counts.glide,R.counts.glide*60/DUR,R.counts.flip,R.counts.flipBig)}
		for i,g in R.glides do if i<=12 then table.insert(lines,"  glide "..g) end end
		for i,f in R.flips do if i<=12 then table.insert(lines,"  flip "..f) end end
		R.report=table.concat(lines,"\n")
		R.done=true
		return
	end
	if dt<=0 then return end
	R.frames+=1
	for name,b in bodies() do
		local cf=b.root.CFrame
		local cur={pos=cf.Position,yaw=yawOf(cf),lf=b.lf.Position,rf=b.rf.Position}
		local low=math.min(cur.lf.Y,cur.rf.Y)
		floorY=if floorY then math.min(floorY,low) else low
		local p=prev[name]
		if p then
			local speed=flat(cur.pos-p.pos).Magnitude/dt
			local fl=flat(cur.lf-p.lf).Magnitude/dt
			local fr=flat(cur.rf-p.rf).Magnitude/dt
			local down=low-floorY<.6
			local turn=angle(cur.yaw,p.yaw)
			if turn>45 then
				R.counts.flip+=1
				if turn>90 then R.counts.flipBig+=1 end
				table.insert(R.flips,string.format("%.2f %s %.0f°",t,name,turn))
			end
			local gliding=down and speed>6 and math.min(fl,fr)>.6*speed and turn<20
			local e=episode[name]
			if gliding then
				if not e then episode[name]={t=t,from=cur.pos,max=speed} else e.max=math.max(e.max,speed) end
			elseif e then
				episode[name]=nil
				local d=flat(cur.pos-e.from).Magnitude
				if t-e.t>.1 and d>1.2 then
					R.counts.glide+=1
					table.insert(R.glides,string.format("%.2f %s %.1f studs en %.2fs, %.0f studs/s",e.t,name,d,t-e.t,e.max))
				end
			end
		end
		prev[name]=cur
	end
end)
return "client probe for "..DUR.." s"
