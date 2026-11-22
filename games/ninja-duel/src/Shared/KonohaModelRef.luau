--!strict
-- GENERATED from tools/blender/konoha_houses.py and konoha_landmarks.py (their REF): do not edit by hand.
-- (21/11, étape 3 ANIMATEUR) The size each Konoha model is built at (base studs, before HubMap.Scale):
-- w along the model's X, d along its Z (the door at +Z), h its wall top. A lot of the plan of another
-- size can scale the model to it (Server/Hub: DressScale = (w_lot/w, 1, d_lot/d), the DEV's call).
return {
	small_house={w=14,d=14,h=7},
	machiya={w=17,d=17,h=14},
	tank_house={w=17,d=16,h=21},
	shop_house={w=20,d=16,h=14},
	apartment={w=24,d=16,h=21},
	clan_house={w=22,d=17,h=9},
	hokage_residence={w=44,d=44,h=40},
	hospital={w=36,d=30,h=24},
	academy_annex={w=36,d=30,h=24},
	exam_hall={w=90,d=12,h=26},
	exam_hall_wing={w=8,d=42,h=18},
	ichiraku={w=16,d=12,h=9},
	great_gate={w=48,d=8,h=50},
	hyuga_hall={w=60,d=22,h=14},
	hyuga_gate={w=8,d=20,h=10},
	uchiha_police={w=24,d=18,h=16},
	naka_shrine={w=26,d=22,h=16},
	torii={w=4,d=18,h=15},
	pier={w=18,d=12,h=2},
	water_tower={w=16,d=16,h=34},
	market_hall={w=26,d=14,h=12},
	memorial_stone={w=4,d=2,h=6},
	academy_tree={w=6,d=6,h=18},
	training_dummy={w=3,d=3,h=7},
	kunai_target={w=4,d=2,h=6},
	stump_target={w=3,d=3,h=3},
}
