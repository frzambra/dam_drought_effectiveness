# Checks backing the Discussion limitations raised in the 2026-07-02 review (comments 2 & 9),
# extended after the internal NW review flagged the first version for answering only the AGGREGATE
# registry-openness question rather than Reviewer 3's DIFFERENTIAL one:
#   (9) inter-basin-transfer SUTVA: are any matched treated and control basins in the SAME cuenca
#       (river network)? The within-cuenca contamination rule should guarantee none, so coupling would
#       require an inter-CUENCA transfer specifically joining a treated cuenca to one of its controls.
#   (2) administrative-vs-realized demand, in three parts:
#       (a) aggregate: was the registry effectively CLOSED during the megadrought?
#       (b) differential saturation: do treated basins carry a higher pre-drought (2009) allocated
#           stock per km2 than their weighted controls (the ceiling / utilization concern)?
#       (c) differential closure: did treated basins stop accruing new rights during the megadrought
#           relative to controls? If treated accrual is at least as fast, a policy freeze specific to
#           dammed basins cannot be manufacturing the demand null.
#   A direct allocations-over-renewable-supply utilization rate is not computable from the registry
#   (no per-basin renewable volume), so (b) reports allocated-stock densities; because treated basins
#   are more arid, equal-or-higher density implies utilization at least as high, which is the
#   conservative direction for the ceiling argument handled in the Discussion.

#' @return data.table(metric, value, detail)
build_spillover_demand_checks <- function(matched_set, subcuencas, water_rights_panel,
                                          mega_years = 2010:2021, base_year = 2009L) {
  ms <- data.table::as.data.table(matched_set$data)
  sc <- data.table::as.data.table(sf::st_drop_geometry(subcuencas))[, .(unit_id, parent_id)]
  sc <- unique(sc, by = "unit_id")
  msc <- merge(ms, sc, by = "unit_id", all.x = TRUE)
  t_cu <- msc[treated == 1L, unique(parent_id)]
  c_cu <- msc[treated == 0L & w > 0, unique(parent_id)]
  shared <- intersect(t_cu, c_cu)

  wp  <- data.table::as.data.table(water_rights_panel)
  acc <- wp[year %in% mega_years,
            .(new = sum(new_n, na.rm = TRUE), basins = sum(new_n > 0, na.rm = TRUE)), by = year]

  # (b) pre-drought allocated stock per km2 (ebal-weighted treated vs control)
  wmean <- function(x, w) sum(x * w) / sum(w)
  base <- merge(ms[, .(unit_id, treated, w, area_km2)],
                wp[year == base_year, .(unit_id, cum_n, cum_lsw)], by = "unit_id", all.x = TRUE)
  base[is.na(cum_n),   cum_n   := 0][is.na(cum_lsw), cum_lsw := 0]
  base[, `:=`(n_dens = 100 * cum_n / area_km2, v_dens = cum_lsw / area_km2)]
  bs <- base[, .(n_dens = wmean(n_dens, w), v_dens = wmean(v_dens, w)), by = treated]

  # (c) megadrought accrual rate + closure incidence (zero-grant basins), treated vs control
  mg <- merge(ms[, .(unit_id, treated, w, area_km2)],
              wp[year %in% mega_years, .(new = sum(new_n, na.rm = TRUE)), by = unit_id],
              by = "unit_id", all.x = TRUE)
  mg[is.na(new), new := 0]
  mg[, rate := 100 * new / area_km2 / length(mega_years)]
  ac <- mg[, .(rate = wmean(rate, w), zero = wmean(as.numeric(new == 0), w)), by = treated]

  data.table::data.table(
    metric = c("treated cuencas", "effective-control cuencas", "cuencas shared by a matched pair",
               "new consumptive rights per megadrought year", "basins granted new rights per year",
               "pre-drought (2009) rights stock, treated (per 100 km2, weighted)",
               "pre-drought (2009) winsorized volume stock, treated (l/s per km2, weighted)",
               "megadrought accrual rate, treated (rights per 100 km2 per yr, weighted)",
               "treated basins with zero new rights over the megadrought (share)"),
    value  = c(length(t_cu), length(c_cu), length(shared),
               round(mean(acc$new)), round(mean(acc$basins)),
               round(bs[treated == 1L, n_dens], 1), round(bs[treated == 1L, v_dens], 2),
               round(ac[treated == 1L, rate], 2), round(ac[treated == 1L, zero], 2)),
    detail = c("distinct DGA cuencas holding >=1 treated subcuenca",
               "distinct DGA cuencas holding >=1 effective (w>0) control",
               "contamination rule removes same-cuenca controls => no matched pair shares a river network",
               sprintf("range %d-%d over %d-%d; registry not closed", min(acc$new), max(acc$new),
                       min(mega_years), max(mega_years)),
               sprintf("of %d matched basins", data.table::uniqueN(ms$unit_id)),
               sprintf("control %.1f; higher stock over lower renewable supply => treated utilization at least as high",
                       bs[treated == 0L, n_dens]),
               sprintf("control %.2f", bs[treated == 0L, v_dens]),
               sprintf("control %.2f; treated accrual not slower => no differential administrative closure",
                       ac[treated == 0L, rate]),
               sprintf("control share %.2f", ac[treated == 0L, zero])))
}
