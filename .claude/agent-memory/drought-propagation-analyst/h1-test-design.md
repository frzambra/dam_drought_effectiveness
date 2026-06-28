---
name: h1-test-design
description: Decisive statistical test design for H1 storage-rectifier — C1/C2/C3 identifiability, TAR/quantile/GPD specs, permutation inference
metadata:
  type: project
---

Design for H1 (reservoir = nonlinear storage rectifier; variance INTO the tail). See [[project-data-constraints]].

**Identifiability verdict:**
- C1 (threshold s*): identifiable WITHIN-treated only (storage is treated-only). Estimand = location of break in storage→eco-drought transfer fn, conditional on SPEI. Physical-vs-policy interpretation GATED (no rule curves).
- C2 (variance INTO tail): partly identifiable. Within-treated regime contrast in CONDITIONAL VARIANCE/tail below vs above s* is the core test. Full "redistribution" (compression of small + amplification of large from SAME process) needs the counterfactual — use matched controls (C3) as the natural-variance reference.
- C3 (heavier tail dammed vs control): MOST IDENTIFIABLE. Estimand = difference in upper-tail (severe-drought) quantile/GPD severity, dammed vs control, conditional on SPEI, ebal-weighted.

**Grain decision:** build the MONTHLY zcNDVI-6 panel. Annual zNPP (26 pts/unit) is fatal for tail/GPD (need ≥ a few hundred exceedances pooled). Monthly gives ~300 mo × 21 treated for within-treated TAR and a real POT sample. Keep annual zNPP as robustness/triangulation.

**C1/C2 within-treated spec:** TAR/threshold regression, outcome = zcNDVI-6 monthly per subcuenca, threshold var = storage_fraction (lagged 1–6 mo, pick by profile-likelihood grid), SPEI-12 (and shorter) as continuous forcing covariate. Two regimes (s < s* vs s ≥ s*). Test (a) MEAN/slope break and (b) RESIDUAL-VARIANCE break (Levene/Bartlett on regime residuals; or model log-variance per regime). Variance-into-tail = larger lower-tail eco-drought residual variance in s<s* regime AFTER conditioning on SPEI. Manual grid-search TAR over candidate s* (0.15–0.60) maximizing profile likelihood; CI by the permutation/bootstrap below. tsDyn::setar per-reservoir for triangulation; pooled via fixest interaction at estimated s*. brms varying-threshold hierarchical model only as confirmatory (worth it: pools 21 reservoirs, propagates s* uncertainty) — gate behind a clear pooled signal first.

**C3 dammed-vs-control tail spec:** (1) Quantile regression (quantreg::rq, weights=w) of eco-drought severity (use NEGATIVE zcNDVI-6 so severe = upper tail, or work at τ=0.05 of zcNDVI-6) on treated dummy + SPEI + covariates; estimand = treated coefficient at τ=0.05/0.10 (tail) vs τ=0.50 (median). H1 ⇒ tail coef ≫ median coef. (2) POT/GPD (extRemes::fevd) on severity exceedances above a high threshold, fit shape ξ and scale separately for treated vs control (ebal-weighted exceedance sampling); H1 ⇒ heavier tail (larger ξ or scale) for treated. (3) Conditional variance/skew contrast as a simpler triangulation.

**Inference (~21 clusters):** PERMUTATION of treatment labels within kg_group × aridity-tercile strata (preserves matching structure, respects megadrought collinearity), 5000+ reps; test statistic = the tail-vs-median QR contrast or treated GPD-ξ difference. For within-treated TAR, permute storage_fraction blocks / use stationary block bootstrap (autocorrelation) to get s* CI and variance-break null. Do NOT rely on analytic cluster-robust SEs.

**Decision criteria:**
- CONFIRM C1: stable s* with profile-likelihood peak, consistent sign across reservoirs, robust to lag choice.
- CONFIRM C2: residual variance / lower-tail dispersion SIGNIFICANTLY larger in s<s* regime after conditioning on SPEI (not just a mean shift).
- CONFIRM C3: τ=0.05 treated coef and/or GPD ξ/scale significantly > control via permutation; median coef ~ 0.
- FALSIFY (per doc): no identifiable s*; equal/lower conditional variance below threshold; lighter/equal treated tail (ξ_treated ≤ ξ_control). Below s*, treated eco-drought NOT exceeding SPEI-only counterfactual ⇒ "buffering just stops", rectifier dies.

**Monthly panel handling:** deseasonalize (zcNDVI-6 already standardized; still include harmonic/month FE), model AR(1) residuals or block-bootstrap, subcuenca FE in fixest.
