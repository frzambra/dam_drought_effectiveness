# Geomorphological confound check on the placebo (2026-07-03 round 6, comment 1): the up/down
# contrast is confounded with the bedrock-to-alluvial transition, and elevation is only a proxy.
# We therefore extract a DIRECT terrain metric, local relief (max minus min SRTM elevation within
# 2.5 km of each gauge; bedrock canyons high, alluvial valleys low, a standard mountain-front
# discriminator), and repeat the confound machinery on the DIFFERENTIAL estimand: does relief
# predict transmission among undammed controls, does a relief-by-forcing adjustment move the
# up/down coefficients, and does the equivalence persist among low-relief (alluvial) units?
# Feeds Supplementary Table S35.

#' Local relief (m) within `radius_m` of each gauge from the SRTM DEM.
gauge_relief <- function(dem_path, gauges, radius_m = 2500) {
  v  <- terra::vect(as.data.frame(gauges[, .(lon, lat)]), geom = c("lon", "lat"),
                    crs = "EPSG:4326")
  b  <- terra::buffer(v, radius_m)
  r  <- terra::rast(dem_path)
  mx <- terra::extract(r, b, fun = max, na.rm = TRUE)[, 2]
  mn <- terra::extract(r, b, fun = min, na.rm = TRUE)[, 2]
  gauges[, relief := mx - mn][]
}

#' @return data.table(quantity, value, detail)
build_geomorph_check <- function(dem_path, stations_units, ssi12,
                                 ssi_panel_up, ssi_panel_down, sources) {
  su <- data.table::as.data.table(stations_units)
  g  <- merge(su[, .(codigo, unit_id, treat, regulated, altura)], gauge_coords(sources),
              by = "codigo")
  g  <- g[is.finite(lon) & is.finite(lat)]
  g  <- gauge_relief(dem_path, g)[is.finite(relief)]

  coefx <- function(m, pat) {
    ct <- as.data.frame(summary(m)$coeftable)
    r <- ct[grepl(pat, rownames(ct)), , drop = FALSE]
    if (nrow(r) != 1L) return(c(est = NA_real_, se = NA_real_, p = NA_real_))
    c(est = r[1, 1], se = r[1, 2], p = r[1, 4])
  }
  tp <- "treat.*spei_c|spei_c.*treat"
  side_rows <- function(panel, side, lab) {
    keep <- g[treat == 0L | regulated == side]
    us <- keep[, .(rel_unit = mean(relief)), by = unit_id]
    us[, rel_z := (rel_unit - mean(rel_unit)) / stats::sd(rel_unit)]
    p <- merge(data.table::as.data.table(panel), us, by = "unit_id")
    ff <- function(fml, d) fixest::feols(fml, data = d, weights = ~w, cluster = ~unit_id,
                                         nthreads = 1)
    b0 <- coefx(ff(ssi ~ spei_c + treat:spei_c | unit_id + month_f + year, p), tp)
    m1 <- ff(ssi ~ spei_c + treat:spei_c + rel_z:spei_c | unit_id + month_f + year, p)
    b1 <- coefx(m1, tp); s1 <- coefx(m1, "rel_z")
    uu <- unique(p[, .(unit_id, rel_unit)])
    lo <- p[unit_id %in% uu[rel_unit < stats::median(uu$rel_unit), unit_id]]
    bl <- coefx(ff(ssi ~ spei_c + treat:spei_c | unit_id + month_f + year, lo), tp)
    nlo <- lo[, data.table::uniqueN(unit_id), by = treat]
    data.table::rbindlist(list(
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI, unadjusted", lab), value = round(b0[["est"]], 4),
        detail = sprintf("SE %.4f, p = %.3f", b0["se"], b0["p"])),
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI, relief-adjusted (spei x relief z)", lab),
        value = round(b1[["est"]], 4),
        detail = sprintf("SE %.4f, p = %.3f; relief term %.4f (SE %.4f, p = %.3f)",
                         b1["se"], b1["p"], s1["est"], s1["se"], s1["p"])),
      data.table::data.table(
        quantity = sprintf("%s: treat x SPEI, low-relief (alluvial) units", lab),
        value = round(bl[["est"]], 4),
        detail = sprintf("SE %.4f, p = %.3f; %d treated / %d control units below median relief",
                         bl["se"], bl["p"], nlo[treat == 1L, V1], nlo[treat == 0L, V1]))))
  }

  slp <- gauge_transmission_slopes(stations_units, ssi12, ssi_panel_up)
  slp <- merge(slp, g[, .(codigo, relief)], by = "codigo")[is.finite(relief) & is.finite(slope)]
  slp[, rel_sdz := (relief - mean(relief)) / stats::sd(relief)]
  cm <- summary(stats::lm(slope ~ rel_sdz, data = slp[treat == 0L]))$coefficients["rel_sdz", ]
  m2 <- summary(stats::lm(slope ~ rel_sdz + I(altura / 1000),
                          data = slp[treat == 0L]))$coefficients
  up_r <- slp[regulated == "up", mean(relief)]; dn_r <- slp[regulated == "down", mean(relief)]

  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "gauges: up vs down local relief (m, 2.5 km radius)",
      value = round(up_r),
      detail = sprintf("down %.0f (gap %.0f m = %.2f SD); n_up=%d, n_down=%d",
                       dn_r, up_r - dn_r, (up_r - dn_r) / stats::sd(slp$relief),
                       slp[regulated == "up", .N], slp[regulated == "down", .N])),
    data.table::data.table(
      quantity = "control gauges: transmission slope per SD relief",
      value = round(cm[["Estimate"]], 4),
      detail = sprintf("SE %.4f, p = %.3f (n=%d); net of elevation p = %.3f",
                       cm[["Std. Error"]], cm[["Pr(>|t|)"]], slp[treat == 0L, .N],
                       m2["rel_sdz", "Pr(>|t|)"])),
    side_rows(ssi_panel_up, "up", "upstream placebo"),
    side_rows(ssi_panel_down, "down", "downstream")))
}
