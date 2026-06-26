# Per-watershed ecological OUTCOME for the matched-set ATT. Until the gated irrigated-area
# product lands (the primary H2 outcome), the available stand-in is the storage-era trend in
# an annual MODIS ecological index: a greening/productivity slope per subcuenca. H2 predicts
# dammed basins expand (induced demand) -> a more POSITIVE trend than matched controls.

#' Absolute paths to an annual MODIS ecological-index product for a set of years.
#'
#' @param sources load_config("data_sources")
#' @param product ecological_indices product key with annual cadence (default "zNPP")
#' @param years   integer years (default 2005-2024: storage era, drops the partial tail)
#' @return character vector of existing file paths (missing years dropped with a warning)
ecological_annual_paths <- function(sources, product = "zNPP", years = 2005:2024) {
  p   <- sources$ecological_indices$products[[product]]
  if (is.null(p)) stop("Unknown ecological product: ", product)
  dir <- file.path(sources$ecological_indices$root, p$subdir)
  # filename_pattern uses a {YYYY.01.01} date stamp for the annual products.
  files <- file.path(dir, sprintf("%s.MOD17A3HGF_Chile_500m_%d.01.01.tif", product, years))
  ok   <- file.exists(files)
  if (!all(ok))
    warning("ecological_annual_paths: missing ", sum(!ok), " year(s): ",
            paste(years[!ok], collapse = ", "))
  list(paths = files[ok], years = years[ok])
}

#' Annual per-unit zonal mean of an annual index (the long panel behind the trend).
#'
#' Zonal-means the index within each polygon for every year — one number per unit-year. This
#' is the raw material both for the calendar-time trend (regress on year) AND for the
#' forcing-conditioned response slope (regress on the SPEI forcing of the same year), so it is
#' factored out here and shared.
#'
#' @param units sf polygons with `unit_id`
#' @param stack list(paths, years) from ecological_annual_paths()
#' @return data.table(unit_id, year, level) — NA-level unit-years dropped
extract_unit_index_annual <- function(units, stack) {
  r <- terra::rast(stack$paths)                 # one layer per year
  yrs <- stack$years
  v <- terra::vect(units)
  if (!terra::same.crs(v, r)) v <- terra::project(v, r)

  # Unit x year matrix of zonal means (ID column + one column per layer/year).
  ex <- data.table::as.data.table(
    terra::extract(r, v, fun = mean, na.rm = TRUE, ID = TRUE))
  data.table::setnames(ex, c("ID", paste0("y", yrs)))
  ex[, unit_id := units$unit_id[ID]]

  long <- data.table::melt(ex, id.vars = c("ID", "unit_id"),
                           variable.name = "yvar", value.name = "level")
  long[, year := as.integer(sub("^y", "", yvar))]
  long <- long[!is.na(level), .(unit_id, year, level)]
  data.table::setorder(long, unit_id, year)
  long[]
}

#' Storage-era OLS trend of an annual index per watershed unit.
#'
#' Fits a per-unit OLS slope over calendar year on the annual panel. The slope is the outcome:
#' index units per year. OLS (not Theil-Sen) keeps the dependency footprint to base R; with
#' ~20 annual points it is adequate and the matched comparison, not the trend estimator,
#' carries the inference. NOTE this is a CALENDAR-TIME slope — see forcing_conditioned.R for
#' the forcing-conditioned alternative that breaks the mega-drought-exposure confound.
#'
#' @param units sf polygons with `unit_id`
#' @param stack list(paths, years) from ecological_annual_paths()
#' @param min_years require at least this many non-NA years to report a slope (default 10)
#' @return data.table(unit_id, trend, mean_level, n_years)
extract_unit_index_trend <- function(units, stack, min_years = 10L) {
  long <- extract_unit_index_annual(units, stack)

  per <- long[, {
    if (.N >= min_years && data.table::uniqueN(year) >= 3L) {
      fit <- stats::lm(level ~ year)
      .(trend = unname(stats::coef(fit)[["year"]]),
        mean_level = mean(level), n_years = .N)
    } else .(trend = NA_real_, mean_level = if (.N) mean(level) else NA_real_, n_years = .N)
  }, by = unit_id]

  data.table::setorder(per, unit_id)
  per[]
}
