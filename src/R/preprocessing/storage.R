# Storage preprocessing: the single most important transform is percent-of-capacity,
# the ONLY cross-reservoir-comparable storage quantity (raw levels are not comparable).

#' Add percent-of-capacity and a capacity-availability flag to the long levels table.
#' pct_capacity = 100 * level / max_level_hm3 ; NA where capacity is missing (Rungue).
#' @param levels_long output of read_reservoir_levels()
#' @return the table with added columns: pct_capacity, has_capacity
compute_pct_capacity <- function(levels_long) {
  dt <- data.table::copy(levels_long)
  dt[, has_capacity := is.finite(max_level_hm3) & max_level_hm3 > 0]
  dt[, pct_capacity := data.table::fifelse(has_capacity, 100 * level / max_level_hm3, NA_real_)]
  # Clamp obviously impossible over-100% spillover artifacts for a robustness flag,
  # but keep the raw value — do NOT silently overwrite.
  dt[, over_capacity := has_capacity & pct_capacity > 105]
  dt[]
}

#' Storage-fraction (0-1) — the H1 regime/threshold variable. Kept separate from the
#' percentage form to make threshold (s*) code read naturally.
#' @param storage_pct output of compute_pct_capacity()
add_storage_fraction <- function(storage_pct) {
  dt <- data.table::copy(storage_pct)
  dt[, storage_fraction := pct_capacity / 100]
  dt[]
}
