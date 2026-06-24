# Phase 1 (exploratory): estimate the storage threshold s* in the storage_fraction ->
# ecological-outcome relationship, per reservoir, via segmented regression.
#
# CAUTION (H1 identification): a detected breakpoint is the EXPECTED signature of an
# operating rule curve. s* is only evidence of emergent "rectification" if it does NOT
# coincide with a documented rule-curve trigger (gated on operating-rule data) and if the
# tail change is more than a mean shift. Treat these estimates as descriptive, with wide
# uncertainty given short series dominated by one mega-drought episode.

#' Per-reservoir segmented fit of outcome on storage fraction.
#' @param panel assemble_analysis_panel() output
#' @param min_n minimum finite observations to attempt a fit
#' @return data.table(ID_DGA, breakpoint, breakpoint_se, slope_below, slope_above, n, ok)
estimate_storage_threshold <- function(panel, min_n = 60) {
  dt <- data.table::as.data.table(panel)[is.finite(storage_fraction) & is.finite(outcome)]
  ids <- unique(dt$ID_DGA)
  res <- vector("list", length(ids))

  for (i in seq_along(ids)) {
    d <- dt[ID_DGA == ids[i]]
    if (nrow(d) < min_n) { res[[i]] <- .threshold_na(ids[i], nrow(d)); next }

    fit <- tryCatch({
      lin <- stats::lm(outcome ~ storage_fraction, data = d)
      seg <- segmented::segmented(lin, seg.Z = ~storage_fraction)
      if (is.null(seg$psi)) stop("no breakpoint")
      slopes <- segmented::slope(seg)$storage_fraction[, "Est."]
      data.table::data.table(
        ID_DGA = ids[i],
        breakpoint    = unname(seg$psi[, "Est."]),
        breakpoint_se = unname(seg$psi[, "St.Err"]),
        slope_below   = slopes[1],
        slope_above   = slopes[2],
        n = nrow(d), ok = TRUE
      )
    }, error = function(e) .threshold_na(ids[i], nrow(d)))

    res[[i]] <- fit
  }
  data.table::rbindlist(res, use.names = TRUE)
}

.threshold_na <- function(id, n) {
  data.table::data.table(ID_DGA = id, breakpoint = NA_real_, breakpoint_se = NA_real_,
                         slope_below = NA_real_, slope_above = NA_real_, n = n, ok = FALSE)
}
