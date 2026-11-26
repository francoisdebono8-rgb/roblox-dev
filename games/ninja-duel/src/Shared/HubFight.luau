-- His kit in the street (26/11, passe 3, DEC-055, HUB-002; François : « qu'on
-- puisse utiliser nos attaques et tout quand on se balade, ça y est pas » ;
-- his choice: « le coup lance le duel »). The rules shared by the walker's
-- client (Client/HubFightClient: the keys, his body plays the move at once)
-- and the server (Server/HubFight: the move granted, everyone sees it, the
-- blow lands on what is in front of him).
--
-- The moves are the duel's own clips on the walker's body (Client/HubBody):
-- the light chain (Light1, Light2, Light3), the heavy blow, the dash, the
-- guard held, the air strike. What a blow meets:
--   * a crate, a barrel, a bench, a stump: it cracks, then breaks (the duel's
--     world, Server/WorldReaction), and is put back a little later;
--   * the training dummy: it takes the blow;
--   * a rogue: his street fight, now; an inspiration's challenger: his
--     challenge, now; the forest's bandit: his fight;
--   * another player: the first blow is a challenge, without damage. If he
--     hits back within the window, the 1v1 starts there (Server/Lobby).
local HubFight={}

-- Each move: its clip (the kit's own, Client/HubBody.clipName), when its blow
-- lands (s after the press), how far and how wide it reaches (studs), the
-- energy it gives the world (WorldReaction.impact), how long the walker is
-- slowed, and the shortest gap before the same move again.
HubFight.Moves={
	Light1={clip="Light1",contact=.14,reach=4.4,width=3.6,energy=22,slow=.34,gap=.16,kind="Light"},
	Light2={clip="Light2",contact=.14,reach=4.4,width=3.6,energy=22,slow=.34,gap=.16,kind="Light"},
	Light3={clip="Light3",contact=.2,reach=4.8,width=4,energy=34,slow=.44,gap=.16,kind="Light"},
	Heavy={clip="Heavy",contact=.32,reach=5.2,width=4.2,energy=60,slow=.62,gap=.55,kind="Heavy"},
	Air={clip="Air1",contact=.16,reach=4.6,width=4,energy=26,slow=0,gap=.3,kind="Light"},
	Dodge={clip="Dash.F",dash=58,dashTime=.17,slow=0,gap=.55,kind="Dodge"},
	Guard={clip="Guard",hold=true,slow=0,gap=.1,kind="Guard"},
}
-- The light chain: the next light within this long after the last one began
-- (its clip played through and a little more) goes on; later, it starts over.
HubFight.CHAIN=.75
-- How slow the walker goes while a blow plays (studs/s), and while guarding.
HubFight.SLOW_SPEED=5
HubFight.GUARD_SPEED=7
-- A player struck: his answer within this long starts the duel; the same two
-- not again before the cooldown.
HubFight.CHALLENGE_WINDOW=5
HubFight.CHALLENGE_COOLDOWN=10
-- A broken prop is put back after this long without a new blow nearby.
HubFight.RESTORE=25
-- The server takes no more than this many moves a second from a walker.
HubFight.RATE=8

-- (pure) The light chain: which light a press is (1, 2 or 3), given the last
-- light's number and when it began.
function HubFight.chain(lastN,lastAt,now)
	if type(lastN)~="number" or type(lastAt)~="number" or now-lastAt>HubFight.CHAIN then return 1 end
	return (lastN%3)+1
end

-- (pure) Whether the server grants `move` to a walker whose last grants are
-- `last` ({[move]=time, all={times}}) at `now`; records it when granted.
function HubFight.grant(last,move,now)
	local spec=HubFight.Moves[move]
	if not spec then return false,"unknown" end
	if last[move] and now-last[move]<spec.gap then return false,"too soon" end
	last.all=last.all or {}
	local recent=0
	for _,t in last.all do if now-t<1 then recent+=1 end end
	if recent>=HubFight.RATE then return false,"rate" end
	last[move]=now
	table.insert(last.all,now)
	while #last.all>HubFight.RATE*2 do table.remove(last.all,1) end
	return true
end

-- (pure) The box a blow reaches, from the walker's root frame: its centre
-- frame and size (in front of him, chest high).
function HubFight.box(rootCFrame,spec)
	local reach=spec.reach or 4
	local cf=rootCFrame*CFrame.new(0,.3,-(reach/2+.6))
	return cf,Vector3.new(spec.width or 3.6,5,reach)
end

-- (pure) The walker's state for a challenge between `from` and `to` at
-- `now` in the record `challenges` ({[to]={from, at}}) and `cooldowns`
-- ({[pairKey]=time}): "accept" (to had challenged from: the riposte),
-- "challenge" (a new one), or "wait" (the same two, too soon).
function HubFight.pairKey(a,b) return if a<b then a..":"..b else b..":"..a end
function HubFight.answer(challenges,cooldowns,from,to,now)
	local mine=challenges[from]
	if mine and mine.from==to and now-mine.at<=HubFight.CHALLENGE_WINDOW then return "accept" end
	local key=HubFight.pairKey(from,to)
	if cooldowns[key] and now-cooldowns[key]<HubFight.CHALLENGE_COOLDOWN then return "wait" end
	return "challenge"
end

return HubFight
