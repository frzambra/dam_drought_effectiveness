# H1 buffering on STREAMFLOW (the vegetation-independent availability outcome). Design by
# drought-propagation-analyst (.claude/agent-memory/.../streamflow-ssi-test-design.md):
# does meteorological drought (SPEI) propagate LESS to streamflow drought (SSI) in dammed vs matched
# control basins? Estimand = differential SPEI->SSI slope: feols(SSI ~ treat:spei_c + spei_c | ...);
# both indices are negative=dry so baseline spei slope is POSITIVE and H1 buffering => treat:spei_c
# NEGATIVE (treated flow held up under deficit). ITT (all gauges in dammed units) is the conservative
# primary; downstream-only (gauge below dam) the refinement; upstream-only the decisive placebo.
# SSI = per-calendar-month Gringorten normal-quantile transform of trailing-12-month mean flow.

#' Gringorten normal-quantile transform of a vector (robust SSI standardization; handles skew/zeros).
#' Climate-driven supply baseline: log-linear trend in annual mean streamflow (%/yr) among control
#' (undammed) vs dammed gauges, the independent benchmark for the descriptive reservoir-storage
#' decline (addresses the missing-control critique: is the storage decline commensurate with the
#' supply reduction seen in unregulated flow?).
#' @return data.table(group, trend_pct_yr, n_gauges)
streamflow_supply_trend <- function(streamflow_monthly, streamflow_stations,
                                    y0 = 2005L, y1 = 2020L, min_months = 8L) {
  qm <- data.table::as.data.table(streamflow_monthly)
  data.table::setnames(qm, "q_mon", "q", skip_absent = TRUE)
  qm <- merge(qm, data.table::as.data.table(streamflow_stations)[, .(codigo, treat)], by = "codigo")
  qa <- qm[year >= y0 & year <= y1 & is.finite(q) & q >= 0,
           .(q = mean(q), nmo = .N), by = .(codigo, treat, year)][nmo >= min_months]
  qa[, lq := log(q + 1e-3)]
  data.table::rbindlist(lapply(c(0L, 1L), function(g) {
    m <- fixest::feols(lq ~ year | codigo, data = qa[treat == g])
    data.table::data.table(group = if (g == 0L) "control" else "dammed",
                           trend_pct_yr = 100 * unname(stats::coef(m)["year"]),
                           n_gauges = data.table::uniqueN(qa[treat == g]$codigo))
  }))
}

.nqt <- function(x) {
  ok <- is.finite(x); out <- rep(NA_real_, length(x))
  n <- sum(ok); if (n < 5L) return(out)
  r <- rank(x[ok], ties.method = "average")
  out[ok] <- stats::qnorm((r - 0.44) / (n + 0.12))
  out
}

#' Dam elevation per matched subcuenca = DEM at reservoir points (lowest dam in the unit ~ outlet).
#' Used to classify gauges as downstream (altura < dam elevation) vs upstream within dammed units.
#' @return data.table(unit_id, dam_elev_m)
extract_dam_elevation <- function(points, reservoir_units, sources) {
  dem <- terra::rast(sources$dem$path)
  pv  <- terra::vect(points)
  if (!terra::same.crs(pv, dem)) pv <- terra::project(pv, dem)
  e <- terra::extract(dem, pv, ID = FALSE)[, 1]
  e[e < -100] <- NA                                       # DEM void fill guard (config note)
  dt <- data.table::data.table(ID_DGA = points$ID_DGA, elev = e)
  ru <- data.table::as.data.table(reservoir_units)[level == "subcuencas", .(ID_DGA, unit_id)]
  m  <- merge(ru, dt, by = "ID_DGA")[is.finite(elev)]
  m[, .(dam_elev_m = min(elev)), by = unit_id]
}

#' Read CR2 station metadata (lat/lon, altura, BNA codes, record span).
read_cr2_stations <- function(sources) {
  sf_cfg <- sources$streamflow
  d <- data.table::fread(file.path(sf_cfg$dir, sf_cfg$stations_file))
  d[, `:=`(codigo = as.integer(codigo_estacion),
           fin_yr = as.integer(substr(fin_observaciones, 1, 4)))]
  d[]
}

