---
name: evidence-tables
description: Where the manuscript's numbers live and key text-vs-table discrepancies
metadata:
  type: reference
---

Result tables backing the manuscript (relative to repo root):

- results/tables/table_main_results.csv — 4 estimators. Row 5 (whole-basin ET) = +0.0479 [0.0255,0.0703], CI EXCLUDES zero, p_perm 0.11; labelled "null" in text. Irrigated-area DiD +0.00075 (p_perm 0.91). Orchard ET -0.0196 (p_perm 0.24). Cross-sectional DR ATTs: irrigated-area -0.69 [-2.4,1.1]; ET buffering -0.014 [-0.065,0.037].
- results/tables/table_equivalence.csv — ALL equivalent=FALSE. Streamflow ITT MDE 0.268 = 45.8% of baseline 0.585; downstream MDE 0.312 = 58.8%. Irrigated-area MDE = 7325% of baseline (no power). Whole-basin ET is ABSENT from this table.
- results/tables/table_storage_band.csv — peak -0.0128 (p=0.013), trough -0.0122 (p<1e-4), amplitude -0.0006 (p=0.91). Fraction-of-capacity units; x100 = the "-1.3/-1.2 pp/yr" in text. Pooled reservoir-FE trend, no control group.

Design docs:
- docs/design/matched-controls.md — ebal within Köppen on log(area)+elevation; 21/24 treated retained; ESS approx 91 (NOT the raw 244 the results text cites); residual aridity SMD 0.17; forcing-cond ATT 0.33->0.11 under quadratic aridity.
- docs/design/grain-selection.md — subcuenca grain; 24 treated, 398 clean controls, 45 contaminated dropped (SUTVA rule).
- docs/hypotheses/H7-upstream-downstream-placebo.md — 15/21 basins have up+down gauges; regional split numbers; south 7t/39c, north only 5 controls (unstable).
- docs/hypotheses/README.md — program pivot; H8 retired (refill-degradation null 4/4); storage band = 22 reservoirs/20 matched units (Rungue no capacity).
