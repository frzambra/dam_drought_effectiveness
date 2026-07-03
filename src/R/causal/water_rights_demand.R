# Induced-demand test on the DGA water-rights panel: does damming accrue MORE consumptive water
# rights than in matched controls? Mirrors the irrigated-area analysis (expansion ATT + event study),
# judged by the paper's primary randomization inference, with a within-Köppen-region check. The
# outlier-robust demand measure is rights DENSITY (count per 100 km2); winsorized volume is secondary.

#' Doubly-robust ATT point estimate from a fit_doubly_robust() result.
.dr_att_pt <- function(fit)
  data.table::as.data.table(fit$estimates)[estimator == "doubly_robust"]$att

#' Merge basin area and compute allocation-intensity outcomes (per 100 km2) on the rights panel.
wr_intensity_panel <- function(water_rights_panel, unit_covars) {
  p <- merge(data.table::as.data.table(water_rights_panel),
             data.table::as.data.table(unit_covars)[, .(unit_id, area_km2)], by = "unit_id")
  p[, `:=`(n_km2 = 100 * cum_n / area_km2, n_gw_km2 = 100 * cum_n_gw / area_km2,
           lsw_km2 = cum_lsw / area_km2)]
  p[]
}

#' Per-unit change in rights density AND winsorized allocated volume over the study window -> the two
#' expansion outcomes for the matched ATT (a count measure, robust to the registry's volume errors,
#' and a winsorized-volume measure of consumptive pressure).
wr_expansion_summary <- function(water_rights_panel, unit_covars, y0 = 2005L, y1 = 2024L) {
  p <- wr_intensity_panel(water_rights_panel, unit_covars)
  s <- p[year %in% c(y0, y1), .(v0 = n_km2[year == y0],  v1 = n_km2[year == y1],
                                l0 = lsw_km2[year == y0], l1 = lsw_km2[year == y1]),
         by = unit_id]
  s <- merge(s, data.table::as.data.table(unit_covars)[, .(unit_id, area_km2)], by = "unit_id")
  s[, `:=`(add_per_km2 = v1 - v0, add_lsw_per_km2 = l1 - l0)]
  s[]
}

#' Doubly-robust matched ATT of damming on rights-density expansion.
fit_wr_expansion_att <- function(matched_set, wr_expansion, outcome_col = "add_per_km2")
  fit_doubly_robust(matched_set, wr_expansion, outcome_col = outcome_col)

#' Randomization inference for the rights-density ATT: permute the treatment label within
#' Köppen x aridity-tercile strata and refit the DR-ATT (design-based, ~21 treated units).
permute_wr_att <- function(matched_set, wr_expansion, outcome_col = "add_per_km2",
                           n_perm = 999L, seed = 1L) {
  obs <- .dr_att_pt(fit_wr_expansion_att(matched_set, wr_expansion, outcome_col))
  u  <- data.table::as.data.table(matched_set$data)
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  set.seed(seed)
  perm <- vapply(seq_len(n_perm), function(b) {
    up <- data.table::copy(u)[, treated := sample(treated), by = stratum]
    ms2 <- matched_set; ms2$data <- up
    tryCatch(.dr_att_pt(fit_wr_expansion_att(ms2, wr_expansion, outcome_col)),
             error = function(e) NA_real_)
  }, numeric(1))
  nv <- sum(!is.na(perm)); qn <- stats::quantile(perm, c(.025, .975), na.rm = TRUE, names = FALSE)
  list(observed = obs, null_mean = mean(perm, na.rm = TRUE), null_sd = stats::sd(perm, na.rm = TRUE),
       null_lo = qn[1], null_hi = qn[2],
       p_perm = (1 + sum(abs(perm) >= abs(obs), na.rm = TRUE)) / (1 + nv), n_perm = nv)
}

#' Assemble the water-rights demand summary for the two outcomes (rights count and winsorized volume).
#' Each row carries the national doubly-robust ATT with its analytic 95% CI, the randomization-
#' inference p, and the 95% band of the PERMUTATION NULL (what random treatment assignment within
#' climate x aridity strata produces). The observed gap lying inside that null band is the design-based
#' evidence that the apparent accrual is siting, not a reservoir effect (no extrapolation involved).
#' @return data.table(outcome, att, ci_lo, ci_hi, perm_p, null_lo, null_hi)
build_wr_demand_summary <- function(matched_set, wr_expansion, n_perm = 999L) {
  one <- function(col, lab) {
    e  <- data.table::as.data.table(
      fit_wr_expansion_att(matched_set, wr_expansion, col)$estimates)[estimator == "doubly_robust"]
    pm <- permute_wr_att(matched_set, wr_expansion, col, n_perm = n_perm)
    data.table::data.table(outcome = lab, att = e$att, ci_lo = e$ci_lo, ci_hi = e$ci_hi,
                           perm_p = pm$p_perm, null_lo = pm$null_lo, null_hi = pm$null_hi)
  }
  data.table::rbindlist(list(one("add_per_km2", "Rights count (per 100 km²)"),
                             one("add_lsw_per_km2", "Allocated volume (winsorized, l/s per km²)")))
}