#' Assign gauges to matched subcuencas (point-in-polygon) + treatment + up/down-dam class.
#' `dam_elev` (unit_id -> dam elevation m) lets us flag downstream (gauge altura < dam elev) vs
#' upstream gauges within dammed units; controls are all "natural".
#' @return data.table(codigo, unit_id, treat, altura, regulated)  regulated in {"down","up","ctrl"}
assign_stations_to_units <- function(stations, units, matched_set, dam_elev = NULL,
                                     fin_min = 2010L, min_obs = 3650L) {
  use <- data.table::as.data.table(stations)[fin_yr >= fin_min & cantidad_observaciones >= min_obs &
                                             is.finite(latitud) & is.finite(longitud)]
  pts <- sf::st_as_sf(use, coords = c("longitud", "latitud"), crs = 4326, remove = FALSE)
  u <- sf::st_transform(sf::st_as_sf(units), 4326)
  ix <- sf::st_join(pts, u["unit_id"], join = sf::st_within)
  ix <- data.table::as.data.table(sf::st_drop_geometry(ix))[!is.na(unit_id)]
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, treat = treated)]
  ix <- merge(ix, ms, by = "unit_id")
  ix[, regulated := "ctrl"]
  if (!is.null(dam_elev)) {
    ix <- merge(ix, data.table::as.data.table(dam_elev), by = "unit_id", all.x = TRUE)
    ix[treat == 1, regulated := data.table::fifelse(is.finite(dam_elev_m) & altura < dam_elev_m,
                                                    "down", "up")]
  } else {
    ix[treat == 1, regulated := "down"]   # no elevation -> treat all dammed gauges as ITT
  }
  ix[, .(codigo, unit_id, treat, altura, regulated)]
}

#' Read monthly mean flow for a set of stations from the wide CR2 file (reads only needed columns).
#' Requires >= `min_days` valid (non-NoData, non-negative) days per month.
#' @return data.table(codigo, year, month, q_mon)
read_cr2_monthly_flow <- function(sources, keep_codes, min_days = 20L) {
  f <- file.path(sources$streamflow$dir, sources$streamflow$data_file)
  hdr   <- data.table::fread(f, nrows = 1L, header = FALSE)
  codes <- as.integer(unlist(hdr[1, -1]))                 # station codes (drop label cell)
  idx   <- which(codes %in% keep_codes)
  dat <- data.table::fread(f, skip = 15L, header = FALSE, select = c(1L, idx + 1L),
                           na.strings = "-9999")
  data.table::setnames(dat, c("date", as.character(codes[idx])))
  dat[, date := as.IDate(date)]
  long <- data.table::melt(dat, id.vars = "date", variable.name = "codigo", value.name = "q")
  long <- long[is.finite(q) & q >= 0]
  mon <- long[, .(q_mon = mean(q), nday = .N),
              by = .(codigo = as.integer(as.character(codigo)),
                     year = data.table::year(date), month = data.table::month(date))]
  mon[nday >= min_days, .(codigo, year, month, q_mon)]
}

#' SSI-`accum` per station: trailing-`accum`-month mean flow, Gringorten NQT per calendar month over
#' the `ref_years` window (common reference so the megadrought is not baked into the baseline).
#' @return data.table(codigo, year, month, ssi)
compute_ssi <- function(monthly_flow, accum = 12L, ref_years = 2000:2020, min_months = 96L) {
  d <- data.table::as.data.table(monthly_flow)
  grid <- d[, data.table::CJ(year = min(year):max(year), month = 1:12), by = codigo]
  d <- merge(grid, d, by = c("codigo", "year", "month"), all.x = TRUE)
  data.table::setorder(d, codigo, year, month)
  d[, roll := data.table::frollmean(q_mon, accum, align = "right", na.rm = FALSE), by = codigo]
  d <- d[year %in% ref_years & is.finite(roll)]
  d[, ssi := .nqt(roll), by = .(codigo, month)]
  d[, n_ssi := sum(is.finite(ssi)), by = codigo]
  d[n_ssi >= min_months & is.finite(ssi), .(codigo, year, month, ssi)]
}

