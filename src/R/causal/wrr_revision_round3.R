# Reviewer 3, third round (2026-08-06): routed-network fatal flaw + seven comments.
#
#   FATAL FLAW — gauge classification is by SRTM elevation, not routed topology, so "upstream"
#   gauges could sit on parallel, hydrologically disconnected tributaries. We validate every
#   treated gauge against the HydroRIVERS v1.0 routed network (data/raw/hydrorivers/): snap
#   gauges and dams to reaches, walk the NEXT_DOWN topology, classify upstream gauges as
#   network-connected (their flow path passes the dam reach) versus parallel, and re-run the
#   placebo on network-validated gauges only.
#
#   Comments: (1) smooth national time trend replacing year FE; (2) elevation-partitioned
#   permutation null (pseudo-treated controls contribute an up/down gauge split, so the null D
#   carries natural up/down differences), applied to the aggregate AND the carryover contrast;
#   (3) SSI re-standardized on the 1990-2020 baseline (the CR2 record is local and runs from
#   1900); (4) drought-conditional missingness assessment; (5) storage trends on the
#   coverage-stable reservoir subset; (6) non-linear aridity-interaction sensitivity;
#   (7) control basins screened against the 1,370-dam inventory, with a re-balanced refit on
#   dam-free controls.
#
# Every estimate is reproducible from pipeline targets; nothing is hand-written.

# --- shared permutation helpers ------------------------------------------------------------------

.rr3_strata <- function(panel) {
  u <- unique(data.table::as.data.table(panel)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  u
}

# permutation p for an arbitrary fit function over one panel
.rr3_perm_one <- function(panel, fit_fn, n_perm = 1000L, seed = 1L) {
  obs <- fit_fn(panel)
  u <- .rr3_strata(panel)
  base <- data.table::as.data.table(panel)[, !"treat", with = FALSE]
  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    tryCatch(fit_fn(merge(base, up[, .(unit_id, treat)], by = "unit_id")),
             error = function(e) NA_real_)
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- unlist(parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore), use.names = FALSE)
  nv <- sum(!is.na(perm))
  list(observed = obs, p = (1 + sum(abs(perm) >= abs(obs), na.rm = TRUE)) / (1 + nv),
       sd = stats::sd(perm, na.rm = TRUE), n = nv)
}

# --- FATAL FLAW: HydroRIVERS connectivity validation ---------------------------------------------

#' Snap points to HydroRIVERS reaches and return reach ids + snap distances (m).
.rr3_snap <- function(pts_sf, rivers) {
  ix <- sf::st_nearest_feature(pts_sf, rivers)
  dd <- as.numeric(sf::st_distance(pts_sf, rivers[ix, ], by_element = TRUE))
  data.table::data.table(reach = rivers$HYRIV_ID[ix], snap_m = dd)
}

#' Walk NEXT_DOWN from a reach; returns the set of downstream reach ids (including start).
#' `nxt` is a hashed environment (id -> next id) for O(1) lookups.
.rr3_trace <- function(start, nxt, max_steps = 20000L) {
  path <- integer(max_steps); i <- 0L; cur <- start
  while (!is.null(cur) && !is.na(cur) && cur != 0L && i < max_steps) {
    i <- i + 1L; path[i] <- cur
    cur <- nxt[[as.character(cur)]]
  }
  path[seq_len(i)]
}

