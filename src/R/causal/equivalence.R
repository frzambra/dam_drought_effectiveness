# Equivalence testing / minimum-detectable-effect (MDE) for the headline nulls, and the
# naive-vs-design siting-confound decomposition. Addresses Nature Water review (2026-06-28)
# Required Analyses #1 (TOST/MDE — the #1 blocker: convert "no effect" into "we can rule out effects
# larger than X") and #5 (quantify how much of the naive dammed-vs-control buffering is siting).
#
# The honest standard error for ~17-24 treated CLUSTERS is the spread of the PERMUTATION null
# distribution (cluster-robust SEs over-reject and would understate the MDE). So MDE and the
# equivalence CI are built from the permutation-null SD, not the analytic SE.

#' Generic slope-gap coefficient (treat x SPEI), robust to fixest interaction naming.
.gap_coef <- function(model) {
  cf <- stats::coef(model); nm <- names(cf)
  hit <- nm[grepl("spei", nm, ignore.case = TRUE) & grepl("treat", nm) & !grepl("irr_share", nm)]
  if (length(hit) != 1L) return(NA_real_); unname(cf[hit])
}

#' Baseline (untreated) forcing->impact transmission slope = the SPEI main-effect coefficient.
.baseline_slope <- function(model) {
  cf <- stats::coef(model); nm <- names(cf)
  hit <- nm[grepl("spei_c$", nm) | (grepl("^spei", nm, ignore.case = TRUE) & !grepl("treat", nm) &
                                    !grepl("rising|irr_share", nm))]
  if (!length(hit)) return(NA_real_); unname(cf[hit[1]])
}

#' Permutation NULL DISTRIBUTION of the slope-gap (treatment permuted within kg_group x aridity
#' tercile), returned in full so we can take its SD for MDE/equivalence. Parallel, fixest single-
#' threaded inside forks.
perm_null_dist <- function(panel, fitfun, coeffun = .gap_coef, n_perm = 1000L, seed = 1L) {
  fixest::setFixest_nthreads(1L)                          # forks inherit; avoid OMP oversubscription
  d <- data.table::as.data.table(panel)
  u <- unique(d[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base <- d[, !c("treat"), with = FALSE]
  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    dp <- merge(base, up[, .(unit_id, treat)], by = "unit_id")
    tryCatch(coeffun(fitfun(dp)), error = function(e) NA_real_)
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  unlist(parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore), use.names = FALSE)
}

#' Equivalence + MDE summary for one headline null.
#'
#' MDE = smallest slope-gap detectable at `power` (two-sided alpha), using the permutation-null SD.
#' Equivalence margin delta = `delta_frac` x |baseline slope| (a buffering effect that attenuates the
#' deficit->impact transmission by delta_frac). TOST-style verdict: equivalent to zero if the 90% CI
#' (observed +- 1.645*SD, i.e. the two one-sided 0.05 tests) lies inside (-delta, +delta).
#'
#' @return data.table(outcome, observed, baseline, null_sd, mde, mde_pct_of_baseline, delta,
#'                    delta_pct, ci90_lo, ci90_hi, equivalent, p_perm)
equivalence_summary <- function(outcome, observed, baseline, null_vec,
                                delta_frac = 0.25, power = 0.8, alpha = 0.05) {
  s   <- stats::sd(null_vec, na.rm = TRUE)
  mde <- (stats::qnorm(1 - alpha / 2) + stats::qnorm(power)) * s
  delta <- delta_frac * abs(baseline)
  z90 <- stats::qnorm(1 - alpha)                          # 1.645 for TOST two one-sided tests
  ci_lo <- observed - z90 * s; ci_hi <- observed + z90 * s
  nv <- sum(!is.na(null_vec))
  data.table::data.table(
    outcome = outcome, observed = observed, baseline = baseline, null_sd = s,
    mde = mde, mde_pct_of_baseline = 100 * mde / abs(baseline),
    delta = delta, delta_pct = 100 * delta_frac,
    ci90_lo = ci_lo, ci90_hi = ci_hi,
    equivalent = (ci_lo > -delta) & (ci_hi < delta),
    p_perm = (1 + sum(abs(null_vec) >= abs(observed), na.rm = TRUE)) / (1 + nv))
}

#' SITING-CONFOUND DECOMPOSITION (#5): how much of the apparent dammed-vs-control buffering is
#' siting/aridity vs a regulation effect? Fits a ladder of estimators on the same panel:
#'   (1) NAIVE   — pooled OLS slope gap, no weights, no FE (what a dammed-vs-undammed study reports)
#'   (2) +unit & time FE (calendar-time-ish control, still unweighted)
#'   (3) DESIGN  — entropy-balance weights + unit + time FE (the forcing-conditioned estimand)
#' The shrinkage (1)->(3) is the siting confound; the residual at (3) is the regulation estimate.
#' @param panel a forcing panel with: outcome `yvar`, spei_c, treat, w, unit_id, time FE col `timevar`
#' @return data.table(estimator, slope_gap, se)
siting_decomposition <- function(panel, yvar = "ssi", timevar = "month_f") {
  d <- data.table::copy(data.table::as.data.table(panel))
  data.table::setnames(d, yvar, "y_")
  f_naive <- stats::as.formula("y_ ~ spei_c * treat")
  f_fe    <- stats::as.formula(sprintf("y_ ~ spei_c + treat:spei_c | unit_id + %s + year", timevar))
  m1 <- fixest::feols(f_naive, data = d, cluster = ~unit_id)
  m2 <- fixest::feols(f_fe, data = d, cluster = ~unit_id)
  m3 <- fixest::feols(f_fe, data = d, weights = ~w, cluster = ~unit_id)
  grab <- function(m, lab) {
    ct <- as.data.frame(summary(m)$coeftable)
    r <- ct[grepl("spei", rownames(ct), ignore.case = TRUE) & grepl("treat", rownames(ct)), ,
            drop = FALSE]
    data.table::data.table(estimator = lab, slope_gap = r[1, 1], se = r[1, 2])
  }
  data.table::rbindlist(list(grab(m1, "naive (no match, no FE)"),
                             grab(m2, "unit+time FE (unweighted)"),
                             grab(m3, "design (ebal + FE)")))
}
