-- The CM's series « YOUR AVATAR × NARUTO SCENES » (27/11, doc projet
-- claude/cm-concept-scenes-naruto-2026-11-27, INBOX-CM-SCENES-20261127): the
-- sceneFilm op (Server/DevSceneFilm) plays a WRITTEN scene in a street of
-- Konoha: the avatar wearing a prodigy's whole kit against the prodigy of the
-- scene, each beat pressed at its time through the duel's real presses, the
-- foe's automatic defences his, the K.O. on the last beat's blow, and tells
-- when each beat was pressed, each blow that landed and each the sand stopped.
-- Real Matches / Combat on harness rigs and a scripted clock; the picture is
-- the CM's, in Studio.
local H=require("./Harness")
local V=H.V
local clock=5000
H.workspace.GetServerTimeNow=function() return clock end
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
H.envBase.Random={new=function(seed)
	local state=(seed or 1)*2654435761%4294967296
	local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
	return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
		NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	return x
end}
H.load("Shared/Config").DamageScale=H.GameDamageScale
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Matches=H.load("Server/Matches")
local SoloPlay=H.load("Server/SoloPlay")
local Progression=H.load("Server/Progression")
local AI=H.load("Server/AI")
local Scene=H.load("Server/DevSceneFilm")
local DevHooks=H.load("Server/DevHooks")
local AvatarBody=H.load("Server/AvatarBody")
-- (the harness has no Roblox avatar: the prodigy's rig stands in for his body)
AvatarBody.rig=function() return nil end
local HubMap=H.load("Shared/HubMap")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local inbox={}
local remote={FireClient=function(_,player,data) inbox[player]=inbox[player] or {};table.insert(inbox[player],data) end}
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players,
		SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end

test("sceneFilm's spec: the streets, the kits, every act a move of the kit, and says what is wrong",function()
	local _,why=Scene.plan({preset="Moon"})
	assert(why and string.find(why,"LeeWeights",1,true),"the presets are not listed: "..tostring(why))
	_,why=Scene.plan({street="Moon",avatar={kit="Leaf"},foe={kit="Sand"},beats={{t=0,act="light"}}})
	assert(why and string.find(why,"Plaza",1,true),"the streets are not listed: "..tostring(why))
	assert(Scene.plan({avatar={kit="Nobody"},foe={kit="Sand"},beats={{t=0,act="light"}}})==nil,"an unknown kit")
	_,why=Scene.plan({avatar={kit="Leaf"},foe={kit="Sand"},beats={{t=0,act="Rasengan"}}})
	assert(why and string.find(why,"RemoveWeights",1,true) and string.find(why,"beat 1",1,true),"a move Lee does not have: "..tostring(why))
	assert(Scene.plan({avatar={kit="Leaf"},foe={kit="Sand"},beats={{t=-1,act="light"}}})==nil,"a beat before the scene")
	assert(Scene.plan({avatar={kit="Leaf"},foe={kit="Sand"},beats={{t=0,who="crowd",act="light"}}})==nil,"a third fighter")
	assert(Scene.plan({avatar={kit="Leaf"},foe={kit="Sand"},beats={}})==nil,"no beat")
	-- the words: the keys, a chakra move by its name, a technique and a seal jutsu by their Id
	local r=assert(Scene.resolve("Leaf","light"));assert(r.action=="Attack" and r.opts==nil,"light")
	r=assert(Scene.resolve("Leaf","AfterImage"));assert(r.action=="Dodge" and r.opts and r.opts.chakra,"AfterImage is the chakra dash")
	r=assert(Scene.resolve("Leaf","chakra leap"));assert(r.action=="Jump" and r.opts.chakra,"the chakra leap")
	local Fighters=H.load("Shared/Fighters")
	for i,tech in Fighters.Leaf.Techniques do
		r=assert(Scene.resolve("Leaf",tech.Id));assert(r.action=="Technique"..i,tech.Id.." is not his key "..i)
	end
	r=assert(Scene.resolve("Legion","CloneAmbush"));assert(r.kind=="seals" and #r.seals==2,"Naruto's clone from the floor is a seal jutsu")
	-- positional beats {t, who, act, toward}; a seal jutsu is the weave (open, two seals)
	local p=assert(Scene.plan({avatar={kit="Legion"},foe={kit="GentleFist"},beats={{1,"avatar","CloneAmbush"},{0,"foe","guard"},{2,"foe","Rotation"}}}))
	assert(#p.presses==5 and p.presses[1].who=="foe" and p.presses[1].action=="Guard","in time order")
	assert(p.presses[2].action=="Seals" and p.presses[3].action:match("^Technique") and p.presses[4].part and p.presses[4].t>p.presses[3].t,"the weave")
	assert(p.presses[5].action=="Dodge" and p.presses[5].opts.chakra,"Neji's Rotation is his chakra dash")
	assert(p.koAtEnd and p.koAt==2 and p.flash and p.gap==Scene.DEFAULT.gap,"the defaults")
	-- the preset, and what the spec changes in it
	local lee=assert(Scene.plan({preset="LeeWeights",take=3}))
	assert(lee.avatar=="Leaf" and lee.foe=="Sand" and lee.take==3 and table.find(lee.nodes,"HeavyDrop"),"Lee's weights")
end)

test("sceneFilm Lee vs Gaara: in the street, the sand stops his blows, the weights crater the floor, the Lotus knocks Gaara out",function()
	local m=Matches.new(remote)
	local player=fakePlayer(9)
	m:selection(player)
	local attrs={}
	local flashes=0
	local scene=Scene.new({matches=m,press=DevHooks.press,avatarState=function() return "ready" end,
		attribute=function(k,v) attrs[k]=v end,flash=function() flashes+=1 end,clock=function() return clock end})
	local r=scene:start(player,{preset="LeeWeights"},clock)
	assert(r.ok and r.street=="Plaza" and r.avatar=="Leaf" and r.foe=="Sand","not started: "..tostring(r.error))
	local s=m.sessions[player]
	assert(s.phase=="Duel" and s.site and s.site.key=="Plaza" and s.site.street,"not in the street")
	assert(s.human.fighterId=="Leaf" and s.bot.fighterId=="Sand" and s.scripted and s.botFrozen and s.roundsToWin==1,"the scene's frame")
	assert(s.introUntil==nil,"the intro plays")
	-- the prodigy's whole kit his, with the weights' crater
	for _,tech in s.human.def.Techniques do assert(not tech.Locked,tech.Id.." is locked for the shoot") end
	local weights
	for _,tech in s.human.def.Techniques do if tech.Id=="RemoveWeights" then weights=tech end end
	assert(weights and weights.Drop,"the weights do not crater the floor")
	local gap=(s.human.root.Position-s.bot.root.Position)*V.new(1,0,1)
	assert(math.abs(gap.Magnitude-7)<.6,"not 7 studs apart: "..gap.Magnitude)
	local function step(seconds)
		for _=1,math.max(1,math.ceil(seconds/.02)) do clock+=.02;m:update(.02,clock);runTimers();scene:step(clock) end
	end
	local t=0
	while scene:result().state=="playing" and t<40 do step(.1);t+=.1 end
	local res=scene:result()
	assert(flashes==1 and res.flashAt and res.flashAt<res.t0,"the sync flash")
	assert(attrs.NDTake==1 and type(attrs.NDBeat)=="string","the cameras are not told the beat")
	local presses=#Scene.plan({preset="LeeWeights"}).presses
	assert(#res.beats==presses,"pressed "..#res.beats.." of "..presses)
	for _,b in res.beats do assert(math.abs(b.since-b.t)<.05,"beat "..b.beat.." pressed at "..b.since.." for "..b.t) end
	local blocked,early,drop=0,0,false
	for _,e in res.events do
		if e.event=="SandShield" and e.who=="foe" then blocked+=1;if e.since<5 then early+=1 end end
		if e.event=="WeightsDrop" then drop=true end
	end
	local landed=0
	for _,h in res.hits do if h.by=="avatar" then landed+=1 end end
	local lines={}
	for _,b in res.beats do table.insert(lines,string.format("%.1f %s%s",b.since,b.act,if b.ok then "" else "(no: "..tostring(b.why)..")")) end
	print("     beats: "..table.concat(lines," · "))
	print(string.format("     the sand stopped %d blows (%d before 5 s), %d landed; weights down: %s; K.O. %s at %.1f s%s",
		blocked,early,landed,tostring(drop),tostring(res.ko and res.ko.by),res.ko and res.ko.since or -1,if res.ko and res.ko.forced then " (forced)" else ""))
	assert(early>=3,"the sand did not stop his first blows: "..early)
	assert(drop,"the weights did not fall")
	assert(landed>=3,"his blows never got past the sand")
	assert(res.state=="done" and res.ko and res.ko.by=="avatar" and not res.ko.forced,"Gaara is not knocked out by a blow: "..tostring(res.state).." "..tostring(res.error))
	-- the Lotus's slam into the floor, not its first seizing blow
	local final
	for _,h in res.hits do if h.by=="avatar" and h.since<=res.ko.since+.05 then final=h end end
	assert(final and final.tag=="Slam" and res.ko.since>13,"the K.O. is not the Lotus's slam: "..tostring(final and final.tag))
	assert(s.phase=="Result" and not s.scripted and not s.botFrozen,"his stick is not back")
	-- another take, from the result screen
	local again=scene:start(player,{preset="LeeWeights",take=2},clock)
	assert(again.ok,"another take: "..tostring(again.error))
end)

print(string.format("NinjaDuel sceneFilm (the CM's Naruto scenes): %d PASS",passed))
