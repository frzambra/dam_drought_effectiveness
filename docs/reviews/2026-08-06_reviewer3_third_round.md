# Fatal Flaws

1. Unvalidated Upstream-Downstream Hydrological Connectivity

The paper's central headline claim relies on the upstream/downstream placebo design, which assumes that upstream gauges are physically located on the same river channel feeding the reservoir. However, the classification of gauges is based solely on SRTM elevation relative to the reservoir outlet and is not validated against a routed stream network topology. Without a routed network, there is a high risk that many 'upstream' gauges are actually located on parallel, hydrologically disconnected tributaries. If these tributaries have different geomorphic characteristics, microclimates, or snowmelt regimes, their natural attenuation would be misread as a siting confound, invalidating the placebo design and overturning the headline conclusion. The authors must validate their gauge pairs using a routed stream network to ensure true hydrological connectivity.

# Reviewer Comments

1. Year fixed effects absorb temporal drought variation

The inclusion of year fixed effects $\tau_t$ in the difference-in-differences specification is a standard way to control for contemporaneous national shocks. However, because multi-year droughts are characterized by widespread, temporally correlated deficits, these year fixed effects absorb the common temporal component of the megadrought. Consequently, the interaction coefficient $\beta$ is identified solely from the spatial variation of SPEI within each year across sub-watersheds. Given that the analysis is matched and weighted within Köppen climate regions, the remaining within-year, within-region variation in SPEI may be limited, which could reduce the statistical power to detect a buffering effect or shift the estimand from a response to a severe regional drought to a response to localized microclimatic deviations. It would be helpful to discuss this trade-off or report a sensitivity specification where year fixed effects are replaced by a smooth national time trend to retain more of the temporal drought signal.

2. Permutation null variance compression in placebo test

The permutation scheme for the within-basin placebo holds the gauge composition of each panel fixed, meaning that a control basin drawn as pseudo-treated contributes the identical gauge set to both the upstream and downstream panels. Under the null hypothesis, however, actual treated basins still exhibit natural upstream-downstream differences (e.g., due to elevation and catchment area gradients) that are absent by construction in the pseudo-treated control basins where the difference is identically zero. This asymmetry could artificially compress the variance of the permutation null distribution of $D = \beta_{\text{down}} - \beta_{\text{up}}$, potentially leading to over-rejection (inflated Type I error). While the paper's finding of a null result ($p = 0.72$) remains robust because any variance compression would only bias the p-value downward, this methodological limitation should be explicitly acknowledged, or a sensitivity analysis using elevation-based partitioning of control gauges should be discussed.

3. Drought-Dominated Short Standardization Window

The Standardized Streamflow Index (SSI-12) is calculated using a 21-year window (2000–2020) that is heavily dominated by the post-2010 megadrought. Standardizing hydrological indices over such a short and dry period violates standard meteorological guidelines (which recommend at least 30 years of stable baseline) and artificially inflates SSI values during the drought, making them appear less severe. This truncation of the dry tail can distort the estimated SPEI-to-SSI transmission slopes and potentially obscure real operational buffering effects. The authors should re-standardize the SSI using a longer historical baseline (e.g., starting from 1980 or 1990) to ensure the robustness of their transmission slope estimates.

4. Selection Bias from Missing Data Propagation

The authors apply a strict rule where any missing daily or monthly value in a trailing 12-month window propagates to make the entire SSI-12 value missing. In hydrology, data gaps are highly non-random and frequently occur during extreme events (e.g., when gauges dry up or are washed out). Systematically dropping these extreme periods truncates the streamflow distribution, which can artificially flatten the estimated SPEI-to-SSI transmission slopes and introduce selection bias. The authors should assess the extent of missingness during drought peaks and test whether this propagation rule systematically excludes the most severe hydrological drought phases.

5. Trend Bias from Mid-Panel Reservoir Entries

The linear trend analysis of reservoir storage pools monthly records for 26 reservoirs over 2005–2024. However, several of these reservoirs were commissioned after 2005. Including reservoirs that enter the panel mid-way can bias the linear trend estimates of peak and trough storage, as their initial filling phases or missing pre-commissioning periods are not accounted for by static reservoir fixed effects. The authors should restrict the percent-of-capacity trend analysis to a coverage-stable subset of reservoirs active across the entire 2005–2024 period, or explicitly control for commissioning dates.

6. Residual Confounding from Unbalanced Aridity

In the cross-basin matched design, baseline aridity (P/PET) is not hard-balanced because doing so reduces the effective sample size. This leaves a residual standardized mean difference (SMD) of -0.17, which the authors rely on a linear doubly-robust outcome model to absorb. However, hydrological processes like drought transmission are highly non-linear functions of aridity. A linear regression adjustment may fail to fully control for this confounding, leaving residual aridity differences that could bias the cross-basin comparison. The authors should employ non-linear or matching methods that achieve better balance on aridity without collapsing the sample size, or explicitly test for non-linear aridity interactions.

7. Control Group Contamination by Unmonitored Dams

The matched control group consists of sub-watersheds that do not contain any of the 26 monitored reservoirs. However, Chile's national dam registry contains 1,370 impoundments. If the 244 matched control sub-watersheds contain some of these other 1,344 unmonitored dams, the control group is contaminated with treatment, which would bias the estimated treatment effects towards zero. The authors should screen the control sub-watersheds against the full national dam inventory to ensure they are truly undammed, or at least quantify the density of unmonitored impoundments in the control group.
