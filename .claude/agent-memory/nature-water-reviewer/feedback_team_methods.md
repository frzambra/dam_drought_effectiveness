---
name: team-methods-conventions
description: Statistical conventions and strengths this team uses; what to credit and what to keep probing
metadata:
  type: feedback
---

Conventions to credit (already standard practice for this team — do not re-litigate):
- Permutation/randomization inference within Koppen x aridity-tercile strata is the trusted inference; cluster-robust SEs at ~17-24 clusters are known to over-reject and are reported only as a foil.
- Identification is forcing-conditioned (outcome = deficit->impact slope treat:spei_c), never off calendar time, because megadrought is collinear with siting.
- Pre-trend Wald tests + in-space/in-time placebos + upstream-of-dam placebo are run as falsifiers.
- aridity-squared flexible control is the standard confound stress test (linear aridity under-controls a convex slope-aridity curve).

**Why:** the megadrought-siting collinearity and few-treated-clusters are the two paper-sinking threats; the team has internalized both.
**How to apply:** focus review effort on (1) whether a NULL is powered enough to be a real null vs underpowered (demand a formal equivalence test / TOST or minimum-detectable-effect), (2) the absence of a naturalized-inflow mass-balance counterfactual and operating rules, and (3) novelty framing required to make a rigorous null publishable in NW.

Recurring pattern: apparent signals (QR tail +0.058; overshoot p~0; basin-ET DiD p=4e-5; cluster-robust SSI p=0.03) repeatedly collapse under permutation or fail their own pre-trends. The methodological cautionary tale (siting confound manufactures spurious buffering) is itself a candidate contribution.
