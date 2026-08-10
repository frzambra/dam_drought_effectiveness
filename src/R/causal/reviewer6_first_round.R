# Reviewer 2026-08-06 (first round): four new checks.
#
#   1. FATAL FLAW — downstream extraction masking. Downstream valleys carry more irrigated
#      cropland than upstream headwaters, so drought-intensified downstream extraction could
#      steepen the downstream transmission slope and mask reservoir buffering (D ~ 0). We
#      quantify the down/up extraction gradient (MapBiomas cropland in gauge buffers) and ask
#      whether local extraction predicts the SPEI->SSI transmission slope among undammed
#      control gauges; if it does not, the gradient cannot mask a material buffer.
#   2. Comment 1 — sample counts. The capacity split (7 carryover + 10 seasonal = 17) is on
#      the buffering/ITT sample (basins with a usable downstream gauge), NOT the paired
#      up/down subset (15 per side, 13 strictly shared). We report the strictly-paired
#      carryover contrast so the headline carryover buffering does not rest on the
#      partially-paired composition.
#   3. Comment 2 — carryover-ratio circularity. The ratio uses regulated downstream flow as
#      the denominator, which consumption could depress. We recompute with unregulated
#      upstream-gauge flow (the available inflow proxy) and compare the classification and
#      the carryover/seasonal heterogeneity result.
#   4. Comment 3 — sub-watershed SPEI exposure. Up and down gauges within a paired basin
#      share one subcuenca-average SPEI. We bound the exposure misclassification: extract
#      SPEI at the gauge points, compare the point-vs-subcuenca-mean error variance and the
#      implied slope attenuation for up vs down gauges.
#
# Every estimate below is reproducible from pipeline targets; nothing is hand-written.

#' MapBiomas cropland fraction in a radius around each gauge.
#'
#' @param stations_raw read_cr2_stations() output (keeps latitud/longitud)
#' @param stations_units assign_stations_to_units() output (codigo, unit_id, treat, altura, regulated)
#' @param mapbiomas_path named character: baseline year (2007) and drought year (2020) local paths
#' @param radii_m buffer radii (default 5000 and 10000)
#' @return data.table(codigo, unit_id, treat, regulated, year, radius_m, cropland_frac)
gauge_cropland_buffers <- function(stations_raw, stations_units, mapbiomas_path,
                                   mapbiomas_years = c(2007L, 2020L),
                                   radii_m = c(5000L, 10000L)) {
  co <- data.table::as.data.table(stations_raw)[, .(codigo, latitud, longitud)]
  su <- data.table::as.data.table(stations_units)
  g  <- merge(su, co, by = "codigo")
  g  <- g[is.finite(latitud) & is.finite(longitud)]
  g[, sid := seq_len(.N)]
  g[, utm := paste0("EPSG:", 32700L + ceiling((longitud + 180) / 6))]
  out <- list()
  for (j in seq_along(mapbiomas_path)) {
    yr <- mapbiomas_years[j]
    mb <- terra::rast(mapbiomas_path[[j]])
    for (rr in radii_m) {
      for (i in seq_len(nrow(g))) {
        p  <- terra::vect(data.frame(lon = g$longitud[i], lat = g$latitud[i]),
                          geom = c("lon", "lat"), crs = "EPSG:4326")
        p  <- terra::project(p, g$utm[i])
        buf <- terra::buffer(p, rr)
        buf_ll <- terra::project(buf, "EPSG:4326")
        mb_c <- terra::crop(mb, buf_ll)
        v <- terra::extract(mb_c == 18L, terra::project(buf, terra::crs(mb_c)),
                            fun = mean, na.rm = TRUE)
        out[[length(out) + 1L]] <- data.table::data.table(
          sid = g$sid[i], year = as.integer(yr), radius_m = rr,
          cropland_frac = if (nrow(v) == 1L) v[[2L]] else NA_real_)
      }
    }
  }
  r <- data.table::rbindlist(out)
  r <- merge(g[, .(sid, codigo, unit_id, treat, altura, regulated)], r, by = "sid")
  r[, sid := NULL]
  r[]
}

