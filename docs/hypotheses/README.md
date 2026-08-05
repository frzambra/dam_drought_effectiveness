# Research Hypotheses — Reservoir Effectiveness & Drought Vulnerability in Chile

Original program (H1–H4) generated 2026-06-23 and stress-tested by the
`hypothesis-challenger` agent (see [`challenge-findings.md`](challenge-findings.md)).
**Program pivot (2026-06-29):** H1–H4 all returned a convergent null; the program was
re-centred on H5–H7 by the `hypothesis-generator` agent.

## Core question

Do reservoirs reduce drought impacts, or do they primarily **delay** impacts while
increasing long-term vulnerability through expansion of water-dependent land uses?

## Current program — retained hypotheses (post-pivot, >8 Nature Water bar)

| ID | Short name | Overall | Role |
|----|------------|---------|------|
| [H5](H5-markers-not-makers.md) | Reservoirs as markers, not makers | **9.0** | **Central narrative** |
| [H7](H7-upstream-downstream-placebo.md) | Upstream/downstream within-basin placebo | 8.3 | **Identification engine** (15/21 basins) |
| [H6](H6-decoupling-regime-shift.md) | Damming changes *what drought means* | 7.8 | Demoted — discussion only |
| H8 | The evaporating buffer (refill degradation) | **RETIRED** | Tested 2026-06-29, null 4/4 (powered) |

### Recommended paper arc

1. **H5** establishes the headline: conditional on siting, the operational reservoir effect
   brackets zero — reservoirs *mark* pre-existing vulnerability, they do not *make* it.
2. **H7** is the identification engine: the within-basin upstream placebo (covering 15/21
   treated basins) differences out siting and shows the apparent buffering is selection.
