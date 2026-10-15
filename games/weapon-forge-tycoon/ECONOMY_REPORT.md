# Economy — finishing pass

The executable simulation uses production Actions/Economy/Profile/Odds modules over five random seeds, with checkpoints at 10 min, 30 min, 1 h, 3 h and 10 h. Exact output: `qa/final-automated.txt`.

Assumptions: active free player, three successfully timed hammer hits, four seconds to choose an outcome, 16/18/20 seconds travel when another collection batch is needed, first four above-Common items displayed, other production sold to NPC, a limited upgrade budget, save toward zones, prestige when eligible. No paid boosts, offline revenue jumps or invented market buyers. The simulation does not predict player demand, retention or fun. It is an optimistic active-play balance check; actual movement/timing mistakes can slow progress.

| Milestone | Five-seed result |
|---|---|
| 10 minutes | 45 weapons, 964–1,745 Coins, Zone 2 visible |
| First Magma Quarry | 12.9–16.8 minutes |
| First Arcane Ruins | 30.2–35.5 minutes |
| First prestige | 46.8–52.8 minutes |
| 3 hours | 4 prestiges, about 761–765 weapons |
| 10 hours | 15–16 prestiges, about 2,527–2,538 weapons |

A previous linear prestige model produced 73–90 prestiges at ten hours. The final model uses square-root diminishing benefits, capped permanent production at +100%, capped permanent luck at +30% rare weight and capped permanent speed modifier at +60%. Prestige cost is `150000 × (1 + 0.12 × prestige)`; initial pacing remains unchanged. Upgrades have exponential costs and strict maxima. No multiplicative permanent x50 chain.

Player prices are free choices from 1 to 100,000,000 Coins. The listing form initially shows twice NPC value as an editable asking price, not an estimate of demand or a guaranteed return. No suggested-perfect-price algorithm, synthetic transactions, fake sales or NPC market buyers. Market transfers existing earned Coins and destroys 8% (rounded up); seller receives the exact remainder, with an overflow wallet at the balance cap. Buying power is not multiplied by the Double Coins pass during settlement. Coin Pack grants are excluded from direct market spending.

Remaining post-launch evidence: real sale conversion, median listing age, returns, first-session exits and scarcity distribution. Tune from those signals; do not claim the simulated marketplace has real liquidity.