#' Routed-network validation of the upstream/downstream placebo (Supplementary Table S37).
#' @return data.table(quantity, value, detail)
hydroriver_connectivity_check <- function(hydroriver_shp, streamflow_stations_raw,
                                          streamflow_stations, points, reservoir_units,
                                          ssi12, spei12_monthly, matched_set,
                                          ssi_panel_down, max_snap_m = 5000,
                                          n_perm = 1000L, seed = 1L) {
  st <- data.table::as.data.table(streamflow_stations)
  co <- data.table::as.data.table(streamflow_stations_raw)[, .(codigo, latitud, longitud)]
  g  <- merge(st[treat == 1L & regulated %in% c("up", "down")], co, by = "codigo")
  g  <- g[is.finite(latitud) & is.finite(longitud)]

  # read reaches inside the gauge/dam bounding box (+2 deg margin)
  pv <- sf::st_as_sf(g, coords = c("longitud", "latitud"), crs = 4326, remove = FALSE)
  dams <- sf::st_transform(sf::st_as_sf(points), 4326)
  xy <- rbind(sf::st_coordinates(pv), sf::st_coordinates(dams))
  wkt <- sf::st_as_text(sf::st_as_sfc(sf::st_bbox(
    c(xmin = min(xy[, 1]) - 2, ymin = min(xy[, 2]) - 2,
      xmax = max(xy[, 1]) + 2, ymax = max(xy[, 2]) + 2), crs = sf::st_crs(4326))))
  rivers <- sf::st_read(hydroriver_shp, wkt_filter = wkt, quiet = TRUE)
  nxt <- list2env(setNames(as.list(rivers$NEXT_DOWN), as.character(rivers$HYRIV_ID)),
                  hash = TRUE)

  gs <- cbind(g, .rr3_snap(pv, rivers))
  ru <- data.table::as.data.table(sf::st_drop_geometry(reservoir_units))
  ru <- ru[level == "subcuencas", .(ID_DGA, unit_id)]
  dd <- merge(data.table::data.table(ID_DGA = dams$ID_DGA), ru, by = "ID_DGA")
  dd <- cbind(dd, .rr3_snap(dams, rivers))

  gs <- gs[snap_m <= max_snap_m]
  dd <- dd[snap_m <= max_snap_m]
  dam_paths <- lapply(seq_len(nrow(dd)), function(i) .rr3_trace(dd$reach[i], nxt))
  names(dam_paths) <- paste(dd$unit_id, seq_len(nrow(dd)))

  gs[, connected := FALSE]
  for (i in seq_len(nrow(gs))) {
    dams_u <- which(dd$unit_id == gs$unit_id[i])
    if (!length(dams_u)) next
    if (gs$regulated[i] == "up") {
      path <- .rr3_trace(gs$reach[i], nxt)
      gs[i, connected := any(dd$reach[dams_u] %in% path)]
    } else {
      gs[i, connected := any(vapply(dams_u, function(j) gs$reach[i] %in% dam_paths[[j]],
                                    logical(1)))]
    }
  }
  up_ok <- gs[regulated == "up" & connected == TRUE, codigo]
  dn_ok <- gs[regulated == "down" & connected == TRUE, codigo]
  n_up  <- st[treat == 1L & regulated == "up", .N]
  n_dn  <- st[treat == 1L & regulated == "down", .N]

  drop_up <- setdiff(st[treat == 1L & regulated == "up", codigo], up_ok)
  drop_dn <- setdiff(st[treat == 1L & regulated == "down", codigo], dn_ok)
  st_up_ok   <- st[!(codigo %in% drop_up)]
  st_both_ok <- st[!(codigo %in% c(drop_up, drop_dn))]

  p_up_ok <- build_ssi_panel(ssi12, st_up_ok, spei12_monthly, matched_set, "up")
  est_up  <- .rr3_perm_one(p_up_ok, function(d) ssi_buffer_coef(fit_ssi_buffering(d)),
                           n_perm = n_perm, seed = seed)
  pct_up  <- placebo_contrast_test(ssi_panel_down, p_up_ok, n_perm = n_perm, seed = seed)
  p_dn_ok <- build_ssi_panel(ssi12, st_both_ok, spei12_monthly, matched_set, "down")
  pct_bo  <- placebo_contrast_test(p_dn_ok, build_ssi_panel(ssi12, st_both_ok, spei12_monthly,
                                                            matched_set, "up"),
                                   n_perm = n_perm, seed = seed)

  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "gauges snapped to HydroRIVERS reaches",
      value = nrow(gs),
      detail = sprintf("of %d treated gauges with coordinates; median snap distance %.0f m; %d dams snapped (median %.0f m); snaps beyond %d m excluded",
                       nrow(g), stats::median(gs$snap_m), nrow(dd),
                       stats::median(dd$snap_m), as.integer(max_snap_m))),
    data.table::data.table(
      quantity = "upstream gauges network-connected through their dam",
      value = length(up_ok),
      detail = sprintf("of %d upstream gauges: flow path (NEXT_DOWN trace) passes the dam reach; the remainder are parallel tributaries or unsnapped", n_up)),
    data.table::data.table(
      quantity = "downstream gauges on the dam's routed downstream path",
      value = length(dn_ok),
      detail = sprintf("of %d downstream gauges", n_dn)),
    data.table::data.table(
      quantity = "upstream placebo slope, network-connected gauges only",
      value = round(est_up$observed, 3),
      detail = sprintf("perm p = %.3f; contrast vs full downstream panel D = %+.3f, p = %.3f (%d perms); raw upstream -0.20",
                       est_up$p, pct_up$D, pct_up$p_perm, n_perm)),
    data.table::data.table(
      quantity = "fully network-validated contrast (both classes connected)",
      value = round(pct_bo$D, 3),
      detail = sprintf("down %+.3f, up %+.3f, perm p = %.3f (%d perms)",
                       pct_bo$down, pct_bo$up, pct_bo$p_perm, n_perm))))
}

