# Forcing-conditioned ATT (Lever 1, docs/conceptual_framework/identification-strategy.md).
#
# The matched-set DR ATT (dr_att) is on the storage-era zNPP TREND — a slope on CALENDAR TIME.
# Because the 2010+ mega-drought is collinear with where reservoirs sit (arid central Chile),
# that trend conflates reservoir EFFECT with drought EXPOSURE (threat T1). The fix:
#
#   1. Per subcuenca, regress the annual ecological anomaly (zNPP) on the annual meteorological
#      forcing (SPEI) -> the deficit->impact RESPONSE SLOPE (a "transmission coefficient").
#      Both series are standardized anomalies, so the slope is a dimensionless, cross-basin
#      drought-transmission elasticity, NOT a calendar-time trend.
#   2. Make that slope the OUTCOME of the existing doubly-robust matched-set estimator.
#
# The contrast then reads: holding climate (matched) AND realized forcing (the regressor)
# fixed, do dammed basins transmit meteorological deficit into ecological impact with a
# different slope than matched controls? Calendar time cannot mimic this. A reservoir that
# buffers should FLATTEN the slope (less impact per unit deficit); induced-demand exhaustion
# (H2) predicts a STEEPER slope once the buffer is spent.

#' Merge the per-unit-year ecological panel with the per-unit-year forcing into one panel.
#'
#' Inner join on (unit_id, year): a unit-year contributes only if BOTH the outcome anomaly and
#' the forcing exist that year. `lag` shifts the forcing to lead the outcome by N years (the
#' outcome year is matched to forcing from `lag` years earlier); default 0 (contemporaneous,
#' since SPEI-12 already integrates the year's water balance and annual NPP responds within
#' the season).
#'
#' @param index_annual  extract_unit_index_annual() output (unit_id, year, level)
#' @param forcing_annual extract_unit_forcing_annual() output (unit_id, year, forcing)
#' @param lag           years the forcing leads the outcome (default 0)
#' @return data.table(unit_id, year, level, forcing)
build_response_panel <- function(index_annual, forcing_annual, lag = 0L) {
  o <- data.table::as.data.table(index_annual)[, .(unit_id, year, level)]
  f <- data.table::as.data.table(forcing_annual)[, .(unit_id, year, forcing)]
  if (lag != 0L) f[, year := year + lag]         # forcing from `lag` years earlier
  p <- merge(o, f, by = c("unit_id", "year"))
  data.table::setorder(p, unit_id, year)
  p[]
}

#' Per-unit deficit->impact response slope (the transmission coefficient).
#'
#' Within each unit, OLS `level ~ forcing`; the slope is the outcome. A reliable slope needs
#' both enough years AND enough spread in the forcing (a unit that barely varied in SPEI yields
#' an ill-determined slope) — units failing either get NA and drop out of the ATT. Carries the
#' realized forcing summaries (mean, spread, slope SE, R^2) as diagnostics so the reader can
#' see the slope is identified off real forcing variation, not noise.
#'
#' @param panel             build_response_panel() output
#' @param min_years         minimum unit-years to fit a slope (default 10)
#' @param min_forcing_range minimum max-min SPEI spread within the unit (default 1.0; one full
#'                          standardized unit, so the slope spans at least a meaningful deficit)
#' @return data.table(unit_id, resp_slope, resp_slope_se, intercept, r2,
#'                    forcing_mean, forcing_sd, forcing_range, n_years)
fit_response_slopes <- function(panel, min_years = 10L, min_forcing_range = 1.0) {
  p <- data.table::as.data.table(panel)
  per <- p[, {
    rng <- if (.N) diff(range(forcing)) else NA_real_
    if (.N >= min_years && data.table::uniqueN(year) >= 3L &&
        is.finite(rng) && rng >= min_forcing_range && stats::sd(forcing) > 0) {
      fit <- stats::lm(level ~ forcing)
      sm  <- summary(fit)
      .(resp_slope    = unname(stats::coef(fit)[["forcing"]]),
        resp_slope_se = unname(sm$coefficients["forcing", "Std. Error"]),
        intercept     = unname(stats::coef(fit)[["(Intercept)"]]),
        r2            = sm$r.squared,
        forcing_mean  = mean(forcing), forcing_sd = stats::sd(forcing),
        forcing_range = rng, n_years = .N)
    } else {
      .(resp_slope = NA_real_, resp_slope_se = NA_real_, intercept = NA_real_,
        r2 = NA_real_, forcing_mean = if (.N) mean(forcing) else NA_real_,
        forcing_sd = if (.N) stats::sd(forcing) else NA_real_,
        forcing_range = rng, n_years = .N)
    }
  }, by = unit_id]
  data.table::setorder(per, unit_id)
  per[]
}

