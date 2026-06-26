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
               "WeightIt", "cobalt", "MatchIt")
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
