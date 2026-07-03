# Response to Reviewer 3 (2026-07-02 round, 12 comments)

Twelve comments. Comments 1, 2, 5, 6, and 7 are answered with new analyses wired into the `targets`
pipeline (Supplementary Tables S12 reworked, S13, S14, S15 new); comments 3, 4, 8, and 9 with
quantified robustness already in place plus expanded limitation text; comments 10, 11, and 12 are
consistency corrections now fixed in the text. An earlier version of this file responded to the
seven-comment 2026-07-01 set; this version supersedes it and tracks the twelve-comment 2026-07-02
review.

---

**1. Snowpack buffering confounds the upstream placebo.**
Reworked and answered on the estimand the placebo actually reports, the treated-versus-control
transmission differential (treat x SPEI on the up- and downstream unit-month panels), not on raw
gauge-level slopes (Supplementary Table S12; `src/R/drought/snow_placebo.R`). Four results bound the
concern. (i) Adding a forcing-by-snowpack adjustment (SPEI x standardized unit peak SWE) leaves the
up/down equivalence intact: the upstream placebo moves from -0.201 to -0.166 and the downstream
coefficient from -0.165 to -0.141, so the differential stays small (-0.03 adjusted vs -0.04
unadjusted), while the snowpack term itself is detectable upstream (p = 0.013), so the null is not
the artifact of a product blind to snow. (ii) Among low-snow units (below-median peak SWE, at most
0.001 m w.e.) the upstream and downstream coefficients are nearly identical (-0.083 vs -0.081), so
the equivalence persists where snowmelt is essentially absent. (iii) The apparent buffering does not
strengthen in high-snow years (treat x SPEI x annual SWE anomaly, p = 0.51 upstream, p = 0.21
downstream), as it would were snowmelt storage producing it. (iv) Gauge-level rows on standardized
SWE cap any snow-induced up-minus-down slope difference at 0.007 against the observed -0.04. On the
suggested alternatives: all snow terms enter standardized, which is robust to ERA5-Land's
multiplicative underestimation of absolute Andean SWE (the same caveat class we apply to MOD16, now
stated symmetrically in the Discussion), and the low-snow restriction implements the
non-snow-dominated subset the reviewer proposed.

**2. Administrative closure confounds demand outcomes; ceiling effects and the collapse counterfactual.**
Now tested differentially, as asked (Supplementary Table S15; `src/R/causal/spillover_demand_checks.R`).
A direct allocations-over-renewable-supply utilization rate is not computable from the registry (no
per-basin renewable volume), so we report the conservative version: dammed basins entered the
megadrought with a higher allocated stock per unit area than their weighted controls (15.5 vs 6.2
rights per 100 km²; 1.8 vs 0.7 l/s per km² winsorized volume), which over their lower renewable
supply implies a utilization rate at least as high. Yet they continued to accrue new rights about
2.7 times faster than controls (1.7 vs 0.6 rights per 100 km² per year), and every treated basin
granted new rights during the megadrought while 29% of weighted controls granted none. A closure or
ceiling artifact would have produced the opposite pattern (treated accrual suppressed toward zero),
so the demand null is a genuine null difference, not the forced silence of saturated registries. On
the collapse counterfactual: collapse prevention would appear as a positive treated-minus-control
divergence in cropland through the megadrought; the matched-control trajectory does not collapse but
evolves in parallel with the treated series, and the event study shows no post-2010 divergence in
either direction (p = 0.81). Both points are now in the Discussion.

**3. Aridity regime gap; present the hard-balanced subset as primary sensitivity.**
We present the equivalent non-extrapolating analysis and the confidence hierarchy explicitly. The
fully non-parametric re-match restricted to the aridity-overlap subset (all 21 treated basins, 158
of 244 controls) re-fits entropy balancing within the overlap and estimates every cross-sectional
outcome with the weighting-only estimator, which carries no outcome-model aridity term and performs
no extrapolation across the regime gap; cropland expansion, orchard-ET buffering, and the
water-rights count remain null (Supplementary Table S7). We prefer this to the hard-balanced ESS=19
subset because it removes extrapolation while retaining support, whereas hard-balancing collapses
the effective sample below what the permutation inference needs; the Methods state this trade-off.
Decisively, the within-basin placebo, the within-region comparison, and the randomization inference
use no outcome-model aridity adjustment at all, and the Discussion now states the resulting
hierarchy of confidence, with the demand-side ATTs held as corroborating rather than independently
decisive (see also comment 5 on their power).

**4. MOD16 unsuitable for irrigated arid orchards.**
Acknowledged and weighted accordingly; a thermal-based replacement is future work. The Discussion
states the caveat and its direction: MOD16's underestimation over irrigated land most plausibly
compresses the deficit-to-impact slope and biases the orchard-ET gap toward zero, so a positive
induced-demand signal masked by MOD16 cannot be ruled out and would need a water-balance or thermal
product (SSEBop/METRIC/ECOSTRESS class) to resolve. Consistent with that, the orchard stratum is
treated as a post-hoc mechanistic diagnostic on which no claim rests, the ET outcome is excluded
from the decisive evidence, and the demand-side conclusion leans on the registry and cropland
outcomes, which do not depend on the ET product. The revised power statement (comment 5) makes the
limited standalone weight of the ET null explicit.