3. **Aridification** (Zambrano et al. 2025, *Earth's Future*) reframes the policy stakes as a
   **supply ceiling**: refill efficiency is intact (H8 null), but less water arrives, so the
   binding constraint is inflow, not storage.

**Single message:** *Reservoirs in Chile still store water as well as ever — there is just less
and less to store; under aridification the binding constraint is inflow, not storage, so
building more dams is a supply-blind response, not resilience.*

> **H8 — "The evaporating buffer" (RETIRED).** Proposed that refill efficiency
> (storage produced per unit meteorological surplus) decays over time under aridification;
> pre-specified fingerprint = negative SPEI-surplus × year interaction. Tested 2026-06-29 on
> cached storage/SPEI panels (22 reservoirs / 20 matched units, 2005–2024) and **null 4/4 with
> demonstrated power** (mid-sample refill transmission +0.013, p=0.027; interaction −0.0006,
> p=0.57 monthly, −0.034, p=0.33 annual-gain). The real signal is a whole-band storage
> downshift (peak −0.013/yr, trough drops too, amplitude flat) — a supply/demand level shift,
> *not* a refill-degradation mechanism. The honest anti-"build more dams" argument is therefore
> a **supply** argument, not a buffer-degradation one.

## Superseded program (H1–H4) — all returned a convergent null

| ID | Short name | Original score | Outcome |
|----|------------|---------|------|
| [H2](H2-induced-demand.md) | Induced demand erases the buffer | 9.4 | **Null** across 4 estimators |
| [H1](H1-storage-rectifier.md) | Storage as a drought-signal rectifier | 8.8 | **Null** (QR tail dies under permutation; GPD tail anti-H1) |
| [H4](H4-ecological-lockin.md) | Ecological lock-in (resistance vs. resilience) | 8.3 | Not pursued after pivot |
| [H3](H3-spatial-displacement.md) | Spatial displacement of vulnerability | 8.1 | Not pursued after pivot |

These four treated endogenous siting as a confound to defeat en route to a treatment effect;
the convergent null plus the H7 placebo showed siting **is** the mechanism — which is what H5
now makes the object of study.

## Cross-cutting threats (must be resolved before any causal claim)

- **Endogenous reservoir siting/timing** — dams are built where demand/aridity is high;
  all four hypotheses depend on the matching / synthetic-control / heterogeneity-robust
  DiD design holding.
- **2010–present mega-drought** is collinear with the treatment clock — the single
  largest confound for H1 and H2 (a monotone decline in protection is expected from
  hydrological exhaustion alone).
- **Drought-vs-land-conversion attribution** in NDVI/ET must be settled before H2/H4.
- **n ≈ 26 reservoirs** caps generalizability — frame as "Chile as natural laboratory."

## Data-state caveat (updated 2026-06-24)

Most core datasets are now **on disk and registered in `config/data_sources.yml`**:

- **Reservoir storage** — 26 monitored reservoirs, monthly 2005-01 → 2026-04, with a
  `max_level_hm3` capacity column. Storage and capacity **share units (hm³)**, so this is
  volume, not a unitless index; percent-of-capacity = `value / max_level_hm3` is directly
  computable (still required before any cross-reservoir or "remaining slack" work; `Rungue`
  has no capacity → drop/impute). National dam **point** registry shapefile (1370 dams;
  construction year, use, size, region) also present.
- **Meteorological drought (CHIRPS-CHIRTS)** — SPI/SPEI/EDDI, monthly, 1991–2026,
  timescales 1/3/6/12/24/36 months.
- **Ecological-drought / EO (MODIS)** — zNPP (annual, 2000–2025), zcNDVI-6 (monthly,
  2000–2025), SETI (standardized actual-ET anomaly, monthly, scales 1–36, 2000–2024).
- **Land cover** — MapBiomas Chile Col. 2, 30 m annual 1999–2024 (agriculture/pasture/
  silviculture classes); MODIS MCD12Q1 IGBP, 500 m annual 2001–2024 as a coarse cross-check.

- **Watershed boundaries** — now available: DGA BNA **139 cuencas** + **489 subcuencas**
  (`data/raw/watersheds/`, registered in `config/data_sources.yml`). These are the analysis
  unit; assign reservoirs to their containing unit by point-in-polygon. The interim
  dam-point extraction is retired.

**Still missing (gates the causal claim):**

- **No streamflow / gauge data** — so hydrological drought (SSI) is unavailable; only the
  meteorological indices and MODIS ET/veg products exist. This breaks the
  *hydrological-drought* link in the core pathway.
- **Reservoir operating rules** — needed before the H1 manuscript (not before the first analysis).

## Next steps

- [x] Acquire and audit hydroclimate / EO / land-cover datasets (done; see `config/data_sources.yml`).
- [x] Acquire watershed boundaries — DGA BNA cuencas (139) + subcuencas (489) now in `data/raw/watersheds/`.
- [x] Assign reservoirs to containing cuenca/subcuenca (point-in-polygon) — 26/26 matched at both grains.
- [x] Pick the analysis grain — **subcuenca** (24 treated, 398 clean controls); cuenca as robustness. See [`../design/grain-selection.md`](../design/grain-selection.md).
- [x] Build the matched control set — entropy balancing, ATT, within Köppen group on log-area + mean elevation; 21/24 treated retained, perfect balance, ESS≈91. See [`../design/matched-controls.md`](../design/matched-controls.md).
- [x] Add elevation (SRTM 3s DEM) — took matched-set ESS from 9 to 91; `dem` in config, `extract_unit_terrain()`.
- [ ] Acquire DGA streamflow → SSI (closes the hydrological-drought link) — now the largest missing dataset.
- [x] CEM / 1:k-NN robustness matches — ebal & NN agree on all 21 treated (NN |SMD|<0.1); CEM prunes the 4 most extreme large/high basins. See [`../design/matched-controls.md`](../design/matched-controls.md).
- [ ] Add annual P/PET aridity covariate; doubly-robust effect estimation on the weighted set (report with/without the 4 CEM-pruned units).
- [ ] Acquire DGA streamflow → compute SSI to close the hydrological-drought link.
- [ ] Acquire reservoir operating rules (before H1 manuscript).
- [ ] Normalize storage to percent-of-capacity.
- [ ] **Run H1 first** (per `nature-water-editor`): storage-state-conditional meteorology→ET/vegetation
      contrast on matched watersheds — the falsification gate for the whole program — before H2's headline.
- [ ] Identify off **continuous within-panel storage-state variation** (matched dammed/undammed),
      NOT staggered-DiD-on-commissioning (~21/26 reservoirs predate the 2005 panel → too few events).
- [ ] Win the **mediation gate** (H2) and the **counterfactual-overshoot test** (H1)
      before committing either to the manuscript.
