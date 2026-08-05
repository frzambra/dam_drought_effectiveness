# Nature Water — Reviewer #1 Report

**Manuscript (working):** Reservoir Effectiveness and Drought Vulnerability in Chile — do reservoirs modify drought propagation/impacts, or merely displace vulnerability?
**Reviewer:** Reviewer #1 (senior hydrology / socio-hydrology / causal inference)
**Date:** 2026-06-28
**Materials reviewed:** identification-strategy.md; hypotheses H1–H5 + README; progress summaries 2026-06-24 (aridity/DR-ATT), 2026-06-26 (forcing-conditioned ATT, land-cover disaggregation, ET/placebo diagnostics), 2026-06-28 (ET + irrigated-area acquisition, DiD/event-study, H1 storage-rectifier, streamflow buffering + upstream placebo).

---

## Recommendation

**Reject** in the present form as a Nature Water research article — but this is a *reframe-and-resubmit* Reject, not a fatal one. The science is rigorous and the central empirical claim is, in my judgement, probably correct; what is missing is (i) the conversion of "we detected no effect" into a defensible *equivalence* claim ("we can rule out reservoir effects larger than X"), and (ii) a mechanistic, operations-side counterfactual (naturalized inflow / release records) that would make the streamflow null an affirmative causal statement rather than a design-limited one. As a positive-finding induced-demand paper (the original H2 arc) it is dead; the data killed it, and the authors are right not to resuscitate it.

---

## Summary of Claims

The authors test whether large reservoirs modify meteorological→hydrological→ecological drought propagation across Chile, using a national matched design (21 dammed vs ~236 control subcuencas; entropy-balancing on baseline aridity, Köppen class, elevation, area). Because the treatment is effectively time-invariant (18/24 reservoirs predate the record) and the 2010+ megadrought is collinear with reservoir siting in arid central Chile, they deliberately refuse to identify off calendar time. Instead the estimand throughout is the **differential deficit→impact slope** (`treat:spei_c`) with unit and year fixed effects, and inference is permutation of the treatment label within Köppen × aridity-tercile strata.

Across every outcome and hypothesis the result is a **convergent null**:
- **H2 (induced-demand vulnerability):** null on forcing-conditioned zNPP slope on irrigated land; null ET buffering (DR ATT −0.014, ns); null net irrigated-area expansion (−0.69 ha/km², ns) despite ~10× more cropland in dammed basins; null forcing-interacted DiD slope-gaps with clean flat area pre-trends.
- **H1 (short-term buffering / nonlinear "rectifier"):** ET buffering null; quantile tail contrast dies under permutation (p=0.45); GPD tail-shape runs *opposite* to prediction; only a weak within-treated "buffering-while-full" mean threshold survives.
- **H5 (recovery enhancement):** wrong sign, ns.
- **Streamflow (the direct, vegetation-independent outcome):** SPEI→SSI slope-gap null under permutation; **the upstream-of-dam placebo (physically unregulated) is as strong as the downstream estimate (−0.20 vs −0.17), with no downstream>upstream dose-response.**

Central claim: reservoirs show **no detectable causal effect on drought propagation on any outcome**; cross-sectional dammed-vs-control contrasts reflect reservoir **siting** in arid, hydrologically distinct basins; naive comparisons, calendar-time DiD, and few-cluster cluster-robust SEs **manufacture spurious "buffering."** A methodological cautionary tale plus a substantive national-scale null.

---

## Novelty Assessment

**Verdict: Marginal-to-insufficient as currently framed; potentially sufficient under one specific reframing.**

I separate three candidate contributions, because they do not clear the bar equally:

1. **"Reservoirs don't buffer drought in Chile" (substantive null).** On its own this is **not** a Nature Water contribution. A null national-scale result, however clean, does not meet the journal's "substantial, generalizable advance of broad interest" bar unless it overturns a *specific, widely held, well-evidenced* prior. The manuscript does not yet establish that the literature confidently claims the opposite at this scale; absent that, a reviewer reads this as "a thing many suspected, in one country, was not found." Insufficient.

