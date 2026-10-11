-- Proposal fixtures ONLY. No active character, weapon or combat reads this data.
local C={Enabled=false,MaxObjects=32,MaxSurfaces=16,MaxEvents=128,MaxLife=30,MaxSpeed=180,MaxChakra=1000,
 Triggers={Infuse=true,ProjectileClash=true,SurfaceHit=true,Contact=true},
 Tags={tool=true,projectile=true,metal=true,blade=true,wire=true,actor=true,solid=true,wall=true,floor=true,anchorCompatible=true,burnable=true,conductive=true,chakra=true,reinforced=true,wind=true,fire=true,lightning=true,marked=true,seal=true,spatialAnchor=true,embedded=true,conductiveWire=true,weaponExpert=true,sealExpert=true,ignited=true},
 Natures={Wind={tag="wind"},Fire={tag="fire"},Lightning={tag="lightning"}},
 Properties={Marked={tag="marked",requires={"tool"}},Seal={tag="seal",requires={"tool"}}},
 Masteries={Basic={tags={},levels={Wind=0,Seal=0}},WeaponExpert={tags={"weaponExpert"},levels={Wind=3,Seal=0}},SealExpert={tags={"sealExpert"},levels={Wind=0,Seal=3}}},
 MasterySkills={Wind=true,Seal=true},CharacterMastery={},Objects={},Surfaces={},Infusions={},Rules={}}
C.Objects.Kunai={toolType="Kunai",tags={"tool","projectile","metal","blade"},canLaunch=true,infusions={Reinforce=true,Wind=true,Fire=true,Lightning=true},stats={speed=42,stability=1,impact=1,cut=1},caps={speed=90,stability=2,impact=2,cut=2},radius=.35,visual="kunai"}
C.Objects.Shuriken={toolType="Shuriken",tags={"tool","projectile","metal","blade"},canLaunch=true,infusions={Reinforce=true,Wind=true,Fire=true,Lightning=true},stats={speed=36,stability=1,impact=1,cut=1},caps={speed=80,stability=2,impact=2,cut=2},radius=.5,visual="shuriken"}
C.Objects.Wire={toolType="Wire",tags={"tool","wire","metal"},canLaunch=false,infusions={Reinforce=true,Lightning=true},stats={stability=1,impact=1},caps={stability=2,impact=2},radius=.2,visual="wire"}
C.Objects.Target={toolType="Target",tags={"actor","conductive"},canLaunch=false,infusions={},stats={},caps={},radius=1,visual="target"}
C.Surfaces.Wall={tags={"solid","wall","anchorCompatible","conductive"},normal={x=-1,y=0,z=0},radius=8}
C.Surfaces.Floor={tags={"solid","floor","anchorCompatible"},normal={x=0,y=1,z=0},radius=8}
C.Surfaces.Wood={tags={"solid","wall","burnable"},normal={x=-1,y=0,z=0},radius=8}
C.Infusions.Reinforce={tags={"chakra","reinforced"},cost=2}
C.Infusions.Wind={nature="Wind",tags={"chakra"},cost=3}
C.Infusions.Fire={nature="Fire",tags={"chakra"},cost=3}
C.Infusions.Lightning={nature="Lightning",tags={"chakra"},cost=3}
C.Rules={
 {id="reinforced-tool",enabled=false,priority=20,trigger="Infuse",when={source={all={"tool","projectile","reinforced"}}},effects={{kind="scaleStat",stat="speed",factor=1.12},{kind="scaleStat",stat="stability",factor=1.2},{kind="scaleStat",stat="impact",factor=1.15}}},
 {id="wind-kunai",enabled=false,priority=30,trigger="Infuse",when={source={all={"projectile","wind"}},toolType="Kunai"},effects={{kind="scaleStat",stat="speed",factor=1.25,mastery="Wind",perLevel=.03,maxFactor=1.4},{kind="scaleStat",stat="cut",factor=1.2}}},
 {id="metal-conduction",enabled=false,priority=20,trigger="Infuse",when={source={all={"metal","lightning"}}},effects={{kind="tag",tag="conductive",target="source"}}},
 {id="wire-property",enabled=false,priority=25,trigger="Infuse",when={source={all={"wire","lightning"}}},effects={{kind="tag",tag="conductiveWire",target="source"},{kind="signal",name="trap-property-ready"}}},
 {id="contact-conduction",enabled=false,priority=20,trigger="Contact",when={source={all={"metal","lightning"}},target={all={"actor","conductive"}}},effects={{kind="signal",name="conduction-contact"}}},
 {id="redirect-projectile",enabled=false,priority=40,group="clash-motion",trigger="ProjectileClash",when={source={all={"projectile"}},target={all={"projectile"}},context={all={"wind"}}},effects={{kind="redirect",target="target",speedScale=.85}}},
 {id="deflect-projectile",enabled=false,priority=10,group="clash-motion",trigger="ProjectileClash",when={source={all={"projectile"}},target={all={"projectile"}}},effects={{kind="reflect",target="target",speedScale=.75}}},
 {id="surface-embed",enabled=false,priority=100,trigger="SurfaceHit",when={source={all={"projectile","metal"}},surface={all={"solid","anchorCompatible"}}},effects={{kind="embed",target="source"}}},
 {id="seal-anchor",enabled=false,priority=90,trigger="SurfaceHit",cost=3,when={source={all={"tool","marked","seal"}},surface={all={"anchorCompatible"}}},effects={{kind="anchor",target="source"},{kind="signal",name="spatial-point-created"}}},
 {id="fire-surface",enabled=false,priority=30,trigger="SurfaceHit",when={source={all={"projectile","fire"}},surface={all={"burnable"}}},effects={{kind="tag",target="surface",tag="ignited"},{kind="signal",name="surface-ignition-request"}}},
}
return C
