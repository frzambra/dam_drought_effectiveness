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
  tar_target(grain_choice,
             compare_grains(reservoir_units, cuencas_dissolved, subcuencas_dissolved,
                            clim_cuencas, clim_subcuencas)),

  # --- matched control set (subcuenca grain, ATT entropy balancing) ------------------
  tar_target(match_covariates,
             build_match_covariates(subcuencas_dissolved, grain_choice$flags$subcuenca,
                                    clim_subcuencas, terrain_subcuencas)),
  tar_target(matched_set, fit_matched_set(match_covariates)),
  tar_target(robustness_matches,
             fit_robustness_matches(match_covariates, matched_set)),

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
