# Design: matched / weighted control set (subcuenca, ATT)

**Date:** 2026-06-24
**Target:** `matched_set` (`targets/_targets.R` → `src/R/matching/build_matched_set.R`)
**Estimand:** ATT — effect on dammed subcuencas.
**Method:** entropy balancing (`WeightIt::weightit`, `method="ebal"`), exact-matched within
Köppen main group (`by = ~kg_group`), balancing **`log(area)` + mean elevation**. Local
elevation common support; latitude reported as an untargeted diagnostic.

## Result

- **21 of 24 treated subcuencas retained.** Balanced essentially perfectly:
  standardized mean differences fall from **log_area 1.18 / elev_mean 0.37** (unadjusted)
  to **0.000** after weighting; variance ratios ≈ 1 (0.84, 1.04). Latitude, although *not*
  targeted, also balances well (SMD 0.73 → −0.02).
- **Effective control sample size ≈ 91** (of 244 in-window controls). Per group: B = 11
  treated / ESS 57.5; C = 10 treated / ESS 36.7. No extreme single-control weights, no
  convergence failure.

### Why elevation matters (the DEM's value, quantified)

The first version balanced `log_area + latitude` and trimmed controls to the treated
latitude band. That gave a degenerate solution: **ESS ≈ 9**, because Köppen-ET spans the
high *northern* Andes (treated) and low *Patagonia* (controls), so latitude and the climate
class fight each other. Adding SRTM mean elevation and balancing on it *instead of*
latitude (latitude is then collinear/redundant within a Köppen group) took **ESS 9 → 91**
and removed the convergence problem. Elevation is the mechanistically correct montane/
lowland axis; latitude was a confounded proxy.

## Common-support trimming (why 3 treated dropped)

| unit_id | Köppen | reason |
|---|---|---|
| 0730 | Dsc | no clean control in Köppen group D anywhere in Chile |
| 0430 | ET  | too few undammed controls inside its high-elevation window |
| 0570 | ET  | too few undammed controls inside its high-elevation window |

Common support is **local**: within each Köppen group controls are restricted to the
treated mean-elevation window (± 250 m), and a group is dropped if fewer than 10 controls
fall in that window. The 3 dropped units are high-Andes (mean elev > 2200 m) with only a
handful of comparable high-elevation undammed subcuencas — kept honest rather than riding
on ~2 controls.

## What the diagnostics reveal (carry to interpretation)

1. **Basin size is the dominant confound** (unadjusted log_area SMD = 1.18): reservoirs sit
   in Chile's larger basins. Weighting removes it, and with elevation in the model the ESS
   cost is now modest (91, not 9) — the design is adequately powered for B and C groups.
2. **The credible matched comparison covers arid (B) and Mediterranean (C) reservoir
   subcuencas** — most of the irrigation-reservoir story — not the 3 high-Andes units.
3. Latitude balancing for free (SMD → −0.02) is reassuring: matching on Köppen group +
   elevation + size yields north–south comparability without targeting it.

## Robustness: CEM and 1:k NN (target `robustness_matches`)

All three estimators run on the *identical* common-support sample (`common_support_trim`).

| method | treated | controls | ESS | max\|SMD\| (area, elev) | lat SMD |
|---|---:|---:|---:|---:|---:|
| ebal (primary) | 21 | 244 | 91.3 | 0.000 | −0.016 |
| CEM            | 17 | 97  | 65.0 | 0.159 | 0.060 |
| NN 1:2 (Mahalanobis) | 21 | 42 | 42.0 | 0.094 | −0.028 |

**Verdict — consistent, with one caveat.** ebal and NN retain all 21 treated with good
balance (NN |SMD|<0.1); the same 3 high-Andes units are out of support in every method.
**CEM additionally prunes 4 treated** — `0210` (BWk, 8158 km², 3812 m), `0573` (BSk),
`0732`, `0831` (Csb) — the most extreme large/high basins, whose coarsened bins contain no
control. CEM also leaves residual **log_area** imbalance (SMD 0.159), again pinpointing
basin size as the stubborn confound: the largest dammed basins (e.g. `0210`) have
essentially no undammed analog and are "matched" by ebal only through weighting.

**Implication for effect estimation:** report the ATT with and without these 4
hard-to-match units; if the estimate is sensitive to them, lean on the CEM (n=17) subset as
the conservative headline.

## Baseline aridity: carried as a diagnostic, not a balance target

