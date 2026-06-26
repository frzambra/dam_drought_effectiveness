# Land-cover-STRATIFIED ecological outcome: per-subcuenca annual zNPP split into AGRICULTURAL
# vs NATURAL cover. This is the decisive test for the forcing-conditioned ATT
# (docs/progress_summary/2026-06-26_forcing-conditioned-att.md): the basin-mean transmission
# slope is confounded by baseline aridity (arid basins are more water-coupled regardless of the
# dam). Splitting the slope by cover separates the mechanisms:
#   - If the dammed-vs-control slope gap is a RESERVOIR/land-use effect (H2), it appears WITHIN
#     agricultural cover (reservoirs water crops, not native vegetation) and ~vanishes WITHIN
#     natural cover.
#   - If it is an ARIDITY/water-limitation artefact, it appears EQUALLY in both strata.
# Comparing within cover class also holds aridity roughly fixed, sidestepping that confound.
#
# Grain bridge: MapBiomas is 30 m (5e9 cells nationally — never loaded whole); zNPP is ~1 km.
# Per polygon we crop both from disk, resample a BASELINE (pre-expansion, exogenous) farming /
# natural binary to the zNPP grid as a fractional cover, threshold it into ag / natural pixel
# masks, and take masked zonal means of the zNPP stack. A static baseline mask (default 2007,
# mid-baseline) keeps the cover classification exogenous to the later drought/reservoir dynamics
# — expansion itself is a separate H2 area-trend test, not this slope test.

#' Absolute paths to MapBiomas annual land-cover rasters for given years.
#' @param sources load_config("data_sources")
#' @param years   integer years (MapBiomas spans 1999-2024)
#' @return character vector of existing paths (missing years dropped with a warning)
mapbiomas_paths <- function(sources, years) {
  lc  <- sources$landcover
  files <- file.path(lc$root, sprintf("mapbiomas_v2.0_%d.tif", years))
  ok <- file.exists(files)
  if (!all(ok))
    warning("mapbiomas_paths: missing ", sum(!ok), " year(s): ",
            paste(years[!ok], collapse = ", "))
  files[ok]
}

#' Baseline fractional cover (farming, natural) on the zNPP grid for ONE polygon.
#'
#' Crops each baseline MapBiomas year to the polygon, builds a 0/1 farming and a 0/1 natural
#' raster, resamples each to the (polygon-cropped) zNPP grid with method="average" -> the
#' fraction of each 30 m cell class within every ~1 km zNPP cell, then averages across baseline
#' years. Returns the two fraction layers aligned to `znpp_tmpl`.
#'
#' @param poly      single-feature SpatVector (one unit)
#' @param znpp_tmpl one zNPP layer cropped+masked to the polygon (the target grid)
#' @param base_rast SpatRaster stack of baseline MapBiomas years (national; cropped here)
#' @param agri,natural integer class-ID vectors
#' @return list(agfrac, natfrac) SpatRasters on the znpp_tmpl grid (NA outside the polygon)
.baseline_cover_fracs <- function(poly, znpp_tmpl, base_rast, agri, natural) {
  ag_list <- nat_list <- vector("list", terra::nlyr(base_rast))
  for (i in seq_len(terra::nlyr(base_rast))) {
    bc <- terra::mask(terra::crop(base_rast[[i]], poly, snap = "out"), poly)
    ag_list[[i]]  <- terra::resample(terra::app(bc, fun = function(v) as.numeric(v %in% agri)),
                                     znpp_tmpl, method = "average")
    nat_list[[i]] <- terra::resample(terra::app(bc, fun = function(v) as.numeric(v %in% natural)),
                                     znpp_tmpl, method = "average")
  }
  agfrac  <- if (length(ag_list)  > 1) terra::mean(terra::rast(ag_list),  na.rm = TRUE) else ag_list[[1]]
  natfrac <- if (length(nat_list) > 1) terra::mean(terra::rast(nat_list), na.rm = TRUE) else nat_list[[1]]
  list(agfrac = agfrac, natfrac = natfrac)
}

#' Per-unit annual zNPP stratified into agricultural vs natural cover.
#'
#' @param units      sf polygons with `unit_id` (pass the matched-set units only — this is heavy)
#' @param znpp_stack list(paths, years) from ecological_annual_paths("zNPP")
#' @param mb_paths   baseline MapBiomas raster paths (from mapbiomas_paths())
#' @param agri,natural class-ID sets (defaults: Agriculture only vs native vegetation)
#' @param frac_thr   a zNPP cell joins a stratum if its baseline fraction of that class >= this
#'                   (default 0.5 — majority cover)
#' @param min_cells  require at least this many cells in a stratum to report it (default 3)
#' @return data.table(unit_id, year, level, stratum, n_cells) ; stratum in {"agri","natural"}
stratified_znpp_annual <- function(units, znpp_stack, mb_paths,
                                   agri = c(18L),
                                   natural = c(1L, 3L, 59L, 60L, 67L, 11L, 12L, 63L, 66L),
                                   frac_thr = 0.5, min_cells = 3L) {
  zn   <- terra::rast(znpp_stack$paths)            # ~1 km annual stack
  yrs  <- znpp_stack$years
  base <- terra::rast(mb_paths)                    # baseline MapBiomas years (cropped per unit)
  uv   <- terra::vect(units)
  if (!terra::same.crs(uv, zn)) uv <- terra::project(uv, zn)

  out <- vector("list", nrow(units))
  for (k in seq_len(nrow(units))) {
    poly <- uv[k]
    zc <- tryCatch(terra::mask(terra::crop(zn, poly, snap = "out"), poly),
                   error = function(e) NULL)
    if (is.null(zc) || all(is.na(terra::minmax(zc[[1]])))) next

    fr <- .baseline_cover_fracs(poly, zc[[1]], base, agri, natural)
    masks <- list(agri = fr$agfrac >= frac_thr, natural = fr$natfrac >= frac_thr)

    rows <- list()
    for (st in names(masks)) {
      m <- masks[[st]]
      n_cells <- as.integer(terra::global(m, "sum", na.rm = TRUE)[1, 1])
      if (is.na(n_cells) || n_cells < min_cells) next
      zst <- terra::mask(zc, m, maskvalues = c(NA, FALSE))      # keep stratum cells only
      mu  <- terra::global(zst, "mean", na.rm = TRUE)[, 1]      # per-year stratum mean
      rows[[st]] <- data.table::data.table(
        unit_id = units$unit_id[k], year = yrs, level = mu,
        stratum = st, n_cells = n_cells)
    }
    if (length(rows)) out[[k]] <- data.table::rbindlist(rows)
  }
  res <- data.table::rbindlist(out)
  res <- res[!is.na(level)]
  data.table::setorder(res, stratum, unit_id, year)
  res[]
}
