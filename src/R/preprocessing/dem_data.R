# SRTM DEM preprocessing -> terrain matching covariates per watershed unit.
# Mean elevation separates the high-Andes reservoir units from low-latitude-but-cold
# (Köppen-ET) Patagonian controls; within-unit relief (sd) proxies valley-vs-montane.

#' Mean elevation and relief per unit from the SRTM DEM.
#'
#' terra reads the DEM's NaN as NA; we additionally mask values < `floor_m` (default
#' -100 m) to drop the unflagged ocean/void fill (the raster reports a spurious -630 m
#' minimum). Stats are area-unweighted cell means within each polygon.
#'
#' @param units    sf polygons with `unit_id` (e.g. subcuencas_dissolved)
#' @param dem_path path to the SRTM GeoTIFF
#' @param floor_m  elevations below this (m) are treated as fill and set NA
#' @return data.table(unit_id, elev_mean, elev_sd, elev_min, elev_max, n_cells)
extract_unit_terrain <- function(units, dem_path, floor_m = -100) {
  r <- terra::rast(dem_path)
  v <- terra::vect(units)
  if (!terra::same.crs(v, r)) v <- terra::project(v, r)

  ex <- data.table::as.data.table(terra::extract(r, v))   # ID, <layer>
  data.table::setnames(ex, names(ex), c("ID", "elev"))
  ex <- ex[!is.na(elev) & elev >= floor_m]

  per <- ex[, .(elev_mean = mean(elev),
                elev_sd   = stats::sd(elev),
                elev_min  = min(elev),
                elev_max  = max(elev),
                n_cells   = .N), by = ID]
  per[, unit_id := units$unit_id[ID]]
  per[, ID := NULL]
  data.table::setcolorder(per, c("unit_id", "elev_mean", "elev_sd",
                                 "elev_min", "elev_max", "n_cells"))
  data.table::setorder(per, unit_id)
  per[]
}
