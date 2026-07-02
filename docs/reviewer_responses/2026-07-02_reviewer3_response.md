# Response to Reviewer 3 (2026-07-02 round)

Seven comments. Comment 1 (groundwater) is answered with a new empirical test; comments 2, 4 with new
analyses; comments 3, 5, 6 with expanded discussion; comment 7 is a caption correction. New analyses
are wired into the `targets` pipeline and regenerate Supplementary Tables S10-S11.

---

**1. Unmeasured groundwater substitution (test with DGA well data).**
Done. We assign the DGA well hydrographs to subcuencas by point-in-polygon and take each well's
megadrought (2010-2021) depth-to-water trend (m/yr, + = falling table), aggregated to the basin by the
outlier-robust median. Across the 26 matched basins with wells (13 dammed, 13 control, 213 wells),
dammed and control water tables fall at similar rates (0.10 vs 0.08 m/yr) and the differential is
indistinguishable from zero (aridity-adjusted ATT +0.03 m/yr, 95% CI [-0.24, 0.29]; p_perm = 0.68).
The residuals show no spatial autocorrelation (Moran's I = -0.07). Dammed basins therefore show none
of the faster drawdown a substitution confound requires, bounding it empirically (Methods; Discussion;
Supplementary Table S10; `src/R/causal/groundwater_substitution.R`).

**2. Unbalanced baseline aridity; restrict primary ATTs to overlap or downgrade demand-side claims.**
We take the second option explicitly and also keep the overlap re-match. The Discussion now states a
hierarchy of confidence: the streamflow conclusion rests on the within-basin upstream placebo (no
aridity adjustment) and is held most firmly, whereas the demand-side cross-sectional ATTs (cropland
area, ET buffering) lack a within-basin control and lean on matching plus a parametric aridity
adjustment across a wide baseline gap, so despite surviving the fully non-parametric aridity-overlap
re-match (Supplementary Table S7) we present them as corroborating a general null rather than as
independently decisive, and hold them with lower confidence than the streamflow result.

**3. Confounded reservoir-storage decline; soften causal language or do a water balance.**
Softened. The Discussion now states we make no causal attribution: the storage decline is confounded
with any secular change in management, release scheduling, or unrecorded abstraction, and partitioning
it would require a per-reservoir water balance from naturalized-inflow and release records that are not
public. We present the falling-supply reading as the interpretation most consistent with the
independent decline in unregulated control streamflow, not as an identified cause.

**4. Reservoir-use heterogeneity (hydropower vs irrigation).**
Addressed with a robustness analysis (Supplementary Table S11). The treated sample is overwhelmingly
irrigation (20 of 26 reservoirs; 18 of the 21 matched treated basins hold an irrigation reservoir,
only three are purely hydropower/potable), so the design already targets the buffering-relevant type.
A formal use-stratified estimate is precluded by the three-basin non-irrigation cell, but restricting
the headline streamflow slope gap to the irrigation-only subset leaves it unchanged (ITT -0.19 vs
-0.18; upstream placebo -0.22 vs -0.20; both permutation-null), so the null is not a hydropower-dilution
artefact. Discussed and pointed to from Methods.

**5. Inter-basin transfer spillovers; prevalence among the matched basins.**
Expanded. We note that most engineered conveyance in the study region is intra-cuenca irrigation
canals, already removed by the within-cuenca contamination rule; genuine inter-cuenca transfers are
comparatively few and documented (e.g. the Laja system; the Paloma complex in the Norte Chico), and to
our knowledge none links a matched treated basin to a specific control in its set. The bias direction
is favourable regardless: a transfer from a dammed to a control basin raises the control's availability
and shrinks the estimated gap, biasing toward the null. A transfer-explicit network model is flagged
for future work.

**6. Administrative vs realized water demand.**
Discussed. We now note the registry records administrative entitlements, not realized abstraction;
under the 1981 Code the granted stock can exceed availability and over-allocated basins are formally
closed to new grants (zonas de prohibicion / areas de restriccion), so a null in new-rights accrual
could reflect administrative saturation rather than absent demand growth. This is why we read the
registry alongside the physical outcomes (cropland area, ET), which do not depend on the granting
process; their agreement makes administrative closure an unlikely sole explanation.

**7. Whole-basin ET pre-trend p-value contradiction (3e-5 vs 1e-10).**
Corrected. The authoritative differential pre-2010 trend test gives p approximately 3e-5 (matching the
Results text and Supplementary Fig. S7). The Table 1 caption's "1e-10" was wrong and is now 3e-5.
