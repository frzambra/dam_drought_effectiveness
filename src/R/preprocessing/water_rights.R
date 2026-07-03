# DGA consolidated water-rights registry (Derechos de Aprovechamiento de Aguas) -> a per-subcuenca
# annual water-ALLOCATION panel. This is the direct demand-side outcome for the induced-demand test
# (does damming accrue more consumptive water rights than in matched controls?), complementing the
# irrigated-area (MapBiomas) and ET proxies. The registry gives, per right: grant date, consumptive
# vs non-consumptive type, surface vs groundwater nature, use, allocated flow (+ unit), and a UTM
# capture point. We harmonize flows to l/s, assign points to subcuencas (point-in-polygon), and build
# a cumulative-stock + annual-increment allocation panel by category.

#' Parse a Chilean-locale numeric string (dot = thousands, comma = decimal).
.num_cl <- function(x) suppressWarnings(as.numeric(gsub(",", ".", gsub("\\.", "", x))))

#' Harmonize an allocated-flow unit to litres per second. Shares/traditional units (Acciones,
#' Regadores) are NOT convertible to a physical flow and return NA (flagged, excluded from volumes).
.unit_to_ls <- function(unit) {
  u <- tolower(trimws(unit))
  yr <- 365.25 * 86400; mo <- 30.4375 * 86400
  data.table::fcase(
    grepl("^lt?/s",  u), 1,
    grepl("^m3/s",   u), 1000,
    grepl("^lt?/min", u), 1 / 60,
    grepl("^mm3/a",  u), 1e6 * 1000 / yr,     # million m3/yr
    grepl("^m3/a",   u), 1000 / yr,           # m3/yr  (año/ano)
    grepl("^m3/mes", u), 1000 / mo,
    grepl("^m3/d",   u), 1000 / 86400,        # m3/day (día/dia)
    default = NA_real_)
}

#' Read + clean the water-rights CSV: select the fields we use, harmonize flow to l/s, parse the
#' grant year, and normalize type / nature / use flags. Returns one row per right (no geometry yet).
#' @param path water_rights_chile.csv (semicolon-delimited, UTF-8, multi-line quoted header)
#' @return data.table(region, cuenca, subcuenca, tipo, naturaleza, uso, year, caudal, unidad,
#'                     flow_ls, consumptive, source_type, irrigation, utmn, utme, huso, datum)
read_water_rights <- function(path) {
  # Column indices in the 68-column DGA export (verified against the header).
  sel <- c(region = 4L, fecha = 9L, tipo = 13L, naturaleza = 14L, uso = 16L,
           cuenca = 17L, subcuenca = 18L, caudal = 34L, unidad = 35L,
           utmn = 42L, utme = 43L, huso = 44L, datum = 45L)
  d <- data.table::fread(path, sep = ";", encoding = "UTF-8", select = unname(sel),
                         colClasses = "character", showProgress = FALSE)
  data.table::setnames(d, names(sel))

  d[, year   := suppressWarnings(as.integer(sub(".*((19|20)[0-9]{2}).*", "\\1", fecha)))]
  d[, caudal_v := .num_cl(caudal)]
  d[, flow_ls := caudal_v * .unit_to_ls(unidad)]
  tl <- tolower(d$tipo); nl <- tolower(d$naturaleza); ul <- tolower(d$uso)
  d[, consumptive := grepl("consun", tl) & !grepl("no consun", tl)]
  d[, source_type := data.table::fifelse(grepl("subterr", nl), "groundwater", "surface")]
  d[, irrigation  := grepl("riego", ul)]
  d[, `:=`(utmn = .num_cl(utmn), utme = .num_cl(utme),
           huso = suppressWarnings(as.integer(huso)),
           datum = suppressWarnings(as.integer(datum)))]
  d[, .(region, cuenca, subcuenca, tipo, naturaleza, uso, year,
        caudal = caudal_v, unidad, flow_ls, consumptive, source_type, irrigation,
        utmn, utme, huso, datum)]
}

#' Assign each right to a subcuenca by point-in-polygon on its UTM capture coordinate, reprojecting
#' per (Huso, Datum) group to WGS84 first. Datum codes: 1984 = WGS84, 1956 = PSAD56, 1969 = SAD69
#' (unknown/missing datum defaults to WGS84; the datum offset is << subcuenca grain). Rows without a
#' usable coordinate (Huso not 18/19, or no UTM) are dropped.
#' @param rights read_water_rights() output
#' @param units  subcuencas_dissolved sf (unit_id geometry)
#' @return rights data.table with an added `unit_id` (assigned rows only)
assign_water_rights_to_units <- function(rights, units) {
  r <- data.table::as.data.table(rights)[is.finite(utmn) & is.finite(utme) & utmn > 1e6 &
                                         huso %in% c(18L, 19L)]
  # EPSG per (huso, datum), defaulting unknown datum to WGS84.
  epsg_tab <- data.table::data.table(
    hk    = c("18_1984","19_1984","18_1956","19_1956","18_1969","19_1969"),
    epsg  = c(32718L, 32719L, 24878L, 24879L, 29188L, 29189L))
  r[, datum2 := data.table::fifelse(datum %in% c(1984L,1956L,1969L), datum, 1984L)]
  r[, hk := paste(huso, datum2, sep = "_")]
  r <- merge(r, epsg_tab, by = "hk", all.x = TRUE)
  r[is.na(epsg), epsg := data.table::fifelse(huso == 18L, 32718L, 32719L)]

  u <- sf::st_transform(sf::st_as_sf(units), 4326)["unit_id"]
  r[, rid := .I]
  assigned <- data.table::rbindlist(lapply(split(r, r$epsg), function(g) {
    pts <- sf::st_as_sf(g, coords = c("utme", "utmn"), crs = g$epsg[1], remove = TRUE)
    pts <- suppressWarnings(sf::st_transform(pts, 4326))
    j   <- sf::st_join(pts, u, join = sf::st_within, left = TRUE)
    data.table::as.data.table(sf::st_drop_geometry(j))[, .(rid, unit_id)]
  }))
  out <- merge(r, assigned, by = "rid", all.x = TRUE)
  out[!is.na(unit_id)][, c("rid","hk","datum2","epsg") := NULL][]
}

