# Response to Reviewer 3 (2026-07-01)

We thank the reviewer for a careful, statistically sophisticated read. The comments led to two new
robustness batteries that we now consider load-bearing for the water-rights conclusion, and to a
correction of one arithmetic sign error. All new analyses are wired into the `targets` pipeline
(`src/R/causal/reviewer3_robustness.R`) and regenerate Supplementary Tables S7-S9. Point-by-point
responses follow; manuscript changes are quoted where relevant.

---

**1. Uncontrolled groundwater substitution (well hydrograph test).**
We now test this confound directly with the DGA well hydrograph network (Supplementary Table S10),
rather than only flagging it. Wells are assigned to subcuencas by point-in-polygon; for each we take
the megadrought (2010-2021) trend in depth to water (m/yr, positive = falling table) and aggregate to
the basin by the outlier-robust median. Across the 26 matched basins with wells (13 dammed, 13
control, 213 wells), dammed and control water tables fall at similar rates (0.10 vs 0.08 m/yr) and the
differential is indistinguishable from zero (aridity-adjusted ATT +0.03 m/yr, 95% CI [-0.24, 0.29];
p_perm = 0.68). The depletion residuals show no spatial autocorrelation (Moran's I = -0.07), so the
stratified permutation is valid here. Dammed basins therefore show none of the faster drawdown a
substitution confound requires, bounding it empirically; the consumptive groundwater water-rights
series shows no differential accrual either. We note the partial coverage and that levels only proxy
pumping. (This addresses comment 1 of both the 2026-07-01 and 2026-07-02 review rounds.) We
now carry unmeasured groundwater explicitly as a subsidy that could support the demand-side nulls.

**2. Baseline aridity confounding; request for a fully non-parametric spec on the overlap subset.**
Done, for all cross-sectional outcomes (Supplementary Table S7). We re-fit entropy balancing *within*
the treated/control aridity-overlap band and use the weighting-only estimator (no outcome-model
aridity term), so no parametric extrapolation crosses the regime gap. Cropland-area expansion
(-0.59, p_perm = 0.33), orchard-ET buffering (-0.018, p_perm = 0.29) and the water-rights count
(+12, p_perm = 0.42) remain null. The reviewer's instinct was partly right: the *winsorized volume*
does turn significant here under the naive stratified permutation (p_perm = 0.005). We traced this to
spatial dependence, not a reservoir effect (see comment 5): under a spatially-restricted permutation
it is no longer significant (p = 0.077) and its cuenca-clustered interval spans zero. We report this
transparently in the Results water-rights paragraph and Supplementary Tables S7 and S9.

**3. Overbroad resilience claims; scope to multi-year.**
Agreed and scoped throughout. The Abstract now reads "rather than create resilience against multi-year
drought, even if they still perform the intra-annual seasonal buffering they are primarily built for,"
and the closing Discussion states the verdict "concerns the multi-year horizon our design resolves and
does not contest the intra-annual, seasonal buffering ... which our 12-month accumulation is not
designed to detect." The Methods already flagged the 12-month window as not resolving 1-3 month
operation; the causal/policy language is now consistently bounded to the multi-year timescale.

**4. Justification of the equivalence margin (slope vs absolute SSI).**
The reviewer is correct that the estimand is a slope, so the absolute SSI perturbation scales with the
deficit. We now give the explicit worst-case calculation in Methods: the largest SPEI-12 deficit in
the panel is approximately -2.0 (minimum -1.98); 25% of the baseline transmission slope is
0.25 x 0.585 = 0.146 SSI per unit SPEI; the maximum absolute perturbation is therefore
0.146 x 1.98 = 0.29 SSI units, below the ~0.5-unit width of one severity category. A 25% slope change
cannot move a basin across an operational threshold even under the worst observed deficit.

**5. Spatial structure in the permutation test.**
Assessed and addressed (Supplementary Table S9). Moran's I on ATT-model residuals (great-circle,
5-NN weights) shows significant positive spatial autocorrelation for the water-rights outcomes
(I = 0.60 count, 0.39 volume; p = 0.001) and cropland area (0.18); orchard ET is not significant.
Because the unit-level stratified permutation does not preserve this structure, we re-run the affected
outcomes with a spatially-restricted permutation that swaps treatment at the cuenca-block level and
with cuenca-clustered CIs. This is decisive for the overlap water-rights volume: the naive stratified
p (0.005) rises to 0.077 and the cuenca-clustered interval spans zero. Methods now specify spatially-valid
inference governs where naive and spatial tests disagree.

