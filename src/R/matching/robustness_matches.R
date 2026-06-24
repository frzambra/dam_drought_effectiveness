# Robustness matches for the subcuenca matched set: coarsened exact matching (CEM) and
# 1:k nearest-neighbour (Mahalanobis), both on the SAME common-support sample as the
# entropy-balance primary (common_support_trim). If the reservoir effect survives all
# three designs, it is not an artefact of one weighting scheme.

#' Balance summary for one MatchIt fit (targeted covariates + latitude diagnostic).
#' @return data.table(method, n_treated, n_control, ess_control, max_abs_smd, lat_smd)
.match_summary <- function(method, m, cov) {
  bt <- cobalt::bal.tab(m, un = TRUE, addl = ~lat, data = as.data.frame(cov),
                        stats = "mean.diffs")$Balance
  ww <- m$weights
  ctrl <- ww[cov$treated == 0L & ww > 0]
  data.table::data.table(
    method      = method,
    n_treated   = sum(ww[cov$treated == 1L] > 0),
    n_control   = sum(cov$treated == 0L & ww > 0),
    ess_control = round(sum(ctrl)^2 / sum(ctrl^2), 1),
    max_abs_smd = round(max(abs(bt[rownames(bt) %in% c("log_area", "elev_mean"), "Diff.Adj"])), 3),
    lat_smd     = round(bt["lat", "Diff.Adj"], 3)
  )
}

#' Run CEM and 1:k NN on the common-support sample and compare to the ebal primary.
#'
#' @param cov build_match_covariates() output (untrimmed; trimmed here identically)
#' @param ebal fit_matched_set() output, for side-by-side comparison
#' @param nn_ratio number of controls matched per treated in NN (default 2)
#' @param min_controls,elev_buffer_m passed to common_support_trim()
#' @return list(comparison, cem, nn, data) — `comparison` is the headline table
fit_robustness_matches <- function(cov, ebal, nn_ratio = 2L,
                                   min_controls = 10L, elev_buffer_m = 250) {
  d <- common_support_trim(cov, min_controls, elev_buffer_m)$cov
  df <- as.data.frame(d)

  # Coarsened exact matching: kg_group exact (factor), log_area + elev_mean auto-coarsened.
  cem <- MatchIt::matchit(treated ~ log_area + elev_mean + kg_group,
                          data = df, method = "cem", estimand = "ATT")

  # 1:k nearest neighbour: Mahalanobis distance, exact within Köppen group.
  nn <- MatchIt::matchit(treated ~ log_area + elev_mean,
                         data = df, method = "nearest", distance = "mahalanobis",
                         exact = ~kg_group, estimand = "ATT",
                         ratio = nn_ratio, replace = FALSE)

  # ebal summary in the same shape (its weights live on the same trimmed sample).
  ed <- as.data.table(ebal$data)
  ec <- ed[treated == 0L, w]
  ebal_row <- data.table::data.table(
    method = "ebal", n_treated = ed[treated == 1L, .N],
    n_control = ed[treated == 0L & w > 0, .N],
    ess_control = round(sum(ec)^2 / sum(ec^2), 1),
    max_abs_smd = round(max(abs(ebal$balance$Balance[
      rownames(ebal$balance$Balance) %in% c("log_area", "elev_mean"), "Diff.Adj"])), 3),
    lat_smd = round(ebal$balance$Balance["lat", "Diff.Adj"], 3)
  )

  comparison <- data.table::rbindlist(list(
    ebal_row,
    .match_summary("cem", cem, d),
    .match_summary("nn",  nn,  d)
  ), use.names = TRUE)

  list(comparison = comparison[], cem = cem, nn = nn, data = d[])
}
