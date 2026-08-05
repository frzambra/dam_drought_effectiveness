# Statistical Analysis Overview

Plain-language summary of the statistical methods behind the manuscript's main results (`manuscript/paper/methods.qmd`, `results.qmd`). For full detail and equations see those files; this is an orientation document, not a replacement.

## The core problem: reservoirs are not placed randomly

Dams in Chile sit in the driest, most agriculturally developed basins. A naive comparison of dammed versus undammed basins will always show dammed basins looking "worse off" or "different," simply because of where they are, not because of what the dam does. Almost every method in the paper exists to separate that siting effect from a genuine operational effect of the reservoir.

Because 18 of 24 treated basins had their reservoir built before the data record even starts, there is no "before/after" event to exploit at the basin level. So the design cannot use a classic before-after (staggered treatment) event study. Identification instead comes from two complementary strategies used together:

1. **Matching**: compare each dammed basin only to undammed basins that look similar (same climate zone, similar size, similar elevation).
2. **Conditioning on drought severity itself**: instead of comparing raw outcome levels, compare each basin's *response per unit of drought* (a slope), which cancels out the fact that dammed basins simply experienced more megadrought exposure.

## Building the matched comparison group

- **Unit of analysis**: 467 sub-watersheds. 24 contain a monitored reservoir (treated); sub-watersheds sharing a regulated main stem with a treated one are dropped as contaminated controls, leaving 398 clean candidate controls.
- **Matching method**: entropy balancing (`WeightIt`, package method `"ebal"`). This is a weighting method, not 1:1 pair matching: it reweights control basins so that, on average, their size (log area) and elevation match the treated basins exactly, within the same Köppen climate group.
- **Result**: 21 of 24 treated basins retained (3 high-Andes basins have no comparable controls), with an effective sample of ~91 controls (of 244 within common support).
- **Aridity is the residual problem**: dammed basins are far more arid than the average control, and forcing that variable to balance too (hard-balancing) shrinks the usable control sample to almost nothing (effective size ~19). The main analysis instead lets a statistical outcome model absorb the remaining aridity gap, and separately reports what happens under hard-balancing as a stress test (spoiler: results don't change).

## Main statistical estimators

Three ways of asking "is there a reservoir effect," each with a different vulnerability, all applied to the same matched sample so their agreement (or disagreement) is informative:

| Estimator | Plain-language meaning |
|---|---|
| Weighting-only (difference in weighted means) | Simplest: average outcome in treated vs. reweighted controls |
| Regression-only (g-computation) | Adjust for covariates via a regression model, no weights |
| **Doubly-robust (headline)** | Weighting *and* regression adjustment together; only fails if both are wrong at once |

Standard errors are "HC3-robust" (a heteroskedasticity-robust variant appropriate for small/uneven samples).

### The key trick: slopes instead of levels

Rather than asking "do dammed basins have less drought damage," the analysis asks "how much does outcome X change per unit increase in drought severity (SPEI-12), and is that per-unit sensitivity different in dammed basins?" This is done two ways:

- **Transmission slope**: for each basin, regress an annual outcome (e.g., streamflow drought index, evapotranspiration) on annual SPEI-12 drought severity. Compare the slope between dammed and control basins.
- **Forcing-interacted difference-in-differences (DiD)**: a panel regression with basin and year fixed effects, where the "treatment" term is `dammed × SPEI` rather than `dammed × post-year`. Because reservoir presence doesn't change over time in this dataset, the year fixed effects soak up the shared megadrought shock, and the coefficient of interest is the *differential slope*, not a level shift.

This matters because it breaks the collinearity between "when the megadrought hit" and "which basins have dams" — both happened in the same arid basins at the same time, so a plain before/after comparison could not tell them apart.

## The decisive test: within-basin placebo

The most convincing evidence in the paper does not rely on matching quality at all. Inside each dammed basin, the streamflow response to drought is compared **upstream of the dam** (unregulated, no possible dam effect) versus **downstream of the dam** (regulated). If the reservoir is truly buffering drought, only the downstream slope should flatten. In the data, the upstream slope flattens by roughly the same amount as downstream, meaning the apparent "buffering" is a property of the basin's location (its aridity), not of the dam's operation. This placebo uses 15 of the 21 matched basins that have both an upstream and downstream gauge.

## Inference: why randomization, not standard cluster-robust errors

With only ~21 treated basins ("clusters"), conventional cluster-robust standard errors are known to over-reject (make effects look more significant than they are). The primary inference procedure is therefore **randomization/permutation inference**: the treated/control labels are shuffled thousands of times within climate-and-aridity strata, and the observed effect is compared to this shuffled null distribution to get a permutation p-value. Cluster-robust confidence intervals are still reported alongside, for comparison, but are not the basis for conclusions.

Where outcomes show spatial autocorrelation (nearby basins behaving similarly for reasons unrelated to treatment, detected via Moran's I), a coarser version of the same idea is used: shuffle treatment at the *watershed* level rather than sub-watershed level, so that spatially clustered units move together in the permutation.

## Proving the nulls aren't just "not enough power"

Most headline results are null (no detectable reservoir effect). Two extra steps guard against the null being a power problem rather than a real absence of effect:

- **Equivalence testing (TOST)**: rather than only failing to reject "no effect," the analysis checks whether the estimate's confidence interval is entirely within a pre-defined "negligible effect" zone (±25% of the baseline drought-transmission slope). This margin is tied to the actual granularity of operational drought severity categories, not picked arbitrarily.
- **Minimum detectable effect (MDE) and positive control**: a known, artificial buffering effect of varying size is injected into the data, and the same pipeline is re-run to confirm it can recover that injected effect and would have flagged it as significant. This shows the design is sensitive enough that a real reservoir effect of policy-relevant size would not have been missed.

## Robustness checks (why the conclusions are hard to argue with)

The manuscript re-runs the key comparisons under many alternative choices to check that no single modeling decision is driving the conclusion:

- Different SPEI accumulation windows (6, 12, 24 months)
- Alternative matching methods (coarsened exact matching, nearest-neighbour Mahalanobis matching)
- Hard-balancing aridity directly instead of adjusting for it parametrically
- Volumetric (log-flow) version of the streamflow index instead of the standardized index, to rule out a normalization artifact
- Winsorized vs. rank-based water-rights volume measures, to rule out outlier-driven results
- Snow water equivalent adjustments, to rule out a snowmelt confound
- Groundwater well hydrographs, to bound a groundwater-substitution confound
- A dynamic event study of cropland trends, to check pre-treatment trends are flat (parallel trends assumption)

## One-paragraph summary

The design compares dammed basins to climate-, size-, and elevation-matched undammed basins (entropy balancing), and instead of comparing raw drought outcomes, it compares each basin's *sensitivity* to drought severity (a slope), which cancels out the fact that dams sit in the basins hit hardest by the current megadrought. The headline estimator is a doubly-robust matched treatment effect, cross-checked against a forcing-interacted difference-in-differences panel model. Because there are only ~21 treated basins, significance is judged by randomization inference rather than conventional standard errors. The most convincing test compares upstream (unregulated) and downstream (regulated) reaches of the same dammed basins directly: both flatten similarly under drought, which is the signature of siting, not the dam. Equivalence tests and an injected positive control confirm that the resulting nulls reflect a real absence of effect within a bounded, quantified range, not simply insufficient statistical power.
