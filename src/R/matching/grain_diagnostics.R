# Grain selection: compare cuenca vs subcuenca as the analysis unit for the matched
# dammed-vs-undammed design. The decision turns on (1) the CLEAN control pool after
# removing units contaminated by the regulated river system, (2) common support on
# climate, and (3) size comparability. Treated/control counts alone are misleading.

#' Per-unit treatment + clean-control flags for one grain.
#'
#' A subcuenca is CONTAMINATED if it is untreated but sits inside a cuenca that contains
#' a reservoir: it shares the regulated main stem (downstream) or the same closure, so it
#' is not a clean counterfactual. We cannot yet split upstream/downstream (no flow
#' topology), so we conservatively drop the whole treated cuenca. At cuenca grain there is
#' no nesting, so every untreated cuenca is a candidate control (adjacency spillover is a
#' separate, qualitative caveat).
#'
#' @param units      dissolved sf for the grain (unit_id, parent_id, geometry)
#' @param treated_ids unit_ids that contain >=1 reservoir, this grain
#' @param treated_parents cuenca codes containing >=1 reservoir (NULL at cuenca grain)
#' @param climate    extract_unit_climate() output for this grain
#' @return data.table(unit_id, parent_id, area_km2, kg_modal, kg_code, status)
flag_units <- function(units, treated_ids, treated_parents, climate) {
  dt <- data.table::data.table(
    unit_id   = units$unit_id,
    parent_id = units$parent_id,
    area_km2  = as.numeric(sf::st_area(units)) / 1e6
  )
  dt <- merge(dt, climate[, .(unit_id, kg_modal, kg_code)], by = "unit_id", all.x = TRUE)

  dt[, status := "control_clean"]
  if (!is.null(treated_parents))
    dt[parent_id %in% treated_parents, status := "control_contaminated"]
  dt[unit_id %in% treated_ids, status := "treated"]
  dt[]
}

#' Compare both grains and emit the decision diagnostics.
#'
#' @param reservoir_units assign_reservoirs_both_levels() output (level, unit_id, parent_id)
#' @param cuencas,subcuencas dissolved sf layers
#' @param clim_cuencas,clim_subcuencas extract_unit_climate() per grain
#' @return list(summary, common_support, flags) — summary is the headline table
compare_grains <- function(reservoir_units, cuencas, subcuencas,
                           clim_cuencas, clim_subcuencas) {
  ru <- data.table::as.data.table(reservoir_units)
  treated_cuencas <- unique(ru[level == "cuencas",   unit_id])
  treated_subc    <- unique(ru[level == "subcuencas", unit_id])

  fc <- flag_units(cuencas,    treated_cuencas, NULL,            clim_cuencas)
  fs <- flag_units(subcuencas, treated_subc,    treated_cuencas, clim_subcuencas)

  # --- common support: does each treated unit's climate have >=1 clean control? --------
  cs_one <- function(flags, grain) {
    tr  <- flags[status == "treated"]
    ctl <- flags[status == "control_clean"]
    ctl_classes <- unique(ctl$kg_modal)
    tr[, has_clean_climate_control := kg_modal %in% ctl_classes]
    list(
      detail = tr[, .(grain = grain, unit_id, kg_modal, kg_code, has_clean_climate_control)],
      n_treated = nrow(tr),
      n_orphan  = sum(!tr$has_clean_climate_control),
      classes_treated = data.table::uniqueN(tr$kg_modal)
    )
  }
  cc <- cs_one(fc, "cuenca")
  cs <- cs_one(fs, "subcuenca")

  med <- function(flags, st) stats::median(flags[status == st, area_km2], na.rm = TRUE)

  summary <- data.table::rbindlist(list(
    data.table::data.table(
      grain = "cuenca", n_units = nrow(fc),
      n_treated = cc$n_treated,
      n_control_clean = sum(fc$status == "control_clean"),
      n_control_contaminated = sum(fc$status == "control_contaminated"),
      treated_climate_zones = cc$classes_treated,
      treated_orphans_no_climate_control = cc$n_orphan,
      med_area_treated_km2 = round(med(fc, "treated")),
      med_area_control_km2 = round(med(fc, "control_clean"))
    ),
    data.table::data.table(
      grain = "subcuenca", n_units = nrow(fs),
      n_treated = cs$n_treated,
      n_control_clean = sum(fs$status == "control_clean"),
      n_control_contaminated = sum(fs$status == "control_contaminated"),
      treated_climate_zones = cs$classes_treated,
      treated_orphans_no_climate_control = cs$n_orphan,
      med_area_treated_km2 = round(med(fs, "treated")),
      med_area_control_km2 = round(med(fs, "control_clean"))
    )
  ))

  list(
    summary = summary[],
    common_support = data.table::rbindlist(list(cc$detail, cs$detail)),
    flags = list(cuenca = fc, subcuenca = fs)
  )
}
