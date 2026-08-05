# Reviewer #1 — Nature Water

**Manuscript:** "The upstream placebo: reservoir siting, not regulation, explains apparent drought buffering during Chile's megadrought"

**Reviewer agent:** nature-water-reviewer
**Date:** 2026-08-05
**Manuscript status reviewed:** Post-reframing version prepared for WRR resubmission (after one Nature Water desk rejection)

---

## Recommendation

**Reject for Nature Water as submitted.** The work is a rigorous, well-executed methodological contribution and a strong candidate for *Water Resources Research* or *Hydrology and Earth System Sciences*. It is not yet a Nature Water paper: the central inference rests on a placebo contrast that is never directly tested, the powered pathway is truncated before the deepest drought years, and the siting conclusion is demonstrated in a single country under a single drought realization. With a second-region replication executed under a pre-specified analysis plan (details in the final section), this design would be competitive at Nature Water; I detail the exact demonstration the replication must make.

---

## Summary of Claims

The manuscript claims that the apparent drought buffering attributed to reservoirs in the hydrological literature is, in Chile's 2010–2024 megadrought, a measurable siting confound rather than a regulation effect. Four pillars are offered: (1) a within-basin upstream/downstream placebo showing the SPEI-12→SSI-12 transmission slope is as attenuated at unregulated reaches above dams (−0.20) as at regulated reaches below (−0.16); (2) a hard-balanced match (aridity SMD 0.000, ESS 19) in which even the apparent buffering collapses (ITT −0.02, permutation p > 0.85); (3) a positive control recovering injected buffering effects one-to-one and detecting them beyond a 46–59% minimum detectable effect; and (4) a convergent set of nulls across streamflow, cropland, water rights, and evapotranspiration, with honest acknowledgement that only the streamflow null is powered (MDEs 7,330% and 237% of baseline for cropland and ET). Demand-side outcomes are framed as a stable siting legacy (4.5× more cropland in dammed basins, no megadrought-era divergence) rather than reservoir-induced expansion. The paper's constructive claims are the portability of the upstream placebo and the policy implication that, under structural aridification, further storage is a "supply-blind response."

---

## Novelty Assessment

**Partial and honestly stated, but insufficient for Nature Water on its own.**

What is genuinely new is the *application* of a within-basin upstream/downstream gauge contrast as a falsification device to decompose reservoir *siting* from reservoir *operation* for the specific question of multi-year drought buffering, packaged with a decomposition ladder, hard-balance collapse, and positive control. This application of the placebo to transmission slopes, and the demonstration that the apparent buffering is an aridity gradient rather than a regulation signal, is not, to my knowledge, previously published.

