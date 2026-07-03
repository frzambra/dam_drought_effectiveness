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

#' Build the equivalence / MDE table over the INTERPRETABLE null outcomes (Nature Water review
#' #1/#3 — makes the previously orphan `table_equivalence.csv` a reproducible pipeline target).
#' Whole-basin ET is deliberately omitted: its event-study pre-trends fail, so an equivalence bound
#' on a confounded estimate would be meaningless (see Results). For each outcome we fit the model,
#' take the observed slope gap and the baseline (untreated) transmission slope, and build the
#' permutation-null distribution for the MDE/equivalence interval.
#' @param ssi_panel_itt,ssi_panel_down build_ssi_panel() outputs (streamflow)
#' @param did_panel_area,did_panel_orch build_did_panel() outputs (irrigated area, orchard ET)
#' @param n_perm permutations for the null distribution
#' @return data.table (equivalence_summary columns), one row per outcome
build_equivalence_table <- function(ssi_panel_itt, ssi_panel_down,
                                    did_panel_area, did_panel_orch, n_perm = 1000L) {
  one <- function(outcome, panel, fitfun, coeffun) {
    m  <- fitfun(panel)
    nd <- perm_null_dist(panel, fitfun, coeffun = coeffun, n_perm = n_perm)
    equivalence_summary(outcome, observed = coeffun(m),
                        baseline = .baseline_slope(m), null_vec = nd)
  }
  data.table::rbindlist(list(
    one("streamflow SSI (ITT)",        ssi_panel_itt,  fit_ssi_buffering, ssi_buffer_coef),
    one("streamflow SSI (downstream)", ssi_panel_down, fit_ssi_buffering, ssi_buffer_coef),
    one("irrigated area (DiD)",        did_panel_area, fit_forcing_did,   .gap_coef),
    one("orchard ET (DiD)",            did_panel_orch, fit_forcing_did,   .gap_coef)))
}

#' Pre-trend MDE (Reviewer 3, 2026-07-02 comment 5). The flat pre-2010 differential cropland trend
#' (p = 0.65) is only informative if the design could have detected a divergent pre-trend, so we
#' hold it to the same standard as the headline nulls: the MDE built from the permutation-null SD
#' of the pre-window treat:year slope, reported per year and cumulated over the pre-window as a
#' share of the control cropland level.
#' @param did_panel build_did_panel() output for area_frac
#' @return data.table(quantity, value, detail)
build_pretrend_mde <- function(did_panel, ref_year = 2009L, n_perm = 1000L) {
  d <- data.table::as.data.table(did_panel)[year <= ref_year]
  fitfun <- function(p) fixest::feols(y ~ treat:year | unit_id + year, data = p, weights = ~w,
                                      nthreads = 1)
  cfun <- function(m) {
    cf <- stats::coef(m); hit <- names(cf)[grepl("treat", names(cf)) & grepl("year", names(cf))]
    if (length(hit) != 1L) return(NA_real_); unname(cf[hit])
  }
  obs <- cfun(fitfun(d))
  nd  <- perm_null_dist(d, fitfun, coeffun = cfun, n_perm = n_perm)
  s   <- stats::sd(nd, na.rm = TRUE)
  mde <- (stats::qnorm(0.975) + stats::qnorm(0.8)) * s
  p_perm <- (1 + sum(abs(nd) >= abs(obs), na.rm = TRUE)) / (1 + sum(!is.na(nd)))
  yrs <- diff(range(d$year))
  ctrl_lvl <- d[treat == 0L, stats::weighted.mean(y, w)]
  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "pre-2010 differential cropland trend (treat:year, basin fraction per yr)",
      value = signif(obs, 3),
      detail = sprintf("perm p = %.2f (%d perms); window %d-%d", p_perm, sum(!is.na(nd)),
                       min(d$year), ref_year)),
    data.table::data.table(
      quantity = "pre-trend MDE (80% power, alpha = 0.05, basin fraction per yr)",
      value = signif(mde, 3),
      detail = sprintf("permutation-null SD %.2g", s)),
    data.table::data.table(
      quantity = "cumulative detectable pre-2010 divergence (% of control cropland level)",
      value = round(100 * mde * yrs / ctrl_lvl, 1),
      detail = sprintf("MDE x %d yr against control weighted mean fraction %.4f", yrs, ctrl_lvl))))
}

