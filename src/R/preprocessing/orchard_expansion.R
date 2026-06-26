# Orchard-area EXPANSION mediator (H2 induced-demand) from the Catastro Frutícola plantation
# year. The cadastre is a current snapshot, but each polygon carries its establishment year
# (`plant_year`), so cumulative orchard area present by year t = sum of areas of (still-existing)
# orchards planted ≤ t. This reconstructs the irrigated-EXPANSION trajectory per subcuenca — the
# H2 mediator the project was gated on. The ecological-slope tests asked "is irrigated land more
# drought-sensitive in dammed basins" (null); this asks the prior limb "did dammed basins EXPAND
# irrigated area more" (the induced-demand prediction).
#
# CAVEATS baked into interpretation (not the code): (1) snapshot-survival — orchards planted then
# GRUBBED before the survey are invisible, so early-year area is under-counted and expansion
# over-stated; (2) endogenous siting — reservoirs are built where irrigation demand exists, so a
# dammed-vs-control expansion gap is reservoir-FACILITATED at best, not cleanly reservoir-CAUSED
# (the H2 identification threat); (3) plant_year ~8% missing + a 1900 fill -> treated as
# pre-window baseline.

#' Assign orchard polygons to watershed units by centroid-in-polygon.
#' @param orchards read_orchards_latest() output (sf, any CRS; carries sup_ha, plant_year)
#' @param units    sf polygons with `unit_id`
#' @return data.table(unit_id, sup_ha, plant_year) for orchards whose centroid falls in a unit
assign_orchards_to_units <- function(orchards, units) {
  cen <- sf::st_centroid(sf::st_geometry(orchards))
  if (sf::st_crs(cen) != sf::st_crs(units)) cen <- sf::st_transform(cen, sf::st_crs(units))
  ix  <- sf::st_intersects(cen, units)
  uid <- vapply(ix, function(z) if (length(z)) units$unit_id[z[1]] else NA_character_, character(1))
  o <- data.table::data.table(unit_id = uid, sup_ha = orchards$sup_ha,
                              plant_year = orchards$plant_year)
  o[!is.na(unit_id) & !is.na(sup_ha)][]
}

#' Cumulative orchard area (ha) per unit per year, zero-filled across ALL units.
#'
#' Establishment year = plant_year, with missing / pre-1950 values folded to `baseline_year`
#' (counted as present from the window start). Units with no orchards get 0 in every year — the
#' correct estimand includes basins that did not expand.
#'
#' @param orchards_assigned assign_orchards_to_units() output
#' @param unit_ids          all units to include (e.g. matched_set$data$unit_id)
#' @param years             panel years (default 2005:2024)
#' @param baseline_year     year to assign unknown/old plant_years (default 1990, pre-window)
#' @return data.table(unit_id, year, orchard_ha)
orchard_area_panel <- function(orchards_assigned, unit_ids, years = 2005:2024,
                               baseline_year = 1990L) {
  o <- data.table::copy(orchards_assigned)
  o[, py2 := data.table::fifelse(is.na(plant_year) | plant_year < 1950L,
                                 baseline_year, plant_year)]
  estab <- o[, .(ha = sum(sup_ha)), by = .(unit_id, py2)]
  estab <- estab[order(unit_id, py2)][, cum_ha := cumsum(ha), by = unit_id]

  grid <- data.table::CJ(unit_id = unique(unit_ids), year = years)
  data.table::setkey(estab, unit_id, py2)
  # rolling join: cumulative area at the latest establishment year <= panel year
  panel <- estab[grid, on = .(unit_id, py2 = year), roll = TRUE,
                 .(unit_id, year = py2, orchard_ha = cum_ha)]
  panel[is.na(orchard_ha), orchard_ha := 0]
  data.table::setorder(panel, unit_id, year)
  panel[]
}

#' Per-unit orchard-expansion summary outcomes for the ATT.
#' @param area_panel  orchard_area_panel() output
#' @param unit_covars data.table with unit_id + area_km2 (e.g. matched_set$data)
#' @return data.table(unit_id, ha_start, ha_end, ha_added, add_per_km2, log_ratio)
orchard_expansion_summary <- function(area_panel, unit_covars) {
  p  <- data.table::as.data.table(area_panel)
  y0 <- min(p$year); y1 <- max(p$year)
  s  <- p[, .(ha_start = orchard_ha[year == y0], ha_end = orchard_ha[year == y1]), by = unit_id]
  s  <- merge(s, data.table::as.data.table(unit_covars)[, .(unit_id, area_km2)], by = "unit_id")
  s[, `:=`(ha_added    = ha_end - ha_start,
           add_per_km2 = (ha_end - ha_start) / area_km2,
           log_ratio   = log((ha_end + 1) / (ha_start + 1)))]
  data.table::setorder(s, -add_per_km2)
  s[]
}

#' Doubly-robust ATT of being dammed on orchard expansion (default: ha added per km²).
#' @param matched_set fit_matched_set() output
#' @param expansion   orchard_expansion_summary() output
#' @param outcome_col expansion metric (default "add_per_km2"; also "log_ratio", "ha_added")
#' @return fit_doubly_robust() result
fit_orchard_expansion_att <- function(matched_set, expansion, outcome_col = "add_per_km2") {
  fit_doubly_robust(matched_set, expansion, outcome_col = outcome_col)
}
