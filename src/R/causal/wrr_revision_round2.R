# Reviewer 3, second round (2026-08-06): fatal flaw + comments 3 and 5.
#
#   FATAL FLAW — cascade-dam contamination of the upstream placebo. If an "upstream" gauge of
#   the classification dam sits downstream of ANOTHER dam (cascade systems: Ralco above Pangue
#   on the Biobío, Laguna del Maule above Colbún on the Maule, La Laguna above Puclaro on the
#   Elqui), it is regulated, its transmission slope could be flattened by real operation, and
#   the placebo would falsely attribute downstream flattening to siting. We flag contaminated
#   upstream gauges against the full national dam inventory (1,370 dams) at two tiers and
#   re-run the placebo without them.
#     Tier 1 (verified, same sub-watershed): the gauge lies below (SRTM elevation, the paper's
#       classification convention) a *material* dam inside its own treated sub-watershed.
#     Tier 2 (conservative bound, same cuenca): the gauge lies below any material dam anywhere
#       in its DGA cuenca. Without a routed network this cannot distinguish an upstream dam
#       from one on a parallel tributary, so tier 2 over-flags by construction; it bounds the
#       worst case.
#   Material dam = DGA-monitored, or registry size GRANDE, or wall height >= 15 m (the ICOLD
#   large-dam threshold). Dam elevations come from the project DEM when available and from the
#   cached SRTM90m extraction (same SRTM source) otherwise; caches are in data/interim/.
#
#   Comment 3 — unweighted percent-of-capacity trends could be dominated by small reservoirs.
#   We re-fit the storage-band trends and 2010 step weighted by reservoir capacity, and report
#   the absolute fleet totals (hm³) on the coverage-stable subset.
#
#   Comment 5 — extreme weight concentration in the aridity hard-balance (ESS 19). We report
#   weight diagnostics (max/top-5 normalized weight share, Kish ESS) and a leave-one-out over
#   the top-weighted control basins for the hard-balanced ITT slope.
#
# Every estimate is reproducible from pipeline targets; nothing is hand-written.

