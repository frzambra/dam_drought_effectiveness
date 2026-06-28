# MOD16A2GF actual-ET (500 m, 8-DAY composites) -> per-basin ET. Two uses:
#   (1) drought-SENSITIVITY for the buffering test — slope of log(annual ET) on SPEI (a
#       semi-elasticity; amplitude-preserving, so buffering shows). H1 predicts a flatter slope
#       on irrigated land in dammed basins.
#   (2) annual ET LEVEL (mm/yr) as the H2 consumptive-water-use panel (extract_unit_et_total_annual).
# Native MOD16 is ~500 m, so orchard-majority cells exist in most matched basins (median densest
# 500 m pixel ~90 % orchard) where the 5.5 km SETI anomaly was too coarse.
#
# DATA QUIRKS (verified on disk 2026-06-27; the old config was wrong — see data_sources.yml):
#   * 8-DAY composites (46/yr); each value is ET summed over its 8-day period (mm/8day), so
#     annual ET = SUM over the year, NOT a mean. Filenames are ET.MOD1623GF_Chile_500m_YYYY.MM.DD.tif.
#   * Values are ALREADY scaled to mm (Float) — do NOT re-apply 0.1. (Verified: a cold Patagonian
#     basin sums to ~365 mm/yr at scale ×1, physically correct; ×0.1 would give an absurd ~37.)
#   * TWO non-physical populations must be masked, not just the nominal fill:
#       - fill PLATEAU at ~3276.1-3276.7 (the scaled 32761-32767 fill codes), AND
#       - a CONTAMINATION cluster at ~2000-3270 mm/8day (3-5% of cells, barren/water/cloud edges).
#     Real 8-day ET is bimodally separated from both: forest q90 ~40, central-Chile q90 ~20, with
#     ~nothing in (80, 2000). So a single PHYSICAL cap at 100 mm/8day removes both cleanly while
#     preserving all real ET (max real ~50-60 mm/8day).
# CAVEAT: MOD16 UNDER-estimates irrigated-crop ET (PM + MODIS-LAI, no irrigation), compressing
# the range and muting a buffering difference; cross-check with PML_V2 if a signal is marginal.

ET_FILL_ABOVE <- 100    # physical max plausible 8-day ET (mm); above = fill plateau OR contamination

#' Absolute paths + dates for the MOD16A2GF 8-day ET rasters.
#' @param sources load_config("data_sources")
#' @param years   calendar years (default 2001:2024; product runs 2000-2025, but 2000/2025 partial)
#' @return list(paths, dates)
mod16_8day_paths <- function(sources, years = 2001:2024) {
  dir <- sources$et_mod16$root
  f   <- list.files(dir, "\\.tif$", full.names = TRUE)
  d   <- as.Date(sub(".*_(\\d{4}\\.\\d{2}\\.\\d{2})\\.tif$", "\\1", basename(f)), "%Y.%m.%d")
  keep <- !is.na(d) & data.table::year(d) %in% years
  ord  <- order(d[keep])
  list(paths = f[keep][ord], dates = d[keep][ord])
}