#' Physical-volume context for the +-25% equivalence margin (Reviewer 3 round 2, comment 4).
#' The margin's maximal SSI perturbation (0.25 x 0.585 x 1.98 ~ 0.29 SSI units at the worst observed
#' deficit) is translated into streamflow volume per treated DOWNSTREAM gauge: the within-gauge
#' linear sensitivity of the 12-month rolling mean flow to its SSI (m3/s per SSI unit) x delta_ssi,
#' expressed in hm3 over a 12-month season and as % of mean annual flow. The linear sensitivity is
#' an average, not a dry-tail, mapping; the flow-SSI curve flattens in the dry tail, so these
#' volumes OVERSTATE the worst-drought case (conservative for the reviewer's concern).
#' @return data.table(quantity, value, detail)
equivalence_volume_context <- function(streamflow_monthly, stations_units, ssi12,
                                       delta_ssi = 0.29, accum = 12L) {
  su <- data.table::as.data.table(stations_units)[treat == 1L & regulated == "down"]
  d  <- data.table::as.data.table(streamflow_monthly)
  data.table::setorder(d, codigo, year, month)
  d[, roll := data.table::frollmean(q_mon, accum, align = "right"), by = codigo]
  m <- merge(d, data.table::as.data.table(ssi12), by = c("codigo", "year", "month"))
  m <- m[codigo %in% su$codigo & is.finite(roll) & is.finite(ssi)]
  per <- m[, .(sens = stats::coef(stats::lm(roll ~ ssi))[2L], qbar = mean(roll)), by = codigo]
  per <- per[is.finite(sens) & sens > 0]
  per[, `:=`(vol_hm3 = sens * delta_ssi * 31.536,          # m3/s sustained one year -> hm3
             pct = 100 * sens * delta_ssi / qbar)]
  qt <- function(x, p) stats::quantile(x, p, names = FALSE)
  data.table::data.table(
    quantity = c("equivalence-margin volume, treated downstream gauges (hm3 per 12-month season)",
                 "equivalence-margin volume as % of mean annual flow"),
    value  = c(round(stats::median(per$vol_hm3), 1), round(stats::median(per$pct), 1)),
    detail = c(sprintf("median across %d gauges; IQR [%.1f, %.1f]; flow-SSI sensitivity x %.2f SSI x 31.5; linear (average) sensitivity overstates the dry-tail volume",
                       nrow(per), qt(per$vol_hm3, .25), qt(per$vol_hm3, .75), delta_ssi),
               sprintf("IQR [%.1f, %.1f]%%", qt(per$pct, .25), qt(per$pct, .75))))
}

#' SITING-CONFOUND DECOMPOSITION (#5): how much of the apparent dammed-vs-control buffering is
#' siting/aridity vs a regulation effect? Fits a ladder of estimators on the same panel:
#'   (1) NAIVE   — pooled OLS slope gap, no weights, no FE (what a dammed-vs-undammed study reports)
#'   (2) +unit & time FE (calendar-time-ish control, still unweighted)
#'   (3) DESIGN  — entropy-balance weights + unit + time FE (the forcing-conditioned estimand)
#' The shrinkage (1)->(3) is the siting confound; the residual at (3) is the regulation estimate.
#' Optional rung (4) lets the SPEI->outcome baseline slope vary by climate region (`region_var`,
#' e.g. Köppen main group), so treat:spei_c is identified only from WITHIN-region dammed-vs-control
#' contrasts. If the apparent buffering is a between-region aridity confound, it collapses here even
#' though rungs (1)-(3) leave it intact.
#' @param panel a forcing panel with: outcome `yvar`, spei_c, treat, w, unit_id, time FE col `timevar`
#' @param region_var optional column (e.g. "kg_group") for the within-region rung; skipped if absent
#' @return data.table(estimator, rung, slope_gap, se)
siting_decomposition <- function(panel, yvar = "ssi", timevar = "month_f",
                                 region_var = "kg_group") {
  d <- data.table::copy(data.table::as.data.table(panel))
  data.table::setnames(d, yvar, "y_")
  # Time FE: monthly panels carry an intra-year season factor (month_f) on top of year; annual
  # panels (e.g. the DiD outcomes) have only year. Include timevar only when it is present.
  fe <- c("unit_id", if (!is.null(timevar) && timevar %in% names(d)) timevar, "year")
  f_naive <- stats::as.formula("y_ ~ spei_c * treat")
  f_fe    <- stats::as.formula(paste0("y_ ~ spei_c + treat:spei_c | ", paste(fe, collapse = " + ")))
  m1 <- fixest::feols(f_naive, data = d, cluster = ~unit_id)
  m2 <- fixest::feols(f_fe, data = d, cluster = ~unit_id)
  m3 <- fixest::feols(f_fe, data = d, weights = ~w, cluster = ~unit_id)
  grab <- function(m, lab, rung) {
    ct <- as.data.frame(summary(m)$coeftable)
    r <- ct[grepl("spei", rownames(ct), ignore.case = TRUE) & grepl("treat", rownames(ct)), ,
            drop = FALSE]
    data.table::data.table(estimator = lab, rung = rung, slope_gap = r[1, 1], se = r[1, 2])
  }
  out <- list(grab(m1, "naive (no match, no FE)", 1L),
              grab(m2, "unit+time FE (unweighted)", 2L),
              grab(m3, "design (ebal + FE)", 3L))
  if (!is.null(region_var) && region_var %in% names(d) &&
      data.table::uniqueN(d[[region_var]]) > 1L) {
    f_reg <- stats::as.formula(paste0("y_ ~ spei_c + treat:spei_c + spei_c:", region_var,
                                      " | ", paste(fe, collapse = " + ")))
    m4 <- fixest::feols(f_reg, data = d, weights = ~w, cluster = ~unit_id)
    out[[length(out) + 1L]] <- grab(m4, "design + within region", 4L)
  }
  data.table::rbindlist(out)
}