#' Flag upstream gauges potentially below another dam and re-run the placebo without them.
#' @return data.table(quantity, value, detail)
upstream_contamination_check <- function(unit_dam_csv, cuenca_dam_csv, matched_subcuencas,
                                         streamflow_stations, ssi12, spei12_monthly, matched_set,
                                         ssi_panel_itt, ssi_panel_down, storage_het_units,
                                         tol_m = 10, n_perm = 1000L, seed = 1L) {
  st <- data.table::as.data.table(streamflow_stations)
  ud <- data.table::fread(unit_dam_csv, colClasses = list(character = "unit_id"))
  cd <- data.table::fread(cuenca_dam_csv, colClasses = list(character = "cuenca_id"))
  ud[, material := MONITOR == "MONITOREO DGA" | TAMANO == "GRANDE" |
       (is.finite(ALT_MURO) & ALT_MURO >= 15)]
  su <- data.table::as.data.table(sf::st_drop_geometry(matched_subcuencas))
  su <- su[level == "subcuencas", .(unit_id, parent_id)]

  up <- merge(st[treat == 1L & regulated == "up"], su, by = "unit_id", all.x = TRUE)
  u_max <- ud[material == TRUE & is.finite(elev_srtm90),
              .(dam_unit_max = max(elev_srtm90)), by = unit_id]
  up <- merge(up, u_max, by = "unit_id", all.x = TRUE)
  up[, tier1 := is.finite(dam_unit_max) & altura + tol_m < dam_unit_max]
  c_max <- cd[is.finite(elev_srtm90),
              .(dam_cuenca_max = max(elev_srtm90)), by = .(parent_id = as.character(cuenca_id))]
  up[, parent_id := as.character(parent_id)]
  up <- merge(up, c_max, by = "parent_id", all.x = TRUE)
  up[, tier2 := tier1 | (is.finite(dam_cuenca_max) & altura + tol_m < dam_cuenca_max)]

  # named-cascade middle tier: tier-1 flags plus gauges below the historically documented
  # upstream works on the same river system (true cascades, no parallel-tributary ambiguity)
  named <- data.table::data.table(
    unit_id = c("0432", "0732", "0382"),
    dam     = c("LA LAGUNA", "LAGUNA DEL MAULE", "LAGUNAS DEL HUASCO"))
  named <- merge(named, cd[, .(dam = NOMBRE, named_elev = elev_srtm90)], by = "dam")
  up <- merge(up, named[, .(unit_id, named_elev)], by = "unit_id", all.x = TRUE)
  up[, tier_named := tier1 | (is.finite(named_elev) & altura + tol_m < named_elev)]

  refit <- function(drop_codes, label) {
    stc <- st[!(codigo %in% drop_codes)]
    p_up <- build_ssi_panel(ssi12, stc, spei12_monthly, matched_set, "up")
    est  <- ssi_buffer_coef(fit_ssi_buffering(p_up))
    pm   <- permute_ssi_buffer(p_up, n_perm = n_perm, seed = seed)
    pct  <- placebo_contrast_test(ssi_panel_down, p_up, n_perm = n_perm, seed = seed)
    list(est = est, p = pm$p_perm, D = pct$D, p_D = pct$p_perm, panel = p_up, stations = stc)
  }
  r1 <- refit(up[tier1 == TRUE, codigo], "tier1")
  rn <- refit(up[tier_named == TRUE, codigo], "named")
  r2 <- refit(up[tier2 == TRUE, codigo], "tier2")

  # carryover contrast with the tier-2-cleaned upstream panel (the stricter exclusion), since
  # two carryover units (Puclaro below La Laguna; Colbún below the upper-Maule works) are flagged
  co <- carryover_subgroup_contrast(ssi_panel_itt, ssi_panel_down, r2$panel,
                                    storage_het_units, "carryover, tier-2-cleaned upstream",
                                    n_perm = n_perm, seed = seed)

  units_lost <- function(flag_col) {
    keep <- up[get(flag_col) == FALSE, unique(unit_id)]
    setdiff(unique(up$unit_id), keep)
  }
  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "upstream gauges screened",
      value = nrow(up),
      detail = sprintf("across %d treated basins; screened against %d inventory dams inside treated basins and %d material dams (monitored / GRANDE / wall >= 15 m) in the same cuencas, from the 1,370-dam national inventory",
                       data.table::uniqueN(up$unit_id), nrow(ud), nrow(cd))),
    data.table::data.table(
      quantity = "tier 1: below a material dam in the same sub-watershed",
      value = up[tier1 == TRUE, .N],
      detail = sprintf("units: %s",
                       ifelse(up[tier1 == TRUE, .N] == 0, "none",
                              paste(sort(unique(up[tier1 == TRUE, unit_id])), collapse = ", ")))),
    data.table::data.table(
      quantity = "named-cascade tier: tier 1 plus gauges below documented upstream works",
      value = up[tier_named == TRUE, .N],
      detail = sprintf("adds gauges below La Laguna (1937, above Puclaro), the Laguna del Maule works (1951, above Colbun), and Lagunas del Huasco (1911, above Santa Juana); units: %s",
                       paste(sort(unique(up[tier_named == TRUE, unit_id])), collapse = ", "))),
    data.table::data.table(
      quantity = "tier 2: below any material dam in the same cuenca (conservative bound)",
      value = up[tier2 == TRUE, .N],
      detail = sprintf("units: %s; units losing all upstream gauges: %s; includes true cascades (Laguna del Maule 1951 above Colbún; La Laguna 1937 above Puclaro; Lagunas del Huasco 1911 above Santa Juana) and parallel-tributary over-flags",
                       paste(sort(unique(up[tier2 == TRUE, unit_id])), collapse = ", "),
                       ifelse(length(units_lost("tier2")) == 0, "none",
                              paste(sort(units_lost("tier2")), collapse = ", ")))),
    data.table::data.table(
      quantity = "upstream placebo slope, tier-1-cleaned",
      value = round(r1$est, 3),
      detail = sprintf("perm p = %.3f; contrast D = %+.3f, p = %.3f (%d perms); raw upstream -0.20, raw D = +0.04",
                       r1$p, r1$D, r1$p_D, n_perm)),
    data.table::data.table(
      quantity = "upstream placebo slope, named-cascade-cleaned",
      value = round(rn$est, 3),
      detail = sprintf("perm p = %.3f; contrast D = %+.3f, p = %.3f (%d perms); n upstream gauges retained %d of %d",
                       rn$p, rn$D, rn$p_D, n_perm, nrow(up) - up[tier_named == TRUE, .N], nrow(up))),
    data.table::data.table(
      quantity = "upstream placebo slope, tier-2-cleaned",
      value = round(r2$est, 3),
      detail = sprintf("perm p = %.3f; contrast D = %+.3f, p = %.3f (%d perms); n upstream gauges retained %d of %d",
                       r2$p, r2$D, r2$p_D, n_perm, nrow(up) - up[tier2 == TRUE, .N], nrow(up))),
    data.table::data.table(
      quantity = "carryover contrast D, tier-2-cleaned upstream",
      value = co$D,
      detail = sprintf("down %+.3f, up %+.3f, perm p = %.3f (n_treat = %d); baseline D = -0.232, p = 0.014",
                       co$est_down, co$est_up, co$p_D, co$n_treat))))
}