Quantitative baseline aridity is now computed (`aridity_index` in `config/data_sources.yml`,
`extract_unit_aridity()`): long-term **mean annual P/PET** over the 1991–2020 WMO normal
(temporal mean of the *annual* rasters — annual-sum P / annual-sum PET — **not** a mean of
the unstable monthly P/PET product). Carried into `match_covariates` as `aridity_mean` /
`log_aridity` and reported as an untargeted balance diagnostic, exactly as latitude was.

The diagnostic is informative, and the decision went the *opposite* way to latitude:

- **Dammed subcuencas are markedly more arid** — median aridity **0.255** (semi-arid) vs
  **0.801** (humid) for controls; unadjusted `log_aridity` SMD = **−0.33**. Reservoirs are
  built where water is scarce, so aridity is a genuine confound, not a nuisance.
- **It does NOT balance for free.** Under the primary spec (`log_area + elev_mean` within
  Köppen group) the residual `log_aridity` SMD is **0.17** — above the 0.1 threshold and,
  unlike latitude (which fell to −0.02), *not* absorbed by elevation.
- **But targeting it is the wrong trade.** Adding `log_aridity` to the ebal formula drives
  its SMD to 0 yet **collapses ESS 91 → 19** (a 79% loss, leaving 21 treated essentially
  unpowered) **and breaks latitude balance (−0.02 → 0.55)**. Aridity, latitude, and
  elevation are mutually confounded within Köppen group — the same fight that demoted
  latitude from a target. Exact aridity balance is bought by re-imbalancing the rest.