2. **"Reservoir siting, not regulation, generates the apparent buffering signal" (the confound-identification contribution).** This is more interesting and is the strongest novelty asset, *if* it is generalized beyond Chile in its implications. The claim that endogenous siting in arid, hydrogeologically distinct basins produces a spurious dammed-vs-control attenuation that survives naive and even calendar-time-DiD analysis is a genuine caution to a real and growing literature (basin-mean greenness / dammed-vs-undammed comparisons). The **upstream-of-dam placebo** is the single most novel and most defensible device in the entire submission — it is a within-design falsification that *only the streamflow outcome can deliver* and that, to my knowledge, is rarely deployed in reservoir-impact work. That is publishable-grade methodology.

3. **"Apparent signals collapse under randomization inference at ~20 clusters" (the inference cautionary tale).** True, important for the subfield, but methodologically not new in general statistics (the few-clusters over-rejection of cluster-robust SEs is textbook, e.g. Cameron–Gelbach–Miller; Conley–Taber; MacKinnon–Webb). It strengthens the paper but cannot *be* the paper.

**What would make it novel enough for Nature Water:** fuse (2) with an affirmative mechanism. A clean demonstration — using the upstream/downstream placebo *and* a naturalized-inflow mass-balance counterfactual — that the regulation signal is genuinely absent while the *siting* signal is large and quantifiable, framed as a generalizable warning about how the global reservoir-impact and "dams-as-drought-resilience" literature is systematically confounded by endogenous placement, with Chile as the natural laboratory. The novelty must be the *transferable identification lesson plus a quantified siting confound*, not the Chilean null per se.

**As named, "induced demand erases the buffer" (H2, the originally-pitched 9.4 headline) is not a finding here — it is a rejected hypothesis.** That is fine and honest, but the novelty case cannot rest on it.

---

## Causal Evidence Assessment

**Verdict: The causal *design* is unusually strong for an observational reservoir study; the causal *interpretation of the null* is currently over-reached in one direction and under-supported in another.**

Strengths (state plainly, because they are real):
- Refusing to identify off calendar time given the megadrought–siting collinearity is exactly correct and is the move most reservoir-drought papers get wrong.
- The forcing-conditioned slope estimand (effect on the deficit→impact transmission function, not on levels/trends) is the right target and cleanly separates exposure from effect.
- Permutation inference within climate × aridity strata is the appropriate response to ~17–24 treated clusters.
- The **upstream-of-dam placebo** is a textbook-quality falsification: a physically unregulated comparison that should be null if the effect is causal, and is instead *as large as* the treated estimate. This is the strongest single piece of causal evidence in the submission and it points to siting, not regulation.
- The pre-megadrought placebo on natural-cover slope (gap already present, and larger, before 2010) correctly converts a residual "effect" into a fixed basin trait.

Causal overreaches / unsupported steps (each must be fixed):

1. **"No detectable effect" is repeatedly slid toward "no effect."** A failure to reject the null under a low-cluster permutation test is **not** evidence of absence. With 17–24 treated clusters and noisy per-unit slopes (median R²≈0.07 reported for the zNPP slopes), the design may simply lack power. Every null in the paper currently asserts absence without a corresponding **equivalence test / minimum-detectable-effect (MDE)**. This is the central causal-logic flaw. The claim the paper *can* defend is: "we can rule out reservoir buffering effects larger than [δ]"; the claim it currently *makes* is "there is no effect." These are not the same, and a sophisticated reviewer will hammer this.

2. **The streamflow null is design-limited, not mechanistic, and the text occasionally forgets this.** The record ends 2020-03 — i.e., it *misses the deepest 2019/20–2024 megadrought years*, which is precisely the regime where storage depletion past s* (the H1 mechanism) and where any real buffering-then-collapse dynamic would be most detectable. A null on streamflow buffering that excludes the worst drought is weaker than the manuscript's "strongest possible evidence" language implies. The upstream placebo is robust to this (it is a relative comparison), but the *level* of the buffering test is not.

