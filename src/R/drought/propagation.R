# Phase 1: drought propagation — which forcing accumulation timescale and lag best
# explains the response (storage, or an ecological outcome). This selects the index
# used downstream and is itself a descriptive result.

#' Cross-correlate a per-reservoir response series against forcing series, per
#' (product, timescale), and return the lag with maximum correlation.
#'
#' @param response  data.table(ID_DGA, date, y) — e.g. storage_fraction or an outcome
#' @param forcing   extract_index_at_points() rows with role == "forcing"
#'                  (ID_DGA, product, timescale, date, value)
#' @param max_lag   maximum lag in months (forcing leading the response)
#' @param sign      "pos" keeps the most positive corr, "abs" the largest |corr|
#' @return data.table(ID_DGA, product, timescale, best_lag, best_corr, n)
best_timescale_lag <- function(response, forcing, max_lag = 18, sign = "abs") {
  resp <- data.table::as.data.table(response)[, .(ID_DGA, date, y)]
  forc <- data.table::as.data.table(forcing)[
    role == "forcing" | is.na(role), .(ID_DGA, product, timescale, date, x = value)]

  keys <- unique(forc[, .(ID_DGA, product, timescale)])
  res  <- vector("list", nrow(keys))

  for (i in seq_len(nrow(keys))) {
    k <- keys[i]
    f <- forc[k, on = .(ID_DGA, product, timescale)]
    d <- merge(resp[ID_DGA == k$ID_DGA], f[, .(date, x)], by = "date")
    data.table::setorder(d, date)
    d <- d[is.finite(x) & is.finite(y)]
    if (nrow(d) < 24) next                       # too short to trust

    cc <- stats::ccf(d$x, d$y, lag.max = max_lag, plot = FALSE, na.action = stats::na.pass)
    keep <- cc$lag <= 0                          # forcing at/leading the response
    lags <- cc$lag[keep]; cors <- cc$acf[keep]
    j <- if (sign == "pos") which.max(cors) else which.max(abs(cors))

    res[[i]] <- data.table::data.table(
      ID_DGA = k$ID_DGA, product = k$product, timescale = k$timescale,
      best_lag = -lags[j], best_corr = cors[j], n = nrow(d)
    )
  }
  out <- data.table::rbindlist(res, use.names = TRUE)
  data.table::setorder(out, ID_DGA, product, timescale)
  out[]
}

#' Pick a single dominant (product, timescale, lag) across reservoirs — the headline
#' propagation result used to build the analysis panel. Median lag, mean |corr|.
summarise_propagation <- function(prop) {
  data.table::as.data.table(prop)[
    , .(median_lag = stats::median(best_lag, na.rm = TRUE),
        mean_abs_corr = mean(abs(best_corr), na.rm = TRUE),
        n_reservoirs = data.table::uniqueN(ID_DGA)),
    by = .(product, timescale)
  ][order(-mean_abs_corr)]
}
