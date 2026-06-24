---
name: treatment-design-constraints
description: Why staggered-adoption DiD is mostly infeasible here; n and commissioning structure of the 26 Chilean reservoirs
metadata:
  type: project
---

Verified 2026-06-23 from first-non-empty month per reservoir in the storage CSV.

**Commissioning structure (start of storage reporting ~ commissioning/filling):**
- ~21 of 26 reservoirs report from 2005-01 (LEFT-CENSORED — built before the panel; no in-panel "off->on" switch, so no clean pre-period within these data).
- Only ~5 switch on during the panel: Ralco & Panque (~2006-05), Convento_Viejo (~2009-05), Aromos (~2010-05), El_Bato (~2013-06).
- Net: a within-panel staggered-adoption event study has effectively ~5 treated switches, several large hydropower (Ralco/Panque/Colbon/Laja) not irrigation -> weak for H2.

**Implications for design:**
- Pure DiD/event-study on commissioning is UNDERPOWERED and confounds with mega-drought onset (Convento_Viejo/Aromos commission right as the 2010 mega-drought begins) -> see [[megadrought-confound-t1]].
- Better levers: (1) treat storage as a CONTINUOUS DOSE / state (percent-of-capacity, slack) interacted with meteorological deficit; (2) cross-sectional dammed-vs-matched-control contrast on basin response functions; (3) the ~5 true switch-ons as a small corroborating event study, not the main design.
- Heterogeneity is severe: capacities span 10 hm3 (Culimo) to 5582 hm3 (Lago_Laja); irrigation vs hydropower purpose differs -> never pool naively; stratify by purpose and normalize by capacity.
- n=26 with strong spatial/latitudinal clustering -> cluster-robust SEs unreliable; use wild-cluster bootstrap and/or permutation/randomization inference, and Bayesian partial pooling (brms) over basins.
