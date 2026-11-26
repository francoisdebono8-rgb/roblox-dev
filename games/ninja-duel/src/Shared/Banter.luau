-- The CM's street words (passe commune 2, DEC-054, 26/11): the burlesque
-- humour of Konoha and the way in. « Chaude et vivante, avec un humour
-- burlesque : […] passants drôles » (François, 26/11). One table, so a word is
-- changed here once (tests/Banter.spec.luau). The CM owns this file (texts).
-- Who reads what (each one wires its own part):
--   Passersby   the villagers (ANIMATEUR, Client/KonohaFolkFX): a bubble when
--               the player passes, runs, walks on a wall, uses a jutsu near
--               them, or when the street watches a duel.
--   Merchants   the market stalls (ANIMATEUR): shouted now and then.
--   Bandit      the forest's bandit of the intro (DEV, the new start of
--               DEC-054): his block, his fight (hit, hurt, guarded, dodged),
--               his defeat, his win.
--   Thugs       the street racket (DEV, Server/Thugs): stop, threat, paid,
--               fight, lost, won. Thugs.LINE stays the racket's sign.
--   Inspirations  the eight in the street (DEV, Shared/Solo, Client/SoloView;
--               HubMoods): greet, idle, his win, his loss. In his own voice,
--               never a line from the anime.
--   Gate        the two guards of the great gate and its sign (DEV, ANIMATEUR).
--   Creation    the creation screen at the gate (DESIGN, DEC-054): title,
--               sections, buttons, the random button's quips.
--   Story       the Ōtsutsuki's tournament (STORY-001): each scene's bubbles
--               {who, line} (Shared/Story.lines, DEV; shown by the DESIGN).
--   Otsutsuki   his lines in the final: before, win, lose (Server/Matches).
--   Goal        Konoha's goal, top left (Shared/MastersView.goal, DEV).
--   Tournament  the tournament's name and the winner's title.
--   Ui          the interface's under-lines, rewritten in a player's words
--               (« les sous-textes font IA », 26/11), for the DESIGN to wire:
--               `was` is the line on screen at f28b8ba, `say` the new one.
-- A bubble line stays under 48 characters (a phone reads it at a glance).
local B={}

B.Passersby={
	idle={
		"Third ramen today. Don't judge me.",
		"My cat ran up a wall again. Ninja cat.",
		"Who keeps throwing kunai at my fruit?",
		"I'm not lost. I'm exploring. Slowly.",
		"These stairs weren't here yesterday.",
		"Rent's going up. Again.",
		"Someone stole my sandal. The left one.",
		"I sold three umbrellas. It's sunny.",
		"My grandma runs on walls. I can't.",
		"If you see a dog in sunglasses, he's mine.",
	},
	runPast={
		"Hey! Walk like a normal person!",
		"Was that a ninja or a very fast cat?",
		"My hat! You owe me a hat!",
		"No running in the market!",
		"Show-off.",
	},
	wallRun={
		"That's my wall! I just painted it!",
		"Use the stairs like everyone else!",
		"Mom! Someone's walking on the house again!",
	},
	jutsuNear={
		"Not near the vegetables!",
		"My eyebrows! Where are my eyebrows?",
		"Again? That's the fourth time today.",
		"I felt that in my teeth.",
	},
	watchDuel={
		"Ten Ryō on the short one!",
		"Kick him! No, the other one!",
		"Not my window! Not again!",
		"I've seen better. In my dreams.",
		"Somebody call a medic. Or a ramen guy.",
	},
	afterWin={
		"Not bad! For a beginner.",
		"I'm telling my cousin. He'll never buy it.",
	},
	afterLoss={
		"That's going to hurt tomorrow.",
		"Get up, kid. The street's watching.",
		"Maybe try the dummies first?",
	},
	clumsy={ -- a beginner's stumble (DEC-054: the clumsy first stage)
		"Careful, the ground is right there.",
		"Did he just trip on nothing?",
	},
}

B.Merchants={
	"Fresh dumplings! Almost fresh!",
	"Kunai! Sharp as my prices!",
	"Buy one for you, one for your rival!",
	"Headbands! Wear them, frame them, lose them!",
	"Sandals! Left AND right, this week only!",
}

B.Bandit={
	name="FOREST BANDIT",
	block={
		"Halt! This forest has a toll.",
		"The toll is everything you own.",
	},
	beforeFight="Hand it over, or I hand you this!",
	hurt={ -- he takes a blow
		"Ow! That was my good side!",
		"Hey! I wasn't ready!",
		"Okay, okay, not the face!",
	},
	hits={ -- he lands a blow
		"Ha! Welcome to the forest!",
		"Should've paid the toll!",
	},
	guarded="Stop blocking! It's rude!",
	dodged="Stand still! How do you DO that?",
	defeated={
		"Fine! Take the road! It's a dumb road anyway!",
		"I'm telling my boss. I don't have a boss.",
	},
	won="Come back when you've had breakfast!",
	leaves="The village is that way. Don't say I sent you.",
}

