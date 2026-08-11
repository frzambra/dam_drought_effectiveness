# Bounding the groundwater-substitution confound (2026-07-02 external review, comment 1).
# If farmers in dammed basins pump MORE groundwater during drought to offset surface-water
# deficits, that hidden pumping could sustain cropland and ET and so mask a failing reservoir,
# invalidating the demand-side nulls. We test it directly with the DGA well hydrograph network:
# assign wells to subcuencas by point-in-polygon, take each well's depth-to-water TREND over the
# megadrought (m/yr; positive = water table dropping = depletion), aggregate to the basin, and ask
# whether dammed basins draw down groundwater differentially faster than matched controls, judged by
# the design's randomization inference. A null bounds the confound. Feeds Supplementary Table S17.

#' Read the DGA well hydrographs (.rds): code, date, raw GWL and the Hampel/LOESS-filtered series.
read_gw_levels <- function(path) {
  d <- data.table::as.data.table(readRDS(path))
  d[, code := sprintf("%08d", as.integer(code))]           # 8-digit BNA code (leading zero restored)
  d[, `:=`(dyear = as.integer(format(date, "%Y")) + (as.integer(format(date, "%j")) - 1) / 365,
           year  = as.integer(format(date, "%Y")))]
  d[]
}

#' Assign wells to subcuencas by point-in-polygon from their lon/lat (the physical location, which
#' can differ from the BNA-code prefix near basin boundaries).
assign_gw_wells <- function(coords_path, units) {
  co <- data.table::as.data.table(readRDS(coords_path))
  co[, code := sprintf("%08d", as.integer(code))]
  u   <- sf::st_transform(sf::st_as_sf(units), 4326)["unit_id"]
  pts <- sf::st_as_sf(co, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  j   <- sf::st_join(pts, u, join = sf::st_within, left = TRUE)
  data.table::as.data.table(sf::st_drop_geometry(j))[!is.na(unit_id), .(code, unit_id, lon, lat)]
}

#' Per-basin groundwater depletion rate (m/yr) over a window. Each well's rate is the OLS slope of
#' the filtered depth-to-water on decimal year (>= min_obs points spanning >= min_span years); basin
#' value aggregates well rates (median by default: a few wells carry extreme, error-like trends, so
#' the outlier-robust median is primary, mean reported for robustness).
#' @return data.table(unit_id, gw_depletion, n_wells)
gw_depletion_by_basin <- function(gw_levels, gw_wells, y0 = 2010L, y1 = 2021L,
                                  series = "GWL_hampel", agg = stats::median,
                                  min_obs = 8L, min_span = 5) {
  g <- merge(data.table::as.data.table(gw_levels),
             data.table::as.data.table(gw_wells)[, .(code, unit_id)], by = "code")
  g <- g[year >= y0 & year <= y1 & is.finite(get(series))]
  sl <- g[, .(slope = if (.N >= min_obs && diff(range(dyear)) >= min_span)
                        stats::coef(stats::lm(get(series) ~ dyear))[["dyear"]] else NA_real_),
          by = .(unit_id, code)][is.finite(slope)]
  sl[, .(gw_depletion = agg(slope), n_wells = .N), by = unit_id]
}

#' Matched dammed-vs-control ATT on the basin groundwater-depletion rate, with the design's
#' randomization inference and a Moran's I check on the residuals (great-circle 5-NN weights).
#' @return data.table(spec, dammed, control, att_wo, wo_lo, wo_hi, perm_p, att_dr, dr_lo, dr_hi,
#'                    n_treated, n_control, n_wells, moran_I, moran_p)
fit_gw_depletion_att <- function(matched_set, gw_basin, spec = "median", n_perm = 999L, seed = 1L) {
  ms <- data.table::as.data.table(matched_set$data)
  d  <- merge(ms, data.table::as.data.table(gw_basin), by = "unit_id")
  est <- dr_estimate(data.table::setnames(data.table::copy(d), "gw_depletion", "y"),
                     covars = c("log_area", "elev_mean", "log_aridity"))$estimates
  wo <- est[estimator == "weighting_only"]; dr <- est[estimator == "doubly_robust"]
  qs <- stats::quantile(d$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  d[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  set.seed(seed)
  perm <- vapply(seq_len(n_perm), function(b) {
    dp <- data.table::copy(d)[, treated := sample(treated), by = stratum]
    stats::coef(stats::lm(gw_depletion ~ treated, data = as.data.frame(dp), weights = dp$w))[["treated"]]
  }, numeric(1))
  p_perm <- (1 + sum(abs(perm) >= abs(wo$att))) / (1 + n_perm)
  mo <- .gw_moran(d, n_perm)
  data.table::data.table(spec = spec,
    dammed = d[treated == 1L, mean(gw_depletion)], control = d[treated == 0L, mean(gw_depletion)],
    att_wo = wo$att, wo_lo = wo$ci_lo, wo_hi = wo$ci_hi, perm_p = p_perm,
    att_dr = dr$att, dr_lo = dr$ci_lo, dr_hi = dr$ci_hi,
    n_treated = d[treated == 1L, .N], n_control = d[treated == 0L, .N],
    n_wells = sum(gw_basin$n_wells), moran_I = mo$I, moran_p = mo$p)
}

#' Moran's I of the depletion residuals (residualised on treated + Köppen + log-aridity) at basin
#' centroids; great-circle 5-NN row-standardised weights, residual-permutation p.
.gw_moran <- function(d, n_perm = 999L) {
  d <- data.table::as.data.table(d)[is.finite(lon) & is.finite(lat)]
  res <- stats::residuals(stats::lm(gw_depletion ~ treated + kg_group + log_aridity,
                                    data = as.data.frame(d)))
  lo <- d$lon * pi/180; la <- d$lat * pi/180; n <- nrow(d); D <- matrix(0, n, n)
  for (i in seq_len(n)) { a <- sin((la - la[i])/2)^2 + cos(la[i])*cos(la)*sin((lo - lo[i])/2)^2
    D[i, ] <- 2 * 6371 * asin(pmin(1, sqrt(a))) }
  W <- matrix(0, n, n)
  for (i in seq_len(n)) { o <- order(D[i, ]); nn <- o[o != i][seq_len(min(5L, n - 1L))]; W[i, nn] <- 1 }
  W <- W / pmax(rowSums(W), 1e-9)
  mI <- function(x) { x <- x - mean(x); (n / sum(W)) * sum(W * outer(x, x)) / sum(x^2) }
  I0 <- mI(res); Ip <- replicate(n_perm, mI(sample(res)))
  list(I = I0, p = (1 + sum(abs(Ip - mean(Ip)) >= abs(I0 - mean(Ip)))) / (1 + n_perm))
}

#' Assemble the groundwater-substitution table: outlier-robust median (primary) + mean (robustness)
#' aggregation, each a matched ATT with randomization inference. A null differential bounds the
#' groundwater-substitution confound on the demand-side outcomes.
build_gw_substitution_summary <- function(matched_set, gw_levels, gw_wells,
                                          y0 = 2010L, y1 = 2021L, series = "GWL_hampel") {
  med <- gw_depletion_by_basin(gw_levels, gw_wells, y0, y1, series, stats::median)
  mn  <- gw_depletion_by_basin(gw_levels, gw_wells, y0, y1, series, mean)
  data.table::rbindlist(list(
    fit_gw_depletion_att(matched_set, med, spec = "median (primary)"),
    fit_gw_depletion_att(matched_set, mn,  spec = "mean (robustness)")))
}
