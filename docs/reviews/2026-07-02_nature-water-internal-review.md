# Internal Nature Water Review — Full Manuscript and Supplementary (Reviewer 3 Revision Round)

**Date:** 2026-07-02
**Reviewer:** Internal Nature Water reviewer simulation (Reviewer #1 standard)
**Scope:** `manuscript/paper/*.qmd` (abstract, introduction, methods, results, discussion), supplementary-feeding result tables, the two new robustness analyses (`src/R/drought/snow_placebo.R`, `src/R/causal/spillover_demand_checks.R`), and the latest Reviewer 3 exchange (`docs/reviews/2026-07-02_reviewer3.md`, `docs/reviewer_responses/2026-07-01_reviewer3_response.md`, `docs/reviewer_responses/2026-07-02_reviewer3_response.md`).

---

## Recommendation

**Major Revision.** The identification strategy and the battery of falsification tests are genuinely strong and close to Nature Water grade, but the two new robustness analyses do not fully close the holes they claim to, the demand-side "nulls" are materially underpowered in a way the convergent-null framing obscures, and three internal-consistency errors flagged by Reviewer 3 remain live in the current text.

---

## Summary of Claims

The paper argues that in central Chile's megadrought, reservoirs do not causally buffer or amplify multi-year drought on any operational pathway (streamflow transmission, ET, cropland area, consumptive water rights); the apparent buffering seen in naive comparisons is a siting/aridity confound, decisively demonstrated by an upstream(unregulated)/downstream(regulated) within-basin placebo showing equal "buffering" above and below the dam. Reservoirs "mark, not make" vulnerability; storage falls in step with declining supply while refill amplitude is statistically unchanged; adaptation should shift to demand management. Scope is explicitly restricted to annual-to-multiyear timescales, not sub-seasonal operation.

---

## Novelty Assessment

The central methodological asset, the within-basin upstream/downstream placebo combined with the forcing-conditioned slope estimand and the siting-confound decomposition ladder, is a real, transferable contribution and is the strongest reason this could clear the Nature Water bar. Reframing the socio-hydrological reservoir-effect hypothesis as a falsifiable causal test with a credible within-basin counterfactual is novel relative to the dammed-vs-undammed and before-after literature the paper cites (`introduction.qmd` L27-28, L47-50). This is defensible for the venue **as a rigorous-null / causal-cautionary paper**, consistent with the prior internal review of this project (2026-06-28).

However, the "convergent null across every operational pathway" framing (abstract L23-24; `results.qmd` sec-bounding) oversells the demand-side arm. As detailed below, the demand-side DiD nulls are near-uninformative on their own power terms, so the paper's breadth claim rests almost entirely on one pathway (streamflow) plus one clean placebo. The novelty is real but narrower than the abstract implies.

---

## Causal Evidence Assessment

The streamflow claim is well-identified: the upstream placebo carries no aridity adjustment, the elevation confound is bounded and over-explains the residual, and the positive control demonstrates the design would detect a large effect. This is the paper's causal backbone and is largely credited.

Causal overreaches and unresolved threats:

1. The snowmelt placebo (new) is presented as empirically excluding the dominant within-basin confound, but the test it runs does not match the estimand it must defend and relies on a product with the same defect the authors reject elsewhere (Major Concern 1).
2. The non-stationary-snowmelt threat (Reviewer 3, comment 7) is answered with a **static** snow climatology, which by construction cannot address a *degrading* buffer (Major Concern 2).
3. The demand-side nulls are framed as informative causal nulls but are underpowered by their own equivalence table (Major Concern 3).
4. The administrative-closure counterfactual (Reviewer 3 comment 2) is answered with an aggregate "registry not closed" statistic that does not test the *differential* utilization/closure between treated and control basins the reviewer actually asked for (Major Concern 4).

---

## Major Concerns

### 1. The new snow placebo tests the wrong estimand and leans on a product with the exact flaw the authors reject for MOD16

(`src/R/drought/snow_placebo.R`; `results/tables/table_snow_placebo.csv`; `discussion.qmd` L142-152)

- **Estimand mismatch:** the main placebo is a *differential* (dammed-minus-control) treat:SPEI slope of −0.20 upstream vs −0.16 downstream, difference −0.04 (`results.qmd` L30-31, L47). The snow check instead operates on **raw per-gauge transmission slopes** (upstream 0.565 vs downstream 0.599, difference −0.033; `build_snow_placebo_check`, lines 52-83) on a different, gauge-level sample (n_up=28, n_down=40) than the 15-basin placebo. The snow confound must be shown not to drive the −0.04 *differential*, not a −0.033 raw gap on a different sample. As written, the check does not defend the quantity the placebo actually reports.
- **Product-quality double standard:** the authors reject MOD16 for underestimating irrigation ET (`discussion.qmd` L153-160) yet close the snow hole with ERA5-Land SWE at 0.1° (~9 km), which is well documented to underrepresent Andean headwater snowpack; the reported peak SWE of 0.04-0.068 m w.e. is implausibly low for these catchments. A null snow-slope sensitivity may simply reflect that ERA5-Land barely resolves the true up/down snow gradient. Reviewer 3 will note the inconsistency immediately.
- **Zero-by-construction bound:** the reported control-gauge sensitivity is "0 per m w.e., p = 1.00" (table row 3). A coefficient of exactly zero with p exactly 1.00 is not a credible statistical result; it is a rounding/scaling artifact (peak SWE values ~0.04-0.07 m are tiny, so the coefficient rounds to 0 at three digits and the bound `SWE gap × sensitivity` is then mechanically 0). **Report the coefficient, its standard error, and CI at full precision, on standardized SWE**, so the bound is not zero by construction.
- **Required:** rerun the snow check on the *differential* placebo estimand and the 15-basin sample; report full-precision, standardized coefficients; and either justify ERA5-Land SWE against an independent high-resolution product (e.g., MODIS fractional snow cover, as Reviewer 3 suggested) or restrict the placebo to genuinely non-snow-dominated catchments.

### 2. "Snow-free basins" are mislabeled, and the static climatology cannot address the non-stationarity threat

(`src/R/drought/snow_placebo.R` L59-60; `discussion.qmd` L149)

- The "snow-free" split is `peak_swe < median(peak_swe)` (lines 59-60), i.e. the *below-median-snow half*, not snow-free basins. With n_up = 6 in that half, the claim "upstream buffering persists without snow (0.57 vs 0.61)" (`discussion.qmd` L149; table row 5) is (a) not a snow-free comparison and (b) rests on six upstream gauges. Rename honestly and report the actual SWE range in each half.
- `aggregate_swe_climatology` reduces SWE to a long-term mean and mean-annual-peak (lines 14-27), a **static** climatology. Reviewer 3 comment 7 is explicitly about *non-stationary* snowmelt: a degrading upstream snow buffer steepening in parallel with a degrading downstream dam buffer, producing a spurious null difference. A static climatology cannot speak to a trend. The discussion cites Andean snow-decline literature (L136-138) but presents no test of whether the upstream transmission slope is itself non-stationary over 2005-2024. This threat remains open.
- **Required:** estimate the upstream and downstream transmission slopes in early vs late sub-periods (or with a snow-trend interaction) and show the up/down difference is stable, or concede the placebo cannot separate parallel buffer degradation.

### 3. The demand-side "nulls" are underpowered to the point of being uninformative, which the convergent-null framing hides

(`results/tables/table_equivalence.md`; `results.qmd` sec-bounding; `fig-forest`)

- The equivalence table reports MDE = **7,330% of baseline** for the irrigated-area DiD and **237%** for orchard ET, versus 46-58% for streamflow. An MDE of 73× the baseline transmission slope means the design cannot detect anything remotely near a plausible effect for the area outcome; the permutation p = 0.91 is therefore "we could not have found it if it were there," not an informative null.
- The forest plot (`fig-forest`) and the abstract's "brackets zero … across every operational pathway" present all pathways as equally strong nulls. They are not. The manuscript does, to its credit, rest causal weight on the placebo rather than equivalence (`discussion.qmd` L92-101), but the top-line framing does not transmit that the demand-side arm is near-zero power.
- **Required:** report the demand-side MDEs prominently, drop or heavily qualify the "convergent across every pathway" language, and restrict strong null claims to the streamflow pathway where the MDE is informative.

### 4. The administrative-closure check does not test what Reviewer 3 asked, and the collapse-prevention counterfactual is untested

(`src/R/causal/spillover_demand_checks.R`; `results/tables/table_spillover_demand.csv`; `discussion.qmd` L108-116)

- Reviewer 3 comment 2 asked specifically whether the *baseline utilization rate (current allocations vs total renewable water) differs between treated and control basins*, and whether the reservoir *prevented a collapse* relative to controls not at capacity. The new check instead reports an aggregate "new consumptive rights per megadrought year (4,687, range 2,539-7,352)" across all matched basins (lines 20-33). That shows the registry was not *globally* closed, but says nothing about *differential* treated-vs-control closure or utilization, which is the confound. The demand null could still be a forced artifact if treated (arid) basins were differentially closed.
- **Required:** compute a per-basin utilization/closure indicator (e.g., allocated vs renewable supply, or presence of *zona de prohibición*/*área de restricción* status) and test the treated-vs-control difference; and address the asymmetric counterfactual (collapse prevention) at least by bounding.
- Note this check is descriptive only and is not, as far as visible, integrated as a supplementary table with a table number (unlike S10-S12); confirm it has a manuscript home and is reproducible as a named target per the repo's own standard (`methods.qmd` L263).

### 5. Three internal-consistency errors flagged by Reviewer 3 (comments 10-12) are still live in the manuscript

These are the easiest points on which a final-round reviewer blocks acceptance, and none is fixed in the current text.

- **Cropland estimand contradiction (R3-10).** `methods.qmd` L158-160 states the two cross-sectional ATTs "apply this machinery" (the forcing-conditioned transmission slope) to "(i) cropland-area expansion, the change in MapBiomas cropland area per basin over the window", a level change, not a slope. Table 1 lists the estimand as "ha km^-2 added" (`table_main_results.md` row 1). The sentence simultaneously asserts a slope machinery and a level-change definition. Rewrite so it is unambiguous that cropland-area expansion is a level change and only ET buffering is a transmission slope.
- **398 vs 244 controls (R3-11).** `methods.qmd` L34 states "398 clean controls"; L116 states "244 in-window controls" and L124 "158 of 244"; figure captions use 244. The drop from 398 to 244 ("in-window") is never defined. State explicitly what the in-window restriction is (elevation/size common support?) and why 154 controls leave the pool.
- **0.585 vs 0.53 baseline slope (R3-12).** `methods.qmd` L192 uses baseline transmission slope 0.585; `results.qmd` L50-51 uses "the 0.53 baseline transmission slope." The equivalence table shows these are the ITT baseline (0.585) and the downstream baseline (0.531) respectively (`table_equivalence.md` rows 1-2), so it is not an arithmetic error, but the text switches without explanation. Add one clause identifying which baseline each refers to.

### 6. Well-count inconsistency

`methods.qmd` L93 states "216 wells," while `discussion.qmd` L122, both response files, and Reviewer 3 comment 8 all use "213 wells." Reconcile.

---

## Minor Concerns

1. **Abstract precision:** the abstract asserts the storage band "drifts downward while its seasonal refill amplitude shows no detectable change" (L31) but the amplitude interval is wide (`results.qmd` L156-158). "No detectable change" reads as "unchanged"; the body correctly says "cannot be resolved." Align the abstract to the weaker, correct statement.
2. **Well-network representativeness (R3-8) unaddressed:** the groundwater bound (`discussion.qmd` L116-131) argues basin-median drawdown but does not discuss whether monitored wells overlap high-value crop footprints. Add a sentence acknowledging the localized-pumping limitation.
3. **Post-treatment aridity baseline (R3-6) unaddressed:** the 1991-2020 aridity baseline overlaps 11 megadrought years. Either recompute baseline aridity on a pre-2010 window or demonstrate P/PET is invariant to reservoir presence during drought, as requested.
4. **Pre-trend MDE (R3-5) unaddressed:** the pre-2010 cropland pre-trend p = 0.65 (`results.qmd` L119) is interpreted as "flat" without a corresponding MDE; the authors hold themselves to a higher standard elsewhere and should here.
5. **Numeric drift check:** `fig-streamflow` caption and `results.qmd` L30-31 give downstream differential −0.16 while earlier drafts used −0.17; confirm the current figure matches −0.16/−0.20 throughout.
6. **Bidirectional transfers (R3-9) partially addressed:** the inter-basin-transfer argument (`discussion.qmd` L163-175) establishes disjoint cuencas for matched pairs but does not fully address the scenario of an external cuenca importing water *into* a treated basin (e.g., Paloma). For a null result this bias is largely self-defusing (imports would inflate apparent buffering, yet none is found), but the text should state that direction explicitly rather than only the treated-to-control case.

---

## Specific Assessment of the Two New Analyses vs. What the Text Claims

- **Snow placebo:** The text (`discussion.qmd` L142-152) faithfully reproduces the table numbers (up/down SWE 0.068/0.040; sensitivity ≈0, p=1.0/0.81 net of elevation; bound ≈0.00 vs observed −0.03; snow-free 0.57/0.61, snowy 0.57/0.59 — all match `table_snow_placebo.csv`). So it is *correctly reported* relative to the table. But the underlying analysis is not sound enough to close the hole: wrong estimand and sample (raw transmission slopes, gauge-level, vs the differential 15-basin placebo), a zero-by-rounding bound, a coarse SWE product with the same underestimation flaw used to dismiss MOD16, a mislabeled "snow-free" split (below-median, n_up=6), and no test of the non-stationarity that Reviewer 3 comment 7 actually raised. It hardens the placebo against a *static, level* snow difference but not against the *dynamic, differential* confound.
- **Spillover/demand check:** The text (`discussion.qmd` L108-116, L163-171) matches `table_spillover_demand.csv` (14 treated cuencas, 70 control, 0 shared; ~4,687 new rights/yr, range 2,539-7,352; 194 of 265 basins). The disjoint-cuenca result is a solid, correct rebuttal to matched-pair SUTVA. The "registry not closed" statistic is correctly reported but answers a weaker question than Reviewer 3 comment 2 posed (aggregate accrual, not differential closure/utilization), so it does not close the administrative-closure hole.

---

## Internal Consistency Checks

Verified consistent:

- Reservoir counts (26 monitored / 24 treated / 20 irrigation) across abstract, `methods.qmd` L25-28, `discussion.qmd` L179.
- Snow table ↔ discussion text: consistent.
- Spillover table ↔ discussion/response text: consistent.
- Main-results table ↔ forest plot/text verdicts: consistent (including the honest "confounded" relabel of whole-basin ET in the Table 1 chunk).

Failed checks:

- 398 vs 244 controls (unexplained; Major 5).
- 0.585 vs 0.53 baseline slope (ITT vs downstream, unexplained in text; Major 5).
- Cropland estimand described as both slope machinery and level change (Major 5).
- 216 vs 213 wells (`methods.qmd` L93 vs `discussion.qmd` L122 and all response files; Major 6).
- Abstract "no detectable change" vs body "cannot be resolved" for refill amplitude (Minor 1).

Methods-vs-code spot checks:

- `snow_placebo.R` computes a static climatology (mean over years) and splits "snow-free" at the median peak SWE — both at odds with how the discussion frames the test.
- `spillover_demand_checks.R` computes aggregate accrual, not the differential utilization the discussion implies it addresses.
- The repo's "every result is a named target" claim (`methods.qmd` L263) should be verified for the new `table_spillover_demand` output, which lacks a supplementary table number.

**Response-file / review-round mismatch:** the 2026-07-02 response file (`docs/reviewer_responses/2026-07-02_reviewer3_response.md`) opens with "Seven comments" and responds to a 7-comment set (groundwater; aridity/overlap; storage causal language; use heterogeneity; inter-basin transfers; administrative demand; an ET p-value caption fix). The 2026-07-02 review on file (`docs/reviews/2026-07-02_reviewer3.md`) contains **12 comments**, including the three consistency errors (10-12) and the pre-trend-MDE, post-treatment-aridity, and well-representativeness points (5, 6, 8), none of which the 07-02 response addresses. Either the response was written against an earlier/ different comment set or the 12-comment round has not yet been answered; as it stands, the live 12-comment review is only partially addressed, and the unanswered items include the easiest grounds for a final-round rejection.

---

## What a Final-Round Reviewer 3 Could Still Seize On to Block Acceptance

1. The static/coarse snow placebo not matching the differential estimand, and ERA5-Land being the same class of product the authors reject for MOD16 (Major 1-2). This is the single most likely blocking objection because snow is Reviewer 3's repeated concern (comments 1 and 7).
2. The three unresolved consistency errors (comments 10-12) — trivial to fix, embarrassing if they survive another round (Major 5).
3. The demand-side underpowering exposed by the authors' own equivalence table (Major 3), which undercuts "convergent null across every pathway."
4. Unaddressed comments 5 (pre-trend MDE), 6 (post-treatment aridity baseline), and 8 (well-network representativeness) from the latest round.

---

## Required Analyses to Strengthen the Submission

1. Rerun the snow check on the differential (dammed-minus-control) placebo estimand and 15-basin sample; report standardized, full-precision coefficients and CIs; validate or replace ERA5-Land SWE against MODIS fractional snow cover; add an early-vs-late sub-period test of upstream slope stationarity.
2. Compute a per-basin utilization/closure indicator and test the treated-vs-control difference; bound the collapse-prevention counterfactual.
3. Report demand-side MDEs alongside streamflow and requalify the breadth claim.
4. Recompute baseline aridity on a strictly pre-2010 window (or demonstrate P/PET invariance) to remove post-treatment contamination.
5. Add a pre-trend MDE/equivalence statement to match the standard applied to the headline nulls.
6. Fix the six consistency items (Major 5, Major 6, Minor 1).

---

## Questions for the Authors

1. Why does the snow placebo defend a −0.033 raw up/down gap on 28/40 gauges rather than the −0.04 *differential* on the 15 placebo basins? Does the confound bound hold on the estimand you actually report?
2. What is the control-gauge snow sensitivity and its CI at full precision on standardized SWE? Is the reported "0, p=1.00" anything other than a rounding artifact?
3. How do you exclude that ERA5-Land's known Andean-SWE underestimation, not the absence of a snow effect, produces the null snow sensitivity, given you reject MOD16 on precisely this ground?
4. Is the upstream transmission slope itself stationary over 2005-2024? If it is degrading in parallel with the downstream buffer, how does the placebo separate them?
5. Do treated (arid) basins differ from controls in baseline water-rights utilization or formal closure status? Without that, how is the demand null distinguishable from administrative saturation?
6. Given MDE = 7,330% of baseline for the area DiD, in what sense is that outcome an informative null rather than an underpowered one?
7. What is the "in-window" restriction that reduces 398 clean controls to 244, and which baseline (ITT vs downstream) does each of 0.585 and 0.53 refer to?