**6. Exploratory (post-hoc) masking of ET data.**
Acknowledged as post-hoc. The orchard-ET stratum was defined after the whole-basin ET pre-trend
failed; it was not pre-specified. Results now state this explicitly and read the orchard result "as
diagnostic of a mechanism rather than as an independent test," resting no claim on it. The Discussion
adds the general caveat that data-driven outcome redefinition can inflate the chance of a convenient
result.

**7. Sensitivity to the winsorization threshold.**
Done (Supplementary Table S8). The winsorized-volume ATT is positive with an analytic interval
excluding zero at the 95th, 99th, 99.5th and 99.9th percentiles, but is not significant under
randomization inference at any threshold (permutation p from 0.39 to 0.21). The full-sample volume
null is not an artefact of the winsorization choice.

**8. Snowmelt and geomorphological confounders in the within-basin placebo.**
Discussed. We now note that upstream reaches are steep, snow-dominated Andean headwaters whereas
downstream reaches sit in flatter alluvial valleys, so snowmelt storage/release, groundwater-surface-water
exchange, and channel geomorphology could shape the up/down transmission slope beyond the elevation gap
we bound. These would have to act differentially between dammed and control basins to manufacture the
null, and snowmelt storage is itself a natural buffer that would *mimic* rather than mask a reservoir
effect; we flag the contrast as comparability-limited rather than a perfect natural experiment.

**9. MOD16 limitations in irrigated arid regions.**
Discussed. MOD16 infers ET from meteorology and vegetation indices and does not represent anthropogenic
water applications, so it underestimates ET over heavily irrigated arid land, exactly our orchard
cells. Such underestimation would compress the deficit-to-impact slope where irrigation sustains
canopies, biasing the orchard-ET gap toward zero and so toward our null; we state that a positive
induced-demand signal masked by MOD16 cannot be excluded and would need a water-balance or thermal ET
product to resolve.

**10 (Water Code). Omission of the 2022 reform (Law 21.435).**
Integrated into the policy Discussion. We now note the 2022 reform prioritizes human consumption, caps
the duration of new rights, and strengthens state authority to limit/reallocate during scarcity; that
it grandfathers pre-2022 perpetual rights and postdates most of our window, so it does not affect our
estimates; and that it moves governance toward the demand-side, adaptive allocation our results argue
for, making its effect on future demand expansion a key monitoring target.

**11 (Elevation sign contradiction).**
Corrected. The reviewer is right: 0.54 km x -0.21 per km = -0.11, the same sign as the observed -0.04
upstream-minus-downstream difference, not opposite. The Results now state elevation would make the
upstream slope ~0.11 more buffered than downstream, "the same sign as, and larger in magnitude than,"
the observed -0.04 difference, so elevation over-explains the whole gap; attributing all of it to
elevation leaves a residual downstream-specific buffering of at most ~0.07 (about 13% of the 0.53
baseline), well inside the negligibility margin and far below the 46-58% the design can detect. This is
a more honest bound than the original (and does not change the conclusion).

**12. Missing volume outcome in Table 1 and Figure 3.**
Corrected. The winsorized volume is reported in Supplementary Figure S6, not in Figure 3 / Table 1
(which carry the count). The Results sentence now attributes the count to "@fig-forest, @tbl-main" and
the volume to "Supplementary Fig. S6" with its value (+2.5 l/s per km2).
