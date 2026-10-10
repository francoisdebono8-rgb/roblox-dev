-- Bangla three-strike M1 foundation; air/grab/launch branches are Ninja Duel glue.
local Combo=require(script.Parent.BanglaCombo)
local function move(startup,active,recovery,damage,travel,reaction,impulse,stun)
 return {startup=startup,active=active,recovery=recovery,damage=damage,travel=travel,
  travelTime=startup+active,reaction=reaction or "HitStun",impulse=impulse or Vector3.new(0,0,7),stun=stun or 0.27,
  range=7.8,width=5.5,height=6,blockable=true}
end
local attacks={
 Light1=move(.09,.12,Combo.comboDelay-.22,Combo.Damage.Punch,3.2),
 Light2=move(.10,.12,Combo.comboDelay-.23,Combo.Damage.HardSmack,3.5),
 Light3=move(.12,.14,Combo.comboDelay-.26,Combo.Damage.MegaPunch,4.2,"Knockback",Vector3.new(0,14,50),.48),
 Heavy=move(.30,.17,.52,16,5.4,"Knockdown",Vector3.new(0,12,34),.68),
 Launcher=move(.17,.14,.28,9,3.2,"Launched",Vector3.new(0,58,13),1.18),
 DashAttack=move(.07,.15,.27,7,8.2,"HitStun",Vector3.new(0,3,13),.31),
 Air1=move(.08,.13,.18,6,2.8,"Juggled",Vector3.new(0,15,8),.62),
 Air2=move(.09,.14,.19,7,3.1,"Juggled",Vector3.new(0,10,12),.64),
 Slam=move(.15,.20,.38,13,2.8,"Knockdown",Vector3.new(0,-78,10),.86),
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
}

for name,spec in attacks do
 if not Combo.Actions[name] then spec.depth=spec.range*.8;spec.offset=spec.range*.4 end
 spec.animation=name;spec.feedback=spec.reaction;spec.chain=name=="Light1" or name=="Light2" or name=="Air1" or name=="Air2" or name=="DashAttack" or name=="AngleStep"
end
-- Hitstop is not authored per move any more: weight comes from Combat.Hitstop so
-- a light jab cannot be given a heavy stop by accident.
local motion={
 Light1={side=1,twist=30,lean=8,arm=82,step=1.05},
 Light2={side=-1,twist=34,lean=10,arm=88,step=1.08},
 Light3={side=1,twist=72,lean=12,arm=102,step=1.2},
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
}
for name,pose in motion do for key,value in pose do attacks[name][key]=value end end
for _,name in {"Light1","Light2","Light3"} do attacks[name].width=5;attacks[name].height=5;attacks[name].range=6 end
attacks.AngleStep.width=5;attacks.AngleStep.range=6.5;attacks.AngleStep.orbit=17
attacks.Sweep.height=3.5;attacks.Sweep.width=6.5;attacks.Sweep.range=6.5
attacks.WallDive.width=6;attacks.WallDive.height=8;attacks.WallDive.range=7.5;attacks.WallDive.facing=-.45
attacks.Grab.range=4.6;attacks.Grab.blockable=false;attacks.Throw.blockable=false;attacks.ThrowUp.blockable=false
return attacks
