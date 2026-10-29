-- Bangla three-strike M1 foundation; air/grab/launch branches are Ninja Duel glue.
local Combo=require(script.Parent.BanglaCombo)
local function move(startup,active,recovery,damage,travel,reaction,impulse,stun)
 return {startup=startup,active=active,recovery=recovery,damage=damage,travel=travel,
  travelTime=startup+active,reaction=reaction or "HitStun",impulse=impulse or Vector3.new(0,0,10),stun=stun or 0.27,
  range=7.8,width=5.5,height=6,blockable=true,
  -- Contact distance (root to root) where the step-in stops: an arm's length
  -- for hand strikes. Closer, the two bodies visibly merge mid-string
  -- (Studio 28/10: at 3.6 the client showed 3.3-4.0, torsos overlapping).
  contact=4.1}
end
local attacks={
 Light1=move(.09,.12,Combo.comboDelay-.22,Combo.Damage.Punch,3.2),
 Light2=move(.10,.12,Combo.comboDelay-.23,Combo.Damage.HardSmack,3.5),
 Light3=move(.12,.14,Combo.comboDelay-.26,Combo.Damage.MegaPunch,4.2,"Knockback",Vector3.new(0,14,50),.48),
 -- (Stage 6) The longer strings: 4 hits for everyone (5 for Lee and Naruto),
 -- the last one (Light3) throws. The middle hits play the fighter's first and
 -- second clips again until they get their own (clip).
 Light4=move(.09,.12,Combo.comboDelay-.22,Combo.Damage.Punch,3.2),
 Light5=move(.10,.12,Combo.comboDelay-.23,Combo.Damage.Punch,3.4),
 Heavy=move(.30,.17,.52,14,5.4,"Knockdown",Vector3.new(0,12,34),.68),
 Launcher=move(.17,.14,.28,8,3.2,"Launched",Vector3.new(0,58,13),1.18),
 DashAttack=move(.07,.15,.27,7,8.2,"HitStun",Vector3.new(0,3,13),.31),
 Air1=move(.08,.13,.18,6,2.8,"Juggled",Vector3.new(0,15,8),.62),
 Air2=move(.09,.14,.19,7,3.1,"Juggled",Vector3.new(0,10,12),.64),
 Slam=move(.15,.20,.38,11,2.8,"Knockdown",Vector3.new(0,-78,10),.86),
 Grab=move(.18,.14,.5,0,2,"Grabbed",Vector3.zero,.8),
 Throw=move(.12,.1,.34,10,0,"Knockdown",Vector3.new(0,18,48),.7),
 ThrowUp=move(.12,.1,.3,7,0,"Launched",Vector3.new(0,50,10),1.1),
 -- Character branches (directional input inside a confirmed string).
 -- Minato: a sidestep cut that swings him around the opponent's guard.
 AngleStep=move(.08,.1,.2,6,1.2,"HitStun",Vector3.new(0,0,9),.3),
 -- Itachi: a low spinning sweep that trades the string for a knockdown,
 -- and the palm that answers a successful Read.
 Sweep=move(.12,.14,.34,7,1.6,"Knockdown",Vector3.new(0,6,12),.62),
 CounterPalm=move(.05,.12,.3,10,2.6,"Knockback",Vector3.new(0,14,46),.5),
 -- From a wall run: a diving strike at the opponent (active window sized to the flight).
 WallDive=move(.1,.3,.32,9,0,"Knockdown",Vector3.new(0,10,30),.62),
 -- Neji: twin palms driven from the hips (heavy after one clean palm, or the
 -- counter after Rotation).
 PalmThrust=move(.11,.14,.34,10,3.4,"Knockback",Vector3.new(0,12,62),.52),
 -- Minato: a knee driven up into the body after one clean cut. The opponent is
 -- popped to waist height: continue on the ground, jump after it, or chase.
 KneeStrike=move(.08,.12,.3,7,2.6,"Juggled",Vector3.new(0,26,4),.62),
 -- Running taijutsu: out of a full sprint, a flying kick (strike) and a
 -- sliding sweep (heavy). The run is the wind-up; a whiff overshoots.
 FlyingKick=move(.1,.16,.32,9,10,"Knockback",Vector3.new(0,14,48),.5),
 -- Riposte: out of a clean block or a perfect dodge, an instant strike that
 -- opens the string (block -> riposte -> combo).
 Riposte=move(.05,.12,.26,8,2.6,"HitStun",Vector3.new(0,5,12),.36),
 -- Gaara: sand erupts under the opponent at range and throws them up.
 SandPillar=move(.27,.14,.5,9,0,"Launched",Vector3.new(0,54,4),1.1),
 -- (Stage 6) Gaara's heavy no longer launches: a hand of sand seizes the body
 -- at range and slams it down; after one lash, the sand fist drives it away.
 SandHand=move(.24,.16,.48,10,0,"Knockdown",Vector3.new(0,-24,-14),.8),
 SandFist=move(.18,.14,.4,11,0,"Knockback",Vector3.new(0,10,64),.52),
 -- (Stage 6) Gaara's own routes: away, a low wave of sand along the floor;
 -- sideways, a glide on the sand that strikes while it slips aside.
 SandLowWave=move(.16,.16,.4,7,0,"Knockdown",Vector3.new(0,6,16),.62),
 SandGlide=move(.12,.12,.26,6,0,"HitStun",Vector3.new(0,3,8),.34),
 SlideSweep=move(.12,.18,.38,8,11,"Knockdown",Vector3.new(0,8,18),.62),
 -- Lateral routes: Itachi's feint step (an afterimage stays, he reappears at
 -- the flank) and Neji's circular step onto a chakra point. Both keep the string.
 FeintStep=move(.1,.12,.22,6,0,"HitStun",Vector3.new(0,4,9),.34),
 CircleStep=move(.09,.12,.22,6,0,"HitStun",Vector3.new(0,3,8),.34),
 -- Air routes after an air hit: drive the body away (toward a wall), spike it
 -- into the floor (it bounces once), or vault to its other side.
 AirDrive=move(.08,.13,.22,7,3,"Knockback",Vector3.new(0,8,48),.5),
 AirSpike=move(.09,.12,.24,7,2,"Spiked",Vector3.new(0,-72,6),.9),
 AirSwitch=move(.1,.14,.2,6,0,"Juggled",Vector3.new(0,13,9),.6),
 -- (User 28/10) Jump + heavy: a small front salto into a heel kick that
 -- sends the body away. Not a safe plunge: a long recovery that lands open.
 AirFlip=move(.17,.13,.38,11,2.4,"Knockback",Vector3.new(0,16,56),.55),
 -- Sasuke: an acrobatic rising kick he follows into the air, a vault over the
 -- opponent into a back kick, and the Chidori thrust (started by the jutsu).
 LionKick=move(.15,.14,.28,8,3,"Launched",Vector3.new(0,50,5),1.25),
 VaultKick=move(.12,.12,.24,7,0,"HitStun",Vector3.new(0,6,12),.36),
 ChidoriThrust=move(.04,.26,.62,22,15,"Knockback",Vector3.new(0,12,70),.7),
 -- Rock Lee (stress-test wave): the Leaf Rising Wind (a straight-leg kick out
 -- of a crouch, followed into the air), the Leaf Hurricane (a low spinning kick
 -- that keeps the string), the Leaf Whirlwind (a wide spinning kick that catches
 -- a side step), the Leaf Great Whirlwind (his technique: a spinning kick across
 -- the gap) and the deflecting crescent kick (his tool: no blade). Shapes and
 -- tags at the end of this file.
 LeafRising=move(.13,.14,.28,8,3.2,"Launched",Vector3.new(0,56,6),1.2),
 LeafHurricane=move(.11,.16,.24,6,1.8,"Juggled",Vector3.new(0,16,7),.55),
 LeafWhirlwind=move(.12,.16,.24,7,1.4,"HitStun",Vector3.new(0,5,14),.38),
 GreatWhirlwind=move(.06,.24,.36,9,14,"Knockback",Vector3.new(0,16,54),.55),
 DeflectKick=move(.05,.18,.3,4,0,"HitStun",Vector3.new(0,4,10),.3),
 -- Temari (roster wave): the iron fan. The Updraft scoops the body into
 -- rising air (Gale.updraft holds it there), the Fan Slam brings the closed fan
 -- down, the Fan Pirouette throws the body aside (lateral), the backhand pushes
 -- away, the Fan Dive blows a body in the air down into the floor. Shapes and
 -- tags at the end of this file.
 Updraft=move(.15,.15,.3,8,1.5,"Launched",Vector3.new(0,46,3),1.25),
 FanSlam=move(.16,.14,.36,9,1.4,"Knockdown",Vector3.new(0,6,12),.7),
 FanPirouette=move(.12,.18,.3,7,.8,"Knockback",Vector3.new(0,8,34),.42),
 FanBackhand=move(.1,.14,.32,9,1.6,"Knockback",Vector3.new(0,12,52),.5),
 FanDive=move(.1,.14,.26,7,1.5,"Spiked",Vector3.new(0,-70,4),.9),
}
-- Reach of the body that lands each strike (see `contact` in move()).
for name,gap in {Light3=4.3,Heavy=4.2,FlyingKick=4.2,PalmThrust=3.7,CounterPalm=3.7,KneeStrike=3.2,Sweep=3.5,Grab=2.6,Throw=2.6,ThrowUp=2.6,Slam=3.0,WallDive=2.6} do
 if attacks[name] then attacks[name].contact=gap end
