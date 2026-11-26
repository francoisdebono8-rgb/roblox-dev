-- The Ōtsutsuki's tournament (26/11, passe 3, STORY-001, DEC-055; François :
-- « une espèce de petite histoire quand même, sans en faire un jeu
-- d'histoire » ; his choice: le tournoi de l'Ōtsutsuki). Headless: the
-- chapters worked out from the profile (Shared/Story), the story's record and
-- its commands (Server/ProfileSchema), the eight seals and the challengers
-- who come for the missing ones (Server/SoloPlay), the final against him
-- (Matches.finalFight: two rounds, his place, his music), his words when it
-- is not open yet (Server/StoryPlay). His body, his hall and the scenes'
-- screens are Studio checks.
local H=require("./Harness")
local V=H.V
local clock=8000
H.workspace.GetServerTimeNow=function() return clock end
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
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
local Story=H.load("Shared/Story")
local S=H.load("Server/ProfileSchema")
local KitTexts=H.load("Shared/KitTexts")
local Matches=H.load("Server/Matches")
local Progression=H.load("Server/Progression")
local SoloPlay=H.load("Server/SoloPlay")
local StoryPlay=H.load("Server/StoryPlay")
local HubMap=H.load("Shared/HubMap")
local Soundscape=H.load("Client/Soundscape")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local order=KitTexts.Order
local function beatenFirst(n)
	local out={}
	for i=1,n do out[order[i]]=true end
	return out
end
local WEEK="2026-11-27"

test("the chapters follow the profile: the forest, the invitation, the seals, the exam, the final, after",function()
	local function at(facts) facts.order=order;facts.week=facts.week or WEEK;return Story.of(facts) end
	assert(at({intro=false}).n==0 and at({intro=false}).next.kind=="forest","the forest")
	local inv=at({intro=true})
	assert(inv.n==1 and inv.next.kind=="inspiration" and inv.scene=="invitation","the invitation")
	local three=at({intro=true,starter="Leaf",beaten=beatenFirst(3)})
	assert(three.n==2 and three.seals==3 and three.need==8,"the seals: "..three.seals)
	assert(three.next.kind=="challenge" and three.next.kit==order[4],"the next seal is the first of the eight not beaten: "..tostring(three.next.kit))
	assert(three.scene==nil,"a scene in the middle of the seals")
	-- one of the eight beaten out of order: the first missing one is next
	local gap=at({intro=true,starter="Leaf",beaten={[order[2]]=true}})
	assert(gap.next.kit==order[1] and gap.seals==1,"out of order")
	local eight=at({intro=true,starter="Leaf",beaten=beatenFirst(8)})
	assert(eight.n==3 and eight.next.kind=="exam" and eight.scene=="seals" and not eight.final.open,"the exam")
	-- the exam won this week counts, as the record's
	assert(at({intro=true,starter="Leaf",beaten=beatenFirst(8),examWon=true}).n==4,"this week's exam won")
	local rec=Story.new();rec.exam=true
	local final=at({intro=true,starter="Leaf",beaten=beatenFirst(8),record=rec})
	assert(final.n==4 and final.next.kind=="final" and final.final.open and final.scene=="exam","the final")
	-- the exam won before the eighth seal: the seals still come first
	assert(at({intro=true,starter="Leaf",beaten=beatenFirst(5),record=rec}).n==2,"the final before the eight seals")
	rec.final=1;rec.finalWeek=WEEK
	local after=at({intro=true,starter="Leaf",beaten=beatenFirst(8),record=rec})
	assert(after.n==5 and after.next.kind=="free" and not after.final.open and after.scene=="finalWon","after, this week")
	rec.seen.finalWon=true
	local nextWeek=at({intro=true,starter="Leaf",beaten=beatenFirst(8),record=rec,week="2026-12-04"})
	assert(nextWeek.next.kind=="weekly" and nextWeek.final.open and nextWeek.scene=="weekly","he comes back next week")
	rec.weeklySeen="2026-12-04"
	assert(at({intro=true,starter="Leaf",beaten=beatenFirst(8),record=rec,week="2026-12-04"}).scene==nil,"the weekly scene twice")
	-- stronger each final he lost, up to his max
	assert(Story.strength(0)==1 and Story.strength(2)>Story.strength(1) and Story.strength(100)==Story.BOSS.max,"his strength")
	assert(Story.nextString(three)=="challenge:"..order[4] and Story.nextString(eight)=="exam","the journal's next target")
	for n=0,Story.LAST do assert(Story.Chapters[n] and Story.Chapters[n].name~="","chapter "..n.." has no name") end
end)

