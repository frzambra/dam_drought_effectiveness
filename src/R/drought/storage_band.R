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

#' Pre/post-megadrought period comparison of the storage band (Reviewer 3 round 3, comment 3):
#' the 2005-2024 linear slope is a summary rate, not a claim of secular linearity, so characterize
#' the band as a level shift at the 2010 megadrought onset: within-reservoir mean peak / trough /
#' amplitude before vs after, with reservoir FE and clustered SEs.
#' @return data.table(component, pre_mean, post_mean, shift, se, ci_lo, ci_hi, p)
storage_period_comparison <- function(band_annual, split_year = 2010L) {
  d <- data.table::as.data.table(band_annual)
  d[, post := as.integer(year >= split_year)]
  one <- function(comp) {
    m  <- fixest::feols(stats::as.formula(sprintf("%s ~ post | ID_DGA", comp)),
                        data = d, cluster = ~ID_DGA)
    ct <- as.data.frame(summary(m)$coeftable)["post", ]
    data.table::data.table(component = comp,
                           pre_mean  = round(d[post == 0L, mean(get(comp))], 3),
                           post_mean = round(d[post == 1L, mean(get(comp))], 3),
                           shift = ct[[1]], se = ct[[2]],
                           ci_lo = ct[[1]] - 1.96 * ct[[2]],
                           ci_hi = ct[[1]] + 1.96 * ct[[2]], p = ct[[4]])
  }
  data.table::rbindlist(lapply(c("peak", "trough", "amplitude"), one))
}

#' R6 6th round, comment 4 (2026-08-05): is the storage decline a step-change at the 2010
#' megadrought onset or a continuous drift? The full-window trend in table_storage_band mixes the
#' two. We report (a) the within-megadrought (2010-2024) trend of peak and trough, to show whether
#' storage stabilized at a lower equilibrium or kept drifting downward through the drought; and
#' (b) a model that nests both a 2010 level shift and a post-shift linear trend, so the step-change
#' and any residual drift are separated. Pooled within-reservoir (ID_DGA FE), reservoir-clustered SE.
#' @return data.table(component, quantity, estimate, se, p, detail)
storage_step_vs_trend <- function(band_annual, split_year = 2010L) {
  d <- data.table::as.data.table(band_annual)
  # within-megadrought linear trend
  dm <- d[year >= split_year]
  one_trend <- function(comp) {
    m <- fixest::feols(stats::as.formula(sprintf("%s ~ year | ID_DGA", comp)),
                       data = dm, cluster = ~ID_DGA)
    ct <- as.data.frame(summary(m)$coeftable)["year", ]
    data.table::data.table(component = comp, quantity = "within-megadrought trend (per yr)",
                           estimate = ct[[1]], se = ct[[2]], p = ct[[4]])
  }
  # step + post-step trend: peak ~ post + year:post | ID_DGA
  d[, post := as.integer(year >= split_year)]
  one_nest <- function(comp) {
    d[, yr_post := (year - split_year) * post]
    m <- fixest::feols(stats::as.formula(sprintf("%s ~ post + yr_post | ID_DGA", comp)),
                       data = d, cluster = ~ID_DGA)
    ct <- as.data.frame(summary(m)$coeftable)
    data.table::rbindlist(list(
      data.table::data.table(component = comp, quantity = "step change at 2010",
                             estimate = ct["post", 1], se = ct["post", 2], p = ct["post", 4]),
      data.table::data.table(component = comp, quantity = "post-2010 drift (per yr)",
                             estimate = ct["yr_post", 1], se = ct["yr_post", 2], p = ct["yr_post", 4])))
  }
  data.table::rbindlist(list(
    one_trend("peak"), one_trend("trough"),
    one_nest("peak"), one_nest("trough")))
}
