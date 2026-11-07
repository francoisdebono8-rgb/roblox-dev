--!nocheck
-- Server (ND-DEV, Play): the game-feel audit recorder (07/11, mission « game
-- feel » : « des défauts observés dans Roblox Studio, avec des exemples
-- précis »). Starts A vs B, lets the game's AI play both seats (autopilot) for
-- DUR seconds and watches, every Heartbeat, what the server holds for both
-- bodies: where they are, where they face, what they do. It does not judge the
-- look (that is the video); it finds the moments to look at, with their time.
--
-- Background: returns at once; shared.NdFeel.done when finished, then
--   shared.NdFeel.report  (counts + the worst examples, t = seconds since the
--                          first frame of the duel, after its intro)
-- Edit A, B, DUR (and HP: both bodies get that health so a round lasts) per call.
local A,B,DUR,HP="Legion","Copycat",60,700
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local RunService=game:GetService("RunService")
local function call(...) return dev:Invoke(...) end
local R={done=false,A=A,B=B,examples={},counts={},attacks={},reactions={},log={}}
shared.NdFeel=R
local function count(k,n) R.counts[k]=(R.counts[k] or 0)+(n or 1) end
local function example(kind,t,text)
	R.examples[kind]=R.examples[kind] or {}
	table.insert(R.examples[kind],string.format("%.2f %s",t,text))
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function yawOf(cf) local l=cf.LookVector return math.atan2(-l.X,-l.Z) end
local function angle(a,b) local d=(a-b)%(2*math.pi) if d>math.pi then d-=2*math.pi end return math.abs(math.deg(d)) end
local function faceErr(cf,toward)
	local d=flat(toward-cf.Position)
	if d.Magnitude<.05 then return 0 end
	local l=flat(cf.LookVector)
	if l.Magnitude<.05 then return 0 end
	return math.deg(math.acos(math.clamp(l.Unit:Dot(d.Unit),-1,1)))
