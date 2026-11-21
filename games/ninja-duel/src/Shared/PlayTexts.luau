-- The CM's words for playing (step 3, DEC-047, 21/11): the first combat's
-- prompts, the things to do alone in Konoha, the titles a player earns.
-- One table, so a word is changed here once (tests/PlayTexts.spec.luau).
-- The CM owns this file (texts); who reads what:
--   Coach       Server/Coach (the prompt's title, the tick of success) and
--               Shared/FirstMinute.Touch (what a phone player presses).
--               {jutsu} and {tool} are filled by T.coachTitle.
--   FirstWin    the first combat's result (the DESIGN's screen).
--   Activities  the things to do alone (DEV task 4, the DESIGN's map and
--               markers): name, a line, the button. {title} is an
--               inspiration's title (Shared/KitTexts).
--   Titles      earned, never sold (« des cosmétiques gagnés par le
--               mérite », 20/11): the title, how it is earned (one line the
--               player reads) and the DEV's `earned` rule (Shared/
--               CatalogStyle). Under the name in Konoha and on the result
--               screen (the DESIGN, task 4).
-- Words from the anime stay out of titles (DEC-043); kit titles come from
-- Shared/KitTexts.
local KitTexts=require(script.Parent.KitTexts)
local T={}

-- The first combat: a prompt says the situation, then the order. Short: it
-- is read in the middle of a fight. The key comes from Server/Coach.
T.Coach={
	move={title="Go get him",done="NICE",touch="Drag on the left of the screen"},
	strike={title="He's open: hit him",done="NICE COMBO",touch="Tap ATTACK three times"},
	guard={title="He's attacking: guard",done="BLOCKED",touch="Hold GUARD"},
	escape={title="Caught! Dodge out",done="ESCAPED",touch="Tap DODGE as his blow lands"},
	grab={title="He's guarding: grab him",done="GOT HIM",touch="Tap GRAB"},
	tool={title="Too far? Throw your {tool}",done="NICE THROW",touch="Tap TOOL"},
	signature={title="Chakra ready: {jutsu}!",done="SIGNATURE!",touch="Tap your jutsu button"},
}
-- The prompt's title, its {jutsu} / {tool} filled.
function T.coachTitle(id,fill)
	local entry=T.Coach[id]
	if not entry then return nil end
	return (string.gsub(entry.title,"{(%w+)}",function(key) return tostring((fill or {})[key] or key) end))
end
-- The tick when a prompt is done ("NICE" when unknown).
function T.coachDone(id)
	local entry=T.Coach[id]
	return entry and entry.done or "NICE"
end

-- The first combat won.
T.FirstWin={head="FIRST WIN!",line="You've got the basics. Konoha is all yours."}

-- The things to do alone. Each pays mastery (DEC-047).
T.Activities={
	Dummies={name="TRAINING DUMMIES",where="Training Ground 3",
		line="Try every move of your kit and your nature. They never get tired.",cta="TRAIN"},
	RoofRace={name="ROOFTOP RACE",where="From the gate to the cliff",
		line="Over the roofs, against the clock. Then against everyone on the board.",cta="RACE"},
	Targets={name="KUNAI TARGETS",where="The training grounds",
		line="Targets pop out of the walls. Hit them before they hide again.",cta="THROW"},
	Challenge={name="{title}'S CHALLENGE",where="In the street",
		line="{title} is waiting for you. Win his challenge to earn his respect.",cta="ACCEPT"},
	Duel={name="DUEL THE AI",where="Anywhere",
		line="A short duel against the AI, right where you stand.",cta="DUEL"},
	StreetDuel={name="STREET DUEL",where="Anywhere",
		line="Challenge the nearest player. Nobody else can join: the street watches.",cta="CHALLENGE"},
}
-- An activity's name and line, {title} filled with an inspiration's title.
function T.activity(id,kitId)
	local a=T.Activities[id]
	if not a then return nil end
	local title=if kitId then KitTexts.name(kitId) else "AN INSPIRATION"
	local function fill(s) return (string.gsub(s,"{title}",title)) end
	return {name=fill(a.name),where=a.where,line=fill(a.line),cta=a.cta}
end
T.MasteryLine="+%d MASTERY"

