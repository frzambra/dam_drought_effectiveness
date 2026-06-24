# Extract index rasters at the reservoir locations.
# INTERIM spatial unit = the dam point (optionally a buffer). The hydrologically correct
# unit (contributing watershed for forcing, command area for response) is gated on
# boundary data — see config/reservoirs.yml:extraction.

#' Extract every raster in the catalog at the reservoir points.
#' @param catalog  build_raster_catalog() output (role, product, timescale, date, path)
#' @param points   read_reservoir_points() sf, in the rasters' CRS
#' @param buffer_m if > 0, average raster cells within this radius (metres) of each point
#' @return data.table(ID_DGA, role, product, timescale, date, value)
extract_index_at_points <- function(catalog, points, buffer_m = 0) {
  ids <- points$ID_DGA
  v   <- terra::vect(points)

  if (buffer_m > 0) {                       # buffer in a metric CRS, then back
    v_m <- terra::project(v, "EPSG:3857")
    v_m <- terra::buffer(v_m, width = buffer_m)
    v   <- terra::project(v_m, terra::crs(v))
  }

  groups <- split(catalog, by = c("role", "product", "timescale"), drop = TRUE)
  out <- vector("list", length(groups))

  for (i in seq_along(groups)) {
    g <- data.table::setorder(data.table::copy(groups[[i]]), date)
    rs <- terra::rast(g$path)               # layers in date order
    ex <- if (buffer_m > 0) {
      terra::extract(rs, v, fun = mean, na.rm = TRUE, ID = FALSE)
    } else {
      terra::extract(rs, v, ID = FALSE)
    }
    m <- data.table::as.data.table(ex)
    m[, ID_DGA := ids]
    long <- data.table::melt(m, id.vars = "ID_DGA",
                             variable.name = "layer", value.name = "value")
    long[, date := g$date[as.integer(layer)]]
    long[, `:=`(role = g$role[1L], product = g$product[1L],
                timescale = g$timescale[1L], layer = NULL)]
    out[[i]] <- long
  }

  res <- data.table::rbindlist(out, use.names = TRUE)
  data.table::setcolorder(res, c("ID_DGA", "role", "product", "timescale", "date", "value"))
  data.table::setorder(res, ID_DGA, role, product, timescale, date)
  res[]
}