3. **Up/down-dam classification rests on a DEM-elevation proxy, not a routed river network.** The upstream placebo is the load-bearing causal device, so its validity hinges on this classification. Misclassification (a gauge above the dam in elevation but on a different tributary, or below-dam diversions/abstractions adding managed-flow noise) could either manufacture or mask the placebo result. The argument "the placebo only needs above-dam" is partly true but does not fully insulate it from network-topology error. This needs a routed-network or at least flow-accumulation validation.

4. **Matching is on observed covariates only.** Endogenous siting is the defining threat, and the authors acknowledge it, but the matched design balances aridity/Köppen/elevation/area — not hydrogeology, groundwater access, water-market participation, or land tenure, all of which plausibly co-determine both siting and drought response. The ET diagnostics already hint at this (control orchards buffer ET as well as dammed ones via groundwater/run-of-river/water markets). Unobserved confounding is not quantified (no E-value / Rosenbaum-style sensitivity on the headline contrasts, despite the identification doc promising it).

5. **The "siting, not regulation" claim is well-supported for the *direction* but not yet *quantified*.** The paper shows the apparent attenuation is a basin property; it does not yet estimate *how large* the siting confound is, which is the number that would make contribution (2) land. "Naive comparisons manufacture spurious buffering" needs a magnitude: how big is the spurious naive effect, and how much of it is siting?

---

## Major Concerns (blocking)

1. **No equivalence testing / power analysis. This is the #1 blocker.** Convert every headline null into a TOST/equivalence statement or report the MDE given the permutation null distribution. Without it, the paper cannot distinguish "reservoirs do not buffer drought" from "this design cannot detect reservoir buffering." Provide, per outcome, the smallest slope-gap the design could have rejected at 80% power, and state the null relative to a hydrologically meaningful effect size (e.g., the buffering implied by typical reservoir storage-to-mean-annual-flow ratios).

2. **The streamflow test excludes the deepest drought (2019/20–2024).** Acquire and incorporate post-2020 CR2 (or alternative gauge / satellite-altimetry / modelled-discharge) data. The H1 rectifier and any "buffer collapses past s*" dynamic are precisely a tail phenomenon concentrated in 2019–2022; a buffering test that stops in March 2020 cannot adjudicate it. If the data genuinely end in 2020-03, the null must be explicitly scoped to "through the onset of the deepest megadrought years" and cannot be presented as conclusive.

3. **No naturalized-inflow / mass-balance counterfactual; no operating rules.** For a *reservoir-effect* paper the most direct causal test is regulated outflow vs naturalized inflow (storage + release mass balance). Its absence means the streamflow null rests entirely on the spatial placebo. Nature Water will expect at least one operations-side line of evidence. If release/spill records are truly unavailable, the authors must either (a) reconstruct naturalized inflow from storage change + downstream gauge + estimated abstractions, or (b) explicitly reframe the paper's scope away from "reservoir regulation effect" toward "basin-scale siting confound," and not claim to have tested the regulation mechanism directly.

4. **Power vs the few-clusters problem is double-edged and unresolved.** The same ~20 treated clusters that make cluster-robust SEs over-reject also make permutation tests low-powered. The paper currently uses the cluster structure to *dismiss* positive signals (correct) but does not confront that it *also* undermines the null. Address head-on: simulation-based power for the permutation test under plausible true effect sizes.

5. **Novelty/framing is unsettled and currently lands below the bar.** The submission reads as "our hypotheses failed." It must be rebuilt around the affirmative, generalizable contribution (siting confound + within-design placebo as a transferable identification lesson). Establish, with citations, the *specific* prior claims this overturns — i.e., quantify the naive/confounded estimate the existing literature would report and show how the design dissolves it.

