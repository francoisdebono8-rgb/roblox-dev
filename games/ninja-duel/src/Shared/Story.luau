-- The Ōtsutsuki's tournament (26/11, passe 3, DEC-055, STORY-001; François :
-- « une espèce de petite histoire quand même, sans en faire un jeu
-- d'histoire. Nous, c'est clairement un jeu de baston » ; his choice: le
-- tournoi de l'Ōtsutsuki). Every chapter is a fight; the story is a few
-- manga bubbles before or after, that he can skip.
--   0 THE FOREST      the bandit, the path, the creation at the gate
--   1 THE INVITATION  the Ōtsutsuki at the gate; his first inspiration
--   2 THE EIGHT SEALS each prodigy's street challenge won is a seal
--   3 THE EXAM        the eight's bracket won with his kit (Server/Tournament)
--   4 THE FINAL       the Ōtsutsuki himself, in the exam hall, two rounds
--   5 AFTER           he comes back every week, stronger
-- Nothing here is stored twice: the chapter is worked out from what the
-- profile already says (the intro done, the first kit, the challenges won:
-- Solo.beaten) and from the story's own record (p.story: the Exam won once,
-- the finals won, the week of the last one, the scenes seen).
-- The words are the CM's (Shared/Banter.Story, by scene id); the lines here
-- stand in until he writes them. The screens are the DESIGN's (the journal in
-- Konoha's HUD: the player's attributes NinjaChapter, NinjaSeals,
-- NinjaStoryNext; the bubbles: Story.scene). Pure.
local Story={}