end

for name,spec in attacks do
 if not Combo.Actions[name] then spec.depth=spec.range*.8;spec.offset=spec.range*.4
 else
  -- The string's donor volume (1 to 3 studs ahead) stopped short of the
  -- contact distance: it now reaches a quarter stud past it.
  spec.depth=spec.contact+.25-1;spec.offset=(1+spec.contact+.25)/2
 end
 spec.animation=name;spec.feedback=spec.reaction;spec.chain=name=="Light1" or name=="Light2" or name=="Light4" or name=="Light5" or name=="Air1" or name=="Air2" or name=="DashAttack" or name=="AngleStep" or name=="Riposte"
  or name=="FeintStep" or name=="CircleStep" or name=="AirSwitch" or name=="VaultKick"
 spec.air=name=="Air1" or name=="Air2" or name=="AirDrive" or name=="AirSpike" or name=="AirSwitch" or name=="AirFlip"
end
-- Hitstop is not authored per move any more: weight comes from Combat.Hitstop so
-- a light jab cannot be given a heavy stop by accident.
local motion={
 Light1={side=1,twist=30,lean=8,arm=82,step=1.05},
 Light2={side=-1,twist=34,lean=10,arm=88,step=1.08},
 Light3={side=1,twist=72,lean=12,arm=102,step=1.2},
 Light4={side=1,twist=30,lean=8,arm=82,step=1.05},
 Light5={side=-1,twist=34,lean=10,arm=88,step=1.08},
 Heavy={side=-1,twist=48,lean=25,arm=116,step=1.3},
 Launcher={side=1,twist=20,lean=-24,arm=112,step=1.15},
 DashAttack={side=1,twist=36,lean=28,arm=96,step=1.35},
 Air1={side=1,twist=38,lean=12,arm=98,step=1.1},
 Air2={side=-1,twist=44,lean=18,arm=104,step=1.15},
 Slam={side=1,twist=12,lean=46,arm=128,step=1.2},
 Grab={side=1,twist=10,lean=18,arm=72,step=1.05},
 Throw={side=1,twist=70,lean=22,arm=92,step=1.1},
 ThrowUp={side=-1,twist=28,lean=-30,arm=110,step=1.1},
 AngleStep={side=1,twist=40,lean=10,arm=90,step=1.1},
 Sweep={side=-1,twist=60,lean=20,arm=60,step=1.0},
 CounterPalm={side=1,twist=30,lean=16,arm=100,step=1.2},
 WallDive={side=1,twist=24,lean=42,arm=80,step=1.2},
 PalmThrust={side=1,twist=20,lean=18,arm=100,step=1.25},
 KneeStrike={side=1,twist=16,lean=14,arm=70,step=1.15},
 FlyingKick={side=1,twist=10,lean=-12,arm=60,step=1.3},
 Riposte={side=1,twist=24,lean=12,arm=92,step=1.2},
 SandPillar={side=1,twist=10,lean=-6,arm=120,step=1},
 SlideSweep={side=1,twist=14,lean=-20,arm=40,step=1.3},
 FeintStep={side=-1,twist=30,lean=10,arm=90,step=1.1},
 CircleStep={side=1,twist=40,lean=8,arm=90,step=1.05},
 AirDrive={side=1,twist=20,lean=-10,arm=60,step=1},
 AirSpike={side=1,twist=10,lean=40,arm=120,step=1},
 AirSwitch={side=-1,twist=60,lean=10,arm=80,step=1},
 AirFlip={side=1,twist=20,lean=-20,arm=60,step=1},
 LionKick={side=1,twist=10,lean=-30,arm=100,step=1.15},
 VaultKick={side=-1,twist=70,lean=10,arm=60,step=1.1},
 ChidoriThrust={side=1,twist=20,lean=30,arm=110,step=1.4},
}
for name,pose in motion do for key,value in pose do attacks[name][key]=value end end
for _,name in {"Light1","Light2","Light3"} do attacks[name].width=5;attacks[name].height=5;attacks[name].range=6 end
attacks.AngleStep.width=5;attacks.AngleStep.range=6.5;attacks.AngleStep.orbit=17
attacks.Sweep.height=3.5;attacks.Sweep.width=6.5;attacks.Sweep.range=6.5
attacks.WallDive.width=6;attacks.WallDive.height=8;attacks.WallDive.range=7.5;attacks.WallDive.facing=-.45
attacks.FlyingKick.range=7.5;attacks.FlyingKick.width=5.5
attacks.SandPillar.range=12.5;attacks.SandPillar.width=6;attacks.SandPillar.height=8;attacks.SandPillar.depth=11;attacks.SandPillar.offset=6;attacks.SandPillar.facing=.25
attacks.SlideSweep.range=7.5;attacks.SlideSweep.height=3.5;attacks.SlideSweep.width=6.5
attacks.FeintStep.width=5;attacks.FeintStep.range=6.5;attacks.FeintStep.orbit=34
attacks.CircleStep.width=5;attacks.CircleStep.range=6;attacks.CircleStep.orbit=28
attacks.AirSwitch.orbit=40;attacks.AirSwitch.width=6;attacks.AirSwitch.height=7
attacks.AirSpike.height=7;attacks.AirDrive.height=7
attacks.VaultKick.width=5.5;attacks.VaultKick.range=6.5;attacks.VaultKick.orbit=50
attacks.ChidoriThrust.range=7;attacks.ChidoriThrust.width=4.5
-- Where a strike lands and what it is: the victim's body answers the blow it
-- actually took (head snaps, body folds, legs are taken away, ...).
local ZONE={Light1="head",Light2="body",Light3="body",Light4="body",Light5="head",Heavy="body",Launcher="chin",DashAttack="body",Air1="body",Air2="head",
 Slam="body",AngleStep="body",Sweep="legs",CounterPalm="body",WallDive="body",PalmThrust="body",KneeStrike="body",FlyingKick="head",
 Riposte="head",SlideSweep="legs",SandPillar="legs",FeintStep="body",CircleStep="body",AirDrive="body",AirSpike="head",AirSwitch="head",
 LionKick="chin",VaultKick="head",ChidoriThrust="body",AirFlip="head",
 Throw="body",ThrowUp="body",Grab="body"}
