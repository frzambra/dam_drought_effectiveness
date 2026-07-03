# Build the matched / weighted control set for the subcuenca design (ATT).
#
# Estimand: ATT — the effect on the dammed subcuencas. With only ~24 treated units and
# 398 clean controls, ENTROPY BALANCING (WeightIt method="ebal") is preferred over 1:1
# matching: it uses every control, achieves exact balance on the covariate moments, and
# is stable at small treated n. Climate is matched EXACTLY by balancing within Köppen
# main-group (the `by` argument), so a B-treated unit is only ever balanced against B
# controls. log(area) and latitude are balanced within each group.
#
# Covariates are deliberately parsimonious and all robustly available: log basin area,
# centroid latitude (the dominant N-S aridity/temperature gradient in Chile), Köppen main
# group, mean elevation (SRTM), and long-term baseline aridity (annual P/PET). Aridity is
# carried as an untargeted balance DIAGNOSTIC first (like latitude): if Köppen group +
# elevation already balance it, there is no need to spend ESS targeting it — see
# docs/design/matched-controls.md.

#' Assemble subcuenca matching covariates (treated + clean controls only).
#' @param subcuencas dissolved sf (unit_id, geometry)
#' @param flags      compare_grains()$flags$subcuenca (status, area_km2, kg_modal, kg_code)
#' @param climate    extract_unit_climate() output (kg_modal_frac)
#' @param terrain    extract_unit_terrain() output (elev_mean, elev_sd); optional
#' @param aridity    extract_unit_aridity() output (aridity_mean, aridity_sd); optional
#' @return data.table(unit_id, treated, status, area_km2, log_area, lat, lon,
#'                    kg_code, kg_group, kg_modal_frac, elev_mean, elev_sd,
#'                    aridity_mean, log_aridity)
build_match_covariates <- function(subcuencas, flags, climate, terrain = NULL,
                                   aridity = NULL) {
  fl <- data.table::as.data.table(flags)[status %in% c("treated", "control_clean")]

  cen <- sf::st_coordinates(suppressWarnings(sf::st_centroid(sf::st_geometry(subcuencas))))
  cd  <- data.table::data.table(unit_id = subcuencas$unit_id, lon = cen[, 1], lat = cen[, 2])

  dt <- merge(fl[, .(unit_id, status, area_km2, kg_modal, kg_code)], cd, by = "unit_id")
  dt <- merge(dt, climate[, .(unit_id, kg_modal_frac)], by = "unit_id", all.x = TRUE)
  if (!is.null(terrain))
    dt <- merge(dt, terrain[, .(unit_id, elev_mean, elev_sd)], by = "unit_id", all.x = TRUE)
  if (!is.null(aridity))
    dt <- merge(dt, aridity[, .(unit_id, aridity_mean, aridity_sd)], by = "unit_id",
                all.x = TRUE)

  dt[, treated  := as.integer(status == "treated")]
  dt[, log_area := log(area_km2)]
  dt[, kg_group := substr(kg_code, 1L, 1L)]      # Köppen main group: A/B/C/D/E
  if ("aridity_mean" %in% names(dt))
    dt[, log_aridity := log(aridity_mean)]       # P/PET is right-skewed; balance on log
  data.table::setorder(dt, -treated, kg_group, unit_id)
  dt[]
}

