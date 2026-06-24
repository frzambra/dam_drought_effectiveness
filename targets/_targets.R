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
               "fixest", "segmented", "lubridate")
)

list(
  # --- config -----------------------------------------------------------------------
  tar_target(cfg_study,   load_config("study_period")),
  tar_target(cfg_vars,    load_config("variables")),
  tar_target(cfg_sources, load_config("data_sources")),

  # --- raw inputs (tracked as files) ------------------------------------------------
  tar_target(reservoir_csv,
             project_path("data/raw/reservoirs/reservoirs_levels_2005-2026.csv"),
             format = "file"),
  tar_target(reservoir_shp,
             project_path("data/raw/reservoirs/reservoirs_shapefile/Embalse_2026_05_31.shp"),
             format = "file"),

  # --- ingestion --------------------------------------------------------------------
  tar_target(levels_long, read_reservoir_levels(reservoir_csv)),
  tar_target(reservoir_ids, unique(levels_long$ID_DGA)),
  tar_target(points, read_reservoir_points(reservoir_shp, reservoir_ids)),

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