local KIND={Light3="kick",Heavy="heavy",Launcher="launch",Air2="kick",Slam="slam",Sweep="sweep",SlideSweep="sweep",KneeStrike="knee",
 FlyingKick="kick",WallDive="kick",SandPillar="launch",AirDrive="kick",AirSpike="spike",AirSwitch="kick",PalmThrust="palm",CounterPalm="palm",
 LionKick="launch",VaultKick="kick",ChidoriThrust="heavy",AirFlip="kick"}
for name,spec in attacks do spec.zone=ZONE[name] or "body";spec.kind=KIND[name] or "strike" end
attacks.Light4.clip="Light1";attacks.Light5.clip="Light2"
attacks.SandHand.range=12;attacks.SandHand.width=5;attacks.SandHand.height=6;attacks.SandHand.depth=11;attacks.SandHand.offset=6;attacks.SandHand.facing=.25;attacks.SandHand.clip="SandPillar";attacks.SandHand.kind="heavy";attacks.SandHand.zone="body"
attacks.SandFist.range=9;attacks.SandFist.width=5;attacks.SandFist.depth=8;attacks.SandFist.offset=4.5;attacks.SandFist.facing=.3;attacks.SandFist.clip="Light3";attacks.SandFist.kind="heavy"
attacks.SandLowWave.range=9.5;attacks.SandLowWave.width=7;attacks.SandLowWave.height=3.5;attacks.SandLowWave.depth=9;attacks.SandLowWave.offset=4.5;attacks.SandLowWave.clip="Sweep";attacks.SandLowWave.zone="legs";attacks.SandLowWave.kind="sweep"
attacks.SandGlide.range=8.5;attacks.SandGlide.width=5;attacks.SandGlide.depth=7;attacks.SandGlide.offset=4;attacks.SandGlide.orbit=34;attacks.SandGlide.clip="FeintStep";attacks.SandGlide.zone="body"
attacks.Grab.range=4.6;attacks.Grab.blockable=false;attacks.Throw.blockable=false;attacks.ThrowUp.blockable=false
-- Rock Lee's moves, kept together so the stress-test fighter stays additive:
-- reach, body, hit zone and kind, the two routes that keep the string, and the
-- two big kicks that crack Gaara's sand shield like a launcher does
-- (breaksShield, read by Combat:damage next to its name list).
for name,shape in {
 LeafRising={contact=3.4,range=6.5,width=5,height=7,zone="chin",kind="launch",side=1,twist=12,lean=-34,arm=40,step=1.15,breaksShield=true},
 LeafHurricane={contact=3.5,range=6.5,width=6.5,height=3.5,zone="legs",kind="sweep",side=-1,twist=70,lean=24,arm=50,step=1.0,chain=true},
 LeafWhirlwind={contact=3.8,range=7,width=9,height=6,zone="head",kind="kick",side=1,twist=80,lean=6,arm=60,step=1.05,chain=true},
 GreatWhirlwind={contact=3.6,range=7,width=7,height=6,zone="body",kind="kick",side=1,twist=90,lean=10,arm=60,step=1.4,breaksShield=true},
 DeflectKick={contact=3.6,range=6,width=7,height=7,zone="body",kind="kick",side=-1,twist=40,lean=-6,arm=50,step=1.0},
} do
 for key,value in shape do attacks[name][key]=value end
