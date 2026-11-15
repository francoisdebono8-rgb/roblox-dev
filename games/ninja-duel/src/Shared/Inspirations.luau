-- (DEC-041, user 14/11 21 h 35: « le choix du premier maître, qu'on va plutôt
-- appeler modèle ou inspiration, parce qu'ils ont 13-14 ans, c'est pas des
-- sensei. Moi, j'imaginais plus un choix comme un choix de starter. Et on
-- donne […] un peu des traits humoristiques ») The three first inspirations,
-- picked like a starter: who he is, in one funny line, and what fighting like
-- him means. Shown on his card when the player meets him (Client/HubClient),
-- the three together by the gate (HubMap.Welcome).
local I={}
I.Lines={
	Legion={title="THE LOUDMOUTH",
		line="Loud, reckless and not the sharpest kunai in the pouch. He never gives up, mostly because he never notices he is losing.",
		with="With him: shadow clones, ramen and shouting your attacks."},
	Lion={title="THE AVENGER",
		line="Brooding genius with a grudge against the whole world. Never smiles. Trains out of pure spite.",
		with="With him: fire, lightning and a lot of hate."},
	Leaf={title="THE HARD WORKER",
		line="Cannot do a single jutsu, so he runs five hundred laps before breakfast. The most motivated boy in Konoha.",
		with="With him: pure taijutsu, ankle weights and the springtime of youth!"},
}
function I.of(id) return I.Lines[id] end
return I
