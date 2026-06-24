# Modal Köppen-Geiger climate class per watershed unit — a static matching covariate.
# First real raster -> watershed zonal extraction; also a sanity check on the dissolve.

#' Modal (dominant) Köppen-Geiger class + dominant-class fraction per unit.
#'
#' The KG raster declares NoData = 0 (oceans), so terra reads those as NA and they are
#' dropped. Large Andean basins straddle several zones — `kg_modal_frac` flags how
#' "pure" the dominant class is (low fraction = climatically heterogeneous unit).
#'
#' @param units    sf polygons with a `unit_id` column (e.g. cuencas_dissolved)
#' @param kg_path  path to the Köppen-Geiger raster (~1 km)
#' @param legend   optional named character vector id->code (e.g. c("5"="BWk")) to attach
#' @return data.table(unit_id, kg_modal, kg_modal_frac, n_cells, kg_code)
extract_unit_climate <- function(units, kg_path, legend = NULL) {
  r <- terra::rast(kg_path)
  v <- terra::vect(units)
  if (!terra::same.crs(v, r)) v <- terra::project(v, r)

  ex <- data.table::as.data.table(terra::extract(r, v))   # ID, <layer>
  data.table::setnames(ex, names(ex), c("ID", "cls"))
  ex <- ex[!is.na(cls)]                                   # 0/ocean -> NA -> dropped

  per <- ex[, {
    tb <- sort(table(cls), decreasing = TRUE)
    .(kg_modal = as.integer(names(tb)[1L]),
      kg_modal_frac = as.numeric(tb[1L]) / sum(tb),
      n_cells = sum(tb))
  }, by = ID]

  per[, unit_id := units$unit_id[ID]]
  per[, ID := NULL]
  if (!is.null(legend)) per[, kg_code := unname(legend[as.character(kg_modal)])]
  data.table::setcolorder(per, c("unit_id", "kg_modal",
                                 if (!is.null(legend)) "kg_code", "kg_modal_frac", "n_cells"))
  data.table::setorder(per, unit_id)
  per[]
}

#' Build the id->code legend map from the data_sources koppen_geiger config block.
#' @param sources load_config("data_sources")
#' @return named character vector, e.g. c("4"="BWh","5"="BWk", ...)
koppen_legend <- function(sources) {
  cl <- sources$koppen_geiger$classes
  stats::setNames(vapply(cl, `[[`, character(1), "code"), names(cl))
}