end
-- Naruto (roster wave, several bodies). His own: the headbutt (heavy after
-- one hit) and the tackle into the legs (low route). Carried out by a shadow
-- clone (`proxy`: where the clone stands, Server/Bodies; `proxyClip`: the
-- clone's own clip while Naruto plays the move's): the kick from behind (the
-- third hit with a clone out), the kick up under the body (the Uzumaki
-- Barrage) and the strike from the flank (side route, the string goes on).
-- The Nine-Tails cloak's claws (no clones there): a rising claw and a long
-- swipe. A clone's own jab and the barrage kick time the clients' clips.
for name,m in {
 Headbutt=move(.1,.1,.3,9,2.6,"HitStun",Vector3.new(0,4,14),.45),
 Tackle=move(.12,.16,.34,8,4.5,"Knockdown",Vector3.new(0,8,22),.7),
 CloneKick=move(.15,.14,.28,11,0,"Juggled",Vector3.new(0,26,6),.62),
 UzumakiKick=move(.16,.14,.3,8,0,"Launched",Vector3.new(0,56,4),1.2),
 MirrorClone=move(.11,.12,.22,6,0,"HitStun",Vector3.new(0,4,10),.36),
 ClawRise=move(.14,.14,.26,10,2.6,"Launched",Vector3.new(0,58,6),1.2),
 ClawSwipe=move(.1,.14,.22,8,1.6,"HitStun",Vector3.new(0,6,16),.4),
 CloneJab=move(.22,.1,.3,4,0,"HitStun",Vector3.new(0,3,10),.32),
 BarrageKick=move(.1,.1,.2,3,0,"Juggled",Vector3.new(0,22,2),.6),
} do
 m.animation=name;m.feedback=m.reaction;m.chain=false;m.air=false
 m.depth=m.range*.8;m.offset=m.range*.4
 attacks[name]=m
