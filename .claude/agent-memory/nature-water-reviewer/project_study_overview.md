---
name: project-study-overview
description: Core design, data, and findings of the Chile reservoir drought-effectiveness study as of 2026-06-28
metadata:
  type: project
---

Study: "Reservoir Effectiveness and Drought Vulnerability in Chile" (PI Zambrano). Target Nature Water.

Question: do reservoirs reduce drought impacts or merely delay them while raising long-term vulnerability via induced demand?

Design: national matched design, 21 dammed vs ~236 control subcuencas (DGA BNA grain). Entropy-balancing on baseline aridity (P/PET), Koppen class, elevation, area. Period 2000-2024; streamflow only to 2020-03.

Outcomes: MODIS zNPP / zcNDVI-6 / MOD16 ET; MapBiomas land cover; CR2 streamflow (SSI-12). Forcing = SPEI-12/-3.

Identification: treatment ~time-invariant (18/24 dams predate record) so NO staggered-adoption. Megadrought collinear with siting (arid central Chile). They never identify off calendar time; estimand is differential deficit->impact SLOPE (treat:spei_c), year/unit FE absorb the common shock. Inference = permutation of treatment label within Koppen x aridity-tercile strata (~17-24 treated CLUSTERS -> cluster-robust SEs over-reject).

Findings = convergent NULL across H1 (buffering/rectifier), H2 (induced demand, 4 methods), H5 (recovery). Streamflow buffering null with DECISIVE upstream-of-dam placebo as strong as downstream (-0.20 vs -0.17), no dose-response -> apparent attenuation is siting/aridity not the dam.

Central claim: no detectable causal reservoir effect on drought propagation on any outcome; cross-sectional contrasts reflect siting in arid hydrologically-distinct basins; naive comparisons + calendar-time DiD + few-cluster SEs manufacture spurious buffering.

Key limitations: ~17-24 treated clusters (null vs true-zero power question); streamflow ends 2020-03 (misses 2020-24 deepest megadrought); no reservoir release/operating-rule records (no naturalized-inflow mass-balance counterfactual); up/down-dam via DEM-elevation proxy (no routed network); standardized-index proxies; time-invariant treatment; matching on observed covariates only.

Docs: docs/conceptual_framework/identification-strategy.md; docs/hypotheses/*; docs/progress_summary/2026-06-26_forcing-conditioned-att.md, 2026-06-28_*.md.
