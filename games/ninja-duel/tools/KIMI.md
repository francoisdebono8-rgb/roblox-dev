# Kimi motion missions

Official CLI: `npm install -g @moonshot-ai/kimi-code` (Node >=22.19).
Authentication: `kimi`, then `/login`, or `kimi login --region global` (same official
device flow). Credentials/sessions stay in `~/.kimi-code/`, never in Git.

From any folder, run `games/ninja-duel/tools/run-kimi-motion.sh` using its absolute
path if necessary. It reads `KIMI_MOTION_QUALITY_PASS.md` by default and creates/reuses
an external Git worktree on `codex/kimi-motion-quality`, based on
`codex/forge-motion-lab-ui-edit`. The active/stable checkout stays untouched.

Another committed mission: `./games/ninja-duel/tools/run-kimi-motion.sh games/ninja-duel/OTHER.md`.
Its branch is derived from the file name. Optional `KIMI_MOTION_BRANCH=codex/kimi-my-pass`.
The default `kimi --auto -p` executes the supplied mission without routine prompts;
it is restricted by the explicit mission, but is an autonomous agent, not a filesystem sandbox.

Commit a new mission on the base branch before launching. Existing dedicated worktrees
are reused as-is (no reset/clean). To bring in a changed brief/base later, update the
Kimi branch deliberately first. Kimi commits on its branch; review before integrating.
No automatic push/publication or replacement of the installed plugin.

Reopen an interactive session: `cd <checkout printed by launcher>; kimi -c`.