end
for name,shape in {
 Headbutt={contact=3.0,range=5.5,zone="head",kind="heavy",side=1,twist=6,lean=26,arm=40,step=1.2},
 Tackle={contact=2.8,range=6.5,width=6,height=4,zone="legs",kind="sweep",side=1,twist=10,lean=40,arm=60,step=1.35},
 CloneKick={contact=2.6,range=6,width=5.5,height=6,zone="body",kind="kick",side=1,twist=40,lean=8,arm=60,step=1,proxy="behind",proxyClip="CloneKickStrike"},
 UzumakiKick={contact=2.4,range=6,width=5.5,height=7,zone="chin",kind="launch",side=1,twist=10,lean=-20,arm=60,step=1,proxy="under",proxyClip="UzumakiRise",breaksShield=true},
 MirrorClone={contact=2.8,range=6,width=5.5,height=6,zone="body",kind="strike",side=-1,twist=30,lean=10,arm=90,step=1,proxy="side",proxyClip="MirrorStrike",chain=true},
 ClawRise={contact=3.4,range=9.5,width=6,height=7,depth=8.5,offset=4.4,zone="chin",kind="launch",side=1,twist=16,lean=-24,arm=120,step=1.15,breaksShield=true},
 ClawSwipe={contact=3.6,range=10,width=9,height=6,depth=9,offset=4.6,zone="body",kind="slash",side=-1,twist=60,lean=12,arm=100,step=1.1,chain=true},
 CloneJab={contact=3,range=5.5,zone="head",kind="strike",side=1,twist=24,lean=10,arm=88,step=1},
 BarrageKick={contact=2.4,range=5,zone="body",kind="kick",side=1,twist=10,lean=-10,arm=60,step=1},
} do
 for key,value in shape do attacks[name][key]=value end
