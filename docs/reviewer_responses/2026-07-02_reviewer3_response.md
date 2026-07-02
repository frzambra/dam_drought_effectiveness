# Response to Reviewer 3 (2026-07-02 round)

Seven comments. Comment 1 (groundwater) is answered with a new empirical test; comments 2, 4, 5, 6 with
new analyses / quantified checks from the data; comment 3 with softened (non-causal) language; comment
7 is a caption correction. All new analyses are wired into the `targets` pipeline (Supplementary Tables
S10-S12 plus the traceable `table_spillover_demand` for comments 5-6).

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

Because that hierarchy rests the strongest claim on the upstream placebo, we further hardened the
placebo against the snowmelt confound (upstream reaches being snow-dominated) using ERA5-Land
snow-water-equivalent (Supplementary Table S12). The up/down peak-snowpack gap is small (0.068 vs
0.040 m w.e.), snow does not predict the transmission slope among control gauges (p = 1.0; p = 0.81 net
of elevation), the bound on any snow-induced up-down slope difference is negligible (approx 0.00 vs an
observed -0.03), and the upstream apparent-buffering pattern persists in snow-free basins (0.57 vs 0.61
downstream) as strongly as in snowy ones. Snowmelt is therefore not the driver of the placebo, so the
streamflow claim the confidence hierarchy leans on is empirically robust to this confound
(`src/R/drought/snow_placebo.R`).

**3. Confounded reservoir-storage decline; soften causal language or do a water balance.**
Softened (the reviewer offered softening OR a water balance; we take the former, as a per-reservoir
water balance needs naturalized-inflow and release records that are not public). The Discussion now
makes no causal attribution: the storage decline is confounded with any secular change in management,
release scheduling, or unrecorded abstraction. We present the falling-supply reading as the
interpretation most consistent with the independent decline in unregulated control streamflow, not as
an identified cause. (We also checked the contemporaneous within-reservoir storage-to-SPEI-12 relation
directly; it is weak and non-significant at monthly resolution, so we do not lean on it and rest the
climate-driven reading on the independent control-streamflow comparison instead.)

**4. Reservoir-use heterogeneity (hydropower vs irrigation).**
Addressed with a robustness analysis (Supplementary Table S11). The treated sample is overwhelmingly
irrigation (20 of 26 reservoirs; 18 of the 21 matched treated basins hold an irrigation reservoir,
only three are purely hydropower/potable), so the design already targets the buffering-relevant type.
A formal use-stratified estimate is precluded by the three-basin non-irrigation cell, but restricting
the headline streamflow slope gap to the irrigation-only subset leaves it unchanged (ITT -0.19 vs
-0.18; upstream placebo -0.22 vs -0.20; both permutation-null), so the null is not a hydropower-dilution
artefact. Discussed and pointed to from Methods.

**5. Inter-basin transfer spillovers; prevalence among the matched basins.**
Now quantified from the matched-basin geography (`src/R/causal/spillover_demand_checks.R`,
table_spillover_demand). The 21 treated basins and their effective controls occupy entirely disjoint
cuencas: 14 distinct treated cuencas versus 70 control cuencas, with zero shared. So no matched pair
shares a river network, and any transfer coupling would have to be an inter-cuenca transfer
specifically joining a treated cuenca to one of its matched controls. Most conveyance in the region is
intra-cuenca irrigation canals (already removed by the contamination rule); genuine inter-cuenca
transfers are few and documented (e.g. the Laja system; the Paloma complex in the Norte Chico), and to
our knowledge none links a treated cuenca to a matched control cuenca. The bias direction is favourable
regardless: a transfer from a dammed to a control basin raises the control's availability and shrinks
the estimated gap, biasing toward the null. A transfer-explicit network model is flagged for future
work.

**6. Administrative vs realized water demand.**
Discussed and now backed by the accrual record (table_spillover_demand). The registry records
administrative entitlements, not realized abstraction; under the 1981 Code the granted stock can exceed
availability and over-allocated basins are formally closed to new grants (zonas de prohibicion / areas
de restriccion), so a null in new-rights accrual could in principle reflect administrative saturation.
But the registry was far from closed over our window: new consumptive rights were granted every year
through the megadrought (roughly 2,500-7,400/yr across ~190 basins), so our result is a null in the
DIFFERENTIAL accrual between dammed and control basins, not the absence of accrual that wholesale
closure would produce. We also read the registry alongside the physical outcomes (cropland area, ET),
which do not depend on the granting process; their agreement makes administrative closure an unlikely
sole explanation.

**7. Whole-basin ET pre-trend p-value contradiction (3e-5 vs 1e-10).**
Corrected. The authoritative differential pre-2010 trend test gives p approximately 3e-5 (matching the
Results text and Supplementary Fig. S7). The Table 1 caption's "1e-10" was wrong and is now 3e-5.