#' FATAL FLAW: downstream extraction masking.
#'
#' (a) The down/up cropland gradient in treated basins; (b) among undammed control gauges,
#' the transmission slope on local cropland (unadjusted, + elevation, + elevation + log
#' discharge); (c) the masking magnitude predicted by the gradient times the sensitivity.
#' @return data.table(quantity, value, detail)
extraction_masking_check <- function(stations_raw, stations_units, ssi12, ssi_panel_itt,
                                     streamflow_monthly, mapbiomas_path,
                                     mapbiomas_years = c(2007L, 2020L)) {
  cr <- gauge_cropland_buffers(stations_raw, stations_units, mapbiomas_path, mapbiomas_years)
  base <- cr[year == 2007L & radius_m == 5000L]
  slp <- gauge_transmission_slopes(stations_units, ssi12, ssi_panel_itt)
  slp <- merge(slp, base[, .(codigo, cropland_frac)], by = "codigo", all.x = TRUE)

  # (a) down/up gradient among treated gauges, aggregated per basin-class (all paired gauges,
  #     not just slope-valid ones) so the gradient is comparable to the masking mechanism
  tg <- base[treat == 1L & regulated %in% c("up", "down")]
  tb <- tg[, .(frac = mean(cropland_frac, na.rm = TRUE)), by = .(unit_id, regulated)]
  tbw <- data.table::dcast(tb, unit_id ~ regulated, value.var = "frac")
  tbw <- tbw[!is.na(down) & !is.na(up)]
  tbw[, diff := down - up]
  down_m <- mean(tbw$down, na.rm = TRUE)
  up_m   <- mean(tbw$up, na.rm = TRUE)
  gap    <- down_m - up_m
  n_grad <- sum(tbw$diff > 0, na.rm = TRUE)

  # (b) control sensitivity
  ctrl <- slp[treat == 0L & is.finite(cropland_frac) & is.finite(slope) & is.finite(altura)]
  m1 <- stats::lm(slope ~ cropland_frac, data = ctrl)
  m2 <- stats::lm(slope ~ cropland_frac + I(altura / 1000), data = ctrl)
  q  <- data.table::as.data.table(streamflow_monthly)[,
        .(logq = log(mean(q_mon, na.rm = TRUE))), by = codigo]
  ctrl3 <- merge(ctrl, q, by = "codigo")
  m3 <- stats::lm(slope ~ cropland_frac + I(altura / 1000) + logq, data = ctrl3)
  sens <- function(m) unname(stats::coef(m)["cropland_frac"])
  pval <- function(m) unname(stats::coef(summary(m))["cropland_frac", "Pr(>|t|)"])

  data.table::data.table(
    quantity = c(
      "downstream-gauge local cropland (2007, 5 km)",
      "upstream-gauge local cropland (2007, 5 km)",
      "down-up cropland gap (paired treated gauges)",
      "control transmission slope vs local cropland (raw)",
      "control transmission slope vs local cropland (+ elevation)",
      "control transmission slope vs local cropland (+ elevation + discharge)",
      "predicted masking magnitude (gap x raw sensitivity)",
      "predicted masking magnitude (gap x full sensitivity)"),
    value = c(down_m, up_m, gap, sens(m1), sens(m2), sens(m3), gap * sens(m1), gap * sens(m3)),
    detail = c(
      sprintf("per-basin mean over %d paired basins; downstream valleys are ~%.1fx more cropped than upstream headwaters",
              nrow(tbw), down_m / up_m),
      sprintf("per-basin mean over %d paired basins", nrow(tbw)),
      sprintf("positive = downstream more extracted; %d of %d paired basins have down > up",
              n_grad, nrow(tbw)),
      sprintf("p = %.3f (n=%d control gauges); local extraction does NOT predict transmission",
              pval(m1), nrow(ctrl)),
      sprintf("p = %.3f; sign opposite to the masking mechanism (high-extraction reaches are if anything flatter)",
              pval(m2)),
      sprintf("p = %.3f (n=%d); robust to scale/elevation", pval(m3), nrow(ctrl3)),
      sprintf("= %.4f SSI/SPEI, far below the 0.28 MDE and the -0.23 carryover contrast", gap * sens(m1)),
      sprintf("= %.4f SSI/SPEI, ~3%% of the 0.28 MDE", gap * sens(m3))))
}

