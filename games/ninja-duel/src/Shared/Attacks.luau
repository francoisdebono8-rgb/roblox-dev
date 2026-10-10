-- Original fighting grammar. Timing, travel, volume and reaction belong to the server.
local function move(startup,active,recovery,damage,travel,reaction,impulse,stun)
 return {startup=startup,active=active,recovery=recovery,damage=damage,travel=travel,
  travelTime=startup+active,reaction=reaction or "HitStun",impulse=impulse or Vector3.new(0,0,7),stun=stun or 0.27,
  range=7.8,width=5.5,height=6,blockable=true}
end
local attacks={
 Light1=move(.10,.12,.22,6,2.8), Light2=move(.11,.12,.22,7,3.2),
 Light3=move(.13,.13,.25,8,3.5), Light4=move(.18,.15,.42,12,4,"Knockback",Vector3.new(0,12,43),.4),
 Heavy=move(.28,.17,.48,16,4.5,"Knockdown",Vector3.new(0,12,28),.65),
 Launcher=move(.18,.14,.28,9,2.5,"Launched",Vector3.new(0,52,11),1.15),
 DashAttack=move(.08,.15,.29,7,7,"HitStun",Vector3.new(0,0,9),.29),
 Air1=move(.09,.13,.19,6,2.5,"Juggled",Vector3.new(0,13,5),.6),
 Air2=move(.11,.13,.20,7,2.5,"Juggled",Vector3.new(0,15,5),.6),
 Slam=move(.17,.18,.37,13,2,"Knockdown",Vector3.new(0,-65,8),.8),
 Grab=move(.18,.14,.5,0,2,"Grabbed",Vector3.zero,.8),
 Throw=move(.12,.1,.34,10,0,"Knockdown",Vector3.new(0,18,48),.7),
 ThrowUp=move(.12,.1,.3,7,0,"Launched",Vector3.new(0,50,10),1.1),
}

for name,spec in attacks do
 spec.animation=name;spec.feedback=spec.reaction;spec.chain=name=="Light1" or name=="Light2" or name=="Light3" or name=="Air1" or name=="Air2" or name=="DashAttack"
end
attacks.Grab.range=4.6;attacks.Grab.blockable=false;attacks.Throw.blockable=false;attacks.ThrowUp.blockable=false
return attacks
