# Fatal flaws

1. Potential contamination of upstream placebo by cascade dams

The central identification strategy relies on the assumption that upstream gauges are physically unregulated and thus serve as a valid placebo. However, many river basins in Chile feature cascade reservoir systems or multiple upstream impoundments (for example, in the Biobío or Maule basins). If an upstream gauge of a downstream reservoir is located downstream of another upstream dam, it is actually regulated. This would cause the upstream transmission slope to flatten due to actual regulation, leading to a false-positive conclusion that the downstream flattening is a siting confound rather than an operational effect. The authors must verify that none of the 15 upstream gauges are downstream of other dams, or exclude any contaminated gauges from the placebo sample.


# Reviewer Comments

1. Unspecified handling of missing streamflow data

The authors do not specify how missing values in the daily streamflow records from the DGA network were handled during the aggregation to monthly and 12-month Standardized Streamflow Index (SSI-12) values. Given that streamflow gauges in mountain regions often suffer from data gaps, especially during extreme flow periods, arbitrary imputation or ignoring missing days could bias the SSI-12 estimates. The authors should clarify their data completeness thresholds and gap-filling procedures.

2. Confounding of storage trends by reservoir sedimentation

Over a 20-year period in steep Andean catchments with high sediment yields, reservoir sedimentation can significantly reduce active storage capacity. If the authors use a static nominal capacity from the registry as the denominator, the observed decline in peak and trough storage (expressed as % of capacity) could be partially or fully explained by the physical loss of active storage volume due to sedimentation, rather than purely a supply-side decline in inflows. The authors should discuss this potential confound or verify whether the nominal capacities have been updated to reflect sedimentation over the study period.

3. Unweighted trend analysis of percent-of-capacity storage

The trend analysis of reservoir storage (peak, trough, and amplitude) is conducted using percent-of-capacity as the dependent variable, pooling all 26 reservoirs with equal weight. However, because these reservoirs differ by orders of magnitude in their storage capacities, an unweighted trend in percentage points can be highly misleading. A steep decline in a few small reservoirs could dominate the pooled trend, even if the largest reservoirs (which hold the vast majority of the country's water buffer) remain stable. To accurately reflect the shrinking of the national multi-year buffering capacity, the authors should weight the trend analysis by reservoir capacity or report the trends in absolute volumetric terms (hm³).

4. Inappropriate interaction model for rigid cropland area

The forcing-interacted DiD model operationalizes agricultural expansion/vulnerability as the interaction between reservoir presence and annual SPEI-12 (beta). However, cropland area—especially permanent orchards and vineyards which dominate central Chile—is a highly rigid, structural variable that does not expand or contract rapidly in response to annual fluctuations in meteorological drought (SPEI-12). Consequently, the null result on this interaction coefficient (beta = 0.001, p = 0.91) is largely expected due to the slow-moving nature of the outcome, and does not rule out long-term, cumulative reservoir-induced demand expansion during the megadrought. The authors should temper their interpretation of this specific null or rely primarily on the dynamic event study to support the claim of no post-2010 expansion.

5. Extreme weight concentration in aridity hard-balancing

The strict hard-balancing of aridity reduces the effective sample size (ESS) of the control group from 244 to just 19. Such a drastic reduction in ESS indicates extreme weight concentration on a very small subset of control basins. This makes the resulting ITT estimate highly sensitive to idiosyncratic noise or outliers in those few highly-weighted control basins, potentially undermining the reliability of the finding that the apparent buffering vanishes. The authors should report weight diagnostics (such as the maximum weight or a participation ratio) and perform a leave-one-out sensitivity analysis on the highly-weighted control basins to ensure the result is not driven by a single control unit.