6. **Multiple-hypothesis / garden-of-forking-paths exposure.** Many estimands, timescales (SPEI-3/6/12/24), lags, masks, strata, and inference methods were explored. Most "discoveries" were *nulls*, which mitigates fishing concerns, but the few survivors (the within-treated "buffering-while-full" mean threshold; the orchard-ET aridity placebo significance) need pre-registration-style documentation of which tests were specified a priori vs post hoc. State the analysis decision tree explicitly.

---

## Minor Concerns

1. **Standardized-index proxies (SPEI, SSI, zNPP, zcNDVI) carry their own estimation uncertainty** that is propagated into the slope outcomes as if fixed. The 2026-06-26 "Next" list flags this (propagate slope-estimation uncertainty); it should be done before submission, not after.

2. **MOD16 ET under-estimates irrigated ET and compresses the range** (acknowledged). A PML_V2 or ECOSTRESS/OpenET-style cross-check on the ET-buffering null would materially strengthen it; otherwise the ET null is partly a sensor-saturation null.

3. **MapBiomas class 18 conflates annual + perennial cropland.** The orchard composition shift (Catastro) vs flat net area is a nice reconciliation, but the "snapshot survival bias" in the Catastro reconstruction is asserted, not quantified. Show it.

4. **Köppen × aridity-tercile strata for permutation** assume exchangeability of treatment within strata; with ~20 treated units spread across strata, some strata may have ≤1 treated unit, weakening the permutation. Report treated counts per stratum.

5. **"~10× more cropland in dammed basins"** is presented as siting evidence but is also exactly what an *induced-demand-that-already-completed-pre-record* world would look like. The cross-section cannot distinguish "dams built where cropland already was" from "cropland grew because of dams, before 2000." The left-censoring is acknowledged but this specific observational-equivalence should be stated where the 10× figure appears.

6. **n≈26 reservoirs / 21 treated** caps external validity; "Chile as natural laboratory" framing is reasonable but the generalization claim in contribution (2) must be argued, not assumed, given Chile's unusual hydrology (Andean snowmelt, extreme aridity gradient, mature water markets).

---

## Required Experiments / Analyses

1. **Equivalence tests (TOST) and minimum-detectable-effect curves** for every headline null (forcing-conditioned slope, ET buffering, area expansion, SSI slope-gap). Express the bound in hydrologically interpretable units. This is mandatory.

2. **Extend streamflow to 2024** (CR2 update, or DGA real-time, or modelled/altimetric discharge) and re-run the SSI buffering + upstream placebo through the deepest drought. If impossible, scope the claim explicitly.

3. **Naturalized-inflow mass-balance counterfactual** for the subset of reservoirs with storage time series + a downstream gauge: reconstruct inflow = ΔS + outflow(+ET+seepage) and test regulated-vs-naturalized SSI attenuation. Even a handful of reservoirs would convert the spatial placebo into an operations-side corroboration.

4. **Routed-network validation of up/down-dam classification** (flow-accumulation / HydroSHEDS routing), with a sensitivity analysis showing the placebo is robust to plausible reclassification.

5. **Quantify the siting confound:** report the naive (unmatched) dammed-vs-control buffering estimate, the calendar-time DiD estimate, and the forcing-conditioned permutation estimate side by side, and decompose how much of the naive signal is siting/aridity. This magnitude *is* the contribution.

6. **Unobserved-confounding sensitivity** (E-value / Rosenbaum bounds) on the surviving cross-sectional contrasts, as the identification doc itself promised.

7. **Simulation-based power for the permutation test** at a grid of true effect sizes, to bound the false-null risk.

8. **ET cross-product check** (PML_V2 / OpenET) on the buffering null.

9. **Pre-registration-style analysis-decision appendix** distinguishing a priori from post hoc tests.

---

## Questions for the Authors

1. What is the smallest reservoir buffering effect (in SSI slope-gap units, and in % drought-deficit attenuation) your design could have detected at 80% power under permutation inference? Until this is answered, why should the reader read your nulls as absence rather than insufficient power?

