-- Server: the jutsu reel (jutsu pass, 05/11). Every quick jutsu, hand-seal
-- jutsu, awakening and ultimate of the beta's eight fighters, cast one after
-- the other against a frozen dummy, each shot opened by NDShot (the client
-- overlay, jutsu_reel_client.luau, shows a black title card there). Runs in
-- the background: progress in workspace attribute NDReel, the per-shot log
-- (cast answer, timings) as JSON in NDReelLog. Goes through DevHooks'
-- attribute channel (execute_luau may not invoke NinjaDuelDev).
-- FIGHTERS: the run's order; nil = all eight.
local FIGHTERS=nil
local Http=game:GetService("HttpService")
local function dev(...)
	local args={...}
	for i,a in args do if typeof(a)=="Vector3" then args[i]={a.X,a.Y,a.Z} end end
	local t0=os.clock()
	while workspace:GetAttribute("NDDevResult")=="pending" and os.clock()-t0<5 do task.wait(.03) end
	workspace:SetAttribute("NDDevResult","pending")
	workspace:SetAttribute("NDDev",Http:JSONEncode({args=args}))
	t0=os.clock()
	repeat task.wait(.03) until workspace:GetAttribute("NDDevResult")~="pending" or os.clock()-t0>8
	local r=workspace:GetAttribute("NDDevResult")
	local ok,dec=pcall(function() return Http:JSONDecode(r) end)
	return if ok then dec else r
end
local B="Mirage" -- the dummy (Kakashi when Itachi casts)
-- {action, gap, label, opts}: opts.bot = the dummy strikes after the cast (counters, reads),
-- opts.pre = presses before the cast, opts.botPre = the dummy casts first, opts.follow = a press after it.
local SHOTS={
	Mirage={
		{"Technique1",14,"Shadow Shuriken"},{"Technique2",14,"Great Fireball"},
		{"Technique3",6,"Genjutsu: Mirage",{bot=.35}},{"Technique4",5,"Sharingan Read",{bot=.25}},
		{"Seal1",8,"Crows"},{"Seal2",5,"Exploding Clone",{bot=.2}},{"Seal3",10,"Sharingan: Paralysis"},{"Seal4",14,"Phoenix Sage Fire"},
	},
	Copycat={
		{"Technique1",14,"Water Dragon"},{"Technique2",10,"Lightning Blade"},{"Technique3",14,"Tracking Fang"},{"Technique4",12,"Lightning Cut"},
		{"Seal1",8,"Earth Wall"},{"Seal2",12,"Earth Headhunter"},{"Seal3",14,"Earth Dragon"},{"Seal4",8,"White Chakra Sabre"},
	},
	Lion={
		{"Technique1",14,"Phoenix Flower"},{"Technique2",10,"Chidori"},{"Technique3",12,"Wire Trap"},{"Technique4",14,"Great Fireball"},
		{"Technique3",12,"Wire Trap + Dragon Flame",{follow={.55,"Technique4",{chakra=true}}}},
		{"Seal1",14,"Soshuha"},{"Seal2",14,"Windmill Blades"},{"Seal3",5,"Sharingan: Counter",{bot=.2}},{"Seal4",12,"Sharingan: Copy",{botPre="Seal4"}},
	},
	Leaf={
		{"Technique1",8,"Leaf Great Whirlwind"},{"Technique2",6,"Primary Lotus"},{"Technique3",8,"Remove the Weights"},{"Technique4",16,"Dynamic Entry"},
		{"Seal1",5,"Nunchaku"},{"Seal2",4,"Dancing Leaf Shadow",{pre={"Attack","Attack","Heavy"},preWait=.42}},{"Seal3",8,"Drunken Fist"},{"Seal4",5,"Goriki Senpu"},
	},
	Legion={
		{"Technique1",10,"Shadow Clone"},{"Technique2",7,"Rasengan"},{"Technique3",12,"Multi Shadow Clone"},{"Technique4",6,"Uzumaki Rendan"},
		{"Seal1",10,"Clone Ambush"},{"Seal2",14,"Hidden Fuma"},{"Seal3",12,"Summoning: Gamakichi"},{"Seal4",10,"Clone Throw"},
	},
	Sand={
		{"Technique1",14,"Sand Shuriken"},{"Technique2",12,"Sand Coffin"},{"Technique3",5,"Desert Wave",{bot=.15}},{"Technique4",5,"Sand Armor",{bot=.35}},
		{"Seal1",7,"Shukaku's Arm"},{"Seal2",12,"Sand Spikes"},{"Seal3",12,"Quicksand"},{"Seal4",8,"Third Eye"},{"Seal5",5,"Sand Clone",{bot=.2}},
	},
	GentleFist={
		{"Technique1",12,"Vacuum Palm"},{"Technique2",4,"64 Palms"},{"Technique3",5,"Rotation",{bot=.12}},{"Technique4",8,"Byakugan"},
		{"Seal1",12,"Hasangeki"},{"Seal2",5,"Leg Points"},{"Seal3",5,"Counter Palm",{bot=.2}},{"Seal4",6,"Trigram Field"},
	},
	Flashstep={
		{"Technique1",14,"Marked Kunai"},{"Technique2",14,"Lightning Strike"},{"Technique3",14,"Flying Thunder God",{pre={"Technique1"},preAim=Vector3.new(7,0,3),preWait=.9}},{"Technique4",14,"Wind Cut"},
		{"Seal1",6,"Rasengan"},{"Seal2",12,"Sealing Trap"},{"Seal3",5,"Space-Time Barrier",{bot=.2}},{"Seal4",10,"Flying Thunder God 2"},
	},
}
local ORDER=FIGHTERS or {"Mirage","Copycat","Lion","Leaf","Legion","Sand","GentleFist","Flashstep"}
local log={}
local index=0
local function place(gap)
	dev("move","human",Vector3.zero);dev("move","bot",Vector3.zero)
	dev("place",Vector3.new(0,3,gap/2),Vector3.new(0,3,-gap/2))
