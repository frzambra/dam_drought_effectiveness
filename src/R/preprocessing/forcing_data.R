# Per-subcuenca METEOROLOGICAL FORCING series (SPEI) for the forcing-conditioned ATT.
#
# The identification spine (docs/conceptual_framework/identification-strategy.md, Lever 1):
# NEVER identify off calendar time. The raw storage-era zNPP TREND is a calendar-time slope,
# so the matched-set ATT on it is partly the 2010+ mega-drought EXPOSURE that hit exactly the
# arid central-Chile basins where reservoirs sit. The fix is to condition on the realized
# forcing and estimate the effect on the deficit->impact RESPONSE SLOPE (transmission
# coefficient): regress the ecological anomaly on the SPEI anomaly WITHIN each subcuenca, and
# take the slope as the outcome. Both zNPP and SPEI are standardized anomalies, so the slope
# is a dimensionless, cross-basin-comparable drought-transmission elasticity.
#
# This file extracts the per-subcuenca annual SPEI forcing; the slope itself is fit in
# src/R/causal/forcing_conditioned.R and fed to the existing doubly-robust estimator.

#' Absolute paths + dates for a monthly standardized drought index at one timescale.
#'
#' Built by direct string construction, not globbing: the filenames embed the literal
#' "chir[p|t]s" token whose brackets/pipe are glob/regex metacharacters (same quirk as the
#' aridity rasters). Covers a contiguous monthly sequence; missing months are dropped.
#'
#' @param sources   load_config("data_sources")
#' @param index     drought_indices key (default "SPEI"; also "SPI", "EDDI")
#' @param timescale accumulation in months (default 12 — the annual water-balance integrator
#'                  matched to an annual ecological outcome)
#' @param years     calendar years to cover (default 2005:2024, the storage era; drops the
#'                  partial 2025/2026 tail so the annual aggregate is complete)
#' @return list(paths, dates) — `dates` are the first-of-month Date stamps of `paths`
forcing_monthly_paths <- function(sources, index = "SPEI", timescale = 12L,
                                  years = 2005:2024) {
  di  <- sources$drought_indices
  sub <- di$indices[[index]]$subdir
  if (is.null(sub)) stop("Unknown drought index: ", index)
  dir <- file.path(di$root, sub, sprintf("%s-%d", index, timescale))

  dates <- seq(as.Date(sprintf("%d-01-01", min(years))),
               as.Date(sprintf("%d-12-01", max(years))), by = "month")
  files <- file.path(dir, sprintf("chir[p|t]s_%s-%d_chile_%s.tif",
                                  index, timescale, format(dates, "%Y-%m-01")))
  ok <- file.exists(files)
  if (!all(ok))
    warning("forcing_monthly_paths: missing ", sum(!ok), " month(s) of ", index, "-",
            timescale, ": ", paste(format(dates[!ok], "%Y-%m"), collapse = ", "))
  list(paths = files[ok], dates = dates[ok])
}

#' Annual per-unit forcing: calendar-year mean of the monthly standardized index.
#'
#' Zonal-means the index within each polygon for every month (area-unweighted cell mean),
#' then averages the monthly zonal means within each calendar year to one forcing value per
#' unit-year — aligned to the annual ecological outcome. Averaging overlapping SPEI-12 windows
#' is monotonic in the year's integrated water balance and keeps a single, smooth annual
#' forcing index; the cross-basin/cross-year RANKING (what the response slope uses) is robust
#' to it.
#'
#' @param units    sf polygons with `unit_id` (e.g. subcuencas_dissolved)
#' @param stack    list(paths, dates) from forcing_monthly_paths()
#' @param clamp    |value| above this is treated as fill and set NA (default 6; standardized
#'                 SPEI is bounded ~|3.5|, so this only catches unflagged fill, not real data)
#' @param min_months_per_year require at least this many months to report a year (default 10)
#' @param mask     optional boolean SpatRaster (cells to KEEP) aligned to `stack` — restricts the
#'                 zonal mean to a stratum (e.g. orchard cells on the SETI grid); default NULL
#' @return data.table(unit_id, year, forcing, n_months)
extract_unit_forcing_annual <- function(units, stack, clamp = 6,
                                        min_months_per_year = 10L, mask = NULL) {
  r <- terra::rast(stack$paths)                 # one layer per month
  r <- terra::ifel(abs(r) > clamp, NA, r)       # drop unflagged fill, keep real anomalies
  if (!is.null(mask)) r <- terra::mask(r, mask, maskvalues = c(NA, FALSE))
  v <- terra::vect(units)
  if (!terra::same.crs(v, r)) v <- terra::project(v, r)

  ex <- data.table::as.data.table(
    terra::extract(r, v, fun = mean, na.rm = TRUE, ID = TRUE))
  data.table::setnames(ex, c("ID", paste0("m", seq_along(stack$dates))))
  ex[, unit_id := units$unit_id[ID]]

  long <- data.table::melt(ex, id.vars = c("ID", "unit_id"),
                           variable.name = "mvar", value.name = "spei")
  long[, midx := as.integer(sub("^m", "", mvar))]
  long[, year := data.table::year(stack$dates[midx])]
  long <- long[!is.na(spei)]

  per <- long[, .(forcing = mean(spei), n_months = .N), by = .(unit_id, year)]
  per <- per[n_months >= min_months_per_year]
  data.table::setorder(per, unit_id, year)
  per[]
}