2. The streamflow record ends 2020-03. The H1 rectifier and any buffer-collapse dynamic are tail phenomena concentrated in 2019–2022. How can a streamflow null that excludes the deepest drought be described as the "strongest possible evidence"?

3. The upstream placebo carries the causal weight. How is "upstream" defined operationally, what fraction of gauges could be misclassified under a routed-network definition, and is the placebo robust to that?

4. Can you reconstruct naturalized inflow (ΔS + outflow) for any reservoirs? If not, can the paper honestly claim to have tested the *regulation* mechanism, as opposed to a basin-scale siting comparison?

5. Dammed basins hold ~10× more cropland. Given pre-2000 left-censoring of dam construction, how do you exclude the possibility that induced-demand expansion *already occurred before your record began* — i.e., that you are observing the post-treatment equilibrium of exactly the H2 mechanism you reject?

6. What specific, well-evidenced prior claim in the literature does this null overturn, and what magnitude of spurious buffering would a conventional dammed-vs-undammed or basin-mean-greenness analysis have reported on these same basins?

7. Matching is on observed covariates. What is the E-value for the surviving natural-cover contrast, and how sensitive is the "siting not regulation" conclusion to an unobserved groundwater-access / water-market confounder?

---

## Nature Water Merit Verdict and Path to Publishability

**Is a rigorous null of this kind publishable in Nature Water?** Yes, but only rarely, and only under stringent conditions. Nature Water will publish a null when it (a) overturns a specific, consequential, widely held belief, (b) is powered enough to be a true null rather than an absence of evidence, and (c) delivers a transferable methodological or policy lesson of broad interest. This submission currently satisfies none of the three cleanly: the prior it overturns is implied rather than documented and quantified; the nulls are not yet equivalence-tested; and the methodological lesson, while real, is presented as a byproduct rather than the headline.

**Merit verdict:** The *work* has genuine merit and the *design* is, in places, exemplary — the forcing-conditioned estimand and especially the upstream-of-dam placebo are the kind of identification craftsmanship Nature Water respects. But as a Nature Water *paper* it is **not there yet**. In its current "all our hypotheses failed" posture it would be rejected, most likely without review or at first review, as an incremental national null.

**The path to publishability — one viable route, in priority order:**

1. **Invert the narrative.** The paper is not "reservoirs failed to show induced demand." It is **"reservoir *siting*, not reservoir *regulation*, drives the apparent drought-buffering signal — a confound that pervades the dammed-vs-undammed literature."** Lead with the upstream placebo and the naive-vs-design decomposition. Make the transferable identification lesson the thesis.

2. **Power the null.** Add equivalence tests and MDE curves so the central statement becomes "we can exclude reservoir buffering larger than X," not "we find none." This single change is what separates a publishable rigorous null from an underpowered non-result.

3. **Add one affirmative mechanistic line of evidence.** A naturalized-inflow mass-balance counterfactual (even on a reservoir subset) and/or the 2020–2024 streamflow extension. The reviewer needs to see that the regulation mechanism was *directly* tested and *still* null, not merely undetected by a spatial proxy.

4. **Quantify and generalize the siting confound** with explicit citations to the studies it would mislead, and a defended argument for why the Chilean lesson transfers (or an honest scoping of where it does not).

**Bottom line:** As an induced-demand / buffering *positive* paper: dead, correctly. As a *rigorous-null + siting-confound + within-design-placebo* methodological contribution: viable for Nature Water **only with** equivalence testing, the post-2020 streamflow extension, and ideally a naturalized-inflow counterfactual. Without those, this is a strong, clean, honest paper for **Water Resources Research, HESS, or Nature Communications** — and there is no shame in that placement; it is the right home for the current evidence. Pursue Nature Water only after the three upgrades above convert "we found nothing" into "we proved the apparent something is an artifact of where dams are built, and we can bound how small any real effect must be."
