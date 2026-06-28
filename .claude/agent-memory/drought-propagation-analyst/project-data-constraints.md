---
name: project-data-constraints
description: Built data assets and identification constraints for the Chile reservoir H1 analysis
metadata:
  type: project
---

Data assets already built in the `targets` store (readable via tar_read):
- `matched_set`: 21 dammed vs 244 control subcuencas; entropy-balancing weights `w`; covariates log_aridity, kg_group (Köppen), elev_mean, area_km2, aridity_mean.
- `storage_pct`: MONTHLY storage_fraction = level/capacity per dam ID_DGA, 2005–2024. TREATED BASINS ONLY (controls have no reservoir). Reservoir→subcuenca mapping exists.
- `znpp_annual`: per-subcuenca ANNUAL zNPP z-score, 2000–2024 (26 pts/unit). Negative = drought.
- `et_unit_annual`, `et_orchard_level`: ANNUAL ET mm/yr 2001–2024.
- On disk, NOT yet paneled: zcNDVI-6 MONTHLY (0.05°, 2000–2025, ~300 mo, standardized accumulated-NDVI anomaly) and SETI monthly ET anomaly.
- `forcing_subcuencas_full`: ANNUAL SPEI-12 per subcuenca 2000–2024 (exogenous met deficit). Monthly SPEI/SPI/EDDI multi-timescale on disk.
- Exploratory H1 targets (WEAK/NULL so far): `storage_threshold` (per-reservoir segmented breakpoints, noisy, inconsistent sign); `dose_response` (capacity×deficit interaction NS p=0.11).

**Why (constraints learned on H2):**
- Megadrought (2010+) collinear with reservoir siting (arid central Chile). NEVER identify off calendar time; condition on realized forcing (SPEI).
- ~21 treated clusters → cluster-robust SEs over-reject. Use permutation/randomization inference (permute treatment within kg_group × aridity-tercile strata). fwildclusterboot is OFF CRAN.
- Storage exists TREATED-ONLY → storage-threshold mechanism (C1/C2) is necessarily WITHIN-treated; dammed-vs-control contrast (C3) cannot use storage for controls.
- GATED for lack of data: physical (vs policy) interpretation of s* needs reservoir rule curves; release/inflow decoupling needs streamflow. Neither available.

**How to apply:** see [[h1-test-design]] for the design that respects all of these.