B.Thugs={
	stop={
		"Whoa, whoa. Street tax. Pay up.",
		"Nice pouch. Heavy? Let me check.",
	},
	threat="Your Ryō or a fight. Pick Ryō.",
	paid="Pleasure doing business! Come again!",
	fight="Oh, a brave one. I hate brave ones.",
	lost={
		"This never happened. Got it?",
		"My mom's calling me. Bye!",
	},
	won="Thanks for the donation!",
}

-- Keys are Shared/KitTexts.Order.
B.Inspirations={
	Legion={
		greet="New guy! I'll be the strongest. Write it down!",
		idle="The ramen place is always open. Right? RIGHT?",
		win="Ha! Told you! I'll sign your forehead later!",
		lose="That doesn't count! My sandal was untied!",
	},
	Lion={
		greet="Don't talk to me.",
		idle="I'm not brooding. I'm thinking angrily.",
		win="Predictable.",
		lose="...Lucky. Once.",
	},
	Leaf={
		greet="Morning! I already did four hundred push-ups!",
		idle="If that bird beats me home, five hundred squats!",
		win="Good match! Now we run laps together!",
		lose="Amazing! I'll train twice as hard! Starting now!",
	},
	GentleFist={
		greet="Your stance is wrong. All of it.",
		idle="I can see through walls. Mostly people eating.",
		win="It was written. I wrote it this morning.",
		lose="That was not in the plan.",
	},
	Sand={
		greet="...",
		idle="I don't sleep. I just stand here. It's fine.",
		win="Sand everywhere. Sorry. Not sorry.",
		lose="You touched me. Once. ...We'll talk.",
	},
	Copycat={
		greet="Nice move. Mine now.",
		idle="I'm not late. Everyone else is early.",
		win="Learned that one from you. Thanks.",
		lose="Okay, that one I can't copy. Yet.",
	},
	Mirage={
		greet="One duel. Then I have errands.",
		idle="If my little brother asks, I wasn't here.",
		win="It was over before you blinked.",
		lose="Interesting. Truly.",
	},
	Flashstep={
		greet="Hi! Bye! Hi again!",
		idle="Ever been in two places at once? Tiring.",
		win="Sorry, I was already behind you.",
		lose="You saw that? Nobody sees that.",
	},
}

B.Gate={
	sign="KONOHA. NO RUNNING. (NOBODY LISTENS.)",
	guards={
		"Name? ...Never mind. Go in.",
		"Welcome to Konoha! Wipe your sandals.",
		"From the forest? Did the bandit cry again?",
		"Another hero. Third one today.",
	},
}

B.Creation={
	title="WHO ARE YOU?",
	sub="The guards want a face. Pick an outfit too.",
	sections={outfit="OUTFIT",hair="HAIR",colour="COLOUR",headband="HEADBAND"},
	random="RANDOM",
	confirm="THAT'S ME",
	enter="ENTER KONOHA",
	quips={ -- one under the avatar after each RANDOM
		"Bold. Very bold.",
		"Your mom would love it.",
		"Too much? Never too much.",
		"Looking sharp. Mostly.",
		"The guards are pretending not to laugh.",
	},
}

-- (26/11, passe 3, DEC-055, STORY-001) The Ōtsutsuki's tournament: the
-- scenes' bubbles {who, line}, read by Shared/Story.lines(id, Banter) (DEV),
-- shown by the DESIGN. The Ōtsutsuki is François's own, the host of the
-- devlogs: a bored god, a little strange, a villain's calm, plain words. The
-- Eight answer him in their own voice (their titles: Shared/KitTexts).
local O="THE ŌTSUTSUKI"
B.Story={
	invitation={ -- at the gate, the forest just behind him
		{who=O,line="Hm. The forest let one through."},
		{who=O,line="I am the Ōtsutsuki. This tournament is mine."},
		{who=O,line="Beat the Eight. Bring me their seals."},
		{who="THE LOUDMOUTH",line="HIM? He can't even tie his headband!"},
		{who=O,line="Pick a teacher. Try not to embarrass them."},
	},
	seals={ -- the eighth seal won: the exam opens
		{who=O,line="Eight seals. I felt every single one."},
		{who=O,line="Now my exam. Win the whole bracket."},
		{who="THE HARD WORKER",line="Go! I'll cheer! VERY loudly!"},
	},
	exam={ -- the exam's bracket won: the final opens
		{who=O,line="The whole bracket. Not bad, little one."},
		{who=O,line="Come to the hall. I'll be gentle."},
		{who=O,line="...No, I won't."},
	},
	finalWon={ -- the Ōtsutsuki beaten, the first time
		{who=O,line="...You hit a god. In the face."},
		{who="THE LOUDMOUTH",line="I SAW THAT! I'm telling EVERYONE!"},
		{who=O,line="Enjoy it. Next week, I come back stronger."},
	},
	weekly={ -- each week he comes back
		{who=O,line="A week is long for a god. I got bored."},
		{who=O,line="I'm stronger now. The hall. Come."},
	},
}
-- His lines in the final (Server/Matches: one of each list, at random).
B.Otsutsuki={
	before={
		"Two rounds. Entertain me.",
		"Show me what the Eight taught you.",
		"Bow first. Then lose.",
	},
	win={ -- he wins
		"As expected. Come back next week.",
		"That was it? Train. Then come back.",
		"Cute. Truly cute.",
	},
	lose={ -- he loses
		"...So that's what the Eight saw in you.",
		"Impossible. Again. Right now.",
		"Fine. You win today. Only today.",
	},
}
-- Konoha's goal, top left (Shared/MastersView.goal, DEV): the head says what
-- to do, the line under it where. `seals` takes the seals won and needed
-- (%d / %d), `exam` the proctor's place (%s).
B.Goal={
	seals={head="BEAT THE EIGHT  •  %d / %d",sub="THEY DARE YOU IN THE STREETS"},
	exam={head="WIN THE EXAM",sub="SEE THE PROCTOR  •  %s"},
	final={head="FIGHT THE ŌTSUTSUKI",sub="HE WAITS IN THE EXAM HALL"},
	weekly={head="HE'S BACK. STRONGER.",sub="HE WAITS IN THE EXAM HALL"},
}
-- The tournament's name and the title of whoever beats him (passe commune 3:
-- the journal, the VS card, the series' season 1). Not read yet: the DEV or
-- the DESIGN picks them up where the name shows.
B.Tournament={name="THE ŌTSUTSUKI TOURNAMENT",winner="GOD PUNCHER"}

