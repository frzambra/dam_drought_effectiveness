# Phase 1: the deficit -> impact RESPONSE FUNCTION. We identify off the SLOPE of impact
# on meteorological deficit, never off levels/calendar time — that is what breaks the
# mega-drought confound (threat T1). See docs/conceptual_framework/identification-strategy.md.

#' Assemble the reservoir x month analysis panel: storage + one forcing index (lagged) +
#' one ecological outcome + period flags.
#' @param storage_pct add_storage_fraction() output
#' @param extracted   extract_index_at_points() output (forcing + outcome rows)
#' @param study       study_period.yml (list)
#' @param forcing     list(product, timescale, lag)  — lag in months (forcing leads)
#' @param outcome     list(product, timescale)
assemble_analysis_panel <- function(storage_pct, extracted, study,
                                    forcing = list(product = "SPEI", timescale = 12, lag = 0),
                                    outcome = list(product = "zcNDVI", timescale = 6)) {
  s <- data.table::as.data.table(storage_pct)[
    , .(ID_DGA, date, pct_capacity, storage_fraction, max_level_hm3, has_capacity)]

  f <- data.table::as.data.table(extracted)[
    role == "forcing" & product == forcing$product & timescale == forcing$timescale,
    .(ID_DGA, date, deficit = value)]
  if (!is.null(forcing$lag) && forcing$lag != 0) {
    f[, date := lubridate::`%m+%`(date, months(forcing$lag))]   # shift forcing forward to lead
  }

  o <- data.table::as.data.table(extracted)[
    role == "outcome" & product == outcome$product &
      (is.na(timescale) | timescale == outcome$timescale),
    .(ID_DGA, date, outcome = value)]

  p <- Reduce(function(a, b) merge(a, b, by = c("ID_DGA", "date")), list(s, f, o))

  mg <- as.Date(study$mega_drought$start)
  p[, period := factor(data.table::fifelse(date < mg, "pre", "mega"), levels = c("pre", "mega"))]
  p[, `:=`(year = data.table::year(date), month = data.table::month(date),
           log_capacity = log(max_level_hm3))]
  data.table::setorder(p, ID_DGA, date)
  p[]
}

#' Lever 2 — within-drought-year cross-sectional dose-response.
#' Year fixed effects absorb the common (mega-drought) shock; the deficit:dose interaction
#' tests whether sensitivity to deficit scales with structural storage dose. This variation
#' is forcing-orthogonal — calendar time cannot mimic it.
#' @param dose column name for the structural dose (default log reservoir capacity;
#'   capacity-per-command-area is the preferred dose but is GATED on irrigated-area data)
fit_dose_response <- function(panel, dose = "log_capacity") {
  fml <- stats::as.formula(sprintf("outcome ~ deficit * %s | year", dose))
  fixest::feols(fml, data = panel[has_capacity == TRUE], cluster = ~ID_DGA)
}

#' Lever 4 — does the deficit->impact slope differ pre-2010 vs mega-drought?
#' Within-dammed (the dammed-vs-matched-control contrast is GATED on watershed boundaries).
#' A pre-period slope already different across groups would falsify a control group.
fit_period_slopes <- function(panel) {
  fixest::feols(outcome ~ deficit * period | ID_DGA, data = panel, cluster = ~ID_DGA)
}
