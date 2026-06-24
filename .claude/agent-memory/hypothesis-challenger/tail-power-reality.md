---
name: tail-power-reality
description: ~21 years of monthly data across 26 basins cannot identify per-basin GPD tails, distinct thresholds, or regime switches
metadata:
  type: project
---

Data reality: 26 dammed reservoirs, monthly storage 2005-2026 (~252 months, ~21 years). Severe ecological droughts are rare and largely confined to one mega-drought episode.

**Why under-identified:**
- GPD/extreme-value tail fits need many exceedances; per-basin there may be a single drought episode contributing tail mass. Per-basin GPD shape parameters will be wildly uncertain.
- TAR/Markov-switching threshold estimates overfit noise with short series; threshold confidence intervals will span most of the storage range.
- Monthly autocorrelation means effective N << 252; consecutive drought months are not independent.
- Cross-basin pooling does not rescue this when basins share the same forcing (spatial correlation collapses effective n). See [[megadrought-shared-shock]].

**How to apply:** Treat any per-basin tail/threshold estimate as descriptive, not inferential. Hierarchical Bayesian (brms) partial pooling helps but the prior/structure will be doing most of the work — report prior-sensitivity. The honest framing is "we cannot estimate distinct tails per basin"; pooled tail contrast (all dammed vs all control) is the most that's defensible, and even that is essentially a contrast over one shared drought.
