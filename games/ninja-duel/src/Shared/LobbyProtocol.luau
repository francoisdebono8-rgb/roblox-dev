-- Players online and challenges (Server/Lobby, Client/LobbyPanel): tunables
-- and the vocabulary between them. Authority stays in Server/Lobby; nothing in
-- here is ever read back from a client.
--
-- Client -> server (RemoteEvent NinjaDuel.Lobby), every field checked there:
--   {op="open"} / {op="close"}           the list is on screen / closed
--   {op="fighter", fighter=id}           the fighter picked on the roster
--   {op="dnd", on=bool}                  do not disturb
--   {op="challenge", to=userId, fighter=id}
--   {op="answer", id=challengeId, accept=bool, fighter=id}
--   {op="cancel", id=challengeId}
--   {op="home"}                          from a duel server: back to the lobby
-- Server -> client:
--   {kind="list", players={...}, dnd=bool, duelServer=bool}
--   {kind="invite", id, from, fromId, fighter, remaining}
--   {kind="sent", id, to, remaining} / {kind="closed", id, text?}
--   {kind="status", text, tone="info"|"bad"} / {kind="dnd", on}
return table.freeze({
	Tune=table.freeze({
		-- Presence: published every Publish s, gone after Life s without a refresh,
		-- the map read back every Read s (up to Page entries), ListMax shown.
		Publish=15,Life=45,Read=10,Page=200,ListMax=60,
		-- A challenge lasts ChallengeLife s; one every Gap s per player, MaxOut
		-- waiting per challenger, MaxIn waiting per challenged player.
		ChallengeLife=20,Gap=10,MaxOut=3,MaxIn=3,
		-- Requests of one player: one every OpGap s.
		OpGap=0.25,
		-- Duel server: both players within Arrival s, its record kept DuelRecordLife s.
		Arrival=45,DuelRecordLife=600,
		PresenceMap="ND_Presence_v1",DuelMap="ND_DuelServers_v1",Topic="ND_Lobby_v1",
	}),
})
