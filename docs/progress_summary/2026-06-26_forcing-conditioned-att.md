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

## Robustness battery (done) — sign robust, magnitude sensitive

`run_forcing_robustness()` (`dr_att_forcing_robustness`) re-runs the headline DR ATT across 10
analytic choices on the *same* `dr_estimate()` core. **Every scenario is positive with a 95% CI
excluding zero** — the direction is robust. The **magnitude ranges 0.11–0.39**, and two levers
move it materially:

| scenario | DR ATT | 95% CI | t | n_t / n_c |
|---|---:|---:|---:|---:|
| baseline (ebal, SPEI-12, lag0) | 0.328 | [0.181, 0.476] | 4.36 | 21 / 236 |
| **+ aridity² term** | **0.110** | **[0.010, 0.210]** | 2.15 | 21 / 236 |
| common aridity band | 0.230 | [0.075, 0.384] | 2.91 | 21 / 153 |
| SPEI-6 forcing | 0.361 | [0.209, 0.514] | 4.64 | 21 / 236 |
| SPEI-24 forcing | 0.242 | [0.107, 0.377] | 3.52 | 21 / 236 |
| **SPEI-12 lag 1yr** | **0.147** | **[0.039, 0.255]** | 2.68 | 21 / 236 |
| CEM subset | 0.321 | [0.172, 0.471] | 4.21 | 17 / 95 |
| NN 1:2 subset | 0.392 | [0.237, 0.546] | 4.96 | 21 / 42 |
| min_years 15 | 0.328 | [0.181, 0.476] | 4.36 | 21 / 236 |
| min_range 1.5 | 0.328 | [0.181, 0.476] | 4.36 | 21 / 236 |

- **Nonlinear aridity is the biggest mover.** Adding `log_aridity²` cuts the ATT to **0.110**
  (−66 %) — confirming the linear adjustment under-controlled the water-limitation curve. The
  effect *survives* (CI excludes 0) but this **0.11 is the conservative floor**, not 0.33. The
  common-aridity-band restriction (0.230, controls 236→153) agrees the extremes inflate it.
- **Lag matters:** a 1-year forcing lag halves the ATT to 0.147 — annual NPP responds to
  *contemporaneous* water, as expected; the contemporaneous spec is the right (and strongest) one.
- **Matching design is irrelevant to the conclusion:** CEM (0.321) and NN (0.392) bracket ebal.
- **Slope-fit thresholds are non-binding:** `min_years 15` / `min_range 1.5` leave the matched
  sample unchanged (median n_years 20, median range ~3), so the result doesn't ride on weakly
  identified slopes.

**Revised headline:** the forcing-conditioned ATT is **robustly positive but its magnitude is
uncertain (≈0.11–0.39); the defensible conservative estimate is ≈0.11** (flexible aridity
control). The H2-vulnerability *direction* survives every robustness cut; the *effect size*
should be reported as a range, not the 0.33 point estimate.

## Land-cover disaggregation (done) — the decisive test DISCONFIRMS the H2 reading

`stratified_znpp_annual()` + `fit_stratified_forcing_att()` (`znpp_strat`,
`dr_att_forcing_strat`) split per-subcuenca annual zNPP into **agricultural** (MapBiomas class
18) vs **natural** cover via a static 2007 baseline mask (30 m → zNPP grid, per-polygon), then
re-run the forcing-conditioned ATT within each stratum. The pre-stated logic: if the steeper
dammed-basin slope is the H2 reservoir/irrigated-demand mechanism, it lives in **agricultural**
cover and ~vanishes in **natural** cover; if it is an aridity/water-limitation artefact, it
hits **natural** cover too. **The result is the latter:**

| stratum | DR ATT (linear) | + aridity² | n_t / n_c |
|---|---:|---:|---:|
| **natural** | **0.362** [0.197, 0.526], t=4.31 | **0.127** [0.004, 0.249], t=2.03 | 21 / 225 |
| **agricultural** | 0.143 [−0.084, 0.371], t=1.24 (ns) | 0.091 [−0.083, 0.264] (ns) | 18 / 34 |
| basin-mean (ref) | 0.328 | 0.110 | 21 / 236 |

