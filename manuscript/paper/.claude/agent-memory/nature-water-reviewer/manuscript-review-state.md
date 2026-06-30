---
name: manuscript-review-state
description: Standing review verdict and blocking-objection status for the "mark not make" Nature Water draft
metadata:
  type: project
---

Manuscript: "Reservoirs mark, but do not make, drought vulnerability..." (Zambrano). Retitled from the old "inflow not storage" framing.

**Round 2 verdict (2026-06-29): Minor Revision (accept-in-principle pending remaining gaps).** Major lift from R1. The 5 blocking objections are now genuinely addressed, not just reworded.

**Status of the 5 R1 blocking objections:**
1. Inflow-not-storage title claim — RESOLVED. Title changed to "mark not make"; storage band relabelled descriptive (no control; cannot separate inflow from demand drawdown) in results.qmd ("Storage declines...") and discussion. Demoted to "strong hypothesis."
2. Whole-basin ET selective retirement — RESOLVED. Now relabelled "confounded*" (not "null"), event-study pre-trends p~1e-10 stated, exclusion from equivalence justified, noted it points toward vulnerability. Handled in open view, results.qmd "No operational reservoir effect..." para.
3. Equivalence overclaim — RESOLVED. Now explicitly states no outcome is formally equivalent to zero; only large effects (>46-59% baseline) excluded; a 20-45% buffer NOT ruled out; causal weight shifted to placebo. table_equivalence.csv all equivalent=FALSE, matches text.
4. Aridity curvature — RESOLVED. New "Sensitivity to aridity adjustment" subsection: residual SMD 0.17 disclosed, DR adjustment called load-bearing, quadratic term moves proxy slope +0.33->+0.11 and irrigation 0.08->0.01. In main text now.
5. Upstream placebo internal validity — PARTIALLY RESOLVED. New table_placebo_check.csv: up gauges higher (1003 vs 459 m), elevation predicts transmission among controls (-0.21/km, p<0.001), BUT raw up/down slopes near-identical (0.565 vs 0.599) and buffering stronger upstream (-0.20 vs -0.16). The elevation confound is now measured, not assumed. Residual gap: regional collapse still leans on the small southern subset (per H7 doc, south 7t/39c); north has few controls. This is acknowledged as a limitation but not fully cured.

**NEW issues found in R2:**
- Sample-size inconsistency: abstract/results say "21 dammed vs 244 control" but ESS≈91 (methods correctly states this). The 244 is the raw in-window control count, not the effective one. Cosmetic but a sharp reviewer will flag the headline n.
- Positive control only validates the STREAMFLOW estimator. The vegetation/ET/area nulls have no positive control; their informativeness still rests on near-zero-power MDEs (irrigated area MDE = 7325% of baseline). Text should not let the streamflow positive control implicitly vouch for the other nulls.
- "Decisive" is used for the placebo in both abstract and discussion while the same paragraphs concede a residual elevation/regime caveat and a small southern subset. Tone slightly outruns the (good) evidence; soften "decisive" to "the strongest single discriminator."

Novelty verdict unchanged: the within-basin upstream/downstream placebo is the genuine, transferable identification advance and is now properly load-bearing. The substantive "mark not make" conclusion is well-scoped to Chile/one megadrought.
