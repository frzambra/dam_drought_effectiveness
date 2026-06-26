# Doubly-robust ATT on the entropy-balanced matched set (enhancement #2,
# docs/design/matched-controls.md). Combines the ebal weights with an outcome-regression
# adjustment so the estimate is consistent if EITHER the weights balance OR the outcome model
# is correct. Crucially, the outcome model includes `log_aridity`: ebal leaves a residual
# aridity SMD of ~0.17 (dammed basins are more arid and aridity could not be hard-balanced
# without collapsing ESS), and regression adjustment is the cheap way to absorb it.
#
# Three estimators are reported on the SAME matched sample so the reader sees the design's
# sensitivity to functional form:
#   1. weighting-only  : ebal-weighted difference in means (no covariate adjustment)
#   2. regression-only : covariate-adjusted, UNWEIGHTED (g-computation over treated units)
#   3. doubly-robust   : ebal-weighted AND covariate-adjusted (the headline)
# Agreement across the three is the credibility check; the DR estimate is the headline.

#' Doubly-robust ATT for the matched set on a unit-level outcome.
#'
#' Continuous covariates are centered at the TREATED-group mean, so the `treated` coefficient
#' in the (group-stratified) outcome model reads directly as the ATT at the treated covariate
#' profile. SEs are HC3 heteroskedasticity-robust, treating the ebal weights as fixed (the
#' standard ebal practice; weight-estimation uncertainty is not propagated — a known, slightly
#' anti-conservative simplification noted in the design doc).
#'
#' @param matched_set fit_matched_set() output (`data` carries unit_id, treated, w, covars,
#'                    kg_group)
#' @param outcome     data.table(unit_id, <outcome_col>) at the same grain
#' @param outcome_col name of the outcome column in `outcome` (default "trend")
#' @param covars      continuous covariates to adjust for (default log_area + elev_mean +
#'                    log_aridity); kg_group is always added as a stratum fixed effect
#' @return list(estimates = data.table(estimator, att, se, t, ci_lo, ci_hi, n_treated,
#'              n_control), models, data, outcome_col, covars)
fit_doubly_robust <- function(matched_set, outcome, outcome_col = "trend",
                              covars = c("log_area", "elev_mean", "log_aridity")) {
  d <- data.table::as.data.table(matched_set$data)
  o <- data.table::as.data.table(outcome)
  if (!outcome_col %in% names(o)) stop("outcome_col '", outcome_col, "' not in outcome")
  o <- o[, .(unit_id, y = get(outcome_col))]

  d <- merge(d, o, by = "unit_id")
  core <- dr_estimate(d, covars)
  c(core, list(outcome_col = outcome_col, covars = core$covars))
}

#' Core doubly-robust estimator on a pre-assembled unit-level frame.
#'
#' Shared by fit_doubly_robust() and the robustness battery (forcing_robustness.R) so every
#' scenario uses an identical estimator: the only thing that varies across scenarios is the
#' assembled frame (which weights `w`, which outcome `y`, which covariates, which subset).
#'
#' @param d      data.table/data.frame carrying `treated` (0/1), `y` (outcome), `w` (weights),
#'               the `covars` columns, and optionally `kg_group` (added as a stratum FE)
#' @param covars continuous covariates to adjust for (missing ones are silently dropped)
#' @return list(estimates, models, data, covars) — `estimates` has weighting_only /
#'         regression_only / doubly_robust rows with att, se, t, ci_lo, ci_hi, n_*
dr_estimate <- function(d, covars = c("log_area", "elev_mean", "log_aridity")) {
  d <- data.table::as.data.table(data.table::copy(d))
  if (!"w" %in% names(d)) stop("dr_estimate: frame must carry a weight column `w`")
  covars <- intersect(covars, names(d))
  d <- d[!is.na(y) & w > 0 & stats::complete.cases(d[, ..covars])]
  if (d[treated == 1L, .N] < 2L || d[treated == 0L, .N] < 2L)
    stop("too few treated/control units with outcome + covariates to estimate the ATT")

  # Center continuous covariates at the treated mean -> `treated` coef = ATT.
  tmean <- d[treated == 1L, lapply(.SD, mean), .SDcols = covars]
  for (v in covars) d[, (paste0(v, "_c")) := get(v) - tmean[[v]]]
  cv <- paste0(covars, "_c")

  has_groups <- "kg_group" %in% names(d) && data.table::uniqueN(d$kg_group) > 1L
  grp <- if (has_groups) " + kg_group" else ""
  f_adj <- stats::as.formula(paste("y ~ treated +", paste(cv, collapse = " + "), grp))

  df <- as.data.frame(d)
  m_w  <- stats::lm(y ~ treated, data = df, weights = df$w)          # weighting-only
  m_r  <- stats::lm(f_adj, data = df)                                # regression-only
  m_dr <- stats::lm(f_adj, data = df, weights = df$w)                # doubly-robust

  est_row <- function(name, m) {
    b  <- stats::coef(m)[["treated"]]
    se <- sqrt(sandwich::vcovHC(m, type = "HC3")["treated", "treated"])
    data.table::data.table(estimator = name, att = b, se = se, t = b / se,
                           ci_lo = b - 1.96 * se, ci_hi = b + 1.96 * se)
  }
  estimates <- data.table::rbindlist(list(
    est_row("weighting_only",  m_w),
    est_row("regression_only", m_r),
    est_row("doubly_robust",   m_dr)
  ))
  estimates[, `:=`(n_treated = d[treated == 1L, .N], n_control = d[treated == 0L, .N])]

  list(estimates = estimates[], models = list(w = m_w, r = m_r, dr = m_dr),
       data = d[], covars = covars)
}
