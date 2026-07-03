# Hard-balanced (aridity-targeted) sensitivity of the headline nulls (Reviewer 3 round 3,
# comment 1). The primary design leaves a residual aridity imbalance to the doubly-robust outcome
# model; the reviewer asks for a strict matched analysis with aridity hard-balanced (ESS ~19) to
# show the nulls hold WITHOUT parametric extrapolation across the hydroclimatic regime gap. Feeds
# Supplementary Table S17.

#' @param matched_set_hard fit_matched_set_hard() output
#' @return data.table(quantity, value, detail)
build_hard_balance_check <- function(matched_set_hard, ssi12, streamflow_stations,
                                     spei12_monthly, irrig_area_panel,
                                     forcing_subcuencas_full, water_rights_panel,
                                     n_perm = 1000L) {
  ms <- matched_set_hard
  d  <- data.table::as.data.table(ms$data)
  wc <- d[treated == 0L, w]
  ess_c <- sum(wc)^2 / sum(wc^2)                       # weighted control ESS (Kish)
  smd <- (d[treated == 1L, mean(log_aridity)] -
          d[treated == 0L, sum(w * log_aridity) / sum(w)]) / d[treated == 1L, stats::sd(log_aridity)]

  p_itt <- build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, ms, "itt")
  m_itt <- fit_ssi_buffering(p_itt)
  pm_itt <- permute_ssi_buffer(p_itt, n_perm = n_perm)
  p_up  <- build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, ms, "up")
  m_up  <- fit_ssi_buffering(p_up)
  pm_up <- permute_ssi_buffer(p_up, n_perm = n_perm)
  coef_se <- function(m) {
    ct <- as.data.frame(summary(m)$coeftable)
    r <- ct[grepl("spei_c", rownames(ct)) & grepl("treat", rownames(ct)), , drop = FALSE]
    c(r[1, 1], r[1, 2])
  }
  ci <- coef_se(m_itt); cu <- coef_se(m_up)

  dp <- build_did_panel(irrig_area_panel, forcing_subcuencas_full, ms, "area_frac",
                        log_outcome = FALSE)
  m_a <- fit_forcing_did(dp)
  pm_a <- permutation_test_slope(dp, m_a, n_perm = n_perm)
  ca <- coef_se(m_a)

  wr <- wr_expansion_summary(water_rights_panel, ms$data)
  aw <- data.table::as.data.table(
    fit_wr_expansion_att(ms, wr)$estimates)[estimator == "weighting_only"]
  pw <- permute_wr_att(ms, wr, n_perm = n_perm)

  data.table::rbindlist(list(
    data.table::data.table(quantity = "effective control sample size (aridity hard-balanced)",
      value = round(ess_c, 1),
      detail = sprintf("log-aridity SMD after balancing %.3f (residual 0.17 in the primary design)", smd)),
    data.table::data.table(quantity = "streamflow treat x SPEI, ITT",
      value = round(ci[1], 3),
      detail = sprintf("SE %.3f, perm p = %.3f (%d perms); primary design -0.183", ci[2], pm_itt$p_perm, pm_itt$n_perm)),
    data.table::data.table(quantity = "streamflow treat x SPEI, upstream placebo",
      value = round(cu[1], 3),
      detail = sprintf("SE %.3f, perm p = %.3f; primary design -0.20", cu[2], pm_up$p_perm)),
    data.table::data.table(quantity = "cropland-area DiD slope gap",
      value = signif(ca[1], 3),
      detail = sprintf("SE %.2g, perm p = %.3f; primary design perm p = 0.91", ca[2], pm_a$p_perm)),
    data.table::data.table(quantity = "water-rights expansion ATT (weighting-only, per 100 km2)",
      value = round(aw$att, 1),
      detail = sprintf("95%% CI [%.1f, %.1f], perm p = %.3f", aw$ci_lo, aw$ci_hi, pw$p_perm))))
}