#' Build the unit-month SSI panel for a treatment subset: aggregate gauge SSI to subcuenca (mean),
#' merge monthly SPEI-12 forcing + matched covariates. `subset` selects which dammed gauges count as
#' treated: "itt" (all), "down" (downstream only), "up" (upstream only, the placebo). Controls always
#' included as treat=0.
#' @return data.table(unit_id, year, month, ssi, spei, spei_c, treat, w, kg_group, aridity_mean)
build_ssi_panel <- function(ssi, stations_units, spei12_monthly, matched_set, subset = "itt") {
  su <- data.table::as.data.table(stations_units)
  keep <- su[treat == 0 | switch(subset,
                                 itt  = treat == 1,
                                 down = regulated == "down",
                                 up   = regulated == "up")]
  d <- merge(data.table::as.data.table(ssi), keep[, .(codigo, unit_id, treat)], by = "codigo")
  unit_m <- d[, .(ssi = mean(ssi, na.rm = TRUE)), by = .(unit_id, treat, year, month)]
  sp <- data.table::as.data.table(spei12_monthly)[, .(unit_id, year = data.table::year(date),
                                                      month = data.table::month(date), spei = value)]
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, w, kg_group, aridity_mean)]
  p <- merge(merge(unit_m, sp, by = c("unit_id", "year", "month")), ms, by = "unit_id")
  p <- p[is.finite(ssi) & is.finite(spei)]
  p[, spei_c := spei - mean(spei)]
  p[, month_f := factor(month)]
  p[]
}

#' Forcing-interacted streamflow buffering model. H1 buffering => treat:spei_c NEGATIVE.
fit_ssi_buffering <- function(ssi_panel) {
  # nthreads=1: this runs inside parallel::mclapply for permutation; fixest's internal
  # multithreading would oversubscribe cores across forks and thrash.
  fixest::feols(ssi ~ spei_c + treat:spei_c | unit_id + month_f + year,
                data = ssi_panel, weights = ~w, cluster = ~unit_id, nthreads = 1)
}

#' Slope-gap coefficient (treat:spei_c) regardless of fixest naming.
ssi_buffer_coef <- function(model) {
  cf <- stats::coef(model); nm <- names(cf)
  hit <- nm[grepl("spei_c", nm) & grepl("treat", nm)]
  if (length(hit) != 1L) return(NA_real_); unname(cf[hit])
}

#' Tidy one-row-per-subset summary of the streamflow buffering test (treat:spei_c + permutation p).
#' The upstream-placebo row is the decisive discriminator: a non-null there means siting, not the dam.
ssi_buffer_summary <- function(buf_itt, buf_down, buf_up, perm_itt, perm_down, perm_up) {
  row <- function(m, pm, lab) {
    ct <- as.data.frame(summary(m)$coeftable)
    r  <- ct[grepl("spei_c", rownames(ct)) & grepl("treat", rownames(ct)), , drop = FALSE]
    data.table::data.table(subset = lab, treat_spei_c = r[1, 1], se = r[1, 2],
                           cluster_p = r[1, 4], perm_p = pm$p_perm, n_perm = pm$n_perm)
  }
  out <- data.table::rbindlist(list(row(buf_itt, perm_itt, "ITT"),
                                    row(buf_down, perm_down, "downstream"),
                                    row(buf_up, perm_up, "upstream placebo")))
  out[, buffering := data.table::fifelse(perm_p < 0.05 & treat_spei_c < 0, "yes", "null")]
  out[]
}

#' Permutation p for the buffering coefficient (treat label permuted within kg_group x aridity
#' tercile; units, not unit-months, are the randomization unit). Negative-tail one-sided not used —
#' two-sided like the rest of the project.
permute_ssi_buffer <- function(ssi_panel, n_perm = 2000L, seed = 1L) {
  obs <- ssi_buffer_coef(fit_ssi_buffering(ssi_panel))
  u <- unique(data.table::as.data.table(ssi_panel)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base <- data.table::as.data.table(ssi_panel)[, !c("treat"), with = FALSE]
  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    dp <- merge(base, up[, .(unit_id, treat)], by = "unit_id")
    tryCatch(ssi_buffer_coef(fit_ssi_buffering(dp)), error = function(e) NA_real_)
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- unlist(parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore), use.names = FALSE)
  nv <- sum(!is.na(perm))
  list(observed = obs, p_perm = (1 + sum(abs(perm) >= abs(obs), na.rm = TRUE)) / (1 + nv),
       n_perm = nv)
}

