# Forcing-interacted DiD / event-study for the (near-time-invariant) reservoir treatment.
#
# DESIGN (reservoir-causal-analyst, 2026-06; see agent-memory forcing_interacted_did_design.md):
# A staggered-adoption event study on commissioning is INFEASIBLE here — 18/24 dams predate the
# panel, only 1-3 commission in-window. Treatment is effectively time-invariant. A naive
# treated x post(>=2010) TWFE would identify off CALENDAR time, which is collinear with the 2010+
# megadrought and reservoir siting (arid central Chile) — the forbidden spec.
#
# Instead the DOSE is SPEI (meteorological deficit), not the calendar year:
#   feols(y ~ treat:spei_c + spei_c | unit + year, weights = ~w, cluster = ~unit)
# - year FE remove the common megadrought shock (exposure); identification is the DIFFERENTIAL
#   response to a given forcing level between matched dammed vs control basins.
# - the estimand is a deficit->impact SLOPE (treat:spei_c), which endogenous siting biases far less
#   than levels. This is the H1/H2 test: H1 buffering -> treated slope FLATTER (sign depends on
#   outcome); H2 vulnerability -> treated slope STEEPER on the impact direction.
# - unit FE absorb treat and the time-invariant matching covariates (a feature, not a loss).
# SPEI must be the meteorological SPEI-12 (precip/PET), NOT a streamflow SSI or storage series —
# those are post-treatment / bad controls.

#' Build a DiD-ready unit-year panel: outcome + centered SPEI dose + treat/weights/covariates.
#'
#' @param panel        a per-unit-year outcome panel (data.table with unit_id, year, <outcome_col>)
#' @param forcing      annual SPEI panel (unit_id, year, forcing) — use forcing_subcuencas_full
#' @param matched_set  fit_matched_set() output (carries treated, w, kg_group, aridity_mean)
#' @param outcome_col  column in `panel` to use as the outcome
#' @param log_outcome  log-transform the outcome (TRUE for ET; FALSE for area_frac)
#' @return data.table(unit_id, year, treat, w, kg_group, aridity_mean, spei, spei_c, y)
build_did_panel <- function(panel, forcing, matched_set, outcome_col, log_outcome = FALSE) {
  p  <- data.table::as.data.table(panel)[, .(unit_id, year, outcome = get(outcome_col))]
  f  <- data.table::as.data.table(forcing)[, .(unit_id, year, spei = forcing)]
  ms <- data.table::as.data.table(matched_set$data)[, .(unit_id, treat = treated, w,
                                                        kg_group, aridity_mean)]
  d <- merge(merge(p, f, by = c("unit_id", "year")), ms, by = "unit_id")
  d[, y := if (log_outcome) log(outcome) else outcome]
  d <- d[is.finite(y) & is.finite(spei)]
  d[, spei_c := spei - mean(spei)]                       # center so treat reads at mean forcing
  data.table::setorder(d, unit_id, year)
  d[]
}

#' PRIMARY: forcing-interacted DiD. `treat:spei_c` = differential deficit->impact slope.
#' @return fixest model (cluster-robust by unit)
fit_forcing_did <- function(did_panel) {
  fixest::feols(y ~ spei_c + treat:spei_c | unit_id + year,
                data = did_panel, weights = ~w, cluster = ~unit_id)
}

#' Extract the two-way slope-gap coefficient regardless of fixest's interaction naming
#' (fixest writes `treat:spei_c` as `spei_c:treat`); excludes the triple-diff term.
.slope_gap_coef <- function(model) {
  cf <- stats::coef(model); nm <- names(cf)
  hit <- nm[grepl("spei_c", nm) & grepl("treat", nm) & !grepl("irr_share", nm)]
  if (length(hit) != 1L) return(NA_real_)
  unname(cf[hit])
}

#' SECONDARY: dynamic event study around megadrought onset — a PARALLEL-TRENDS / divergence
#' diagnostic, NOT a clean causal estimate. Pre-`ref` leads ~0 => parallel trends; post-`ref` lags
#' describe divergence under the common drought (still exposure-confounded).
#' @return fixest model with i(year, treat, ref) coefficients
fit_event_study <- function(did_panel, ref_year = 2009L) {
  fixest::feols(y ~ i(year, treat, ref = ref_year) | unit_id + year,
                data = did_panel, weights = ~w, cluster = ~unit_id)
}

