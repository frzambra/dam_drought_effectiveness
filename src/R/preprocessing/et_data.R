# MOD16A2GF actual-ET (500 m, monthly) -> per-basin ET drought-sensitivity for the buffering
# test. Unlike the SETI anomaly product (~5.5 km, too coarse to isolate orchards), native MOD16
# is ~500 m, so orchard-majority cells exist in most matched basins (median densest 500 m pixel
# ~90 % orchard). The outcome is the AMPLITUDE of ET response to drought — slope of log(annual ET)
# on SPEI (a semi-elasticity, fractional ET change per SPEI unit) — NOT a z-standardised slope,
# because standardising would erase the amplitude that IS the buffering signal. Reservoir
# buffering (H1) predicts a SMALLER (flatter) slope on irrigated land in dammed basins.
#
# CAVEAT: MOD16 is known to UNDER-estimate irrigated-crop ET (its PM + MODIS-LAI algorithm does
# not model irrigation), which can compress the dynamic range and mute a buffering difference;
# cross-check with PML_V2 if a signal is marginal.

#' Absolute paths + dates for the MOD16A2GF monthly ET rasters.
#' @param sources load_config("data_sources")
#' @param years   calendar years (default 2001:2024; the product runs 2000-2025, but 2000 may be
#'                partial and 2025 incomplete)
#' @return list(paths, dates)
mod16_monthly_paths <- function(sources, years = 2001:2024) {
  dir <- sources$et_mod16$root
  f   <- list.files(dir, "\\.tif$", full.names = TRUE)
  d   <- as.Date(sub(".*_(\\d{8})\\.tif$", "\\1", f), "%Y%m%d")
  keep <- !is.na(d) & data.table::year(d) %in% years
  ord  <- order(d[keep])
  list(paths = f[keep][ord], dates = d[keep][ord])
}

#' Per-basin annual ET over a cover stratum, returned as log(annual mean monthly ET).
#'
#' Masks MODIS fill (> `fill_above`), aggregates the monthly stack to an annual mean per year
#' (`tapp`), restricts to cells where the stratum cover fraction ≥ `frac_thr`, and takes the
#' per-basin per-year mean. `level` = log(annual ET) so the downstream slope is a fractional ET
#' sensitivity (semi-elasticity).
#'
#' @param units     sf polygons with `unit_id`
#' @param stack     mod16_monthly_paths() output
#' @param coverfrac cover-fraction SpatRaster on the ET grid (orchard or cropland)
#' @param frac_thr  minimum cover fraction for a cell (default 0.5)
#' @param min_cells minimum stratum cells per unit (default 3)
#' @param fill_above values above this are MODIS fill -> NA (default 32760)
#' @return data.table(unit_id, year, level, n_cells)
extract_unit_et_annual <- function(units, stack, coverfrac, frac_thr = 0.5,
                                   min_cells = 3L, fill_above = 32760) {
  et <- terra::rast(stack$paths)
  et <- terra::ifel(et > fill_above, NA, et)
  yr <- data.table::year(stack$dates)
  et_ann <- terra::tapp(et, yr, mean, na.rm = TRUE)       # annual mean monthly ET
  yrs <- as.integer(sub("X", "", names(et_ann)))

  m   <- coverfrac >= frac_thr
  et_o <- terra::mask(et_ann, m, maskvalues = c(NA, FALSE))
  v <- terra::vect(units)
  if (!terra::same.crs(v, et_ann)) v <- terra::project(v, et_ann)

  ex <- data.table::as.data.table(terra::extract(et_o, v, fun = mean, na.rm = TRUE, ID = TRUE))
  data.table::setnames(ex, c("ID", paste0("y", yrs)))
  nc <- data.table::as.data.table(
    terra::extract(m, v, fun = function(x) sum(x > 0, na.rm = TRUE), ID = TRUE))
  data.table::setnames(nc, c("ID", "n_cells"))
  ex[, unit_id := units$unit_id[ID]]
  ex <- merge(ex, nc, by = "ID")[n_cells >= min_cells]

  long <- data.table::melt(ex, id.vars = c("ID", "unit_id", "n_cells"),
                           variable.name = "yv", value.name = "et")
  long[, year := as.integer(sub("y", "", yv))]
  long <- long[!is.na(et) & et > 0, .(unit_id, year, level = log(et), n_cells)]
  data.table::setorder(long, unit_id, year)
  long[]
}

#' ET-buffering ATT: dammed-vs-control slope of log(orchard ET) on SPEI.
#' @param et_panel    extract_unit_et_annual() output (orchard cells)
#' @param forcing     extract_unit_forcing_annual() SPEI output
#' @param matched_set fit_matched_set() output
#' @return list(att, slopes, group_means) — H1 buffering predicts a NEGATIVE ATT
fit_et_buffering_att <- function(et_panel, forcing, matched_set) {
  sl  <- fit_response_slopes(build_response_panel(et_panel[, .(unit_id, year, level)], forcing),
                             min_years = 10L)
  fit <- fit_doubly_robust(matched_set, sl, outcome_col = "resp_slope")
  g   <- merge(data.table::as.data.table(matched_set$data)[, .(unit_id, treated, w)],
               sl[, .(unit_id, resp_slope)], by = "unit_id")[!is.na(resp_slope)]
  list(att = fit$estimates[estimator == "doubly_robust"], slopes = sl,
       group_means = g[, .(mean_sensitivity = mean(resp_slope)), by = treated])
}