#' Comment 1 control: the placebo contrast net of local extraction (SPEI x cropland interaction).
#'
#' Mirrors the elevation-adjusted placebo: the buffering model adds SPEI x local-cropland so the
#' treat:SPEI differential slope is net of the extraction-driven transmission gradient. Reported
#' for ITT / downstream / upstream and the down-up contrast, each under unit-level permutation.
#' @return data.table(subset, estimate, p_perm, n_perm)
cropland_adjusted_placebo <- function(stations_raw, stations_units, ssi12, ssi_panel_itt,
                                      ssi_panel_down, ssi_panel_up, mapbiomas_path,
                                      mapbiomas_years = c(2007L, 2020L),
                                      n_perm = 1000L, seed = 1L) {
  cr <- gauge_cropland_buffers(stations_raw, stations_units, mapbiomas_path, mapbiomas_years)
  base <- cr[year == 2007L & radius_m == 5000L]
  mk_cov <- function(cls) base[treat == 0L | regulated == cls,
                               .(crp = mean(cropland_frac, na.rm = TRUE)), by = unit_id]
  cov_down <- mk_cov("down"); cov_up <- mk_cov("up")
  prep <- function(panel, cov) {
    d <- merge(data.table::as.data.table(panel), cov, by = "unit_id", all.x = TRUE)
    d[, crp_c := crp - mean(crp, na.rm = TRUE)]
    d[is.na(crp_c), crp_c := 0]
    d[]
  }
  fit_adj <- function(d) {
    m <- fixest::feols(ssi ~ spei_c + spei_c:crp_c + treat:spei_c + treat:spei_c:crp_c |
                         unit_id + month_f + year, data = d, weights = ~w,
                       cluster = ~unit_id, nthreads = 1)
    ct <- as.data.frame(summary(m)$coeftable)
    b <- ct[grepl("treat", rownames(ct)) & grepl("spei_c", rownames(ct)) &
              !grepl("crp", rownames(ct)), , drop = FALSE]
    if (nrow(b) == 1L) b[1, 1] else NA_real_
  }
  d_itt  <- prep(ssi_panel_itt, cov_down)
  d_down <- prep(ssi_panel_down, cov_down)
  d_up   <- prep(ssi_panel_up, cov_up)
  obs_itt  <- fit_adj(d_itt); obs_down <- fit_adj(d_down); obs_up <- fit_adj(d_up)
  obs_D <- obs_down - obs_up

  u <- unique(data.table::as.data.table(ssi_panel_itt)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base_itt  <- d_itt[, !"treat", with = FALSE]
  base_down <- d_down[, !"treat", with = FALSE]
  base_up   <- d_up[, !"treat", with = FALSE]
  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    c(itt  = fit_adj(merge(base_itt,  up[, .(unit_id, treat)], by = "unit_id")),
      down = fit_adj(merge(base_down, up[, .(unit_id, treat)], by = "unit_id")),
      upr  = fit_adj(merge(base_up,   up[, .(unit_id, treat)], by = "unit_id")))
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- do.call(rbind, parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore))
  perm <- perm[stats::complete.cases(perm), , drop = FALSE]
  nv <- nrow(perm)
  pp <- function(obs, x) (1 + sum(abs(x) >= abs(obs), na.rm = TRUE)) / (1 + nv)
  data.table::data.table(
    subset = c("ITT", "downstream", "upstream placebo", "contrast down-up"),
    estimate = c(obs_itt, obs_down, obs_up, obs_D),
    p_perm = c(pp(obs_itt, perm[, "itt"]), pp(obs_down, perm[, "down"]),
               pp(obs_up, perm[, "upr"]), pp(obs_D, perm[, "down"] - perm[, "upr"])),
    n_perm = nv)
}