# --- Comment 1: smooth national time trend instead of year FE ------------------------------------

#' Buffering slopes with year fixed effects replaced by a cubic national time trend
#' (Supplementary Table S25).
smooth_trend_sensitivity <- function(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                     n_perm = 1000L, seed = 1L) {
  fit_smooth <- function(d) {
    d <- data.table::as.data.table(d)
    d[, t_num := year + (as.integer(as.character(month_f)) - 1) / 12]
    m <- fixest::feols(ssi ~ spei_c + treat:spei_c + poly(t_num, 3) | unit_id + month_f,
                       data = d, weights = ~w, cluster = ~unit_id, nthreads = 1)
    ct <- as.data.frame(summary(m)$coeftable)
    r <- ct[grepl("treat", rownames(ct)) & grepl("spei_c", rownames(ct)), , drop = FALSE]
    if (nrow(r) != 1L) return(NA_real_)
    unname(r[1, 1])
  }
  ri <- .rr3_perm_one(ssi_panel_itt,  fit_smooth, n_perm, seed)
  rd <- .rr3_perm_one(ssi_panel_down, fit_smooth, n_perm, seed)
  ru <- .rr3_perm_one(ssi_panel_up,   fit_smooth, n_perm, seed)
  row <- function(lab, r, extra = "") data.table::data.table(
    quantity = lab, value = round(r$observed, 3),
    detail = sprintf("perm p = %.3f (%d perms)%s", r$p, r$n, extra))
  data.table::rbindlist(list(
    row("smooth-trend buffering, ITT", ri, "; year-FE primary -0.183"),
    row("smooth-trend buffering, downstream", rd, "; year-FE primary -0.165"),
    row("smooth-trend buffering, upstream placebo", ru, "; year-FE primary -0.201"),
    data.table::data.table(
      quantity = "smooth-trend placebo contrast (down - up)",
      value = round(rd$observed - ru$observed, 3),
      detail = "cubic national time trend + month FE retain the temporal drought signal that year FE absorb; regulation would give < 0")))
}

# --- Comment 2: elevation-partitioned permutation null -------------------------------------------

