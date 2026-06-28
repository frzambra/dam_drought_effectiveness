---
name: forcing-interacted-did-design
description: The defensible DiD/event-study design for time-invariant reservoir treatment + megadrought confound — treat x SPEI slope, year FE as exposure control
metadata:
  type: project
---

For this project the only defensible dynamic design given (a) near-time-invariant treatment (see [[treatment-design-constraints]]) and (b) the megadrought confound (see [[megadrought-confound-t1]]) is a **forcing-interacted DiD where SPEI, not calendar year, is the time-varying dose**.

**Ranked designs (decided 2026-06):**
1. PRIMARY: forcing-interacted DiD. `feols(outcome ~ treat:spei_c + spei_c | subcuenca + year, weights=~w, cluster=~subcuenca)`. Estimand = differential deficit->impact SLOPE (dammed vs matched control). `treat:spei_c` is the H1/H2 test. Unit FE absorb treat & time-invariant matching covars (fine — FE dominate). Run on area_frac (MapBiomas, no survival bias), log whole-basin ET, log orchard ET (cleanest H2). Also run a year-FE-only + matching-covar version to recover the doubly-robust LEVEL ATT as cross-check.
2. SECONDARY (divergence/pre-trends test, NOT clean causal): dynamic event study `i(year, treat, ref=2009)` around megadrought onset, unit+year FE. Pre-2009 leads = parallel-trends evidence; post-2009 lags = descriptive divergence under common drought, never a clean effect.
3. SMALL (mechanism probe): triple-difference `treat:spei_c:irr_share_c` on orchard ET — does the slope gap widen with induced-demand intensity.
4. DROP: commissioning staggered event study (CS/SA/dCDH) — ~3 in-panel events, 2 at onset; keep only as descriptive mini-case (El_Bato 2013). DROP naive treat x post TWFE entirely (the forbidden spec).

**Why year FE break the confound:** year FE remove the common megadrought shock; identification is then differential response to a GIVEN forcing level between matched basins. Exposure lives in spei; the reservoir effect is how the spei->outcome MAPPING differs. The estimand is a SLOPE not a level, so siting-in-arid-central-Chile biases levels not slopes. Frame year-FE absorption as a feature.

**Transforms:** area as area_frac (basin-normalized, comparable across ~10x siting gap); ET as log (multiplicative buffering); center SPEI (spei_c) so treat main effect reads at mean forcing.

**Inference (~18-24 treated clusters):** wild cluster bootstrap (fwildclusterboot::boottest, Rademacher B=9999, clustid=subcuenca) as PRIMARY on the single coef; Webb 6-pt if treated clusters < ~12; permutation/randomization within kg_group x aridity-tercile blocks as design-based corroboration. Real n = ~24 treated trajectories, not 265x26 cells.

**Decision rule:** triple null CONFIRMED (with stronger within-unit ID) iff Design-2 pre-2009 leads jointly flat AND treat:spei_c CI covers 0 on all 3 panels (wild boot) AND aridity placebo null. OVERTURNED (H2) iff treat:spei_c>0 on area and/or triple coef>0, surviving wild boot, with flat pre-trends.

**Key placebos:** (i) aridity placebo — swap treat for high-aridity-tercile among CONTROLS only; must be ~0. (ii) pre-megadrought slope 1991-2009 (SPEI available back to 1991); must be ~0. (iii) SPEI-12 is meteorological so exogenous to reservoir operation — NEVER use SSI/storage as the forcing (post-treatment/bad control).
