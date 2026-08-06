# Validation of the within-basin upstream/downstream streamflow placebo (Reviewer #2 asks):
#   (1) COMPARABILITY — upstream gauges sit higher than downstream gauges, so "up ~ down" could be
#       an elevation/snow-regime artifact rather than absence of regulation. We quantify the
#       elevation gap and then test whether gauge elevation actually drives the SPEI->SSI
#       transmission slope among UNDAMMED control gauges. If it does not, the up/down elevation
#       difference cannot manufacture a spurious slope gap, defending the placebo despite the gap.
#   (2) POSITIVE CONTROL — a null is only credible if the design could detect a true effect. We
#       inject a known buffering slope into the treated downstream units and confirm the estimator
#       recovers it and that randomization inference rejects once the effect exceeds the MDE.

#' Per-gauge SPEI->SSI transmission slope, with gauge elevation and up/down/control class.
#' @param stations_units assign_stations_to_units() output (codigo, unit_id, treat, altura, regulated)
#' @param ssi12 compute_ssi() output (codigo, year, month, ssi)
#' @param ssi_panel any build_ssi_panel() output — used only to recover per-unit SPEI (unit_id, year, month, spei)
#' @param min_months minimum gauge-months to fit a slope (default 60)
#' @return data.table(codigo, unit_id, treat, regulated, altura, slope, n)
gauge_transmission_slopes <- function(stations_units, ssi12, ssi_panel, min_months = 60L) {
  su   <- data.table::as.data.table(stations_units)
  ssi  <- data.table::as.data.table(ssi12)
  uspei <- unique(data.table::as.data.table(ssi_panel)[, .(unit_id, year, month, spei)])
  g <- merge(ssi, su[, .(codigo, unit_id, treat, altura, regulated)], by = "codigo")
  g <- merge(g, uspei, by = c("unit_id", "year", "month"))
  g <- g[is.finite(ssi) & is.finite(spei)]
  g[, if (.N >= min_months)
       .(slope = stats::coef(stats::lm(ssi ~ spei))[2L], n = .N,
         unit_id = unit_id[1L], altura = altura[1L],
         treat = treat[1L], regulated = regulated[1L]),
    by = codigo]
}

#' (1) Placebo comparability: up vs down gauge attributes + the elevation-confound test on controls.
#' @return data.table with rows for the up/down attribute contrast and the control slope~elevation test
ssi_placebo_comparability <- function(stations_units, ssi12, ssi_panel) {
  slp <- gauge_transmission_slopes(stations_units, ssi12, ssi_panel)

  ud <- slp[treat == 1L & regulated %in% c("up", "down"),
            .(n_gauges = .N, elev_mean_m = round(mean(altura, na.rm = TRUE)),
              transmission_mean = round(mean(slope, na.rm = TRUE), 3)), by = regulated]

  # Decisive check: among UNDAMMED controls, does gauge elevation predict the transmission slope?
  ctrl <- slp[treat == 0L & is.finite(altura) & is.finite(slope)]
  m  <- stats::lm(slope ~ I(altura / 1000), data = ctrl)         # slope change per +1000 m
  ct <- summary(m)$coefficients["I(altura/1000)", ]

  data.table::rbindlist(list(
    data.table::data.table(quantity = "upstream gauges (elev, mean m)",
                           value = ud[regulated == "up", elev_mean_m],
                           detail = sprintf("n=%d; mean transmission %.3f",
                                            ud[regulated == "up", n_gauges],
                                            ud[regulated == "up", transmission_mean])),
    data.table::data.table(quantity = "downstream gauges (elev, mean m)",
                           value = ud[regulated == "down", elev_mean_m],
                           detail = sprintf("n=%d; mean transmission %.3f",
                                            ud[regulated == "down", n_gauges],
                                            ud[regulated == "down", transmission_mean])),
    data.table::data.table(
      quantity = "control transmission slope vs elevation (per +1000 m)",
      value = round(ct[["Estimate"]], 3),
      detail = sprintf("p = %.2f (n=%d control gauges); elevation predicts transmission, so the up/down gap is bounded with this sensitivity rather than assumed away",
                       ct[["Pr(>|t|)"]], nrow(ctrl)))))
}