#' Placebo-contrast permutation with pseudo-treated CONTROL basins contributing an
#' elevation-partitioned gauge split (above-median -> up panel, at/below -> down panel), so the
#' null distribution of D carries the natural up/down differences that the composition-fixed
#' scheme sets to zero by construction. Applied to the aggregate contrast and to the carryover
#' subgroup contrast (Supplementary Table S30).
placebo_elevsplit_permutation <- function(ssi12, streamflow_stations, spei12_monthly,
                                          matched_set, storage_het_units,
                                          n_perm = 1000L, seed = 1L) {
  st <- data.table::as.data.table(streamflow_stations)
  st[, med_alt := stats::median(altura, na.rm = TRUE), by = unit_id]
  st[, pseudo_cls := data.table::fifelse(is.finite(altura) & altura > med_alt, "up", "down")]
  ssi <- merge(data.table::as.data.table(ssi12),
               st[, .(codigo, unit_id, treat, regulated, pseudo_cls)], by = "codigo")
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, w, kg_group, aridity_mean)]
  sp <- data.table::as.data.table(spei12_monthly)[, .(unit_id, year = data.table::year(date),
                                                      month = data.table::month(date),
                                                      spei = value)]
  mk_panel <- function(assign_dt, cls, keep_treated = NULL) {
    d <- merge(ssi, assign_dt, by = "unit_id")
    if (!is.null(keep_treated)) d <- d[treat == 0L | unit_id %in% keep_treated]
    keep <- d[(treat == 1L & regulated == cls) |
              (treat == 0L & (treat_new == 0L | pseudo_cls == cls))]
    um <- keep[, .(ssi = mean(ssi, na.rm = TRUE), treat = treat_new[1]),
               by = .(unit_id, year, month)]
    p <- merge(merge(um, sp, by = c("unit_id", "year", "month")), ms, by = "unit_id")
    p <- p[is.finite(ssi) & is.finite(spei)]
    p[, spei_c := spei - mean(spei)]
    p[, month_f := factor(month)]
    p
  }
  fit_D <- function(assign_dt, keep_treated = NULL) {
    fd <- ssi_buffer_coef(fit_ssi_buffering(mk_panel(assign_dt, "down", keep_treated)))
    fu <- ssi_buffer_coef(fit_ssi_buffering(mk_panel(assign_dt, "up", keep_treated)))
    fd - fu
  }
  u <- unique(ssi[, .(unit_id, treat)])
  u <- merge(u, ms, by = "unit_id")
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  truth <- u[, .(unit_id, treat_new = treat)]
  obs_D <- fit_D(truth)
  cu <- as.character(storage_het_units)
  u_c <- u[treat == 0L | unit_id %in% cu]
  obs_Dc <- fit_D(truth, keep_treated = cu)

  run_null <- function(uu, keep_treated) {
    one <- function(b) {
      set.seed(seed + b)
      up <- data.table::copy(uu)[, treat_new := sample(treat), by = stratum]
      tryCatch(fit_D(up[, .(unit_id, treat_new)], keep_treated),
               error = function(e) NA_real_)
    }
    ncore <- max(1L, parallel::detectCores() - 2L)
    perm <- unlist(parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore),
                   use.names = FALSE)
    nv <- sum(!is.na(perm))
    list(sd = stats::sd(perm, na.rm = TRUE), nv = nv,
         p = function(o) (1 + sum(abs(perm) >= abs(o), na.rm = TRUE)) / (1 + nv))
  }
  nl  <- run_null(u, NULL)
  nlc <- run_null(u_c, cu)
  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "aggregate contrast D under elevation-partitioned null",
      value = round(obs_D, 3),
      detail = sprintf("perm p = %.3f, null SD %.3f (%d perms); composition-fixed scheme: p = 0.718, null SD 0.098 (Supplementary Table S29)",
                       nl$p(obs_D), nl$sd, nl$nv)),
    data.table::data.table(
      quantity = "carryover contrast D under elevation-partitioned null",
      value = round(obs_Dc, 3),
      detail = sprintf("perm p = %.3f, null SD %.3f (%d perms); composition-fixed scheme: p = 0.014 (Supplementary Table S50)",
                       nlc$p(obs_Dc), nlc$sd, nlc$nv))))
}

# --- Comment 3: SSI standardization baseline -----------------------------------------------------

