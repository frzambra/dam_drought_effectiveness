---
name: project-identification
description: Identification strategy decisions — left-censoring kills staggered DiD; use continuous storage-state variation
metadata:
  type: project
---

**Staggered DiD on commissioning is dead on arrival.** ~5 of 26 reservoirs switch on within the 2005-2026 panel -> too few events/pre-periods for Callaway-Sant'Anna or Sun-Abraham. Report as a one-line design justification, not an analysis.

**Why:** most reservoirs left-censored (built before 2005 panel start).

**How to apply — recommended layered design (strongest first):**
1. PRIMARY: continuous-treatment identification off STORAGE DYNAMICS (percent-of-capacity), not commissioning timing. Buffer switches on/off as storage rises/falls; identifying variation is exogenous upstream meteorology. Estimand = storage-state-dependent modification of the meteorology->ecology drought-response slope.
2. Cross-sectional matched PSM / entropy balancing on aridity, baseline irrigated fraction, elevation, area, latitude — vulnerable to endogenous siting, flag it.
3. The ~5 within-panel commissioners as individual synthetic controls (tidysynth) in an appendix, illustrative not headline.
4. Mega-drought confound (2010-present, collinear with time): differenced out by the MATCHED CONTROL ARM experiencing the same shock — control arm is non-negotiable.

**Biggest Reviewer #2 threat:** common-cause confounding by the mega-drought masquerading as a reservoir effect. Defused by (a) matched undammed controls, (b) within-period storage-state s* interaction giving cross-state variation that isn't just "later=drier", (c) H2 mediation gate.