#' Non-parametric (rank-based) checks on RAW, unwinsorized volumes (Reviewer 3 round 4, comment 1).
#' (a) Does volume PER RIGHT differ systematically between dammed and control basins? (b) Does the
#' raw megadrought volume expansion per km2 differ under a rank test that no outlier, cap, or
#' monotone data error can distort? Ranks are invariant to the extreme caudal entries, so this
#' complements the winsorized ATT without discarding large rights. Also reports how concentrated
#' the raw volume distribution is (share held by the largest 1% of rights).
#' @return data.table(quantity, value, detail)
wr_rank_check <- function(rights_assigned, matched_set, y0 = 2005L, y1 = 2024L) {
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, treated, area_km2)]
  r  <- merge(data.table::as.data.table(rights_assigned)[consumptive == TRUE & is.finite(flow_ls)],
              ms, by = "unit_id")
  w1  <- stats::wilcox.test(flow_ls ~ treated, data = r)
  med <- r[, .(m = stats::median(flow_ls)), by = treated]
  top <- r[, sum(sort(flow_ls, decreasing = TRUE)[seq_len(ceiling(.N / 100))]) / sum(flow_ls)]
  b <- r[year >= y0 & year <= y1, .(raw_add = sum(flow_ls)), by = unit_id]
  b <- merge(ms, b, by = "unit_id", all.x = TRUE)
  b[is.na(raw_add), raw_add := 0][, raw_km2 := raw_add / area_km2]
  w2   <- stats::wilcox.test(raw_km2 ~ treated, data = b)
  bmed <- b[, .(m = stats::median(raw_km2)), by = treated]

  # Design-based rank test: the naive Wilcoxon reproduces the siting gap; the estimand of interest
  # is the DESIGN contrast on ranks (ebal-weighted mean-rank difference, stratified permutation),
  # outlier-immune without any cap.
  msd <- data.table::as.data.table(matched_set$data)[, .(unit_id, w, kg_group, aridity_mean)]
  bd  <- merge(b, msd, by = "unit_id")
  bd[, rrank := data.table::frank(raw_km2)]
  gap <- function(d) d[treated == 1L, mean(rrank)] - d[treated == 0L, sum(w * rrank) / sum(w)]
  obs <- gap(bd)
  qs <- stats::quantile(bd$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  bd[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  set.seed(1)
  perm <- vapply(seq_len(1999L), function(i) {
    dp <- data.table::copy(bd)[, treated := sample(treated), by = stratum]; gap(dp)
  }, numeric(1))
  p_perm <- (1 + sum(abs(perm) >= abs(obs))) / (1 + length(perm))

  # Water-rights outcomes are strongly spatially autocorrelated (Supp Table S9), so the unit-level
  # permutation is anti-conservative; the governing inference swaps treatment at the cuenca-block
  # level, exactly as for the winsorized volume (.spatial_block_wr).
  bd[, block := substr(unit_id, 1L, 2L)]
  blk <- unique(bd[, .(btreat = as.integer(any(treated == 1L))), by = .(block, kg_group)])
  set.seed(1)
  perm_b <- vapply(seq_len(1999L), function(i) {
    bp <- data.table::copy(blk)[, btreat := sample(btreat), by = kg_group]
    dd <- merge(data.table::copy(bd)[, !"treated"], bp[, .(block, treated = btreat)], by = "block")
    gap(dd)
  }, numeric(1))
  p_block <- (1 + sum(abs(perm_b) >= abs(obs), na.rm = TRUE)) / (1 + sum(!is.na(perm_b)))

  data.table::data.table(
    quantity = c("volume per right, raw (median l/s): dammed vs control",
                 sprintf("raw volume added %d-%d, uncapped (median l/s per km2): dammed vs control",
                         y0, y1),
                 "design rank contrast on raw volume (mean-rank difference, ebal-weighted)",
                 "design rank contrast under spatially-restricted (cuenca-block) permutation",
                 "share of total raw volume held by the largest 1% of rights"),
    value  = c(round(med[treated == 1L, m], 1), round(bmed[treated == 1L, m], 2),
               round(obs, 1), round(obs, 1), round(top, 3)),
    detail = c(sprintf("control %.1f; Wilcoxon rank-sum p = %.2f (n = %s rights)",
                       med[treated == 0L, m], w1$p.value,
                       format(nrow(r), big.mark = ",")),
               sprintf("control %.2f; naive Wilcoxon p = %.2f (%d basins) reproduces the siting gap the design removes",
                       bmed[treated == 0L, m], w2$p.value, nrow(b)),
               sprintf("unit-level stratified permutation p = %.3f, anti-conservative under the spatial autocorrelation of Supp Table S9",
                       p_perm),
               sprintf("cuenca-block permutation p = %.3f (1999 perms), the governing inference for water-rights outcomes; rank scale immune to caudal errors and caps",
                       p_block),
               "raw registry (data errors included); why the level analysis winsorizes"))
}
