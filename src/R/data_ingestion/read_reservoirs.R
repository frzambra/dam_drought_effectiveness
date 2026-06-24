# Ingest the reservoir storage table and the dam-point shapefile.

#' Read the wide reservoir levels CSV and return a tidy long table.
#'
#' The file is comma-delimited UTF-8, one row per reservoir, with id columns
#' (embsalse, ID_DGA, ID_IDE, max_level_hm3) followed by one storage column per month.
#' A run of empty trailing (padding) columns is dropped.
#'
#' @param path path to reservoirs_levels_*.csv
#' @return data.table(embsalse, ID_DGA, ID_IDE, max_level_hm3, date, level)
read_reservoir_levels <- function(path) {
  dt <- data.table::fread(path, na.strings = c("", "NA"))

  id_cols <- c("embsalse", "ID_DGA", "ID_IDE", "max_level_hm3")
  miss <- setdiff(id_cols, names(dt))
  if (length(miss)) stop("Missing expected id columns: ", paste(miss, collapse = ", "))

  # Melt ONLY true date columns (YYYY-MM-DD). This excludes the run of empty trailing
  # padding columns that fread auto-names (V258, ...) and any other stray fields.
  date_cols <- grep("^\\d{4}-\\d{2}-\\d{2}$", names(dt), value = TRUE)
  if (!length(date_cols)) stop("No YYYY-MM-DD storage columns found in ", path)

  long <- data.table::melt(
    dt, id.vars = id_cols, measure.vars = date_cols,
    variable.name = "date", value.name = "level"
  )
  long[, date  := as.Date(as.character(date))]
  long[, level := as.numeric(level)]
  long <- long[!is.na(date)]                       # belt-and-suspenders
  long[, max_level_hm3 := as.numeric(max_level_hm3)]
  data.table::setorder(long, embsalse, date)
  long[]
}

#' Read the national dam-point shapefile, filter to the monitored reservoirs, reproject.
#'
#' The shapefile is POINTS (national registry, ~1370 features), joined to the levels
#' table by CODEMBAL == ID_DGA. We keep the attributes the causal design needs.
#'
#' @param shp_path  path to Embalse_*.shp
#' @param keep_ids  character vector of ID_DGA codes to retain (from the levels table)
#' @param target_crs CRS to reproject to (match the rasters); default EPSG:4326
#' @return sf points with columns: ID_DGA, anocontr, use, size_class, region, geometry
read_reservoir_points <- function(shp_path, keep_ids, target_crs = "EPSG:4326") {
  pts <- sf::st_read(shp_path, quiet = TRUE)
  pts <- pts[pts$CODEMBAL %in% keep_ids, ]
  if (nrow(pts) == 0) stop("No shapefile points matched the supplied ID_DGA codes.")

  out <- sf::st_transform(pts, target_crs)
  out <- out[, c("CODEMBAL", "NOMBRE", "ANOCONTR", "USO_EMBAL", "TAMANO", "NOMREG")]
  names(out)[names(out) != attr(out, "sf_column")] <-
    c("ID_DGA", "name_shp", "anocontr", "use", "size_class", "region")
  out$anocontr[out$anocontr == 0] <- NA_integer_   # 0 = unknown construction year
  out
}
