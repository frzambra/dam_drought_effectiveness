# Robustness battery for the forcing-conditioned ATT (dr_att_forcing). Each scenario reuses
# the SAME estimator core (dr_estimate, src/R/causal/doubly_robust.R); only the assembled
# frame changes — which weights, which forcing slope, which covariates, which subset. The
# headline is the doubly-robust ATT in every scenario, tabled side by side so the reader sees
# the +0.33 transmission-slope effect is not an artefact of one analytic choice.
#
# Axes covered (the open items from docs/progress_summary/2026-06-26_forcing-conditioned-att.md):
#   1. Nonlinear aridity     — add log_aridity^2 to the outcome model; restrict to the common
#                              aridity overlap band.
#   2. SPEI timescale        — refit the transmission slope on SPEI-6 / SPEI-12 / SPEI-24.
#   3. Forcing lag           — forcing leading the outcome by 1 year.
#   4. Matching design       — re-estimate on the CEM (n=17) and 1:k NN subsets, not just ebal.
#   5. Slope-fit thresholds  — vary min_years and min_forcing_range in fit_response_slopes.

#' Assemble a DR frame: a weight-bearing covariate table + a per-unit slope outcome.
#'
#' @param wframe data.table with unit_id, treated, a weight column, covars, kg_group
#' @param slopes fit_response_slopes() output (unit_id, resp_slope, ...)
#' @param wcol   name of the weight column in `wframe` (default "w")
#' @return data.table ready for dr_estimate(): y = resp_slope, w = weights, + a precomputed
#'         log_aridity_sq column so the nonlinear-aridity scenario can request it
.assemble_dr_frame <- function(wframe, slopes, wcol = "w") {
  w <- data.table::as.data.table(data.table::copy(wframe))
  if (wcol != "w") data.table::setnames(w, wcol, "w")
  s <- data.table::as.data.table(slopes)[, .(unit_id, y = resp_slope)]
  d <- merge(w, s, by = "unit_id")
  if ("log_aridity" %in% names(d)) d[, log_aridity_sq := log_aridity^2]
  d[]
}

#' One doubly-robust row from an assembled frame (errors -> a NA row, never aborts the battery).
.dr_row <- function(scenario, frame, covars) {
  out <- tryCatch(dr_estimate(frame, covars), error = function(e) e)
  if (inherits(out, "error"))
    return(data.table::data.table(scenario = scenario, att = NA_real_, se = NA_real_,
                                  t = NA_real_, ci_lo = NA_real_, ci_hi = NA_real_,
                                  n_treated = NA_integer_, n_control = NA_integer_,
                                  note = conditionMessage(out)))
  e <- out$estimates[estimator == "doubly_robust"]
  data.table::data.table(scenario = scenario, att = e$att, se = e$se, t = e$t,
                         ci_lo = e$ci_lo, ci_hi = e$ci_hi,
                         n_treated = e$n_treated, n_control = e$n_control, note = "")
}

#' Run the full robustness battery for the forcing-conditioned ATT.
#'
#' @param matched_set       fit_matched_set() output (ebal weights)
#' @param robustness_matches fit_robustness_matches() output (CEM + NN, same trimmed sample)
#' @param znpp_annual        extract_unit_index_annual() output (unit_id, year, level)
#' @param forcing_by_ts      named list of extract_unit_forcing_annual() tables keyed by SPEI
#'                           timescale as character, e.g. list(`6`=, `12`=, `24`=)
#' @param covars             baseline outcome-model covariates
#' @return list(table = headline scenario x DR-ATT comparison, baseline = full dr_estimate)
run_forcing_robustness <- function(matched_set, robustness_matches, znpp_annual,
                                   forcing_by_ts,
                                   covars = c("log_area", "elev_mean", "log_aridity")) {
  ebal <- data.table::as.data.table(matched_set$data)            # carries w
  rm_d <- data.table::as.data.table(robustness_matches$data)
  rm_d[, `:=`(w_cem = robustness_matches$cem$weights,
              w_nn  = robustness_matches$nn$weights)]

  # Slope outcomes for the scenarios that need them.
  slopes <- function(ts, lag = 0L, min_years = 10L, min_range = 1.0) {
    f <- forcing_by_ts[[as.character(ts)]]
    fit_response_slopes(build_response_panel(znpp_annual, f, lag = lag),
                        min_years = min_years, min_forcing_range = min_range)
  }
  s12 <- slopes(12)                                              # primary slope outcome

  rows <- list()

  # --- baseline (ebal, SPEI-12, lag 0, linear aridity) ------------------------------
  base_fit <- dr_estimate(.assemble_dr_frame(ebal, s12), covars)
  rows[["baseline (ebal, SPEI-12, lag0)"]] <-
    .dr_row("baseline (ebal, SPEI-12, lag0)", .assemble_dr_frame(ebal, s12), covars)

  # --- 1. nonlinear aridity ---------------------------------------------------------
  rows[["+ aridity^2 term"]] <-
    .dr_row("+ aridity^2 term", .assemble_dr_frame(ebal, s12),
            c(covars, "log_aridity_sq"))
  # common aridity overlap band (drop non-overlapping extremes, refit on ebal weights)
  fr <- .assemble_dr_frame(ebal, s12)
  lo <- max(fr[treated == 1L, min(log_aridity)], fr[treated == 0L, min(log_aridity)])
  hi <- min(fr[treated == 1L, max(log_aridity)], fr[treated == 0L, max(log_aridity)])
  rows[["common aridity band"]] <-
    .dr_row("common aridity band", fr[log_aridity >= lo & log_aridity <= hi], covars)

  # --- 2. SPEI timescale ------------------------------------------------------------
  for (ts in c(6, 24)) {
    sl <- slopes(ts)
    rows[[sprintf("SPEI-%d forcing", ts)]] <-
      .dr_row(sprintf("SPEI-%d forcing", ts), .assemble_dr_frame(ebal, sl), covars)
  }

  # --- 3. forcing lag (1 yr) --------------------------------------------------------
  rows[["SPEI-12 lag 1yr"]] <-
    .dr_row("SPEI-12 lag 1yr", .assemble_dr_frame(ebal, slopes(12, lag = 1L)), covars)

  # --- 4. matching design (CEM, NN) -------------------------------------------------
  rows[["CEM subset"]] <-
    .dr_row("CEM subset", .assemble_dr_frame(rm_d, s12, wcol = "w_cem"), covars)
  rows[["NN 1:2 subset"]] <-
    .dr_row("NN 1:2 subset", .assemble_dr_frame(rm_d, s12, wcol = "w_nn"), covars)

  # --- 5. slope-fit thresholds ------------------------------------------------------
  rows[["min_years 15"]] <-
    .dr_row("min_years 15", .assemble_dr_frame(ebal, slopes(12, min_years = 15L)), covars)
  rows[["min_range 1.5"]] <-
    .dr_row("min_range 1.5", .assemble_dr_frame(ebal, slopes(12, min_range = 1.5)), covars)

  tab <- data.table::rbindlist(rows, use.names = TRUE)
  list(table = tab[], baseline = base_fit)
}