end
local function settle(minT,maxT)
	local t0=os.clock();local calm=0
	task.wait(minT)
	while os.clock()-t0<maxT do
		local s=dev("state")
		local h=type(s)=="table" and s.human
		local b=type(s)=="table" and s.bot
		if h and h.state=="Neutral" and not h.pending and not h.reaction and (not b or not b.reaction) then calm+=1 else calm=0 end
		if calm>=3 then break end
		task.wait(.1)
	end
	return os.clock()-t0
end
local function shot(A,entry)
	index+=1
	local action,gap,label,opts=entry[1],entry[2],entry[3],entry[4] or {}
	local cam=if action=="Ultimate" then "game" else "side"
	workspace:SetAttribute("NDShot",string.format("%02d|%s|%s|%s|%s",index,A,action,label,cam))
	task.wait(.08)
	dev("refill");dev("health","human",400);dev("health","bot",400)
	place(gap)
	task.wait(.45)
	if action=="Awaken" then dev("health","human",30) end
	if action=="Ultimate" then dev("ultimate","human",100) end
	local rec={i=index,fighter=A,action=action,label=label,t=os.clock()}
	if opts.botPre then
		local s=dev("state");rec.botPre=dev("act","bot",opts.botPre,s.human and s.human.position);task.wait(.7)
	end
	local s=dev("state")
	for _,p in opts.pre or {} do
		local preAim=if opts.preAim and s.bot then Vector3.new(table.unpack(s.bot.position))+opts.preAim else nil
		rec.pre=(rec.pre or "")..p..":"..tostring((dev("act","human",p,preAim) or {}).reason).." ";task.wait(opts.preWait or .32)
	end
	s=dev("state")
	local aim=s.bot and s.bot.position
	local r=dev("act","human",action,aim)
	rec.ok=type(r)=="table" and r.ok;rec.reason=type(r)=="table" and r.reason or r
	if opts.bot then task.wait(opts.bot);rec.botHit=dev("act","bot","Attack",s.human and s.human.position) end
	if opts.follow then task.wait(opts.follow[1]);rec.follow=dev("act","human",opts.follow[2],aim,opts.follow[3]) end
	local long=action=="Ultimate"
	rec.dur=settle(if long then 3 else 1.2,if long then 14 else 7)
	task.wait(.9)
	table.insert(log,rec)
	workspace:SetAttribute("NDReelLog",Http:JSONEncode(log))
	workspace:SetAttribute("NDReel",string.format("%d %s %s",index,A,action))
end
local function startDuel(A)
	local b=if A=="Mirage" then "Copycat" else B
	workspace:SetAttribute("NDShot",string.format("%02d|%s|start|vs %s|side",index,A,b))
	dev("start",A,b)
	local t0=os.clock()
	repeat task.wait(.25);local r=dev("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>14
	dev("autopilot",false);dev("freezeBot",true);dev("scripted",true)
end
shared.NdReelStop=false
task.spawn(function()
	workspace:SetAttribute("NDReel","running")
	for _,A in ORDER do
		if shared.NdReelStop then break end
		startDuel(A)
		for _,e in SHOTS[A] do if shared.NdReelStop then break end;shot(A,e) end
		if not shared.NdReelStop then shot(A,{"Awaken",7,"Awakening"}) end
		if not shared.NdReelStop then shot(A,{"Ultimate",6,"Ultimate"}) end
	end
	workspace:SetAttribute("NDShot","")
	workspace:SetAttribute("NDReel","done "..index)
end)
return "reel started: "..table.concat(ORDER,",")
