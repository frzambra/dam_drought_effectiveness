# Build a tidy catalog of every index raster on disk: one row per (role, product,
# timescale, date, path). Downstream extraction iterates over this, so the messy,
# product-specific filename conventions are confined to this file.

#' List GeoTIFFs in a directory and parse their date token.
#' We never glob the filename prefix (the forcing files literally contain the
#' bracket string "chir[p|t]s", a glob hazard) — we list all .tif and extract the date.
#' @param dir directory to scan
#' @param date_regex regex capturing the date token in the file name
#' @param date_fmt strptime format for that token
list_rasters <- function(dir, date_regex, date_fmt) {
  if (!dir.exists(dir)) {
    warning("Raster dir not found, skipping: ", dir); return(NULL)
  }
  files <- list.files(dir, pattern = "\\.tif$", full.names = TRUE)
  if (!length(files)) return(NULL)
  tok <- regmatches(basename(files), regexpr(date_regex, basename(files)))
  ok  <- nzchar(tok)
  data.table::data.table(
    date = as.Date(tok[ok], format = date_fmt),
    path = files[ok]
  )
}

#' Assemble the full raster catalog from config.
#' @param sources data_sources.yml (list)
#' @param variables variables.yml (list)
#' @return data.table(role, product, timescale, date, path) sorted by product, timescale, date
build_raster_catalog <- function(sources, variables) {
  pieces <- list()

  # --- FORCING: <root>/<INDEX>/<INDEX>-<scale>/  ----------------------------------
  froot <- sources$drought_indices$root
  for (idx in variables$forcing$indices) {
    for (sc in idx$timescales) {
      dir <- file.path(froot, idx$name, sprintf("%s-%d", idx$name, sc))
      r <- list_rasters(dir, "\\d{4}-\\d{2}-\\d{2}", "%Y-%m-%d")
      if (!is.null(r)) {
        r[, `:=`(role = "forcing", product = idx$name, timescale = sc)]
        pieces[[length(pieces) + 1L]] <- r
      }
    }
  }

  # --- OUTCOME: MODIS ecological indices ------------------------------------------
  eroot <- sources$ecological_indices$root
  for (p in variables$outcome$products) {
    if (p$cadence == "annual") {
      # zNPP: <root>/zNPP/ , no timescale, date token uses dots (YYYY.01.01)
      dir <- file.path(eroot, p$name)
      r <- list_rasters(dir, "\\d{4}\\.\\d{2}\\.\\d{2}", "%Y.%m.%d")
      if (!is.null(r)) {
        r[, `:=`(role = "outcome", product = p$name, timescale = NA_integer_)]
        pieces[[length(pieces) + 1L]] <- r
      }
    } else {
      # SETI / zcNDVI: <root>/<P>/<P>-<scale>/ , monthly, YYYY-MM-01
      for (sc in p$timescales) {
        dir <- file.path(eroot, p$name, sprintf("%s-%d", p$name, sc))
        r <- list_rasters(dir, "\\d{4}-\\d{2}-\\d{2}", "%Y-%m-%d")
        if (!is.null(r)) {
          r[, `:=`(role = "outcome", product = p$name, timescale = sc)]
          pieces[[length(pieces) + 1L]] <- r
        }
      }
    }
  }

  if (!length(pieces)) stop("No rasters found — check data_sources.yml roots and the external drive.")
  cat <- data.table::rbindlist(pieces, use.names = TRUE)
  cat <- cat[!is.na(date)]
  data.table::setorder(cat, role, product, timescale, date)
  cat[, .(role, product, timescale, date, path)]
}