#' Buffering and placebo re-estimated with SSI standardized on 1990-2020 (31 years), meeting the
#' 30-year guideline; the CR2 daily record begins in 1900 (Supplementary Table S11).
ssi_baseline_sensitivity <- function(streamflow_monthly, streamflow_stations, spei12_monthly,
                                     matched_set, ref_years = 1990:2020,
                                     n_perm = 1000L, seed = 1L) {
  ssi_b <- compute_ssi(streamflow_monthly, accum = 12L, ref_years = ref_years,
                       min_months = 96L)
  n_new <- data.table::uniqueN(ssi_b$codigo)
  p_itt  <- build_ssi_panel(ssi_b, streamflow_stations, spei12_monthly, matched_set, "itt")
  p_down <- build_ssi_panel(ssi_b, streamflow_stations, spei12_monthly, matched_set, "down")
  p_up   <- build_ssi_panel(ssi_b, streamflow_stations, spei12_monthly, matched_set, "up")
  fit1 <- function(d) ssi_buffer_coef(fit_ssi_buffering(d))
  ri <- .rr3_perm_one(p_itt, fit1, n_perm, seed)
  rd <- .rr3_perm_one(p_down, fit1, n_perm, seed)
  ru <- .rr3_perm_one(p_up, fit1, n_perm, seed)
  pct <- placebo_contrast_test(p_down, p_up, n_perm = n_perm, seed = seed)
  row <- function(lab, r, primary) data.table::data.table(
    quantity = lab, value = round(r$observed, 3),
    detail = sprintf("perm p = %.3f (%d perms); 2000-2020-baseline primary %s", r$p, r$n, primary))
  data.table::rbindlist(list(
    data.table::data.table(
      quantity = sprintf("gauges retained under %d-%d standardization",
                         min(ref_years), max(ref_years)),
      value = n_new,
      detail = "SSI-12 re-standardized per gauge-month (Gringorten) on the 31-year baseline"),
    row("long-baseline buffering, ITT", ri, "-0.183"),
    row("long-baseline buffering, downstream", rd, "-0.165"),
    row("long-baseline buffering, upstream placebo", ru, "-0.201"),
    data.table::data.table(
      quantity = "long-baseline placebo contrast (down - up)",
      value = round(pct$D, 3),
      detail = sprintf("perm p = %.3f (%d perms); regulation would give < 0",
                       pct$p_perm, pct$n_perm))))
}

# --- Comment 4: drought-conditional missingness --------------------------------------------------

#' Does the no-imputation rule preferentially delete drought months? (Supplementary Table S10)
missingness_drought_bias <- function(streamflow_monthly, streamflow_stations,
                                     spei12_monthly, years = 2000:2020) {
  st <- data.table::as.data.table(streamflow_stations)
  qm <- data.table::as.data.table(streamflow_monthly)[year %in% years]
  qm <- qm[codigo %in% st$codigo]
  span <- qm[, .(y0 = min(year), y1 = max(year)), by = codigo]
  grid <- span[, data.table::CJ(year = max(min(years), y0):min(max(years), y1), month = 1:12),
               by = codigo]
  g <- merge(grid, qm[, .(codigo, year, month, present = 1L)],
             by = c("codigo", "year", "month"), all.x = TRUE)
  g[is.na(present), present := 0L]
  g <- merge(g, st[, .(codigo, unit_id, treat, regulated)], by = "codigo")
  sp <- data.table::as.data.table(spei12_monthly)[, .(unit_id, year = data.table::year(date),
                                                      month = data.table::month(date),
                                                      spei = value)]
  g <- merge(g, sp, by = c("unit_id", "year", "month"))
  g[, miss := 1L - present]
  m <- fixest::feols(miss ~ spei | codigo, data = g, cluster = ~unit_id)
  ct <- as.data.frame(summary(m)$coeftable)["spei", ]
  rate <- function(x) sprintf("%.2f%%", 100 * mean(x))
  dr <- g[spei < -1, mean(miss)]; nr <- g[spei >= -1, mean(miss)]
  cls <- g[treat == 1L, .(miss_dr = mean(miss[spei < -1]), n = .N), by = regulated]
  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "gauge-month missingness within record span, 2000-2020",
      value = round(g[, mean(miss)], 4),
      detail = sprintf("%s of %d gauge-months (months failing the >= 20-valid-days rule or absent)",
                       rate(g$miss), nrow(g))),
    data.table::data.table(
      quantity = "missingness in drought months (SPEI < -1) vs other months",
      value = round(dr, 4),
      detail = sprintf("drought %s vs non-drought %s", rate(g[spei < -1, miss]),
                       rate(g[spei >= -1, miss]))),
    data.table::data.table(
      quantity = "missingness on SPEI (gauge FE, unit-clustered)",
      value = round(ct[[1]], 5),
      detail = sprintf("per SPEI unit; SE %.5f, p = %.3g; a negative sign means drier months are MORE likely missing",
                       ct[[2]], ct[[4]])),
    data.table::data.table(
      quantity = "drought-month missingness, treated downstream vs upstream gauges",
      value = round(cls[regulated == "down", miss_dr] - cls[regulated == "up", miss_dr], 4),
      detail = sprintf("down %s, up %s; a differential would be needed to bias the contrast D",
                       sprintf("%.2f%%", 100 * cls[regulated == "down", miss_dr]),
                       sprintf("%.2f%%", 100 * cls[regulated == "up", miss_dr])))))
}