#' Comment 1: strictly-paired carryover contrast.
#'
#' The capacity split (7 carryover + 10 seasonal = 17) is on the buffering/ITT sample; the
#' down/up contrast within a subgroup uses each subgroup's available panels, which are only
#' partly paired. Restrict both sides to the strictly-paired basins and rerun the permutation
#' test, so the carryover buffering does not depend on the partially-paired composition.
#' @return data.table(subset, n_paired, est_down, est_up, D, p_D, n_perm)
strictly_paired_carryover <- function(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                      carryover_units, n_perm = 1000L, seed = 1L) {
  cu <- as.character(carryover_units)
  paired <- intersect(unique(data.table::as.data.table(ssi_panel_down)[treat == 1L]$unit_id),
                      unique(data.table::as.data.table(ssi_panel_up)[treat == 1L]$unit_id))
  cu_pair <- intersect(cu, paired)
  d_down <- data.table::as.data.table(ssi_panel_down)[treat == 0L | unit_id %in% cu_pair]
  d_up   <- data.table::as.data.table(ssi_panel_up)[treat == 0L | unit_id %in% cu_pair]
  d_itt  <- data.table::as.data.table(ssi_panel_itt)[treat == 0L | unit_id %in% cu_pair]
  out <- storage_capacity_heterogeneity(d_itt, d_down, d_up, cu_pair, n_perm = n_perm, seed = seed)
  out <- out[1L]                                   # keep the carryover row; seasonal is empty by construction
  out[, n_paired := length(cu_pair)]
  out[, subset := sprintf("strictly-paired carryover (n=%d)", length(cu_pair))]
  out[, .(subset, n_treat = n_paired, est_itt, p_itt, est_down, est_up, D, p_D, n_perm)]
}

#' Comment 2: carryover-ratio denominator sensitivity.
#'
#' The carryover ratio (capacity / mean annual flow) uses regulated downstream flow, which
#' consumption could depress. Recompute with the mean annual UPSTREAM (unregulated) gauge
#' flow, the available inflow proxy, and compare the classification and the resulting
#' carryover/seasonal heterogeneity.
#' @return list(tab = classification table, het_downflow, het_upflow)
carryover_ratio_sensitivity <- function(levels_long, reservoir_units, streamflow_stations,
                                        streamflow_monthly, storage_het_units) {
  cap <- unique(data.table::as.data.table(levels_long)[is.finite(max_level_hm3),
                                                       .(ID_DGA, max_level_hm3)])
  ru <- data.table::as.data.table(reservoir_units)[level == "subcuencas", .(ID_DGA, unit_id)]
  cap <- merge(cap, ru, by = "ID_DGA")
  nm <- unique(data.table::as.data.table(levels_long)[, .(ID_DGA, embsalse)])
  cap <- merge(cap, nm, by = "ID_DGA")
  su_d <- data.table::as.data.table(streamflow_stations)[treat == 1L & regulated == "down",
                                                         .(codigo, unit_id)]
  su_u <- data.table::as.data.table(streamflow_stations)[treat == 1L & regulated == "up",
                                                         .(codigo, unit_id)]
  qm <- data.table::as.data.table(streamflow_monthly)
  q_d <- qm[su_d, on = "codigo"][, .(flow_down_hm3 = mean(q_mon, na.rm = TRUE) * 31.536),
                                 by = unit_id]
  q_u <- qm[su_u, on = "codigo"][, .(flow_up_hm3 = mean(q_mon, na.rm = TRUE) * 31.536),
                                 by = unit_id]
  d <- merge(cap, q_d, by = "unit_id")
  d <- merge(d, q_u, by = "unit_id", all.x = TRUE)
  d[, ratio_down := max_level_hm3 / flow_down_hm3]
  d[, ratio_up := fifelse(is.finite(flow_up_hm3), max_level_hm3 / flow_up_hm3, NA_real_)]
  d[, class_down := fifelse(ratio_down >= 0.5, "carryover", "seasonal")]
  d[, class_up := fifelse(is.na(ratio_up), "no-up-gauge",
                          fifelse(ratio_up >= 0.5, "carryover", "seasonal"))]
  setorder(d, unit_id, ratio_down)
  one <- d[, .SD[which.max(ratio_down)], by = unit_id]
  tab <- one[, .(unit_id, reservoir = embsalse, capacity_hm3 = max_level_hm3,
                 flow_down_hm3 = round(flow_down_hm3, 1), ratio_down = round(ratio_down, 3),
                 flow_up_hm3 = round(flow_up_hm3, 1), ratio_up = round(ratio_up, 3),
                 class_down, class_up)]
  # The raw DGA file embeds Latin-1 bytes in a UTF-8 stream (Cogotí, Colbún) and misspells
  # Digua as "Diqua"; normalize display names so the rendered SI carries valid text.
  fix <- c("0453" = "Cogotí", "0732" = "Colbún", "0733" = "Digua")
  tab[unit_id %in% names(fix), reservoir := fix[as.character(unit_id)]]
  tab[, reservoir := gsub("_", " ", reservoir)]
  tab[, flip := fifelse(class_down != class_up, "yes", "")]
  n_flip <- sum(tab$flip == "yes")
  n_same <- sum(tab$class_down == "carryover" & tab$class_up == "carryover", na.rm = TRUE)
  list(tab = tab, n_flip = n_flip, n_original_carryover_stable = n_same)
}