But the *mechanics* are not novel, and the manuscript should not imply they are. Paired upstream/downstream gauges to isolate dam effects on streamflow are an established technique at national scale: Chalise et al. (2021, *Earth's Future*) paired USGS records above and below 209 dams across the CONUS to show dams dampen or amplify climate-driven flow alteration, and Chalise et al. (2023) extended this to 175 pairs; the upstream-reference design is also standard in the ecological dam literature. The introduction's framing ("whether reservoirs buffer multi-year drought... has remained untested for want of a credible counterfactual") is simply inaccurate: the naturalized/simulated-flow counterfactual literature exists and is extensive (Wu et al. 2019, 2021, *Journal of Hydrology*; Wan et al. 2017, *JGR-A*), and those studies find reservoir regulation does attenuate hydrological drought downstream. The paper's actual contribution relative to that literature is a *challenge to its transferability*, arguing that modeled-counterfactual findings may not account for where dams sit, and offering an alternative counterfactual (the unregulated upstream reach) that avoids model dependence. That is a legitimate and publishable position, but it must be argued against the naturalized-flow literature explicitly, not by asserting the field had no counterfactuals.

The siting-confound *concept* for dammed-versus-undammed comparisons is also well precedented, both in the reservoir-effect theory (di Baldassarre et al. 2018) and in the broader dam-siting literature. What is new is the empirical *demonstration* that the confound quantitatively explains the apparent buffering. That is a real, useful contribution, but it is a negative-result and cautionary finding, not a positive advance of the kind Nature Water typically prioritizes.

**Is it a positive contribution or still a null?** It is a hybrid. The null is real and bounded (good), but it is still a null; the "positive" content is about the *method* (the placebo works, the positive control recovers 1:1) and about the *confound* (hard-balance collapses the effect). For WRR this is a solid contribution. For Nature Water, the decisive test is external validity: one country, one drought, one governance regime, one mountain-front hydrology. A single-region demonstration that a known confound explains a known finding is incremental; a demonstration that the placebo ports and the siting conclusion replicates across independent regions is a Nature Water advance.

---

## Causal Evidence Assessment

The design is substantially stronger than the typical dammed-versus-undammed comparison, and the causal discipline shown (permutation inference as primary, forcing-conditioned estimands, falsifiers, honest power accounting) is commendable. But three causal gaps are blocking, and one is decisive.

**Blocking: the placebo's own contrast is never directly tested.** The headline claim is "apparent buffering is as strong upstream as downstream (−0.20 versus −0.16)." The placebo inference requires a test of the *difference* between the upstream and downstream differential slopes, with a permutation null appropriate to the paired (same-basin) structure. No such test is reported anywhere in the manuscript or tables. The p = 0.39 quoted in the abstract is the *intent-to-treat* permutation p (the pooled treated-vs-control gap, rung 3 of the siting ladder, 0.388), not a test of the up-vs-down contrast. The upstream placebo's own permutation p is 0.483 (siting ladder rung 5). The abstract therefore attaches a p-value from one estimand to a claim about a different estimand. As written, "as strong upstream as downstream" rests on point estimates whose difference (0.04) is small relative to the null SD (~0.10), which is fine, but that has not been *shown*; it is asserted. This is the single most important missing analysis in the paper. (Note the raw gauge-level comparison in Table S22, 0.565 upstream vs 0.599 downstream, is a different, non-differential quantity and does not substitute.)

**The elevation correction is the load-bearing assumption and is handled better than most, but still extrapolative.** The logic (0.54 km elevation gap × −0.21/km control sensitivity = −0.115 predicted, over-explaining the observed −0.04, leaving ≤0.07 residual downstream-specific buffering, 13% of baseline) is coherent, and the snowline piecewise test (p = 0.25) and the snow-placebo checks are the right supporting analyses. But the extrapolation assumes the control-gauge elevation sensitivity applies at the treated upstream reaches, and the geomorph check shows relief-adjusting *changes* the downstream estimate substantially (−0.16 → −0.20), which the text glosses as "leaves the placebo unchanged." It does leave the placebo unchanged, but the downstream movement deserves explicit comment. Also, upstream/downstream classification is by SRTM elevation, not by routed network topology; misclassification (a "downstream" gauge on an unregulated tributary, or a reach below another dam) would bias the placebo toward the null. This must be validated.

**The hard-balanced match cannot distinguish confound-removal from power collapse, and the abstract overstates it.** At ESS 19, the MDE is far above the primary design's 46–59%. The vanishing of −0.18 to −0.02 is exactly what both (a) an aridity confound removed and (b) a near-powerless design would produce. The methods paragraph acknowledges this honestly ("evidential value is agreement with the powered primary, not independent power"), but the abstract headline ("makes even the apparent buffering vanish entirely") does not carry the caveat. The vanishing is corroborative, not decisive; the decisive evidence must be the placebo contrast and the decomposition ladder.

**Positive control.** Sound and appropriately limited: it verifies the estimator recovers an injected signal on the standardized scale (recovery is exactly base + injected), confirming the machinery and the MDE-based detection threshold. It does not validate recovery of a physically distinct mechanism (e.g., variance compression or reservoir evaporation), and the manuscript should not imply more.

**Borderline water-rights volume.** The unit-level overlap-subset p = 0.005 that becomes p = 0.077 under cuenca-block permutation and p = 0.145 for ranked raw volumes is honestly reported, but the methods text ("the volume null is insensitive to the winsorization threshold, permutation p from 0.39 to 0.21") and the results emphasis on 0.005 are in unresolved tension. These are different samples (full match vs overlap subset); that must be stated in one place.

---

## Major Concerns

**MC1 (Severity: blocking). No direct test that the upstream and downstream placebo slopes differ (or do not).** The abstract's "as strong upstream as downstream (−0.20 vs −0.16), randomization-inference p = 0.39" misattributes the ITT permutation p to the placebo contrast. Report the distribution of the within-basin upstream-minus-downstream differential slope under treatment permutation, its p-value, and its paired structure (same 15 basins). This is the analysis the paper's identification rests on, and its absence is the difference between "the placebo shows X" and "the placebo is asserted to show X."

**MC2 (Severity: blocking). The powered streamflow pathway ends in 2020, missing the deepest drought years.** Methods state streamflow runs 2000–2020, so the "late (2015–2024)" megadrought phase for the streamflow null is really 2015–2020. Central Chile's most acute deficits (2019–2022) are absent from the one pathway that carries the causal weight. The truncation is disclosed only by a parenthetical data-range in Methods, never flagged in Results or Discussion. Either extend the CR2 series through 2024 (the placebo comparison makes this tractable, since it needs the same gauges to continue) or state explicitly and prominently that the powered null does not cover the peak of the drought, and that the storage/cropland pathways (which do run to 2024) are the only multi-year-drought evidence for the late phase.

**MC3 (Severity: major). Supplementary Table S24 is internally inconsistent, and the late-phase downstream estimate contradicts the narrative.** The "early-to-late phase shift" interaction estimates (+0.288 ITT, +0.293 downstream, +0.364 upstream) do not reconcile with the early/late subsample estimates in the same table (downstream: −0.430 early + 0.293 shift = −0.137, not the stated −0.444 late). The two sets of numbers come from different specifications and must be reconciled or labeled. More substantively, the downstream late-phase point estimate is −0.444, essentially unchanged from the early-phase −0.430, while only the upstream placebo weakened (−0.430 → −0.215). The sentence "the later weakening is sharpest in the unregulated placebo itself, forcing, not depletion" is true only for upstream; it elides that the *regulated* downstream gap did not weaken at all through the deepest drought. A skeptical reader will read the late-phase downstream −0.44 as residual downstream-specific buffering. The phase analysis also uses analytic cluster-robust p-values despite the design's own documented rule that these over-reject at ~21 clusters; no permutation inference is provided for the phase split. Address the late downstream point estimate directly (is it a fixed siting property or noise, SE 0.36, p = 0.224?), and add permutation inference for the phase shifts.

**MC4 (Severity: major). The introduction misstates the prior art on credible counterfactuals.** "Whether reservoirs buffer multi-year drought... has remained untested for want of a credible counterfactual" is contradicted by the naturalized/simulated-flow literature (Wu et al. 2019, 2021; Wan et al. 2017), which tests reservoir effects on hydrological drought against reconstructed or modeled unregulated flow and finds downstream attenuation. The correct and stronger argument is: those counterfactuals are model-based and can themselves embed siting assumptions; the upstream placebo provides a direct, model-free discriminator, and where it is available it *contradicts* the buffering those studies find. Rewrite the framing accordingly and cite that literature; as written, the paper invites rejection from any reviewer who knows it.

**MC5 (Severity: major). Policy conclusions outrun the bounded null.** Equivalence at ±25% was *not* established (every row of the equivalence table returns equivalent = FALSE); the paper establishes only that buffering above the MDE (46–59% of baseline) is excluded, at the multi-year timescale, in this setting. Yet the Discussion states "we detect no operational buffering" and "building more storage is a supply-blind response to a supply problem" without the qualifier. The policy claim must carry the bound ("no operational buffering above ~46–59% of baseline"), especially given the MC3 finding that the late-phase downstream point estimate is −0.44. The phrase "Adaptation must shift toward managing demand" (abstract) is defensible as a conditional recommendation but currently reads as established fact.

**MC6 (Severity: major). The storage–streamflow "in step" claim is overstated and internally inconsistent.** Results report peak storage declining 1.3 pp yr⁻¹ (p = 0.013); Discussion later restates this as "the ~1.4% per year decline in peak storage"; the abstract claims the storage band drifts down "in step with the independent decline in unregulated streamflow," which fell ~2.9%/yr (controls) and 3.4%/yr (dammed). A factor-of-two difference is not "in step" or "comparable." Reconcile the 1.3-pp vs ~1.4% restatement and calibrate the claim (direction is consistent; rate is about half).

**MC7 (Severity: major). Generalizability cannot be argued from within-country evidence.** The Discussion portability paragraph is appropriately hedged, but the paper's Nature Water-level claim rests on the transfer of the method, not its demonstration. Single country, single megadrought realization, time-invariant treatment, one governance regime (1981 Water Code), one hydrology (short, steep, snow-fed mountain fronts), a fully allocated water market that may itself explain the absence of induced demand. The paper concedes it cannot adjudicate whether the null is general "or the mark of a fully allocated market" — that concession belongs in the abstract's reach, not just the Discussion. (See the replication verdict below.)

---

## Minor Concerns

**MN1.** The winsorized-volume p-values cited in Methods (0.39–0.21 across thresholds, full sample) and in Results (0.005 on the overlap subset) need a single joint statement identifying which sample each test uses; the current separate presentations read as contradictory.

**MN2.** Siting-ladder rung 4 (−0.05, the "regulation estimate" after within-region baselines) is reported without a permutation p; the reader cannot tell whether −0.05 (about 9% of baseline) is within its own null. Its SE (0.070) suggests it is, but report it.

**MN3.** The gauge up/down classification by SRTM elevation should be validated (e.g., against the DGA gauge-network topology and reservoir locations) and its error rate reported. The entire placebo rests on this classification.

**MN4.** The rung-2 (unit+time FE, unweighted) streamflow estimate (−0.1646) coincides to three decimals with the "downstream" equivalence estimate; verify these are genuinely different estimators and label them.

**MN5.** The abstract's "SMD 0.000... makes even the apparent buffering vanish entirely" should carry the ESS-19 power caveat that the methods paragraph correctly includes.

**MN6.** The Results claim that relief adjustment "leaves the placebo unchanged" should note that the downstream estimate moved from −0.16 to −0.20 under that adjustment (Table S22), which is actually favorable to the siting story but deserves one sentence.

**MN7.** The low-relief (alluvial) subsample used to show "no buffering among alluvial units" contains only 3 treated units (upstream) and 7 (downstream); label these as illustrative, not evidentiary.

**MN8.** Minor: "7,330% and 237% of baseline" MDEs (cropland DiD, orchard ET) — the text calls these "orders of magnitude above baseline"; 237% is under an order of magnitude for the ET row. Adjust the adjective.

---

## Required Experiments / Analyses

1. **Direct up-vs-down placebo contrast with its own permutation null** (MC1). Distribution of the within-basin (downstream − upstream) differential slope under treatment permutation within strata, with the paired structure exploited; p-value plus the point estimate of the residual downstream-specific buffering.
2. **Extend streamflow through 2024** or, if impossible, prominently disclose the 2020 truncation and re-state the late-phase conclusion over the correct window (MC2).
3. **Reconcile or relabel the S24 phase-shift interaction vs subsample estimates, add permutation inference to the phase split, and address the late downstream −0.44 directly** (MC3).
4. **Validate the up/down gauge classification** against network topology (MC7/MN3).
5. **Rewrite the introduction's counterfactual claim** against the naturalized-flow literature and position the placebo as a model-free alternative (MC4).
6. **Carry the bounded-null qualifier through every policy sentence** (MC5).
7. **Replicate in a second region** (see verdict below).

---

## Questions for the Authors

1. What is the p-value of the within-basin test that the upstream and downstream differential transmission slopes are equal, under the design's permutation inference? Why is it not in the paper, given it is the paper's central falsifier?
2. The late-phase downstream point estimate is −0.444, unchanged from the early phase, while upstream relaxed to −0.215. If the attenuation is a fixed siting property, why does the regulated reach show undiminished attenuation through the deepest drought while the placebo weakens? Is this noise (SE 0.36) or a real late-phase downstream signal, and how is the claim "forcing, not depletion" robust to it?
3. Which permutation p is "p = 0.39" in the abstract, and which estimand does it test? Can the abstract be rewritten so each quoted p tests the sentence it supports?
4. How are the −0.20 (upstream) and −0.16 (downstream) differential slopes baselined? Are both against the same control pool, or do the upstream and downstream gauge subsets use different matched controls?
5. If the naturalized-flow literature finds downstream buffering (Wu 2019, 2021; Wan 2017), what does the manuscript say about the regimes in which those findings hold and where the placebo would or would not contradict them? Is Chile's fully allocated market the boundary condition?

---

## Verdict on the Reframing

**Does the reframing fix the "null-result trap"? Partially, and the remaining risk is specific.** Leading with the placebo, the hard-balance collapse, and the 1:1 positive control converts a bare null into a methodological cautionary contribution with positive demonstrations, which materially reduces the desk-rejection risk that killed the previous version. What remains is narrower but sharper: (a) the substantive headline is still a bounded null, so Nature Water editors will weight the significance of the siting demonstration against its single-country reach; (b) the abstract's key quantitative claim (the placebo p) is mis-specified, which an editor or reviewer will catch immediately; (c) the intro overstates the field's counterfactual gap, inviting a literature-based rejection; and (d) the demand-side breadth claim ("across four pathways") still reads broader than the powered evidence.

**Verdict with a second-region replication.** Yes — conditionally — this paper would be competitive at Nature Water if the replication demonstrates, with its own data and pre-specified analysis plan, at least the following:

1. **The placebo pattern replicates**: upstream (unregulated) differential transmission attenuation at least as strong as downstream, ideally with a direct up-vs-down contrast test that is permutation-null, in a hydrologically and institutionally different region (California's Sierra/Central Valley, the Iberian reservoirs under the *Plan Hidrológico*, or SE Australia's Murray–Darling tributaries). A second-region *null* alone is insufficient; the replication must show the placebo is null *where the primary was null* and, ideally, that a region with known buffering claims (e.g., naturalized-flow studies) reproduces the siting pattern.
2. **The confound demonstration replicates**: apparent buffering collapses under a hard-balanced aridity match, and the decomposition ladder localizes the signal to the between-region aridity gradient.
3. **Streamflow coverage through the recent drought** in both regions (no 2020 truncation).
4. **A positive control in the second region**, so the null is powered there too, and the MDE reported.
5. **Governance contrast**: prefer a region with water still unallocated or with prior-appropriation forfeiture, so the demand-side boundary ("the mark of a fully allocated market") is tested rather than assumed. If the replication instead uses another fully allocated system, the paper must say plainly that the induced-demand null has not been tested outside that regime.
6. **Pre-registration or an explicit analysis plan committed before the replication data are examined**, to avoid the obvious HARKing risk in a confirmatory follow-up to a null.

If the replication delivers (1)–(3) with honest power accounting, the paper becomes "the upstream placebo: siting not regulation, across two continents," which is a Nature Water advance (a portable identification method, a literature-correcting finding, and a policy consequence). Without it, the manuscript is a strong WRR/HESS contribution and should be submitted there.

---

**Bottom line.** As submitted: Reject for Nature Water. The verification I performed against the results tables confirms most quoted numbers are accurate (the −0.20/−0.16 slopes, the hard-balance −0.023/−0.047 with p > 0.85, the 46–59% MDE, the exact 1:1 positive-control recovery, the 4.5× cropland gap, the storage trends, the carryover availability), and the causal discipline is well above the field's norm. But the paper's decisive falsifier is never directly tested, the powered outcome misses the deepest drought years, the phase analysis contains an internal inconsistency and a late-phase anomaly that favors the skeptic, and the single-country reach cannot carry a Nature Water significance claim. With the direct placebo test, the streamflow extension, and a second-region replication, this becomes a genuinely competitive Nature Water submission; as it stands it is a very good Water Resources Research paper that is being asked to carry more weight than its evidence, in its current single-region form, can bear.

---

## Prior-Art References Consulted

- Chalise et al., 2021, *Earth's Future*: [Dams and Climate Interact to Alter River Flow Regimes Across the United States](https://consensus.app/papers/details/bc6d0ff307b9515f998ba861b18165bf/?utm_source=claude_code) — paired USGS gauges above/below 209 dams
- Chalise et al., 2023, *Earth's Future*: [Spectral Signatures of Flow Regime Alteration by Dams Across the United States](https://consensus.app/papers/details/7636a032ca9c519a872e2f5c2b3ef1ac/?utm_source=claude_code)
- Wu et al., 2019, *J. Hydrology*: [Assessing the impact of human regulations on hydrological drought development and recovery](https://consensus.app/papers/details/fcf4dd113e8e59fbae7bab695b730cf9/?utm_source=claude_code)
- Wu et al., 2021, *J. Hydrology*: [Reservoirs regulate the relationship between hydrological drought recovery water and drought characteristics](https://consensus.app/papers/details/ff52fa764cd557d8be38c833c0097767/?utm_source=claude_code)
- Wan et al., 2017, *JGR-A*: [Hydrological Drought in the Anthropocene](https://consensus.app/papers/details/57b00d3fd7fc5b15baad6c7e82b22c71/?utm_source=claude_code)
- di Baldassarre et al., 2018, *Nature Sustainability*: [Water shortages worsened by reservoir effects](https://consensus.app/papers/details/5709c25cb5055ffcbe06c513c973e8b3/?utm_source=claude_code)
- Kellner, 2021, *WIREs Water*: [The controversial debate on the role of water reservoirs in reducing water scarcity](https://consensus.app/papers/details/8aaed6eecca25f2490baec87284b4796/?utm_source=claude_code)
- Wang et al., 2021, *Water*: [Dam Siting: A Review](https://consensus.app/papers/details/8866d49de8e35c0db1c70e6a5040678a/?utm_source=claude_code)