end
task.spawn(function()
	call("start",A,B,false)
	local t0=os.clock()
	repeat task.wait(.2) local r=call("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
	call("scripted",true);call("autopilot",true)
	call("health","human",HP);call("health","bot",HP)
	local models={}
	local function model(id)
		local m=models[id]
		if m and m.Parent then return m end
		for _,d in workspace:GetDescendants() do
			if d.Name==id and d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") then models[id]=d return d end
		end
	end
	local function root(id)
		local m=model(id)
		return m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)
	end
	local prev={}        -- last frame per id
	local open={}        -- attack in progress per id
	local react={}       -- reaction being watched per victim id
	local episode={}     -- running episodes (overlap, deadAir)
	local start=os.clock()
	R.wall=DateTime.now():FormatLocalTime("HH:mm:ss","fr-fr")
	local frames=0
	local conn
	conn=RunService.Heartbeat:Connect(function()
		local t=os.clock()-start
		if t>DUR then conn:Disconnect() R.done=true return end
		local ok,snap=pcall(call,"inspect")
		if not ok or type(snap)~="table" or snap.phase~="Duel" then return end
		frames+=1
		local rows={}
		for _,a in snap.actors do rows[a.id]=a end
		local ids={"PlayerFighter","AIFighter"}
		local cur={}
		for i,id in ids do
			local row,rp=rows[id],root(id)
			if row and rp then cur[id]={row=row,cf=rp.CFrame,pos=rp.Position,vel=rp.AssemblyLinearVelocity,other=ids[3-i]} end
		end
		if not cur.PlayerFighter or not cur.AIFighter then return end
		local dist=flat(cur.PlayerFighter.pos-cur.AIFighter.pos).Magnitude
		R.track=R.track or {}
		local function rowtxt(c) local r=c.row return string.format("%.2f,%.2f,%.2f,%.0f,%s,%s,%s,%s,%s,%s",c.pos.X,c.pos.Y,c.pos.Z,math.deg(yawOf(c.cf)),r.state,r.phase,r.move,r.reaction,r.terrain,r.hitConfirmed and 1 or 0) end
		table.insert(R.track,string.format("%.3f|%s|%s",t,rowtxt(cur.PlayerFighter),rowtxt(cur.AIFighter)))
		-- Bodies inside each other (both on the ground, closer than two torsos).
		local bothGround=cur.PlayerFighter.row.terrain=="ground" and cur.AIFighter.row.terrain=="ground"
		if dist<2.2 and bothGround then
			if not episode.overlap then episode.overlap={t=t,min=dist,states=cur.PlayerFighter.row.state.."/"..cur.AIFighter.row.state} end
			episode.overlap.min=math.min(episode.overlap.min,dist)
		elseif episode.overlap then
			local e=episode.overlap;episode.overlap=nil
			count("overlap");count("overlapTime",t-e.t)
			if t-e.t>.12 then example("overlap",e.t,string.format("corps l'un dans l'autre %.2fs (min %.1f studs) %s",t-e.t,e.min,e.states)) end
		end
		-- Dead air: both in neutral, far apart.
		local idle=cur.PlayerFighter.row.state=="Neutral" and cur.AIFighter.row.state=="Neutral"
		if idle and dist>16 then
			episode.dead=episode.dead or {t=t,max=dist}
			episode.dead.max=math.max(episode.dead.max,dist)
		elseif episode.dead then
			local e=episode.dead;episode.dead=nil
			count("deadAirTime",t-e.t)
			if t-e.t>2 then example("deadAir",e.t,string.format("%.1fs sans engagement, jusqu'à %.0f studs",t-e.t,e.max)) end
		end
		for id,c in cur do
			local row=c.row
			local o=cur[c.other]
			local p=prev[id]
			local fe=faceErr(c.cf,o.pos)
			local speed=flat(c.vel).Magnitude
			-- Turning: the server writing a new facing in one frame.
			if p then
				local turn=angle(yawOf(c.cf),yawOf(p.cf))
				local moved=(c.pos-p.pos).Magnitude
				if moved>8 then
					count("teleport")
					example("teleport",t,string.format("%s %.1f studs en une image (%s %s)",row.fighterId,moved,row.state,row.move))
				elseif turn>30 then
					count("snapTurn")
					example("snapTurn",t,string.format("%s pivote %.0f° en une image (%s %s %s)",row.fighterId,turn,row.state,row.move,row.reaction))
				end
				-- Sliding: a grounded body without a step moving fast (idle,
				-- recovery of a ground attack, guard).
				local planted=row.terrain=="ground" and (row.movement=="idle" or row.phase=="recovery" or row.guard)
				if planted and speed>6 and row.state~="Dodging" and row.reaction=="none" then
					episode["slide"..id]=episode["slide"..id] or {t=t,max=speed,state=row.state.." "..row.move,from=c.pos}
					episode["slide"..id].max=math.max(episode["slide"..id].max,speed)
				elseif episode["slide"..id] then
					local e=episode["slide"..id];episode["slide"..id]=nil
					local d=flat(c.pos-e.from).Magnitude
					if t-e.t>.1 and d>1.2 then
						count("slide")
						example("slide",e.t,string.format("%s glisse %.1f studs en %.2fs à %.0f studs/s (%s)",row.fighterId,d,t-e.t,e.max,e.state))
					end
				end
			end
			-- Attacks: from the first startup frame to the next neutral.
			local atk=open[id]
			local attacking=row.phase~="none" and row.move~="none"
			if attacking and (not atk or atk.move~=row.move) then
				if atk then table.insert(R.attacks,atk) end
				atk={id=id,fighter=row.fighterId,move=row.move,t=t,dist=dist,face=fe,oppFace=faceErr(o.cf,c.pos),oppState=o.row.state,oppReaction=o.row.reaction,
					from=c.pos,path=0,hit=false,blocked=false,activeDist=nil,activeFace=nil,air=row.terrain~="ground",oppAir=o.row.terrain~="ground",maxOppFace=0}
				open[id]=atk
				if fe>35 then count("attackMisaimed") example("misaimed",t,string.format("%s lance %s en regardant à %.0f° de l'adversaire (%.1f studs)",row.fighterId,row.move,fe,dist)) end
			elseif not attacking and atk then
				atk.duration=t-atk.t;atk.net=flat(c.pos-atk.from).Magnitude
				table.insert(R.attacks,atk);open[id]=nil
				local brawl=string.find(atk.move,"Light") or string.find(atk.move,"Heavy") or atk.move=="Launcher" or atk.move=="Grab"
				if brawl and not atk.hit and not atk.blocked then
					count("whiff")
					if (atk.activeDist or atk.dist)>7.5 then
						count("whiffFar")
						example("whiffFar",atk.t,string.format("%s %s dans le vide à %.1f studs (départ %.1f), face %.0f°",atk.fighter,atk.move,atk.activeDist or atk.dist,atk.dist,atk.activeFace or atk.face))
					end
				end
			end
			if atk then
				if p then atk.path+=flat(c.pos-p.pos).Magnitude end
				if row.phase=="active" and not atk.activeDist then
					atk.activeDist=dist;atk.activeFace=fe
					if fe>35 and dist<12 then count("activeMisaimed") example("activeMisaimed",t,string.format("%s %s frappe en regardant à %.0f° de l'adversaire (%.1f studs)",row.fighterId,row.move,fe,dist)) end
				end
				if row.hitConfirmed then atk.hit=true end
				if o.row.guard or (o.row.dodge or 0)>0 or (o.row.invulnerability or 0)>0 then atk.blocked=true end
				if row.phase=="startup" and o.row.reaction=="none" and o.row.phase=="none" then
					atk.maxOppFace=math.max(atk.maxOppFace,faceErr(o.cf,c.pos))
				end
			end
			-- Reactions: watch the victim for 0.6 s from the first frame.
			if row.reaction~="none" and (not p or p.row.reaction=="none") then
				local by=open[c.other]
				local from=flat(o.pos-c.pos)
				local hitSide=if from.Magnitude>.1 then math.deg(math.acos(math.clamp(flat(c.cf.LookVector).Unit:Dot(from.Unit),-1,1))) else 0
				react[id]={t=t,kind=row.reaction,fighter=row.fighterId,by=by and by.move or o.row.move,side=hitSide,from=c.pos,att=o.pos,yaw=yawOf(c.cf),maxTurn=0,air=row.terrain~="ground"}
			end
			local rw=react[id]
			if rw then
				if p then rw.maxTurn=math.max(rw.maxTurn,angle(yawOf(c.cf),yawOf(p.cf))) end
				if t-rw.t>=.6 or row.reaction=="none" then
					rw.travel=flat(c.pos-rw.from).Magnitude;rw.turn=angle(yawOf(c.cf),rw.yaw);rw.lasted=t-rw.t
					local away=flat(rw.from-rw.att)
					if rw.travel>1 and away.Magnitude>.1 then
						rw.align=flat(c.pos-rw.from).Unit:Dot(away.Unit)
						if rw.align<-.2 then count("knockToward") example("knockToward",rw.t,string.format("%s (%s par %s) part VERS l'attaquant (%.1f studs, cos %.2f)",rw.fighter,rw.kind,rw.by,rw.travel,rw.align)) end
					end
					table.insert(R.reactions,rw);react[id]=nil
					count("reaction:"..rw.kind)
					if rw.maxTurn>45 then example("reactionSnap",rw.t,string.format("%s (%s par %s) pivote %.0f° en une image",rw.fighter,rw.kind,rw.by,rw.maxTurn)) end
					if rw.side>120 then example("hitFromBehind",rw.t,string.format("%s touché de dos (%.0f°) par %s → %s, recul %.1f studs",rw.fighter,rw.side,rw.by,rw.kind,rw.travel)) end
				end
			end
			prev[id]=c
		end
	end)
	repeat task.wait(.5) until R.done
	call("autopilot",false);call("scripted",false)
	-- The report.
	local rep={A=A,B=B,wall=R.wall,frames=frames,dur=DUR,counts=R.counts}
	local n,far,mis,ex={},0,0,0
	for _,atk in R.attacks do
		local k=atk.fighter.." "..atk.move
		n[k]=n[k] or {count=0,hit=0,blocked=0,whiff=0,dist=0,face=0,oppFace=0,net=0}
		local s=n[k];s.count+=1
		if atk.hit then s.hit+=1 elseif atk.blocked then s.blocked+=1 else s.whiff+=1 end
		s.dist+=atk.activeDist or atk.dist;s.face+=atk.activeFace or atk.face;s.oppFace+=atk.maxOppFace;s.net+=atk.net or 0
	end
	local lines={}
	for k,s in n do
		table.insert(lines,string.format("%-22s n=%2d touché %2d paré/esquivé %2d vide %2d | dist %.1f face %.0f° adv.regard %.0f° dépl %.1f",k,s.count,s.hit,s.blocked,s.whiff,s.dist/s.count,s.face/s.count,s.oppFace/s.count,s.net/s.count))
	end
	table.sort(lines)
	rep.attacks=lines
	local rk={}
	for _,rw in R.reactions do
		local k=rw.fighter.." "..rw.kind
		rk[k]=rk[k] or {n=0,travel=0,turn=0,back=0,lasted=0}
		local s=rk[k];s.n+=1;s.travel+=rw.travel;s.turn+=rw.turn;s.lasted+=rw.lasted;if rw.side>120 then s.back+=1 end
	end
	local rl={}
	for k,s in rk do table.insert(rl,string.format("%-26s n=%2d recul %.1f pivot %.0f° dos %d durée %.2f",k,s.n,s.travel/s.n,s.turn/s.n,s.back,s.lasted/s.n)) end
	table.sort(rl)
	rep.reactions=rl
	rep.examples={}
	for kind,list in R.examples do rep.examples[kind]={n=#list,first=table.move(list,1,math.min(#list,8),1,{})} end
	R.report=rep
end)
return "recording "..A.." vs "..B.." for "..DUR.." s"
