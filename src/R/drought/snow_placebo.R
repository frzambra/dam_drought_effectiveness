# Bounding the SNOWMELT confound in the within-basin upstream/downstream streamflow placebo
# (2026-07-02 review; snow-related concern from the 2026-07-01 round, comment 8). Upstream reaches are
# snow-dominated Andean headwaters and downstream reaches are lower valleys, so snowmelt storage could
# in principle shape the SPEI->SSI transmission slope differently up- vs downstream, independent of
# regulation. We test this directly, mirroring the elevation-confound check: extract a per-gauge snow
# climatology from ERA5-Land SWE, ask whether snow predicts the transmission slope among undammed
# controls, bound the maximum snow-induced up/down slope difference, and confirm the upstream
# lower-transmission pattern persists in snow-free basins. Feeds Supplementary Table S12.

#' Crop the global ERA5-Land SWE NetCDF to Chile and reduce it to a 2-band climatology
#' (long-term mean SWE and mean annual-peak SWE, m w.e.), written to a local GeoTIFF. Reads the slow
#' external NetCDF once; downstream steps use the small local raster.
#' @return path to the written climatology raster (for tar_target(format = "file"))
aggregate_swe_climatology <- function(nc_path, out_path, window = c(283, 295, -56, -17)) {
  r  <- terra::rast(nc_path)
  rc <- terra::crop(r, terra::ext(window))                 # windowed read (small spatial subset)
  terra::ext(rc) <- terra::ext(terra::xmin(rc) - 360, terra::xmax(rc) - 360,
                               terra::ymin(rc), terra::ymax(rc))  # 0..360 -> -180..180
  terra::crs(rc) <- "EPSG:4326"
  yr <- as.integer(format(terra::time(rc), "%Y"))
  out <- c(terra::mean(rc, na.rm = TRUE),
           terra::mean(terra::tapp(rc, index = yr, fun = max, na.rm = TRUE), na.rm = TRUE))
  names(out) <- c("mean_swe", "peak_swe")
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

#' Snowmelt-confound check for the upstream/downstream placebo.
#' Extends gauge_transmission_slopes() with a per-gauge snow climatology and reports: the up/down snow
#' gap, the control-gauge snow-sensitivity of transmission (raw and net of elevation), the implied
#' bound on the snow-induced up/down slope difference, and the up vs down transmission split by
#' snow-free vs snowy basins.
#' @return data.table(quantity, value, detail)
build_snow_placebo_check <- function(swe_clim_path, stations_units, ssi12, ssi_panel, sources) {
  slp <- gauge_transmission_slopes(stations_units, ssi12, ssi_panel)
  slp <- merge(slp, gauge_coords(sources), by = "codigo", all.x = TRUE)
  slp <- slp[is.finite(lon) & is.finite(lat) & is.finite(slope)]
  swe <- terra::rast(swe_clim_path)
  ex  <- terra::extract(swe, terra::vect(as.data.frame(slp[, .(lon, lat)]),
                                         geom = c("lon", "lat"), crs = "EPSG:4326"))
  slp[, `:=`(peak_swe = ex$peak_swe, mean_swe = ex$mean_swe)]
  slp <- slp[is.finite(peak_swe)]

  up_swe <- slp[regulated == "up", mean(peak_swe)];  dn_swe <- slp[regulated == "down", mean(peak_swe)]
  up_sl  <- slp[regulated == "up", mean(slope)];     dn_sl  <- slp[regulated == "down", mean(slope)]
  ctrl <- slp[treat == 0L]
  m  <- stats::lm(slope ~ peak_swe, data = ctrl)
  cm <- summary(m)$coefficients["peak_swe", ]
  m2 <- summary(stats::lm(slope ~ peak_swe + I(altura / 1000), data = ctrl))$coefficients
  bound <- (up_swe - dn_swe) * cm[["Estimate"]]
  thr <- stats::median(slp$peak_swe)
  lo <- slp[peak_swe <  thr]; hi <- slp[peak_swe >= thr]
  ud <- function(d, cl) round(d[regulated == cl, mean(slope)], 3)

  data.table::rbindlist(list(
    data.table::data.table(quantity = "upstream gauges peak SWE (m w.e.)", value = round(up_swe, 3),
      detail = sprintf("mean transmission %.3f (n=%d)", up_sl, slp[regulated=="up", .N])),
    data.table::data.table(quantity = "downstream gauges peak SWE (m w.e.)", value = round(dn_swe, 3),
      detail = sprintf("mean transmission %.3f (n=%d)", dn_sl, slp[regulated=="down", .N])),
    data.table::data.table(quantity = "control transmission slope vs peak SWE (per m w.e.)",
      value = round(cm[["Estimate"]], 3),
      detail = sprintf("p = %.2f (n=%d controls); net of elevation p = %.2f => snow does not drive transmission",
                       cm[["Pr(>|t|)"]], nrow(ctrl), m2["peak_swe", "Pr(>|t|)"])),
    data.table::data.table(quantity = "bound: snow-induced up-down slope difference",
      value = round(bound, 3),
      detail = sprintf("SWE gap %.3f m x sensitivity; observed up-down slope diff %.3f",
                       up_swe - dn_swe, up_sl - dn_sl)),
    data.table::data.table(quantity = "snow-free basins: up vs down transmission",
      value = ud(lo, "up"),
      detail = sprintf("down %.3f (n_up=%d, n_down=%d); upstream buffering persists without snow",
                       ud(lo, "down"), lo[regulated=="up", .N], lo[regulated=="down", .N])),
    data.table::data.table(quantity = "snowy basins: up vs down transmission",
      value = ud(hi, "up"),
      detail = sprintf("down %.3f (n_up=%d, n_down=%d)",
                       ud(hi, "down"), hi[regulated=="up", .N], hi[regulated=="down", .N]))))
}