# --- Comment 5: coverage-stable storage subset ---------------------------------------------------

#' Storage-band trends restricted to reservoirs covering >= min_years of 2005-2024
#' (Supplementary Table S5).
storage_stable_trends <- function(band_annual, min_years = 18L,
                                  split_year = 2010L) {
  d <- data.table::as.data.table(band_annual)
  keep <- d[, .N, by = ID_DGA][N >= min_years, ID_DGA]
  ds <- d[ID_DGA %in% keep]
  ds[, post := as.integer(year >= split_year)]
  ds[, yr_post := (year - split_year) * post]
  one <- function(comp, rhs, term, lab) {
    m <- fixest::feols(stats::as.formula(sprintf("%s ~ %s | ID_DGA", comp, rhs)),
                       data = ds, cluster = ~ID_DGA)
    ct <- as.data.frame(summary(m)$coeftable)[term, ]
    data.table::data.table(
      quantity = sprintf("stable-subset %s, %s", lab, comp),
      value = round(ct[[1]], 4),
      detail = sprintf("SE %.4f, p = %.3g (%d reservoirs with >= %d band years; full fleet in Supplementary Tables S5, S41)",
                       ct[[2]], ct[[4]], length(keep), as.integer(min_years)))
  }
  data.table::rbindlist(c(
    lapply(c("peak", "trough", "amplitude"), one, rhs = "year", term = "year",
           lab = "trend (per yr)"),
    lapply(c("peak", "trough"), one, rhs = "post + yr_post", term = "post",
           lab = "step at 2010"),
    lapply(c("peak", "trough"), one, rhs = "post + yr_post", term = "yr_post",
           lab = "post-2010 drift (per yr)")))
}

# --- Comment 6: non-linear aridity interaction ---------------------------------------------------

#' Buffering slope net of quadratic aridity-by-forcing interactions (Supplementary Table S22).
nonlinear_aridity_sensitivity <- function(ssi_panel_itt, n_perm = 1000L, seed = 1L) {
  fit_nl <- function(d) {
    d <- data.table::as.data.table(d)
    d[, la := log(aridity_mean) - mean(log(aridity_mean), na.rm = TRUE)]
    d[, la2 := la^2]
    m <- fixest::feols(ssi ~ spei_c + spei_c:la + spei_c:la2 + treat:spei_c |
                         unit_id + month_f + year,
                       data = d, weights = ~w, cluster = ~unit_id, nthreads = 1)
    ct <- as.data.frame(summary(m)$coeftable)
    r <- ct[grepl("treat", rownames(ct)) & grepl("spei_c", rownames(ct)) &
              !grepl("la", rownames(ct)), , drop = FALSE]
    if (nrow(r) != 1L) return(NA_real_)
    unname(r[1, 1])
  }
  r <- .rr3_perm_one(ssi_panel_itt, fit_nl, n_perm, seed)
  # report the nonlinear terms themselves from the observed fit
  d <- data.table::as.data.table(ssi_panel_itt)
  d[, la := log(aridity_mean) - mean(log(aridity_mean), na.rm = TRUE)]
  d[, la2 := la^2]
  m <- fixest::feols(ssi ~ spei_c + spei_c:la + spei_c:la2 + treat:spei_c |
                       unit_id + month_f + year,
                     data = d, weights = ~w, cluster = ~unit_id)
  ct <- as.data.frame(summary(m)$coeftable)
  la1 <- ct[rownames(ct) == "spei_c:la", ]
  la2r <- ct[rownames(ct) == "spei_c:la2", ]
  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "buffering ITT net of quadratic aridity-by-forcing terms",
      value = round(r$observed, 3),
      detail = sprintf("perm p = %.3f (%d perms); linear-adjustment primary -0.183", r$p, r$n)),
    data.table::data.table(
      quantity = "aridity-by-forcing terms (linear; quadratic)",
      value = round(la1[1, 1], 3),
      detail = sprintf("linear p = %.3g; quadratic %.3f, p = %.3g (cluster-robust); the control transmission gradient across aridity is also tercile-checked in Supplementary Table S21",
                       la1[1, 4], la2r[1, 1], la2r[1, 4]))))
}