#' Aridity-overlap sensitivity: re-estimate the key results on the sub-sample of basins whose baseline
#' log-aridity lies in the treated/control overlap band, to show the parametric aridity adjustment is
#' not masking a true effect where common support is genuine. Reports the streamflow transmission slope
#' gap and the water-rights expansion ATT on the full set vs the overlap subset.
#' @return data.table(quantity, full, overlap, overlap_ci_lo, overlap_ci_hi, n_treated, n_control)
aridity_overlap_sensitivity <- function(matched_set, ssi_panel_itt, wr_expansion) {
  md <- data.table::as.data.table(matched_set$data)
  lo <- max(md[treated == 1L, min(log_aridity)], md[treated == 0L, min(log_aridity)])
  hi <- min(md[treated == 1L, max(log_aridity)], md[treated == 0L, max(log_aridity)])
  ov <- md[log_aridity >= lo & log_aridity <= hi]
  dp  <- data.table::as.data.table(ssi_panel_itt)
  sl_full <- ssi_buffer_coef(fit_ssi_buffering(dp))
  sl_ov   <- ssi_buffer_coef(fit_ssi_buffering(dp[unit_id %in% ov$unit_id]))
  mso <- matched_set; mso$data <- ov
  a <- data.table::as.data.table(
    fit_wr_expansion_att(mso, data.table::as.data.table(wr_expansion)[unit_id %in% ov$unit_id]
                         )$estimates)[estimator == "doubly_robust"]
  af <- data.table::as.data.table(fit_wr_expansion_att(matched_set, wr_expansion)$estimates)[
    estimator == "doubly_robust"]
  data.table::data.table(
    quantity = c("Streamflow SPEI->SSI slope gap", "Water-rights expansion ATT"),
    full = c(sl_full, af$att), overlap = c(sl_ov, a$att),
    overlap_ci_lo = c(NA_real_, a$ci_lo), overlap_ci_hi = c(NA_real_, a$ci_hi),
    n_treated = ov[treated == 1L, .N], n_control = ov[treated == 0L, .N])
}

#' Assemble the siting-confound ladder across outcomes for the manuscript figure.
#'
#' Runs siting_decomposition() (naive -> +FE -> design -> +within-region) on the streamflow SSI
#' transmission slope and the two DiD proxy outcomes, then appends the within-basin UPSTREAM PLACEBO
#' (design estimator on unregulated above-dam gauges) as the decisive comparator for streamflow: if
#' the residual attenuation were regulation it should vanish upstream, not persist. The design and
#' placebo rows carry the randomization-inference p (the design's valid inference).
#' @return data.table(outcome, estimator, rung, slope_gap, se, perm_p, placebo)
build_siting_ladder <- function(ssi_panel_itt, did_panel_area, did_panel_orch,
                                streamflow_summary, did_summary) {
  lad <- function(panel, yv, outcome) {
    r <- siting_decomposition(panel, yvar = yv); r[, outcome := outcome]; r[]
  }
  tab <- data.table::rbindlist(list(
    lad(ssi_panel_itt,  "ssi", "Streamflow SSI (SPEI->SSI slope)"),
    lad(did_panel_area, "y",   "Irrigated area (DiD)"),
    lad(did_panel_orch, "y",   "Orchard ET (DiD)")))
  tab[, `:=`(perm_p = NA_real_, placebo = FALSE)]

  ss <- data.table::as.data.table(streamflow_summary)
  ds <- data.table::as.data.table(did_summary)
  # perm p on the DESIGN rung (rung 3), from each outcome's design-based inference
  tab[outcome %like% "Streamflow" & rung == 3L, perm_p := ss[subset == "ITT", perm_p]]
  tab[outcome %like% "Irrigated area" & rung == 3L, perm_p := ds[spec == "area_frac", p_perm]]
  tab[outcome %like% "Orchard ET" & rung == 3L, perm_p := ds[spec == "log_orchard_ET", p_perm]]

  up <- ss[subset == "upstream placebo"]
  placebo_row <- data.table::data.table(
    outcome = "Streamflow SSI (SPEI->SSI slope)", estimator = "upstream placebo (unregulated)",
    rung = 5L, slope_gap = up$treat_spei_c, se = up$se, perm_p = up$perm_p, placebo = TRUE)
  data.table::rbindlist(list(tab, placebo_row), use.names = TRUE)
}
