# FATAL-FLAW response (2026-07-03 review): SSI standardizes each gauge to its own (regulated)
# distribution, so any variance compression by the dam is divided out and the SSI slope tests
# percentile transmission, not volumetric response. Two direct checks (Supplementary Table S19):
#   (1) proportional volumetric transmission — replace SSI with log 12-month mean flow (a
#       semi-elasticity, % flow per SPEI unit, NOT variance-normalized) and re-run the buffering
#       models and the upstream placebo;
#   (2) the premise itself — does regulation compress relative flow variability? Deseasonalized
#       log-flow SD by gauge class (control / upstream / downstream).

#' Unit-month panel of log 12-month rolling mean flow with SPEI forcing (mirrors build_ssi_panel).
build_logq_panel <- function(monthly_flow, stations_units, spei12_monthly, matched_set,
                             subset = "itt", accum = 12L) {
  d <- data.table::as.data.table(monthly_flow)
  data.table::setorder(d, codigo, year, month)
  d[, roll := data.table::frollmean(q_mon, accum, align = "right"), by = codigo]
  d <- d[is.finite(roll) & roll > 0]
  su <- data.table::as.data.table(stations_units)
  keep <- su[treat == 0 | switch(subset, itt = treat == 1,
                                 down = regulated == "down", up = regulated == "up")]
  g  <- merge(d, keep[, .(codigo, unit_id, treat)], by = "codigo")
  um <- g[, .(lq = mean(log(roll))), by = .(unit_id, treat, year, month)]
  sp <- data.table::as.data.table(spei12_monthly)[, .(unit_id, year = data.table::year(date),
                                                      month = data.table::month(date),
                                                      spei = value)]
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, w, kg_group, aridity_mean)]
  p <- merge(merge(um, sp, by = c("unit_id", "year", "month")), ms, by = "unit_id")
  p <- p[is.finite(lq) & is.finite(spei)]
  p[, spei_c := spei - mean(spei)][, month_f := factor(month)]
  p[]
}

fit_logq_buffering <- function(panel)
  fixest::feols(lq ~ spei_c + treat:spei_c | unit_id + month_f + year,
                data = panel, weights = ~w, cluster = ~unit_id, nthreads = 1)

#' @return data.table(quantity, value, detail) for Supplementary Table S19
build_volumetric_check <- function(monthly_flow, stations_units, spei12_monthly, matched_set,
                                   n_perm = 1000L) {
  cfun <- function(mm) {
    cf <- stats::coef(mm)
    h <- names(cf)[grepl("spei_c", names(cf)) & grepl("treat", names(cf))]
    if (length(h) != 1L) return(NA_real_)
    unname(cf[h])
  }
  one <- function(subset, lab) {
    p  <- build_logq_panel(monthly_flow, stations_units, spei12_monthly, matched_set, subset)
    m  <- fit_logq_buffering(p)
    ct <- as.data.frame(summary(m)$coeftable)
    r  <- ct[grepl("spei_c", rownames(ct)) & grepl("treat", rownames(ct)), , drop = FALSE]
    base <- ct[rownames(ct) == "spei_c", 1]
    nd <- perm_null_dist(p, fit_logq_buffering, coeffun = cfun, n_perm = n_perm)
    pp <- (1 + sum(abs(nd) >= abs(r[1, 1]), na.rm = TRUE)) / (1 + sum(!is.na(nd)))
    data.table::data.table(
      quantity = sprintf("log-flow semi-elasticity gap, %s (treat x SPEI)", lab),
      value = round(r[1, 1], 4),
      detail = sprintf("SE %.4f, perm p = %.3f; baseline d log Q / d SPEI %.3f (%% flow per SPEI unit)",
                       r[1, 2], pp, base))
  }
  rows <- data.table::rbindlist(list(one("itt", "ITT"), one("down", "downstream"),
                                     one("up", "upstream placebo")))

  d <- data.table::as.data.table(monthly_flow)[q_mon > 0][, lq := log(q_mon)]
  d[, lqa := lq - mean(lq), by = .(codigo, month)]
  gv <- d[, .(sdlq = stats::sd(lqa), n = .N), by = codigo][n >= 60]
  su <- data.table::as.data.table(stations_units)
  gv <- merge(gv, su[, .(codigo, treat, regulated)], by = "codigo")
  gv[, class := data.table::fifelse(treat == 0L, "control",
                                    data.table::fifelse(regulated == "down", "down", "up"))]
  cm <- gv[, .(sd = mean(sdlq), n = .N), by = class]
  wt <- stats::wilcox.test(sdlq ~ regulated,
                           data = gv[treat == 1L & regulated %in% c("up", "down")])
  data.table::rbindlist(list(rows, data.table::data.table(
    quantity = "deseasonalized log-flow SD by gauge class (relative variability)",
    value = round(cm[class == "down", sd], 3),
    detail = sprintf("downstream %.3f (n=%d) vs upstream %.3f (n=%d) vs control %.3f (n=%d); up-down Wilcoxon p = %.2f",
                     cm[class == "down", sd], cm[class == "down", n],
                     cm[class == "up", sd], cm[class == "up", n],
                     cm[class == "control", sd], cm[class == "control", n], wt$p.value))))
}
