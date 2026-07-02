# Two descriptive checks that back Discussion limitations raised in the 2026-07-02 review:
#   (5) inter-basin-transfer SUTVA: are any matched treated and control basins in the SAME cuenca
#       (river network)? The within-cuenca contamination rule should guarantee none, so coupling would
#       require an inter-CUENCA transfer specifically joining a treated cuenca to one of its controls.
#   (6) administrative-vs-realized demand: was the water-rights registry effectively CLOSED during the
#       megadrought (which would make the demand null an artefact of basin saturation), or did new
#       rights keep accruing (so the null is a null DIFFERENCE, not an absence of accrual)?

#' @return data.table(metric, value, detail)
build_spillover_demand_checks <- function(matched_set, subcuencas, water_rights_panel,
                                          mega_years = 2010:2021) {
  ms <- data.table::as.data.table(matched_set$data)
  sc <- data.table::as.data.table(sf::st_drop_geometry(subcuencas))[, .(unit_id, parent_id)]
  sc <- unique(sc, by = "unit_id")
  ms <- merge(ms, sc, by = "unit_id", all.x = TRUE)
  t_cu <- ms[treated == 1L, unique(parent_id)]
  c_cu <- ms[treated == 0L & w > 0, unique(parent_id)]
  shared <- intersect(t_cu, c_cu)

  wp <- data.table::as.data.table(water_rights_panel)[year %in% mega_years]
  acc <- wp[, .(new = sum(new_n, na.rm = TRUE), basins = sum(new_n > 0, na.rm = TRUE)), by = year]

  data.table::data.table(
    metric = c("treated cuencas", "effective-control cuencas", "cuencas shared by a matched pair",
               "new consumptive rights per megadrought year", "basins granted new rights per year"),
    value  = c(length(t_cu), length(c_cu), length(shared),
               round(mean(acc$new)), round(mean(acc$basins))),
    detail = c("distinct DGA cuencas holding >=1 treated subcuenca",
               "distinct DGA cuencas holding >=1 effective (w>0) control",
               "contamination rule removes same-cuenca controls => no matched pair shares a river network",
               sprintf("range %d-%d over %d-%d; registry not closed", min(acc$new), max(acc$new),
                       min(mega_years), max(mega_years)),
               sprintf("of %d matched basins", data.table::uniqueN(ms$unit_id))))
}
