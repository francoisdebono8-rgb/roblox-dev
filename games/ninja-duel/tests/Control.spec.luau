-- Release gate: a scripted pad player against the real AI for the eight main
-- fighters (tests/Control.sim.luau). Fails on a freeze (stick held, nothing
-- holding the body, no movement), a ghost airborne state on the floor, a state
-- stuck for 2 s, or more than 3.5% of presses eaten (refused just before the
-- body was free with nothing coming out). User 29/10: "je pouvais plus bouger".
_G.ControlGate={seconds=40}
require("./Control.sim")
