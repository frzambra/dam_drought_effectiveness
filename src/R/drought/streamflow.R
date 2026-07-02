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