Story.Chapters={
	[0]={id="forest",name="THE FOREST",goal="Get through the forest"},
	[1]={id="invitation",name="THE INVITATION",goal="Choose your first inspiration"},
	[2]={id="seals",name="THE EIGHT SEALS",goal="Beat the Eight in the street"},
	[3]={id="exam",name="THE EXAM",goal="Win the exam's bracket"},
	[4]={id="final",name="THE FINAL",goal="Beat the Ōtsutsuki"},
	[5]={id="after",name="HE COMES BACK",goal="Beat him again this week"},
}
Story.LAST=5
-- The eight seals: the inspirations whose street challenge he won.
Story.SEALS=8
-- The Ōtsutsuki: his name on screen, the kit he fights with (a stand-in: his
-- own kit, a blow stolen from each of the eight and Minato's kunai, comes
-- with the ANIMATEUR's model), his AI, and where he waits (the exam hall: the
-- tournament is his).
Story.BOSS={
	name="THE ŌTSUTSUKI",sub="HOST OF THE TOURNAMENT",kit="Mirage",level="hard",
	-- his place: before the statue's hands at the end of the hall, facing the
	-- doors (HubMap relative, at the village's first scale: Story.spot)
	at=Vector3.new(0,0,-106),face=Vector3.new(0,0,-22),
	-- the duel's place: the hall's floor along its length, between the
	-- proctor (z -52) and him (Story.site)
	duel={key="Final",at=Vector3.new(0,0,-80),radius=22,place="THE EXAM HALL",axis=Vector3.zAxis,start=12,final=true},
	-- « plus fort » each week: his blows hit this much harder per final he
	-- lost, up to MAX
	stronger=.1,max=1.5,
	-- his words until the CM's (Banter.Otsutsuki: before, win, lose)
	before="Two rounds. Try not to bore me.",
	win="As expected. Come back next week.",
	lose="...So that's what the Eight saw in you.",
}

-- The scenes: when each one plays (the chapter he reaches, or a fight's end)
-- and its bubbles {who, line}. Banter.Story[id] replaces the lines.
Story.Scenes={
	invitation={chapter=1,lines={
		{who="ŌTSUTSUKI",line="Another nobody from the woods."},
		{who="ŌTSUTSUKI",line="Beat the Eight. Then maybe I'll look at you."},
		{who="THE EIGHT",line="Him? HA!"},
	}},
	seals={chapter=3,lines={
		{who="ŌTSUTSUKI",line="Eight seals. Cute."},
		{who="ŌTSUTSUKI",line="Win my exam and you get me."},
	}},
	exam={chapter=4,lines={
		{who="ŌTSUTSUKI",line="You won the exam. Finally, a toy."},
		{who="ŌTSUTSUKI",line="The hall. Now. Two rounds."},
	}},
	finalWon={chapter=5,lines={
		{who="ŌTSUTSUKI",line="...Interesting."},
		{who="ŌTSUTSUKI",line="Next week I won't hold back."},
	}},
	weekly={chapter=5,lines={
		{who="ŌTSUTSUKI",line="I'm back. Stronger. Were you waiting?"},
	}},
}

-- The scene each chapter opens with (chapter 5: the final won, once; then
-- the weekly one, each week he comes back).
Story.SceneOf={[1]="invitation",[3]="seals",[4]="exam",[5]="finalWon"}

-- (pure) The story's record in the profile: the Exam won once, the finals
-- won, the week of the last one, the scenes seen, the week the weekly scene
-- was seen.
function Story.new() return {exam=false,final=0,finalWeek="",seen={},weeklySeen=""} end
local function whole(n) return type(n)=="number" and n==math.floor(n) and n>=0 and n<=1e6 end
function Story.valid(r)
	if type(r)~="table" or type(r.exam)~="boolean" or not whole(r.final) or type(r.finalWeek)~="string" or #r.finalWeek>10 or type(r.seen)~="table"
		or (r.weeklySeen~=nil and (type(r.weeklySeen)~="string" or #r.weeklySeen>10)) then
		return false,"story record"
	end
	for id,v in r.seen do
		if type(id)~="string" or not Story.Scenes[id] or v~=true then return false,"story scene" end
	end
	return true
end

-- (pure) The facts the chapter is worked out from:
--   intro    he walked out of the forest (the profile's intro done)
--   starter  his first inspiration's kit, or nil
--   beaten   the inspirations whose challenge he won (kit -> true)
--   order    the eight's kits (KitTexts.Order)
--   record   the story's record (Story.new's shape), or nil
--   examWon  the Exam won this week (Exam.view's passed): counts as won
--   week     this week's key (Exam.current(t).key)
-- Returns {n, id, name, goal, seals, need, next={kind, kit}, scene, final}:
--   next.kind  "forest" | "inspiration" | "challenge" (next.kit: the first
--              of the eight not beaten) | "exam" | "final" | "weekly" | "free"
--   final      {open, won, level}: whether the Ōtsutsuki fights him now, how
--              many finals he won, the strength of the next one
--   scene      the scene of his chapter he has not seen, or nil
function Story.of(facts)
	facts=facts or {}
	local record=facts.record or Story.new()
	local order=facts.order or {}
	local seals,nextKit=0,nil
	for _,kit in order do
		if facts.beaten and facts.beaten[kit] then seals+=1 elseif not nextKit then nextKit=kit end
	end
	local need=math.min(Story.SEALS,#order)
	local examWon=record.exam==true or facts.examWon==true
	local won=record.final or 0
	local n,next_
	if facts.intro~=true then n,next_=0,{kind="forest"}
	elseif facts.starter==nil then n,next_=1,{kind="inspiration"}
	elseif seals<need then n,next_=2,{kind="challenge",kit=nextKit}
	elseif not examWon then n,next_=3,{kind="exam"}
	elseif won==0 then n,next_=4,{kind="final"}
	else
		n=5
		next_=if record.finalWeek~=(facts.week or "") then {kind="weekly"} else {kind="free"}
	end
	local open=n==4 or (n==5 and next_.kind=="weekly")
	local c=Story.Chapters[n]
	local out={n=n,id=c.id,name=c.name,goal=c.goal,seals=seals,need=need,next=next_,
		final={open=open,won=won,level=Story.strength(won)}}
	-- the scene of the chapter he reached, if not seen yet (the weekly one,
	-- each week he comes back)
	local id=Story.SceneOf[n]
	if id and not (record.seen and record.seen[id]) then out.scene=id
	elseif n==5 and next_.kind=="weekly" and (record.weeklySeen or "")~=(facts.week or "") then out.scene="weekly" end
	return out
end

-- (pure) Where he waits and where he faces, at the village's scale `scale`
-- (HubMap.Scale; relative to HubMap.Origin).
function Story.spot(scale)
	local k=scale or 1
	return Story.BOSS.at*k,Story.BOSS.face*k
end
-- (pure) The final's place at the village's scale: {key, at, radius, place,
-- axis, start, final} (relative to HubMap.Origin).
function Story.site(scale)
	local k=scale or 1
	local d=Story.BOSS.duel
	return {key=d.key,at=d.at*k,radius=d.radius*k,place=d.place,axis=d.axis,start=d.start*k,final=true}
end

-- (pure) How much harder the Ōtsutsuki hits after `won` finals lost to him.
function Story.strength(won)
	return math.min(Story.BOSS.max,1+Story.BOSS.stronger*math.max(0,won or 0))
end

-- (pure) The attribute the journal reads for the next target: "challenge:Lion",
-- "exam", "final"…
function Story.nextString(view)
	local nx=view and view.next
	if not nx then return "" end
	return if nx.kit then nx.kind..":"..nx.kit else nx.kind
end

-- (pure) A scene's bubbles: the CM's words (Banter.Story[id], a list of
-- {who, line}) when written, else the stand-ins.
function Story.lines(id,banter)
	local mine=banter and type(banter.Story)=="table" and banter.Story[id]
	if type(mine)=="table" and #mine>0 then return mine end
	local scene=Story.Scenes[id]
	return scene and scene.lines or {}
end

return Story