#' Mirror the 8-day ET files to a LOCAL directory, returning a local stack.
#'
#' The source lives on a slow USB-NTFS drive (see [[external-drive-slow-ntfs]]) where terra's
#' windowed/tiled reads seek badly (~2 MB/s effective — a year took ~30 min); a SEQUENTIAL file copy
#' runs ~15-40x faster, after which aggregation runs at local-NVMe speed. Idempotent: files already
#' present with matching size are skipped, so re-running is cheap and the copy happens once.
#'
#' @param stack     mod16_8day_paths() output (source paths on the external drive)
#' @param local_dir local directory to mirror into (created if needed)
#' @return list(paths = local paths, dates = stack$dates)
mirror_et_local <- function(stack, local_dir) {
  dir.create(local_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(local_dir, basename(stack$paths))
  have <- file.exists(dest)
  if (any(have)) have[have] <- file.size(dest[have]) == file.size(stack$paths[have])
  if (any(!have)) {
    ok <- file.copy(stack$paths[!have], dest[!have], overwrite = TRUE)
    if (!all(ok)) stop("mirror_et_local: failed to copy ", sum(!ok), " file(s)")
  }
  list(paths = dest, dates = stack$dates)
}

#' Annual sum of one year's cropped, fill-masked 8-day composites (internal).
.year_et_sum <- function(paths, crop_ext, fill_above) {
  ry <- terra::rast(paths)
  if (!is.null(crop_ext)) ry <- terra::crop(ry, crop_ext)
  ry <- terra::ifel(ry > fill_above, NA, ry)
  terra::app(ry, sum, na.rm = TRUE)
}

#' Is a single 8-day file readable over the crop window? (forces a strip read to catch corruption).
.et_file_ok <- function(p, crop_ext) {
  tryCatch({
    x <- terra::rast(p)
    if (!is.null(crop_ext)) x <- terra::crop(x, crop_ext)
    terra::global(x, "max", na.rm = TRUE)   # forces a full read of the cropped region
    TRUE
  }, error = function(e) FALSE)
}

#' Cache the 8-day ET stack as a 24-band annual TOTAL-ET (mm/yr) raster.
#'
#' This is the ONE expensive full-grid pass: terra::tapp sums the year's 8-day composites (each
#' mm/8day) per cell -> annual ET in mm/yr. Caching it as a file means every downstream per-unit /
#' per-stratum extraction reads only 24 bands instead of re-scanning the 1104-layer stack (which
#' terra::extract does over the full extent per layer regardless of unit count — intractable ×N
#' targets). Fill / contamination (> fill_above) is set NA before summing; an all-fill cell sums to
#' 0 under na.rm and is then set NA.
#'
#' @param stack       mod16_8day_paths() output
#' @param out_path    GeoTIFF path to write (24 bands, names y2001..y2024)
#' @param units       sf polygons to CROP the stack to before aggregating (default NULL = full grid).
#'                    Pass the matched units: the national grid is hugely inflated by oceanic islands
#'                    (~80% NA, 32869 cols); cropping to the mainland-basin extent is far less I/O.
#'                    All downstream extraction uses the same units, so nothing outside is needed.
#' @param fill_above  values above this (mm/8day) are fill/contamination -> NA (default
#'                    ET_FILL_ABOVE = 100, the physical 8-day-ET cap)
#' @return out_path (for tar_target(format = "file"))
aggregate_et_annual <- function(stack, out_path, units = NULL, fill_above = ET_FILL_ABOVE) {
  yrs    <- sort(unique(data.table::year(stack$dates)))
  outdir <- dirname(out_path)
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  # PERSISTENT per-year band dir (NOT a temp dir): makes the aggregate RESUMABLE — the ~50-min pass
  # has failed midway on environmental issues (OOM under concurrency, /tmp full, transient terra
  # temp-read glitches), so each year's annual sum is written here and a re-run skips years already
  # done. Combined into out_path only once all 24 bands exist.
  bandsdir <- file.path(outdir, "annual_bands")
  dir.create(bandsdir, showWarnings = FALSE)
  # terra scratch on the roomy /home filesystem (NOT /tmp on the small / partition). Cleared only on
  # SUCCESS so a mid-run failure leaves the persistent band files intact for resume.
  ttmp    <- file.path(outdir, "terra_tmp")
  dir.create(ttmp, showWarnings = FALSE)
  old_tmp <- terra::terraOptions(print = FALSE)$tempdir
  terra::terraOptions(tempdir = ttmp)
  on.exit(terra::terraOptions(tempdir = old_tmp), add = TRUE)

  crop_ext <- NULL
  if (!is.null(units)) {
    tmpl <- terra::rast(stack$paths[1])
    v <- terra::vect(units)
    if (!terra::same.crs(v, tmpl)) v <- terra::project(v, tmpl)
    crop_ext <- terra::ext(v)
  }
  # YEAR-BY-YEAR: process one year's 46 composites, write the annual sum to a small persistent band.
  band_files <- file.path(bandsdir, sprintf("band_%d.tif", yrs))
  for (i in seq_along(yrs)) {
    bf <- band_files[i]
    if (file.exists(bf) && !inherits(try(terra::rast(bf), silent = TRUE), "try-error")) {
      message("aggregate_et_annual: year ", yrs[i], " cached, skipping (", i, "/", length(yrs), ")")
      next
    }
    yr_paths <- stack$paths[data.table::year(stack$dates) == yrs[i]]
    # Try the fast bulk path up to 3x (transient terra temp-read glitches have crashed a year on
    # otherwise-fine data). If it still fails, fall back to the per-file path that drops corrupt
    # composites (a missing 8-day period under-counts that year's ET by ~1/46 for affected cells —
    # flagged). On error the band files already written persist, so a re-run resumes.
    s <- NULL
    for (attempt in 1:3) {
      s <- tryCatch(.year_et_sum(yr_paths, crop_ext, fill_above), error = function(e) NULL)
      if (!is.null(s)) break
    }
    if (is.null(s)) {
      ok   <- vapply(yr_paths, .et_file_ok, logical(1), crop_ext = crop_ext)
      warning("aggregate_et_annual: year ", yrs[i], " dropped ", sum(!ok), " corrupt file(s): ",
              paste(basename(yr_paths[!ok]), collapse = ", "))
      s <- .year_et_sum(yr_paths[ok], crop_ext, fill_above)
    }
    # sum(na.rm=TRUE) of an all-NA (water/barren fill) cell returns 0, not NA -> set NA.
    s <- terra::ifel(s <= 0, NA, s)
    names(s) <- paste0("y", yrs[i])
    terra::writeRaster(s, bf, overwrite = TRUE)
    # Wipe terra scratch now that this year's band is safely on disk. terra's own gc-triggered
    # cleanup is unreliable here (no gc -> ~2-3 GB/yr piles up and fills the disk; gc -> occasional
    # "cannot read spat temp"), so manage it explicitly: nothing references ttmp across iterations
    # (bands live in bandsdir), so it is safe to clear the spat_* temp files after each year.
    rm(s); gc(verbose = FALSE)
    unlink(list.files(ttmp, pattern = "^spat_", full.names = TRUE))
    message("aggregate_et_annual: year ", yrs[i], " done (", i, "/", length(yrs), ")")
  }
  out <- terra::rast(band_files)
  terra::writeRaster(out, out_path, overwrite = TRUE)      # combine the 24 bands into the final file
  unlink(ttmp, recursive = TRUE)                            # clear scratch only after success
  out_path
}

#' Per-unit count of cover-stratum cells (internal helper, windowed).
.unit_cover_cells <- function(units, coverfrac, frac_thr = 0.5) {
  m <- coverfrac >= frac_thr
  v <- terra::vect(units)
  if (!terra::same.crs(v, m)) v <- terra::project(v, m)
  nc <- data.table::as.data.table(
    terra::extract(m, v, fun = function(x) sum(x > 0, na.rm = TRUE), ID = TRUE))
  data.table::setnames(nc, c("ID", "n_cells"))
  nc[, unit_id := units$unit_id[ID]]
  nc[, .(unit_id, n_cells)]
}

#' Per-unit annual TOTAL ET (mm/yr) panel — the H2 consumptive-water-use trajectory.
#'
#' Reads the CACHED 24-band annual-ET raster (aggregate_et_annual), not the 8-day stack, so it is
#' cheap and re-runnable. With `coverfrac` supplied, restricts to a cover stratum (orchard /
#' cropland majority cells); with NULL, uses all cells (whole-basin ET). The per-unit value is the
#' spatial mean of cells' annual ET (mm/yr) — comparable across years and basins.
#'
#' @param units     sf polygons with `unit_id`
#' @param et_annual cached annual-ET SpatRaster (bands named y2001..y2024) from aggregate_et_annual
#' @param coverfrac optional cover-fraction SpatRaster on the ET grid (NULL = all cells)
#' @param frac_thr  minimum cover fraction for a cell when masking (default 0.5)
#' @param min_cells minimum stratum cells per unit when masking (default 3)
#' @return data.table(unit_id, year, et_mm, n_cells)  [n_cells is NA when coverfrac is NULL]
extract_unit_et_total_annual <- function(units, et_annual, coverfrac = NULL, frac_thr = 0.5,
                                         min_cells = 3L) {
  yrs <- as.integer(sub("y", "", names(et_annual)))
  r   <- et_annual
  if (!is.null(coverfrac)) {
    # et_annual is cropped to the units extent; coverfrac is on the full ET grid. Resample onto r's
    # exact grid so terra::mask geometry matches (crop alone can leave a sub-pixel extent mismatch).
    if (!terra::compareGeom(coverfrac, r, stopOnError = FALSE))
      coverfrac <- terra::resample(coverfrac, r, method = "near")
    r <- terra::mask(r, coverfrac >= frac_thr, maskvalues = c(NA, FALSE))
  }
  v <- terra::vect(units)
  if (!terra::same.crs(v, r)) v <- terra::project(v, r)

  ex <- data.table::as.data.table(terra::extract(r, v, fun = mean, na.rm = TRUE, ID = TRUE))
  data.table::setnames(ex, c("ID", paste0("y", yrs)))
  ex[, unit_id := units$unit_id[ID]]
  long <- data.table::melt(ex, id.vars = c("ID", "unit_id"),
                           variable.name = "yv", value.name = "et_mm")
  long[, year := as.integer(sub("y", "", yv))]
  if (!is.null(coverfrac)) {
    nc   <- .unit_cover_cells(units, coverfrac, frac_thr)
    long <- merge(long, nc, by = "unit_id")[n_cells >= min_cells]
  } else {
    # whole-basin: count valid (non-NA) annual-ET cells per unit; drop basins with too few. Over
    # hyper-arid barren basins MOD16 is nearly all fill, so a "basin mean" from 1-2 surviving cells
    # is meaningless (e.g. one contaminated cell -> spurious 2967 mm/yr). Require >= min_cells.
    nc <- data.table::as.data.table(
      terra::extract(!is.na(r[[1]]), v, fun = function(x) sum(x > 0, na.rm = TRUE), ID = TRUE))
    data.table::setnames(nc, c("ID", "n_cells"))
    nc[, unit_id := units$unit_id[ID]]
    long <- merge(long, nc[, .(unit_id, n_cells)], by = "unit_id")[n_cells >= min_cells]
  }
  long <- long[!is.na(et_mm) & et_mm > 0, .(unit_id, year, et_mm, n_cells)]
  data.table::setorder(long, unit_id, year)
  long[]
}

#' Per-basin annual ET over a cover stratum, as log(annual ET) — for the drought-SENSITIVITY slope.
#'
#' Thin wrapper on extract_unit_et_total_annual: `level` = log(annual ET mm/yr). The buffering test
#' uses the slope of this on SPEI; any constant scaling cancels in the log, so using the annual SUM
#' (vs the old annual mean) leaves the slope/ATT unchanged.
#'
#' @inheritParams extract_unit_et_total_annual
#' @param coverfrac cover-fraction SpatRaster (required here — buffering is a stratum test)
#' @return data.table(unit_id, year, level, n_cells)
extract_unit_et_annual <- function(units, et_annual, coverfrac, frac_thr = 0.5, min_cells = 3L) {
  tot <- extract_unit_et_total_annual(units, et_annual, coverfrac, frac_thr, min_cells)
  tot[, .(unit_id, year, level = log(et_mm), n_cells)]
}

#' ET-buffering ATT: dammed-vs-control slope of log(orchard ET) on SPEI.
#' @param et_panel    extract_unit_et_annual() output (orchard cells)
#' @param forcing     extract_unit_forcing_annual() SPEI output
#' @param matched_set fit_matched_set() output
#' @return list(att, slopes, group_means) — H1 buffering predicts a NEGATIVE ATT
fit_et_buffering_att <- function(et_panel, forcing, matched_set) {
  sl  <- fit_response_slopes(build_response_panel(et_panel[, .(unit_id, year, level)], forcing),
                             min_years = 10L)
  fit <- fit_doubly_robust(matched_set, sl, outcome_col = "resp_slope")
  g   <- merge(data.table::as.data.table(matched_set$data)[, .(unit_id, treated, w)],
               sl[, .(unit_id, resp_slope)], by = "unit_id")[!is.na(resp_slope)]
  list(att = fit$estimates[estimator == "doubly_robust"], slopes = sl,
       group_means = g[, .(mean_sensitivity = mean(resp_slope)), by = treated])
}
