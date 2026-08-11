# Reviewer 3, fourth round (2026-08-06): small-cluster inference for the storage-band trends.
#
# The storage trends and the 2010 step are judged by cluster-robust SEs with only 22-26
# reservoir clusters, which the paper itself argues over-reject at ~21 clusters elsewhere. The
# design's randomization inference does not apply here (there is no treatment assignment to
# permute in a descriptive within-reservoir trend), so the requested remedy is the wild cluster
# bootstrap: restricted (null-imposed) WCB-R with Rademacher weights drawn at the reservoir
# level, the standard small-cluster refinement (Cameron, Gelbach & Miller 2008). Implemented
# directly on the fixest models (no added dependency); bootstrap p compares |t*| against the
# observed cluster-robust |t|.
#
# Every estimate is reproducible from pipeline targets; nothing is hand-written.

#' Null-imposed wild cluster bootstrap p-value for one coefficient of a reservoir-FE model.
#'
#' Runs serially and pins fixest to one thread throughout. Both matter: a single fit on this
#' 506-row panel costs ~13 ms, so 2,000 draws take under a minute, while forking (mclapply)
#' after fixest has initialized its OpenMP pool deadlocks the workers, the same hazard that
#' fit_ssi_buffering() guards against with nthreads = 1.
.rr4_wcb <- function(d, comp, rhs_full, rhs_restr, term, wcol = NULL,
                     B = 1999L, seed = 1L) {
  old_nthreads <- fixest::getFixest_nthreads()
  fixest::setFixest_nthreads(1)
  on.exit(fixest::setFixest_nthreads(old_nthreads), add = TRUE)

  wts <- if (is.null(wcol)) NULL else stats::as.formula(paste0("~", wcol))
  m1 <- fixest::feols(stats::as.formula(sprintf("%s ~ %s | ID_DGA", comp, rhs_full)),
                      data = d, weights = wts, cluster = ~ID_DGA)
  ct <- as.data.frame(summary(m1)$coeftable)[term, ]
  t_obs <- ct[[3]]
  m0 <- fixest::feols(stats::as.formula(sprintf("%s ~ %s | ID_DGA", comp,
                                                if (rhs_restr == "") "1" else rhs_restr)),
                      data = d, weights = wts, cluster = ~ID_DGA)
  y0 <- stats::fitted(m0); u0 <- stats::resid(m0)
  cl <- as.character(d$ID_DGA); ucl <- unique(cl)
  db <- data.table::copy(d)
  fb <- stats::as.formula(sprintf("yboot ~ %s | ID_DGA", rhs_full))
  tb <- rep(NA_real_, B)
  set.seed(seed)
  for (b in seq_len(B)) {
    wg <- stats::setNames(sample(c(-1, 1), length(ucl), replace = TRUE), ucl)
    data.table::set(db, j = "yboot", value = y0 + u0 * wg[cl])
    mb <- tryCatch(fixest::feols(fb, data = db, weights = wts, cluster = ~ID_DGA),
                   error = function(e) NULL)
    if (is.null(mb)) next
    cb <- as.data.frame(summary(mb)$coeftable)
    if (term %in% rownames(cb)) tb[b] <- cb[term, 3]
  }
  nv <- sum(!is.na(tb))
  list(est = ct[[1]], p_analytic = ct[[4]],
       p_wcb = (1 + sum(abs(tb) >= abs(t_obs), na.rm = TRUE)) / (1 + nv), nv = nv)
}

#' Wild-cluster-bootstrap confirmation of the storage-band trends and 2010 step, unweighted and
#' capacity-weighted (Supplementary Table S6).
#' @return data.table(quantity, value, detail)
storage_wild_bootstrap <- function(band_annual, levels_long, split_year = 2010L,
                                   B = 1999L, seed = 1L) {
  cap <- unique(data.table::as.data.table(levels_long)[is.finite(max_level_hm3),
                                                       .(ID_DGA, max_level_hm3)])
  d <- merge(data.table::as.data.table(band_annual), cap, by = "ID_DGA")
  d[, post := as.integer(year >= split_year)]
  d[, yr_post := (year - split_year) * post]
  specs <- list(
    list(rhs = "year",           restr = "",        term = "year",    lab = "trend (per yr)"),
    list(rhs = "post + yr_post", restr = "yr_post", term = "post",    lab = "step at 2010"),
    list(rhs = "post + yr_post", restr = "post",    term = "yr_post", lab = "post-2010 drift (per yr)"))
  comps <- function(lab) if (lab == "trend (per yr)") c("peak", "trough", "amplitude")
                         else c("peak", "trough")
  rows <- list()
  for (wcol in list(NULL, "max_level_hm3")) {
    wlab <- if (is.null(wcol)) "unweighted" else "capacity-weighted"
    for (s in specs) for (comp in comps(s$lab)) {
      r <- .rr4_wcb(d, comp, s$rhs, s$restr, s$term, wcol = wcol, B = B, seed = seed)
      rows[[length(rows) + 1L]] <- data.table::data.table(
        quantity = sprintf("%s %s, %s", wlab, s$lab, comp),
        value = round(r$est, 4),
        detail = sprintf("analytic cluster-robust p = %.3g; wild cluster bootstrap p = %.3f (%d draws, Rademacher, null imposed)",
                         r$p_analytic, r$p_wcb, r$nv))
    }
  }
  data.table::rbindlist(rows)
}