#' Restrict the covariate table to the matched-design common support.
#'
#' Drops units with missing climate/area/elevation; keeps only Köppen groups containing
#' treated units (ATT); within each group restricts controls to the treated mean-elevation
#' window (± `elev_buffer_m`); drops groups with fewer than `min_controls` in-window
#' controls (their treated units are out of support). Shared by ALL matching estimators so
#' the entropy-balance primary and the CEM / NN robustness fits use an identical sample.
#'
#' @return list(cov = trimmed data.table, dropped = data.table(unit_id, kg_code, reason))
common_support_trim <- function(cov, min_controls = 10L, elev_buffer_m = 250) {
  cov <- data.table::copy(cov)[!is.na(kg_group) & !is.na(log_area) & !is.na(elev_mean)]
  dropped <- cov[0L, .(unit_id, kg_code, reason = character())]

  has_t <- cov[, .(n_t = sum(treated)), by = kg_group][n_t > 0, kg_group]
  cov <- cov[kg_group %in% has_t]

  win <- cov[treated == 1L, .(lo = min(elev_mean) - elev_buffer_m,
                              hi = max(elev_mean) + elev_buffer_m), by = kg_group]
  cov <- merge(cov, win, by = "kg_group", all.x = TRUE)
  cov <- cov[treated == 1L | (elev_mean >= lo & elev_mean <= hi)]   # trim far controls

  ok <- cov[treated == 0L, .(n_c = .N), by = kg_group][n_c >= min_controls, kg_group]
  dropped <- rbind(dropped, cov[treated == 1L & !(kg_group %in% ok),
                   .(unit_id, kg_code,
                     reason = "too few in-elevation-window controls in Köppen group")])
  cov <- cov[kg_group %in% ok][, c("lo", "hi") := NULL]
  list(cov = cov[], dropped = dropped[])
}

#' Trim to common support, then entropy-balance controls to treated within climate group.
#'
#' Balances `log(area)` + mean elevation EXACTLY within Köppen main group. Latitude is
#' deliberately NOT a balance target: within a Köppen group it is collinear with — and for
#' the ET group contradictory to — elevation (ET spans the high northern Andes and low
#' Patagonia), which broke the optimization. Köppen group + elevation capture the climate
#' and montane/lowland regime; residual latitude balance is reported as a diagnostic.
#'
#' @param cov build_match_covariates() output
#' @param min_controls,elev_buffer_m passed to common_support_trim()
#' @return list(data, weightit, balance, ess, dropped) — `data` carries column `w`
fit_matched_set <- function(cov, min_controls = 10L, elev_buffer_m = 250) {
  ts  <- common_support_trim(cov, min_controls, elev_buffer_m)
  cov <- ts$cov; dropped <- ts$dropped

  W <- WeightIt::weightit(
    treated ~ log_area + elev_mean,
    data = as.data.frame(cov),
    method = "ebal", estimand = "ATT",
    by = ~kg_group,                         # exact climate-group matching (within strata)
    maxit = 5000
  )
  cov[, w := W$weights]

  # Report balance on the targeted covariates PLUS untargeted diagnostics: latitude and
  # long-term baseline aridity (log P/PET). If aridity balances for free here, Köppen group
  # + elevation already capture it and we need not spend ESS targeting it.
  addl <- if ("log_aridity" %in% names(cov)) ~lat + log_aridity else ~lat
  bal <- cobalt::bal.tab(W, un = TRUE, addl = addl, data = as.data.frame(cov),
                         disp = c("means", "sds"),
                         stats = c("mean.diffs", "variance.ratios"))

  list(
    data     = cov[],
    weightit = W,
    balance  = bal,
    ess      = summary(W)$effective.sample.size,
    dropped  = dropped[]
  )
}

#' Hard-balanced sensitivity fit (Reviewer 3 round 3, comment 1): entropy balancing that ALSO
#' targets log baseline aridity (with log area + elevation, within Köppen group). This removes the
#' residual aridity imbalance entirely, so no outcome-model extrapolation across the regime gap is
#' needed, at the cost of collapsing the effective control sample (~19). Used only as a sensitivity;
#' the primary design deliberately leaves aridity to the doubly-robust outcome model (see above).
#' @return list(data, weightit, ess) — `data` carries column `w`
fit_matched_set_hard <- function(cov, min_controls = 10L, elev_buffer_m = 250) {
  ts  <- common_support_trim(cov, min_controls, elev_buffer_m)
  cov <- ts$cov
  W <- WeightIt::weightit(
    treated ~ log_area + elev_mean + log_aridity,
    data = as.data.frame(cov), method = "ebal", estimand = "ATT",
    by = ~kg_group, maxit = 10000)
  cov[, w := W$weights]
  list(data = cov[], weightit = W, ess = summary(W)$effective.sample.size)
}
