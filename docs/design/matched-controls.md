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

## Enhancements (in priority order)

1. ~~Add elevation~~ **done** (SRTM 3s; `dem` in `config/data_sources.yml`,
   `extract_unit_terrain()`).
2. **Add quantitative baseline aridity** computed as long-term *annual* P/PET (annual sums,
   not a mean of the unstable monthly P/PET product on the drive).
3. **Sensitivity:** vary `min_controls` / `elev_buffer_m`; compare ebal vs CEM vs 1:k NN
   (MatchIt) as robustness; consider adding within-unit relief (`elev_sd`) if it helps.
4. **Doubly-robust:** estimate effects by regression adjustment on the weighted matched
   set, not weighting alone — report both.