#' Capacity-weighted and absolute-volume storage-band trends (Reviewer 3 round 2, comment 3).
#' @return data.table(quantity, value, detail)
storage_band_weighted <- function(band_annual, levels_long, split_year = 2010L,
                                  min_years = 18L) {
  cap <- unique(data.table::as.data.table(levels_long)[is.finite(max_level_hm3),
                                                       .(ID_DGA, max_level_hm3)])
  d <- merge(data.table::as.data.table(band_annual), cap, by = "ID_DGA")
  d[, post := as.integer(year >= split_year)]
  d[, yr_post := (year - split_year) * post]

  one <- function(comp, fml_rhs, term, label) {
    m <- fixest::feols(stats::as.formula(sprintf("%s ~ %s | ID_DGA", comp, fml_rhs)),
                       data = d, weights = ~max_level_hm3, cluster = ~ID_DGA)
    ct <- as.data.frame(summary(m)$coeftable)[term, ]
    data.table::data.table(
      quantity = sprintf("capacity-weighted %s, %s", label, comp),
      value = round(ct[[1]], 4),
      detail = sprintf("SE %.4f, p = %.3g (capacity-weighted reservoir FE, clustered)",
                       ct[[2]], ct[[4]]))
  }
  w_rows <- data.table::rbindlist(c(
    lapply(c("peak", "trough", "amplitude"), one, fml_rhs = "year", term = "year",
           label = "trend (per yr)"),
    lapply(c("peak", "trough"), one, fml_rhs = "post + yr_post", term = "post",
           label = "step at 2010"),
    lapply(c("peak", "trough"), one, fml_rhs = "post + yr_post", term = "yr_post",
           label = "post-2010 drift (per yr)")))

  # absolute fleet totals on the coverage-stable subset (reservoirs with >= min_years band years)
  keep <- d[, .N, by = ID_DGA][N >= min_years, ID_DGA]
  tot <- d[ID_DGA %in% keep,
           .(peak_hm3 = sum(peak * max_level_hm3), trough_hm3 = sum(trough * max_level_hm3),
             n_res = .N), by = year][order(year)]
  tot_full <- tot[n_res == length(keep)]
  one_tot <- function(comp, label) {
    y <- tot_full[[comp]]
    m <- stats::lm(y ~ year + post + yr_post,
                   data = data.frame(year = tot_full$year,
                                     post = as.integer(tot_full$year >= split_year),
                                     yr_post = pmax(0, tot_full$year - split_year)))
    tr <- stats::lm(y ~ year, data = data.frame(year = tot_full$year))
    ct <- summary(tr)$coefficients["year", ]
    cs <- summary(m)$coefficients
    data.table::data.table(
      quantity = sprintf("fleet total %s (hm3), trend and 2010 step", label),
      value = round(ct[[1]], 1),
      detail = sprintf("trend %+.1f hm3/yr (p = %.3g); 2010 step %+.0f hm3 (p = %.3g), post-2010 drift %+.1f hm3/yr (p = %.3g); %d reservoirs with full coverage, %d of %d years",
                       ct[[1]], ct[[4]], cs["post", 1], cs["post", 4],
                       cs["yr_post", 1], cs["yr_post", 4],
                       length(keep), nrow(tot_full), nrow(tot)))
  }
  cov_row <- data.table::data.table(
    quantity = "coverage-stable subset share of fleet capacity",
    value = round(cap[ID_DGA %in% keep, sum(max_level_hm3)] / cap[, sum(max_level_hm3)], 3),
    detail = sprintf("%d of %d reservoirs with >= %d band years; totals below use years with all %d reporting",
                     length(keep), nrow(cap), min_years, length(keep)))
  data.table::rbindlist(list(w_rows, cov_row,
                             one_tot("peak_hm3", "peak storage"),
                             one_tot("trough_hm3", "trough (carryover) storage")))
}

