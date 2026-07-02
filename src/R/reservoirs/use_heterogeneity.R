# Reservoir-use heterogeneity (2026-07-02 review, comment 4). Treatment is modelled as a uniform
# basin-level intervention, but operating rules differ by primary use, and hydropower reservoirs are
# not managed to buffer agricultural drought, so mixing them with irrigation reservoirs could dilute a
# buffering signal. Here we (i) report the use composition of the treated basins and (ii) re-estimate
# the headline streamflow slope gap on the IRRIGATION-only subset (dropping treated basins whose
# reservoirs are purely hydropower/potable, controls unchanged). Feeds Supplementary Table S11.

#' Classify treated subcuencas by whether they contain any irrigation reservoir.
#' @return data.table(unit_id, has_irrig, n_res, uses)
classify_reservoir_use <- function(points, reservoir_units) {
  p  <- merge(data.table::as.data.table(sf::st_drop_geometry(points)),
              data.table::as.data.table(sf::st_drop_geometry(reservoir_units))[, .(ID_DGA, unit_id)],
              by = "ID_DGA")
  p[, irrigation := grepl("RIEGO", use)]
  p[, .(has_irrig = any(irrigation), n_res = .N,
        uses = paste(sort(unique(use)), collapse = "; ")), by = unit_id]
}

#' Streamflow SPEI->SSI slope gap on all treated vs the irrigation-only treated subset, with the
#' design's randomization inference, plus the use-composition counts. A stable slope across the two
#' shows the null is not an artefact of pooling hydropower with irrigation reservoirs.
#' @return data.table with a composition row and per-panel all-vs-irrigation slope gaps
build_use_heterogeneity <- function(matched_set, points, reservoir_units,
                                    ssi_panel_itt, ssi_panel_up, n_perm = 999L) {
  bu <- classify_reservoir_use(points, reservoir_units)
  treated <- data.table::as.data.table(matched_set$data)[treated == 1L, unit_id]
  bt <- bu[unit_id %in% treated]
  drop_units <- bt[has_irrig == FALSE, unit_id]

  one <- function(panel, lab) {
    p <- data.table::as.data.table(panel)
    pig <- p[!(unit_id %in% drop_units)]
    ca <- ssi_buffer_coef(fit_ssi_buffering(p))
    ci <- ssi_buffer_coef(fit_ssi_buffering(pig))
    data.table::data.table(quantity = lab,
      all_slope = ca,  all_perm_p  = permute_ssi_buffer(p,   n_perm = n_perm)$p_perm,
      irrig_slope = ci, irrig_perm_p = permute_ssi_buffer(pig, n_perm = n_perm)$p_perm,
      n_treat_all = p[treat == 1L, data.table::uniqueN(unit_id)],
      n_treat_irrig = pig[treat == 1L, data.table::uniqueN(unit_id)])
  }
  slopes <- data.table::rbindlist(list(
    one(ssi_panel_itt, "Streamflow slope gap (ITT)"),
    one(ssi_panel_up,  "Streamflow slope gap (upstream placebo)")))
  comp <- data.table::data.table(
    quantity = "Treated-basin use composition",
    all_slope = NA_real_, all_perm_p = NA_real_, irrig_slope = NA_real_, irrig_perm_p = NA_real_,
    n_treat_all = bt[, .N], n_treat_irrig = bt[has_irrig == TRUE, .N])
  list(composition = bt[], summary = data.table::rbindlist(list(comp, slopes)))
}
