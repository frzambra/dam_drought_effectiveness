# WRR revision round (2026-08-06, second round): hardening the carryover heterogeneity claim.
#
# The carryover subgroup (7 treated units, contrast D = -0.23, p = 0.014) is the paper's only
# significant result, and an exploratory reviewer-prompted split, so it draws two attacks:
#
#   1. Use-type confounding. The carryover class mixes five irrigation reservoirs (Conchi,
#      Santa Juana, Puclaro, Recoleta, Cogotí) with two large dams whose operation involves
#      hydropower generation (Colbún, registry use RIEGO / GENERACIÓN DE ENERGÍA; Lago Laja,
#      operated jointly for irrigation and generation under its 1958 operating agreement).
#      If D is driven by the hydropower pair, "carryover capacity buffers multi-year drought"
#      collapses into "hydropower scheduling smooths flows". We re-estimate the contrast on
#      the irrigation-only carryover basins.
#   2. Leave-one-out fragility of the p-value. With seven treated units a single basin can
#      move the permutation p across 0.05; the reported point-estimate stability (D from
#      -0.28 to -0.22) is not enough. Each leave-one-out contrast is re-run with its own
#      permutation null.
#
# Every estimate is reproducible from pipeline targets; nothing is hand-written.

#' Down/up placebo contrast for one treated subgroup, under the design's permutation inference.
#'
#' Mirrors the run_group machinery of storage_capacity_heterogeneity() for a single subgroup:
#' treated units outside `units` are dropped from the panels (controls unchanged), the ITT,
#' downstream, and upstream buffering slopes are re-fit, and the treatment label is permuted at
#' the unit level within kg_group x aridity-tercile strata, with the same draw applied to all
#' three panels so the contrast D = beta_down - beta_up carries its own paired null.
#' @return data.table(subset, n_treat, est_itt, p_itt, est_down, est_up, D, p_D, n_perm)
carryover_subgroup_contrast <- function(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                        units, label, n_perm = 1000L, seed = 1L) {
  units <- as.character(units)
  keep <- function(p) data.table::as.data.table(p)[treat == 0L | unit_id %in% units]
  d_itt  <- keep(ssi_panel_itt)
  d_down <- keep(ssi_panel_down)
  d_up   <- keep(ssi_panel_up)
  fit_buf <- function(d) ssi_buffer_coef(fit_ssi_buffering(d))
  est_itt  <- fit_buf(d_itt)
  est_down <- fit_buf(d_down)
  est_up   <- fit_buf(d_up)
  D <- est_down - est_up

  u <- unique(d_itt[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base_itt  <- d_itt[,  !"treat", with = FALSE]
  base_down <- d_down[, !"treat", with = FALSE]
  base_up   <- d_up[,   !"treat", with = FALSE]
  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    c(itt  = fit_buf(merge(base_itt,  up[, .(unit_id, treat)], by = "unit_id")),
      down = fit_buf(merge(base_down, up[, .(unit_id, treat)], by = "unit_id")),
      upr  = fit_buf(merge(base_up,   up[, .(unit_id, treat)], by = "unit_id")))
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- do.call(rbind, parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore))
  perm <- perm[stats::complete.cases(perm), , drop = FALSE]
  nv <- nrow(perm)
  pp <- function(o, x) (1 + sum(abs(x) >= abs(o), na.rm = TRUE)) / (1 + nv)
  data.table::data.table(
    subset = label,
    n_treat = length(unique(d_itt[treat == 1L]$unit_id)),
    est_itt = round(est_itt, 3), p_itt = round(pp(est_itt, perm[, "itt"]), 3),
    est_down = round(est_down, 3), est_up = round(est_up, 3),
    D = round(D, 3), p_D = round(pp(D, perm[, "down"] - perm[, "upr"]), 3), n_perm = nv)
}

#' Carryover-claim robustness battery: irrigation-only (hydropower excluded) + leave-one-out.
#'
#' @param carryover_units carryover unit ids (storage_het_units target)
#' @param hydro_units carryover units whose reservoir operation involves hydropower generation
#'   (Colbún 0732 per the DGA registry use field; Lago Laja 0837 per its joint
#'   irrigation-generation operating regime)
#' @param unit_names optional named character vector (names = unit ids) for display labels
#' @return data.table, one row per check
carryover_robustness_checks <- function(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                        carryover_units, hydro_units = c("0732", "0837"),
                                        unit_names = NULL, n_perm = 1000L, seed = 1L) {
  cu <- as.character(carryover_units)
  nm <- function(u) if (!is.null(unit_names) && u %in% names(unit_names)) unit_names[[u]] else u
  irr <- setdiff(cu, hydro_units)
  rows <- list(carryover_subgroup_contrast(
    ssi_panel_itt, ssi_panel_down, ssi_panel_up, irr,
    sprintf("irrigation-only carryover (hydropower excluded, n=%d)", length(irr)),
    n_perm = n_perm, seed = seed))
  for (u in cu) {
    rows[[length(rows) + 1L]] <- carryover_subgroup_contrast(
      ssi_panel_itt, ssi_panel_down, ssi_panel_up, setdiff(cu, u),
      sprintf("leave-one-out: drop %s", nm(u)), n_perm = n_perm, seed = seed)
  }
  data.table::rbindlist(rows)
}