test("the scenes: a few bubbles each, under a phone's width, the CM's words first",function()
	for id,scene in Story.Scenes do
		assert(#scene.lines>=1 and #scene.lines<=4,id..": "..#scene.lines.." bubbles")
		for _,b in scene.lines do assert(type(b.who)=="string" and #b.line<=48,id..": "..b.line) end
	end
	local mine={{who="X",line="Y"}}
	assert(Story.lines("invitation",{Story={invitation=mine}})==mine,"the CM's words")
	assert(Story.lines("invitation",{})==Story.Scenes.invitation.lines,"the stand-ins")
	for n,id in Story.SceneOf do assert(Story.Scenes[id] and Story.Scenes[id].chapter==n,"chapter "..n.."'s scene") end
end)

test("the story's record in the profile: the exam once, a final won, a scene seen; nothing else",function()
	local p=S.new("dev_story")
	assert(S.validate(p),"a new profile")
	local function run(kind,args) local q,r=S.apply(p,p.sequence+1,kind,args);p=q;return r end
	local r=run("storyExam",{})
	assert(r.first==true and p.story.exam==true,"the exam")
	assert(run("storyExam",{}).first==false,"the exam twice is not a first")
	assert(run("storyFinal",{week=WEEK,won=false}).final==0,"a lost final counts")
	local won=run("storyFinal",{week=WEEK,won=true})
	assert(won.final==1 and p.story.finalWeek==WEEK,"a final won")
	run("storySeen",{scene="invitation"})
	assert(p.story.seen.invitation==true,"the scene seen")
	run("storySeen",{scene="weekly",week=WEEK})
	assert(p.story.weeklySeen==WEEK and p.story.seen.weekly==nil,"the weekly scene")
	assert(not pcall(S.apply,p,p.sequence+1,"storySeen",{scene="nope"}),"an unknown scene")
	assert(not pcall(S.apply,p,p.sequence+1,"storyFinal",{week="soon",won=true}),"a bad week")
	local bad=S.copy(p);bad.story.final=-1
	assert(not S.validate(bad),"a negative final")
	assert(S.serializable(p),"JSON-safe")
end)

test("Progression reads the chapter off the profile's own facts",function()
	local p=S.new("dev_story2")
	assert(Progression.storyOf(p,1795000000).n==0,"a new profile is in the forest")
	p.intro=true
	assert(Progression.storyOf(p,1795000000).n==1,"out of the forest")
	p.kits.starter="Leaf";p.kits.owned.Leaf=true;p.kits.selected="Leaf"
	p.solo={beaten=beatenFirst(8)}
	local v=Progression.storyOf(p,1795000000)
	assert(v.n==3 and v.seals==8,"the eight seals from the challenges won")
end)

test("the challengers come for his missing seals first",function()
	local kits={"A","B","C"}
	local left=SoloPlay.forSeals(kits,{A=true,C=true})
	assert(#left==1 and left[1]=="B","the one not beaten")
	assert(#SoloPlay.forSeals(kits,{A=true,B=true,C=true})==3,"all eight beaten: any of them")
	assert(#SoloPlay.forSeals(kits,nil)==3,"none beaten")
end)

test("the Ōtsutsuki's words while the final is not his",function()
	assert(StoryPlay.word({next={kind="challenge"},seals=3},"not yet")=="3 seals of eight. Go get the rest.","the seals")
	assert(StoryPlay.word({next={kind="exam"}},"not yet")==StoryPlay.Words.exam,"the exam")
	assert(StoryPlay.word({next={kind="free"}},"not yet")==StoryPlay.Words.free,"beaten this week")
	assert(StoryPlay.word(nil,"taken")==StoryPlay.Words.taken,"his place taken")
	assert(StoryPlay.word({next={kind="final"}},"busy")==nil,"busy: nothing")
	for key,w in StoryPlay.Words do assert(#string.format(w,8)<=60,key) end
end)

local inbox={}
local remote={FireClient=function(_,player,data) inbox[player]=inbox[player] or {};table.insert(inbox[player],data) end}
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players,
		SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end

test("the final: him, in the hall, his final's music, two rounds won, his blows harder each week",function()
	local m=Matches.new(remote)
	local player=fakePlayer(61)
	m:selection(player)
	-- not open: refused
	local story={n=3,next={kind="exam"},seals=8,final={open=false,won=0,level=1}}
	local recorded=nil
	local saved={story=Progression.story,view=Progression.view,owns=Progression.owns,storyFinal=Progression.storyFinal}
	Progression.story=function() return story end
	Progression.view=function() return {selected="Leaf"} end
	Progression.owns=function() return true end
	Progression.storyFinal=function(_,won) recorded=won;return {final=if won then 1 else 0} end
	local ok,why=m:finalFight(player)
	assert(ok==false and why=="not yet","the final before the exam: "..tostring(why))
	story={n=5,next={kind="weekly"},seals=8,final={open=true,won=2,level=Story.strength(2)}}
	assert(m:finalFight(player)==true,"the final did not start")
	local s=m.sessions[player]
	assert(s.phase=="Duel" and s.botId==Story.BOSS.kit and s.playerId=="Leaf","the fighters")
	assert(s.site and s.site.key=="Final" and s.site.final==true and s.site.place==Story.BOSS.duel.place,"his place")
	local site=Story.site(HubMap.Scale)
	assert((s.origin-(HubMap.Origin+site.at)).Magnitude<.01,"the hall's floor")
	assert(s.roundsToWin==2,"two rounds")
	assert(s.bot.displayName==Story.BOSS.name and math.abs((s.bot.outScale or 1)-Story.strength(2))<1e-6,"his name and strength")
	assert(s.dare and s.dare.who==Story.BOSS.name and s.dare.line~="","his word before")
	local snap=m:view(s,s,s.human,s.bot)
	assert(snap.site.final==true and Soundscape.state(snap,nil)=="final","the final's music: "..tostring(Soundscape.state(snap,nil)))
	-- a second walker can't take the hall meanwhile
	local other=fakePlayer(62)
	m:selection(other)
	local ok2,why2=m:finalFight(other)
	assert(ok2==false and why2=="taken","the hall twice: "..tostring(why2))
	-- two rounds to the player
	for _=1,2 do
		s.finish(s.human,s.bot)
		clock+=3;runTimers()
	end
	assert(s.phase=="Result","not decided after two rounds")
	assert(recorded==true,"the final not recorded")
	assert(s.progress and s.progress.final and s.progress.final.won==true and s.progress.final.say,"the result does not say it")
	-- REMATCH once he won it: not a plain duel against the stand-in kit, Konoha
	story={n=5,next={kind="free"},seals=8,final={open=false,won=3,level=Story.strength(3)}}
	s.lastLifecycle=-10
	m:request(player,{action="Rematch",epoch=s.epoch})
	assert(s.phase=="Selection","a rematch of a final already won: "..s.phase)
	-- lost, REMATCH is the final again
	story={n=4,next={kind="final"},seals=8,final={open=true,won=0,level=1}}
	assert(m:finalFight(player)==true,"the final again")
	for _=1,2 do s.finish(s.bot,s.human);clock+=3;runTimers() end
	assert(s.phase=="Result" and recorded==false,"the final lost")
	clock+=2;s.lastLifecycle=-10
	m:request(player,{action="Rematch",epoch=s.epoch})
	assert(s.phase=="Duel" and s.site and s.site.final and s.roundsToWin==2 and s.bot.displayName==Story.BOSS.name,"the rematch is the final")
	m:selection(player)
	assert(s.final==nil,"the final kept after it")
	for k,f in saved do Progression[k]=f end
end)

print(("Story: %d tests passed"):format(passed))
