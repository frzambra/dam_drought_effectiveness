# Nature Water — Simulated Reviewer Report (two rounds)

**Date:** 2026-06-29
**Reviewer:** `nature-water-reviewer` agent (skeptical, statistically sophisticated Reviewer #2 register)

| Round | Manuscript title at review | Recommendation |
|---|---|---|
| **1** | *Under aridification the binding constraint is inflow, not storage…* | **Major Revision** (leaning Reject) |
| **2** | *Reservoirs mark, but do not make, drought vulnerability…* | **Minor Revision** (accept-in-principle) |

Round 1 is recorded below; the **Round 2 re-review** (after the authors' revisions) is appended at the end.

---

# Round 1

**Files reviewed:** `manuscript/paper/{manuscript,introduction,methods,results,discussion}.qmd`, `references.bib`; design docs (`docs/design/`, `docs/hypotheses/`); results tables (`results/tables/table_main_results.csv`, `table_equivalence.csv`, `table_storage_band.csv`).

---

## Recommendation: **Major Revision** (leaning Reject in present form)

The genuinely novel and valuable contribution is the **within-basin upstream/downstream placebo** as a transferable identification tool for separating reservoir *regulation* from reservoir *siting*. That idea is good and defensible.

The problem is a mismatch between marketing and evidence: the paper headlines a **substantive discovery** ("inflow not storage; dams are supply-blind") that its strongest evidence cannot causally support, and it rests the central claim on a **null it concedes is not an equivalence**. The contribution that *is* solid (the identification method and a credibly bounded null) is more modest than the title promises.

| Lens | Assessment |
|---|---|
| **Novelty** | Method (within-basin placebo) is novel and transferable. The substantive "inflow not storage" framing is asserted beyond what the design identifies. |
| **Causal rigor** | Strong for the placebo logic; weak for the title claim (no control group, no inflow series) and undermined by an unaddressed aridity-curvature sensitivity. |
| **Policy relevance** | High *if* the causal claims hold; as written the "supply-blind" recommendation outruns the identified estimand. |

---

## Five blocking objections (all verified against the results tables)

### 1. The title claim is unidentified
"The binding constraint is inflow, not storage" rests entirely on `table_storage_band.csv` — a **pooled reservoir-fixed-effects time trend with no control group and no inflow series**. A flat-amplitude downshift of the storage band is **equally consistent with rising demand-side drawdown** — the very mechanism the paper champions elsewhere — as with declining inflow. The analysis also pools ~22 reservoirs, **not** the matched-21 causal sample, so it is not on the same footing as the rest of the paper.
**Fix:** demote the inflow claim from the title/abstract, **or** add a naturalized/observed inflow series (or a demand-side decomposition) that can actually distinguish falling supply from rising demand.

### 2. The whole-basin ET result is mislabeled a null
`table_main_results.csv`: whole-basin ET slope gap = **+0.048, 95% CI [0.0255, 0.0703]** — the CI **excludes zero**; p_perm = 0.11; the sign points *toward* the vulnerability direction. It is also the **only outcome omitted from `table_equivalence.csv`**. Presenting it among "convergent nulls" while dismissing it post hoc (barren-land confound, pre-trend failure) reads as selective reporting to a skeptical reviewer.
**Fix:** apply equal rigor — either rehabilitate it with the same equivalence/permutation machinery used elsewhere, or justify its exclusion transparently in the main text rather than in passing.

### 3. No outcome is statistically equivalent to zero
`table_equivalence.csv`: `equivalent = FALSE` for **all four** outcomes. The streamflow design can only exclude buffering **> 46–59%** of baseline transmission, so a **policy-relevant 20–45% buffer is not ruled out**. The Results claim to "rule out the order of buffering that would justify storage expansion" therefore overreaches.
**Fix:** state plainly that the design rules out only *large* effects; soften the policy inference accordingly; let the placebo (not equivalence) carry the causal weight, and say so explicitly.

### 4. Aridity-curvature sensitivity is hidden
`docs/design/matched-controls.md`: the forcing-conditioned ATT swings **0.33 → 0.11** under a quadratic aridity term, with residual aridity **SMD 0.17 (> 0.1 threshold)**. Linear/doubly-robust adjustment under-controls a genuine confound, so the headline null may partly be an adjustment artifact.
**Fix:** bring this sensitivity into the **main text**, not the design appendix; report the curvature-robust estimate alongside the headline.

### 5. The decisive placebo is decisive only where it is weakest
The regional collapse to −0.03 is driven by the **wet south (7 treated / 39 control; southern p_perm = 0.78)**, where drought is *least* binding; the **arid north has only 5 controls and is "unstable."** Moreover, upstream gauges may differ from downstream in **drainage area, elevation, and snow fraction**, so "up ≈ down" could reflect a **hydrologic regime difference**, not the absence of regulation.
**Fix:** validate upstream/downstream **hydrologic comparability** (area, elevation, snow fraction); report the contrast where drought actually binds (arid basins) with honest power caveats; avoid leaning the headline on the low-power southern subset.

---

## Required revisions (to be competitive at Nature Water)

1. **Demote or identify the inflow claim.** Remove "inflow not storage" from the title/abstract, or add a naturalized-inflow / demand-decomposition analysis on the matched sample.
2. **Treat the ET result with equal rigor.** Run it through the equivalence/permutation pipeline; stop labeling a CI-excludes-zero estimate a "null" without justification.
3. **Foreground the power limits.** Make the bounded-null (non-equivalence) explicit; rescale the policy claims to what the MDE supports.
4. **Surface the aridity-curvature sensitivity** in the main text with a curvature-robust estimate.
5. **Validate the placebo's hydrologic comparability** and report it where drought binds, with power caveats.
6. **Add a positive control** demonstrating the design can detect a true effect when one exists (e.g., a known regulated/buffered system, or a simulation injecting a known buffering signal) — essential to make any null persuasive.

## Recommended (strengthen, not blocking)

- Move the within-basin placebo to the front as the paper's *primary* methodological contribution; let the substantive null be the application.
- Reconcile the pooled storage-band sample (~22) with the matched-21 causal sample.
- Quantify the siting-confound decomposition (naive → FE → design ladder) in the main text, since it is the cleanest demonstration of the central thesis.

## Alternative explanations to rule out

- **Rising demand drawdown** (not falling inflow) producing the storage-band downshift — directly competes with the title.
- **Upstream/downstream regime differences** (area/elevation/snow) producing "up ≈ down" without implying absence of regulation.
- **Residual nonlinear aridity** producing the forcing-conditioned null (objection 4).
- **Residual SUTVA** (adjacency, shared aquifers) surviving the contamination rule.

---

## Bottom line

The paper has a real methodological contribution and a credibly *bounded* null, but currently over-claims on three fronts: an unidentified title, a mislabeled ET result, and an equivalence the data do not establish. Reframing the paper around the **identification method + a transparently bounded null**, and either demoting or properly identifying the inflow claim, would convert a likely reject into a competitive submission.

*Reviewer state persisted at `manuscript/paper/.claude/agent-memory/nature-water-reviewer/` for consistency across future review rounds.*

---

# Round 2 — Re-review after revision

**Recommendation: Minor Revision (accept-in-principle).**

The authors revised against all five Round-1 blocking objections with substantive analysis and honest relabelling, not rhetoric. The emphasis is now correctly inverted: the within-basin upstream/downstream placebo is the load-bearing claim, and the weaker substantive readings ("inflow not storage") are properly demoted. What remains are tightening issues, not identification failures.

**Files re-checked:** all five `.qmd`; `table_main_results.csv`, `table_equivalence.csv`, `table_storage_band.csv`, `table_placebo_check.csv` (new), `table_positive_control.csv` (new); `src/R/causal/placebo_validation.R`, `src/R/drought/storage_band.R`.

## Status of the five blocking objections

| # | Objection | Round-2 status | Evidence checked |
|---|---|---|---|
| 1 | "Inflow not storage" title was a bare pooled trend | **Resolved** | Title changed; storage trend relabelled descriptive ("cannot distinguish declining inflow from rising demand"); discussion calls it "a strong hypothesis rather than an identified result" |
| 2 | Whole-basin ET mislabeled a null (CI excludes zero) | **Resolved** | Even-handed treatment; verdict hard-set "confounded\*"; exclusion from equivalence stated; noted it points toward *vulnerability*, so retiring it doesn't rescue the narrative |
| 3 | Equivalence over-claim | **Resolved** | States no formal equivalence; only large effects (>46–59%) excluded; 20–45% buffer *not* ruled out; weight moved to placebo |
| 4 | Aridity curvature hidden | **Resolved, turned to advantage** | New Results subsection; SMD≈0.17 + load-bearing DR disclosed; quadratic moves +0.33→+0.11 *toward* the null; direction-of-bias argument makes nulls conservative |
| 5 | Upstream-placebo internal validity | **Partially resolved** | New `table_placebo_check`: elevation gap real and confound acknowledged (−0.21/km, p<0.001), but up/down raw slopes near-identical (0.565 vs 0.599) and buffering stronger upstream. Residual: within-region collapse still leans on the small southern subset (7 treated/39 control) |

## New issues introduced by the revision (minor, fixable)

1. **Headline n is misleading** — abstract/results cite "244 controls," but the entropy-balanced effective sample is ESS≈91. Report ESS≈91 (or "244 controls, ESS≈91") at first mention.
2. **Positive control validates only the streamflow estimator** — the area/ET nulls have no positive control and near-uninformative MDEs (irrigated-area MDE = 7325% of baseline). Add a sentence that they rest on the placebo + conservative-bias argument, not on their own power.
3. **"Decisive" overruns the conceded caveats** — with a measured-but-not-eliminated elevation confound and a 7-basin southern collapse, downgrade "decisive" to "cleanest within-design falsification" (already used and well-calibrated) in abstract and discussion.
4. **ET "neither buffer nor amplify" needs magnitude-qualifying** — the orchard-ET and cross-sectional ET nulls are low-power (orchard-ET MDE = 237% of baseline), so phrase as "no large effect detected," as the streamflow claim already is.

## Three lenses (Round 2)

- **Novelty — sufficient.** The within-basin SPEI→SSI placebo is a genuine, transferable identification advance; now that overclaims are demoted it sits where the evidence is strongest. Clears the bar as a methods-plus-finding contribution.
- **Causal rigor — now strong, appropriately bounded.** No longer confuses "fail to reject" with "zero"; identifies a *cause* (siting/aridity) for the apparent effect; validates detection power; discloses the load-bearing aridity adjustment. Residual: regional collapse leans on a small southern subset.
- **Policy relevance — high and defensible.** "Adding storage to basins whose inflow is declining is a supply-blind response" is actionable and now hedged to the drought effect and to what the design can rule out; the Water Code framing gives international reach.

## Remaining gaps to close before submission (conditions for Minor Revision; no new data needed)

1. Report **ESS≈91** at first mention (abstract + Results), not the raw 244.
2. **Scope the positive control** explicitly to the streamflow estimator; state the area/ET nulls rest on the placebo + conservative-bias argument.
3. **Recalibrate "decisive"** → "cleanest within-design falsification" in abstract and discussion.
4. **Qualify the ET "neither buffer nor amplify"** claim to detectable magnitude.
5. *Optional, strengthening (not blocking):* a naturalized-inflow series / coarse demand decomposition on a subset of basins to settle the inflow-vs-demand ambiguity behind the storage trend — already flagged in the outlook; add one sentence on why it was out of scope.

**Summary for the editor:** all five blocking objections addressed with substantive analysis; the remainder is sample-size reporting, positive-control scoping, and tone calibration. With those addressed this is a publishable, well-identified, policy-relevant contribution whose methodological core is novel and transferable. **Minor Revision.**
