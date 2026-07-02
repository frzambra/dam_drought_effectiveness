# Robustness analyses added in response to the 2026-07-01 external review (Reviewer 3):
#   (S7) fully NON-PARAMETRIC matching on the aridity-overlap subset for every cross-sectional
#        outcome (re-fit entropy balancing WITHIN the overlap band + weighting-only estimator, so
#        no parametric outcome-model aridity term extrapolates across the regime gap);
#   (S8) sensitivity of the winsorized water-rights VOLUME null to the winsorization threshold;
#   (S9) SPATIAL AUTOCORRELATION assessment (Moran's I on ATT-model residuals) and a
#        spatially-restricted (cuenca-block) permutation / cuenca-clustered CI for the
#        spatially-dependent water-rights outcomes.
# These feed Supplementary Tables S7-S9 and the water-rights paragraph of the Results.

# ---- shared helpers ---------------------------------------------------------------------------

#' Aridity-overlap band on the (already common-support-trimmed) matched frame.
.overlap_band <- function(md) {
  md <- data.table::as.data.table(md)
  lo <- max(md[treated == 1L, min(log_aridity)], md[treated == 0L, min(log_aridity)])
  hi <- min(md[treated == 1L, max(log_aridity)], md[treated == 0L, max(log_aridity)])
  d  <- md[log_aridity >= lo & log_aridity <= hi]
  keep <- d[, .(nt = sum(treated), nc = sum(treated == 0L)), by = kg_group][nt > 0 & nc > 0, kg_group]
  d[kg_group %in% keep]
}

#' Re-fit entropy balancing on a covariate frame (same spec as fit_matched_set), returning the
#' frame with a fresh `w`. Drops Köppen groups lacking both treatment levels. NULL on failure.
.refit_ebal <- function(d) {
  d <- data.table::as.data.table(data.table::copy(d))
  keep <- d[, .(nt = sum(treated), nc = sum(treated == 0L)), by = kg_group][nt > 0 & nc > 0, kg_group]
  d <- d[kg_group %in% keep]
  W <- tryCatch(WeightIt::weightit(treated ~ log_area + elev_mean, data = as.data.frame(d),
                  method = "ebal", estimand = "ATT", by = ~kg_group, maxit = 5000),
                error = function(e) NULL)
  if (is.null(W)) return(NULL)
  d[, w := W$weights]; d[]
}

#' Weighting-only ATT (ebal-weighted difference in means, HC3 SE) for outcome column `yc`.
.wo_att <- function(d, yc) {
  dd <- data.table::as.data.table(d)[is.finite(get(yc)) & w > 0]
  if (dd[treated == 1L, .N] < 2L || dd[treated == 0L, .N] < 2L)
    return(list(att = NA_real_, se = NA_real_, nt = NA_integer_, nc = NA_integer_))
  m <- stats::lm(get(yc) ~ treated, data = as.data.frame(dd), weights = dd$w)
  b <- stats::coef(m)[["treated"]]; se <- sqrt(sandwich::vcovHC(m, type = "HC3")["treated", "treated"])
  list(att = b, se = se, nt = dd[treated == 1L, .N], nc = dd[treated == 0L, .N])
}

#' Assemble the unit-level frame of matched covariates + every cross-sectional outcome.
.assemble_outcomes <- function(matched_set, irrig_area_expansion, wr_expansion, att_et_buffering) {
  md   <- data.table::as.data.table(matched_set$data)
  area <- data.table::as.data.table(irrig_area_expansion)[, .(unit_id, y_area = add_per_km2)]
  orch <- data.table::as.data.table(att_et_buffering$slopes)[, .(unit_id, y_orch = resp_slope)]
  wr   <- data.table::as.data.table(wr_expansion)[, .(unit_id, y_wrc = add_per_km2,
                                                      y_wrv = add_lsw_per_km2)]
  Reduce(function(a, b) merge(a, b, by = "unit_id", all.x = TRUE), list(md, area, orch, wr))
}

# ---- S7: fully non-parametric matching on the aridity-overlap subset --------------------------