#' (2) Positive control: inject a known buffering slope into treated units, confirm recovery + power.
#' For each injected beta, ssi := ssi + beta * treat * spei_c, then re-fit the buffering model and
#' run randomization inference. beta=0 reproduces the real (null) estimate; more-negative beta is a
#' stronger true buffering effect. Detection at |effect| beyond the MDE validates the design's power.
#' @param ssi_panel build_ssi_panel(..., "down") output
#' @param betas injected treat:spei_c increments (negative = buffering)
#' @param n_perm permutations per scenario
#' @return data.table(beta_injected, recovered, p_perm, detected)
ssi_positive_control <- function(ssi_panel, betas = c(0, -0.15, -0.30, -0.45), n_perm = 999L) {
  d0 <- data.table::as.data.table(ssi_panel)
  data.table::rbindlist(lapply(betas, function(b) {
    d <- data.table::copy(d0)[, ssi := ssi + b * treat * spei_c]
    pm <- permute_ssi_buffer(d, n_perm = n_perm)
    data.table::data.table(beta_injected = b, recovered = round(pm$observed, 3),
                           p_perm = round(pm$p_perm, 3), detected = pm$p_perm < 0.05)
  }))
}

#' Reviewer 2026-08-05 (2nd round, comment 2): catchment-area confound in the up/down placebo.
#' Upstream gauges sit in smaller catchments than downstream gauges; in hydrology, larger
#' catchments can attenuate drought transmission on their own, so the up/down attenuation could
#' be a catchment-scale artifact rather than the absence of regulation. We mirror the elevation
#' test: among UNDAMMED control gauges, does the per-gauge SPEI->SSI transmission slope depend on
#' catchment area (unit area_km2, a proxy for the drainage area feeding each gauge)? If it does
#' not, area cannot manufacture the up/down slope difference. We also report the up/down area
#' contrast so the scale of the gap is visible.
#' @param stations_units assign_stations_to_units() output
#' @param ssi12 compute_ssi() output
#' @param ssi_panel any build_ssi_panel() output (recovers per-unit SPEI)
#' @param unit_area data.table(unit_id, area_km2) from matched_set$data
#' @return data.table with up/down area contrast and the control slope~area test
catchment_area_sensitivity <- function(stations_units, ssi12, ssi_panel, unit_area) {
  slp <- gauge_transmission_slopes(stations_units, ssi12, ssi_panel)
  ua  <- data.table::as.data.table(unit_area)[, .(unit_id, area_km2)]
  slp <- merge(slp, ua, by = "unit_id")

  ud <- slp[treat == 1L & regulated %in% c("up", "down"),
            .(n_gauges = .N, area_mean_km2 = round(mean(area_km2, na.rm = TRUE)),
              transmission_mean = round(mean(slope, na.rm = TRUE), 3)), by = regulated]

  ctrl <- slp[treat == 0L & is.finite(area_km2) & is.finite(slope) & area_km2 > 0]
  m  <- stats::lm(slope ~ log(area_km2), data = ctrl)   # slope change per e-fold area
  ct <- summary(m)$coefficients["log(area_km2)", ]
  # also a tercile check so a non-monotonic area effect is not missed
  ctrl[, area_terc := cut(area_km2,
                          stats::quantile(area_km2, c(0, 1/3, 2/3, 1)),
                          include.lowest = TRUE)]
  tc <- ctrl[, .(mean_slope = mean(slope), n = .N), by = area_terc][order(area_terc)]

  data.table::rbindlist(list(
    data.table::data.table(quantity = "upstream gauges (unit area, km2)",
                           value = ud[regulated == "up", area_mean_km2],
                           detail = sprintf("n=%d; mean transmission %.3f",
                                            ud[regulated == "up", n_gauges],
                                            ud[regulated == "up", transmission_mean])),
    data.table::data.table(quantity = "downstream gauges (unit area, km2)",
                           value = ud[regulated == "down", area_mean_km2],
                           detail = sprintf("n=%d; mean transmission %.3f",
                                            ud[regulated == "down", n_gauges],
                                            ud[regulated == "down", transmission_mean])),
    data.table::data.table(
      quantity = "control transmission slope vs log(area), per e-fold",
      value = round(ct[["Estimate"]], 3),
      detail = sprintf("p = %.2f (n=%d control gauges); area does not predict transmission, so the up/down catchment-size gap cannot manufacture the placebo attenuation",
                       ct[["Pr(>|t|)"]], nrow(ctrl))),
    data.table::data.table(
      quantity = "control transmission by area tercile (mean slope)",
      value = NA_real_,
      detail = sprintf("small %.3f (n=%d) | mid %.3f (n=%d) | large %.3f (n=%d)",
                       tc$mean_slope[1], tc$n[1], tc$mean_slope[2], tc$n[2],
                       tc$mean_slope[3], tc$n[3]))))
}
