# Fatal flaws

1. Placebo confounded by cumulative catchment scale

The 'upstream placebo' design compares upstream (unregulated) and downstream (regulated) gauges to separate siting from regulation. To control for catchment size, the authors use the local sub-watershed polygon area where each gauge sits, claiming that upstream and downstream gauges sit in units of essentially identical area. However, in river networks, the actual contributing catchment area of a downstream gauge is cumulative and integrates all upstream sub-watersheds, making it vastly larger than that of an upstream headwater gauge. Confusing the local polygon area with the cumulative drainage area means the comparison is highly confounded by scale, as larger catchments naturally have different routing times, storage capacities, and groundwater contributions that flatten drought transmission slopes. This scale mismatch invalidates the placebo as a clean control, undermining the paper's headline identification strategy.

## Reviewer Comments

1. Low statistical power in paired placebo

The within-basin placebo analysis relies on a paired contrast of only 15 treated basins. With such a small sample size, the paired permutation test has very low statistical power to detect differences in transmission slopes. The resulting non-significant p-value (p = 0.72) is highly likely to be a Type II error (failure to reject a false null) rather than evidence of true equivalence between upstream and downstream slopes. The authors should perform a power analysis specifically for this paired design or temper their strong conclusions regarding the similarity of the slopes.

2. Aridity matching underpowered or confounded

Aridity is identified as the primary confounder explaining apparent buffering. However, in the main matching analysis, the authors do not balance aridity because doing so collapses the effective sample size (ESS) of the control group from 91 to 19. This leaves a substantial residual imbalance (SMD = 0.17) in the main model, meaning it remains confounded by aridity. When they do force balance (the 'hard-balanced' sensitivity analysis), the ESS drops to 19, making the test extremely underpowered to detect any real operational buffering. Thus, the matched analysis is either confounded or lacks the power to reject the null, making the conclusion of 'no effect' unreliable.