#' MC1 (reviewer 2026-08-05): direct within-basin test of the upstream/downstream placebo
#' contrast. The paper's central falsifier is that "apparent buffering is as strong upstream as
#' downstream"; this was previously asserted from point estimates (-0.20 vs -0.16) without a test
#' of the difference. D = beta_down - beta_up, the difference in the treat:SPEI differential
#' transmission slope between regulated downstream and unregulated upstream reaches of the SAME
#' treated basins. A genuine reservoir effect predicts D < 0 (more buffering below the dam);
#' D ~ 0 means the upstream placebo already reproduces the downstream attenuation (siting).
#' Treatment labels are permuted at the UNIT level within kg_group x aridity-tercile strata, the
#' design's inference regime, preserving the paired structure (the same treated basins contribute
#' both slopes via their own down/up gauge subsets).
#' @return list(down, up, D, p_perm, n_perm, null_sd, D_residual, p_two_sided)
placebo_contrast_test <- function(ssi_panel_down, ssi_panel_up, n_perm = 2000L, seed = 1L) {
  fit_one <- function(panel) ssi_buffer_coef(fit_ssi_buffering(panel))
  obs_down <- fit_one(ssi_panel_down)
  obs_up   <- fit_one(ssi_panel_up)
  obs_D    <- obs_down - obs_up

  u <- unique(data.table::as.data.table(ssi_panel_down)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base_down <- data.table::as.data.table(ssi_panel_down)[, !"treat", with = FALSE]
  base_up   <- data.table::as.data.table(ssi_panel_up)[,   !"treat", with = FALSE]

  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    pd <- merge(base_down, up[, .(unit_id, treat)], by = "unit_id")
    pu <- merge(base_up,   up[, .(unit_id, treat)], by = "unit_id")
    tryCatch(fit_one(pd) - fit_one(pu), error = function(e) NA_real_)
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- unlist(parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore), use.names = FALSE)
  nv <- sum(!is.na(perm))
  list(down = obs_down, up = obs_up, D = obs_D,
       p_perm = (1 + sum(abs(perm) >= abs(obs_D), na.rm = TRUE)) / (1 + nv),
       n_perm = nv, null_sd = stats::sd(perm, na.rm = TRUE))
}

#' One-row summary of the placebo-contrast test for the manuscript table.
placebo_contrast_row <- function(pct) {
  data.table::data.table(
    quantity = "within-basin placebo contrast (downstream - upstream differential slope)",
    estimate = pct$D,
    detail = sprintf(
      "downstream %+.3f, upstream placebo %+.3f, D = %+.3f (SE_perm %.3f); permutation p = %.3f (%d perms); a genuine regulation effect would give D < 0",
      pct$down, pct$up, pct$D, pct$null_sd, pct$p_perm, pct$n_perm))
}

