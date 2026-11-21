#!/usr/bin/env bash
# Run every headless Ninja Duel suite. Works from the repository root or from
# games/ninja-duel. Exit code is non-zero if any suite fails.
set -uo pipefail
cd "$(dirname "$0")/.."

TOOLS=${NINJA_DUEL_TOOLS:-/private/tmp/ninja-duel-tools}
LUAU=${LUAU:-$TOOLS/luau}
LUNE=${LUNE:-$TOOLS/lune}
# (20/11) where tests/install_tools.sh puts them
command -v "$LUAU" >/dev/null 2>&1 || { [ -x "$HOME/.ninja-duel-tools/luau" ] && LUAU=$HOME/.ninja-duel-tools/luau; }
command -v "$LUNE" >/dev/null 2>&1 || { [ -x "$HOME/.ninja-duel-tools/lune" ] && LUNE=$HOME/.ninja-duel-tools/lune; }
command -v "$LUAU" >/dev/null 2>&1 || LUAU=$(command -v luau || true)
command -v "$LUNE" >/dev/null 2>&1 || LUNE=$(command -v lune || true)
if [ -z "${LUAU:-}" ] || [ -z "${LUNE:-}" ]; then
  echo "luau and lune are required; set LUAU / LUNE or install both" >&2
  exit 2
fi