#' Build the per-subcuenca annual water-allocation panel. Rights are perpetual under the 1981 Water
#' Code, so the state variable is the cumulative allocated CONSUMPTIVE stock present by each year,
#' with the annual grant (increment) for the event study, broken out by source (surface vs
#' groundwater) and by irrigation use. Pre-`min(years)` rights seed the opening stock.
#'
#' The DGA registry contains severe volume outliers (physically impossible caudal entries, e.g.
#' >200,000 m3/s; a single erroneous right can be ~90% of a basin's raw total), so the volume series
#' is WINSORIZED at the `winsor` quantile of individual consumptive flows. The primary, outlier-robust
#' demand measure is the cumulative COUNT of rights (`cum_n`), immune to caudal errors; winsorized
#' volume (`cum_lsw`) is the secondary measure. Raw uncapped `cum_ls` is retained for transparency.
#' @param rights assign_water_rights_to_units() output
#' @param years  reporting years (default 1990-2024)
#' @param winsor quantile at which individual consumptive flows are capped (default 0.995)
#' @return data.table(unit_id, year, new_*, cum_n, cum_lsw, cum_ls, cum_gw, cum_irr, cum_n_gw, cum_n_irr)
build_water_rights_panel <- function(rights, years = 1990:2024, winsor = 0.995) {
  r <- data.table::as.data.table(rights)[consumptive == TRUE & !is.na(unit_id) &
                                         !is.na(year) & is.finite(flow_ls) & flow_ls > 0]
  cap <- stats::quantile(r$flow_ls, winsor, names = FALSE)     # tame data-error volume outliers
  r[, flow_w := pmin(flow_ls, cap)]
  inc <- r[, .(new_ls   = sum(flow_ls),  new_lsw  = sum(flow_w),
               new_gw   = sum(flow_w[source_type == "groundwater"]),
               new_irr  = sum(flow_w[irrigation]),
               new_n    = .N,
               new_n_gw = sum(source_type == "groundwater"),
               new_n_irr = sum(irrigation)),
           by = .(unit_id, year)]
  ally  <- seq.int(min(inc$year), max(years))                 # include pre-window rights in the stock
  grid  <- data.table::CJ(unit_id = unique(inc$unit_id), year = ally)
  p     <- merge(grid, inc, by = c("unit_id", "year"), all.x = TRUE)
  cols  <- c("new_ls","new_lsw","new_gw","new_irr","new_n","new_n_gw","new_n_irr")
  for (cc in cols) p[!is.finite(get(cc)), (cc) := 0]
  data.table::setorder(p, unit_id, year)
  p[, `:=`(cum_ls  = cumsum(new_ls),  cum_lsw = cumsum(new_lsw),
           cum_gw  = cumsum(new_gw),  cum_irr = cumsum(new_irr),
           cum_n   = cumsum(new_n),   cum_n_gw = cumsum(new_n_gw),
           cum_n_irr = cumsum(new_n_irr)), by = unit_id]
  p[year %in% years][]
}

#' Physical validation of the winsorization cap (Reviewer 3 round 3, comment 5): are the retained
#' (capped) individual consumptive flows physically plausible? For every gauged basin, compare the
#' largest retained right against the basin's maximum observed monthly mean streamflow (a physical
#' ceiling on abstraction); report the cap itself in flow units. A right exceeding the river's
#' maximum observed flow would be physically impossible; the check shows how many survive the cap.
#' @return data.table(quantity, value, detail)
winsor_physical_check <- function(rights_assigned, streamflow_monthly, stations_units,
                                  winsor = 0.995) {
  r <- data.table::as.data.table(rights_assigned)[consumptive == TRUE & is.finite(flow_ls)]
  cap <- stats::quantile(r$flow_ls, winsor, names = FALSE)
  r[, fl := pmin(flow_ls, cap)]
  su <- unique(data.table::as.data.table(stations_units)[, .(codigo, unit_id)])
  q  <- merge(data.table::as.data.table(streamflow_monthly), su, by = "codigo")
  qmax <- q[, .(qmax_ls = 1000 * max(q_mon, na.rm = TRUE)), by = unit_id]  # m3/s -> l/s
  rb  <- r[, .(max_right_ls = max(fl)), by = unit_id]
  cmp <- merge(rb, qmax, by = "unit_id")
  ok  <- cmp$max_right_ls <= cmp$qmax_ls
  rat <- cmp$max_right_ls / cmp$qmax_ls
  data.table::data.table(
    quantity = c("winsorization cap (99.5th pct of consumptive flows)",
                 "gauged basins where the largest retained right <= max observed monthly flow",
                 "median ratio: largest retained right / max observed flow"),
    value  = c(round(cap), sum(ok), round(stats::median(rat), 3)),
    detail = c(sprintf("l/s (= %.1f m3/s); uncapped registry maximum %.3g l/s", cap / 1000,
                       max(r$flow_ls)),
               sprintf("of %d gauged basins (%.0f%%)", nrow(cmp), 100 * mean(ok)),
               sprintf("IQR [%.3f, %.3f]", stats::quantile(rat, .25, names = FALSE),
                       stats::quantile(rat, .75, names = FALSE)))
  )
}
