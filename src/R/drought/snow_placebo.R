# Bounding the SNOWMELT confound in the within-basin upstream/downstream streamflow placebo
# (2026-07-02 review round; reworked after the 2026-07-02 internal NW review flagged the first
# version for testing raw gauge-level transmission slopes instead of the differential placebo
# estimand). Upstream reaches are snow-dominated Andean headwaters and downstream reaches lower
# valleys, so snowmelt storage could in principle shape the treated-vs-control SPEI->SSI slope gap
# differently up- vs downstream, independent of regulation. This version tests the confound on the
# estimand the manuscript actually reports — the treat:spei_c coefficient of the up- and downstream
# unit-month panels — four ways:
#   (1) refit the placebo model with a snow x forcing adjustment (spei_c x standardized unit peak
#       SWE) and ask whether treat:spei_c moves;
#   (2) refit on the low-snow half of units (below-median peak SWE; NOT snow-free) and ask whether
#       the up/down contrast persists;
#   (3) split the panel into early/late halves to test stationarity of the up/down contrast
#       (a snow buffer degrading in parallel with a dam buffer would show up here);
#   (4) interact the placebo with the ANNUAL peak-SWE anomaly (unit-year): if snowmelt manufactured
#       the upstream pseudo-buffering, it should strengthen in high-snow years.
# ERA5-Land SWE (0.1 deg) underestimates absolute Andean snowpack — the same class of product flaw
# that disqualifies MOD16 for irrigation ET — so all coefficients use STANDARDIZED (relative) SWE,
# which is robust to multiplicative bias, and test (4) doubles as a product positive-control: a
# nonzero spei_c x snow-year term among the panels shows the product resolves real snow signal.
# Feeds Supplementary Table S12.

#' Crop the global ERA5-Land SWE NetCDF to Chile and reduce it to a climatology + per-year stack:
#' long-term mean SWE, mean annual-peak SWE, and one annual-peak layer per calendar year (m w.e.),
#' written to a local GeoTIFF. Reads the slow external NetCDF once; downstream steps use the small
#' local raster.
#' @return path to the written raster (for tar_target(format = "file"))
aggregate_swe_climatology <- function(nc_path, out_path, window = c(283, 295, -56, -17)) {
  r  <- terra::rast(nc_path)
  rc <- terra::crop(r, terra::ext(window))                 # windowed read (small spatial subset)
  terra::ext(rc) <- terra::ext(terra::xmin(rc) - 360, terra::xmax(rc) - 360,
                               terra::ymin(rc), terra::ymax(rc))  # 0..360 -> -180..180
  terra::crs(rc) <- "EPSG:4326"
  yr  <- as.integer(format(terra::time(rc), "%Y"))
  ann <- terra::tapp(rc, index = yr, fun = max, na.rm = TRUE)     # annual peak SWE, one layer/year
  names(ann) <- paste0("peak_", sub("^X", "", names(ann)))
  out <- c(terra::mean(rc, na.rm = TRUE), terra::mean(ann, na.rm = TRUE), ann)
  names(out)[1:2] <- c("mean_swe", "peak_swe")
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  terra::writeRaster(out, out_path, overwrite = TRUE)
  out_path
}

#' Per-gauge coordinates (lon/lat) from the raw CR2 stations metadata, keyed by integer `codigo`.
gauge_coords <- function(sources) {
  sf_cfg <- sources$streamflow
  d <- data.table::fread(file.path(sf_cfg$dir, sf_cfg$stations_file))
  d[, .(codigo = as.integer(codigo_estacion), lon = longitud, lat = latitud)]
}

#' Placebo buffering model with an optional snow x forcing adjustment.
#' @return coeftable row (estimate, se, p) for the term matching `term_pat`
.snow_coef <- function(model, term_pat) {
  ct <- as.data.frame(summary(model)$coeftable)
  r  <- ct[grepl(term_pat, rownames(ct)), , drop = FALSE]
  if (nrow(r) != 1L) return(c(est = NA_real_, se = NA_real_, p = NA_real_))
  c(est = r[1, 1], se = r[1, 2], p = r[1, 4])
}

.fit_snow <- function(panel, adjust = FALSE) {
  fml <- if (adjust) ssi ~ spei_c + treat:spei_c + swe_z:spei_c | unit_id + month_f + year
         else            ssi ~ spei_c + treat:spei_c              | unit_id + month_f + year
  fixest::feols(fml, data = panel, weights = ~w, cluster = ~unit_id, nthreads = 1)
}

