# Release gate

- Rebuild and run `tools/verify_release.py`; confirm the binary and six script sources match.
- Run the 14 edit-mode Studio test groups. Check `tests/RESULTS.md` for actual execution evidence.
- Native rerun on 2026-09-27: 14 groups PASS; see `../../../docs/forge/forge-catalog-native-run.txt`. No benchmarked time-saving claim is made.
- Complete the new real-project captures in `MEDIA_PLAN.md`; older gray-scene images do not meet issue #12.
- Existing asset: **103958912217728**. Never create another JointForge asset. The commercial binary is unchanged; no binary re-upload is needed in this pass.
- If a future Studio update is necessary, explicitly select that existing asset and verify its ID before submitting. Stop if Studio cannot distinguish update from new asset.
- The user handles Creator Hub media/listing, distribution and pricing. No website changes in this task.