-- The interface's under-lines, for the DESIGN (file:line at f28b8ba). The
-- DESIGN's d875b0b (26/11) already rewrote the shop, MY NINJA, the result,
-- the map and the settings in a player's words: those are kept as they are,
-- and only the lines still on screen at d875b0b are here.
-- A player's words: what it is or what to do, short; nothing about rules.
B.Ui={
	cupChampion={at="Client/CupScreen.luau:12",
		was="Eight prodigies entered the arena. One walks out with the tournament.",say="Eight came in. You walk out."},
	cupOut={at="Client/CupScreen.luau:214",
		was="Even prodigies lose. Learn the opening you missed, then come back to the arena.",say="Out this time. Come back sharper."},
	boardDuels={at="Client/Leaderboard.luau:108,143",
		was="No duel counted yet. Every duel between two players counts.",say="No duels yet. Be the first."},
	boardKit={at="Client/Leaderboard.luau:143",
		was="No mastery counted yet. Play this kit to be the first.",say="Nobody yet. Play this kit."},
	boardRace={at="Client/Leaderboard.luau:143",
		was="No race run yet. The rooftop race starts at the gate.",say="No times yet. The race starts at the gate."},
	lobbyEmpty={at="Client/LobbyPanel.luau:74",
		was="Nobody else is online right now. Train against the AI — the list refreshes by itself.",say="Nobody online. Duel the AI while you wait."},
	questsWait={at="Client/QuestPanel.luau:83",was="The day's quests arrive with your profile.",say="Loading today's quests…"},
	shopSoon={at="Client/ShopPanel.luau:584",was="Ryō packs show SOON until they are on sale.",say="Coming soon."},
	treeFoot={at="Client/TreePanel.luau:219",
		was="A learned node stays learned: turn nodes on and off between duels. Ranked and tournament duels give everyone the prodigy's whole kit, on an equal budget.",
		say="Switch nodes between duels. In ranked, everyone has the full kit."},
	queueTravel={at="Client/UI.luau:1370",was="Both of you are on the way to the same arena…",say="Heading to the arena…"},
	queueWait={at="Client/UI.luau:1370",was="Waiting for your opponent to arrive…",say="Waiting for your opponent…"},
	queueCasual={at="Client/UI.luau:1364",was="Casual 1v1  •  you meet the next player who searches.",say="Casual 1v1"},
	resultMasterWon={at="Client/UI.luau:1921",was="He saw enough: his kit is yours.",say="His kit is yours!"},
	resultMasterLost={at="Client/UI.luau:1921",was="He is not convinced yet. Come back stronger.",say="Not yet. Come back stronger."},
	resultLeft={at="Client/UI.luau:1929",was="Your opponent left the duel. The win is yours.",say="They ran. You win."},
	cupNext={at="Client/UI.luau:1941,1943",was="Your name moves up the bracket.",say="You're through!"},
	cupEnds={at="Client/UI.luau:1945",was="Your tournament ends here. The bracket plays out without you.",say="Out of the tournament."},
	kitsLoading={at="Shared/MastersView.luau:65",was="Your ninja's kits are on their way.",say="Loading…"},
}

-- One line of a list, never the same twice in a row (`last` = the previous
-- one). `rng` is a Random (tests pass a seeded one).
function B.pick(list,last,rng)
	if type(list)~="table" then return list end
	if #list==0 then return nil end
	if #list==1 then return list[1] end
	local r=rng or Random.new()
	local line=list[r:NextInteger(1,#list)]
	while line==last do line=list[r:NextInteger(1,#list)] end
	return line
end

return B