#' R2 (reviewer 2026-08-05, comment 2): test for non-linear / dry-tail reservoir transmission.
#' The linear SPEI->SSI transmission slope could mask buffering that acts only in extreme deficits
#' (threshold-based release rules). Two responses, both with unit-level permutation inference:
#'  (a) nonlinearity test on the full panel: add a quadratic SPEI term with a treat interaction;
#'      a reservoir effect confined to the dry tail would appear as a nonzero treat:SPEI^2 term.
#'  (b) dry-tail re-estimate: restrict to drought months (SPEI < thr) and re-fit the buffering
#'      slope on ITT / downstream / upstream plus the up/down placebo contrast D.
#' @return list for the nonlinearity test
nonlinear_transmission_test <- function(ssi_panel_itt, n_perm = 2000L, seed = 1L) {
  fit_q <- function(d) {
    d <- data.table::as.data.table(d)
    d[, spei2 := spei_c^2]
    m <- fixest::feols(ssi ~ spei_c + spei2 + treat:spei_c + treat:spei2 |
                         unit_id + month_f + year,
                       data = d, weights = ~w, cluster = ~unit_id, nthreads = 1)
    ct <- as.data.frame(summary(m)$coeftable)
    r  <- ct[grepl("spei2", rownames(ct)) & grepl("treat", rownames(ct)), , drop = FALSE]
    if (nrow(r) != 1L) return(NA_real_); unname(r[1, 1])
  }
  dt <- data.table::as.data.table(ssi_panel_itt)
  obs <- fit_q(dt)
  u <- unique(dt[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base <- dt[, !"treat", with = FALSE]
  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    dp <- merge(base, up[, .(unit_id, treat)], by = "unit_id")
    tryCatch(fit_q(dp), error = function(e) NA_real_)
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- unlist(parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore), use.names = FALSE)
  nv <- sum(!is.na(perm))
  list(observed = obs,
       p_perm = (1 + sum(abs(perm) >= abs(obs), na.rm = TRUE)) / (1 + nv),
       n_perm = nv, null_sd = stats::sd(perm, na.rm = TRUE))
}

#' Dry-tail re-estimate of the buffering test and the up/down placebo contrast, restricting the
#' SSI panel to meteorological drought months (SPEI < `thr`). A buffering effect that only acts in
#' the extreme tail would appear here and not in the full-sample linear fit.
#' @return data.table(subset, estimate, p_perm, n_perm, detail)
dry_tail_transmission <- function(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                  thr = -1.0, n_perm = 2000L, seed = 1L) {
  dt <- data.table::as.data.table(ssi_panel_itt)[spei < thr]
  dd <- data.table::as.data.table(ssi_panel_down)[spei < thr]
  du <- data.table::as.data.table(ssi_panel_up)[spei < thr]

  fit_buf <- function(p) ssi_buffer_coef(fit_ssi_buffering(p))
  u <- unique(dt[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base <- dt[, !"treat", with = FALSE]
  base_d <- dd[, !"treat", with = FALSE]
  base_u <- du[, !"treat", with = FALSE]

  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    c(
      itt = tryCatch(fit_buf(merge(base,   up[, .(unit_id, treat)], by = "unit_id")),
                     error = function(e) NA_real_),
      down = tryCatch(fit_buf(merge(base_d, up[, .(unit_id, treat)], by = "unit_id")),
                      error = function(e) NA_real_),
      upr = tryCatch(fit_buf(merge(base_u, up[, .(unit_id, treat)], by = "unit_id")),
                     error = function(e) NA_real_))
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- do.call(rbind, parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore))
  perm <- perm[stats::complete.cases(perm), , drop = FALSE]
  nv <- nrow(perm)
  pp <- function(obs, x) (1 + sum(abs(x) >= abs(obs), na.rm = TRUE)) / (1 + nv)

  obs_itt  <- fit_buf(dt);  obs_down <- fit_buf(dd);  obs_up <- fit_buf(du)
  obs_D <- obs_down - obs_up
  D_null <- perm[, "down"] - perm[, "upr"]

  data.table::data.table(
    quantity = c(
      sprintf("dry-tail buffering, ITT (SPEI < %.1f)", thr),
      sprintf("dry-tail buffering, downstream (SPEI < %.1f)", thr),
      sprintf("dry-tail buffering, upstream placebo (SPEI < %.1f)", thr),
      sprintf("dry-tail placebo contrast down-minus-up (SPEI < %.1f)", thr)),
    value = c(obs_itt, obs_down, obs_up, obs_D),
    detail = c(
      sprintf("est %+.3f, permutation p = %.3f (%d perms)", obs_itt, pp(obs_itt, perm[, "itt"]), nv),
      sprintf("est %+.3f, permutation p = %.3f (%d perms)", obs_down, pp(obs_down, perm[, "down"]), nv),
      sprintf("est %+.3f, permutation p = %.3f (%d perms)", obs_up, pp(obs_up, perm[, "upr"]), nv),
      sprintf("D = %+.3f, permutation p = %.3f (%d perms); regulation would give D < 0",
              obs_D, pp(obs_D, D_null), nv)))
}

#' R3 third round (2026-08-05): elevation-adjusted placebo test.
#' The raw up/down transmission contrast could be confounded by the gauge elevation gradient
#' (among controls, transmission flattens ~0.21 per km; upstream gauges sit ~0.54 km higher than
#' downstream). This fits the buffering model with a SPEI x elevation interaction so the treat:SPEI
#' differential slope is estimated net of the elevation-driven transmission gradient, for the ITT /
#' downstream / upstream panels, plus the up/down contrast D_adj = beta_down_adj - beta_up_adj,
#' each under unit-level permutation inference within the design's strata. A genuine regulation
#' effect requires D_adj < 0; a null D_adj means the up/down similarity survives elevation adjustment.
#' @return data.table(subset, estimate_raw, estimate_adj, p_perm_adj, elev_term_p, n_perm)
elevation_adjusted_placebo <- function(stations_units, ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                       n_perm = 2000L, seed = 1L) {
  su <- data.table::as.data.table(stations_units)
  unit_elev <- function(subset) {
    keep <- su[treat == 0 | switch(subset,
                                   itt  = treat == 1,
                                   down = regulated == "down",
                                   up   = regulated == "up")]
    keep[, .(elev_m = mean(altura, na.rm = TRUE)), by = unit_id]
  }
  e_itt  <- unit_elev("itt");  e_down <- unit_elev("down");  e_up <- unit_elev("up")

  prep <- function(panel, elev) {
    d <- merge(data.table::as.data.table(panel), elev, by = "unit_id", all.x = TRUE)
    d[, elev_c := (elev_m / 1000) - mean(elev_m / 1000, na.rm = TRUE)]
    d[]
  }
  fit_adj <- function(d) {
    m <- fixest::feols(ssi ~ spei_c + spei_c:elev_c + treat:spei_c + treat:spei_c:elev_c |
                         unit_id + month_f + year,
                       data = d, weights = ~w, cluster = ~unit_id, nthreads = 1)
    ct <- as.data.frame(summary(m)$coeftable)
    b  <- ct[grepl("treat", rownames(ct)) & grepl("spei_c", rownames(ct)) & !grepl("elev", rownames(ct)),
             , drop = FALSE]
    ep <- ct[grepl("spei_c", rownames(ct)) & grepl("elev_c", rownames(ct)) & !grepl("treat", rownames(ct)),
             , drop = FALSE]
    c(beta = if (nrow(b) == 1L) b[1, 1] else NA_real_,
      elev_p = if (nrow(ep) == 1L) ep[1, 4] else NA_real_)
  }
  d_itt  <- prep(ssi_panel_itt, e_itt)
  d_down <- prep(ssi_panel_down, e_down)
  d_up   <- prep(ssi_panel_up, e_up)

  obs_itt  <- fit_adj(d_itt);  obs_down <- fit_adj(d_down);  obs_up <- fit_adj(d_up)
  obs_D <- obs_down[["beta"]] - obs_up[["beta"]]

  u <- unique(data.table::as.data.table(ssi_panel_itt)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base_itt  <- d_itt[,  !"treat", with = FALSE]
  base_down <- d_down[, !"treat", with = FALSE]
  base_up   <- d_up[,   !"treat", with = FALSE]

  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    c(itt  = fit_adj(merge(base_itt,  up[, .(unit_id, treat)], by = "unit_id"))[["beta"]],
      down = fit_adj(merge(base_down, up[, .(unit_id, treat)], by = "unit_id"))[["beta"]],
      upr  = fit_adj(merge(base_up,   up[, .(unit_id, treat)], by = "unit_id"))[["beta"]])
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- do.call(rbind, parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore))
  perm <- perm[stats::complete.cases(perm), , drop = FALSE]
  nv <- nrow(perm)
  pp <- function(obs, x) (1 + sum(abs(x) >= abs(obs), na.rm = TRUE)) / (1 + nv)
  D_null <- perm[, "down"] - perm[, "upr"]

  data.table::data.table(
    subset = c("ITT", "downstream", "upstream placebo", "contrast down-up"),
    estimate_raw = c(ssi_buffer_coef(fit_ssi_buffering(ssi_panel_itt)),
                     ssi_buffer_coef(fit_ssi_buffering(ssi_panel_down)),
                     ssi_buffer_coef(fit_ssi_buffering(ssi_panel_up)),
                     NA_real_),
    estimate_adj = c(obs_itt[["beta"]], obs_down[["beta"]], obs_up[["beta"]], obs_D),
    p_perm_adj = c(pp(obs_itt[["beta"]], perm[, "itt"]),
                   pp(obs_down[["beta"]], perm[, "down"]),
                   pp(obs_up[["beta"]],  perm[, "upr"]),
                   pp(obs_D, D_null)),
    elev_term_p = c(obs_itt[["elev_p"]], obs_down[["elev_p"]], obs_up[["elev_p"]], NA_real_),
    n_perm = nv)
}
