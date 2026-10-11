#!/usr/bin/env bash
# Run an explicit Markdown mission in a dedicated checkout, never on the base branch.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(git -C "$script_dir" rev-parse --show-toplevel)
base=codex/forge-motion-lab-ui-edit
mission_arg=${1:-games/ninja-duel/KIMI_MOTION_QUALITY_PASS.md}
if [[ $# -gt 1 || "$mission_arg" == --help || "$mission_arg" == -h ]]; then
  printf 'Usage: %s [mission.md]\nKIMI_MOTION_INTERACTIVE=1 opens the TUI; default executes the mission autonomously.\n' "$0"
  exit 0
fi
command -v kimi >/dev/null || { printf 'Install official CLI: npm install -g @moonshot-ai/kimi-code\n' >&2; exit 1; }
command -v python3 >/dev/null || { printf 'python3 is required to resolve the mission safely.\n' >&2; exit 1; }
# Accept a repo-relative path, a game-relative path, or an absolute path INSIDE the repo.
mission=$(python3 - "$repo" "$mission_arg" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve();arg=Path(sys.argv[2])
candidates=[arg] if arg.is_absolute() else [root/arg,root/'games/ninja-duel'/arg]
for candidate in candidates:
    p=candidate.resolve()
    if p.is_file() and p.suffix.lower()=='.md' and p.is_relative_to(root):
        print(p.relative_to(root));break
else: raise SystemExit('Mission must be an existing Markdown file inside this repo.')
PY
)
git -C "$repo" cat-file -e "$base:$mission" || { printf 'Commit the mission on %s first.\n' "$base" >&2; exit 1; }
slug=$(basename "$mission" .md | tr '[:upper:]_' '[:lower:]-' | sed 's/[^a-z0-9-]/-/g;s/^kimi-//;s/-pass$//')
branch=${KIMI_MOTION_BRANCH:-codex/kimi-$slug}
[[ "$branch" == codex/kimi-* ]] || { printf 'Kimi branch must start with codex/kimi-.\n' >&2; exit 1; }
git check-ref-format --branch "$branch" >/dev/null
common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)
repo_id=$(python3 -c 'import hashlib,sys;print(hashlib.sha256(sys.argv[1].encode()).hexdigest()[:12])' "$common")
checkout="$HOME/.local/share/kimi-motion/worktrees/$repo_id/${branch#codex/}"
export KIMI_CODE_HOME="${KIMI_CODE_HOME:-$HOME/.kimi-code}"
python3 - "$KIMI_CODE_HOME" "$repo" "$checkout" <<'PY'
from pathlib import Path
import sys
home=Path(sys.argv[1]).expanduser().resolve()
for path in sys.argv[2:]:
    if home.is_relative_to(Path(path).resolve()):
        raise SystemExit('KIMI_CODE_HOME must stay outside the repository/worktree.')
PY
if [[ -e "$checkout" ]]; then
  actual=$(git -C "$checkout" branch --show-current)
  [[ "$actual" == "$branch" ]] || { printf 'Checkout is on another branch; refusing.\n' >&2; exit 1; }
  [[ "$(git -C "$checkout" rev-parse --path-format=absolute --git-common-dir)" == "$common" ]] || { printf 'Checkout belongs to another repository; refusing.\n' >&2; exit 1; }
else
  mkdir -p "$(dirname "$checkout")"
  if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$repo" worktree add "$checkout" "$branch"
  else
    git -C "$repo" worktree add -b "$branch" "$checkout" "$base"
  fi
fi
[[ -f "$checkout/$mission" ]] || { printf 'Mission missing in dedicated checkout; refusing.\n' >&2; exit 1; }
cd -- "$checkout"
printf 'Kimi branch: %s\nCheckout: %s\nMission: %s\n' "$branch" "$checkout" "$mission"
prompt="Execute the Markdown mission below completely in this checkout. Read AGENTS.md and the relevant existing Motion Lab modules/README. You are the visible-motion specialist, not an infrastructure designer.

Stay on branch $branch. Never change another checkout, switch to a stable branch, merge, or modify the live Ninja Duel runtime. Preserve existing Motion Lab functionality and data-driven editability. Never read, print, copy or commit credentials/API secrets. Authentication and sessions belong only in the external KIMI_CODE_HOME, never in the repo.

Use actual readable visual references (video frames/screenshots, anime/game footage); link the exact sources and honestly label extrapolation. Minimum benchmark: Neji, Lee, Itachi, Gaara, each idle + walk/run/strafe, five improved strikes, three useful transitions, all editable in Motion Lab. Preserve old profiles for a clear old/new comparison. Do not stop after writing a plan or a few tunings. Implement, build and run targeted checks (python3 games/ninja-duel/motion-lab/build.py; tools in /private/tmp/ninja-duel-tools). Do not take over the whole screen or repeatedly open Studio. Human visual review follows delivery; do not invent a native visual PASS. Do not install the plugin over the user's working copy during development.

When finished, commit the actual improvements on this branch, write a short motion/reference/limitations report and exact old/new preview instructions. Leave a clean checkout. Do not push or publish automatically.

Mission file: $mission

$(cat -- "$checkout/$mission")"
if [[ ${KIMI_MOTION_INTERACTIVE:-0} == 1 ]]; then
  printf 'Interactive mode: paste the mission path and execute it after /login, if needed.\n'
  exec kimi
fi
exec kimi -p "$prompt"
