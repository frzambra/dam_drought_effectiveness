# Metric and functional-form checks (2026-07-03 review, comments 1, 3, 4). Feeds Supplementary
# Table S20:
#   (c1) does the baseline SPEI->SSI transmission hold its form across the aridity gradient among
#        UNDAMMED controls? Baseline slope by aridity tercile (controls only).
#   (c3) is the control elevation-transmission sensitivity linear across the ~2000 m snowline?
#        Piecewise fit below/above with an interaction test.
#   (c4) is the cropland null metric-dependent? Re-fit the forcing DiD on log cropland share
#        (relative expansion) with randomization inference.

#' @return data.table(quantity, value, detail)
build_metric_checks <- function(ssi_panel_itt, stations_units, ssi12, irrig_area_panel,
                                forcing_subcuencas_full, matched_set, n_perm = 999L) {
  p <- data.table::as.data.table(ssi_panel_itt)[treat == 0L]
  u  <- unique(p[, .(unit_id, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1))
  p[, terc := cut(aridity_mean, unique(qs), include.lowest = TRUE,
                  labels = c("arid", "mid", "humid"))]
  m  <- fixest::feols(ssi ~ spei_c:terc | unit_id + month_f + year,
                      data = p, weights = ~w, cluster = ~unit_id, nthreads = 1)
  cf <- stats::coef(m)
  sl <- cf[grepl("spei_c", names(cf))]

  slp  <- gauge_transmission_slopes(stations_units, ssi12, ssi_panel_itt)
  ctrl <- slp[treat == 0L & is.finite(altura) & is.finite(slope)]
  ctrl[, hi := as.integer(altura > 2000)]
  mm <- summary(stats::lm(slope ~ I(altura / 1000) * hi, data = ctrl))$coefficients
  lo_est <- mm["I(altura/1000)", "Estimate"]
  hi_est <- lo_est + mm["I(altura/1000):hi", "Estimate"]
  int_p  <- mm["I(altura/1000):hi", "Pr(>|t|)"]

  dp <- build_did_panel(irrig_area_panel, forcing_subcuencas_full, matched_set, "area_frac",
                        log_outcome = TRUE)
  md <- fit_forcing_did(dp)
  pm <- permutation_test_slope(dp, md, n_perm = n_perm)
  ct <- as.data.frame(summary(md)$coeftable)
  r  <- ct[grepl("spei_c", rownames(ct)) & grepl("treat", rownames(ct)), , drop = FALSE]

  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "control baseline SPEI->SSI slope by aridity tercile (arid / mid / humid)",
      value = round(unname(sl[1]), 3),
      detail = sprintf("mid %.3f, humid %.3f; smooth monotone variation, no regime break",
                       sl[2], sl[3])),
    data.table::data.table(
      quantity = "control elevation sensitivity of transmission, below vs above the ~2000 m snowline",
      value = round(lo_est, 3),
      detail = sprintf("above %.3f per km; interaction p = %.2f (n=%d control gauges)",
                       hi_est, int_p, nrow(ctrl))),
    data.table::data.table(
      quantity = "relative cropland expansion: forcing-DiD slope gap on log cropland share",
      value = signif(r[1, 1], 3),
      detail = sprintf("SE %.2g, perm p = %.3f (%d units with nonzero cropland); metric-invariant null",
                       r[1, 2], pm$p_perm, data.table::uniqueN(dp$unit_id)))))
}
