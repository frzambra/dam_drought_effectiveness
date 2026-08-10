# Phase 0-1 targets pipeline: ingest reservoir storage + index rasters, compute
# percent-of-capacity, extract forcing/outcome indices at reservoir points, and run the
# forcing-conditioned response-function analyses that break the mega-drought confound.
#
# Run from the project root:
#   targets::tar_make(script = "targets/_targets.R", store = "targets/store")
#   targets::tar_visnetwork(script = "targets/_targets.R", store = "targets/store")
#   targets::tar_read(propagation_summary, store = "targets/store")
#
# Phases 2-4 (matched controls, H1 tail, H2 mediation) are gated on watershed boundaries,
# land-cover/irrigated-area, and operating rules — see config/variables.yml:gated.

library(targets)

# Resolve the project root whether targets runs from root or from targets/.
root <- getwd()
if (basename(root) == "targets") root <- dirname(root)
Sys.setenv(DDV_ROOT = root)

tar_source(file.path(root, "src", "R"))   # source all analysis functions recursively

tar_option_set(
  packages = c("data.table", "sf", "terra", "yaml",
               "fixest", "segmented", "lubridate",
               "WeightIt", "cobalt", "MatchIt", "exactextractr",
               "ggplot2", "patchwork", "quantreg", "extRemes")
)

