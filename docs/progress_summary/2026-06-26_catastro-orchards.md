# Progress summary — 2026-06-26 (Catastro Frutícola orchards)

**Focus:** ingest the CIREN/ODEPA **Catastro Frutícola** (irrigated fruit-orchard cadastre) and
use it two ways — (1) a *ground-truth* irrigated stratum for the forcing-conditioned ATT, and
(2) the *orchard-area expansion* mediator (H2 induced-demand). Companion to
[`2026-06-26_forcing-conditioned-att.md`](2026-06-26_forcing-conditioned-att.md).

## The data

Per-region fruit-orchard polygons, definitively irrigated (cherry, table grape, blueberry,
avocado, walnut, citrus, stone fruit, olive…). One survey per region every ~3-4 yr; we take each
region's **latest** `poligonos_<year>` (2021–2025). Registered in
`config/data_sources.yml:catastro_fruticola`; ingested by `src/R/data_ingestion/read_orchards.R`.

- **12 regions, 89,683 polygons, uniform EPSG:32719 (UTM 19S)**; ~335 kha declared /
  ~379 kha geometric footprint. Attributes: `ESPECIE`, **`plant_year`** (establishment),
  `SUPERFICIE` (ha).
- Dissolved national footprint saved to `data/processed/orchards/orchards_{latest,dissolved}.gpkg`.
  Dissolve runs in the **native UTM** (planar GEOS) — the geographic s2 path fails on the
  cadastre's degenerate edges.
- **19 of 21 matched dammed subcuencas contain orchards** (median ~2170 ha) vs 46/244 controls
  (median ~216 ha) — reservoirs↔orchards strongly coupled.

## Arc 1 — Definitive irrigated stratum (done)

Rasterized the orchard footprint to the zNPP grid as a cover fraction
(`orchard_fraction_raster()`), thresholded (≥0.05) into an irrigated stratum, and re-ran the
forcing-conditioned ATT vs natural cover (`dr_att_forcing_orchard`).

| stratum | DR ATT (linear) | + aridity² | n_t / n_c |
|---|---:|---:|---:|
| **irrigated — ground-truth orchards** | **0.060** (t=0.68, ns) | **−0.048** (ns) | 18 / 36 |
| natural | 0.362 (t=4.31) | 0.127 (t=2.03) | 21 / 224 |

**Confirms the H2-vulnerability null with ground truth.** On definitively-irrigated land, dammed
and control basins transmit drought to productivity almost identically (raw slopes 0.224 vs
0.159); the dammed-vs-control divergence is entirely in natural cover. Agrees with the MapBiomas
class-18 proxy (0.077, ns). So at the zNPP grain there is **no evidence reservoirs make irrigated
agriculture more drought-sensitive** — the *vulnerability* limb of H2 is not detectable in the
ecological proxy (grain caveat: zNPP ~1 km over fragmented orchards dilutes the signal).

## Arc 2 — Orchard-area EXPANSION mediator (done) — H2's first limb IS supported

`plant_year` reconstructs cumulative orchard area present by each year (orchards planted ≤ t),
zero-filled across all matched basins (`orchard_area_panel()` →
`orchard_expansion_summary()` → `att_orchard_expansion`). Tests the *prior* limb of H2:
**did dammed basins expand irrigated area more than matched controls?**

Raw: dammed orchard area **17,997 → 101,680 ha (2005→2024)**; treated mean expansion intensity
**1.66** vs control **0.11 ha/km²** (~15×). Doubly-robust ATT:

| outcome | ATT | 95% CI | t |
|---|---:|---:|---:|
| ha added per km² | 1.41 | [0.08, 2.73] | 2.08 |
| log area ratio | 0.82 | [0.24, 1.40] | 2.78 |
| ha added (absolute) | 3,434 | [406, 6461] | 2.22 |

**Significant across all three metrics: dammed basins expanded irrigated orchards markedly more
than climatically-matched controls** — the induced-demand prediction.

## The decomposition (the headline of the whole arc)

H2 has two limbs, and the orchard data resolves them oppositely:

1. **Reservoirs → agricultural expansion: SUPPORTED.** Dammed basins expanded irrigated orchard
   area ~2–15× more than matched controls (expansion ATT significant).
2. **Expansion → amplified ecological drought vulnerability: NOT detected.** Irrigated land in
   dammed basins is no more drought-sensitive (transmission-slope ATT null) — the basin-mean
   "vulnerability" signal was a natural-vegetation aridity confound, not the irrigated mechanism.

The induced demand is real; its translation into *ecological* drought vulnerability is not visible
in NPP — plausibly because irrigation buffers productivity (reservoirs supply the water), or
because the true vulnerability outcome is water-balance / shortage / ET, not greenness.

## Caveats / open items

- **Endogenous siting is the headline threat to Arc 2.** Reservoirs are built where irrigation
  demand exists/was anticipated, so the expansion ATT is reservoir-*facilitated* at best, not
  cleanly reservoir-*caused*. The matched design controls climate/size/elevation/aridity but not
  latent agricultural suitability. Needs the causal treatment: pre-reservoir expansion trends,
  commissioning-timing event study (limited — most dams left-censored pre-2005), or an instrument.
- **Snapshot-survival bias:** grubbed-up orchards are invisible, so early-year area is
  under-counted and expansion over-stated (affects both groups; possibly differentially).
- **plant_year** ~8% missing + a 1900 fill → folded to a pre-window baseline.
- Arc 1 grain limit: zNPP ~1 km can't isolate fragmented orchards; the expansion mediator
  (grain-independent) is the stronger use of this data.

## Next (priority order)

1. **Causal treatment of the expansion ATT** — pre-trends / forcing-conditioning / timing to move
   from "dammed basins have more orchards" to "reservoirs facilitated expansion."
2. **Better vulnerability outcome** — water-balance / streamflow / ET shortage (gated on
   streamflow) to test the second H2 limb where NPP is blind.
3. Extend the orchard ingestion beyond the matched set if the analysis grain widens.

## Files touched

- `src/R/data_ingestion/read_orchards.R` (new) — `orchard_latest_shapefiles()`,
  `read_orchards_latest()`, `dissolve_orchards()`.
- `src/R/preprocessing/orchard_outcomes.R` (new) — `orchard_fraction_raster()`,
  `extract_unit_orchard_znpp()`, `combine_orchard_natural()`.
- `src/R/preprocessing/orchard_expansion.R` (new) — `assign_orchards_to_units()`,
  `orchard_area_panel()`, `orchard_expansion_summary()`, `fit_orchard_expansion_att()`.
- `config/data_sources.yml` — `catastro_fruticola` block.
- `targets/_targets.R` — `orchard_root`, `orchards_latest`, `orchards_dissolved`,
  `orchard_frac_file`, `znpp_orchard`, `znpp_orchard_natural`, `dr_att_forcing_orchard`;
  `orchards_assigned`, `orchard_panel`, `orchard_expansion`, `att_orchard_expansion`.
- `data/processed/orchards/` — `orchards_latest.gpkg`, `orchards_dissolved.gpkg`, `orchard_frac.tif`.