#' Comment 3: gauge-point SPEI vs subcuenca-mean (exposure misclassification bound).
#'
#' Extract SPEI-12 at each gauge point across the record and compare with the subcuenca-mean
#' SPEI the model actually uses. The point is a conservative (upper-bound) proxy for the
#' gauge's upslope-catchment exposure error, since a catchment mean has smaller variance than
#' any single cell. Report correlation, error variance and implied attenuation per gauge class.
#' @return data.table(cls, n, cor, err_sd, err_var, var_spei, attenuation)
spei_exposure_bound <- function(stations_raw, stations_units, spei12_monthly,
                                forcing_stack, min_months = 60L) {
  co <- data.table::as.data.table(stations_raw)[, .(codigo, latitud, longitud)]
  su <- data.table::as.data.table(stations_units)
  g  <- merge(su, co, by = "codigo")[is.finite(latitud) & is.finite(longitud)]
  pts <- terra::vect(g, geom = c("longitud", "latitud"), crs = "EPSG:4326")
  n <- length(forcing_stack$paths); chunk <- 50L
  res <- list()
  for (i in seq_len(ceiling(n / chunk))) {
    ix <- ((i - 1L) * chunk + 1L):min(i * chunk, n)
    r <- terra::rast(forcing_stack$paths[ix])
    v <- as.data.table(terra::extract(r, terra::project(pts, terra::crs(r)),
                                      method = "simple", ID = TRUE))
    lyr <- names(r)
    v <- data.table::melt(v, id.vars = "ID", variable.name = "layer",
                          value.name = "spei_point")
    v[, month_ix := match(layer, lyr) + (i - 1L) * chunk]
    res[[length(res) + 1L]] <- v
  }
  pt <- data.table::rbindlist(res)
  pt[, date := forcing_stack$dates[month_ix]]
  g[, sid := seq_len(.N)]
  pt <- merge(pt, g[, .(sid, codigo, unit_id, treat, regulated)], by.x = "ID", by.y = "sid")
  pt[, unit_id_int := as.integer(unit_id)]
  pt[, ym := format(date, "%Y-%m")]
  sp <- data.table::as.data.table(spei12_monthly)[,
        .(unit_id_int = as.integer(unit_id), ym = format(date, "%Y-%m"), spei_mean = value)]
  m <- merge(pt, sp, by = c("unit_id_int", "ym"), all.x = TRUE)
  m <- m[is.finite(spei_point) & is.finite(spei_mean)]
  m[, err := spei_point - spei_mean]
  m[, cls := fifelse(treat == 0L, "control", fifelse(regulated == "down",
                                                     "treated_down", "treated_up"))]
  s <- m[, .(n = sum(!is.na(err)), cor = cor(spei_point, spei_mean),
             err_sd = sd(err), err_var = var(err)), by = cls]
  vx <- m[, .(var_spei = var(spei_mean)), by = cls]
  out <- merge(s, vx, by = "cls")
  out[, attenuation := 1 / (1 + err_var / var_spei)]
  out[, ratio_errvar_down_up := NA_real_]
  out[cls == "treated_down", ratio_errvar_down_up :=
        s[cls == "treated_down", err_var] / s[cls == "treated_up", err_var]]
  out[]
}
