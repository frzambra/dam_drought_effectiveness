# Response to Nature Water review — Required Experiments / Analyses

Addresses the 9 items in `2026-06-28_nature-water-review.md` §"Required Experiments / Analyses".
Status per item: **DONE** (computed here), **PARTIAL** (partly done / method shown, refinement pending),
**DEFERRED** (needs new data or a separate build). Code: `src/R/causal/equivalence.R`. Numeric
outputs: `results/tables/table_equivalence.csv`.

## #1 Equivalence tests / minimum-detectable-effect — DONE (the #1 blocker)

For each headline slope-gap null we computed the permutation-null distribution (treatment permuted
within Köppen × aridity-tercile strata) and the MDE = $(z_{0.975}+z_{0.8})\times \mathrm{SD}_{\text{perm}}$,
with the equivalence margin set to 25% of the baseline deficit→impact transmission slope.

| outcome | observed gap | baseline slope | MDE (abs) | MDE as % of baseline | p_perm |
|---|---:|---:|---:|---:|---:|
| streamflow SSI (ITT) | −0.183 | 0.585 | 0.268 | **46%** | 0.39 |
| streamflow SSI (downstream) | −0.165 | 0.531 | 0.312 | **59%** | 0.48 |
| irrigated area (DiD) | +0.001 | ≈0 | 0.010 | (baseline≈0) | 0.90 |
| orchard ET (DiD) | −0.020 | 0.019 | 0.046 | 237% | 0.25 |

**Honest reading — this partly concedes the reviewer and bounds it.** The design can exclude only
*large* reservoir buffering: for streamflow it can detect attenuation of the deficit→streamflow
transmission only if it exceeds **~46–59%**. Moderate buffering (e.g. the 25% margin) is **NOT**
excluded — no outcome is statistically equivalent to zero at that margin. So the defensible claim is
"we can rule out reservoir buffering larger than ~½ the natural transmission," **not** "there is no
effect." This is exactly the distinction the reviewer demanded, and it means the manuscript must
state the nulls as bounded equivalence, not absence.

*Caveat (drives #7):* at ~17–24 treated clusters the permutation null is lumpy/heavy-tailed — a
slope-gap of −0.18 arises in 39% of random treatment relabelings — so the SD-based MDE is
approximate and likely optimistic. `p_perm` is the authoritative inference; a simulation-based power
curve (#7) is the refinement.

## #5 Quantify the siting confound — DONE (and it reframes the mechanism)

Estimator ladder for the streamflow slope-gap on the same panel:

| estimator | slope-gap | se |
|---|---:|---:|
| naive (no match, no FE) | −0.197 | 0.090 |
| unit + time FE (unweighted) | −0.165 | 0.075 |
| design (ebal weights + FE) | −0.183 | 0.083 |

**Matching on observed covariates does NOT dissolve the apparent buffering** (−0.20 → −0.18; the
signal is *not* carried by aridity/Köppen/elevation/area). The confound is therefore an **unobserved
basin trait**, and the **upstream-of-dam placebo is what exposes it**: the regulation-attributable
component is downstream − upstream = −0.165 − (−0.201) = **+0.04 ≈ 0**. Quantified: the spurious
apparent buffering is ≈ −0.20 (≈ 34% of the natural transmission slope), of which **≈ 100% is siting
and ≈ 0 is the reservoir**. This both delivers the magnitude the reviewer asked for and *strengthens*
the reviewer's point #4 (observed-covariate matching is insufficient; the placebo, not the matching,
carries the identification).

## #7 Simulation-based power for the permutation test — PARTIAL

The MDE above is the analytic (SD-based) version. Because the permutation null is heavy-tailed, the
rigorous version injects a known effect δ·SPEI into treated units, re-runs the permutation test over a
grid of δ, and reads off the δ at 80% rejection. Method is implemented-ready (reuse
`perm_null_dist` with a shifted outcome); not yet run as a grid. Expected to give an MDE **≥** the
analytic one, reinforcing the "underpowered for tight equivalence" conclusion.

## #6 Unobserved-confounding sensitivity (E-value / Rosenbaum) — PARTIAL

E-values are defined for *non-null* estimates; the headline contrasts are null, so the relevant
sensitivity question is inverted ("how large an unobserved confounder would be needed to *hide* a real
buffer?"), which is exactly what the MDE (#1) bounds. For the few *surviving* cross-sectional
positives (the natural-cover aridity²-residual; the orchard-ET aridity placebo significance) a
Rosenbaum/E-value bound is appropriate and is proposed. Note the upstream placebo already functions as
a strong design-based sensitivity check (a real regulation effect should not appear above the dam).

## #2 Extend streamflow through 2024 — DEFERRED (needs data)

CR2 `qflxDaily_2020` ends 2020-03, missing the deepest 2019–2024 megadrought — the tail regime where
buffer-collapse would show. Requires acquiring updated discharge (CR2 refresh / DGA real-time
`snia.mop.gob.cl` / modelled or altimetric discharge). Until then the streamflow null is explicitly
scoped to "through the onset of the deepest megadrought years." **Action: acquire post-2020 discharge.**

## #3 Naturalized-inflow mass-balance counterfactual — DEFERRED (separate build, partly feasible)

The most direct regulation test: regulated outflow vs naturalized inflow = ΔStorage + outflow
(+ ET + seepage). Feasible in principle for the subset of reservoirs with a monthly storage series
**and** a downstream gauge (we have both for several units), modulo unit/area reconciliation
(storage hm³ → flux; gauge m³/s → monthly volume) and ignoring ET/seepage. This is the operations-side
evidence Nature Water will want and the single highest-value next build. **Action: pair storage units
to downstream gauges and reconstruct inflow for the feasible subset.**

## #4 Routed-network validation of up/down-dam classification — DEFERRED (new infra)

The upstream placebo is load-bearing, and up/down is currently a DEM-elevation proxy (no routed
network). Needs HydroSHEDS / flow-accumulation routing to confirm gauges are truly on the regulated
reach, plus a sensitivity analysis showing the placebo survives plausible reclassification.
**Action: route gauges + dams on HydroSHEDS; re-run placebo.**

## #8 ET cross-product check (PML_V2 / OpenET) — DEFERRED (new data)

MOD16 under-estimates irrigated ET (range compression), so the ET-buffering null is partly a
sensor-saturation null. A PML_V2 / OpenET / ECOSTRESS cross-check would confirm it. **Action: acquire
a second ET product.**

## #9 Pre-registration-style analysis-decision appendix — PARTIAL (documentation)

The decision tree (estimands, SPEI timescales, lags, masks, strata, inference) is recoverable from
the dated progress summaries + `docs/hypotheses/`. It should be consolidated into one appendix
distinguishing a-priori from post-hoc tests before submission. Most explorations returned nulls
(mitigating fishing), but the few survivors need explicit a-priori/post-hoc labeling.

---

## Bottom line for the manuscript
- The two self-contained blockers are addressed: equivalence/MDE (#1) and the quantified siting
  confound (#5). The honest result is **bounded equivalence** ("rule out buffering > ~46–59% of
  natural transmission"), not zero, and a clean decomposition showing **~all apparent streamflow
  buffering is siting (unobserved basin trait), ~0 is regulation** — with the upstream placebo, not
  the covariate matching, doing the identification.
- The remaining items split into **new-data** (#2 post-2020 discharge, #8 second ET product) and
  **new-build** (#3 naturalized inflow — highest value; #4 HydroSHEDS routing; #7 power simulation;
  #6 Rosenbaum on survivors; #9 appendix). Recommended order: #3 → #2 → #7 → #4 → #6/#8/#9.
