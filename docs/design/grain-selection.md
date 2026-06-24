# Design decision: analysis grain (cuenca vs subcuenca)

**Date:** 2026-06-24
**Decision:** Use **subcuenca** (DGA BNA sub-watersheds) as the primary analysis unit for
the matched dammed-vs-undammed design. Use **cuenca** as a coarser robustness check and
for any quantity needing hydrologic closure (storage/streamflow water balances).

Reproduced by the `grain_choice` target (`targets/_targets.R` →
`src/R/matching/grain_diagnostics.R`). Treated = unit contains ≥1 of the 26 monitored
reservoirs (point-in-polygon). A subcuenca is **contaminated** (dropped as a control) if
it is untreated but sits inside a cuenca that contains a reservoir — it shares the
regulated main stem / closure and is not a clean counterfactual.

## Evidence

| metric | cuenca | subcuenca |
|---|---:|---:|
| total units | 101 | 467 |
| treated units | 14 | **24** |
| clean controls | 87 | **398** |
| contaminated controls (excluded) | 0 | 45 |
| treated climate zones (modal Köppen) | 4 | 6 |
| treated units w/o same-climate clean control | 1 | 2 |
| median area, treated (km²) | 11,510 | 2,666 |
| median area, control (km²) | 4,073 | 1,139 |

## Rationale

1. **Power.** 24 vs 14 treated units — ~70% more treatment units. With n this small,
   every treated unit matters for matching/DiD precision.
2. **Common support on size — the binding constraint.** Reservoirs sit in Chile's largest
   main-stem basins, so treated units are systematically bigger than controls at *both*
   grains (~2.3–2.8× the median control area). At cuenca grain this means 14 very large
   treated basins (median 11,510 km²) against mostly-small controls — poor overlap. The
   subcuenca grain shrinks the absolute scale and supplies far more controls inside the
   treated size range, making credible matching on area feasible.
3. **Contamination handled explicitly.** The 45 untreated subcuencas inside reservoir
   basins are removed, defusing the obvious SUTVA/downstream-spillover violation while
   still leaving 398 clean controls.

## Caveats carried forward to the matching step

- **Basin size × aridity is the core confound** (dams are placed in big, water-demanded
  basins). Match/weight on area + Köppen + baseline aridity; do **not** compare naively.
- **Climate orphans are an artifact of exact modal-class matching.** The 2 treated
  subcuencas with no same-class clean control are rare zones (Csa: `0603`; Dsc: `0730`).
  Coarsening Köppen to main groups (B / Cs / Cf / D / E) rescues them — Csa joins Csb
  controls, Dsc joins the D group. Use coarsened climate strata, not exact modal class.
- **Contamination rule is conservative.** Dropping the whole treated cuenca discards
  upstream (unaffected) subcuencas. With flow topology we could later reclassify
  above-dam subcuencas as clean controls — and even build within-basin upstream/downstream
  contrasts.
- **Residual SUTVA at subcuenca grain:** adjacency and shared aquifers between neighboring
  subcuencas. Note as a residual identification threat; check robustness at cuenca grain.
