-- Online 1v1 (NET-001): shared tunables and the request vocabulary of the
-- online flow. Authority stays in Server/Online and Server/Matches; nothing in
-- here is ever read back from a client.
return table.freeze({
	-- Seconds both players get to confirm (or change) their fighter once paired;
	-- the duel starts when both confirm or when the time runs out.
	PickTime=15,
	-- Private duel codes: short, upper case, no look-alike characters (0/O, 1/I/L).
	CodeLength=5,
	CodeAlphabet="ABCDEFGHJKMNPQRSTUVWXYZ23456789",
	-- Minimum gap between two lobby requests of one player (same as the local duel).
	LifecycleGap=0.8,
	-- Requests that enter or leave the online flow from the roster / waiting screen.
	Lifecycle=table.freeze({Queue=true,Host=true,Join=true,Cancel=true}),
	-- The only requests an online fighter may send during a fight. Anything else
	-- is ignored before it reaches Combat.
	Combat=table.freeze({Move=true,Attack=true,Heavy=true,Jump=true,JumpOff=true,Dodge=true,Guard=true,GuardOff=true,
		Grab=true,Tool=true,Pursuit=true,Substitute=true,Feint=true,WallDetach=true,Awaken=true,
		Technique1=true,Technique2=true,Technique3=true,Technique4=true,Technique5=true}),
})