**Decision:** keep `log_area + elev_mean` as the ebal targets; carry baseline aridity as a
reported diagnostic and **mop up the residual 0.17 via doubly-robust regression adjustment**
(enhancement #2 below) — far cheaper than spending 72 ESS to hard-balance it. Köppen group
already captures most of the aridity signal categorically; the residual is within-group.

## Doubly-robust ATT (the residual-aridity mop-up, demonstrated)

Implemented in `fit_doubly_robust()` (`src/R/causal/doubly_robust.R`, target `dr_att`). On
the ebal matched set it fits three estimators on the *same* sample and reports all three so
the reader sees functional-form sensitivity directly:

1. **weighting-only** — ebal-weighted difference in means (no covariate adjustment);
2. **regression-only** — covariate-adjusted, unweighted (g-computation over treated units);
3. **doubly-robust** — ebal-weighted **and** covariate-adjusted (the headline), with the
   outcome model carrying `log_aridity + elev_mean + log_area`. Continuous covariates are
   centered at the treated mean so the `treated` coefficient reads as the ATT; SEs are HC3
   robust (ebal weights treated as fixed — weight-estimation uncertainty not propagated, the
   standard, mildly anti-conservative ebal simplification).

**Demonstration outcome (provisional).** The primary H2 outcome (irrigated-area expansion)
is gated, so the estimator is exercised on the available stand-in: the **storage-era
(2005–2024) trend in annual zNPP** per subcuenca (`outcome_subcuencas`), a greening/
productivity slope. 21 treated / 236 controls carry the outcome (8 controls drop for missing
zNPP coverage).

**Result — the three estimators agree to the third decimal:**

| estimator | ATT (zNPP trend, yr⁻¹) | 95% CI | t |
|---|---:|---:|---:|
| weighting-only  | −0.0243 | [−0.041, −0.008] | −2.91 |
| regression-only | −0.0240 | [−0.040, −0.008] | −2.91 |
| **doubly-robust** | **−0.0244** | **[−0.042, −0.007]** | −2.76 |

Covariate adjustment barely moves the estimate off the weighting-only number — the residual
aridity imbalance was **not** driving the result, which is exactly the reassurance DR is for.
Dammed subcuencas show a *more negative* productivity trend than matched controls (raw
−0.018 vs +0.005 yr⁻¹).

**Caveat — this is not yet a clean reservoir effect.** The ATT is on the *raw* trend and the
matched design controls baseline climate (Köppen + aridity + elevation), **not** the realized
2010–2015+ megadrought intensity, which was concentrated in exactly the arid central-Chile
basins where reservoirs sit. So a negative productivity trend in dammed basins partly
reflects drought *exposure*, not reservoir *causation*. Breaking that confound is the job of
the forcing-conditioned response function (the `dose_response` / `period_slopes` levers) — the
matched ATT and the forcing-conditioning must be combined before any causal claim. Treat the
sign as a hypothesis-generating signal, not a finding.

## Forcing-conditioned ATT (the mega-drought-exposure fix, done)

The trend-based `dr_att` above carries the exposure confound flagged in its caveat: the raw
zNPP trend is a *calendar-time* slope, so the ATT on it conflates reservoir effect with
mega-drought exposure. The forcing-conditioned estimator (`dr_att_forcing`,
[`src/R/causal/forcing_conditioned.R`](../../src/R/causal/forcing_conditioned.R)) implements
Lever 1 of the identification strategy: per subcuenca, regress annual zNPP on annual SPEI-12
forcing (2005–2024) and take the **transmission slope** (a standardized, cross-basin
drought-transmission elasticity) as the outcome of the *same* DR machinery.

**The sign flips once forcing is conditioned out:**

| outcome | DR ATT | 95% CI | t |
|---|---:|---:|---:|
| raw zNPP trend (calendar-time) | −0.0244 | [−0.042, −0.007] | −2.76 |
| **transmission slope (forcing-conditioned)** | **+0.328** | **[0.181, 0.476]** | 4.36 |

Dammed basins convert a unit of meteorological deficit into **more** ecological impact (a
*steeper* slope: treated +0.223 vs control −0.089), the **H2 vulnerability** signature, not the
H1 buffering one. The raw-trend negative was largely exposure.

**Robustness (`dr_att_forcing_robustness`, 10 scenarios) — direction robust, magnitude
sensitive.** Every scenario (nonlinear aridity, SPEI-6/12/24, lag, CEM/NN subsets, slope-fit
thresholds) is positive with a CI excluding zero, but the magnitude spans **0.11–0.39**. The
two movers: adding a **quadratic aridity** term cuts the ATT to **0.110** (the conservative
floor — linear adjustment under-controlled the water-limitation curve), and a 1-year forcing
lag halves it to 0.147 (annual NPP responds contemporaneously). Matching design is irrelevant
(CEM 0.32 / NN 0.39 bracket ebal) and the slope-fit thresholds are non-binding.

**Land-cover disaggregation reframes the basin-mean result — it is an aridity confound, not
H2.** Splitting the slope by cover (`dr_att_forcing_strat*`) and powering the agricultural
stratum:

| stratum | DR ATT | + aridity² | n_t / n_c |
|---|---:|---:|---:|
| natural | 0.362 (t=4.31) | 0.127 (t=2.03) | 21 / 224 |
| farming {9,15,18} (powered) | 0.278 (t=2.78) | 0.096 (ns) | 20 / 104 |
| **irrigated cropland — class 18, powered** | **0.077 (ns)** | **0.007 (ns)** | 21 / 62 |

The effect lives in **rain-fed** vegetation (natural + the silviculture/pasture part of
farming), tracks baseline aridity (r=−0.53), and **collapses under aridity²** everywhere. The
powered, **irrigation-specific** stratum — exactly where H2 predicts steepening — is a **clean
null** (0.077 → 0.007). Ordering is anti-H2 (natural ≈ farming ≫ irrigated cropland). **So the
steeper dammed-basin transmission is a water-limitation/residual-aridity confound on rain-fed
cover, not the irrigated-demand (H2) mechanism; at the zNPP grain there is no reservoir
vulnerability effect.** H2 awaits its proper outcome (irrigated area + ET). Full result + caveats:
[`docs/progress_summary/2026-06-26_forcing-conditioned-att.md`](../progress_summary/2026-06-26_forcing-conditioned-att.md).

## Enhancements (in priority order)

1. ~~Add elevation~~ **done** (SRTM 3s; `dem`, `extract_unit_terrain()`). ~~Add quantitative
   baseline aridity~~ **done** (annual P/PET, `aridity_index`, `extract_unit_aridity()`) —
   diagnostic, not a target, for the ESS reason above. ~~Doubly-robust adjustment~~ **done**
   (`fit_doubly_robust()`, `dr_att`) — see section above; ready to re-point at the gated
   irrigated-area outcome when it lands.
2. ~~**Forcing-conditioned ATT**~~ **done** (`dr_att_forcing`) — see section above; the
   transmission-slope outcome removes the mega-drought-exposure confound and flips the sign.
3. ~~**Sensitivity of the forcing-conditioned ATT**~~ **done** (`dr_att_forcing_robustness`):
   nonlinear aridity, SPEI-6/12/24, forcing lag, CEM/NN subsets, slope-fit thresholds — see the
   robustness paragraph above. Direction robust; magnitude ≈0.11–0.39.
4. **Still open:** matched-set sensitivity to `min_controls` / `elev_buffer_m`; within-unit
   relief (`elev_sd`); re-fit ebal weights on the outcome-complete sample (the 8 dropped
   controls). **Confirmatory (gated, now highest value):** land-cover-disaggregated
   transmission slope — isolates the H2 mechanism and sidesteps the aridity confound.