- **The whole basin-mean effect lives in NATURAL vegetation, not agriculture** — the *opposite*
  of the H2 prediction. The natural-cover ATT (0.362) reproduces the basin-mean (0.328) and
  **collapses identically under aridity²** (→0.127), while within natural cover treated basins
  are far more arid (mean aridity 0.42 vs 1.0) and the slope tracks aridity (r=−0.53). This is
  a **natural-vegetation water-limitation / residual-aridity** signal, not a reservoir effect.
- **The agriculture-specific test — where H2 predicts the action — is null** (0.14, ns) and
  collapses further under aridity². So the induced-demand-vulnerability mechanism is **not
  supported** by the available ecological proxy.

**Revised bottom line.** The forcing-conditioned basin-mean ATT is positive and sign-robust,
but the disaggregation shows it is **mostly residual baseline aridity acting on rain-fed
vegetation, not the H2 irrigated-demand mechanism**. The honest reading: at the basin-mean zNPP
grain we **cannot** claim a reservoir-driven vulnerability effect; the apparent signal is a
water-limitation confound the matched design + linear adjustment did not fully remove. The
powered, irrigation-specific test below (added 2026-06-26) confirms this — see that section for
the definitive H2 null. H2 ultimately awaits its proper outcome (irrigated area + ET).

## Agriculture power upgrade (done) — confirms the disconfirming read

The class-18-only agriculture stratum had only 34 controls (no power). Broadening to **farming
{9 silviculture, 15 pasture, 18 agriculture}** on a 3-year baseline mask (`znpp_strat_farming`,
`dr_att_forcing_strat_farming`) triples the control pool to **104** — enough to test the H2
agricultural-slope claim with real power.

| stratum (mask) | DR ATT (linear) | + aridity² | n_t / n_c |
|---|---:|---:|---:|
| agricultural — class 18, thr 0.5 (sharp, low power) | 0.143 (ns) | 0.091 (ns) | 18 / 34 |
| agricultural — farming {9,15,18} (powered, rain-fed-mixed) | 0.278 [0.08, 0.47], t=2.78 | 0.096 (ns), t=1.40 | 20 / 104 |
| **agricultural — class 18, thr 0.1 (powered, IRRIGATION-specific)** | **0.077** [−0.08, 0.24], t=0.95 (ns) | **0.007** (ns), t=0.11 | 21 / 62 |
| **irrigated — Catastro orchards (GROUND TRUTH)** | **0.060** [−0.11, 0.24], t=0.68 (ns) | **−0.048** (ns), t=−0.66 | 18 / 36 |
| natural | 0.362 [0.20, 0.53], t=4.31 | 0.127, t=2.03 | 21 / 224 |

