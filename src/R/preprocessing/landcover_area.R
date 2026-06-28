# Observed annual agricultural / irrigated AREA panel from MapBiomas (30 m). This is the clean,
# OBSERVED counterpart to the Catastro-orchard reconstruction (orchard_expansion.R): MapBiomas
# classifies cover each year, so the area trajectory is measured, not reconstructed from a single
# survivor snapshot. It therefore has NO survival bias and NO siting-only confound in levels (the
# Catastro ratio falls 3.3x->1.7x precisely because survivors over-state recent expansion). It is,
# however, a PROXY: class 18 = "Agriculture" (annual + perennial crops), not strictly irrigated —
# but in central Chile cropland is overwhelmingly irrigated, and the Catastro orchard series is the
# irrigation-specific ground truth to cross-check against.
#
# Grain bridge: MapBiomas is 30 m (~5e9 cells nationally — never loaded whole). Per polygon we crop
# each year from disk, build a 0/1 class mask, and sum the per-cell area (terra::cellSize, which
# accounts for the lat-varying cell size of the EPSG:4326 grid). The whole-unit area is computed
# once (geometry is year-invariant) so area_frac = class area / unit area is directly comparable.

#' Mirror raster files to a local directory, returning local paths (idempotent, size-checked).
#'
#' Same rationale as the ET mirror ([[external-drive-slow-ntfs]]): MapBiomas lives on the slow USB
#' drive; copying the 26 small (~150 MB) files to local NVMe once makes the per-year aggregate fast
#' and avoids flaky seeky reads. Files already present with matching size are skipped.
#'
#' @param paths     source file paths
#' @param local_dir local directory to mirror into (created if needed)
#' @return character vector of local paths (same order as `paths`)
mirror_paths_local <- function(paths, local_dir) {
  dir.create(local_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(local_dir, basename(paths))
  have <- file.exists(dest)
  if (any(have)) have[have] <- file.size(dest[have]) == file.size(paths[have])
  if (any(!have)) {
    ok <- file.copy(paths[!have], dest[!have], overwrite = TRUE)
    if (!all(ok)) stop("mirror_paths_local: failed to copy ", sum(!ok), " file(s)")
  }
  dest
}

#' Observed annual area (ha) of a land-cover class set per unit.
#'
#' Uses `exactextractr::exact_extract` with `coverage_area = TRUE`: for each year it reads the 30 m
#' grid ONCE in C++ and accumulates, per polygon, the partial-cell-area-weighted area (m²) of cells
#' whose class is in `classes` — so boundary cells are handled exactly and lat-varying EPSG:4326 cell
#' areas are correct. This is ~100x faster than the terra approaches tried earlier (naive
#' per-polygon crop ~8.7 h; full-grid `aggregate` ~100 min/pass) — see [[external-drive-slow-ntfs]].
#' `unit_ha` is the geodesic polygon area (sf::st_area); `area_frac = area_ha / unit_ha`.
#'
#' @param units    sf polygons with `unit_id`
#' @param mb_paths MapBiomas year raster paths, ALIGNED to `years` (from mapbiomas_paths())
#' @param years    integer years matching mb_paths (e.g. 1999:2024)
#' @param classes  integer class IDs to sum (default 18 = Agriculture)
#' @return data.table(unit_id, year, area_ha, unit_ha, area_frac)
extract_unit_area_panel <- function(units, mb_paths, years, classes = 18L) {
  stopifnot(length(mb_paths) == length(years))
  if (!inherits(units, "sf")) units <- sf::st_as_sf(units)
  # geodesic polygon area (ha) for the fraction denominator
  unit_ha <- as.numeric(sf::st_area(units)) / 1e4

  # area (m²) of `classes` per polygon, exact partial-cell weighting
  class_area_m2 <- function(values, cov_area) {
    keep <- !is.na(values) & values %in% classes
    if (!any(keep)) return(0)
    sum(cov_area[keep])
  }
  out <- vector("list", length(years))
  for (j in seq_along(years)) {
    r <- terra::rast(mb_paths[j])
    u <- if (sf::st_crs(units) != sf::st_crs(r)) sf::st_transform(units, terra::crs(r)) else units
    m2 <- exactextractr::exact_extract(r, u, fun = class_area_m2,
                                       coverage_area = TRUE, progress = FALSE)
    out[[j]] <- data.table::data.table(unit_id = units$unit_id, year = years[j],
                                       area_ha = m2 / 1e4, unit_ha = unit_ha)
  }
  res <- data.table::rbindlist(out)
  res[, area_frac := area_ha / unit_ha]
  data.table::setorder(res, unit_id, year)
  res[]
}

#' Per-unit area-EXPANSION summary outcomes for the ATT (mirrors orchard_expansion_summary).
#'
#' Cross-sectional outcomes from the observed area panel: area added (ha and per km²) and the
#' log-ratio over the panel span. Directly comparable to the Catastro orchard expansion ATT, so
#' the observed and reconstructed irrigated-area signals can be contrasted under the same estimator.
#'
#' @param area_panel  extract_unit_area_panel() output
#' @param unit_covars data.table with unit_id + area_km2 (e.g. matched_set$data)
#' @return data.table(unit_id, ha_start, ha_end, ha_added, add_per_km2, log_ratio, frac_start, frac_end)
area_expansion_summary <- function(area_panel, unit_covars) {
  p  <- data.table::as.data.table(area_panel)
  y0 <- min(p$year); y1 <- max(p$year)
  s  <- p[, .(ha_start  = area_ha[year == y0],   ha_end   = area_ha[year == y1],
              frac_start = area_frac[year == y0], frac_end = area_frac[year == y1]),
          by = unit_id]
  s  <- merge(s, data.table::as.data.table(unit_covars)[, .(unit_id, area_km2)], by = "unit_id")
  s[, `:=`(ha_added    = ha_end - ha_start,
           add_per_km2 = (ha_end - ha_start) / area_km2,
           log_ratio   = log((ha_end + 1) / (ha_start + 1)))]
  data.table::setorder(s, -add_per_km2)
  s[]
}

#' Doubly-robust ATT of being dammed on observed agricultural-area expansion.
#' @param matched_set fit_matched_set() output
#' @param expansion   area_expansion_summary() output
#' @param outcome_col expansion metric (default "add_per_km2"; also "log_ratio", "ha_added")
#' @return fit_doubly_robust() result
fit_area_expansion_att <- function(matched_set, expansion, outcome_col = "add_per_km2") {
  fit_doubly_robust(matched_set, expansion, outcome_col = outcome_col)
}