#' @return data.table(outcome, att, se, ci_lo, ci_hi, perm_p, n_treated, n_control)
build_nonparam_overlap <- function(matched_set, irrig_area_expansion, wr_expansion,
                                   att_et_buffering, n_perm = 999L, seed = 1L) {
  d0 <- .assemble_outcomes(matched_set, irrig_area_expansion, wr_expansion, att_et_buffering)
  base <- .overlap_band(d0)
  qs <- stats::quantile(base$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  base[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  outcomes <- c(`Cropland-area expansion (ha/km2)` = "y_area",
                `Orchard ET buffering (dlogET/dSPEI)` = "y_orch",
                `Water-rights count (per 100 km2)` = "y_wrc",
                `Water-rights volume (l/s per km2)` = "y_wrv")
  set.seed(seed)
  data.table::rbindlist(lapply(seq_along(outcomes), function(i) {
    yc <- outcomes[[i]]
    obs <- .wo_att(.refit_ebal(base), yc)
    perm <- vapply(seq_len(n_perm), function(b) {
      dp <- data.table::copy(base)[, treated := sample(treated), by = stratum]
      dw <- .refit_ebal(dp); if (is.null(dw)) return(NA_real_)
      .wo_att(dw, yc)$att
    }, numeric(1))
    nv <- sum(is.finite(perm))
    data.table::data.table(outcome = names(outcomes)[i], att = obs$att, se = obs$se,
      ci_lo = obs$att - 1.96 * obs$se, ci_hi = obs$att + 1.96 * obs$se,
      perm_p = (1 + sum(abs(perm) >= abs(obs$att), na.rm = TRUE)) / (1 + nv),
      n_treated = obs$nt, n_control = obs$nc)
  }))
}

# ---- S8: winsorization-threshold sensitivity of the water-rights volume null ------------------

#' @return data.table(winsor, att, ci_lo, ci_hi, perm_p, null_lo, null_hi)
build_winsor_sensitivity <- function(matched_set, water_rights_assigned,
                                     winsors = c(0.95, 0.99, 0.995, 0.999), n_perm = 999L) {
  covd <- data.table::as.data.table(matched_set$data)
  data.table::rbindlist(lapply(winsors, function(w) {
    panel <- build_water_rights_panel(water_rights_assigned, winsor = w)
    wex   <- wr_expansion_summary(panel, covd)
    e <- data.table::as.data.table(
      fit_wr_expansion_att(matched_set, wex, "add_lsw_per_km2")$estimates)[estimator == "doubly_robust"]
    pm <- permute_wr_att(matched_set, wex, "add_lsw_per_km2", n_perm = n_perm)
    data.table::data.table(winsor = w, att = e$att, ci_lo = e$ci_lo, ci_hi = e$ci_hi,
                           perm_p = pm$p_perm, null_lo = pm$null_lo, null_hi = pm$null_hi)
  }))
}

# ---- S9: spatial autocorrelation + spatially-restricted inference -----------------------------

#' Great-circle distance matrix (km) from lon/lat vectors.
.gc_dist <- function(lon, lat) {
  R <- 6371; rad <- pi / 180; la <- lat * rad; lo <- lon * rad; n <- length(lat)
  D <- matrix(0, n, n)
  for (i in seq_len(n)) {
    a <- sin((la - la[i]) / 2)^2 + cos(la[i]) * cos(la) * sin((lo - lo[i]) / 2)^2
    D[i, ] <- 2 * R * asin(pmin(1, sqrt(a)))
  }
  D
}
#' Row-standardised k-nearest-neighbour weight matrix from a distance matrix.
.knn_W <- function(D, k = 5L) {
  n <- nrow(D); W <- matrix(0, n, n)
  for (i in seq_len(n)) { o <- order(D[i, ]); nn <- o[o != i][seq_len(min(k, n - 1L))]; W[i, nn] <- 1 }
  W / pmax(rowSums(W), 1e-9)
}
.moran <- function(x, W) { x <- x - mean(x); (length(x) / sum(W)) * sum(W * outer(x, x)) / sum(x^2) }

#' Moran's I of ATT-model residuals for one outcome, with a residual-permutation p.
.moran_of <- function(d, yc, k = 5L, nperm = 999L) {
  d <- data.table::as.data.table(d)[is.finite(get(yc)) & is.finite(lon) & is.finite(lat)]
  f <- if (data.table::uniqueN(d$kg_group) > 1L)
         stats::as.formula(paste(yc, "~ treated + kg_group + log_aridity"))
       else stats::as.formula(paste(yc, "~ treated + log_aridity"))
  res <- stats::residuals(stats::lm(f, data = as.data.frame(d)))
  W <- .knn_W(.gc_dist(d$lon, d$lat), k)
  I0 <- .moran(res, W); Ip <- replicate(nperm, .moran(sample(res), W))
  list(I = I0, expected = -1 / (length(res) - 1L),
       p = (1 + sum(abs(Ip - mean(Ip)) >= abs(I0 - mean(Ip)))) / (1 + nperm), n = length(res))
}

#' Spatial-block permutation p + cuenca-clustered CI for a water-rights outcome on the overlap subset.
#' Treatment is permuted at the cuenca-block level (first two BNA digits) so co-located subcuencas
#' move together; ebal is re-fit each draw and the weighting-only ATT recomputed.
.spatial_block_wr <- function(matched_set, wr_expansion, yc, n_perm = 999L, seed = 1L) {
  md <- data.table::as.data.table(matched_set$data)
  wr <- data.table::as.data.table(wr_expansion)[, .(unit_id, y = get(yc))]
  base <- .overlap_band(md)
  d <- .refit_ebal(base); if (is.null(d)) return(NULL)
  d <- merge(d, wr, by = "unit_id")[is.finite(y)]
  d[, block := substr(unit_id, 1L, 2L)]
  m <- stats::lm(y ~ treated, data = as.data.frame(d), weights = d$w)
  b <- stats::coef(m)[["treated"]]
  se_cl <- sqrt(sandwich::vcovCL(m, cluster = d$block, type = "HC1")["treated", "treated"])
  blk <- unique(d[, .(btreat = as.integer(any(treated == 1L))), by = .(block, kg_group)])
  set.seed(seed)
  perm <- vapply(seq_len(n_perm), function(i) {
    bp <- data.table::copy(blk)[, btreat := sample(btreat), by = kg_group]
    dd <- merge(data.table::copy(d)[, !"treated"], bp[, .(block, treated = btreat)], by = "block")
    if (dd[treated == 1L, .N] < 2L || dd[treated == 0L, .N] < 2L) return(NA_real_)
    dw <- .refit_ebal(dd); if (is.null(dw)) return(NA_real_)   # dw retains the merged `y` column
    .wo_att(dw, "y")$att
  }, numeric(1))
  nv <- sum(is.finite(perm))
  list(att = b, ci_cl_lo = b - 1.96 * se_cl, ci_cl_hi = b + 1.96 * se_cl,
       block_p = (1 + sum(abs(perm) >= abs(b), na.rm = TRUE)) / (1 + nv))
}

#' @return list(moran = data.table, inference = data.table) feeding table_spatial_moran /
#'         table_spatial_inference.
build_spatial_diagnostics <- function(matched_set, irrig_area_expansion, wr_expansion,
                                      att_et_buffering, nonparam_overlap, n_perm = 999L) {
  d <- .assemble_outcomes(matched_set, irrig_area_expansion, wr_expansion, att_et_buffering)
  ycs <- c(y_area = "Cropland-area expansion", y_wrc = "Water-rights count",
           y_wrv = "Water-rights volume", y_orch = "Orchard ET buffering")
  moran <- data.table::rbindlist(lapply(names(ycs), function(yc) {
    r <- .moran_of(d, yc)
    data.table::data.table(outcome = ycs[[yc]], n = r$n, moran_I = round(r$I, 3),
                           expected = round(r$expected, 3), p_perm = round(r$p, 3))
  }))
  # spatially-restricted inference for the two water-rights outcomes; stratified p reused from S7
  npo <- data.table::as.data.table(nonparam_overlap)
  strat_p <- function(lab) npo[outcome %like% lab, perm_p]
  vol <- .spatial_block_wr(matched_set, wr_expansion, "add_lsw_per_km2", n_perm)
  cnt <- .spatial_block_wr(matched_set, wr_expansion, "add_per_km2", n_perm)
  inference <- data.table::data.table(
    outcome = c("Water-rights volume (l/s per km2)", "Water-rights count (per 100 km2)"),
    att = c(vol$att, cnt$att),
    ci_hc3 = c(sprintf("[%.2f, %.2f]", npo[outcome %like% "volume", ci_lo],
                       npo[outcome %like% "volume", ci_hi]),
               sprintf("[%.2f, %.2f]", npo[outcome %like% "count", ci_lo],
                       npo[outcome %like% "count", ci_hi])),
    perm_p_stratified = c(strat_p("volume"), strat_p("count")),
    ci_cuenca_clustered = c(sprintf("[%.2f, %.2f]", vol$ci_cl_lo, vol$ci_cl_hi),
                            sprintf("[%.2f, %.2f]", cnt$ci_cl_lo, cnt$ci_cl_hi)),
    perm_p_spatial_block = c(vol$block_p, cnt$block_p))
  list(moran = moran[], inference = inference[])
}
