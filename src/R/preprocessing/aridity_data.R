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

#' Pre-drought aridity-window sensitivity (Reviewer 3, 2026-07-02 comment 6).
#'
#' The 1991-2020 WMO normal used for baseline aridity overlaps 11 megadrought years, so the
#' matching covariate could be partly post-treatment. We recompute unit aridity on the strictly
#' pre-drought 1991-2009 window and the drought-decade 2010-2020 window and report (a) whether the
#' matched design is invariant to the window (level and rank agreement, and agreement of the
#' aridity terciles used as permutation strata) and (b) whether the megadrought CHANGE in P/PET
#' differs by treatment, the direct test that P/PET is invariant to reservoir presence during the
#' drought (ebal-weighted; a differential change would signal reservoir-driven PET/P feedbacks).
#'
#' @param matched_set fit_matched_set() output (the common-support sample: 21 treated + controls)
#' @param units       sf polygons with unit_id (subcuencas_dissolved)
#' @param paths_pre   annual aridity rasters 1991-2009 (aridity_annual_paths(..., years = 1991:2009))
#' @param paths_post  annual aridity rasters 2010-2020
#' @return data.table(quantity, value, detail)
aridity_window_sensitivity <- function(matched_set, units, paths_pre, paths_post) {
  pre  <- extract_unit_aridity(units, paths_pre)[,  .(unit_id, aridity_pre  = aridity_mean)]
  post <- extract_unit_aridity(units, paths_post)[, .(unit_id, aridity_post = aridity_mean)]
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, treated, w,
                                                        aridity_full = aridity_mean)]
  d <- merge(merge(ms, pre, by = "unit_id"), post, by = "unit_id")

  r_p <- stats::cor(d$aridity_full, d$aridity_pre)
  r_s <- stats::cor(d$aridity_full, d$aridity_pre, method = "spearman")
  terc <- function(x) cut(x, stats::quantile(x, c(0, 1/3, 2/3, 1)),
                          include.lowest = TRUE, labels = FALSE)
  same_terc <- mean(terc(d$aridity_full) == terc(d$aridity_pre))
  med <- d[, .(pre = stats::median(aridity_pre), full = stats::median(aridity_full)), by = treated]

  d[, delta := aridity_post - aridity_pre]
  ct <- summary(stats::lm(delta ~ treated, data = d, weights = d$w))$coefficients["treated", ]

  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "unit aridity, pre-drought (1991-2009) vs full (1991-2020) window: Pearson r",
      value = round(r_p, 4),
      detail = sprintf("Spearman rho %.4f (n=%d matched units)", r_s, nrow(d))),
    data.table::data.table(
      quantity = "aridity-tercile agreement between windows (permutation strata)",
      value = round(same_terc, 3),
      detail = "share of matched units assigned the same tercile"),
    data.table::data.table(
      quantity = "median P/PET, treated: pre-drought vs full window",
      value = round(med[treated == 1L, pre], 3),
      detail = sprintf("full %.3f; control pre %.3f, full %.3f",
                       med[treated == 1L, full], med[treated == 0L, pre],
                       med[treated == 0L, full])),
    data.table::data.table(
      quantity = "megadrought change in P/PET (2010-2020 minus 1991-2009), treated minus control",
      value = signif(ct[["Estimate"]], 3),
      detail = sprintf("SE %.4f, p = %.2f (ebal-weighted); small against the ~0.5 treated-control aridity gap",
                       ct[["Std. Error"]], ct[["Pr(>|t|)"]]))))
}
