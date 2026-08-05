# Progress summary — 2026-06-28 (streamflow buffering test)

**Focus:** test reservoir drought-buffering on the GATED, vegetation-independent availability outcome
— **streamflow** — now that CR2 daily flow is acquired. This is the most DIRECT reservoir-effect test
(reservoirs literally regulate streamflow) and the best remaining shot at a positive after H1/H2/H5
failed on vegetation/ET proxies. Design by `drought-propagation-analyst`
(`.claude/agent-memory/.../streamflow-ssi-test-design.md`). Build: `src/R/drought/streamflow.R`.

## Data + method
- CR2 daily mean flow (m3/s), 811 DGA gauges, 1913–2020-03 (`-9999` missing). Window 2000–2020.
- Feasibility: 430 usable gauges; **217 in matched units → 17 of 21 treated + 60 control subcuencas**.
- **SSI-12**: daily→monthly mean (≥20 valid days), trailing-12-mo mean, per-calendar-month Gringorten
  normal-quantile transform over the common 2000–2020 window. Gauge→subcuenca by point-in-polygon;
  SSI averaged across a unit's gauges.
- Estimand (forcing-interacted, monthly): `feols(SSI12 ~ spei_c + treat:spei_c | unit + month + year,
  weights=w)`. Both indices negative=dry ⇒ baseline `spei_c` POSITIVE; **H1 buffering ⇒ treat:spei_c
  NEGATIVE** (treated flow held up under deficit). Inference = permutation of treatment within
  kg_group × aridity-tercile strata (2000 reps; 17 clusters ⇒ cluster-robust SEs over-reject).
- Gauge regulation class via DEM dam elevation: ITT (all dammed gauges), downstream-only (gauge below
  dam), **upstream-only placebo** (above dam — cannot be regulated). 61 down / 35 up treated gauges.

## Result — NULL, and the upstream placebo proves it is siting, not the reservoir

| subset | treat:spei_c | cluster p | **permutation p** | n_t / n_c |
|---|---:|---:|---:|---:|
| ITT | −0.183 | 0.031 | **0.39 (NS)** | 17 / 44 |
| downstream (regulated) | −0.165 | 0.058 | **0.47 (NS)** | 15 / 44 |
| **upstream PLACEBO** | **−0.201** | 0.030 | **0.48 (NS)** | 15 / 44 |

Two independent reasons this is not a reservoir effect:
1. **Nothing survives permutation** (all p≈0.39–0.48). The cluster-robust significance (ITT p=0.031)
   is the familiar ~17-cluster over-rejection.
2. **The upstream placebo is as strong as downstream** (−0.20 vs −0.17). Above-dam gauges are
   physically unregulated, yet show the same flatter SPEI→streamflow slope — so the apparent
   attenuation is a property of WHERE dammed basins sit (siting + basin hydrogeology/aridity), not the
   dam. No downstream>upstream dose-response (the diagnostic for a real regulation effect).

The baseline `spei_c`≈+0.59 (t≈9.5) confirms streamflow drought tracks meteorological drought
strongly, as expected — the design has power for the main signal; what's absent is the reservoir
DIFFERENCE.

## Bottom line — the conclusion now rests on the strongest possible evidence
Reservoirs show **no detectable drought-buffering even on the direct, vegetation-independent
availability outcome**, and the **within-design upstream placebo demonstrates the nominal signal is
siting/aridity, not regulation** — a discriminator only streamflow could provide. Combined with the
prior nulls, ALL FOUR hypotheses fail: H1 buffering (veg + ET + streamflow), H2 induced-demand
(4 methods), H5 recovery, and the H1 nonlinear rectifier. The robust finding: cross-sectional
dammed-vs-control contrasts reflect reservoir SITING in arid, hydrologically-distinct basins, not a
causal reservoir effect; naive comparisons (and calendar-time DiD, and cluster-robust SEs at ~20
clusters) manufacture spurious "buffering."

## Caveats
- Record ends 2020-03 → misses the deepest 2020–24 megadrought years.
- ITT/up-down split uses DEM dam elevation as a downstream proxy (no routed river network); abstraction/
  diversion adds managed-flow noise. The upstream placebo is robust to these (it only needs above-dam).
- A naturalized-inflow (storage+release mass-balance) counterfactual would be the operations-side test;
  needs reservoir release/spill records (unavailable).

## Files
- `config/data_sources.yml`: `streamflow:` source block.
- `src/R/drought/streamflow.R`: `read_cr2_stations`, `extract_dam_elevation`, `assign_stations_to_units`,
  `read_cr2_monthly_flow`, `compute_ssi` (Gringorten NQT), `build_ssi_panel`, `fit_ssi_buffering`,
  `permute_ssi_buffer`.
- `targets/_targets.R`: `streamflow_stations(_raw)`, `dam_elev`, `streamflow_monthly`, `ssi12`,
  `ssi_panel_{itt,down,up}`, `ssi_buffer_{itt,down,up}`, `ssi_perm_{itt,down,up}`.

## Next
1. Streamflow figure: SPEI→SSI slope by group with the ITT/downstream/upstream coefficients + the
   placebo — the cleanest single visual of "the signal is siting."
2. Fold streamflow + the upstream-placebo argument into the manuscript as the capstone of the
   siting-not-buffering thesis.
