local M=require(script.Parent.Model)
local L={}
L.Families={"Locomotion","Punches","Kicks","Knees","Elbows","Launchers","Dodges","Counters","Reactions","Transitions","Aerial","Wall","Grabs","Projectiles"}
L.Blocks={
 {"idle","Idle","Locomotion","Idle",1.5},{"walk","Walk","Locomotion","Walk",1.1},{"run","Run","Locomotion","Run",.8},{"sprint","Sprint","Locomotion","Sprint",.65},{"strafe","Strafe","Locomotion","Strafe",1},{"turn","Pivot","Locomotion","Pivot",.6},{"jump","Jump","Aerial","Jump",.8},{"land","Land","Transitions","Land",.5},{"dash","Dash","Dodges","Dash",.4},{"dashattack","Dash attack","Punches","DashAttack",.6},
 {"jab","Jab","Punches","Light1",.5},{"cross","Cross","Punches","Light2",.55},{"hook","Hook","Punches","Hook",.6},{"uppercut","Uppercut","Punches","Uppercut",.6},{"palm","Palm","Punches","PalmThrust",.6},
 {"frontkick","Front kick","Kicks","FrontKick",.65},{"sidekick","Side kick","Kicks","SideKick",.7},{"roundhouse","Roundhouse","Kicks","Roundhouse",.8},{"spinkick","Spin kick","Kicks","Light3",.85},{"sweep","Sweep","Kicks","Sweep",.7},
 {"knee","Knee","Knees","KneeStrike",.6},{"risingknee","Rising knee","Knees","RisingKnee",.65},{"elbow","Elbow","Elbows","Elbow",.6},{"spinelbow","Spinning elbow","Elbows","SpinElbow",.7},
 {"launcher","Launcher","Launchers","Launcher",.7},{"dodge","Dodge","Dodges","Dodge",.6},{"counter","Counter palm","Counters","CounterPalm",.6},{"hit","Light hit","Reactions","Hit",.6},{"stagger","Stagger","Reactions","Stagger",.9},{"knockdown","Knockdown","Reactions","Knockdown",1.1},
 {"pursue","Pursuit","Transitions","Pursue",.6},{"air1","Air strike 1","Aerial","Air1",.55},{"air2","Air strike 2","Aerial","Air2",.6},{"slam","Slam","Aerial","Slam",.75},{"wallrun","Wall run","Wall","WallRun",1},{"wallentry","Wall re-entry","Wall","WallDive",.8},{"grab","Grab","Grabs","Grab",.8},{"throw","Weapon throw","Projectiles","ToolThrow",.65},
}
L.Templates={
 {id="lee",name="Lee",note="Lower-body drive / physical pursuit",dna={cadence=1.65,stepLength=1.4,lowerActivity=1.5,upperActivity=1.2,aggression=.95,forwardPressure=.9,acrobatics=.8,groundedness=.8},rules={preferredGrammar={Pursue="physical",Strike="taijutsu"},grammarOverrides={Pursue={rootTravel=1,bodyScale=1.2},Air1={bodyScale=1.3}}},stance={root={y=-.4,pitch=14},torso={pitch=8},ra={raise=60,elbow=110},la={raise=65,elbow=100}}},
 {id="gaara",name="Gaara",note="Calm body / sand conversion proposals",dna={cadence=.6,amplitude=.35,upperActivity=.3,lowerActivity=.3,rootIntensity=.3,looseness=.2,apparentWeight=.85,groundedness=.95,acrobatics=.1,guardOpenness=.85},rules={preferredGrammar={Launcher="sand-lift",Pursue="sand-carry",Strike="sand-pressure"},grammarOverrides={Launcher={bodyScale=.15,rootTravel=.05},Pursue={bodyScale=.2,rootLift=.25},Slam={bodyScale=.2}}},stance={root={y=-.12,pitch=0},torso={pitch=0},ra={raise=12,elbow=30},la={raise=12,elbow=30}}},
 {id="bee",name="Killer Bee",note="Asymmetric stance / irregular axes",dna={asymmetry=.65,cadence=1.15,amplitude=1.25,lateralBias=.35,rotationAmount=1.4,hipInvolvement=1.35,looseness=.85,acrobatics=.75,precision=.5},rules={preferredGrammar={Strike="multi-axis",Projectile="multi-weapon"},grammarOverrides={Hook={bodyScale=1.25,lateralTravel=.3},CounterPalm={bodyScale=1.1,lateralTravel=-.3}}},stance={root={y=-.45,roll=10,yaw=25},torso={roll=-12,yaw=-18},ra={raise=85,out=35,elbow=80},la={raise=25,out=40,elbow=120}}},
 {id="shisui",name="Shisui",note="Burst cadence / lateral transitions",dna={cadence=1.8,strideFrequency=1.5,lateralBias=.6,recoverySpeed=1.65,apparentWeight=.2,rotationAmount=1.2,precision=.9,rootIntensity=1.2,acrobatics=.75},rules={preferredGrammar={Transition="burst-step",Dodge="lateral-burst"},grammarOverrides={Dodge={lateralTravel=.8,rootTravel=.4},Pursue={rootTravel=.6,lateralTravel=.5}}},stance={root={y=-.38,pitch=12,yaw=-18},torso={pitch=7,yaw=8},ra={raise=45,elbow=100},la={raise=60,elbow=90}}},
}
function L.new()
 local lib={presets={},assets={},order={},assetOrder={}}
 for _,b in L.Blocks do
  lib.assets[b[1]]={id=b[1],name=b[2],category=b[3],grammar=b[4],tags={b[3]},compatibleBodyLayers=M.copy(M.Layers),defaultSpeed=1,duration=b[5],contactMarkers={{at=.38,name="contact"}},rootPolicy="presentation",styleTags={},sourceType="procedural",proceduralDefinition={kind=b[4]}}
  table.insert(lib.assetOrder,b[1])
 end
 for _,template in L.Templates do
  local p=M.new(template.id,template.name);for k,v in template.dna do p.motionDNA[k]=v end
  p.stance=M.copy(template.stance);p.stance.weapon={roll=template.dna.asymmetry and 45 or 0};p.characterRules=M.copy(template.rules);p.metadata.description=template.note;p.metadata.sourceType="generated";p.metadata.startingProfile=true;p.metadata.dnaReference=M.copy(p.motionDNA)
  lib.presets[p.id]=p;table.insert(lib.order,p.id)
 end
 return lib
end
function L.propose(preset)
 -- Suggested pieces stay ordinary editable references, never archetype locks.
 local dna=preset.motionDNA;local p=M.copy(preset)
 p.locomotionSet={idle="idle",walk="walk",run=if dna.cadence>1.4 then "sprint" else "run",dash="dash",jump="jump",land="land",wall="wallrun"}
 local route=if dna.acrobatics>.65 then {"jab","knee","spinkick"} elseif dna.precision>.8 then {"palm","cross","launcher"} else {"jab","cross","frontkick"}
 p.sequences={{id="sequence1",name="Opening phrase",orderedClips={}}}
 for _,id in route do local block;for _,b in L.Blocks do if b[1]==id then block=b end end;table.insert(p.sequences[1].orderedClips,{asset=id,duration=block[5]/dna.cadence,blend=.1,transition="blend"}) end
 p.metadata.generated=true;return p
end
return L
