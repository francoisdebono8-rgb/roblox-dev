# Online foundation — two-player 1v1 (NET-001)

Branch `claude/nd-online-foundation`, based on `c2d797c`. Scope: mission
[COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
sections 13–14, under DEC-012 (PvP opened) and DEC-003 (isolation).

| Gate | Status |
|---|---|
| Headless (`tests/run.sh`) | **TECHNICAL PASS**: 16 suites / 180 cases (163 existing unchanged + 17 new in `Online.spec.luau`) |
| Builds normal / debug / QA, isolation, architecture, project docs | **PASS** |
| Two-client Studio session | **NOT RUN** (no Studio in this session). Checklist in §5 |
| Latency matrix 0 / ~60 / ~100–120 ms + jitter | **NOT RUN**. Procedure and tools in §6 |
| Human feel online | **PENDING** |

## 1. What exists now

A real two-player duel on the same server-authoritative engine as the AI mode:

`roster → ONLINE DUEL (casual queue) or HOST / JOIN a private code → fighter pick
(versus screen, 15 s, both READY or timer) → fight (intro, best of 3 rounds, KO beat)
→ result → REMATCH (both players) or RETURN TO THE ROSTER`

- **Casual queue**: first come, first paired, per server. **Private duel**: the host
  gets a 5-character code (no look-alike characters, single use, dies with the
  host); the friend types it next to JOIN.
- **Pick**: the roster screen in versus mode. Left half = your fighter (changeable
  until you confirm), right half = the opponent's live pick, READY / LEAVE.
- **Fight**: both actors are humans, each driven only by its own player's requests.
  No AI object is ever created for an online duel.
- **Leaving**: cancel in the queue, leave the pick (the other player is sent back
  with "OPPONENT LEFT"), disconnect mid-fight (forfeit, "VICTORY • FORFEIT" for the
  player who stays, a knockout that already decided the match keeps its winner),
  leave the result (the other player's rematch shows "OPPONENT LEFT"). The stage
  and its lane are freed once nobody is left in the duel.
- The local AI duel and the tutorial run on the same code path as before (§2.6).

## 2. Design

### 2.1 Sessions, duels, lanes
- Every player keeps their own session in `Matches.sessions` (phase, epoch, request
  bucket, lifecycle throttle). An online player's session carries `s.online`
  (`queue`, `host` or `duel` + seat) and mirrors the duel's phase and epoch.
- An online duel `d` is a separate table that is also the `Combat` match
  (`Combat.new(d)`): same fields as a local session (phase, origin, effects,
  rounds, wins, KO beat). It holds two seats `{player, session, fighter, actor,
  ready, rematch, present, impact cursor}`.
- `Matches:update` steps local duels as before and skips online sessions;
  `Online:update` steps each online duel exactly once per frame and broadcasts.
- Lanes: online duels draw from the same `nextLane` counter as the local sessions
  (no shared stage position) and return their lane to a free list on disposal.
- Epochs: a duel starts above both players' epochs and every change is pushed to
  both sessions before the packet goes out, so no client ever drops a packet as
  stale (`Main.client` discards older epochs). The spec asserts this on every packet.

### 2.2 Authority and validation, per player
- One shared input path, `Matches:act(s, actor, payload)`, used by the local duel
  (`s.human`) and by each online seat (its own actor). It is the previous
  validation code unchanged: anti-cheat timestamp window and per-action rate
  limits (`VelmoraAntiCheat`, keyed by actor = per player), finite and bounded
  direction, aim within 150 studs, held-guard intent, lock-on flag. The per-player
  token bucket stays on each player's session.
- Online fights accept only the combat allowlist in `OnlineProtocol.Combat`; lobby,
  AI-mode or invented actions never reach `Combat` during a fight.
- Lobby inputs are validated server-side: fighter id must exist, code must be
  exactly 5 characters `[A-Z0-9]` after trimming/upper-casing, one lobby action per
  0.8 s per player (same gap as the local duel, also throttles code guessing).
- Clients never send health, state, position, opponent or winner; extra fields are
  ignored (tested).
- `player.Character` is each player's own rig; the root's network owner is re-set to
  the server after the assignment (rigs are already created server-owned).

### 2.3 Per-viewer snapshot and the opponent rig (choice)
- `Matches:view(s, cursor, mine, theirs)` builds the existing snapshot from one
  side: `human` = the viewer's actor, `bot` = the opponent, `winner` reads
  `"PlayerFighter"` when the viewer won, `wins = {human, bot}` from the viewer's
  side, impact feed from the viewer's own cursor. The local duel calls it with
  `(s, s, s.human, s.bot)`: the AI mode receives the same fields and values as before.
- **Opponent rig — chosen**: the client resolves the opponent model by the id the
  server already sends, `data.bot.id`, which is the model's name in the duel folder
  (`Presentation.opponent(data, folder)`, also used by Camera and the Studio
  probe; Effects keeps the two ids from the last packet). Against the AI the id is
  still `"AIFighter"`; online the rigs are `Duelist1` / `Duelist2`. Every other
  client lookup was already by id (`impact.owner`, `actor.id`, `seal.body`,
  projectile owner), so nothing else changes.
- Rejected: per-viewer `AIFighter` naming (a name replicates to everyone; one shared
  model cannot carry two names); per-viewer ObjectValue/attribute (extra instances
  and a replication-order race on the first packet for no gain over an id that is
  already in the packet); client-side renaming (fragile, would also require
  rewriting every owner/victim id per viewer).

### 2.4 Rounds, result, rematch
- `Matches:roundOver` (KO beat, tally, next round or result) and
  `Matches:resetRound` (fresh fighters, seat 1 on +Z, seat 2 on −Z, short intro,
  new epoch) were extracted unchanged from the local duel and are used by both.
  The local duel adds its new AI per round in `nextRound`, the online duel does not.
- Rematch requires both players; it rebuilds the stage and the fighters like the
  local rematch.

### 2.5 Combat with two humans (audit)
`Combat`, `Brawler`, `Techniques`, `Motor`, `VelmoraDefense`, `BanglaEvade` and
`VelmoraHitDetection` only use `a.target`, `combat.actors` and the match fields
`phase/origin/effects/introUntil/finishing/finish/onCue/onCombatEvent/
techniquesDisabled`. No reference to `s.human`, `s.bot` or the AI exists outside
`Matches`, `Tutorial`, `DevHooks`, `NativeQA` (local duel only). The only AI
assumptions were in the session wiring: the idle-move rule (now applied to both
seats), `guardWanted` and lock-on (both set from each player's own requests), and
`locked=true` at spawn (both seats, as `c2d797c` does for the bot). Verified headless
through the players' own requests: Itachi's shuriken thrown by player B hitting
player A with the right owner/victim in A's packets, B's substitution after A's
hit (A gets the tracking window), A's Flying Thunder God to A's seal (B unmoved),
A's grab and B's throw break, B's jump, and a clash between two players' strikes.

### 2.6 AI mode and tutorial
Unchanged behaviour: same snapshot fields, same AI creation per round with the same
seed, same lifecycle (Start / Tutorial / Rematch / Selection / TutorialSkip), same
validation. Client: the roster screen gains one row (ONLINE DUEL, HOST PRIVATE
DUEL, code box, JOIN) and a notice line, so its scale reference grows from 660 to
728 px high; HUD and result read "AI" as before. The 163 existing cases pass
unchanged and a new case replays a local AI duel through the shared helpers.

### 2.7 Codex `33028b2` audit (DEC-011)
| Module | Verdict |
|---|---|
| `OnlineQueue` (FIFO, dedup) | Idea reused inline in `Online` (a separate module was not needed) |
| `OnlineValidation` (allowlist, sequence numbers, clientTime ±1 s) | Allowlist reused (`OnlineProtocol.Combat`). Sequence numbers dropped: Roblox remotes are reliable and ordered, replay is bounded by epoch + anti-cheat window. Its ±1 s clock window was looser than the engine's existing one, which both modes now share |
| `OnlineMatch` | Not reused: it bypassed the anti-cheat, guard-intent and lock handling of the real input path; `Matches:act` is the single path |
| `OnlineReplication` (per-recipient impact cursor + ack) | Cursor idea reused (`cursor` argument of `Matches:view`); ack not needed with reliable remotes |
| `OnlineHost` (factory, disabled flag) | Not reused (generic indirection) |
| `OnlineProtocol` | Name kept; version / snapshot rate / enabled flags dropped |
| Dev panels of the same commit | Untouched (DEC-011) |

## 3. Files

| File | Change |
|---|---|
| `src/Server/Online.luau` | **new** — queue, private codes, pick, two-human duel, per-viewer packets, leave/forfeit/dispose, Studio summary |
| `src/Shared/OnlineProtocol.luau` | **new** — pick time, code alphabet/length, lobby and combat allowlists |
| `src/Server/Matches.luau` | `act` (shared validated input), `view` (per-viewer snapshot), `roundOver`/`resetRound` (shared rounds), online routing in `request`/`update`/`remove`/`selection`, `laneOrigin`, refused-input counters |
| `src/Server/DevHooks.luau` | debug/QA only: request latency simulator, `lag` and `online` ops |
| `src/Client/UI.luau` | online row, waiting overlay, versus pick on the roster, opponent name, rematch/forfeit states |
| `src/Client/Presentation.luau`, `Camera.luau`, `Effects.luau`, `Main.client.luau` | opponent resolved by `data.bot.id`; menu orbit for queue/pick |
| `tests/Online.spec.luau` | **new** — 17 cases; registered in `tests/run.sh` and `build.py` |
| `dist/*` | rebuilt (normal, debug, QA) |

Not touched: `docs/active/*` (integration by the lead). `motion-lab/dist/manifest.json`
records the `src` tree hash as provenance only; it follows on the next Lab build.

## 4. Headless tests (`tests/Online.spec.luau`, 17 cases)
Queue pairing and refusal of bad entries; private code (wrong / numeric / oversized
/ own / consumed / cancelled); pick change, confirm, timer; two human actors and no
AI; per-viewer `human`/`bot` and opponent rig by `bot.id`; B's inputs drive only B,
client fields never write state, per-player idle rule; no AI acts for an idle
player; anti-cheat timestamps and rate state, epochs, bounded vectors and aim,
token buckets per player, refused-input counters; only combat requests reach
`Combat` mid-fight; mechanics through both players' requests (§2.5); rounds, KO
beat and result mapped per viewer; `Ready` resync in every online phase; rematch;
leave / disconnect in queue, host, pick, fight and result, lane reuse; decided KO
kept when its winner disconnects; local AI duel on the shared helpers; latency
simulator order and pass-through; the real UI rendering roster, queue, pick, duel,
result, forfeit and AI packets with simulated clicks. Every packet's epoch is
checked to never go backwards. Deliberate mutations of the main rules (per-viewer
swap, dispose, forfeit, code reuse, allowlist, anti-cheat, aim range, lock-on, lane
leak, winner mapping, idle rule, resync, epoch start, UI states) all fail the
suite; the only survivors were equivalent rewrites (redundant defensive epoch
`max`, an equivalent update guard).
These cases prove server lifecycle and authority, not replication, physics or feel.

## 5. Two clients in Studio (checklist for the next native session)
Open `dist/NinjaDuel-Debug.rbxlx` (has the latency tools; `NinjaDuel.rbxlx` works
for a plain test). Test tab ▸ Clients and Servers ▸ Local Server, 2 players ▸ Start.
1. Both windows show the roster with the online row. Client 1: pick a fighter ▸
   ONLINE DUEL ▸ "SEARCHING FOR AN OPPONENT". Client 2: ONLINE DUEL ▸ both switch
   to the versus pick (opponent name, opponent's fighter on the right, countdown).
2. Change fighter on one side: the other sees it. READY on both (or wait 15 s).
3. Fight: each client controls only its own fighter; camera, HUD (opponent name
   instead of AI), intro, combo counters and cues are from each own side.
4. Check on the server (command bar): `Players.Player1.Character` and
   `Players.Player2.Character` are `Duelist1` / `Duelist2` under
   `workspace.NinjaDuels.Online_<lane>`, and both
   `…HumanoidRootPart:GetNetworkOwner()` return `nil`.
5. Exercise: blades both ways, guard/parry, substitution after a hit, Minato seal +
   FTG (both clients see the teleport), Itachi genjutsu decoy only on the fooled
   side, wall run/splat, launcher + chase, grab + throw break, clash, awakening.
6. Two knockouts: VICTORY on one window, DEFEAT on the other, scores mirrored.
   REMATCH on one ("WAITING FOR OPPONENT…"), then on the other: fresh fight.
7. Private: HOST PRIVATE DUEL ▸ code shown ▸ the other types it ▸ JOIN.
8. Leaving: LEAVE in the pick (other back to roster with "OPPONENT LEFT"); close a
   client mid-fight (other: "VICTORY • FORFEIT"); RETURN TO THE ROSTER from the result.
9. AI mode on both clients still works exactly as before (ENTER THE STAGE, TRAINING).
Server state at any time: `game.ServerStorage.NinjaDuelDev:Invoke("online")`.

## 6. Latency testing
Two halves, because Studio's own lag setting only affects what a client receives:
- **Server → client**: Studio ▸ File ▸ Studio Settings ▸ Network ▸ *Incoming
  Replication Lag* (seconds). It delays everything the test clients receive
  (physics replication and remotes), has no jitter, and must be set before Start.
  If the installed Studio offers a newer network emulation panel (latency, jitter,
  loss), use it instead; check the exact menu in that version.
- **Client → server (debug/QA places only)**: `DevHooks.delayRequests` holds each
  player's requests for `NinjaDuelSimLatency` ms ± `NinjaDuelSimJitter` ms, in
  order, like a slow reliable remote. Set on the server:
  `game.ServerStorage.NinjaDuelDev:Invoke("lag", 55, 20)` or
  `workspace:SetAttribute("NinjaDuelSimLatency", 55)`; `("lag", 0, 0)` turns it off.
  The module is excluded from the normal build (`build.py` debug sources;
  `test_build_isolation.py` asserts `DevHooks` is absent from `NinjaDuel.rbxlx`).

| Case | Incoming Replication Lag | `lag` (ms, ± jitter) | ≈ round trip |
|---|---|---|---|
| Baseline | 0 | 0, 0 | 0 ms |
| Typical | 0.030 | 30, 0 | ~60 ms |
| Long | 0.055 | 55, 0 | ~110 ms |
| Jitter | 0.055 | 55, 20 | ~110 ms ± 20 on inputs |
| Stress | 0.100 | 150, 50 | ~250 ms — stale-input refusals expected |

Record per case: own-movement delay (press → visible), strike/jump start delay,
guard and parry success on a known rhythm, substitution inside its window, FTG and
substitution readability on the *other* client, projectile visual vs damage,
throw-break success, clash frequency, and `refusedInputs` / `refusedAge` per seat
from `Invoke("online")` (refusals with an age near 0.3 s mean the anti-cheat
window, not the player, dropped the press).

Timing facts for reading the results: the client sends movement every 80 ms;
snapshots go out every 66 ms plus an immediate packet on contacts (≥ 30 ms apart);
bodies are drawn on a ~45 ms interpolation track, projectiles 60 ms behind server
time; the anti-cheat accepts a press stamped up to 50 ms in the future and 300 ms
in the past. Windows that latency shrinks by about one round trip + 45 ms: parry
0.20 s, perfect dodge ~0.13 s, substitution 0.42 s after a hit, wall tech
0.05–0.34 s, throw break 0.35 s, clash 0.07 s.

## 7. Prediction: not now (decision)
Not implemented. Rigs are server-owned and simulated by the server's Motor and
parkour donor; predicting the local fighter means running that movement on the
client and reconciling corrections, and predicting a strike means rolling back
refused presses. Without measurements this risks visible snaps worse than the delay
it hides, and the mission ties prediction to latency evidence (MOV-006). The server
stays the only authority; nothing in this branch changes that.
Order proposed once §6 has numbers: (1) send movement on direction change, not
only every 80 ms (up to 80 ms saved, bucket headroom to check); (2) presentation
anticipation on press (start the local wind-up pose, cancel if refused, server
unchanged); (3) lag-aware windows: judge defensive windows (substitution, parry,
throw break, wall tech) at the press `clientTime`, bounded by the 0.3 s anti-cheat
window, and rewind melee checks with the existing 0.3 s position history; (4) only
then local movement prediction with reconciliation behind a flag.

## 8. Risks
1. **Anti-cheat clock window** (−50 ms / +300 ms) can refuse real presses on jittery or
   asymmetric connections. Counters added; widen only on evidence.
2. **Latency shrinks defensive windows** (§6) and there is no lag compensation yet:
   the defender is favoured; online duels will feel harder to defend above ~100 ms.
3. **Update order**: seat 1 is stepped before seat 2 each frame (as player before AI);
   two strikes going active on the same frame without facing each other trade in
   seat 1's favour. The clash rule covers facing exchanges; alternating the order is a
   cheap follow-up if it shows up.
4. **Network ownership** is asserted, not observed: verify step 5.4 in Studio.
5. Hidden fighters (Gaara) are accepted if a crafted client asks, like the AI mode.
6. No reconnection: a disconnect forfeits; a rejoin starts from the roster.
7. Queue and codes are per server (no cross-server matchmaking).
8. Each viewer gets the full snapshot (two per duel): bandwidth per duel doubles
   compared to an AI duel. The combat debug overlay and inspector cover local duels only.
9. Private codes are typed on keyboard; the pad flow is casual queue only.

## 9. What remains
- Native: §5 and §6 on this artifact, then MOV-006 decision.
- Prediction / reconciliation and lag-aware windows as ordered in §7 (MOV-006, NET-002).
- **Ranked hooks for PROG-002**: queue entries already carry the validated pick;
  add a `bracket` (SP budget) to the entry, keep one FIFO per bracket in
  `Online:enter`, validate the active build server-side against the bracket before
  enqueueing (Codex `29a9ec1` profile/progression to audit), pass `mode="ranked"` to
  `Online:pair`, report the result from the duel's Result transition (forfeit = loss)
  to the rating store. Casual and private stay budget-free.
- Reconnect grace window instead of an instant forfeit; cross-server matchmaking
  (MemoryStore) when there is traffic; online coverage in the debug inspector.
