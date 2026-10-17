# Public alpha after roster 20

This is a product direction, not a request for launch polish.

Once the game has approximately 20 genuinely playable fighters at baseline quality and the core combat can run online, move toward a **public Roblox alpha / combat test** instead of waiting for final animations, VFX, balance, progression or presentation.

## Goal

Publish early enough that the project starts being developed against a real online product rather than only Studio/local assumptions.

The alpha may still have rough animations, imperfect combos, unfinished VFX, incomplete chakra interactions and incomplete polish. That is acceptable if the core session is stable enough to be played by strangers.

## Minimum public-alpha loop

A player must be able to:

1. join the public experience;
2. enter matchmaking / find an opponent;
3. choose a playable fighter;
4. start an actual server-backed duel;
5. complete the match;
6. rematch or return to matchmaking;
7. leave/rejoin without corrupting the session.

The target is **real Roblox online play**, not merely a two-player local Studio test. Local multi-client tests and simulated latency remain useful technical steps, but they do not count as the online product being validated.

## Before public access

Do not wait for final quality, but ensure at least:

- no common session-destroying crash/state lock;
- server-authoritative combat is sufficiently stable;
- basic disconnect/rage-quit handling;
- no unsafe or destructive persistence behavior;
- a simple player-facing way to report bugs/feedback;
- basic telemetry where practical: fighter choice, match duration/result, disconnect/abandon, rematch, server errors.

Do not block publication on premium-quality VFX, final balance, full progression, final arena art or full monetization.

## Monetization

Treat this first release as an **EARLY ALPHA / COMBAT TEST**. Do not make aggressive monetization a prerequisite for publication. Monetization can be added progressively once the real online loop is stable and worth returning to.

## Why this matters

The purpose of publishing early is to expose the game to conditions Studio cannot fully reproduce: real servers, real latency, unexpected player behavior, mashing, quitting, matchup abuse, misunderstood mechanics, balance outliers and rare state bugs.

Even a very small number of real players can produce higher-value feedback than continuing to refine the game exclusively in isolation.

## Relationship to roster-20 direction

The intended sequence is:

**20 baseline-playable fighters -> stable real online combat loop -> public alpha -> continue polishing the same live game.**

Do not interpret this as a request to stop the V1 convergence or rush a broken build live. It means that once those minimum gates are met, public online validation becomes part of development rather than something postponed until the end.