list(
  # --- config -----------------------------------------------------------------------
  # Track the YAML files so edits invalidate downstream targets automatically.
  tar_target(study_yml,   project_path("config/study_period.yml"), format = "file"),
  tar_target(vars_yml,    project_path("config/variables.yml"),    format = "file"),
  tar_target(sources_yml, project_path("config/data_sources.yml"), format = "file"),
  tar_target(cfg_study,   { study_yml;   load_config("study_period") }),
  tar_target(cfg_vars,    { vars_yml;    load_config("variables") }),
  tar_target(cfg_sources, { sources_yml; load_config("data_sources") }),

  # --- raw inputs (tracked as files) ------------------------------------------------
  tar_target(reservoir_csv,
             project_path("data/raw/reservoirs/reservoirs_levels_2005-2026.csv"),
             format = "file"),
  tar_target(reservoir_shp,
             project_path("data/raw/reservoirs/reservoirs_shapefile/Embalse_2026_05_31.shp"),
             format = "file"),
  tar_target(cuencas_shp,
             project_path("data/raw/watersheds/watersheds_DGA/Cuencas_BNA.shp"),
             format = "file"),
  tar_target(subcuencas_shp,
             project_path("data/raw/watersheds/subwatersheds_DGA/SubCuencas_BNA.shp"),
             format = "file"),

  # --- ingestion --------------------------------------------------------------------
  tar_target(levels_long, read_reservoir_levels(reservoir_csv)),
  tar_target(reservoir_ids, unique(levels_long$ID_DGA)),
  tar_target(points, read_reservoir_points(reservoir_shp, reservoir_ids)),

  # --- watershed units + reservoir-to-unit assignment (point-in-polygon) ------------
  # cuencas_shp / subcuencas_shp force rebuilds when the shapefiles change.
  tar_target(cuencas,    { cuencas_shp;    read_watersheds(cfg_sources, "cuencas") }),
  tar_target(subcuencas, { subcuencas_shp; read_watersheds(cfg_sources, "subcuencas") }),
  tar_target(reservoir_units,
             assign_reservoirs_both_levels(points, cuencas, subcuencas)),
  # Dissolved to one feature per unit_id — the geometry for zonal raster extraction.
  tar_target(cuencas_dissolved,    dissolve_watersheds(cuencas)),
  tar_target(subcuencas_dissolved, dissolve_watersheds(subcuencas)),

  # --- water rights (DGA registry): demand-side allocation panel per subcuenca --------------------
  # Direct measure of claimed consumptive water demand (l/s) for the induced-demand test (does damming
  # accrue more consumptive rights than in matched controls?), complementing the irrigated-area and ET
  # proxies. Read -> harmonize flow to l/s + parse grant year -> point-in-polygon assign to subcuencas
  # (UTM per Huso/Datum) -> cumulative-stock + annual-increment allocation panel by source and use.
  tar_target(water_rights_csv,
             project_path("data/raw/water_rights/water_rights_chile.csv"), format = "file"),
  tar_target(water_rights_raw,      read_water_rights(water_rights_csv)),
  tar_target(water_rights_assigned, assign_water_rights_to_units(water_rights_raw, subcuencas_dissolved)),
  tar_target(water_rights_panel,    build_water_rights_panel(water_rights_assigned)),

  # --- groundwater wells (DGA hydrographs): bound the groundwater-substitution confound -----------
  tar_target(gw_levels_rds,  project_path("data/raw/groundwater/data_GWL_corregida.rds"), format = "file"),
  tar_target(gw_coords_rds,  project_path("data/raw/groundwater/data_wells_coordenadas.rds"), format = "file"),
  tar_target(gw_levels,      read_gw_levels(gw_levels_rds)),
  tar_target(gw_wells,       assign_gw_wells(gw_coords_rds, subcuencas_dissolved)),

  # --- grain selection: climate covariate + cuenca-vs-subcuenca diagnostics ----------
  tar_target(koppen_path,
             project_path(cfg_sources$koppen_geiger$root,
                          cfg_sources$koppen_geiger$resolutions[["0p00833333"]]$file),
             format = "file"),
  tar_target(kg_legend, koppen_legend(cfg_sources)),
  tar_target(clim_cuencas,
             extract_unit_climate(cuencas_dissolved, koppen_path, kg_legend)),
  tar_target(clim_subcuencas,
             extract_unit_climate(subcuencas_dissolved, koppen_path, kg_legend)),
  tar_target(dem_path, cfg_sources$dem$path, format = "file"),
  tar_target(terrain_subcuencas,
             extract_unit_terrain(subcuencas_dissolved, dem_path)),
  # Long-term baseline aridity (annual P/PET, 1991-2020 WMO normal) as a quantitative
  # climate matching covariate. NOT format="file": the "chir[p|t]s" filenames contain | and
  # *, which targets bans in tracked file paths — depend on sources_yml for invalidation.
  tar_target(aridity_paths, { sources_yml; aridity_annual_paths(cfg_sources) }),
  tar_target(aridity_subcuencas,
             extract_unit_aridity(subcuencas_dissolved, aridity_paths)),
  tar_target(grain_choice,
             compare_grains(reservoir_units, cuencas_dissolved, subcuencas_dissolved,
                            clim_cuencas, clim_subcuencas)),

  # --- matched control set (subcuenca grain, ATT entropy balancing) ------------------
  tar_target(match_covariates,
             build_match_covariates(subcuencas_dissolved, grain_choice$flags$subcuenca,
                                    clim_subcuencas, terrain_subcuencas,
                                    aridity_subcuencas)),
  tar_target(matched_set, fit_matched_set(match_covariates)),
  tar_target(robustness_matches,
             fit_robustness_matches(match_covariates, matched_set)),

  # --- doubly-robust ATT: ebal weights + outcome-regression adjustment ----------------
  # Outcome = storage-era (2005-2024) trend in annual zNPP per subcuenca, an ecological-
  # expansion proxy standing in for the gated irrigated-area outcome (config variables:gated).
  # The outcome model carries log_aridity to absorb the residual aridity imbalance the
  # weights leave behind (see docs/design/matched-controls.md).
  tar_target(znpp_stack, { sources_yml; ecological_annual_paths(cfg_sources, "zNPP") }),
  tar_target(outcome_subcuencas,
             extract_unit_index_trend(subcuencas_dissolved, znpp_stack)),
  tar_target(dr_att, fit_doubly_robust(matched_set, outcome_subcuencas,
                                       outcome_col = "trend")),

  # --- forcing-conditioned ATT: the deficit->impact RESPONSE SLOPE as the outcome -----
  # Breaks the mega-drought-exposure confound the raw zNPP TREND carries (identification
  # strategy Lever 1): per subcuenca regress annual zNPP on annual SPEI-12 forcing, take the
  # transmission slope, and run the SAME doubly-robust matched-set estimator on it. Both
  # series are standardized anomalies -> the slope is a cross-basin drought-transmission
  # elasticity, not a calendar-time trend. Reported alongside dr_att.
  tar_target(spei_stack, { sources_yml;
             forcing_monthly_paths(cfg_sources, index = "SPEI", timescale = 12L) }),
  tar_target(forcing_subcuencas,
             extract_unit_forcing_annual(subcuencas_dissolved, spei_stack)),
  tar_target(znpp_annual,
             extract_unit_index_annual(subcuencas_dissolved, znpp_stack)),
  tar_target(response_panel, build_response_panel(znpp_annual, forcing_subcuencas)),
  tar_target(response_slopes, fit_response_slopes(response_panel)),
  tar_target(dr_att_forcing,
             fit_forcing_conditioned_att(matched_set, response_slopes)),

  # --- forcing-conditioned ATT robustness battery -------------------------------------
  # Nonlinear aridity, SPEI timescale (6/12/24), forcing lag, CEM/NN subsets, slope-fit
  # thresholds — all on the same dr_estimate() core. SPEI-6/24 forcing needs its own zonal
  # extraction; SPEI-12 is reused from forcing_subcuencas above.
  tar_target(spei_stack_6,  { sources_yml;
             forcing_monthly_paths(cfg_sources, index = "SPEI", timescale = 6L) }),
  tar_target(spei_stack_24, { sources_yml;
             forcing_monthly_paths(cfg_sources, index = "SPEI", timescale = 24L) }),
  tar_target(forcing_subcuencas_6,
             extract_unit_forcing_annual(subcuencas_dissolved, spei_stack_6)),
  tar_target(forcing_subcuencas_24,
             extract_unit_forcing_annual(subcuencas_dissolved, spei_stack_24)),
  tar_target(dr_att_forcing_robustness,
             run_forcing_robustness(
               matched_set, robustness_matches, znpp_annual,
               forcing_by_ts = list(`6`  = forcing_subcuencas_6,
                                    `12` = forcing_subcuencas,
                                    `24` = forcing_subcuencas_24))),

  # --- land-cover-disaggregated transmission slope: the decisive aridity-vs-mechanism test --
  # Split per-subcuenca annual zNPP into AGRICULTURAL (MapBiomas class 18) vs NATURAL cover
  # using a static 2007 baseline mask, then run the forcing-conditioned ATT within each
  # stratum. Heavy (per-polygon 30 m crops) -> restricted to the matched-set units only.
  tar_target(mb_baseline_paths, { sources_yml; mapbiomas_paths(cfg_sources, 2007L) }),
  tar_target(matched_subcuencas,
             subcuencas_dissolved[subcuencas_dissolved$unit_id %in% matched_set$data$unit_id, ]),
  # Sharp (mechanism-pure) stratum: irrigated Agriculture (class 18) only, single-year mask.
  tar_target(znpp_strat,
             stratified_znpp_annual(matched_subcuencas, znpp_stack, mb_baseline_paths)),
  tar_target(dr_att_forcing_strat,
             fit_stratified_forcing_att(matched_set, znpp_strat, forcing_subcuencas)),
  # Power upgrade: broaden the managed-cover stratum to FARMING {9 silviculture, 15 pasture,
  # 18 agriculture} on a 3-year baseline mask. Class-18-only left only 34 controls (no power);
  # farming triples the control pool (~110+). Trades mechanism-sharpness (now "managed cover",
  # not irrigated-only) for the power needed to credibly test the H2 agricultural-slope null.
  tar_target(mb_baseline_multi, { sources_yml;
             mapbiomas_paths(cfg_sources, c(2005L, 2007L, 2009L)) }),
  tar_target(znpp_strat_farming,
             stratified_znpp_annual(matched_subcuencas, znpp_stack, mb_baseline_multi,
                                    agri = c(9L, 15L, 18L))),
  tar_target(dr_att_forcing_strat_farming,
             fit_stratified_forcing_att(matched_set, znpp_strat_farming, forcing_subcuencas)),
  # Irrigation-specific powered test: Agriculture (18) ONLY but at a low fraction threshold
  # (0.1) on the 3-year baseline, to power the mechanism-pure stratum (~65 controls) that the
  # farming broadening dilutes with rain-fed silviculture/pasture. Cells are more mixed at
  # thr=0.1 — read as "any non-trivial irrigated cropland", complementing the sharp thr=0.5.
  tar_target(znpp_strat_irrig,
             stratified_znpp_annual(matched_subcuencas, znpp_stack, mb_baseline_multi,
                                    agri = c(18L), frac_thr = 0.1)),
  tar_target(dr_att_forcing_strat_irrig,
             fit_stratified_forcing_att(matched_set, znpp_strat_irrig, forcing_subcuencas)),

  # --- DEFINITIVE irrigated stratum: Catastro Frutícola orchard footprint (ground truth) ----
  # Replaces the MapBiomas class-18 proxy with actual irrigated-orchard polygons. Each region's
  # latest survey year, dissolved to a national footprint, rasterized to the zNPP grid as a
  # cover fraction, thresholded (>=0.05) into the irrigated stratum; contrasted with natural.
  tar_target(orchard_root, cfg_sources$catastro_fruticola$root),
  tar_target(orchards_latest, { sources_yml; read_orchards_latest(orchard_root) }),
  tar_target(orchards_dissolved, sf::st_transform(dissolve_orchards(orchards_latest), 4326)),
  # SpatRaster can't serialize through targets -> persist the cover-fraction raster as a file.
  tar_target(orchard_frac_file, {
               r <- orchard_fraction_raster(orchards_dissolved, znpp_stack)
               p <- project_path("data/processed/orchards/orchard_frac.tif")
               terra::writeRaster(r, p, overwrite = TRUE); p
             }, format = "file"),
  tar_target(znpp_orchard,
             extract_unit_orchard_znpp(matched_subcuencas, znpp_stack,
                                       terra::rast(orchard_frac_file))),
  tar_target(znpp_orchard_natural, combine_orchard_natural(znpp_orchard, znpp_strat)),
  tar_target(dr_att_forcing_orchard,
             fit_stratified_forcing_att(matched_set, znpp_orchard_natural, forcing_subcuencas)),

  # --- H2 induced-demand: orchard-area EXPANSION mediator (Catastro plant_year) --------------
  # Reconstruct cumulative irrigated-orchard area present by each year per subcuenca, then the
  # dammed-vs-control expansion ATT. Tests the FIRST limb of H2 (reservoirs -> agricultural
  # expansion), distinct from the ecological-slope tests (the vulnerability limb).
  tar_target(orchards_assigned, assign_orchards_to_units(orchards_latest, matched_subcuencas)),
  tar_target(orchard_panel,
             orchard_area_panel(orchards_assigned, matched_set$data$unit_id)),
  tar_target(orchard_expansion,
             orchard_expansion_summary(orchard_panel, matched_set$data)),
  tar_target(att_orchard_expansion,
             fit_orchard_expansion_att(matched_set, orchard_expansion)),

  # --- causal scrutiny of the expansion ATT: left-censoring + siting pre-trends -------------
  # Most dams predate the orchard record (left-censored), so the expansion ATT cannot be cleanly
  # causally identified; this tests whether the dammed-vs-control gap predates 2005 (siting) or
  # opens up after (reservoir/drought era). orchard_panel_long extends the panel back to 1990.
  tar_target(commission_years, reservoir_commission_years(reservoir_units, points)),
  tar_target(orchard_panel_long,
             orchard_area_panel(orchards_assigned, matched_set$data$unit_id, years = 1990:2024)),
  tar_target(expansion_pretrends,
             orchard_expansion_pretrends(orchard_panel_long, matched_set)),

  # --- discriminating diagnostics (hypothesis-challenger, 2026-06-26) ------------------------
  # Test A: orchard-ET (SETI~SPEI) transmission slope — does irrigation buffer ET where it did
  # not visibly buffer NPP? GRAIN-LIMITED (SETI ~5.5 km; orchard cells mostly matrix).
  tar_target(seti_stack, { sources_yml; seti_monthly_paths(cfg_sources, "SETI", 12L) }),
  tar_target(orchard_frac_seti_file, {
               tmpl <- terra::rast(seti_stack$paths[1])
               r <- terra::rasterize(terra::vect(orchards_dissolved), tmpl, cover = TRUE)
               p <- project_path("data/processed/orchards/orchard_frac_seti.tif")
               terra::writeRaster(r, p, overwrite = TRUE); p
             }, format = "file"),
  tar_target(att_orchard_et,
             fit_orchard_et_att(matched_subcuencas, seti_stack,
                                terra::rast(orchard_frac_seti_file),
                                forcing_subcuencas, matched_set)),
  # Test B: pre-megadrought PLACEBO on the natural-cover slope (zNPP/SPEI extended to 2000-2024).
  tar_target(znpp_stack_full, { sources_yml;
             ecological_annual_paths(cfg_sources, "zNPP", years = 2000:2024) }),
  tar_target(znpp_strat_full,
             stratified_znpp_annual(matched_subcuencas, znpp_stack_full, mb_baseline_paths)),
  tar_target(forcing_subcuencas_full, { sources_yml;
             extract_unit_forcing_annual(matched_subcuencas,
               forcing_monthly_paths(cfg_sources, "SPEI", 12L, years = 2000:2024)) }),
  tar_target(placebo_period_att,
             fit_period_transmission_att(znpp_strat_full, forcing_subcuencas_full, matched_set)),

  # Test A2 (the feasible ET-buffering test): MOD16 500 m ET on orchard-majority cells. Native
  # MODIS ET is fine enough (orchard cells reach ~90% cover at 500 m) where the 5.5 km SETI was
  # not. Outcome = slope of log(annual ET) on SPEI; H1 buffering -> flatter slope in dammed basins.
  tar_target(et_stack, { sources_yml; mod16_8day_paths(cfg_sources, years = 2001:2024) }),
  # The 8-day source is on a slow USB-NTFS drive where terra's windowed reads seek at ~2 MB/s
  # (a single year took ~30 min in place). Mirror the 1104 files to local NVMe ONCE (sequential
  # copy, ~15-40x faster), then aggregate from the local copy. Idempotent: skips files already
  # mirrored, so this is a one-time cost. (~105 GB local in data/interim/et_8day/.)
  tar_target(et_local_dir, project_path("data/interim/et_8day")),
  tar_target(et_stack_local, mirror_et_local(et_stack, et_local_dir)),
  # Cache the 1104-layer stack as a 24-band annual-ET (mm/yr) raster (year-by-year). Every
  # per-unit/per-stratum extraction below then reads only 24 bands (fast, re-runnable).
  tar_target(et_annual_file,
             aggregate_et_annual(et_stack_local, project_path("data/interim/et/et_annual_mm.tif"),
                                 units = matched_subcuencas),
             format = "file"),
  tar_target(orchard_frac_et_file, {
               tmpl <- terra::rast(et_stack$paths[1])
               r <- terra::rasterize(terra::vect(orchards_dissolved), tmpl, cover = TRUE)
               p <- project_path("data/processed/orchards/orchard_frac_et.tif")
               terra::writeRaster(r, p, overwrite = TRUE); p
             }, format = "file"),
  tar_target(et_orchard_annual,
             extract_unit_et_annual(matched_subcuencas, terra::rast(et_annual_file),
                                    terra::rast(orchard_frac_et_file))),
  tar_target(att_et_buffering,
             fit_et_buffering_att(et_orchard_annual, forcing_subcuencas_full, matched_set)),

  # === H2 OUTCOME ACQUISITION: annual ET (mm/yr) + observed irrigated-area panels ============
  # The forcing-conditioned + cover-disaggregated zNPP tests exhausted the ecological PROXY
  # (clean H2 null on the deficit->impact slope) but cannot test the area/ET MEDIATOR directly.
  # These targets build the two missing time-varying outcomes (2026-06-27):
  #   (1) per-unit annual ET LEVEL (mm/yr) — consumptive water use, whole-basin and orchard cells;
  #   (2) OBSERVED annual agricultural area (MapBiomas) — the no-survival-bias counterpart to the
  #       Catastro orchard reconstruction. Closes config/variables.yml:gated irrigated_area_landcover.

  # (1a) whole-basin annual ET level (mm/yr), all matched units. min_cells=20 drops hyper-arid
  # northern basins where MOD16 is nearly all fill over barren/salar (1-8 valid cells, spurious
  # ~1700-2967 mm/yr); real vegetated basins have hundreds-thousands of cells (10th pctile 193).
  tar_target(et_unit_annual,
             extract_unit_et_total_annual(matched_subcuencas, terra::rast(et_annual_file),
                                          min_cells = 20L)),
  # (1b) orchard-stratum annual ET level (mm/yr) — ET on irrigated cells, the H2 consumptive signal.
  tar_target(et_orchard_level,
             extract_unit_et_total_annual(matched_subcuencas, terra::rast(et_annual_file),
                                          terra::rast(orchard_frac_et_file))),

  # (2) OBSERVED agricultural-area panel from MapBiomas (30 m), 1999-2024, matched units.
  #     irrig = Agriculture (class 18, the irrigated-cropland proxy); farm = farming {9,15,18}.
  tar_target(mb_area_years, 1999:2024),
  # Mirror the 26 MapBiomas files to local NVMe (slow USB source); idempotent, ~3.6 GB.
  tar_target(mb_area_paths,
             { sources_yml
               mirror_paths_local(mapbiomas_paths(cfg_sources, mb_area_years),
                                  project_path("data/interim/mapbiomas_local")) },
             format = "file"),
  tar_target(irrig_area_panel,
             extract_unit_area_panel(matched_subcuencas, mb_area_paths, mb_area_years,
                                     classes = 18L)),
  tar_target(farm_area_panel,
             extract_unit_area_panel(matched_subcuencas, mb_area_paths, mb_area_years,
                                     classes = c(9L, 15L, 18L))),
  # observed-area expansion ATT (compare to att_orchard_expansion from the Catastro reconstruction)
  tar_target(irrig_area_expansion, area_expansion_summary(irrig_area_panel, matched_set$data)),
  tar_target(att_irrig_area_expansion,
             fit_area_expansion_att(matched_set, irrig_area_expansion)),

  # === FORCING-INTERACTED DiD / EVENT-STUDY (reservoir-causal-analyst design 2026-06) ===========
  # Treatment is near-time-invariant (dams predate the panel) and calendar time is megadrought-
  # confounded, so the dose is SPEI, not the year: feols(y ~ treat:spei_c + spei_c | unit + year).
  # year FE remove the common drought shock; treat:spei_c is the differential deficit->impact SLOPE.
  # Forcing = meteorological SPEI-12 (forcing_subcuencas_full, 2000-2024), NOT a streamflow/storage
  # series. Outcomes: area_frac (no survival bias), log whole-basin ET, log orchard ET (cleanest H2).
  tar_target(did_panel_area,
             build_did_panel(irrig_area_panel, forcing_subcuencas_full, matched_set,
                             "area_frac", log_outcome = FALSE)),
  tar_target(did_panel_et,
             build_did_panel(et_unit_annual, forcing_subcuencas_full, matched_set,
                             "et_mm", log_outcome = TRUE)),
  tar_target(did_panel_orch,
             build_did_panel(et_orchard_level, forcing_subcuencas_full, matched_set,
                             "et_mm", log_outcome = TRUE)),

  # PRIMARY slope-gap models + dynamic event-study (parallel-trends/divergence diagnostic, ref 2009)
  tar_target(did_area, fit_forcing_did(did_panel_area)),
  tar_target(did_et,   fit_forcing_did(did_panel_et)),
  tar_target(did_orch, fit_forcing_did(did_panel_orch)),
  tar_target(es_area,  fit_event_study(did_panel_area)),
  tar_target(es_et,    fit_event_study(did_panel_et)),
  tar_target(es_orch,  fit_event_study(did_panel_orch)),

  # MECHANISM triple-difference (does the slope gap widen with irrigation intensity?)
  tar_target(irr_share, irrig_area_panel[, .(irr_share = mean(area_frac)), by = unit_id]),
  tar_target(did_triple_orch, fit_triple_diff(did_panel_orch, irr_share)),

  # PLACEBO: high-aridity-tercile pseudo-treatment among CONTROLS (must be ~0)
  tar_target(did_placebo_area, fit_aridity_placebo(did_panel_area)),
  tar_target(did_placebo_orch, fit_aridity_placebo(did_panel_orch)),

  # randomization inference on treat:spei_c (permute treatment within kg_group x aridity-tercile
  # strata; ~24 treated CLUSTERS, not unit-years — fwildclusterboot is off CRAN so this is the
  # design-based small-cluster inference)
  tar_target(perm_area, permutation_test_slope(did_panel_area, did_area)),
  tar_target(perm_et,   permutation_test_slope(did_panel_et,   did_et)),
  tar_target(perm_orch, permutation_test_slope(did_panel_orch, did_orch)),
  tar_target(did_summary, data.table::rbindlist(list(
               did_slope_summary(did_area, "area_frac",      perm_area),
               did_slope_summary(did_et,   "log_basin_ET",   perm_et),
               did_slope_summary(did_orch, "log_orchard_ET", perm_orch)))),

  # === H1 STORAGE-RECTIFIER (drought-propagation-analyst design) ===============================
  # Monthly zcNDVI-6 severity vs monthly SPEI-12/-3 forcing. C3 (control-anchored): heavier upper-tail
  # ecological-drought severity in dammed vs matched-control basins, conditional on forcing. C1/C2
  # (within-treated): a storage threshold s* with lower-tail variance inflation below it.
  tar_target(zc6_stack,    { sources_yml; zcndvi_monthly_paths(cfg_sources, 6L, 2000:2024) }),
  tar_target(zc6_monthly,  extract_unit_index_monthly(matched_subcuencas, zc6_stack)),
  tar_target(spei12_stack, { sources_yml; forcing_monthly_paths(cfg_sources, "SPEI", 12L, 2000:2024) }),
  tar_target(spei12_monthly, extract_unit_index_monthly(matched_subcuencas, spei12_stack)),
  tar_target(spei3_stack,  { sources_yml; forcing_monthly_paths(cfg_sources, "SPEI", 3L, 2000:2024) }),
  tar_target(spei3_monthly, extract_unit_index_monthly(matched_subcuencas, spei3_stack)),
  tar_target(severity_panel,
             build_severity_panel(zc6_monthly, spei12_monthly, spei3_monthly, matched_set)),
  tar_target(treated_storage_panel,
             build_treated_storage_panel(zc6_monthly, spei12_monthly, spei3_monthly,
                                         storage_pct, reservoir_units, matched_set)),
  # C3: dammed-vs-control upper-tail severity (quantile regression + GPD; permutation inference)
  tar_target(h1_quantreg,      fit_tail_quantreg(severity_panel)),
  tar_target(h1_tail_contrast, tail_contrast(h1_quantreg)),
  tar_target(h1_perm,
             permute_tail_stat(severity_panel, tail_contrast_fast, n_perm = 1000L)),
  tar_target(h1_gpd,           fit_gpd_tail(severity_panel)),
  # C1/C2: within-treated storage threshold + variance break + counterfactual-overshoot falsifier
  tar_target(h1_tar,           fit_storage_tar(treated_storage_panel)),
  tar_target(h1_overshoot,     overshoot_test(severity_panel, h1_tar)),

  # === H1 BUFFERING ON STREAMFLOW (the vegetation-independent availability outcome) ============
  # CR2 daily flow -> SSI-12; does meteorological drought propagate LESS to streamflow drought in
  # dammed vs control? treat:spei_c NEGATIVE = buffering. ITT (all dammed gauges) is the conservative
  # primary; downstream-only (gauge below dam) the refinement; UPSTREAM-only the decisive placebo
  # (above-dam gauges cannot be regulated -> any "buffering" there is siting/aridity, not the dam).
  tar_target(streamflow_stations_raw, { sources_yml; read_cr2_stations(cfg_sources) }),
  tar_target(dam_elev, extract_dam_elevation(points, reservoir_units, cfg_sources)),
  tar_target(streamflow_stations,
             assign_stations_to_units(streamflow_stations_raw, matched_subcuencas, matched_set, dam_elev)),
  tar_target(streamflow_monthly, { sources_yml; read_cr2_monthly_flow(cfg_sources, streamflow_stations$codigo) }),
  tar_target(ssi12, compute_ssi(streamflow_monthly)),
  tar_target(ssi_panel_itt,  build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, matched_set, "itt")),
  tar_target(ssi_panel_down, build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, matched_set, "down")),
  tar_target(ssi_panel_up,   build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, matched_set, "up")),
  tar_target(ssi_buffer_itt,  fit_ssi_buffering(ssi_panel_itt)),
  tar_target(ssi_buffer_down, fit_ssi_buffering(ssi_panel_down)),
  tar_target(ssi_buffer_up,   fit_ssi_buffering(ssi_panel_up)),
  tar_target(ssi_perm_itt,  permute_ssi_buffer(ssi_panel_itt)),
  tar_target(ssi_perm_down, permute_ssi_buffer(ssi_panel_down)),
  tar_target(ssi_perm_up,   permute_ssi_buffer(ssi_panel_up)),
  tar_target(streamflow_summary,
             ssi_buffer_summary(ssi_buffer_itt, ssi_buffer_down, ssi_buffer_up,
                                ssi_perm_itt, ssi_perm_down, ssi_perm_up)),

  # --- placebo validation (Nature Water review #5, #6) -----------------------------------------
  # #5 COMPARABILITY: upstream gauges sit higher than downstream, so quantify the gap and test
  # whether gauge elevation drives the SPEI->SSI transmission slope among undammed controls (if not,
  # the up/down elevation difference cannot manufacture a spurious slope gap -> placebo defended).
  tar_target(ssi_placebo_check,
             ssi_placebo_comparability(streamflow_stations, ssi12, ssi_panel_itt)),
  tar_target(table_placebo_check_file, write_table(ssi_placebo_check, "table_placebo_check"),
             format = "file"),
  # Catchment-area confound in the up/down placebo (reviewer 2026-08-05, 2nd round): mirror the
  # elevation test with unit area as the drainage-area proxy, so the up/down catchment-size gap
  # cannot manufacture the placebo attenuation.
  tar_target(catchment_area_check,
             catchment_area_sensitivity(streamflow_stations, ssi12, ssi_panel_itt,
                                        matched_set$data)),
  tar_target(table_catchment_area_file,
             write_table(catchment_area_check, "table_catchment_area"),
             format = "file"),
  # Snowmelt-confound bound for the up/down placebo (reviewer 2026-07-02, reworked after the
  # internal NW review): test on the DIFFERENTIAL estimand (treat:spei_c of the up/down panels) —
  # snow-adjusted refit, low-snow subsample, early/late stationarity, snow-year modulation — plus
  # standardized gauge-level sensitivity rows.
  tar_target(swe_nc, cfg_sources$snow$file, format = "file"),
  tar_target(swe_clim, aggregate_swe_climatology(swe_nc, project_path("data/interim/snow/swe_chile_clim.tif"),
                                                 cfg_sources$snow$window),
             format = "file"),
  tar_target(snow_placebo_check,
             build_snow_placebo_check(swe_clim, streamflow_stations, ssi12,
                                      ssi_panel_up, ssi_panel_down, cfg_sources)),
  tar_target(table_snow_placebo_file, write_table(snow_placebo_check, "table_snow_placebo"),
             format = "file"),
  # Elevation-adjusted placebo test (reviewer 2026-08-05, 3rd round): the raw up/down contrast
  # could be confounded by the gauge elevation gradient, so re-estimate treat:SPEI net of a
  # SPEI x elevation interaction, for ITT/down/up plus the D_adj contrast, with permutation.
  tar_target(elev_adjusted_placebo,
             elevation_adjusted_placebo(streamflow_stations, ssi_panel_itt,
                                        ssi_panel_down, ssi_panel_up)),
  tar_target(table_elev_adjusted_placebo_file,
             write_table(elev_adjusted_placebo, "table_elev_adjusted_placebo"),
             format = "file"),
  # Gauge-misclassification robustness (reviewer 2026-08-05, 4th round): re-run the placebo
  # contrast after (a) dropping the 3 downstream gauges that sit in a sub-cuenca named for a
  # different river or tributary than the dam (Duqueco tributary under Biobío dams; Itata river
  # under the Laja dam), and (b) dropping the downstream gauges within 100 m of the dam elevation
  # (the ones most plausibly on a parallel tributary).
  tar_target(gauge_class_robust,
             gauge_classification_robustness(streamflow_stations, ssi12, spei12_monthly,
                                             matched_set, dam_elev,
                                             cross_river_codes = c(8323001, 8122001),
                                             margin_m = 100L)),
  tar_target(table_gauge_class_robust_file,
             write_table(gauge_class_robust, "table_gauge_classification_robustness"),
             format = "file"),
  # Cumulative-catchment-scale confound (reviewer 2026-08-05, 5th round): local polygon area does
  # not capture the cumulative drainage feeding a downstream gauge. Add per-gauge log mean
  # discharge (proportional to cumulative area) as a SPEI-interacted covariate, re-fit buffering
  # + D contrast under permutation, and report the control-gauge scale sensitivity and the
  # up/down discharge ratio among paired basins.
  tar_target(cumulative_scale_check,
             cumulative_scale_sensitivity(streamflow_stations, streamflow_monthly, ssi12,
                                          ssi_panel_itt, ssi_panel_down, ssi_panel_up)),
  tar_target(table_cumulative_scale_file,
             write_table(cumulative_scale_check, "table_cumulative_scale"),
             format = "file"),
  # Paired-placebo power analysis (reviewer 2026-08-05, 5th round): MDE of the down-minus-up
  # contrast at 80% power from the permutation-null SD, so the Type-II-error risk is quantified.
  tar_target(paired_placebo_power, paired_placebo_power(ssi_panel_down, ssi_panel_up)),
  tar_target(table_paired_power_file, write_table(paired_placebo_power, "table_paired_placebo_power"),
             format = "file"),
  # Early/late megadrought phase split (reviewer round 7, comment 1): does the placebo hold at
  # drought onset (2010-2014), before storage depletion could wash out early buffering? Per-phase
  # treat:spei_c for the three subsets plus the treat:spei_c:late shift on the pooled panel.
  tar_target(phase_split_check,
             build_phase_split_check(ssi_panel_itt, ssi_panel_down, ssi_panel_up)),
  tar_target(table_phase_split_file, write_table(phase_split_check, "table_phase_split"),
             format = "file"),
  # Direct within-basin placebo contrast test (reviewer 2026-08-05, MC1): the central falsifier,
  # downstream-minus-upstream differential slope with its own permutation p, paired within basins.
  tar_target(placebo_contrast,
             placebo_contrast_test(ssi_panel_down, ssi_panel_up)),
  tar_target(placebo_contrast_table, placebo_contrast_row(placebo_contrast)),
  tar_target(table_placebo_contrast_file, write_table(placebo_contrast_table, "table_placebo_contrast"),
             format = "file"),
  # Permutation inference for the phase-shift analysis (reviewer 2026-08-05, MC3): valid small-
  # cluster inference for the treat:spei_c:late shifts and the downstream-minus-upstream contrast.
  tar_target(phase_shift_perm,
             build_phase_shift_permutation(ssi_panel_itt, ssi_panel_down, ssi_panel_up)),
  tar_target(table_phase_shift_perm_file,
             write_table(phase_shift_perm, "table_phase_shift_permutation"),
             format = "file"),
  # Permutation inference for siting-ladder rung 4 (reviewer 2026-08-05, MN2): the "design +
  # within region" estimate reported without a permutation p in the ladder table.
  tar_target(siting_rung4_perm, permute_siting_rung4(ssi_panel_itt)),
  tar_target(siting_rung4_perm_row,
             data.table::data.table(
               quantity = "siting-ladder rung 4 (design + within region), permutation p",
               estimate = siting_rung4_perm$observed,
               detail = sprintf("est %+.3f, permutation p = %.3f (%d perms), null SD %.3f",
                                siting_rung4_perm$observed, siting_rung4_perm$p_perm,
                                siting_rung4_perm$n_perm, siting_rung4_perm$null_sd))),
  tar_target(table_siting_rung4_file, write_table(siting_rung4_perm_row, "table_siting_rung4_perm"),
             format = "file"),
  # Reviewer 2026-08-05, comment 2: non-linear / dry-tail transmission. Quadratic SPEI interaction
  # (full panel) plus dry-tail re-estimates at SPEI < -1.0 and < -1.5, each with permutation.
  tar_target(nonlinear_transmission, nonlinear_transmission_test(ssi_panel_itt)),
  tar_target(nonlinear_transmission_row,
             data.table::data.table(
               quantity = "non-linear transmission test (treat x SPEI^2), permutation p",
               estimate = nonlinear_transmission$observed,
               detail = sprintf("est %+.3f, permutation p = %.3f (%d perms), null SD %.3f; a dry-tail-only buffering effect would appear as a nonzero interaction",
                                nonlinear_transmission$observed, nonlinear_transmission$p_perm,
                                nonlinear_transmission$n_perm, nonlinear_transmission$null_sd))),
  tar_target(dry_tail_10, dry_tail_transmission(ssi_panel_itt, ssi_panel_down, ssi_panel_up, thr = -1.0)),
  tar_target(dry_tail_15, dry_tail_transmission(ssi_panel_itt, ssi_panel_down, ssi_panel_up, thr = -1.5)),
  tar_target(dry_tail_table, rbind(dry_tail_10, dry_tail_15)),
  tar_target(table_dry_tail_file, write_table(dry_tail_table, "table_dry_tail"),
             format = "file"),
  tar_target(table_nonlinear_file, write_table(nonlinear_transmission_row, "table_nonlinear_transmission"),
             format = "file"),
  # #6 POSITIVE CONTROL: inject a known buffering slope into treated downstream units, confirm the
  # estimator recovers it and that randomization inference rejects once the effect exceeds the MDE.
  tar_target(ssi_positive_ctrl, ssi_positive_control(ssi_panel_down)),
  tar_target(table_positive_ctrl_file, write_table(ssi_positive_ctrl, "table_positive_control"),
             format = "file"),

  # Equivalence / MDE bounds on the interpretable nulls — makes the formerly orphan
  # table_equivalence.csv a reproducible target. Whole-basin ET omitted (pre-trends fail).
  tar_target(equivalence_table,
             build_equivalence_table(ssi_panel_itt, ssi_panel_down, did_panel_area, did_panel_orch)),
  tar_target(table_equivalence_file, write_table(equivalence_table, "table_equivalence"),
             format = "file"),

  # === WATER-RIGHTS INDUCED-DEMAND TEST (DGA registry; the direct demand outcome) ================
  # Does damming accrue more consumptive water rights than in matched controls? Rights-density (count
  # per 100 km2) expansion ATT + event study, judged by randomization inference, with a within-region
  # check. Naive analysis looks positive; it collapses under design-based inference (siting confound).
  tar_target(wr_expansion,      wr_expansion_summary(water_rights_panel, matched_set$data)),
  tar_target(wr_att,            fit_wr_expansion_att(matched_set, wr_expansion)),
  tar_target(wr_demand_summary, build_wr_demand_summary(matched_set, wr_expansion)),
  tar_target(wr_perm,          data.table::as.data.table(wr_demand_summary)[outcome %like% "Rights count", perm_p]),
  tar_target(wr_did_panel,
             build_did_panel(wr_intensity_panel(water_rights_panel, matched_set$data),
                             forcing_subcuencas_full, matched_set, "n_km2")),
  tar_target(es_wr,             fit_event_study(wr_did_panel)),
  # Aridity-overlap sensitivity (reviewer): key results re-estimated on the aridity common-support subset
  tar_target(aridity_overlap_tab, aridity_overlap_sensitivity(matched_set, ssi_panel_itt, wr_expansion)),
  tar_target(table_aridity_overlap_file, write_table(aridity_overlap_tab, "table_aridity_overlap"),
             format = "file"),
  # Reviewer-3 robustness (2026-07-01): S7 fully non-parametric matching on the aridity-overlap
  # subset for every outcome; S8 winsorization-threshold sensitivity of the water-rights volume null;
  # S9 spatial-autocorrelation (Moran's I) + spatially-restricted (cuenca-block) inference. These
  # only depend on already-built matched-set / outcome objects, so they add no raster work.
  tar_target(nonparam_overlap_tab,
             build_nonparam_overlap(matched_set, irrig_area_expansion, wr_expansion,
                                    att_et_buffering)),
  tar_target(table_nonparam_overlap_file,
             write_table(nonparam_overlap_tab, "table_nonparam_overlap"), format = "file"),
  tar_target(winsor_sensitivity_tab,
             build_winsor_sensitivity(matched_set, water_rights_assigned)),
  tar_target(table_winsor_sensitivity_file,
             write_table(winsor_sensitivity_tab, "table_winsor_sensitivity"), format = "file"),
  tar_target(spatial_diagnostics,
             build_spatial_diagnostics(matched_set, irrig_area_expansion, wr_expansion,
                                       att_et_buffering, nonparam_overlap_tab)),
  tar_target(table_spatial_moran_file,
             write_table(spatial_diagnostics$moran, "table_spatial_moran"), format = "file"),
  tar_target(table_spatial_inference_file,
             write_table(spatial_diagnostics$inference, "table_spatial_inference"), format = "file"),
  # Groundwater-substitution bound (reviewer 2026-07-02): differential well-drawdown ATT between
  # dammed and matched-control basins, outlier-robust median (primary) + mean, with RI and Moran's I.
  tar_target(gw_substitution_summary,
             build_gw_substitution_summary(matched_set, gw_levels, gw_wells)),
  tar_target(table_gw_substitution_file,
             write_table(gw_substitution_summary, "table_gw_substitution"), format = "file"),
  # Reservoir-use heterogeneity (reviewer 2026-07-02): headline streamflow slope gap on all treated
  # vs the irrigation-only subset (hydropower/potable basins dropped), + use composition.
  tar_target(use_heterogeneity,
             build_use_heterogeneity(matched_set, points, reservoir_units,
                                     ssi_panel_itt, ssi_panel_up)),
  tar_target(table_use_heterogeneity_file,
             write_table(use_heterogeneity$summary, "table_use_heterogeneity"), format = "file"),
  # Inter-basin-transfer (SUTVA) + administrative-demand checks (reviewer 2026-07-02, comments 2 & 9),
  # extended per the internal NW review: cuenca disjointness, aggregate registry openness, PLUS the
  # differential pre-drought stock density and megadrought accrual (treated vs control closure test).
  tar_target(spillover_demand_checks,
             build_spillover_demand_checks(matched_set, subcuencas, water_rights_panel)),
  tar_target(table_spillover_demand_file,
             write_table(spillover_demand_checks, "table_spillover_demand"), format = "file"),
  # Pre-drought aridity-window sensitivity (reviewer 2026-07-02, comment 6): the 1991-2020 matching
  # baseline overlaps 11 megadrought years -> recompute on 1991-2009 / 2010-2020 and show design
  # invariance + no treated-vs-control differential P/PET change during the drought.
  tar_target(aridity_paths_pre,  { sources_yml; aridity_annual_paths(cfg_sources, years = 1991:2009) }),
  tar_target(aridity_paths_post, { sources_yml; aridity_annual_paths(cfg_sources, years = 2010:2020) }),
  tar_target(aridity_window_tab,
             aridity_window_sensitivity(matched_set, subcuencas_dissolved,
                                        aridity_paths_pre, aridity_paths_post)),
  tar_target(table_aridity_window_file,
             write_table(aridity_window_tab, "table_aridity_window"), format = "file"),
  # Pre-trend MDE (reviewer 2026-07-02, comment 5): hold the flat pre-2010 cropland trend to the
  # same equivalence/MDE standard as the headline nulls.
  tar_target(pretrend_mde_tab, build_pretrend_mde(did_panel_area)),
  tar_target(table_pretrend_mde_file,
             write_table(pretrend_mde_tab, "table_pretrend_mde"), format = "file"),
  # Physical-volume translation of the +-25% equivalence margin (reviewer round 2, comment 4).
  tar_target(margin_volume_tab,
             equivalence_volume_context(streamflow_monthly, streamflow_stations, ssi12)),
  tar_target(table_margin_volume_file,
             write_table(margin_volume_tab, "table_margin_volume"), format = "file"),
  # Hard-balanced (aridity-targeted) sensitivity, ESS ~19 (reviewer round 3, comment 1).
  tar_target(matched_set_hard, fit_matched_set_hard(match_covariates)),
  tar_target(hard_balance_check,
             build_hard_balance_check(matched_set_hard, ssi12, streamflow_stations,
                                      spei12_monthly, irrig_area_panel,
                                      forcing_subcuencas_full, water_rights_panel)),
  tar_target(table_hard_balance_file,
             write_table(hard_balance_check, "table_hard_balance"), format = "file"),
  # Pre/post-2010 storage level shift (reviewer round 3, comment 3).
  tar_target(storage_period_tab, storage_period_comparison(storage_band)),
  tar_target(table_storage_period_file,
             write_table(storage_period_tab, "table_storage_period"), format = "file"),
  # Step-change vs continuous drift in the storage band (reviewer 2026-08-05, 6th round): within-
  # megadrought (2010-2024) trend plus a nested 2010-step + post-step-drift model, so the level
  # shift and any residual drift are separated.
  tar_target(storage_step_trend_tab, storage_step_vs_trend(storage_band)),
  tar_target(table_storage_step_trend_file,
             write_table(storage_step_trend_tab, "table_storage_step_vs_trend"), format = "file"),
  # Physical validation of the winsorization cap (reviewer round 3, comment 5).
  tar_target(winsor_physical_tab,
             winsor_physical_check(water_rights_assigned, streamflow_monthly, streamflow_stations)),
  tar_target(table_winsor_physical_file,
             write_table(winsor_physical_tab, "table_winsor_physical"), format = "file"),
  # Rank-based checks on raw, unwinsorized volumes (reviewer round 4, comment 1).
  tar_target(wr_rank_tab, wr_rank_check(water_rights_assigned, matched_set)),
  tar_target(table_wr_rank_file, write_table(wr_rank_tab, "table_wr_rank"), format = "file"),
  # Volumetric-scale streamflow checks (reviewer round 5 "fatal flaw"): log-flow semi-elasticity
  # buffering + placebo (not variance-normalized) and the variance-compression premise itself.
  tar_target(volumetric_check_tab,
             build_volumetric_check(streamflow_monthly, streamflow_stations,
                                    spei12_monthly, matched_set)),
  tar_target(table_volumetric_file,
             write_table(volumetric_check_tab, "table_volumetric"), format = "file"),
  # Metric / functional-form checks (round 5, comments 1, 3, 4): control transmission by aridity
  # tercile, snowline piecewise elevation sensitivity, relative (log) cropland DiD.
  tar_target(metric_checks_tab,
             build_metric_checks(ssi_panel_itt, streamflow_stations, ssi12, irrig_area_panel,
                                 forcing_subcuencas_full, matched_set)),
  tar_target(table_metric_checks_file,
             write_table(metric_checks_tab, "table_metric_checks"), format = "file"),
  # Geomorphological (alluvial) confound check on the placebo (round 6, comment 1): direct local-
  # relief metric from SRTM, on the differential estimand.
  tar_target(dem_tif, cfg_sources$dem$path, format = "file"),
  tar_target(geomorph_check_tab,
             build_geomorph_check(dem_tif, streamflow_stations, ssi12,
                                  ssi_panel_up, ssi_panel_down, cfg_sources)),
  tar_target(table_geomorph_file,
             write_table(geomorph_check_tab, "table_geomorph"), format = "file"),
  # Carryover-capacity context (round 6, comment 5): capacity / annual flow + pre-2010 trough.
  tar_target(carryover_tab,
             build_carryover_check(levels_long, reservoir_units, streamflow_monthly,
                                   streamflow_stations, storage_band)),
  tar_target(table_carryover_file,
             write_table(carryover_tab, "table_carryover"), format = "file"),
  # Storage-capacity heterogeneity (reviewer 2026-08-05, 6th round): disaggregate the buffering
  # test by reservoir carryover ratio (capacity / annual downstream flow), so large carryover
  # reservoirs are not diluted by seasonal ones. Re-estimates ITT + down/up contrast within the
  # carryover (>= 0.5 yr) and seasonal subgroups, under permutation.
  tar_target(storage_het_units, {
    cap <- unique(data.table::as.data.table(levels_long)[is.finite(max_level_hm3),
                                                         .(ID_DGA, max_level_hm3)])
    ru <- data.table::as.data.table(reservoir_units)[level == "subcuencas", .(ID_DGA, unit_id)]
    su <- data.table::as.data.table(streamflow_stations)[treat == 1L & regulated == "down",
                                                         .(codigo, unit_id)]
    q  <- merge(data.table::as.data.table(streamflow_monthly), su, by = "codigo")
    qu <- q[, .(q_ms = mean(q_mon, na.rm = TRUE)), by = unit_id]
    qu[, flow_hm3 := q_ms * 31.536]
    d <- merge(merge(cap, ru, by = "ID_DGA"), qu, by = "unit_id")
    d[, ratio := max_level_hm3 / flow_hm3]
    d[, .(ratio = max(ratio)), by = unit_id][ratio >= 0.5, unit_id]
  }),
  tar_target(storage_het_check,
             storage_capacity_heterogeneity(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                            storage_het_units, n_perm = 2000L)),
  tar_target(table_storage_het_file,
             write_table(storage_het_check, "table_storage_capacity_heterogeneity"),
             format = "file"),
  # === Reviewer 2026-08-06 (first round) ==========================================================
  # (1) FATAL FLAW: downstream extraction masking. Local cropland (MapBiomas class 18) in 5/10 km
  #     buffers around each gauge; the down/up extraction gradient in treated basins; the control
  #     transmission-slope sensitivity to local extraction; and the predicted masking magnitude.
  tar_target(mb_mask_paths, {
    sources_yml
    y <- c("2007" = 2007L, "2020" = 2020L)
    setNames(mirror_paths_local(mapbiomas_paths(cfg_sources, unname(y)),
                                project_path("data/interim/mapbiomas_local")), names(y))
  }, format = "file"),
  tar_target(extraction_masking_tab,
             extraction_masking_check(streamflow_stations_raw, streamflow_stations, ssi12,
                                      ssi_panel_itt, streamflow_monthly, mb_mask_paths,
                                      mapbiomas_years = c(2007L, 2020L))),
  tar_target(table_extraction_masking_file,
             write_table(extraction_masking_tab, "table_extraction_masking"), format = "file"),
  #    Direct control for downstream extraction: the placebo net of a SPEI x local-cropland
  #    interaction (mirrors the elevation-adjusted placebo), under permutation.
  tar_target(cropland_adj_placebo,
             cropland_adjusted_placebo(streamflow_stations_raw, streamflow_stations, ssi12,
                                       ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                       mb_mask_paths, mapbiomas_years = c(2007L, 2020L),
                                       n_perm = 1000L)),
  tar_target(table_cropland_adj_placebo_file,
             write_table(cropland_adj_placebo, "table_cropland_adj_placebo"), format = "file"),
  # (2) Comment 1: strictly-paired carryover contrast. The 7+10=17 capacity split is on the
  #     buffering/ITT sample; restrict the down/up contrast to the strictly-paired basins so the
  #     carryover buffering does not rest on the partially-paired composition.
  tar_target(strictly_paired_carryover_tab,
             strictly_paired_carryover(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                       storage_het_units, n_perm = 1000L)),
  tar_target(table_strictly_paired_carryover_file,
             write_table(strictly_paired_carryover_tab, "table_strictly_paired_carryover"),
             format = "file"),
  # (3) Comment 2: carryover-ratio denominator sensitivity. Recomputed with the unregulated
  #     upstream-gauge flow (the available inflow proxy) and the resulting heterogeneity split.
  tar_target(carryover_ratio_sens,
             carryover_ratio_sensitivity(levels_long, reservoir_units, streamflow_stations,
                                         streamflow_monthly, storage_het_units)),
  tar_target(table_carryover_ratio_sens_file,
             write_table(carryover_ratio_sens$tab, "table_carryover_ratio_sensitivity"),
             format = "file"),
  tar_target(carryover_upflow_het, {
    t <- carryover_ratio_sens$tab
    up_units <- t[class_up == "carryover", as.character(unit_id)]
    storage_capacity_heterogeneity(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                   up_units, n_perm = 2000L)
  }),
  tar_target(table_carryover_upflow_het_file,
             write_table(carryover_upflow_het, "table_carryover_upflow_heterogeneity"),
             format = "file"),
  # (5) WRR revision (2026-08-06, second round): carryover-claim hardening. (a) The contrast on
  #     the irrigation-only carryover basins, excluding the two dams with hydropower operation
  #     (Colbún 0732, Lago Laja 0837), so the buffering reading is not hydropower scheduling;
  #     (b) leave-one-out re-runs with their own permutation p, since with 7 treated units a
  #     single basin could move the permutation p across 0.05.
  tar_target(carryover_robustness, {
    nm <- setNames(as.character(carryover_ratio_sens$tab$reservoir),
                   as.character(carryover_ratio_sens$tab$unit_id))
    carryover_robustness_checks(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                storage_het_units, hydro_units = c("0732", "0837"),
                                unit_names = nm, n_perm = 1000L)
  }),
  tar_target(table_carryover_robustness_file,
             write_table(carryover_robustness, "table_carryover_robustness"),
             format = "file"),
  # === Reviewer 3, second round (2026-08-06) ======================================================
  # FATAL FLAW: cascade-dam contamination of the upstream placebo. Upstream gauges are screened
  # against the full national dam inventory (same-unit tier + same-cuenca conservative tier) and
  # the placebo re-run without flagged gauges. Dam elevation caches (data/interim/) were extracted
  # via SRTM90m (the project SRTM 3s DEM lives on the external drive); regenerate against the DEM
  # with extract_dam_elevation() when the drive is mounted.
  tar_target(dam_unit_elev_csv, "data/interim/dam_inventory_treated_elev.csv", format = "file"),
  tar_target(dam_cuenca_elev_csv, "data/interim/dam_inventory_cuenca_elev.csv", format = "file"),
  tar_target(upstream_contamination,
             upstream_contamination_check(dam_unit_elev_csv, dam_cuenca_elev_csv,
                                          matched_subcuencas, streamflow_stations, ssi12,
                                          spei12_monthly, matched_set, ssi_panel_itt,
                                          ssi_panel_down, storage_het_units, n_perm = 1000L)),
  tar_target(table_upstream_contamination_file,
             write_table(upstream_contamination, "table_upstream_contamination"),
             format = "file"),
  # Comment 3: capacity-weighted + absolute-volume storage-band trends.
  tar_target(storage_weighted_tab, storage_band_weighted(storage_band, levels_long)),
  tar_target(table_storage_weighted_file,
             write_table(storage_weighted_tab, "table_storage_weighted"), format = "file"),
  # Comment 5: hard-balance weight diagnostics + leave-one-out over top-weighted controls.
  tar_target(hard_balance_weights,
             hard_balance_weight_diagnostics(matched_set_hard, match_covariates, ssi12,
                                             streamflow_stations, spei12_monthly)),
  tar_target(table_hard_balance_weights_file,
             write_table(hard_balance_weights, "table_hard_balance_weights"), format = "file"),
  # === Reviewer 3, third round (2026-08-06) =======================================================
  # FATAL FLAW: routed-network validation of the up/down gauge classification (HydroRIVERS v1.0,
  # data/raw/hydrorivers/, NEXT_DOWN topology traced from each gauge through its dam reach).
  tar_target(hydrorivers_shp,
             "data/raw/hydrorivers/HydroRIVERS_v10_sa_shp/HydroRIVERS_v10_sa.shp",
             format = "file"),
  tar_target(network_connectivity,
             hydroriver_connectivity_check(hydrorivers_shp, streamflow_stations_raw,
                                           streamflow_stations, points, reservoir_units, ssi12,
                                           spei12_monthly, matched_set, ssi_panel_down,
                                           n_perm = 1000L)),
  tar_target(table_network_connectivity_file,
             write_table(network_connectivity, "table_network_connectivity"), format = "file"),
  # (1) smooth national time trend replacing year FE
  tar_target(smooth_trend_tab,
             smooth_trend_sensitivity(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                      n_perm = 1000L)),
  tar_target(table_smooth_trend_file,
             write_table(smooth_trend_tab, "table_smooth_trend"), format = "file"),
  # (2) elevation-partitioned permutation null (aggregate + carryover contrasts)
  tar_target(elevsplit_perm_tab,
             placebo_elevsplit_permutation(ssi12, streamflow_stations, spei12_monthly,
                                           matched_set, storage_het_units, n_perm = 1000L)),
  tar_target(table_elevsplit_perm_file,
             write_table(elevsplit_perm_tab, "table_elevsplit_permutation"), format = "file"),
  # (3) SSI re-standardized on the 1990-2020 (31-year) baseline
  tar_target(ssi_baseline_tab,
             ssi_baseline_sensitivity(streamflow_monthly, streamflow_stations, spei12_monthly,
                                      matched_set, n_perm = 1000L)),
  tar_target(table_ssi_baseline_file,
             write_table(ssi_baseline_tab, "table_ssi_baseline"), format = "file"),
  # (4) drought-conditional missingness assessment
  tar_target(missingness_tab,
             missingness_drought_bias(streamflow_monthly, streamflow_stations, spei12_monthly)),
  tar_target(table_missingness_file,
             write_table(missingness_tab, "table_missingness_drought"), format = "file"),
  # (5) storage trends on the coverage-stable reservoir subset
  tar_target(storage_stable_tab, storage_stable_trends(storage_band)),
  tar_target(table_storage_stable_file,
             write_table(storage_stable_tab, "table_storage_stable_subset"), format = "file"),
  # (6) non-linear aridity-by-forcing sensitivity
  tar_target(nonlin_aridity_tab, nonlinear_aridity_sensitivity(ssi_panel_itt, n_perm = 1000L)),
  tar_target(table_nonlin_aridity_file,
             write_table(nonlin_aridity_tab, "table_nonlinear_aridity"), format = "file"),
  # (7) control basins screened against the national dam inventory; re-balanced dam-free refit
  tar_target(control_contamination_tab,
             control_dam_contamination(
               "data/raw/reservoirs/reservoirs_shapefile/Embalse_2026_05_31.shp",
               matched_subcuencas, matched_set, match_covariates, ssi12,
               streamflow_stations, spei12_monthly, n_perm = 1000L)),
  tar_target(table_control_contamination_file,
             write_table(control_contamination_tab, "table_control_dam_contamination"),
             format = "file"),
  # === Reviewer 3, fourth round (2026-08-06): wild cluster bootstrap for storage trends =========
  tar_target(storage_wcb_tab, storage_wild_bootstrap(storage_band, levels_long, B = 1999L)),
  tar_target(table_storage_wcb_file,
             write_table(storage_wcb_tab, "table_storage_wild_bootstrap"), format = "file"),
  # (4) Comment 3: sub-watershed SPEI exposure misclassification bound. Gauge-point SPEI vs the
  #     subcuenca-mean SPEI the model uses, per gauge class (correlation, error variance, implied
  #     slope attenuation).
  tar_target(spei_exposure_tab,
             spei_exposure_bound(streamflow_stations_raw, streamflow_stations, spei12_monthly,
                                 spei12_stack)),
  tar_target(table_spei_exposure_file,
             write_table(spei_exposure_tab, "table_spei_exposure"), format = "file"),
  # ET confound demonstration (reviewer): whole-basin vs vegetated-cell ET event studies
  tar_target(fig_et_confound_obj, fig_et_confound(es_et, es_orch, did_panel_et, did_panel_orch)),
  tar_target(fig_et_confound_file,
             save_fig(fig_et_confound_obj, "fig_et_confound", width = "onehalf", height_mm = 120),
             format = "file"),

  tar_target(fig_water_rights_obj, fig_water_rights(es_wr, wr_demand_summary)),
  tar_target(fig_water_rights_file,
             save_fig(fig_water_rights_obj, "fig_water_rights", width = "onehalf", height_mm = 130),
             format = "file"),
  tar_target(table_wr_summary_file, write_table(wr_demand_summary, "table_water_rights"),
             format = "file"),

  # === MANUSCRIPT FIGURES + TABLES (results/ via file targets; one message each) ===============
  # Main results table: convergent H2 null across cross-sectional ATTs, forcing-interacted DiD, and
  # the direct water-rights demand test (all judged by randomization inference).
  tar_target(main_results_table,
             build_main_results_table(att_irrig_area_expansion, att_et_buffering, did_summary,
                                      att_wr = wr_att, wr_perm = wr_perm)),
  tar_target(table_main_file, write_table(main_results_table, "table_main_results"),
             format = "file"),

  # Fig 1 (concept): schematic of the two comparisons (matched dammed-vs-control; within-basin
  # upstream/downstream placebo) that separate the reservoir from its siting.
  tar_target(fig_schematic_obj, fig_design_schematic()),
  tar_target(fig_schematic_file,
             save_fig(fig_schematic_obj, "fig_design_schematic", width = "onehalf", height_mm = 75),
             format = "file"),

  # Study-area / treatment-control map (Supplementary) — matched sample on Chile's aridity gradient,
  # controls sized by entropy-balancing weight, plus the within-basin up/down placebo geometry inset.
  tar_target(fig_study_area_obj,
             fig_study_area(matched_set, matched_subcuencas, subcuencas_dissolved, points,
                            reservoir_units, streamflow_stations, streamflow_stations_raw)),
  tar_target(fig_study_area_file,
             save_fig(fig_study_area_obj, "fig_study_area", width = "double", height_mm = 150),
             format = "file"),

  # Fig 2 (design): covariate-balance love plot + common support — entropy balancing collapses the
  # siting imbalance to ~0; the three pruned treated units are off-support high-Andes/cold basins.
  tar_target(fig_balance_obj, fig_covariate_balance(matched_set, match_covariates)),
  tar_target(fig_balance_file,
             save_fig(fig_balance_obj, "fig_covariate_balance", width = "onehalf", height_mm = 150),
             format = "file"),

  # Supp fig: non-parametric aridity common-support/overlap check (reviewer round 7, comment 2) —
  # shows the doubly-robust aridity adjustment interpolates inside the control support.
  tar_target(fig_aridity_overlap_obj, fig_aridity_overlap(matched_set)),
  tar_target(fig_aridity_overlap_file,
             save_fig(fig_aridity_overlap_obj, "fig_aridity_overlap", width = "onehalf", height_mm = 95),
             format = "file"),

  # Fig 3 (was Fig 1): observed irrigated-area DiD — siting level gap + flat event-study (dynamic null)
  tar_target(es_area_envelope, es_permutation_envelope(did_panel_area)),
  tar_target(fig_area_did_obj, fig_area_did(did_panel_area, es_area,
                                            es_envelope = es_area_envelope)),
  tar_target(fig_area_did_file,
             save_fig(fig_area_did_obj, "fig_area_did", width = "onehalf", height_mm = 120),
             format = "file"),

  # Fig 3: streamflow buffering is siting (SPEI->SSI slopes + ITT/downstream/upstream-placebo coefs)
  tar_target(fig_streamflow_obj, fig_streamflow(streamflow_summary, ssi_panel_down)),
  tar_target(fig_streamflow_file,
             save_fig(fig_streamflow_obj, "fig_streamflow", width = "onehalf", height_mm = 130),
             format = "file"),

  # Fig 4: convergent-null forest — uniform estimate/SE axis, faceted by estimator regime, DiD rows
  # annotated with randomization-inference p, whole-basin ET flagged confounded/excluded (open symbol).
  tar_target(fig_convergent_obj, fig_convergent_null(main_results_table)),
  tar_target(fig_convergent_file,
             save_fig(fig_convergent_obj, "fig_convergent_null", width = "onehalf", height_mm = 100),
             format = "file"),

  # Fig 6 (identification): siting-confound decomposition ladder — the dammed-vs-control slope gap at
  # naive -> +FE -> design -> +within-region, plus the upstream placebo. Shows the streamflow signal
  # survives matching/FE but collapses within climate region and equals the unregulated placebo.
  tar_target(siting_ladder,
             build_siting_ladder(ssi_panel_itt, did_panel_area, did_panel_orch,
                                 streamflow_summary, did_summary)),
  tar_target(table_siting_ladder_file, write_table(siting_ladder, "table_siting_ladder"),
             format = "file"),
  tar_target(fig_ladder_obj, fig_decomposition_ladder(siting_ladder)),
  tar_target(fig_ladder_file,
             save_fig(fig_ladder_obj, "fig_decomposition_ladder", width = "onehalf", height_mm = 140),
             format = "file"),

  # Fig (forcing, Extended Data): national + treated-vs-control SPEI-12 over 2000-2024 — the sustained
  # megadrought dose shared by dammed and control basins, motivating the forcing-conditioned estimand.
  tar_target(fig_forcing_obj, fig_drought_forcing(spei12_monthly, matched_set)),
  tar_target(fig_forcing_file,
             save_fig(fig_forcing_obj, "fig_drought_forcing", width = "onehalf", height_mm = 120),
             format = "file"),

  # Fig (power, Extended Data): informative-null panel — (a) equivalence/MDE bounds on the streamflow
  # outcomes vs the +-25%-baseline negligible region; (b) positive-control recovery of an injected
  # buffering slope with randomization-inference detection. Converts "failed to reject" into limits.
  tar_target(fig_informative_obj, fig_informative_null(equivalence_table, ssi_positive_ctrl)),
  tar_target(fig_informative_file,
             save_fig(fig_informative_obj, "fig_informative_null", width = "onehalf", height_mm = 115),
             format = "file"),

  # Fig 4: the binding constraint is inflow, not storage — the whole storage band shifts down
  # (annual peak & trough percent-of-capacity both decline) while seasonal amplitude stays flat,
  # a supply-side level shift rather than refill/buffer degradation. Built from storage_pct.
  # Independent supply baseline for the descriptive storage decline: streamflow trend in control gauges
  tar_target(streamflow_supply_trend_tab,
             streamflow_supply_trend(streamflow_monthly, streamflow_stations)),
  tar_target(storage_band, storage_band_annual(storage_pct)),
  tar_target(storage_band_trends, fit_storage_band_trends(storage_band)),
  tar_target(table_storage_band_file, write_table(storage_band_trends, "table_storage_band"),
             format = "file"),
  tar_target(fig_storage_obj, fig_storage_band(storage_band, storage_band_trends)),
  tar_target(fig_storage_file,
             save_fig(fig_storage_obj, "fig_storage_band", width = "onehalf", height_mm = 120),
             format = "file"),

  # --- storage preprocessing --------------------------------------------------------
  tar_target(storage_pct, add_storage_fraction(compute_pct_capacity(levels_long))),

  # --- index raster catalog + extraction at reservoir points ------------------------
  tar_target(raster_catalog, build_raster_catalog(cfg_sources, cfg_vars)),
  tar_target(extracted,      extract_index_at_points(raster_catalog, points, buffer_m = 0)),

  # --- Phase 1: propagation (timescale/lag selection) -------------------------------
  tar_target(
    propagation,
    best_timescale_lag(
      response = storage_pct[has_capacity == TRUE, .(ID_DGA, date, y = storage_fraction)],
      forcing  = extracted
    )
  ),
  tar_target(propagation_summary, summarise_propagation(propagation)),

  # --- Phase 1: forcing-conditioned response function -------------------------------
  # Defaults (SPEI-12 -> zcNDVI-6) are a starting point; revise from propagation_summary.
  tar_target(
    panel,
    assemble_analysis_panel(
      storage_pct, extracted, cfg_study,
      forcing = list(product = "SPEI", timescale = 12, lag = 0),
      outcome = list(product = "zcNDVI", timescale = 6)
    )
  ),
  tar_target(dose_response,  fit_dose_response(panel)),    # Lever 2 (forcing-orthogonal)
  tar_target(period_slopes,  fit_period_slopes(panel)),    # Lever 4 (pre vs mega slope)
  tar_target(storage_threshold, estimate_storage_threshold(panel))  # exploratory s*
)