#' Snowmelt-confound check on the DIFFERENTIAL placebo estimand (treat:spei_c, up/down panels).
#' @param swe_path aggregate_swe_climatology() output (climatology + annual-peak layers)
#' @param stations_units assign_stations_to_units() output (codigo, unit_id, treat, altura, regulated)
#' @param ssi12 compute_ssi() output — for the secondary gauge-level sensitivity rows
#' @param ssi_panel_up build_ssi_panel(..., "up") output (the placebo panel)
#' @param ssi_panel_down build_ssi_panel(..., "down") output
#' @param sources cfg_sources (gauge coordinates)
#' @return data.table(quantity, value, detail)
build_snow_placebo_check <- function(swe_path, stations_units, ssi12,
                                     ssi_panel_up, ssi_panel_down, sources) {
  su <- data.table::as.data.table(stations_units)
  g  <- merge(su[, .(codigo, unit_id, treat, regulated, altura)], gauge_coords(sources),
              by = "codigo")
  g  <- g[is.finite(lon) & is.finite(lat)]
  swe <- terra::rast(swe_path)
  ex  <- terra::extract(swe, terra::vect(as.data.frame(g[, .(lon, lat)]),
                                         geom = c("lon", "lat"), crs = "EPSG:4326"))
  g[, peak_swe := ex$peak_swe]
  ann_cols <- grep("^peak_[0-9]{4}$", names(ex), value = TRUE)
  gann <- data.table::melt(
    data.table::as.data.table(cbind(codigo = g$codigo, ex[, ann_cols, drop = FALSE])),
    id.vars = "codigo", variable.name = "band", value.name = "swe_ann")
  gann[, year := as.integer(sub("peak_", "", band))][, band := NULL]

  # Unit-level SWE under each panel's gauge subset (treated units: up- or downstream gauges only;
  # controls: all their gauges) — mirrors build_ssi_panel()'s aggregation.
  prep_panel <- function(panel, side) {
    keep <- g[is.finite(peak_swe) & (treat == 0L | regulated == side)]
    us <- keep[, .(swe_unit = mean(peak_swe)), by = unit_id]
    us[, swe_z := (swe_unit - mean(swe_unit)) / stats::sd(swe_unit)]
    uy <- merge(gann[is.finite(swe_ann)], keep[, .(codigo, unit_id)],
                by = "codigo")[, .(swe_ann = mean(swe_ann)), by = .(unit_id, year)]
    uy[, swe_anom := swe_ann - mean(swe_ann), by = unit_id]
    uy[, swe_anom_z := swe_anom / stats::sd(swe_anom)]
    p <- merge(data.table::as.data.table(panel), us, by = "unit_id")
    merge(p, uy[, .(unit_id, year, swe_anom_z)], by = c("unit_id", "year"), all.x = TRUE)
  }

  one_side <- function(panel, side) {
    p <- prep_panel(panel, side)
    nu <- p[, data.table::uniqueN(unit_id), by = treat]
    n_t <- nu[treat == 1L, V1]; n_c <- nu[treat == 0L, V1]
    b0 <- .snow_coef(.fit_snow(p),               "^treat:spei_c$|^spei_c:treat$")
    m1 <- .fit_snow(p, adjust = TRUE)
    b1 <- .snow_coef(m1, "treat.*spei_c|spei_c.*treat")
    s1 <- .snow_coef(m1, "swe_z")
    # (3) stationarity: early vs late half of the panel years, with a formal period-interaction
    # test (treat x spei_c x late) so "no divergence" is a tested claim, not an eyeball one
    ymed <- stats::median(unique(p$year))
    bE <- .snow_coef(.fit_snow(p[year <= ymed]), "treat.*spei_c|spei_c.*treat")
    bL <- .snow_coef(.fit_snow(p[year >  ymed]), "treat.*spei_c|spei_c.*treat")
    pl <- data.table::copy(p)[, late := as.integer(year > ymed)]
    mT <- fixest::feols(ssi ~ spei_c + treat:spei_c + spei_c:late + treat:spei_c:late |
                          unit_id + month_f + year,
                        data = pl, weights = ~w, cluster = ~unit_id, nthreads = 1)
    bT <- .snow_coef(mT, "treat.*late|late.*treat")
    # (2) low-snow half of units (below-median peak SWE — NOT snow-free)
    us <- unique(p[, .(unit_id, swe_unit)])
    lo <- p[unit_id %in% us[swe_unit < stats::median(us$swe_unit), unit_id]]
    nlo <- lo[, data.table::uniqueN(unit_id), by = treat]
    bS <- .snow_coef(.fit_snow(lo), "treat.*spei_c|spei_c.*treat")
    # (4) snow-year modulation: does the placebo strengthen in high-snow years?
    pd <- p[is.finite(swe_anom_z)]
    m3 <- fixest::feols(ssi ~ spei_c + treat:spei_c + spei_c:swe_anom_z +
                          treat:spei_c:swe_anom_z | unit_id + month_f + year,
                        data = pd, weights = ~w, cluster = ~unit_id, nthreads = 1)
    b3  <- .snow_coef(m3, "treat.*swe_anom_z|swe_anom_z.*treat")
    b3s <- .snow_coef(m3, "^spei_c:swe_anom_z$|^swe_anom_z:spei_c$")
    fmt <- function(b) sprintf("%.4f (SE %.4f, p = %.3f)", b["est"], b["se"], b["p"])
    lab <- if (side == "up") "upstream placebo" else "downstream"
    data.table::rbindlist(list(
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI, unadjusted", lab),
        value = round(b0[["est"]], 4),
        detail = sprintf("SE %.4f, p = %.3f; %d treated / %d control units", b0["se"], b0["p"], n_t, n_c)),
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI, snow-adjusted (spei x peak-SWE z)", lab),
        value = round(b1[["est"]], 4),
        detail = sprintf("SE %.4f, p = %.3f; snow term %s", b1["se"], b1["p"], fmt(s1))),
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI, low-snow units (below-median peak SWE)", lab),
        value = round(bS[["est"]], 4),
        detail = sprintf("SE %.4f, p = %.3f; %d treated / %d control units; peak SWE %.4f-%.4f m w.e.",
                         bS["se"], bS["p"],
                         nlo[treat == 1L, V1], nlo[treat == 0L, V1],
                         max(0, min(us$swe_unit)), stats::median(us$swe_unit))),
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI, early vs late period", lab),
        value = round(bE[["est"]], 4),
        detail = sprintf("early (<=%d) %s; late (>%d) %s; period change (treat x SPEI x late) %s",
                         ymed, fmt(bE), ymed, fmt(bL), fmt(bT))),
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI x annual-SWE anomaly (snow-year modulation)", lab),
        value = round(b3[["est"]], 4),
        detail = sprintf("SE %.4f, p = %.3f; base spei x snow-year %s",
                         b3["se"], b3["p"], fmt(b3s)))),
      use.names = TRUE)
  }

  # Secondary, gauge-level rows retained from the original check, now on STANDARDIZED SWE so the
  # sensitivity and the implied bound cannot round to zero by unit choice.
  slp <- gauge_transmission_slopes(stations_units, ssi12, ssi_panel_up)
  slp <- merge(slp, g[, .(codigo, peak_swe)], by = "codigo")
  slp <- slp[is.finite(peak_swe) & is.finite(slope)]
  slp[, swe_sdz := (peak_swe - mean(peak_swe)) / stats::sd(peak_swe)]
  up_swe <- slp[regulated == "up", mean(peak_swe)]
  dn_swe <- slp[regulated == "down", mean(peak_swe)]
  gap_z  <- (up_swe - dn_swe) / stats::sd(slp$peak_swe)
  ctrl <- slp[treat == 0L]
  cm <- summary(stats::lm(slope ~ swe_sdz, data = ctrl))$coefficients["swe_sdz", ]
  m2 <- summary(stats::lm(slope ~ swe_sdz + I(altura / 1000), data = ctrl))$coefficients
  ci_hi <- abs(cm[["Estimate"]]) + stats::qnorm(0.975) * cm[["Std. Error"]]
  gauge_rows <- data.table::rbindlist(list(
    data.table::data.table(
      quantity = "gauges: up vs down peak SWE (m w.e., ERA5-Land)",
      value = round(up_swe, 4),
      detail = sprintf("down %.4f (gap %.4f m = %.2f SD); n_up=%d, n_down=%d",
                       dn_swe, up_swe - dn_swe, gap_z,
                       slp[regulated == "up", .N], slp[regulated == "down", .N])),
    data.table::data.table(
      quantity = "control gauges: transmission slope per SD peak SWE",
      value = round(cm[["Estimate"]], 4),
      detail = sprintf("SE %.4f, 95%% CI [%.4f, %.4f], p = %.3f (n=%d); net of elevation p = %.3f",
                       cm[["Std. Error"]],
                       cm[["Estimate"]] - stats::qnorm(0.975) * cm[["Std. Error"]],
                       cm[["Estimate"]] + stats::qnorm(0.975) * cm[["Std. Error"]],
                       cm[["Pr(>|t|)"]], nrow(ctrl), m2["swe_sdz", "Pr(>|t|)"])),
    data.table::data.table(
      quantity = "conservative bound: snow-induced up-down slope difference",
      value = round(gap_z * ci_hi, 4),
      detail = sprintf("SWE gap %.2f SD x CI-upper |sensitivity| %.4f; observed differential gap -0.04",
                       gap_z, ci_hi))))

  data.table::rbindlist(list(one_side(ssi_panel_up, "up"),
                             one_side(ssi_panel_down, "down"),
                             gauge_rows), use.names = TRUE)
}
