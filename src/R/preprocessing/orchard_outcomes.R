# DEFINITIVE irrigated stratum for the forcing-conditioned transmission slope, from the Catastro
# Frutícola orchard footprint (ground-truth irrigated land) — the upgrade over the MapBiomas
# class-18 proxy used in landcover_cover.R. Same idea (split per-subcuenca annual zNPP by cover,
# fit the deficit→impact slope within the stratum), but the irrigated mask is now the actual
# orchard polygons instead of a classified land-cover class.
#
# Grain caveat (unavoidable): zNPP is ~1 km and orchards are fragmented (~2% of basin area), so
# few cells are majority-orchard. We threshold on a modest orchard cover FRACTION (default 0.05)
# — a cell with non-trivial orchard presence — exactly as the class-18 test used thr=0.1. The
# orchard data's grain-independent strength is the EXPANSION mediator (plant_year), not this
# 1 km slope; here it simply makes the irrigated mask definitive rather than classified.

#' Per-cell orchard cover fraction on the zNPP grid.
#'
#' terra::rasterize(cover=TRUE) returns, for every zNPP cell, the fraction of its area covered
#' by the (dissolved) orchard polygons. Cheap on the ~1 km grid; computed once and reused.
#'
#' @param orchards_dissolved sf orchard footprint (any CRS; reprojected to the grid)
#' @param znpp_stack list(paths, years) — first layer is the target grid
#' @return SpatRaster of orchard cover fraction (0–1), aligned to the zNPP grid
orchard_fraction_raster <- function(orchards_dissolved, znpp_stack) {
  tmpl <- terra::rast(znpp_stack$paths[1])
  v <- terra::vect(orchards_dissolved)
  if (!terra::same.crs(v, tmpl)) v <- terra::project(v, tmpl)
  terra::rasterize(v, tmpl, cover = TRUE)
}

#' Per-unit annual zNPP over orchard (irrigated) cells.
#'
#' Masks the zNPP stack to cells whose orchard cover fraction ≥ `frac_thr` (done once, globally),
#' then takes the per-unit per-year mean over those cells. Units with fewer than `min_cells`
#' orchard cells are dropped (ill-determined stratum mean).
#'
#' @param units      sf polygons with `unit_id`
#' @param znpp_stack list(paths, years) from ecological_annual_paths("zNPP")
#' @param orchfrac   orchard_fraction_raster() output
#' @param frac_thr   minimum orchard cover fraction for a cell to count (default 0.05)
#' @param min_cells  minimum orchard cells to report a unit (default 3)
#' @return data.table(unit_id, year, level, stratum = "irrigated", n_cells)
extract_unit_orchard_znpp <- function(units, znpp_stack, orchfrac,
                                      frac_thr = 0.05, min_cells = 3L) {
  zn  <- terra::rast(znpp_stack$paths)
  yrs <- znpp_stack$years
  m   <- orchfrac >= frac_thr                       # boolean orchard mask on the zNPP grid
  zno <- terra::mask(zn, m, maskvalues = c(NA, FALSE))

  v <- terra::vect(units)
  if (!terra::same.crs(v, zn)) v <- terra::project(v, zn)

  ex <- data.table::as.data.table(
    terra::extract(zno, v, fun = mean, na.rm = TRUE, ID = TRUE))
  data.table::setnames(ex, c("ID", paste0("y", yrs)))
  nc <- data.table::as.data.table(
    terra::extract(m, v, fun = function(x) sum(x > 0, na.rm = TRUE), ID = TRUE))
  data.table::setnames(nc, c("ID", "n_cells"))

  ex[, unit_id := units$unit_id[ID]]
  ex <- merge(ex, nc, by = "ID")
  ex <- ex[n_cells >= min_cells]

  long <- data.table::melt(ex, id.vars = c("ID", "unit_id", "n_cells"),
                           variable.name = "yvar", value.name = "level")
  long[, year := as.integer(sub("^y", "", yvar))]
  long <- long[!is.na(level), .(unit_id, year, level, stratum = "irrigated", n_cells)]
  data.table::setorder(long, unit_id, year)
  long[]
}

#' Combine the orchard (irrigated) stratum with the natural stratum for the cover contrast.
#' @param orchard_znpp extract_unit_orchard_znpp() output
#' @param strat_znpp   stratified_znpp_annual() output (its "natural" rows are used)
#' @return data.table(unit_id, year, level, stratum, n_cells) with strata {irrigated, natural}
combine_orchard_natural <- function(orchard_znpp, strat_znpp) {
  nat <- data.table::as.data.table(strat_znpp)[stratum == "natural"]
  data.table::rbindlist(list(orchard_znpp, nat), use.names = TRUE, fill = TRUE)[]
}