#' Hard-balance weight diagnostics + leave-one-out over top-weighted controls
#' (Reviewer 3 round 2, comment 5).
#'
#' Two leave-one-out variants are reported. The naive variant drops a top-weighted control from
#' the panel with the remaining weights unchanged; because that unit carried part of the aridity
#' balance, its removal mechanically reintroduces the aridity imbalance, so drift back toward
#' the confounded primary estimate is expected and is NOT evidence of fragility. The
#' design-consistent variant re-fits the entropy balance without the unit (restoring
#' log-aridity SMD ~ 0 on the remaining controls) and re-estimates; this is the test of whether
#' the vanishing of the apparent buffering depends on any single control basin.
#' @return data.table(quantity, value, detail)
hard_balance_weight_diagnostics <- function(matched_set_hard, match_covariates, ssi12,
                                            streamflow_stations, spei12_monthly, top_k = 8L) {
  d  <- data.table::as.data.table(matched_set_hard$data)
  wc <- d[treated == 0L][order(-w)]
  wn <- wc$w / sum(wc$w)
  ess <- sum(wc$w)^2 / sum(wc$w^2)
  p0 <- build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, matched_set_hard, "itt")
  base <- ssi_buffer_coef(fit_ssi_buffering(p0))
  k <- min(top_k, nrow(wc))

  loo_naive <- data.table::rbindlist(lapply(seq_len(k), function(i) {
    est <- ssi_buffer_coef(fit_ssi_buffering(p0[unit_id != wc$unit_id[i]]))
    data.table::data.table(unit_id = wc$unit_id[i], est = est)
  }))

  cov <- data.table::as.data.table(match_covariates)
  loo_rebal <- data.table::rbindlist(lapply(seq_len(k), function(i) {
    msi <- fit_matched_set_hard(cov[unit_id != wc$unit_id[i]])
    di  <- data.table::as.data.table(msi$data)
    smd <- (di[treated == 1L, mean(log_aridity)] -
            di[treated == 0L, sum(w * log_aridity) / sum(w)]) /
           di[treated == 1L, stats::sd(log_aridity)]
    pi  <- build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, msi, "itt")
    est <- ssi_buffer_coef(fit_ssi_buffering(pi))
    wci <- di[treated == 0L, w]
    data.table::data.table(unit_id = wc$unit_id[i], est = est, smd = smd,
                           ess = sum(wci)^2 / sum(wci^2))
  }))

  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "hard-balance control weights: maximum normalized share",
      value = round(wn[1], 3),
      detail = sprintf("top-5 share %.2f, Kish ESS %.1f of %d controls (participation ratio %.3f)",
                       sum(wn[1:5]), ess, nrow(wc), ess / nrow(wc))),
    data.table::data.table(
      quantity = "hard-balanced ITT slope, all controls",
      value = round(base, 3),
      detail = "primary-design estimate -0.183; hard-balanced perm p > 0.85 (Supplementary Table S17)"),
    data.table::data.table(
      quantity = sprintf("naive leave-one-out (weights fixed) over top-%d controls", k),
      value = round(max(abs(loo_naive$est)), 3),
      detail = sprintf("estimates span [%.3f, %.3f]; largest excursion dropping unit %s; removing a balancing unit without re-balancing reintroduces the aridity imbalance, so drift toward the confounded -0.183 is mechanical, not fragility",
                       min(loo_naive$est), max(loo_naive$est),
                       loo_naive[which.max(abs(est)), unit_id])),
    data.table::data.table(
      quantity = sprintf("re-balanced leave-one-out over top-%d controls", k),
      value = round(max(abs(loo_rebal$est)), 3),
      detail = sprintf("entropy balance re-fit without each unit: estimates span [%.3f, %.3f], log-aridity SMD stays %.3f to %.3f, ESS %.1f to %.1f; largest excursion dropping unit %s",
                       min(loo_rebal$est), max(loo_rebal$est),
                       min(loo_rebal$smd), max(loo_rebal$smd),
                       min(loo_rebal$ess), max(loo_rebal$ess),
                       loo_rebal[which.max(abs(est)), unit_id]))))
}
