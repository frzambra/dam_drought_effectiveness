---
name: project-overview
description: Goals, hypotheses, and target venue for the Chile reservoir-drought project
metadata:
  type: project
---

Project: "Reservoir Effectiveness and Drought Vulnerability in Chile". Target venue: Nature Water (reviewer-#2 level rigor expected).

Two competing/nested hypotheses, threatened by the SAME confounds:
- **H2 (central, load-bearing = MEDIATION):** "Induced demand erases the buffer." Reliable storage lowers perceived irrigation risk -> irrigated area / consumptive ET expands -> buffer committed to larger footprint -> net basin drought protection decays toward zero within ~a decade. Causal claim runs THROUGH cumulative irrigated-area/ET expansion (a mediator), not a direct storage->protection effect.
- **H1 (mechanism = VARIANCE REDISTRIBUTION INTO THE TAIL):** "Storage as drought-signal rectifier." Above critical storage fraction s*, releases decouple downstream availability from meteorological deficit (attenuation). Below s*, suppressed deficit is transmitted at once -> heavier-tailed severe ecological (vegetation/ET) drought in dammed vs matched controls. Novel claim is tail amplification, NOT mere loss of buffering.

**Why:** H1 and H2 are near-observationally-equivalent ("rectifier" ~ "buffer erosion"); the paper's contribution depends on separating them and on ruling out hydrological exhaustion as the sole driver.
**How to apply:** Every design choice must (a) break the mega-drought confound [[megadrought-confound-t1]] and (b) preserve the ability to distinguish mediation (H2) from threshold variance-redistribution (H1).

Tooling stack: R — MatchIt/WeightIt/cobalt, fixest, Callaway-Sant'Anna (did), Sun-Abraham (fixest sunab), synthetic control (Synth/tidysynth/scpi), brms (Bayesian mediation), marginaleffects.
