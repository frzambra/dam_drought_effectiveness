---
name: project-editorial-log
description: Log of editorial recommendations rendered and the project's revision trajectory
metadata:
  type: project
---

**2026-06-24 — First-analysis recommendation (PI asked where to START).**

Recommended FIRST analysis: storage-state-conditional meteorology->ET/vegetation contrast (the EMPIRICAL CORE of H1), on matched dammed/undammed WATERSHEDS.
- Outcome: SETI (primary), zcNDVI-6 (cross-check). Forcing: SPEI at data-selected timescale (let control-basin cross-correlation pick it; likely SPEI-6 or -12).
- Modifier: percent-of-capacity storage. Estimand: difference-in-slopes (drought sensitivity) dammed vs control + threshold interaction (does dammed slope exceed control slope once S < s*?).
- Model: fixest interaction `Y ~ SPEI*dammed*I(S<s*) | unit + month` + threshold search.

**Rationale / editorial stance:** cannot claim the buffer ERODES (H2 headline) before showing the buffer EXISTS (H1 core). H2 DiD/mediation is "chapter 3" — do NOT start there. This first analysis is the FALSIFICATION GATE for the whole program: if dammed/undammed slopes are equal, H2 has nothing to erode.

**Binding constraint flagged:** spatial unit — dam POINT must be replaced by contributing watersheds + downstream command areas before ANY number is publishable.

Axis scores for the proposed start: Novelty 4/5, Causal 3/5 (correct first rung), Policy 4/5.

(No manuscript or results reviewed yet — verdict pending data + first analysis.)
