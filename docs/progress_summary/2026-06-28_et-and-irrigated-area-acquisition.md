# Progress summary — 2026-06-28

**Focus:** acquire the two H2 mediator/outcome time series the
[`2026-06-26`](2026-06-26_forcing-conditioned-att.md) summary flagged as the exhausted-proxy gap —
**annual ET (consumptive water use)** and **observed irrigated-area expansion** — and wire them into
the `targets` pipeline. Both are now built; the pipeline is fully up to date.

## New outcomes built

### 1. Annual ET (mm/yr) panels — MOD16A2GF
- `et_annual_file` — cached 24-band annual-ET raster (mm/yr, 2001–2024), the one expensive pass.
- `et_unit_annual` — whole-basin annual ET, **228 units × 24 yr** (controls ~621, treated ~400 mm/yr).
- `et_orchard_level` — orchard-stratum annual ET, **18 treated / 31 control** (treated ~412 vs
  control ~586 mm/yr). The clean H2 consumptive-use signal.
- `att_et_buffering` **re-run on corrected ingestion** (the 2026-06-26 "decisive null" was built on a
  now-missing monthly dataset): **DR ATT −0.014 [−0.065, 0.037], t=−0.53 (ns)**. The H1 null HOLDS —
  orchard ET is weakly drought-sensitive in both groups (treated 0.018 vs control 0.033); reservoirs
  add no detectable ET buffering beyond what irrigated agriculture already achieves.

### 2. Observed irrigated-area panels — MapBiomas Collection 2 (30 m)
- `irrig_area_panel` — agriculture (class 18) area per unit per year, **265 units × 1999–2024**.
- `farm_area_panel` — farming {9 silviculture, 15 pasture, 18 agriculture}, same grain.
- `att_irrig_area_expansion` — dammed-vs-control net-cropland-expansion ATT.

## Headline result — the observed area data DISCONFIRMS the H2 expansion limb

| expansion outcome | DR ATT | 95% CI | t |
|---|---:|---:|---:|
| **observed MapBiomas cropland (class 18)** | **−0.69 ha/km²** | **[−2.44, 1.06]** | −0.77 (ns) |
| Catastro orchard reconstruction (ref) | +1.41 ha/km² | [0.08, 2.73] | 2.08 |

- **Dammed basins hold ~10× more cropland than controls** (mean frac 0.11 vs 0.02) — strong
  endogenous SITING, as the Catastro layer also showed.
- **But net cropland area is flat/slightly declining in both groups** (treated 626,867→609,821 ha;
  ratio treated/control 0.954→0.926), and the expansion ATT is a **clean null** (−0.69, ns).
- **Reconciliation:** the Catastro orchard "expansion" (+1.41, sig.) is a **compositional shift
  toward perennials within roughly-constant cropland area** — plus survival-bias/siting artifacts of
  the snapshot reconstruction — NOT net cropland growth. Broad farming {9,15,18} also grew similarly
  in both groups (treated +4.3%, control +3.8%).

**Bottom line:** across all three observable H2 mediators the induced-demand mechanism now lacks
support: (i) ecological deficit→impact slope on irrigated land — null (2026-06-26); (ii) reservoir
ET buffering — null; (iii) net irrigated-AREA expansion — null. The cross-sectional dammed-vs-control
gaps are baseline aridity + endogenous siting, not a reservoir-driven vulnerability dynamic.

## Caveats
- MapBiomas class 18 is total cropland (annual + perennial), not irrigation-specific; the orchard
  composition shift is real and may still carry a water-demand signal not visible in net area.
- Whole-basin ET is MOD16-unreliable over barren (min_cells=20 guard drops ~6 hyper-arid basins);
  the orchard-stratum ET is the reliable H2 ET signal.
- Expansion identification is still siting-limited (most dams left-censored pre-record); the area
  panels support a DiD/event-study that is not yet run.

## Infrastructure (see CLAUDE.md / data_sources.yml)
- **Corrected the `et_mod16` config** — it was wrong on every field: 8-day (not monthly), mm/8day
  (scale ×1), real path `ET.MOD16A2GF.061/`, filename `ET.MOD1623GF_Chile_500m_{YYYY.MM.DD}.tif`.
  Two non-physical populations masked at a 100 mm/8day cap (fill plateau ~3276 + a ~2000–3270
  contamination cluster). One corrupt source file (2008-03-29) is tolerated (45/46 composites).
- The source drive is slow USB-NTFS; both ET (99 GB) and MapBiomas (3.6 GB) are **mirrored to local
  NVMe** before processing. `aggregate_et_annual` is year-by-year, resumable (persistent
  `annual_bands/`), with terra scratch on `/home` wiped per year.
- MapBiomas area uses **`exactextractr`** (new dependency) — ~100× faster than the terra
  per-polygon / full-grid-aggregate approaches tried first.

## Files touched
- `config/data_sources.yml` — rewritten `et_mod16` block.
- `src/R/preprocessing/et_data.R` — `mod16_8day_paths`, `mirror_et_local`, `aggregate_et_annual`
  (resumable), `extract_unit_et_total_annual`, `extract_unit_et_annual`, helpers.
