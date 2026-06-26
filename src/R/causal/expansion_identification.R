# Causal scrutiny of the orchard-EXPANSION ATT (H2 induced-demand). The cross-sectional matched
# ATT (att_orchard_expansion) shows dammed basins have far more irrigated orchard than matched
# controls, but the headline threat is ENDOGENOUS SITING: reservoirs are built in Chile's prime
# fruit basins, so the gap may predate the dams rather than be caused by them. Two diagnostics:
#
#   1. Reservoir commissioning years per treated basin — quantifies the LEFT-CENSORING that caps
#      what is identifiable (most dams predate the orchard record entirely).
#   2. Pre-trends DiD-in-slopes on the reconstructed orchard trajectory (1990-2024): if the
#      dammed-vs-control divergence concentrates AFTER 2005 it is consistent with a reservoir/
#      drought-era effect; if the gap was already present (or the ratio is shrinking) it is the
#      siting signature. Survival-bias caveat applies to LEVELS but partly differences out of the
#      treated-vs-control RELATIVE comparison (both groups reconstructed identically).

#' Earliest reservoir commissioning year per (matched) subcuenca unit.
#' @param reservoir_units assign_reservoirs_both_levels() output (ID_DGA, unit_id, level)
#' @param points         read_reservoir_points() output (ID_DGA, anocontr, ...)
#' @return data.table(unit_id, commyear, n_dams) — commyear NA if all dams lack anocontr
reservoir_commission_years <- function(reservoir_units, points) {
  ru <- data.table::as.data.table(reservoir_units)[level == "subcuencas", .(ID_DGA, unit_id)]
  pa <- data.table::as.data.table(sf::st_drop_geometry(points))[, .(ID_DGA, anocontr)]
  m  <- merge(ru, pa, by = "ID_DGA")
  m[, .(commyear = if (all(is.na(anocontr))) NA_integer_ else min(anocontr, na.rm = TRUE),
        n_dams = .N), by = unit_id]
}

#' Pre-trends / siting diagnostic on the orchard-expansion trajectory.
#'
#' Fits a DiD-in-slopes: log1p(orchard_ha) on treated × post-`split_year`, with unit and year
#' fixed effects (treated is time-invariant -> absorbed by unit FE; the treated:post interaction
#' carries the differential). A POSITIVE interaction = dammed basins expanded faster *after* the
#' split (recent divergence, consistent with a reservoir effect); ≈0 or NEGATIVE = the gap was
#' already there or controls are catching up (the siting signature). Also returns the
#' treated/control total-area ratio over time (the most survival-bias-robust readout).
#'
#' @param panel    orchard_area_panel() over a long span (e.g. 1990:2024)
#' @param matched_set fit_matched_set() output (for treated + weights)
#' @param split_year period boundary (default 2005, the storage-era / drought start)
#' @return list(did = fixest model, ratio = data.table(year, treated_ha, control_ha, ratio),
#'              period_growth = per-group log-area CAGR pre vs post)
orchard_expansion_pretrends <- function(panel, matched_set, split_year = 2005L) {
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, treated, w)]
  p  <- merge(data.table::as.data.table(panel), ms, by = "unit_id")
  p[, `:=`(post = as.integer(year >= split_year), lha = log1p(orchard_ha))]

  did <- fixest::feols(lha ~ treated:post | unit_id + year, data = p, cluster = ~unit_id)

  ratio <- p[, .(treated_ha = sum(orchard_ha[treated == 1]),
                 control_ha = sum(orchard_ha[treated == 0])), by = year]
  ratio[, ratio := treated_ha / control_ha]
  data.table::setorder(ratio, year)

  # group log-area growth rate (CAGR) pre vs post split, on group totals
  tot <- p[, .(ha = sum(orchard_ha)), by = .(treated, year)]
  cagr <- function(d) {
    d <- d[order(year)]
    pre  <- d[year <  split_year]; pos <- d[year >= split_year]
    pre_r  <- if (nrow(pre) > 1)  (log(pre$ha[nrow(pre)] + 1)  - log(pre$ha[1] + 1))  / (diff(range(pre$year)))  else NA_real_
    post_r <- if (nrow(pos) > 1)  (log(pos$ha[nrow(pos)] + 1) - log(pos$ha[1] + 1)) / (diff(range(pos$year))) else NA_real_
    data.table::data.table(pre_lograte = pre_r, post_lograte = post_r)
  }
  period_growth <- tot[, cagr(.SD), by = treated]

  list(did = did, ratio = ratio[], period_growth = period_growth[])
}