**5. Absence of evidence in pre-trend tests; report the pre-trend MDE.**
Done (Supplementary Table S14; `build_pretrend_mde` in `src/R/causal/equivalence.R`). Held to the
same permutation-based standard as the headline nulls: the minimum detectable pre-2010 differential
trend (80% power, two-sided alpha 0.05, permutation-null SD) is 0.0014 basin-fraction per year,
which cumulated over the 2000-2009 pre-window is about half (51%) of the weighted control cropland
level; the observed differential trend (-0.0002 per year, permutation p = 0.72) is about a seventh
of the minimum detectable slope. The Results now state this alongside the p-value. We note the same
standard applied to the demand-side outcomes themselves is now reported prominently (MDE about 237%
of baseline for orchard ET, far above baseline for the cropland slope gap; Supplementary Table S2),
and the convergence language has been tempered accordingly throughout.

**6. Post-treatment bias in the 1991-2020 aridity baseline.**
Tested both ways the reviewer offered (Supplementary Table S13; `aridity_window_sensitivity` in
`src/R/preprocessing/aridity_data.R`). Recomputing unit aridity on the strictly pre-drought
1991-2009 window leaves the design unchanged: pre-drought and full-window aridity are essentially
identical across the 265 matched units (Pearson r = 0.998, Spearman rho = 0.999) and 99% of units
keep the aridity tercile used as a permutation stratum, so re-matching on the pre-drought window
would reproduce the same design. And the megadrought change in P/PET does not differ significantly
between treated and weighted control basins (-0.044, SE 0.027, p = 0.10), an order of magnitude
smaller than the ~0.5 treated-control aridity gap the matching addresses, so P/PET carries no
material reservoir imprint over the drought decade. Methods now state both results.

**7. Non-stationary snowmelt in the upstream placebo.**
Tested dynamically, not just contextualized (Supplementary Table S12, rows 4-5 and 9-10). If a
degrading upstream snow buffer were steepening in parallel with a degrading downstream dam buffer,
the up-minus-down differential would drift across the record and the placebo would depend on snow
years; neither happens. The differential is statistically indistinguishable between the early
(<=2010) and late (>2010) halves of the panel, now formally tested with a treat x SPEI x period
interaction (p = 0.46 upstream, p = 0.52 downstream; Supplementary Table S12), and the placebo does
not strengthen in high-snow years (treat x SPEI x annual SWE anomaly p = 0.51 upstream, p = 0.21
downstream). The Discussion cites the Andean snow-decline literature the reviewer points to when
introducing the confound.

**8. Representativeness of the groundwater well network.**
Acknowledged as a scope limitation, as asked. The Discussion now states that the DGA network is not
designed around agriculture: monitored wells need not sit inside the high-value orchard footprints
where compensatory pumping concentrates, nor sample the same aquifer strata, so a basin-median can
miss localized drawdown; the bound accordingly constrains basin-scale substitution, with field-scale
pumping outside the monitored network a residual caveat. The well count is also now reported
consistently (216 usable hydrographs nationally, 213 inside the matched basins; comment cluster
10-12).

**9. Oversimplification of inter-basin transfers.**
The bidirectional case is now treated explicitly. Exports (dammed to control) shrink the estimated
gap and bias toward the null we report. Imports sustaining a treated basin during peak drought would
flatten the treated transmission slope where deliveries land, downstream, and so mimic
regulation-specific buffering; the absence of any downstream-specific flattening therefore bounds
this direction too, since imports are evidently not manufacturing an apparent reservoir effect,
though a vulnerability signal partially offset by imports cannot be fully excluded without an
explicit transfer-network model, which remains flagged for future work. The geographic base rate is
quantified in Supplementary Table S15: no matched pair shares a cuenca (14 treated vs 70 control
cuencas, zero shared), so coupling requires a documented inter-cuenca transfer specifically joining
a treated cuenca to one of its matched controls, and we know of none.

**10. Cropland-area estimand contradiction (slope machinery vs level change).**
Fixed. Methods Section 2.5 now states explicitly that the two cross-sectional ATTs share the
doubly-robust matched machinery but differ in outcome transform, and only ET buffering is a
transmission slope: cropland-area expansion is a level-change outcome (ha km^-2 added, as Table 1
states), whose protection against differential megadrought exposure comes from the
forcing-interacted DiD, not from the slope transform.

**11. Unexplained 398 vs 244 controls.**
Fixed. Methods now define the in-window restriction where the 244 first appear: the 244 are the
subset of the 398 clean controls surviving the common-support trim shared by every matching
estimator (a control must lie in a Köppen main group containing a treated unit and within 250 m of
that group's treated elevation range; groups with fewer than ten such controls are dropped), so 154
clean controls fall outside support and never enter the matching pool.

**12. Inconsistent baseline transmission slope (0.585 vs 0.53).**
Fixed. Both values are correct but belong to different panels, which the text now says at both
sites: 0.585 is the untreated baseline of the intent-to-treat panel (used for the equivalence
margin, Methods) and 0.531 the downstream-gauge panel baseline (used for the elevation-bound
arithmetic, Results); both appear in Supplementary Table S2.