- `src/R/preprocessing/landcover_area.R` (new) — `mirror_paths_local`, `extract_unit_area_panel`
  (exactextractr), `area_expansion_summary`, `fit_area_expansion_att`.
- `targets/_targets.R` — `et_local_dir`, `et_stack_local`, `et_annual_file`, `et_unit_annual`,
  `et_orchard_level`; `mb_area_paths`, `irrig_area_panel`, `farm_area_panel`, `irrig_area_expansion`,
  `att_irrig_area_expansion`; added `exactextractr` to packages.

## DiD / event-study (added 2026-06-28) — dynamic confirmation of the area null

Design (reservoir-causal-analyst): treatment is near-time-invariant (18/24 dams pre-1999; ≤3
commission in-window) so a commissioning event study is infeasible and a treated×post TWFE would
identify off the megadrought-collinear calendar time. Instead the **dose is SPEI, not the year**:
`feols(y ~ spei_c + treat:spei_c | unit + year, weights=~w, cluster=~unit)`. Year FE remove the
common drought shock; `treat:spei_c` is the differential deficit→impact SLOPE. Inference is
randomization (permute treatment within kg_group × aridity-tercile strata, 999 reps) because the real
n is ~24 treated CLUSTERS (fwildclusterboot is off CRAN). `src/R/causal/did_event_study.R`.

**Slope-gap `treat:spei_c` (PRIMARY):**

| panel | coef | p_cluster | **p_perm** | event-study pre-2009 leads (Wald) |
|---|---:|---:|---:|---:|
| area_frac (MapBiomas) | +0.0007 | 0.73 | **0.91 (null)** | **p=0.68 — FLAT ✓** |
| log basin ET | +0.048 | 3.9e-5 | **0.11 (null)** | p≈1e-10 — violated |
| log orchard ET | −0.020 | 0.13 | **0.24 (null)** | p=0.003 — violated |

- **Observed irrigated AREA — clean dynamic null.** Parallel pre-trends hold (Wald p=0.68), the
  SPEI-slope gap is null (p_perm 0.91), and the event-study shows no post-2010 divergence (mean lag
  coef ~0). This is the strongest new result: **no reservoir-driven irrigated-area dynamic**, with a
  credible DiD design.
- **basin ET "significant" under cluster-robust SE (p=4e-5) but NULL under permutation (0.11)** — a
  textbook few-clusters over-rejection; and its pre-trends fail (p≈1e-10). The dynamic ET design is
  **pre-trend-confounded**, so ET conclusions rest on the CROSS-SECTIONAL ET nulls (buffering ATT
  −0.014, ns), not this DiD.
- **Mechanism triple-diff** (treat:spei_c:irr_share_c, orchard ET): +0.11, p=0.13 (null).
- **Aridity placebo** (high-aridity control tercile as pseudo-treat): null for area (p=0.09) but
  **significant for orchard ET (p=0.002)** — residual aridity-slope sensitivity; disclose. The real
  reservoir slope-gap is null regardless.

**Decision-rule outcome:** triple null is CONFIRMED cleanly for the observed-area panel (flat
pre-trends, slope-gap CI covers 0, placebo null). For ET, the slope-gap is null but the dynamic
design fails its own assumptions (pre-trends + placebo), so ET evidence stays cross-sectional. No
panel shows a positive H2 effect — nothing overturned.

## Manuscript figures + tables (added 2026-06-28)

Figure infrastructure built: `config/figure_settings.yml` (Nature Water style), `src/R/visualization/`
(`theme.R` publication theme + palette + `save_fig`; `figures.R`; `tables.R`). Outputs flow to
`results/figures/` and `results/tables/` as file targets, and are wired into
`manuscript/paper/results.qmd`.

- **Fig 1 (`fig_area_did`)** — observed irrigated-area DiD: (a) dammed (~11%) vs control (~2.4%)
  cropland-fraction trajectories (the ~10x siting gap, parallel), (b) event-study (flat pre-trends,
  no post-2010 divergence). The clean dynamic null.
- **Fig 2 (`fig_convergent_null`)** — forest plot, standardized effect (estimate/SE; DiD rows via
  permutation p) across all four estimators; every CI spans zero.
- **Table 1 (`table_main_results`)** — convergent-null table (2 cross-sectional ATTs + 3 DiD
  slope-gaps); verdict from the trustworthy inference (permutation p for DiD). CSV + markdown.

Pipeline fully up to date (0 outdated, 121 targets).

## Next
1. **renv::snapshot()** to pin `exactextractr`, `patchwork`, `ggtext` in the lockfile
   (`fwildclusterboot` is off CRAN — permutation inference used instead).
2. **Reframe the contribution**: a convergent multi-method null (forcing-conditioned slope, ET
   buffering, net area expansion, AND a clean dynamic area DiD with parallel trends) shows the
   cross-sectional dammed-vs-control gaps are siting + baseline aridity, not a reservoir-driven
   vulnerability dynamic — a caution basin-mean greenness studies would miss.
3. Whole-basin ET pre-trend failure + orchard-ET aridity placebo suggest the ET panels still carry an
   aridity gradient; an aridity²-flexible or aridity-tercile-stratified ET DiD could probe it.