#' MECHANISM: triple-difference — does the slope gap widen with irrigation intensity?
#' `irr_share` is the unit-level mean cropland fraction (induced-demand intensity), centered.
#' @param did_panel build_did_panel() output
#' @param irr_share data.table(unit_id, irr_share) — e.g. unit-mean area_frac from irrig_area_panel
#' @return fixest model; treat:spei_c:irr_share_c is the mechanism coefficient
fit_triple_diff <- function(did_panel, irr_share) {
  d <- merge(data.table::copy(did_panel),
             data.table::as.data.table(irr_share)[, .(unit_id, irr_share)], by = "unit_id")
  d[, irr_share_c := irr_share - mean(irr_share)]
  fixest::feols(y ~ spei_c + treat:spei_c + spei_c:irr_share_c + treat:spei_c:irr_share_c |
                  unit_id + year, data = d, weights = ~w, cluster = ~unit_id)
}

#' Randomization-inference p-value for the slope-gap coefficient (small treated-cluster count).
#'
#' fwildclusterboot is no longer on CRAN, so we use the design's design-based backup: permute the
#' TREATMENT LABEL among units WITHIN strata (kg_group x aridity tercile — the matching dimensions),
#' re-fit the forcing-DiD each time, and compare |observed treat:spei_c| to the permutation null.
#' This respects the ~24-treated-cluster reality (units, not unit-years, are the randomization unit)
#' and needs no external package. Two-sided p = (1 + #|perm| >= |obs|) / (1 + n_valid).
#'
#' @param did_panel build_did_panel() output (carries unit_id, treat, kg_group, aridity_mean, w)
#' @param observed_model fit_forcing_did() result on the same panel
#' @param n_perm number of permutations (default 999)
#' @return list(observed, p_perm, n_perm)
permutation_test_slope <- function(did_panel, observed_model, n_perm = 999L, seed = 1L) {
  obs <- .slope_gap_coef(observed_model)
  u <- unique(data.table::as.data.table(did_panel)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base <- did_panel[, !c("treat"), with = FALSE]
  set.seed(seed)
  perm <- vapply(seq_len(n_perm), function(b) {
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    dp <- merge(base, up[, .(unit_id, treat)], by = "unit_id")
    m <- tryCatch(fixest::feols(y ~ spei_c + treat:spei_c | unit_id + year,
                                data = dp, weights = ~w), error = function(e) NULL)
    if (is.null(m)) NA_real_ else .slope_gap_coef(m)
  }, numeric(1))
  nv <- sum(!is.na(perm))
  list(observed = obs, p_perm = (1 + sum(abs(perm) >= abs(obs), na.rm = TRUE)) / (1 + nv),
       n_perm = nv)
}

#' Aridity PLACEBO: among CONTROLS only, relabel the most-arid tercile as pseudo-treated and re-fit
#' the forcing-DiD. A non-null `treat:spei_c` here would mean the slope gap is an aridity artifact,
#' not a reservoir effect. Should be ~0.
#' @param did_panel build_did_panel() output (must carry aridity_mean)
fit_aridity_placebo <- function(did_panel) {
  d <- data.table::copy(did_panel)[treat == 0]
  thr <- stats::quantile(unique(d[, .(unit_id, aridity_mean)])$aridity_mean, 1/3, na.rm = TRUE)
  d[, treat := as.integer(aridity_mean <= thr)]          # low aridity index = most arid
  fixest::feols(y ~ spei_c + treat:spei_c | unit_id + year,
                data = d, weights = ~w, cluster = ~unit_id)
}

#' Tidy a forcing-DiD or placebo into a one-row summary of the treat:spei_c slope-gap coefficient.
did_slope_summary <- function(model, label, perm = NULL) {
  ct <- as.data.frame(summary(model)$coeftable)
  row <- ct[grepl("spei_c", rownames(ct)) & grepl("treat", rownames(ct)) &
              !grepl("irr_share", rownames(ct)), , drop = FALSE]
  out <- data.table::data.table(
    spec = label,
    att_slope = if (nrow(row)) row[[1]] else NA_real_,
    se        = if (nrow(row)) row[[2]] else NA_real_,
    t         = if (nrow(row)) row[[3]] else NA_real_,
    p_cluster = if (nrow(row)) row[[4]] else NA_real_,
    p_perm    = if (!is.null(perm)) perm$p_perm else NA_real_,
    n_obs = stats::nobs(model))
  out[]
}
