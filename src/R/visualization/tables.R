# Manuscript tables. build_*_table() returns tidy data.tables; write_table() persists CSV + a
# markdown rendering under results/tables/.

#' Assemble the convergent-null main results table from the key estimators.
#'
#' Rows: cross-sectional matched DR ATTs (irrigated-area expansion; reservoir ET buffering) +
#' forcing-interacted DiD slope-gaps (area, whole-basin ET, orchard ET). One table making the point
#' that every independent test of the H2 vulnerability mechanism straddles zero.
#'
#' @param att_area    att_irrig_area_expansion (fit_doubly_robust output)
#' @param att_etbuf   att_et_buffering (list with $att = doubly_robust row)
#' @param did_summary did_summary (slope-gap table with p_perm)
#' @return data.table(group, outcome, method, estimand, estimate, se, ci_lo, ci_hi, p, n_treated,
#'                    n_control, verdict)
build_main_results_table <- function(att_area, att_etbuf, did_summary,
                                     att_wr = NULL, wr_perm = NA_real_) {
  drrow <- function(x) data.table::as.data.table(x$estimates)[estimator == "doubly_robust"]
  a <- drrow(att_area); b <- data.table::as.data.table(att_etbuf$att)
  cs <- function(outcome, estimand, r, p = NA_real_) data.table::data.table(
    group = "Cross-sectional matched ATT", outcome = outcome, method = "DR matched",
    estimand = estimand, estimate = r$att, se = r$se, ci_lo = r$ci_lo, ci_hi = r$ci_hi,
    p = p, n_treated = r$n_treated, n_control = r$n_control)
  rows <- list(
    cs("Cropland-area expansion", "ha km^-2 added", a),
    cs("Reservoir ET buffering",   "d log ET / d SPEI", b))
  # Water-rights accrual (induced-demand test): a cross-sectional expansion ATT judged, like the DiD
  # rows, by randomization inference (the analytic CI over-rejects at ~21 clusters).
  if (!is.null(att_wr))
    rows[[length(rows) + 1L]] <-
      cs("Water-rights accrual", "rights / 100 km^2 added", drrow(att_wr), p = wr_perm)

  ds  <- data.table::as.data.table(did_summary)
  lab <- c(area_frac = "Cropland area", log_basin_ET = "Whole-basin ET",
           log_orchard_ET = "Orchard ET")
  for (i in seq_len(nrow(ds))) {
    r <- ds[i]
    rows[[length(rows) + 1L]] <- data.table::data.table(
      group = "Forcing-interacted DiD (slope-gap)", outcome = lab[[r$spec]],
      method = "treat:spei_c", estimand = "differential deficit->impact slope",
      estimate = r$att_slope, se = r$se, ci_lo = r$att_slope - 1.96 * r$se,
      ci_hi = r$att_slope + 1.96 * r$se, p = r$p_perm,
      n_treated = NA_integer_, n_control = NA_integer_)
  }
  tab <- data.table::rbindlist(rows)
  # Verdict from the trustworthy inference: DiD rows (few clusters -> cluster-robust CI over-rejects)
  # are judged by the PERMUTATION p; cross-sectional ATTs by their CI. The reported ci_lo/ci_hi on
  # DiD rows are cluster-robust and shown for completeness only.
  sgn <- function(est) data.table::fifelse(est > 0, "+ (vulnerability)", "- (buffering)")
  tab[, verdict := data.table::fifelse(
        !is.na(p), data.table::fifelse(p > 0.05, "null", sgn(estimate)),
        data.table::fifelse(ci_lo <= 0 & ci_hi >= 0, "null", sgn(estimate)))]
  # "Evidence z" for the forest plot, on a common axis: DiD rows from the permutation p (the inference
  # we trust), ATT rows from estimate/SE. So whole-basin ET (cluster-sig but permutation-null, and
  # pre-trend-confounded) correctly reads as null.
  tab[, z := data.table::fifelse(
        !is.na(p), sign(estimate) * stats::qnorm(pmin(1 - 1e-6, 1 - p / 2)), estimate / se)]
  tab[]
}

#' Persist a results table as CSV + a GitHub-markdown rendering under results/tables/.
#' @return character vector of written paths (for tar_target(format = "file"))
write_table <- function(tab, name, digits = 3) {
  dir <- project_path("results/tables"); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  csv <- file.path(dir, paste0(name, ".csv"))
  data.table::fwrite(tab, csv)
  d <- data.table::copy(data.table::as.data.table(tab))
  numcols <- names(d)[vapply(d, is.numeric, logical(1))]
  for (cc in numcols) d[[cc]] <- formatC(d[[cc]], digits = digits, format = "g")
  md <- file.path(dir, paste0(name, ".md"))
  hdr <- paste0("| ", paste(names(d), collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", ncol(d)), collapse = "|"), "|")
  body <- apply(d, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  writeLines(c(hdr, sep, body), md)
  c(csv, md)
}
