-- Roster 20 batches (Shared/WaveN): a fighter's own strike, added to Attacks
-- with the fields every strike carries (Animation.spec: side/twist/lean/arm/
-- step; Combat: animation/feedback/chain/air/depth/offset), so a batch only
-- writes its timing and its shape.
--   timing  {startup, active, recovery, damage, travel, reaction, impulse, stun}
--   shape   reach, body and tags (range, contact, width, height, zone, kind,
--           chain, air, lateral, orbit, riders, breaksShield...)
-- A new strike has no clip of its own: the fighter's Motion.borrow names the
-- clip it plays (VelmoraMotionEngine), otherwise its family's Light1.
local RosterMoves={}
function RosterMoves.add(move,attacks,list)
	for name,entry in list do
		assert(not attacks[name],"strike "..name.." already exists")
		local m=move(table.unpack(entry[1]))
		m.animation=name;m.feedback=m.reaction;m.chain=false;m.air=false
		m.side=1;m.twist=30;m.lean=10;m.arm=90;m.step=1.1
		m.zone="body";m.kind="strike"
		for key,value in entry[2] do m[key]=value end
		m.depth=entry[2].depth or m.range*.8
		m.offset=entry[2].offset or m.range*.4
		attacks[name]=m
	end
end
return RosterMoves
