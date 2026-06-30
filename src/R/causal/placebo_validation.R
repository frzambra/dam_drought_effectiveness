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
         altura = altura[1L], treat = treat[1L], regulated = regulated[1L]),
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
      detail = sprintf("p = %.2f (n=%d control gauges); ~0 => elevation does not drive transmission",
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
