# Assign monitored reservoirs to their containing watershed unit by point-in-polygon.
# There is NO attribute key linking the reservoir table to BNA codes, so the treatment
# unit is defined geometrically. See config/data_sources.yml:watersheds:notes.

#' Spatially join reservoir points to a watershed level (point-in-polygon).
#'
#' Points and polygons must already share a CRS (both are reprojected to EPSG:4326 by
#' their readers). Points that fall in no polygon (offshore digitizing slop, coastal
#' dams just outside the boundary) come back with NA unit_id and are reported.
#'
#' @param points     read_reservoir_points() sf (must carry ID_DGA)
#' @param watersheds read_watersheds() sf for one level (carries unit_id, level, ...)
#' @return data.table(ID_DGA, name_shp, region, level, unit_id, unit_name, parent_id, unit_region)
assign_reservoirs_to_units <- function(points, watersheds) {
  if (sf::st_crs(points) != sf::st_crs(watersheds))
    stop("CRS mismatch: reproject points and watersheds to a common CRS first.")

  joined <- sf::st_join(points, watersheds, join = sf::st_within, left = TRUE)

  res <- data.table::as.data.table(sf::st_drop_geometry(joined))
  keep <- intersect(
    c("ID_DGA", "name_shp", "region", "level",
      "unit_id", "unit_name", "parent_id", "unit_region"),
    names(res)
  )
  res <- res[, ..keep]

  unmatched <- res[is.na(unit_id)]
  if (nrow(unmatched))
    warning(nrow(unmatched), " reservoir(s) fell outside every ",
            watersheds$level[1], " polygon: ",
            paste(unmatched$ID_DGA, collapse = ", "),
            " (snap to nearest unit or verify coordinates).")

  data.table::setorder(res, ID_DGA)
  res[]
}

#' Convenience: assign reservoirs to BOTH levels and bind into one long table.
#' @param points     read_reservoir_points() sf
#' @param cuencas    read_watersheds(..., "cuencas")
#' @param subcuencas read_watersheds(..., "subcuencas")
#' @return data.table stacked over both levels (one row per reservoir per level)
assign_reservoirs_both_levels <- function(points, cuencas, subcuencas) {
  data.table::rbindlist(
    list(
      assign_reservoirs_to_units(points, cuencas),
      assign_reservoirs_to_units(points, subcuencas)
    ),
    use.names = TRUE, fill = TRUE
  )
}