#' Forcing-conditioned ATT: the doubly-robust matched-set estimator on the response slope.
#'
#' Thin wrapper over fit_doubly_robust() so the forcing-conditioned estimand reuses the exact
#' same ebal weights, covariate adjustment (log_aridity etc.), and three-estimator credibility
#' check as the trend-based dr_att — only the outcome differs (transmission slope vs calendar
#' trend). Reporting both side by side shows how much of the trend-based ATT was mega-drought
#' exposure: if the forcing-conditioned ATT collapses toward zero, the raw-trend signal was
#' largely exposure, not a reservoir effect.
#'
#' @param matched_set fit_matched_set() output
#' @param response_slopes fit_response_slopes() output
#' @param covars      outcome-model covariates (default as in fit_doubly_robust)
#' @return fit_doubly_robust() result on outcome_col = "resp_slope"
fit_forcing_conditioned_att <- function(matched_set, response_slopes,
                                        covars = c("log_area", "elev_mean", "log_aridity")) {
  fit_doubly_robust(matched_set, response_slopes, outcome_col = "resp_slope",
                    covars = covars)
}

#' Land-cover-stratified forcing-conditioned ATT — the decisive aridity-vs-mechanism test.
#'
#' Runs the forcing-conditioned ATT SEPARATELY on the agricultural-cover and natural-cover
#' transmission slopes (from stratified_znpp_annual()). The contrast is the whole point:
#'   - ATT(agri) > 0 with ATT(natural) ≈ 0  ⇒ the steeper dammed-basin slope is a
#'     reservoir/land-use (H2) effect — reservoirs water crops, not native vegetation.
#'   - ATT(agri) ≈ ATT(natural)             ⇒ it is a baseline-aridity/water-limitation
#'     artefact (which hits both covers), NOT reservoir-specific.
#' Comparing within a cover class also holds water-demand regime roughly fixed, sidestepping
#' the aridity confound that moved the basin-mean estimate (the aridity² robustness scenario).
#'
#' @param matched_set  fit_matched_set() output
#' @param znpp_strat   stratified_znpp_annual() output (unit_id, year, level, stratum, n_cells)
#' @param forcing      extract_unit_forcing_annual() output (the SPEI forcing)
#' @param lag          forcing lead in years (default 0)
#' @param covars       outcome-model covariates
#' @return list(table = stratum x DR-ATT comparison, slopes = per-stratum response_slopes,
#'              group_means = treated/control mean slope per stratum)
fit_stratified_forcing_att <- function(matched_set, znpp_strat, forcing, lag = 0L,
                                       covars = c("log_area", "elev_mean", "log_aridity")) {
  zs <- data.table::as.data.table(znpp_strat)
  strata <- sort(unique(zs$stratum))
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, treated, w)]

  rows <- list(); slope_tabs <- list(); gmeans <- list()
  for (st in strata) {
    panel  <- build_response_panel(zs[stratum == st, .(unit_id, year, level)], forcing, lag = lag)
    slopes <- fit_response_slopes(panel)
    slope_tabs[[st]] <- slopes

    fit <- tryCatch(
      fit_doubly_robust(matched_set, slopes, outcome_col = "resp_slope", covars = covars),
      error = function(e) e)
    if (inherits(fit, "error")) {
      rows[[st]] <- data.table::data.table(stratum = st, att = NA_real_, se = NA_real_,
        t = NA_real_, ci_lo = NA_real_, ci_hi = NA_real_, n_treated = NA_integer_,
        n_control = NA_integer_, note = conditionMessage(fit))
      next
    }
    e <- fit$estimates[estimator == "doubly_robust"]
    rows[[st]] <- data.table::data.table(stratum = st, att = e$att, se = e$se, t = e$t,
      ci_lo = e$ci_lo, ci_hi = e$ci_hi, n_treated = e$n_treated, n_control = e$n_control,
      note = "")

    g <- merge(ms, slopes[, .(unit_id, resp_slope)], by = "unit_id")[!is.na(resp_slope)]
    gmeans[[st]] <- data.table::data.table(stratum = st,
      treated_mean  = g[treated == 1L, mean(resp_slope)],
      control_mean  = g[treated == 0L, mean(resp_slope)],
      control_wmean = g[treated == 0L, stats::weighted.mean(resp_slope, w)])
  }

  list(table       = data.table::rbindlist(rows, use.names = TRUE)[],
       slopes      = slope_tabs,
       group_means = data.table::rbindlist(gmeans, use.names = TRUE)[])
}