-- The titles to earn, in the order of the list a player browses. Ids and
-- `earned` rules are those of the DEV's Shared/CatalogStyle (slot "title",
-- Style.met) for the ten already there; `new` marks a rule the DEV still has
-- to count (a proposal: he keeps or drops it). The exam's two come from
-- Shared/Exam (Server/WeeklyExam), not from the shop.
T.Titles={
	{id="TitleGraduate",title="ACADEMY GRADUATE",earned="wins1",how="Win your first duel."},
	{id="TitleStreet",title="STREET RIVAL",earned="pvp10",how="Win 10 duels against players."},
	{id="TitleStreetLegend",title="STREET LEGEND",earned="pvp50",new=true,how="Win 50 duels against players."},
	{id="TitleHundred",title="HUNDRED VICTORIES",earned="wins100",how="Win 100 duels."},
	{id="TitleGenin",title="THE GENIN",earned="rank2",how="Reach GENIN in ranked."},
	{id="TitleChunin",title="THE CHUNIN",earned="rank3",how="Reach CHUNIN in ranked."},
	{id="TitleJonin",title="THE JONIN",earned="rank4",how="Reach JONIN in ranked."},
	{id="TitleAnbu",title="ANBU",earned="rank5",how="Reach ANBU in ranked."},
	{id="TitleKage",title="THE KAGE",earned="rank6",how="Reach KAGE in ranked."},
	{id="TitleUnbeaten",title="UNBEATEN",earned="pvpStreak10",new=true,how="Win 10 duels against players in a row."},
	{id="TitleGiantSlayer",title="GIANT SLAYER",earned="giant2",new=true,how="Beat a player two ranks above yours."},
	{id="TitleComeback",title="COMEBACK KID",earned="comeback",new=true,how="Win a round with less than a tenth of your health."},
	{id="TitleUntouched",title="UNTOUCHED",earned="untouched",new=true,how="Win a round without taking a single hit."},
	{id="ExamPassed",title="EXAM PASSED",earned="exam",how="Win the final of the week's Rank Exam. Yours until the next one opens."},
	{id="ExamTop3",title="TOP 3 OF THE WEEK",earned="exam",how="Finish in the Rank Exam's best three. Yours for a week."},
	{id="TitleRooftops",title="ROOFTOP RUNNER",earned="rooftops",how="Finish the rooftop race."},
	{id="TitleFastest",title="FASTEST IN KONOHA",earned="rooftopsTop1",new=true,how="Hold the best rooftop race time of the week."},
	{id="TitleDeadEye",title="DEAD EYE",earned="targetsAll",new=true,how="Hit every kunai target in one run."},
	{id="TitleNeverSkips",title="NEVER SKIPS TRAINING",earned="dummies7",new=true,how="Train on the dummies 7 days in a row."},
	{id="TitleStudentOfEight",title="STUDENT OF THE EIGHT",earned="challenges8",new=true,how="Win the challenge of all eight inspirations."},
	{id="TitleEightWays",title="EIGHT WAYS",earned="kits300",new=true,how="Reach 300 mastery with all eight kits."},
	{id="TitleFireBorn",title="FIRE BORN",earned="natureFire25",nature="Fire",new=true,how="Win 25 duels with Element Mastery and the fire nature."},
	{id="TitleWindRider",title="WIND RIDER",earned="natureWind25",nature="Wind",new=true,how="Win 25 duels with Element Mastery and the wind nature."},
	{id="TitleStormCaller",title="STORM CALLER",earned="natureLightning25",nature="Lightning",new=true,how="Win 25 duels with Element Mastery and the lightning nature."},
	{id="TitleStoneWall",title="STONE WALL",earned="natureEarth25",nature="Earth",new=true,how="Win 25 duels with Element Mastery and the earth nature."},
	{id="TitleTideBreaker",title="TIDE BREAKER",earned="natureWater25",nature="Water",new=true,how="Win 25 duels with Element Mastery and the water nature."},
	{id="TitleSevenDays",title="SEVEN DAYS STRONG",earned="days7",how="Play 7 days in a row."},
	{id="TitleEveryDay",title="NEVER MISSES A DAY",earned="days30",new=true,how="Play 30 days in a row."},
}
-- One heir title per prodigy: 800 mastery with his kit, the top tier of his tree.
for _,kitId in KitTexts.Order do
	table.insert(T.Titles,{id="TitleHeir"..kitId,title=KitTexts.name(kitId).."'S HEIR",earned="heir"..kitId,kit=kitId,new=true,
		how="Reach 800 mastery with "..KitTexts.name(kitId).."."})
end
T.ById={}
for _,t in T.Titles do T.ById[t.id]=t end

return T
