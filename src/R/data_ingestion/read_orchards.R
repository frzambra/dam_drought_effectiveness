# Catastro Frutícola (CIREN/ODEPA fruit-orchard cadastre) — DEFINITIVELY IRRIGATED orchard
# polygons, the ground-truth irrigated-agriculture layer the project has been missing. One
# survey per region every ~3-4 years; we take each region's LATEST polygon year and combine
# into a national orchard footprint. Used two ways:
#   1. A definitive irrigated mask for the land-cover-stratified transmission slope (replaces
#      the MapBiomas class-18 proxy, which is rain-fed-contaminated — see the 2026-06-26
#      progress summary).
#   2. The plantation-year (`AñO DE PL`) attribute reconstructs orchard-area EXPANSION — the
#      H2 induced-demand mediator (a future use; kept on the per-polygon layer, not the dissolve).
#
# Polygons are MULTIPOLYGON in EPSG:32719 (UTM 19S) across all regions; reprojected to EPSG:4326
# to match the watershed/raster stack.

#' Latest-year orchard polygon shapefile per region under the Catastro root.
#' @param root Catastro_fruticola directory (one subdir per region, each with poligonos_<year>/)
#' @return data.table(region, year, shp) — the most recent poligonos shapefile for each region
orchard_latest_shapefiles <- function(root) {
  regs <- list.dirs(root, recursive = FALSE)
  rows <- lapply(regs, function(rd) {
    pdirs <- list.files(rd, "^poligonos_", full.names = TRUE)
    if (!length(pdirs)) return(NULL)
    last <- sort(pdirs)[length(pdirs)]
    shp  <- list.files(last, "\\.shp$", full.names = TRUE)[1]
    if (is.na(shp)) return(NULL)
    data.table::data.table(region = basename(rd),
                           year = as.integer(sub(".*poligonos_", "", last)), shp = shp)
  })
  data.table::rbindlist(rows)
}

#' Read + combine each region's latest-year orchards into one national per-polygon layer.
#'
#' Keeps a minimal, schema-stable attribute set: region, survey year, crop species, plantation
#' year (column name varies: "AñO DE PL" / "AñO PLANT"), and reported area (ha). Geometries are
#' made valid and reprojected to `crs`. This is the per-polygon layer (attributes preserved);
#' dissolve_orchards() collapses it to the irrigated-area footprint.
#'
#' Kept in native UTM 19S (EPSG:32719) so st_make_valid / st_union run on planar GEOS — the
#' geographic (s2) path fails on the cadastre's degenerate edges, and areas are correct in
#' metres. Reproject to 4326 downstream (after dissolving) to meet the raster stack.
#'
#' @param root Catastro root; @param crs working EPSG (default 32719, the native UTM)
#' @return sf (MULTIPOLYGON) with columns region, survey_year, especie, plant_year, sup_ha
read_orchards_latest <- function(root, crs = 32719) {
  idx <- orchard_latest_shapefiles(root)
  pick <- function(df, cands) { h <- intersect(cands, names(df)); if (length(h)) df[[h[1]]] else NA }
  parts <- lapply(seq_len(nrow(idx)), function(i) {
    g <- sf::st_read(idx$shp[i], quiet = TRUE)
    a <- sf::st_drop_geometry(g)
    out <- sf::st_sf(
      region      = idx$region[i],
      survey_year = idx$year[i],
      especie     = as.character(pick(a, c("ESPECIE", "especie"))),
      plant_year  = suppressWarnings(as.integer(pick(a, c("AñO.DE.PL", "AñO.PLANT",
                                                          "AÑO.DE.PL", "ANO.DE.PL")))),
      sup_ha      = suppressWarnings(as.numeric(pick(a, c("SUPERFICIE", "Superficie")))),
      geometry    = sf::st_geometry(g))
    out <- sf::st_make_valid(out)
    if (is.na(sf::st_crs(out))) sf::st_crs(out) <- 32719   # all regions are UTM 19S
    sf::st_transform(out, crs)
  })
  do.call(rbind, parts)
}

#' Dissolve the per-polygon orchard layer into the irrigated-area footprint.
#'
#' Unions per region first (cheaper than one global union over ~90k polygons), then combines.
#' Orchard polygons do not overlap, so the dissolved area should ≈ the raw polygon-area sum —
#' a built-in validation (returned as an attribute).
#'
#' @param orchards read_orchards_latest() output
#' @return sf with one feature per region (region, geometry) + attr "raw_area_ha" / "diss_area_ha"
dissolve_orchards <- function(orchards) {
  regs <- unique(orchards$region)
  diss <- lapply(regs, function(r) {
    u <- sf::st_union(sf::st_geometry(orchards[orchards$region == r, ]))
    sf::st_sf(region = r, geometry = u)
  })
  out <- do.call(rbind, diss)
  raw  <- sum(orchards$sup_ha, na.rm = TRUE)
  dge  <- as.numeric(sum(sf::st_area(out))) / 1e4        # m^2 -> ha
  attr(out, "raw_area_ha")  <- raw
  attr(out, "diss_area_ha") <- dge
  out
}