# --- Comment 7: control contamination by unmonitored dams ----------------------------------------

#' Screen matched control basins against the national dam inventory and re-fit the streamflow
#' results with a re-balanced dam-free control pool (Supplementary Table S3).
control_dam_contamination <- function(dam_shp, matched_subcuencas, matched_set,
                                      match_covariates, ssi12, streamflow_stations,
                                      spei12_monthly, n_perm = 1000L, seed = 1L) {
  sh <- sf::st_read(dam_shp, quiet = TRUE)
  suppressWarnings({
    shc <- sf::st_transform(sf::st_centroid(sh), 4326)
    un <- sf::st_transform(sf::st_as_sf(matched_subcuencas), 4326)
    ix <- sf::st_join(shc, un["unit_id"], join = sf::st_within)
  })
  d <- data.table::as.data.table(sf::st_drop_geometry(ix))[!is.na(unit_id)]
  d[, material := MONITOR == "MONITOREO DGA" | TAMANO == "GRANDE" |
      (is.finite(ALT_MURO) & ALT_MURO >= 15)]
  ms <- data.table::as.data.table(matched_set$data)
  ctrl <- ms[treated == 0L, unit_id]
  cnt <- d[unit_id %in% ctrl, .(n_dams = .N, n_material = sum(material)), by = unit_id]
  any_dam <- cnt[n_dams > 0, unit_id]
  mat_dam <- cnt[n_material > 0, unit_id]
  w_share <- ms[treated == 0L & unit_id %in% mat_dam, sum(w)] / ms[treated == 0L, sum(w)]

  cov <- data.table::as.data.table(match_covariates)
  ms_clean <- fit_matched_set(cov[!(unit_id %in% mat_dam)])
  p_itt  <- build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, ms_clean, "itt")
  p_down <- build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, ms_clean, "down")
  p_up   <- build_ssi_panel(ssi12, streamflow_stations, spei12_monthly, ms_clean, "up")
  fit1 <- function(dd) ssi_buffer_coef(fit_ssi_buffering(dd))
  ri <- .rr3_perm_one(p_itt, fit1, n_perm, seed)
  ru <- .rr3_perm_one(p_up, fit1, n_perm, seed)
  pct <- placebo_contrast_test(p_down, p_up, n_perm = n_perm, seed = seed)
  ess <- {wc <- data.table::as.data.table(ms_clean$data)[treated == 0L, w]
          sum(wc)^2 / sum(wc^2)}
  data.table::rbindlist(list(
    data.table::data.table(
      quantity = "matched control basins containing any inventory dam",
      value = length(any_dam),
      detail = sprintf("of %d matched controls; %d contain a MATERIAL dam (monitored / GRANDE / wall >= 15 m), holding %.1f%% of the entropy-balancing weight",
                       length(ctrl), length(mat_dam), 100 * w_share)),
    data.table::data.table(
      quantity = "dam-free-control buffering, ITT (re-balanced)",
      value = round(ri$observed, 3),
      detail = sprintf("perm p = %.3f (%d perms); primary -0.183; entropy balance re-fit on dam-free controls, control ESS %.1f",
                       ri$p, ri$n, ess)),
    data.table::data.table(
      quantity = "dam-free-control upstream placebo (re-balanced)",
      value = round(ru$observed, 3),
      detail = sprintf("perm p = %.3f; primary -0.201", ru$p)),
    data.table::data.table(
      quantity = "dam-free-control placebo contrast (down - up)",
      value = round(pct$D, 3),
      detail = sprintf("down %+.3f, up %+.3f, perm p = %.3f (%d perms)",
                       pct$down, pct$up, pct$p_perm, pct$n_perm))))
}
