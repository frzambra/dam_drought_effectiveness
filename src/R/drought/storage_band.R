# Storage-band trend analysis: under aridification the whole storage band shifts DOWN — annual
# peak AND trough percent-of-capacity both decline — while the seasonal amplitude stays ~flat.
# That is a supply-side LEVEL shift (less water arriving), NOT a degradation of refill/buffering
# capacity (which would shrink the amplitude). Built from percent-of-capacity, the only
# cross-reservoir-comparable storage quantity (raw levels are not comparable).

#' Per reservoir-year storage band: annual peak (max), trough (min), and amplitude of storage,
#' in FRACTION-of-capacity (0-1). Drops reservoirs without a capacity (pct undefined, e.g. Rungue)
#' and reservoir-years with too few monthly observations to define a stable peak/trough.
#' @param storage_pct add_storage_fraction(compute_pct_capacity(levels_long))
#' @param min_months minimum monthly observations required per reservoir-year (default 6)
#' @return data.table(ID_DGA, year, peak, trough, amplitude) in storage fraction (0-1)
storage_band_annual <- function(storage_pct, min_months = 6L) {
  dt <- data.table::as.data.table(storage_pct)[has_capacity == TRUE & is.finite(storage_fraction)]
  dt[, year := data.table::year(date)]
  band <- dt[, .(n = .N,
                 peak   = max(storage_fraction),
                 trough = min(storage_fraction)),
             by = .(ID_DGA, year)][n >= min_months]
  band[, amplitude := peak - trough]
  band[, n := NULL]
  data.table::setorder(band, ID_DGA, year)
  band[]
}

#' Linear year-trend of each band component (peak / trough / amplitude) pooled across reservoirs,
#' with reservoir fixed effects and reservoir-clustered SEs. The diagnostic signature:
#'   whole-band downshift  = peak slope < 0 AND trough slope < 0;
#'   intact buffer (refill) = amplitude slope ~ 0 (the band drops but does not narrow).
#' @param band_annual storage_band_annual() output
#' @return data.table(component, slope, se, ci_lo, ci_hi, p) — per-year, fraction-of-capacity units
fit_storage_band_trends <- function(band_annual) {
  d <- data.table::as.data.table(band_annual)
  one <- function(comp) {
    m  <- fixest::feols(stats::as.formula(sprintf("%s ~ year | ID_DGA", comp)),
                        data = d, cluster = ~ID_DGA)
    ct <- as.data.frame(summary(m)$coeftable)["year", ]
    data.table::data.table(component = comp, slope = ct[[1]], se = ct[[2]],
                           ci_lo = ct[[1]] - 1.96 * ct[[2]],
                           ci_hi = ct[[1]] + 1.96 * ct[[2]], p = ct[[4]])
  }
  data.table::rbindlist(lapply(c("peak", "trough", "amplitude"), one))
}
