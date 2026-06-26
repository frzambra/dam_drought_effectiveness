# Progress summary — 2026-06-26

**Focus:** the forcing-conditioned ATT (identification-strategy Lever 1) — the next item from
[`2026-06-24`](2026-06-24_aridity-and-doubly-robust-att.md). Moves the matched-set estimand
off the calendar-time zNPP trend and onto the **deficit→impact response slope**, breaking the
mega-drought-exposure confound (threat T1).

## What changed and why

The previous headline (`dr_att`) put the **storage-era zNPP trend** — a slope on *calendar
time* — as the outcome. The identification strategy
([`identification-strategy.md`](../conceptual_framework/identification-strategy.md)) is explicit:
*never identify off calendar time*, because the 2010+ mega-drought is collinear with where
reservoirs sit (arid central Chile), so that trend conflates reservoir **effect** with drought
**exposure**. Lever 1 fixes it: condition on the realized forcing and estimate the effect on
the deficit→impact **transmission slope**.

Per subcuenca we now regress the annual ecological anomaly (zNPP) on the annual meteorological
forcing (SPEI-12) over the storage era (2005–2024); the slope is the **transmission
coefficient**. Both series are standardized anomalies, so the slope is a dimensionless,
cross-basin-comparable drought-transmission elasticity — *not* a calendar-time trend. That
slope becomes the outcome of the **same** doubly-robust matched-set estimator (ebal weights +
`log_aridity` adjustment), so trend-based and forcing-conditioned ATTs are directly comparable.

## Result — forcing-conditioning FLIPS the story

| estimator | ATT (transmission slope) | 95% CI | t |
|---|---:|---:|---:|
| weighting-only  | 0.316 | [0.183, 0.449] | 4.66 |
| regression-only | 0.329 | [0.194, 0.463] | 4.78 |
| **doubly-robust** | **0.328** | **[0.181, 0.476]** | 4.36 |

(21 treated / 236 controls with usable slopes.) Raw mean slope: **treated +0.223 vs control
−0.089**. The raw-trend ATT was −0.024 yr⁻¹ (dammed basins "declining"); **conditioned on
forcing, the sign flips** — dammed basins convert a unit of meteorological deficit into
**more** ecological impact (a *steeper* transmission slope), not less.

**Interpretation.** The raw-trend negative was largely mega-drought *exposure*. The
forcing-conditioned positive ATT is the **H2 vulnerability signature**, not the H1 buffering
one: a reservoir that merely buffered would *flatten* the slope; induced-demand expansion of
water-dependent land use predicts a *steeper* slope (productivity collapses harder when the
deficit bites). This is hypothesis-supporting for the central question — but see caveats.

## Confound checks (done, partial)

- **Water-limitation / baseline aridity.** Arid basins are naturally more water-coupled, and
  dammed basins are more arid (mean aridity 0.42 vs 0.98). Real but **small**: the controls-only
  slope–aridity gradient is −0.072 per log-unit (p≈6e-16); dammed basins are more arid by
  Δlog≈−0.85, predicting only **≈+0.06** of the observed **+0.31** ATT. DR (with `log_aridity`)
  barely moves off weighting-only, so linear aridity adjustment does not absorb it.
- **Within Köppen group the gap survives:** B (arid) +0.243 vs +0.038; C (Mediterranean)
  +0.202 vs −0.163. Not an artifact of climate-class mixing.

## Caveats / open items

- **Nonlinear aridity not yet ruled out.** The adjustment is linear in `log_aridity`; a
  nonlinear water-limitation curve could still inflate the slope gap. Next: spline/quantile in
  aridity, or restrict to a common aridity band.
- **Basin-mean zNPP mixes natural + irrigated cover.** The H2 mechanism predicts the
  *irrigated* signal steepens specifically (crops fail without water). The identification doc
  (threat 3) warns against basin-mean NDVI alone — disaggregating the slope by MapBiomas land
  cover is the proper confirmatory test (gated on land-cover ingestion).
- **Per-unit slopes are noisy** (median R²≈0.07): productivity~SPEI explains little annual
  variance. This is outcome measurement error → lower precision (the ATT survives at t≈4.4),
  not bias.
- **Single timescale/lag** (SPEI-12, contemporaneous). Lag and timescale robustness pending.

## Next (priority order)

1. **Robustness of the forcing-conditioned ATT** — nonlinear aridity adjustment; vary SPEI
   timescale (6/12/24) and forcing lag; re-fit on the CEM (n=17) and 1:k NN subsets; sensitivity
   to `min_forcing_range` / `min_years`.
2. **Land-cover-disaggregated slope** (gated) — separate transmission slopes for irrigated vs
   natural cover; the H2-specific test.

## Files touched

- `src/R/preprocessing/forcing_data.R` (new) — `forcing_monthly_paths()`,
  `extract_unit_forcing_annual()` (SPEI zonal → annual per-unit forcing).
- `src/R/preprocessing/ecological_outcomes.R` — factored out `extract_unit_index_annual()`
  (the per-unit-year panel); `extract_unit_index_trend()` now reuses it.
- `src/R/causal/forcing_conditioned.R` (new) — `build_response_panel()`,
  `fit_response_slopes()` (transmission coefficient), `fit_forcing_conditioned_att()`.
- `targets/_targets.R` — `spei_stack`, `forcing_subcuencas`, `znpp_annual`, `response_panel`,
  `response_slopes`, `dr_att_forcing`.
- `docs/design/matched-controls.md` (forcing-conditioned section + enhancement #2 closed).
