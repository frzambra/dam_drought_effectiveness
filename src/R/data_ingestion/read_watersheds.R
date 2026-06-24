# Ingest the DGA Banco Nacional de Aguas (BNA) watershed / sub-watershed polygons.
# These are the analysis units for treatment/control matching and zonal extraction,
# replacing the interim dam-point unit. See config/data_sources.yml:watersheds.

#' Read one BNA boundary level (cuencas or subcuencas), reproject, standardize columns.
#'
#' Field names come from config (data_sources.yml:watersheds), so the same reader works
#' for both levels. Output column names are normalized to a level-agnostic schema so
#' downstream code does not branch on cuenca vs subcuenca.
#'
#' @param sources   load_config("data_sources") output
#' @param level     "cuencas" or "subcuencas"
#' @param target_crs CRS to reproject to (match the rasters/points); default EPSG:4326
#' @return sf polygons with columns: unit_id, unit_name, parent_id (NA for cuencas),
#'         unit_region, level, geometry
#'         (unit_region is named to avoid colliding with the reservoir points' own
#'         `region` column during the spatial join.)
read_watersheds <- function(sources, level = c("cuencas", "subcuencas"),
                            target_crs = "EPSG:4326") {
  level <- match.arg(level)
  spec  <- sources$watersheds[[level]]
  if (is.null(spec)) stop("No watersheds$", level, " block in data_sources.yml")

  poly <- sf::st_read(resolve_path(spec$shapefile), quiet = TRUE)
  poly <- sf::st_transform(poly, target_crs)

  id_field     <- spec$id_field
  name_field   <- spec$name_field
  parent_field <- spec$parent_field            # NULL for cuencas
  region_field <- spec$region_fields[[1]]       # first listed (e.g. REGION)

  miss <- setdiff(c(id_field, name_field, parent_field, region_field), names(poly))
  if (length(miss)) stop("Missing expected fields in ", level, ": ",
                         paste(miss, collapse = ", "))

  out <- data.frame(
    unit_id   = as.character(poly[[id_field]]),
    unit_name = as.character(poly[[name_field]]),
    parent_id   = if (is.null(parent_field)) NA_character_ else as.character(poly[[parent_field]]),
    unit_region = as.character(poly[[region_field]]),
    level       = level,
    stringsAsFactors = FALSE
  )
  out <- sf::st_sf(out, geometry = sf::st_geometry(poly))

  if (anyDuplicated(out$unit_id))
    warning(level, ": ", sum(duplicated(out$unit_id)),
            " duplicate unit_id values; dissolve_watersheds() merges them to one ",
            "feature per unit before zonal extraction.")
  out
}

#' Dissolve a watershed layer to ONE (multi)polygon per unit_id.
#'
#' The BNA shapefiles store some basins as several separate polygon features that share a
#' code (islands, disjoint command areas, digitizing splits). Zonal raster extraction must
#' run on one feature per unit or each basin is summarised in pieces. This unions geometry
#' by unit_id and keeps the (constant-within-unit) attributes. A no-op if already unique.
#'
#' @param watersheds read_watersheds() sf for one level
#' @return sf with one row per unit_id, same attribute columns, geometry unioned
dissolve_watersheds <- function(watersheds) {
  attrs <- sf::st_drop_geometry(watersheds)
  ids   <- attrs$unit_id
  if (!anyDuplicated(ids)) return(watersheds)            # already one feature per unit

  keep_cols <- intersect(
    c("unit_id", "unit_name", "parent_id", "unit_region", "level"), names(attrs)
  )
  parts <- split(seq_len(nrow(watersheds)), ids)

  geom <- do.call(c, lapply(parts, function(idx)
    sf::st_union(sf::st_geometry(watersheds)[idx])))     # one geometry per unit

  meta <- attrs[vapply(parts, `[`, integer(1), 1L), keep_cols, drop = FALSE]
  meta <- meta[match(names(parts), meta$unit_id), , drop = FALSE]   # align to geom order

  inconsistent <- vapply(parts, function(idx)
    any(vapply(keep_cols, function(cc) length(unique(attrs[[cc]][idx])) > 1L, logical(1))),
    logical(1))
  if (any(inconsistent))
    warning(sum(inconsistent), " unit(s) had differing attributes across parts; ",
            "kept the first part's values.")

  out <- sf::st_sf(meta, geometry = sf::st_sfc(geom, crs = sf::st_crs(watersheds)))
  rownames(out) <- NULL
  out
}
