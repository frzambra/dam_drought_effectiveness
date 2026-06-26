---
name: forcing-att-internal-tensions
description: Two unresolved over-claims in the 2026-06 forcing-conditioned ATT results — the 0.06-vs-0.22 aridity contradiction and the weak-null on irrigated cover
metadata:
  type: project
---

The 2026-06 forcing-conditioned ATT work (zNPP~SPEI transmission slope, matched DR ATT) reached an
H2-null reading. Two tensions in the docs are NOT yet resolved and should be challenged before any
manuscript ships:

1. **The 0.06-vs-0.22 aridity contradiction (load-bearing).** `2026-06-26_forcing-conditioned-att.md`
   argues baseline aridity can mechanically explain only ~+0.06 of the +0.31 basin-mean ATT
   (controls-only slope-aridity gradient −0.072/log-unit × Δlog≈0.85). But the robustness battery shows
   adding `log_aridity²` REMOVES ~0.22 (0.33→0.11). Both cannot be true. Either nonlinearity is huge, or
   aridity² is collinear with treatment and over-subtracting real signal. The team cites 0.06 to defend
   the effect AND 0.11 to dissolve it. **Discriminating test:** flexible `s(log_aridity)` (mgcv) +
   placebo-"fake-dam" assigned to most-arid undammed controls. Cheap (hours), decisive.

2. **"Dissolves entirely" is an over-claim.** Natural-cover ATT survives aridity² at 0.127 (t=2.03,
   CI [0.004,0.249]) — small but excludes zero. Plausibly riparian/groundwater enhancement of natural
   veg near reservoirs (a real reservoir effect), not pure aridity. Correct framing: "attenuates to a
   small residual of unresolved origin," not "dissolves."

3. **The irrigated-cover null is WEAK evidence of absence, not positive evidence.** Both irrigation
   decoupling (irrigation buffers greenness in both groups) and zNPP ~1km grain dilution over fragmented
   orchards predict a null on irrigated cover whether or not H2 is true. The framing doc leans on "even
   ground-truth orchards give a null" as a strength — it is the LEAST informative stratum. Real test is
   ET/consumptive use (SETI is on disk) and pure-orchard high-res pixels, not greenness.

**How to apply:** Before the methods/cautionary paper ships, require tests for (1) and (3). Lever 4
(pre-2005 placebo transmission slope, 1991–2004 SPEI exists) is listed in identification-strategy.md but
apparently unrun — it is a sitting falsification gate. Related: [[reservoir-drought-alternatives]],
[[megadrought-shared-shock]]. The core question (water availability) stays unanswerable until streamflow/SSI lands.
