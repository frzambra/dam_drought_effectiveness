# Progress summary — 2026-06-24

**Focus:** baseline aridity as a matching covariate, and a doubly-robust ATT on the
entropy-balanced matched set. Advances the `matched_set` design in
[`docs/design/matched-controls.md`](../design/matched-controls.md).

## 1. Registered the annual aridity index

- Added the `aridity_index` block to `config/data_sources.yml` (annual + monthly P/PET,
  CHIRPS-CHIRTS, 1981–2026, 0.05°, EPSG:4326).
- Captured the gotchas for downstream code: raw P/PET ratio (**not** a z-score, low = arid,
  opposite sign to SPI/SPEI); valid range ~0.001–5.8 (Chile-wide median ~0.25, semi-arid);
  a few unflagged negative fill cells (~ −172.9) that must be masked `< 0`; the `chir[p|t]s`
  filename quirk (literal brackets/pipe break naive globbing); 2026 is partial/provisional.

## 2. Baseline aridity as a matching covariate (enhancement done)

- `src/R/preprocessing/aridity_data.R` — `aridity_annual_paths()` + `extract_unit_aridity()`:
  long-term **mean annual P/PET** over the 1991–2020 WMO normal per subcuenca.
- Wired into the pipeline (`aridity_paths`, `aridity_subcuencas` → `match_covariates`) and
  carried into `build_match_covariates()` as `aridity_mean` / `log_aridity`.
- **Key empirical finding:** dammed subcuencas are markedly more arid (median aridity 0.255
  vs 0.801 for controls). Aridity does **not** balance for free under the primary spec
  (residual `log_aridity` SMD = 0.17), but hard-targeting it in entropy balancing collapses
  ESS 91 → 19 and breaks latitude balance (−0.02 → 0.55). **Decision:** carry aridity as a
  reported diagnostic, not a balance target, and absorb the residual via regression
  adjustment. Matched set unchanged (21/24 treated retained, ESS ≈ 91).

## 3. Doubly-robust ATT (enhancement done)

- `src/R/causal/doubly_robust.R` — `fit_doubly_robust()`: three estimators on the same
  matched sample (weighting-only, regression-only, doubly-robust), covariates centered at
  the treated mean so the `treated` coefficient is the ATT, HC3 robust SEs. The outcome
  model carries `log_aridity + elev_mean + log_area` to mop up the residual aridity
  imbalance. No new package dependencies (base `lm` + `sandwich`).
- `src/R/preprocessing/ecological_outcomes.R` — per-subcuenca storage-era (2005–2024) trend
  in annual zNPP (`outcome_subcuencas`), a provisional ecological-expansion stand-in for the
  gated irrigated-area outcome.
- Pipeline: `znpp_stack` → `outcome_subcuencas` → `dr_att`.

**Result (validated end-to-end):**

| estimator | ATT (zNPP trend, yr⁻¹) | 95% CI | t |
|---|---:|---:|---:|
| weighting-only  | −0.0243 | [−0.041, −0.008] | −2.91 |
| regression-only | −0.0240 | [−0.040, −0.008] | −2.91 |
| **doubly-robust** | **−0.0244** | **[−0.042, −0.007]** | −2.76 |

The three agree to the third decimal — covariate adjustment barely moves the estimate, so
the residual aridity imbalance was not driving the result (the reassurance DR is for).

## Caveats / open items

- **Not yet a clean reservoir effect.** The ATT is on the *raw* trend; the matched design
  controls baseline climate but **not** the realized 2010–2015 megadrought intensity, which
  hit the arid central-Chile basins where reservoirs sit. The sign is hypothesis-generating,
  not causal — pending forcing-conditioning.
- **Provisional outcome.** zNPP trend stands in for the gated irrigated-area outcome; the
  estimator is general and ready to re-point when that data lands.
- 8 control subcuencas dropped from the DR fit for missing zNPP coverage (244 → 236; all 21
  treated retained).

## Next (priority order, from the design doc)

1. **Forcing-conditioned ATT** — combine the matched set with drought-forcing conditioning so
   the effect is on the deficit→impact slope, not the raw trend (removes the megadrought
   confound).
2. **Sensitivity** — vary `min_controls` / `elev_buffer_m`; ebal vs CEM vs 1:k NN; re-fit
   weights on the outcome-complete sample.

## Files touched

- `config/data_sources.yml` (aridity_index block)
- `src/R/preprocessing/aridity_data.R` (new)
- `src/R/preprocessing/ecological_outcomes.R` (new)
- `src/R/causal/doubly_robust.R` (new)
- `src/R/matching/build_matched_set.R` (aridity covariate + diagnostic)
- `targets/_targets.R` (aridity + outcome + DR targets)
- `docs/design/matched-controls.md` (aridity decision + DR results documented)
