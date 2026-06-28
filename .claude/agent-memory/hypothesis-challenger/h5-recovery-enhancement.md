---
name: h5-recovery-enhancement
description: H5 "recovery enhancement" hypothesis — sharpened estimand, dominant confounds, decisive falsifier, and honest prior after H1/H2 failed
metadata:
  type: project
---

**H5 (proposed 2026-06):** Dammed basins RECOVER from drought faster/more completely than matched
controls (rebound limb), distinct from H1 buffering (onset limb) and H2 induced-demand. Reached for
AFTER H1 and H2 failed under permutation inference — watch for hypothesis-survivorship / motivated search.

**Is it distinct from H1?** Yes, mechanistically: H1 = onset slope (how fast greenness falls as forcing
worsens); H5 = recovery slope (how fast it returns as forcing improves). A reservoir can be invisible on
drawdown yet visible on rebound (refill + continued release). So NOT just H1 relabeled — IF the asymmetry
is real.

**Recommended single estimand (avoid the 5-way forking-path menu):** onset/recovery ASYMMETRY in the
contemporaneous forcing-transmission slope. fixest, monthly zcNDVI-6:
`zcNDVI6 ~ treated*SPEI12*rising | subcuenca + year_month`, weight=entropy-balance w,
rising=1{dSPEI12>0}. **H5 parameter = the triple interaction `treated:SPEI12:rising`.** Inference by
PERMUTATION of treatment label within kg_group × aridity-tercile strata (>=2000 draws) — the procedure
that killed H1/H2. Avoid time-to-baseline (no clean events in persistent megadrought) and
conditional-on-storage (storage is post-treatment/endogenous — collider; see [[endogenous-operation-rules]]).

**Dominant confounds that FAKE enhanced recovery (all point the SAME direction as H5, so stronger threat
than for H1):**
1. Cropland phenology — managed veg rebounds fast/complete after any water pulse regardless of reservoir;
   dammed basins ~10x cropland. THE decisive rival. See [[reservoir-drought-alternatives]] item 1.
2. Regression-to-the-mean of z-anomalies — deeper drawdown mechanically rebounds faster; dammed reach
   deeper (aridity/cropland). Control via depth-of-anomaly reached.
3. Baseline-aridity / Mediterranean phenological speed — same gate as the unresolved 0.06-vs-0.22
   tension in [[forcing-att-internal-tensions]]; test with flexible s(log_aridity) + fake-dam placebo.
4. Operating-policy refill (reverse sign) — refill priority could SLOW treated recovery; a null may mask
   canceling effects.
5. MODIS asymmetric saturation + reflooded shoreline pixels — mask water/shoreline, replicate with EVI.
6. One shared return event (~2023) within the megadrought — leave-2023-out + episode block-bootstrap.
   See [[megadrought-shared-shock]].

**SINGLE MOST DECISIVE FALSIFIER: the natural-cover-only split.** If enhanced recovery exists in cropland
but vanishes in natural vegetation, H5 = cropland phenology, dies same death as H1/H2. One cheap model run.

**Confirm only on the conjunction:** positive triple interaction, perm p<0.05 within strata, SURVIVES in
natural-cover-only, survives flexible s(log_aridity), null fake-dam placebo, null pre-2005 placebo
(1991-2004 SPEI exists), no collapse on leave-2023-out/episode bootstrap.

**Honest prior: ~15-20% H5 reflects a real reservoir effect; expect collapse to siting+cropland+mean-
reversion.** But it is the best-designed remaining shot. Run natural-cover-only FIRST before any
engineering investment.
