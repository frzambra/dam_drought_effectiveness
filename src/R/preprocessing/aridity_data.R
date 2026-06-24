# Long-term baseline aridity (annual P/PET) -> a quantitative climate matching covariate.
# Köppen main group matches climate categorically; baseline aridity refines it within the
# group (e.g. a wetter vs. drier Mediterranean subcuenca). Enhancement #2 in
# docs/design/matched-controls.md.
#
# IMPORTANT (per the design note): use the *annual* P/PET product — each annual raster is
# already an annual-sum P / annual-sum PET ratio. The long-term baseline is the temporal
# MEAN of those annual rasters, NOT an average of the unstable monthly P/PET product.

#' Absolute paths to the annual aridity-index rasters for a set of years.
#'
#' Built by direct string construction, not globbing: the filenames embed the literal
#' "chir[p|t]s" token whose brackets/pipe are glob/regex metacharacters.
#'
#' @param sources load_config("data_sources")
#' @param years   integer vector of calendar years (default: 1991-2020 WMO normal, matching
#'                the Köppen-Geiger reference period; excludes the partial 2026)
#' @return character vector of existing file paths (missing years are dropped with a warning)
aridity_annual_paths <- function(sources, years = 1991:2020) {
  a    <- sources$aridity_index
  dir  <- file.path(a$root, a$annual$subdir)
  files <- file.path(dir, sprintf("aridity_index_chir[p|t]s.chile.%d.tif", years))
  ok   <- file.exists(files)
  if (!all(ok))
    warning("aridity_annual_paths: missing ", sum(!ok), " year(s): ",
            paste(years[!ok], collapse = ", "))
  files[ok]
}

#' Long-term mean annual aridity (P/PET) per watershed unit.
#'
#' Stacks the annual rasters, masks the unflagged negative fill (a few cells carry ~ -172.9;
#' valid P/PET is > 0), averages across years to a single long-term-mean raster, then takes
#' the area-unweighted cell mean within each polygon. `aridity_sd` is the WITHIN-unit spatial
#' spread of that long-term mean (climatic heterogeneity of the basin), analogous to
#' `elev_sd` for terrain — not interannual variability.
#'
#' @param units    sf polygons with `unit_id` (e.g. subcuencas_dissolved)
#' @param paths    annual aridity raster paths (from aridity_annual_paths())
#' @param floor    values below this are treated as fill and set NA (default 0; P/PET > 0)
#' @return data.table(unit_id, aridity_mean, aridity_sd, n_cells, n_years)
extract_unit_aridity <- function(units, paths, floor = 0) {
  r <- terra::rast(paths)                       # one layer per year
  r <- terra::ifel(r < floor, NA, r)            # drop the spurious negative fill
  m <- terra::mean(r, na.rm = TRUE)             # long-term mean annual aridity

  v <- terra::vect(units)
  if (!terra::same.crs(v, r)) v <- terra::project(v, r)

  ex <- data.table::as.data.table(terra::extract(m, v))   # ID, <layer>
  data.table::setnames(ex, names(ex), c("ID", "aridity"))
  ex <- ex[!is.na(aridity)]

  per <- ex[, .(aridity_mean = mean(aridity),
                aridity_sd   = stats::sd(aridity),
                n_cells      = .N), by = ID]
  per[, unit_id := units$unit_id[ID]]
  per[, ID := NULL]
  per[, n_years := length(paths)]
  data.table::setcolorder(per, c("unit_id", "aridity_mean", "aridity_sd",
                                 "n_cells", "n_years"))
  data.table::setorder(per, unit_id)
  per[]
}
