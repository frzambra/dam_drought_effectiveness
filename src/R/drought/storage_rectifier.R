# H1 — reservoir as nonlinear STORAGE RECTIFIER. Decisive test design by drought-propagation-analyst
# (.claude/agent-memory/drought-propagation-analyst/h1-test-design.md). Three claims:
#   C3 (cleanest, control-anchored): heavier UPPER-TAIL ecological-drought severity in dammed vs
#       matched-control basins, conditional on forcing — storage-free, the publishable core.
#   C1 (within-treated): a storage threshold s* exists in the storage->eco-drought transfer.
#   C2 (within-treated): conditional variance is state-dependent and LOWER-TAIL-loaded below s*
#       (variance redistribution into the severe tail, not mere loss of buffering).
# Outcome grain is MONTHLY zcNDVI-6 (annual zNPP has too few extremes for tail estimation). Forcing
# is meteorological SPEI (never calendar time). Inference is permutation within kg_group x
# aridity-tercile strata (~21 treated clusters; cluster-robust SEs over-reject).

# ---- monthly raster extraction ---------------------------------------------------------------

#' Paths + dates for monthly zcNDVI at a given accumulation (nested subdir zcNDVI/zcNDVI-<ts>/).
zcndvi_monthly_paths <- function(sources, timescale = 6L, years = 2000:2024) {
  ei  <- sources$ecological_indices
  dir <- file.path(ei$root, ei$products$zcNDVI$subdir, sprintf("zcNDVI-%d", timescale))
  f   <- list.files(dir, "\\.tif$", full.names = TRUE)
  d   <- as.Date(sub(".*_(\\d{4}-\\d{2}-\\d{2})\\.tif$", "\\1", basename(f)))
  keep <- !is.na(d) & data.table::year(d) %in% years
  ord  <- order(d[keep])
  list(paths = f[keep][ord], dates = d[keep][ord])
}

#' Per-unit MONTHLY zonal mean of a standardized index stack. Clamps |z| > `clamp` (fill guard).
#' @return data.table(unit_id, date, year, month, value)
extract_unit_index_monthly <- function(units, stack, clamp = 6) {
  r <- terra::rast(stack$paths)
  r <- terra::ifel(abs(r) > clamp, NA, r)
  v <- terra::vect(units)
  if (!terra::same.crs(v, r)) v <- terra::project(v, r)
  ex <- data.table::as.data.table(terra::extract(r, v, fun = mean, na.rm = TRUE, ID = TRUE))
  data.table::setnames(ex, c("ID", paste0("m", seq_along(stack$dates))))
  ex[, unit_id := units$unit_id[ID]]
  long <- data.table::melt(ex, id.vars = c("ID", "unit_id"),
                           variable.name = "mv", value.name = "value")
  long[, midx := as.integer(sub("m", "", mv))]
  long[, date := stack$dates[midx]]
  long[, `:=`(year = data.table::year(date), month = data.table::month(date))]
  long[!is.na(value), .(unit_id, date, year, month, value)][order(unit_id, date)]
}

# ---- panel assembly --------------------------------------------------------------------------

#' Severity panel for the dammed-vs-control C3 test: monthly zcNDVI-6 + monthly SPEI-12/-3 +
#' treatment/weights/covariates. `sev = -zcNDVI6` so SEVERE ecological drought is the UPPER tail.
build_severity_panel <- function(zc_monthly, spei12_monthly, spei3_monthly, matched_set) {
  zc <- data.table::as.data.table(zc_monthly)[, .(unit_id, date, year, month, zc = value)]
  s12 <- data.table::as.data.table(spei12_monthly)[, .(unit_id, date, spei12 = value)]
  s3  <- data.table::as.data.table(spei3_monthly)[, .(unit_id, date, spei3 = value)]
  ms  <- data.table::as.data.table(matched_set$data)[, .(unit_id, treat = treated, w,
                                                         kg_group, aridity_mean, elev_mean)]
  d <- merge(merge(merge(zc, s12, by = c("unit_id", "date")),
                   s3, by = c("unit_id", "date")), ms, by = "unit_id")
  d[, sev := -zc]
  d[, month := factor(month)]
  d[is.finite(sev) & is.finite(spei12) & is.finite(spei3)][]
}

