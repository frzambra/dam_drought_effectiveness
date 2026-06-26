# Two discriminating diagnostics for the forcing-conditioned ATT, prompted by the
# hypothesis-challenger (2026-06-26). Both reuse the response-slope + doubly-robust machinery.
#
# TEST A — ET buffering on irrigated orchards. zNPP showed a null on irrigated land, but that is
#   consistent with both "no effect" AND "irrigation buffers productivity". SETI (standardized
#   actual-ET anomaly) is a direct water-USE signal: reservoir-buffered orchards should keep
#   transpiring through drought (FLATTER SETI~SPEI slope) than rain-fed control orchards.
#   CAVEAT: SETI is ~5.5 km, so orchard-bearing cells are mostly non-orchard matrix — a null is
#   uninformative (the matrix ET response dominates and masks any orchard buffering).
#
# TEST B — pre-megadrought PLACEBO. If the dammed-vs-control natural-cover transmission-slope gap
#   is a fixed basin trait (baseline aridity), it is present BEFORE the 2010 megadrought; if it is
#   a drought-era reservoir effect, it opens up only in 2010+. Splits the natural-cover slope into
#   a pre-drought (2000-2009) and drought (2010-2024) window and compares the ATT.

#' Absolute paths + dates for a monthly MODIS ecological index (SETI) at one timescale.
#' @param sources   load_config("data_sources")
#' @param product   ecological_indices key (default "SETI")
#' @param timescale accumulation months (default 12)
#' @param years     calendar years (default 2005:2024)
#' @return list(paths, dates)
seti_monthly_paths <- function(sources, product = "SETI", timescale = 12L, years = 2005:2024) {
  p   <- sources$ecological_indices$products[[product]]
  if (is.null(p)) stop("Unknown ecological product: ", product)
  # Files live under <root>/<subdir>/<PRODUCT>-<timescale>/ (e.g. MODIS/SETI/SETI-12/).
  dir <- file.path(sources$ecological_indices$root, p$subdir,
                   sprintf("%s-%d", product, timescale))
  dates <- seq(as.Date(sprintf("%d-01-01", min(years))),
               as.Date(sprintf("%d-12-01", max(years))), by = "month")
  files <- file.path(dir, sprintf("%s-%d_chile_%s.tif", product, timescale,
                                  format(dates, "%Y-%m-01")))
  ok <- file.exists(files)
  if (!all(ok))
    warning("seti_monthly_paths: missing ", sum(!ok), " month(s)")
  list(paths = files[ok], dates = dates[ok])
}

#' Test A — orchard-ET transmission-slope ATT (SETI~SPEI on orchard-bearing cells).
#'
#' @param units       matched subcuencas (sf)
#' @param seti_stack  seti_monthly_paths() output
#' @param orchfrac_seti orchard cover-fraction raster on the SETI grid
#' @param forcing     extract_unit_forcing_annual() SPEI output
#' @param matched_set fit_matched_set() output
#' @param frac_thr,min_cells orchard-cell thresholds (defaults 0.05 / 2 — SETI grain is coarse)
#' @return list(att = doubly-robust estimate row, slopes, n)
fit_orchard_et_att <- function(units, seti_stack, orchfrac_seti, forcing, matched_set,
                               frac_thr = 0.05, min_cells = 2L) {
  m <- orchfrac_seti >= frac_thr
  seti_o <- extract_unit_forcing_annual(units, seti_stack, mask = m)   # annual orchard-cell SETI
  data.table::setnames(seti_o, "forcing", "level")
  panel  <- build_response_panel(seti_o[, .(unit_id, year, level)], forcing)
  slopes <- fit_response_slopes(panel, min_years = 8L)
  fit <- fit_doubly_robust(matched_set, slopes, outcome_col = "resp_slope")
  list(att = fit$estimates[estimator == "doubly_robust"], slopes = slopes,
       caveat = "SETI ~5.5 km: orchard cells are mostly matrix; a null is grain-limited, not evidence of absence")
}

#' Test B — natural-cover transmission-slope ATT split into pre-drought vs drought windows.
#'
#' @param stratum_panel stratified_znpp_annual() output spanning the full window (e.g. 2000-2024)
#' @param forcing        extract_unit_forcing_annual() SPEI output over the same window
#' @param matched_set    fit_matched_set() output
#' @param stratum        which cover stratum (default "natural")
#' @param periods        named list of year vectors (default pre 2000-2009 / drought 2010-2024)
#' @return data.table(period, years, att, ci_lo, ci_hi, t, att_ar2, t_ar2, n_t, n_c)
fit_period_transmission_att <- function(stratum_panel, forcing, matched_set,
                                        which_stratum = "natural",
                                        periods = list(pre = 2000:2009, drought = 2010:2024)) {
  np <- data.table::as.data.table(stratum_panel)[stratum == which_stratum, .(unit_id, year, level)]
  rows <- lapply(names(periods), function(nm) {
    yrs <- periods[[nm]]
    sl  <- fit_response_slopes(build_response_panel(np[year %in% yrs], forcing[year %in% yrs]),
                               min_years = min(7L, length(yrs)))
    e1 <- fit_doubly_robust(matched_set, sl, outcome_col = "resp_slope")$estimates[
      estimator == "doubly_robust"]
    d <- merge(data.table::as.data.table(matched_set$data), sl[, .(unit_id, resp_slope)],
               by = "unit_id")
    d[, `:=`(y = resp_slope, log_aridity_sq = log_aridity^2)]
    e2 <- dr_estimate(d, c("log_area", "elev_mean", "log_aridity", "log_aridity_sq"))$estimates[
      estimator == "doubly_robust"]
    data.table::data.table(period = nm, years = sprintf("%d-%d", min(yrs), max(yrs)),
                           att = e1$att, ci_lo = e1$ci_lo, ci_hi = e1$ci_hi, t = e1$t,
                           att_ar2 = e2$att, t_ar2 = e2$t,
                           n_t = e1$n_treated, n_c = e1$n_control)
  })
  data.table::rbindlist(rows)[]
}
