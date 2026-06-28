# Progress summary — 2026-06-28 (H1 storage-rectifier test)

**Focus:** test the OTHER main-thesis hypothesis, **H1 — reservoir as nonlinear storage rectifier**
(attenuate small droughts, but past a storage-depletion threshold s* transmit an amplified,
tail-loaded signal → heavier-tailed severe ecological drought in dammed vs control basins). Design
by `drought-propagation-analyst` (`.claude/agent-memory/.../h1-test-design.md`). Three claims: C1 s*
exists; C2 variance redistributed INTO the tail (novel); C3 heavier upper-tail severity dammed vs
control. Build: `src/R/drought/storage_rectifier.R`.

## Data
Monthly **zcNDVI-6** severity (sev = −zcNDVI6) vs monthly **SPEI-12/-3** forcing, 2000–2024, matched
21 dammed / 236 control subcuencas (75,303 unit-months). Storage fraction (treated-only) for the
within-treated threshold. Annual zNPP had too few extremes for tail estimation — monthly is essential.

## Result — H1's strong/novel claims are NOT supported under proper inference

| test | statistic | verdict |
|---|---|---|
| **C3 quantile tail contrast** (treat τ0.95 − τ0.50) | **+0.058**, but **permutation p = 0.45** | NS — few-clusters artifact |
| **C3 GPD tail shape** | ξ_treated **−0.54** vs ξ_control **−0.35** | **opposite to H1** (treated tail *more* bounded) |
| **C1 threshold** | s* ≈ 0.30 (6-mo lag); SPEI→sev slope −0.40 below vs −0.23 above | weak: transmission steepens when storage low |
| **C2 variance-into-tail** (novel) | var ratio below/above = 0.93; Levene p = 0.49 | **falsified** — no tail-loading |
| counterfactual overshoot | below-s* +0.11 > natural-forcing pred, p≈0 | over-rejects (unclustered month-level t-test); suggestive only |

- The headline QR tail contrast (+0.058, the H1-direction "median buffered, tail amplified" pattern)
  **does not survive randomization inference** across the ~21 treated clusters (p_perm 0.45) — the same
  cluster-structure lesson that killed the H2 DiD's nominal significance.
- The **GPD shape contrast runs the wrong way** (treated ξ more negative = lighter/more-bounded tail),
  directly against C3's heavier-tail prediction.
- The **novel C2 variance-redistribution claim is falsified** (no excess conditional variance below s*).
- There IS a weak, sensible within-treated mean signal — drought transmits more strongly when storage
  is low (slope −0.40 below s* vs −0.23 above; overshoot worse below s*) — consistent with "buffering
  attenuates and then weakens as the reservoir empties," but NOT the rectifier's tail-amplification.

## Bottom line
**Both main hypotheses' strong claims fail under proper inference.** H2 (induced-demand vulnerability)
is a convergent null; H1 (rectifier tail-amplification) is unsupported — the apparent tail signal is a
few-clusters artifact and the tail-shape contrast is anti-H1. The defensible reading: reservoirs
neither demonstrably amplify nor (beyond the mean) demonstrably buffer drought transmission in a way
separable from siting + baseline aridity, given this design. The recurring methodological lesson —
apparent signals (QR +0.058; overshoot p≈0) evaporate or become uninterpretable once the ~21-cluster
structure is respected — is itself the contribution.

## Caveats
- **Power**: treated GPD has only ~598 exceedances across 21 units; tail tests are low-powered, so C3
  is "no robust evidence," not high-power refutation.
- The proper H1 test needs **streamflow** (regulated vs naturalized drought attenuation) and
  **reservoir operating rules** (to argue s* is physical, not policy) — both GATED.
- The C1 mean-slope threshold (steeper transmission at low storage) is real and worth reporting as a
  modest "buffering-while-full" finding, distinct from the failed tail claim.

## Files
- `src/R/drought/storage_rectifier.R` (new): `zcndvi_monthly_paths`, `extract_unit_index_monthly`,
  `build_severity_panel`, `build_treated_storage_panel`, `fit_tail_quantreg`, `tail_contrast(_fast)`,
  `fit_gpd_tail`, `permute_tail_stat` (parallel), `fit_storage_tar`, `overshoot_test`.
- `targets/_targets.R`: monthly panels (`zc6_monthly`, `spei12_monthly`, `spei3_monthly`,
  `severity_panel`, `treated_storage_panel`) + H1 tests (`h1_quantreg`, `h1_tail_contrast`, `h1_perm`,
  `h1_gpd`, `h1_tar`, `h1_overshoot`); packages `quantreg`, `extRemes`.

## H5 — post-drought RECOVERY enhancement (evaluated + gate-tested 2026-06-28)

`hypothesis-challenger` evaluated a NEW hypothesis (dammed basins REBOUND faster than controls;
agent-memory `h5-recovery-enhancement.md`). Sharpest identifiable estimand given the persistent
megadrought: onset/recovery ASYMMETRY = triple interaction `treat:spei12:rising` on monthly zcNDVI-6
(unit + year-month FE, ebal weights; rising = 1{ΔSPEI12 > 0}); decisive falsifier = natural-cover-only
split; honest prior ~15-20% survival. Cheap gate test (scratch, on cached `severity_panel`):

| term | estimate | t | cluster p |
|---|---:|---:|---:|
| `spei12:treat` (overall transmission) | +0.259 | 4.37 | ~0 |
| **`spei12:rising:treat` (H5 recovery asymmetry)** | **−0.021** | −1.42 | **0.16** |

H5 predicts POSITIVE; observed is **wrong-signed and NS** — dammed basins respond slightly *less* to
improving SPEI on the recovery limb. No positive signal to even pass to the natural-cover falsifier;
permutation (strictly more conservative) was unnecessary. The `spei12:treat` = +0.26 is cluster-robust
over-rejection of the same forcing-transmission slope that collapses under permutation/aridity (not new).

**H1, H2, and now H5 all fail under proper inference** — the reservoir signal keeps reducing to
siting + baseline aridity + cropland phenology. (H5 gate test is a scratch script, not yet a target;
wire it if the recovery angle is pursued — e.g. on its proper outcome once streamflow is acquired.)

## Next
1. H1 figure (QR coefficient-by-τ fan + GPD tails) for the supplement, framed as the tail-null.
2. The modest C1 "buffering-while-full" mean-threshold could anchor a tempered H1 sub-result.
3. Acquire streamflow / operating rules to test H1 on its proper (availability) outcome.