#' Within-treated panel for C1/C2: monthly zcNDVI-6 severity + SPEI + reservoir storage fraction.
#' Storage is mapped reservoir->subcuenca (mean fraction across a unit's dams).
build_treated_storage_panel <- function(zc_monthly, spei12_monthly, spei3_monthly,
                                        storage_pct, reservoir_units, matched_set) {
  ru <- data.table::as.data.table(reservoir_units)[level == "subcuencas", .(ID_DGA, unit_id)]
  sp <- data.table::as.data.table(storage_pct)[has_capacity == TRUE,
                                               .(ID_DGA, date, storage_fraction)]
  sp <- merge(sp, ru, by = "ID_DGA")[!is.na(storage_fraction),
              .(storage_fraction = mean(storage_fraction)), by = .(unit_id, date)]
  base <- build_severity_panel(zc_monthly, spei12_monthly, spei3_monthly, matched_set)[treat == 1]
  d <- merge(base, sp, by = c("unit_id", "date"))
  data.table::setorder(d, unit_id, date)
  d[]
}

# ---- C3: dammed-vs-control upper-tail severity -----------------------------------------------

#' Quantile regression of severity on treatment + forcing + covariates across quantiles.
#' Tail signature of H1 = treated coefficient at high tau (severe) >> at the median.
fit_tail_quantreg <- function(sev_panel, taus = c(0.5, 0.9, 0.95, 0.99)) {
  quantreg::rq(sev ~ treat + spei12 + spei3 + log(aridity_mean) + elev_mean + kg_group,
               tau = taus, weights = sev_panel$w, data = sev_panel, method = "fn")
}

#' Lightweight tail contrast for permutation: fits only the two needed quantiles with the fast
#' interior-point solver (default "br" is intractable at ~75k rows). Returns the scalar contrast.
tail_contrast_fast <- function(sev_panel, tau_hi = 0.95, tau_mid = 0.5) {
  m <- quantreg::rq(sev ~ treat + spei12 + spei3 + log(aridity_mean) + elev_mean + kg_group,
                    tau = c(tau_mid, tau_hi), weights = sev_panel$w, data = sev_panel,
                    method = "fn")
  cf <- stats::coef(m)["treat", ]
  unname(cf[2] - cf[1])
}

#' Treated tail-vs-median contrast: treat coef at `tau_hi` minus at `tau_mid` (the H1 estimand).
tail_contrast <- function(rq_model, tau_hi = 0.95, tau_mid = 0.5) {
  cf <- stats::coef(rq_model)                 # rows = terms, cols = taus
  tn <- as.numeric(sub("tau= *", "", colnames(cf)))
  th <- cf["treat", which.min(abs(tn - tau_hi))]
  tm <- cf["treat", which.min(abs(tn - tau_mid))]
  c(treat_hi = unname(th), treat_mid = unname(tm), contrast = unname(th - tm))
}

#' GPD/POT tail-shape contrast: residualize severity on forcing (ebal-weighted), then fit a
#' Generalized Pareto to exceedances over a high threshold separately for treated vs control.
#' H1 confirm: shape (xi) and/or scale of treated > control (heavier tail at equal forcing).
fit_gpd_tail <- function(sev_panel, u_quantile = 0.9) {
  d <- data.table::copy(sev_panel)
  m <- stats::lm(sev ~ spei12 + spei3 + log(aridity_mean) + elev_mean + kg_group,
                 data = d, weights = d$w)
  d[, res := stats::residuals(m)]
  u <- as.numeric(stats::quantile(d$res, u_quantile, na.rm = TRUE))
  fit_grp <- function(g) {
    x <- d$res[d$treat == g]
    fe <- tryCatch(extRemes::fevd(x, threshold = u, type = "GP"), error = function(e) NULL)
    if (is.null(fe)) return(c(scale = NA_real_, shape = NA_real_, n_exc = sum(x > u)))
    p <- fe$results$par
    c(scale = unname(p["scale"]), shape = unname(p["shape"]), n_exc = sum(x > u))
  }
  list(threshold = u, treated = fit_grp(1L), control = fit_grp(0L))
}

#' Permutation inference: permute the treatment label among UNITS within kg_group x aridity-tercile
#' strata, recompute a treated-vs-control statistic, two-sided p vs the permutation null.
#' @param statfun function(panel) -> scalar statistic (e.g. the QR tail contrast)
permute_tail_stat <- function(sev_panel, statfun, n_perm = 2000L, seed = 1L) {
  obs <- statfun(sev_panel)
  u <- unique(data.table::as.data.table(sev_panel)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base <- data.table::as.data.table(sev_panel)[, !c("treat"), with = FALSE]
  one_perm <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    dp <- merge(base, up[, .(unit_id, treat)], by = "unit_id")
    tryCatch(statfun(dp), error = function(e) NA_real_)
  }
  ncore <- max(1L, parallel::detectCores() - 2L)        # fork-based; panel is small, rq per worker
  perm <- unlist(parallel::mclapply(seq_len(n_perm), one_perm, mc.cores = ncore),
                 use.names = FALSE)
  nv <- sum(!is.na(perm))
  list(observed = obs, p_perm = (1 + sum(abs(perm) >= abs(obs), na.rm = TRUE)) / (1 + nv),
       n_perm = nv, null = perm)
}

