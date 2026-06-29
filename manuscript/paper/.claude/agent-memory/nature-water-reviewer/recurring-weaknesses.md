---
name: recurring-weaknesses
description: Recurring methodological patterns in this project's analyses to scrutinize
metadata:
  type: feedback
---

Patterns seen across this team's work (H1-H8 program + manuscript). Watch for these.

**Why:** This project has pivoted through many hypotheses (H1-H4 nulls, H8 retired) toward a null-as-finding paper; the danger mode is converting underpowered failure-to-reject into a positive discovery.

**How to apply:**
- Null-as-finding logic: the team is strong on framing but repeatedly leans "we couldn't reject" as if it were "it's zero." Always demand the equivalence/MDE bound AND a positive control showing the design can detect a true effect.
- Small clusters (~21 treated, n=26 reservoirs): cluster-robust SEs over-reject; they correctly use randomization inference but the underlying power is low. Generalizability ("everywhere siting is non-random") is an argument, not evidence — one country/one drought.
- Confound control by DR "mop-up" rather than balance: they decline to balance baseline aridity (the genuine confound) to preserve ESS, then adjust. Check nonlinear/quadratic confound sensitivity — they already found 0.33->0.11 swings.
- Selective framing of estimates: convergent-null count includes near-zero-power outcomes (irrigated-area MDE 7325% of baseline) and a CI-excludes-zero ET result. Press on what each estimator can actually rule out, individually.
- Causal claims from bare trends: storage-band title claim is a time-series slope with no counterfactual. The team sometimes lets a plausible reading of a trend stand in for identification.