**Ground-truth confirmation (Catastro Frutícola orchards).** Replacing the MapBiomas class-18
proxy with the actual irrigated-orchard footprint (CIREN/ODEPA cadastre, §"Definitive irrigated
stratum" below) gives the **same clean null** (0.060, t=0.68; −0.048 under aridity²). On
definitively-irrigated land, dammed and control basins transmit drought to productivity *almost
identically* (raw slopes 0.224 vs 0.159) — the entire dammed-vs-control divergence is in natural
cover (0.251 vs −0.119). Three independent irrigated definitions (class-18 proxy, ground-truth
orchards, and the aridity²-adjusted farming stratum) now agree on the H2 null.

**The powered, mechanism-pure test is a clean H2 null — and reveals where the broad signal came
from:**

- **Irrigated cropland (class 18, powered) shows NO dammed-vs-control slope difference** —
  0.077 (t=0.95) linearly, and essentially **zero (0.007) under aridity²**. Exactly where H2
  predicts the steepening, there is none, with power.
- **The farming-stratum positive (0.278) was the rain-fed components, not irrigation.** Farming
  {9,15,18} is dominated by silviculture/pasture (rain-fed, water-limited, tracking SPEI like
  natural cover); stripping to irrigated cropland only removes that and the effect vanishes.
  So the broad-managed signal was the aridity/water-limitation confound, not irrigated demand.
- **Ordering is anti-H2:** natural (0.36) ≈ farming (0.28) >> irrigated cropland (0.08). The
  irrigated stratum is the *flattest / most decoupled* from meteorological forcing — directionally
  consistent with reservoir **buffering** of irrigated cropland (H1), the opposite of H2's
  amplified vulnerability — though the ATT is null, so read as "no detectable difference," not
  a buffering finding.

## Caveats / open items

- **zNPP is a coarse proxy** for the H2 outcome — annual NPP z-score over cropland does not
  isolate irrigation water use; the real test needs irrigated-area expansion + ET (gated). The
  null here is a strong *absence of an ecological-transmission signal*, not a direct test of the
  area/ET mediator.
- **Even the natural-cover effect survives aridity² weakly** (0.127, t=2.03) — could be deeper
  aridity nonlinearity, a minor genuine natural-veg effect (riparian/groundwater), or other
  confound; it is **not** the H2 mechanism regardless.
- Per-unit slopes remain noisy (median R²≈0.07): less precision, not bias.

## Next (priority order)

1. **Acquire the H2 outcome** — irrigated-area / ET time series. The ecological (zNPP) proxy is
   now exhausted: it gives a clean, powered H2 null on the deficit→impact slope, but cannot
   directly test the area/ET mediator the hypothesis is actually about.
2. **Inference upgrade** — wild-cluster bootstrap / permutation for the small-n ATT; propagate
   slope-estimation uncertainty (currently treated as a fixed outcome).
3. **Reframe the contribution** — the forcing-conditioned + cover-disaggregated null is itself a
   result: it shows the basin-mean "vulnerability" signal is an aridity confound, a caution
   other reservoir studies using basin-mean greenness would miss. Worth a methods-forward angle.

## Files touched

- `src/R/preprocessing/forcing_data.R` (new) — `forcing_monthly_paths()`,
  `extract_unit_forcing_annual()` (SPEI zonal → annual per-unit forcing).
- `src/R/preprocessing/ecological_outcomes.R` — factored out `extract_unit_index_annual()`
  (the per-unit-year panel); `extract_unit_index_trend()` now reuses it.
- `src/R/causal/forcing_conditioned.R` (new) — `build_response_panel()`,
  `fit_response_slopes()` (transmission coefficient), `fit_forcing_conditioned_att()`,
  `fit_stratified_forcing_att()` (per-cover ATT contrast).
- `src/R/causal/doubly_robust.R` — factored out `dr_estimate()` (reusable estimator core)
  shared by `fit_doubly_robust()`, the robustness battery, and the stratified ATT.
- `src/R/causal/forcing_robustness.R` (new) — `run_forcing_robustness()` (10-scenario battery).
- `src/R/preprocessing/landcover_cover.R` (new) — `mapbiomas_paths()`,
  `stratified_znpp_annual()` (per-polygon 30 m cover mask → ag/natural zNPP strata).
- `src/R/data_ingestion/read_orchards.R` (new) — `read_orchards_latest()`,
  `dissolve_orchards()` (Catastro Frutícola → national irrigated-orchard footprint).
- `src/R/preprocessing/orchard_outcomes.R` (new) — `orchard_fraction_raster()`,
  `extract_unit_orchard_znpp()`, `combine_orchard_natural()` (ground-truth irrigated stratum).
- `config/data_sources.yml` — `catastro_fruticola` source block.
- `targets/_targets.R` — `spei_stack`, `forcing_subcuencas`, `znpp_annual`, `response_panel`,
  `response_slopes`, `dr_att_forcing`; robustness: `spei_stack_6/24`,
  `forcing_subcuencas_6/24`, `dr_att_forcing_robustness`; land cover: `mb_baseline_paths`,
  `mb_baseline_multi`, `matched_subcuencas`, `znpp_strat` + `dr_att_forcing_strat` (class-18),
  `znpp_strat_farming` + `dr_att_forcing_strat_farming` (powered farming),
  `znpp_strat_irrig` + `dr_att_forcing_strat_irrig` (powered irrigation-specific);
  orchards: `orchards_latest`, `orchards_dissolved`, `orchard_frac_file`, `znpp_orchard`,
  `znpp_orchard_natural`, `dr_att_forcing_orchard` (ground-truth irrigated).
- `docs/design/matched-controls.md` (forcing-conditioned section + enhancement #2 closed).