# ---- C1 / C2: within-treated storage threshold (TAR) + variance break ------------------------

#' Pooled grid-search threshold (TAR): for each lag k and candidate s*, split SPEI slopes by
#' whether lagged storage_fraction is below s*, keep the (k, s*) maximizing profile likelihood
#' (min pooled SSR). Then test the C2 variance break: residual dispersion below vs above s*, and
#' whether the excess is LOWER-tail-loaded (severe drought). H1: steeper severe transmission and
#' larger lower-tail variance BELOW s*.
fit_storage_tar <- function(treated_panel, s_grid = seq(0.15, 0.60, by = 0.025),
                            lags = c(1L, 2L, 3L, 6L)) {
  d0 <- data.table::as.data.table(treated_panel)
  best <- NULL
  for (k in lags) {
    d <- data.table::copy(d0)
    d[, s_lag := data.table::shift(storage_fraction, k), by = unit_id]
    d <- d[is.finite(s_lag)]
    for (s in s_grid) {
      d[, below := as.integer(s_lag < s)]
      m <- tryCatch(fixest::feols(sev ~ below + below:spei12 + below:spei3 +
                                    spei12 + spei3 | unit_id + month, data = d),
                    error = function(e) NULL)
      if (is.null(m)) next
      ssr <- sum(stats::residuals(m)^2)
      if (is.null(best) || ssr < best$ssr)
        best <- list(k = k, s_star = s, ssr = ssr, model = m, data = data.table::copy(d))
    }
  }
  if (is.null(best)) return(NULL)
  d <- best$data; d[, below := as.integer(s_lag < best$s_star)]
  d[, res := stats::residuals(best$model)]
  # C2 variance break: dispersion of residuals below vs above s*, and lower-tail (severe) focus
  var_below <- stats::var(d$res[d$below == 1], na.rm = TRUE)
  var_above <- stats::var(d$res[d$below == 0], na.rm = TRUE)
  levene_p <- tryCatch(stats::oneway.test(I(abs(res - stats::ave(res, below))) ~ factor(below),
                                          data = d, var.equal = FALSE)$p.value,
                       error = function(e) NA_real_)
  q05_below <- stats::quantile(d$res[d$below == 1], 0.95, na.rm = TRUE)  # severe (sev high) tail
  q05_above <- stats::quantile(d$res[d$below == 0], 0.95, na.rm = TRUE)
  cf <- stats::coef(best$model)
  list(k = best$k, s_star = best$s_star, model = best$model, tar_data = d,
       slope_below = unname(cf["spei12"] + cf["below:spei12"]),
       slope_above = unname(cf["spei12"]),
       var_below = var_below, var_above = var_above, var_ratio = var_below / var_above,
       levene_p = levene_p, tail95_below = unname(q05_below), tail95_above = unname(q05_above))
}

#' COUNTERFACTUAL-OVERSHOOT test (the doc's decisive falsifier): fit the SPEI->severity transfer on
#' CONTROL units (natural, no reservoir), predict onto treated unit-months, and test whether treated
#' BELOW-s* severity systematically EXCEEDS that natural-forcing prediction (rectifier overshoot).
overshoot_test <- function(sev_panel, treated_tar) {
  if (is.null(treated_tar)) return(NULL)
  ctrl <- data.table::as.data.table(sev_panel)[treat == 0]
  cf_model <- stats::lm(sev ~ spei12 + spei3 + log(aridity_mean) + elev_mean + kg_group,
                        data = ctrl)                       # natural (no-reservoir) transfer function
  td <- data.table::copy(treated_tar$tar_data)             # treated frame with `below`, sev, covars
  td[, pred_nat := stats::predict(cf_model, newdata = td)]
  td[, overshoot := sev - pred_nat]                        # >0 = worse than natural forcing implies
  list(mean_overshoot_below = mean(td$overshoot[td$below == 1], na.rm = TRUE),
       mean_overshoot_above = mean(td$overshoot[td$below == 0], na.rm = TRUE),
       p_below = tryCatch(stats::t.test(td$overshoot[td$below == 1])$p.value,
                          error = function(e) NA_real_))
}