end
-- Temari's fan moves: a reach of their own (contact: she stays further out),
-- the zone and kind the body answers, the air flag of the Fan Dive and the
-- lateral push of the pirouette (Brawler.hit: thrown aside, not away).
for name,shape in {
 Updraft={contact=4.8,range=7.5,width=6,height=8,zone="chin",kind="launch",side=1,twist=12,lean=-28,arm=120,step=1.1,breaksShield=true},
 FanSlam={contact=4.8,range=7.6,width=5,height=7,zone="head",kind="heavy",side=1,twist=10,lean=30,arm=120,step=1.15},
 FanPirouette={contact=4.6,range=7.6,width=8.5,height=6,zone="body",kind="palm",side=1,twist=90,lean=6,arm=80,step=1.0,lateral=true},
 FanBackhand={contact=4.8,range=7.6,width=6,height=6,zone="body",kind="slash",side=-1,twist=50,lean=10,arm=96,step=1.15},
 FanDive={contact=4.2,range=7.5,width=6,height=8,zone="head",kind="spike",side=1,twist=10,lean=40,arm=120,step=1,air=true},
} do
 for key,value in shape do attacks[name][key]=value end
end
-- Ninja Embodiment (EMB-002, Shared/ActionContext): two shared strikes the
-- situation itself calls for. `clip` names the clip a fighter plays for it
-- when he has none of his own (his own kick from behind, his own air kick).
--   BackStrike  the opponent's back is turned: a full strike into it, no
--               turning needed; it throws the body away (a punish, not a string).
--   DropStrike  falling onto a grounded body: the weight comes down with the
--               strike; it does not hold the body in the air.
for name,m in {
 BackStrike=move(.08,.13,.3,10,2.4,"Knockback",Vector3.new(0,10,34),.46),
 -- (The stick backing off as he presses: a quick strike that takes the
 -- step back with it: it lands, and the body is already out of reach.)
 StepBackStrike=move(.07,.1,.26,5,0,"HitStun",Vector3.new(0,3,10),.34),
 DropStrike=move(.07,.15,.24,8,1.2,"HitStun",Vector3.new(0,-6,10),.4),
} do
 m.animation=name;m.feedback=m.reaction;m.chain=false;m.air=false
 m.depth=m.range*.8;m.offset=m.range*.4
 attacks[name]=m
end
for name,shape in {
 BackStrike={contact=3.6,range=6.5,width=5.5,height=6,zone="body",kind="kick",clip="Light3",side=1,twist=60,lean=14,arm=100,step=1.2},
 DropStrike={contact=3,range=6.5,width=6,height=10,zone="head",kind="kick",clip="Air2",side=-1,twist=40,lean=24,arm=100,step=1.1},
 StepBackStrike={contact=3.4,range=6,width=5,height=6,zone="body",kind="strike",clip="Light2",side=-1,twist=30,lean=-6,arm=90,step=.9,retreat=2.6},
} do
 for key,value in shape do attacks[name][key]=value end
end
-- Roster 20 batches add their strikes from their own data modules.
for _,wave in {require(script.Parent.Wave1),require(script.Parent.Wave2),require(script.Parent.Wave3),require(script.Parent.Wave4)} do
 if wave.attacks then wave.attacks(move,attacks) end
end
return attacks