status=0
run() {
  local label=$1; shift
  local output
  if output=$("$@" 2>&1); then
    printf '%-12s PASS  %s\n' "$label" "$(printf '%s\n' "$output" | tail -1)"
  else
    status=1
    printf '%-12s FAIL  %s\n' "$label" "$(printf '%s\n' "$output" | tail -1)"
    printf '%s\n' "$output" | grep -E '^(FAIL|.*Error)' | head -5
  fi
}
run Rules      "$LUAU" tests/Rules.spec.luau
run Input      "$LUNE" run tests/Input.spec.luau
run Combat     "$LUNE" run tests/Combat.spec.luau
run Sequences  "$LUNE" run tests/Sequences.spec.luau
run CameraFeel "$LUNE" run tests/CameraFeel.spec.luau
run FeelPress  "$LUNE" run tests/FeelPress.spec.luau
run Regression "$LUNE" run tests/Regression.spec.luau
run Feedback   "$LUNE" run tests/Feedback.spec.luau
run Animation  "$LUNE" run tests/Animation.spec.luau
run Locomotion "$LUNE" run tests/Locomotion.spec.luau
run BodyRange  "$LUNE" run tests/BodyRange.spec.luau
run Film10Feet "$LUNE" run tests/Film10Feet.spec.luau
run AwakenFX "$LUNE" run tests/AwakenFX.spec.luau
run LightBudget "$LUNE" run tests/LightBudget.spec.luau
run Lightning "$LUNE" run tests/Lightning.spec.luau
run Sharingan "$LUNE" run tests/Sharingan.spec.luau
run Toad "$LUNE" run tests/Toad.spec.luau
run Models "$LUNE" run tests/Models.spec.luau
run OutfitMeshes "$LUNE" run tests/OutfitMeshes.spec.luau
run FaceCam    "$LUNE" run tests/FaceCam.spec.luau
run Shadow "$LUNE" run tests/Shadow.spec.luau
run Movement   "$LUNE" run tests/Movement.spec.luau
run CombatFeel "$LUNE" run tests/CombatFeel.spec.luau
run Engagement "$LUNE" run tests/Engagement.spec.luau
run Look "$LUNE" run tests/Look.spec.luau
run Stage "$LUNE" run tests/Stage.spec.luau
run AIVariety "$LUNE" run tests/AIVariety.spec.luau
run HudText "$LUNE" run tests/HudText.spec.luau
run Leftovers "$LUNE" run tests/Leftovers.spec.luau
run Appearance "$LUNE" run tests/Appearance.spec.luau
run Avatar "$LUNE" run tests/Avatar.spec.luau
run SyphoRig  "$LUNE" run tools/syphodev/rig_dump.luau --check tools/syphodev/rig.json
run SyphoLint python3 tools/syphodev/lint_src.py
run SyphoClips env LUNE="$LUNE" python3 tools/syphodev/audit_clips.py --gate
run Masters "$LUNE" run tests/Masters.spec.luau
run MastersView "$LUNE" run tests/MastersView.spec.luau
run Trees "$LUNE" run tests/Trees.spec.luau
run Hub "$LUNE" run tests/Hub.spec.luau
run Shop "$LUNE" run tests/Shop.spec.luau
run Weapons    "$LUNE" run tests/NinjaWeapons.spec.luau
run Daily      "$LUNE" run tests/DailyQuests.spec.luau
run Exam       "$LUNE" run tests/Exam.spec.luau
run Codes      "$LUNE" run tests/Codes.spec.luau
run VillageDuel "$LUNE" run tests/VillageDuel.spec.luau
run Ranked     "$LUNE" run tests/Ranked.spec.luau
run NinjaTree  "$LUNE" run tests/NinjaTree.spec.luau
run NinjaArts  "$LUNE" run tests/NinjaArts.spec.luau
run FirstCombat "$LUNE" run tests/FirstCombat.spec.luau
run Solo     "$LUNE" run tests/Solo.spec.luau
run KitTexts   "$LUNE" run tests/KitTexts.spec.luau
run PlayTexts  "$LUNE" run tests/PlayTexts.spec.luau
run HubLayout "$LUNE" run tests/HubLayout.spec.luau
run KonohaLayout "$LUNE" run tests/KonohaLayout.spec.luau
run MeritAura "$LUNE" run tests/MeritAuraFX.spec.luau
run Infusions "$LUNE" run tests/InfusionFX.spec.luau
run StyleFX "$LUNE" run tests/StyleFX.spec.luau
run Loop       "$LUNE" run tests/Loop.spec.luau
run Outfit "$LUNE" run tests/Outfit.spec.luau
run Spacing "$LUNE" run tests/Spacing.spec.luau
run StepSpeeds "$LUNE" run tests/StepSpeeds.spec.luau
run ReactionSides "$LUNE" run tests/ReactionSides.spec.luau
run Travel "$LUNE" run tests/Travel.spec.luau
run Embodiment "$LUNE" run tests/Embodiment.spec.luau
run Fluidity   "$LUNE" run tests/Fluidity.spec.luau
run Control    "$LUNE" run tests/Control.spec.luau
run Branches   "$LUNE" run tests/Branches.spec.luau
run ComboModel "$LUNE" run tests/ComboModel.spec.luau
run Phase4     "$LUNE" run tests/Phase4.spec.luau
run Neji       "$LUNE" run tests/Neji.spec.luau
run Identity   "$LUNE" run tests/Identity.spec.luau
run Systems    "$LUNE" run tests/Systems.spec.luau
run Tools      "$LUNE" run tests/Tools.spec.luau
run Chakra     "$LUNE" run tests/Chakra.spec.luau
run ChakraFlow "$LUNE" run tests/ChakraFlow.spec.luau
run Seals      "$LUNE" run tests/Seals.spec.luau
run Lobby      "$LUNE" run tests/Lobby.spec.luau
run Tournament "$LUNE" run tests/Tournament.spec.luau
run FirstMin   "$LUNE" run tests/FirstMinute.spec.luau
run AirCombat  "$LUNE" run tests/AirCombat.spec.luau
run Sasuke     "$LUNE" run tests/Sasuke.spec.luau
run Gaara      "$LUNE" run tests/Gaara.spec.luau
run Lee        "$LUNE" run tests/Lee.spec.luau
run Naruto     "$LUNE" run tests/Naruto.spec.luau
run Kakashi    "$LUNE" run tests/Kakashi.spec.luau
run Temari     "$LUNE" run tests/Temari.spec.luau
run Roster     "$LUNE" run tests/Roster.spec.luau
run Roster20   "$LUNE" run tests/Roster20.spec.luau
run Converge   "$LUNE" run tests/Convergence.spec.luau
run Online     "$LUNE" run tests/Online.spec.luau
run Progression "$LUNE" run tests/Progression.spec.luau
run Profiles   "$LUNE" run tests/Profiles.spec.luau
run Preparation "$LUNE" run tests/Preparation.spec.luau
run DevInfra   "$LUNE" run tests/DevInfra.spec.luau
run Entonnoir  python3 tools/analytics/test_entonnoir.py
run PlaceCommune python3 tools/mac/test_place_commune.py
run Empreinte  python3 tools/kits/test_empreinte.py
run KitPrint   "$LUNE" run tests/KitPrint.spec.luau
run Planche    python3 tools/tenues/test_planche.py
run Nodes      "$LUNE" run tests/Nodes.spec.luau
run NoeudsLus  python3 tools/kits/test_noeuds_lus.py
exit $status
