# Early/late megadrought phase split of the streamflow buffering test (Reviewer 3 round 7,
# comment 1). Concern: a single transmission slope over 2005-2024 could wash out early-phase
# buffering (storage still full at drought onset) with late-phase failure (storage depleted).
# Response: refit treat:spei_c separately on the early megadrought (2010-2014) and the late
# phase (2015-2024) for each subset (ITT, downstream-only, upstream placebo), and test the
# early-to-late change with a phase interaction on the pooled 2010-2024 panel. The decisive
# pattern for the siting interpretation: the UPSTREAM placebo attenuates as strongly as
# downstream already in the EARLY phase, when depletion cannot yet explain anything, and no
# subset shows an early-buffering-then-late-failure reversal.

.phase_fit <- function(p) {
  m <- fixest::feols(ssi ~ spei_c + treat:spei_c | unit_id + month_f + year,
                     data = p, weights = ~w, cluster = ~unit_id, nthreads = 1)
  ct <- as.data.frame(summary(m)$coeftable)
  r  <- ct[grepl("spei_c", rownames(ct)) & grepl("treat", rownames(ct)), , drop = FALSE]
  list(est = r[1, 1], se = r[1, 2], p = r[1, 4],
       n_treat = length(unique(p[treat == 1, unit_id])),
       n_ctrl  = length(unique(p[treat == 0, unit_id])))
}

#' Phase-split rows for one SSI panel subset. Early = 2010-2014, late = 2015-2024;
#' the phase-shift row is the treat:spei_c:late triple interaction on the pooled
#' megadrought panel (year FE absorb the phase main effect).
phase_split_rows <- function(panel, label,
                             early_years = 2010:2014, late_years = 2015:2024) {
  dt <- data.table::as.data.table(panel)
  e  <- .phase_fit(dt[year %in% early_years])
  l  <- .phase_fit(dt[year %in% late_years])

  pool <- dt[year %in% c(early_years, late_years)]
  pool[, late := as.integer(year %in% late_years)]
  mi  <- fixest::feols(ssi ~ spei_c + spei_c:late + treat:spei_c + treat:spei_c:late |
                         unit_id + month_f + year,
                       data = pool, weights = ~w, cluster = ~unit_id, nthreads = 1)
  cti <- as.data.frame(summary(mi)$coeftable)
  ri  <- cti[grepl("late", rownames(cti)) & grepl("treat", rownames(cti)), , drop = FALSE]

  yr_lab <- function(y) sprintf("%d-%d", min(y), max(y))
  data.table::data.table(
    quantity = c(
      sprintf("%s: treat x SPEI, early megadrought (%s)", label, yr_lab(early_years)),
      sprintf("%s: treat x SPEI, late megadrought (%s)",  label, yr_lab(late_years)),
      sprintf("%s: early-to-late phase shift (treat x SPEI x late)", label)),
    value = c(e$est, l$est, ri[1, 1]),
    detail = c(
      sprintf("SE %.4f, p = %.3f; %d treated / %d control units", e$se, e$p, e$n_treat, e$n_ctrl),
      sprintf("SE %.4f, p = %.3f; %d treated / %d control units", l$se, l$p, l$n_treat, l$n_ctrl),
      sprintf("SE %.4f, p = %.3f; pooled 2010-2024 panel, year FE absorb the phase level",
              ri[1, 2], ri[1, 4])))
}

#' Assemble the full phase-split table across the three streamflow subsets.
build_phase_split_check <- function(ssi_panel_itt, ssi_panel_down, ssi_panel_up) {
  data.table::rbindlist(list(
    phase_split_rows(ssi_panel_itt,  "ITT"),
    phase_split_rows(ssi_panel_down, "downstream"),
    phase_split_rows(ssi_panel_up,   "upstream placebo")))
}

#' treat:spei_c:late interaction coefficient from a pooled-phase feols fit.
.phase_shift_coef <- function(model) {
  cti <- as.data.frame(summary(model)$coeftable)
  ri  <- cti[grepl("late", rownames(cti)) & grepl("treat", rownames(cti)), , drop = FALSE]
  if (nrow(ri) != 1L) return(NA_real_); unname(ri[1, 1])
}

#' MC3 (reviewer 2026-08-05): permutation inference for the early-to-late phase shift
#' (treat:spei_c:late) of the streamflow buffering model, per gauge-class subset. The original
#' phase_split_check used cluster-robust p-values, which the design's own rule says over-reject at
#' ~21 clusters; this permutes treatment at the unit level within strata, the design's valid
#' inference. Also returns the CONTRAST of phase shifts (downstream shift - upstream shift): if the
#' apparent buffering were regulation, the downstream shift would be smaller than the upstream shift
#' (downstream retains more attenuation through depletion) -> contrast < 0; the null predicts contrast ~ 0.
#' @return list(subset, shift_obs, p_perm, contrast, contrast_p, n_perm)
permute_phase_shift <- function(panel_down, panel_up, n_perm = 2000L, seed = 1L,
                                early_years = 2010:2014, late_years = 2015:2024) {
  fit_shift <- function(dt) {
    # Restrict to the megadrought window exactly as build_phase_split_check does, so the
    # interaction estimates match the table's pooled-phase rows (which fit on 2010-2024).
    dt <- data.table::as.data.table(dt)[year %in% c(early_years, late_years)]
    dt[, late := as.integer(year %in% late_years)]
    m <- fixest::feols(ssi ~ spei_c + spei_c:late + treat:spei_c + treat:spei_c:late |
                         unit_id + month_f + year,
                       data = dt, weights = ~w, cluster = ~unit_id, nthreads = 1)
    .phase_shift_coef(m)
  }
  p_down <- fit_shift(panel_down)
  p_up   <- fit_shift(panel_up)
  contrast <- p_down - p_up

  u <- unique(data.table::as.data.table(panel_down)[, .(unit_id, treat, kg_group, aridity_mean)])
  qs <- stats::quantile(u$aridity_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  u[, stratum := paste(kg_group, cut(aridity_mean, unique(qs), include.lowest = TRUE))]
  base_down <- data.table::as.data.table(panel_down)[, !"treat", with = FALSE]
  base_up   <- data.table::as.data.table(panel_up)[,   !"treat", with = FALSE]

  one <- function(b) {
    set.seed(seed + b)
    up <- data.table::copy(u)[, treat := sample(treat), by = stratum]
    sd_ <- tryCatch(fit_shift(merge(base_down, up[, .(unit_id, treat)], by = "unit_id")),
                    error = function(e) NA_real_)
    su_ <- tryCatch(fit_shift(merge(base_up,   up[, .(unit_id, treat)], by = "unit_id")),
                    error = function(e) NA_real_)
    c(shift_down = sd_, shift_up = su_, contrast = sd_ - su_)
  }
  ncore <- max(1L, parallel::detectCores() - 2L)
  perm <- do.call(rbind, parallel::mclapply(seq_len(n_perm), one, mc.cores = ncore))
  perm <- perm[stats::complete.cases(perm), , drop = FALSE]
  nv <- nrow(perm)
  pp <- function(obs, x) (1 + sum(abs(x) >= abs(obs), na.rm = TRUE)) / (1 + nv)
  list(down_shift = p_down, up_shift = p_up, contrast = contrast,
       down_p = pp(p_down, perm[, "shift_down"]), up_p = pp(p_up, perm[, "shift_up"]),
       contrast_p = pp(contrast, perm[, "contrast"]), n_perm = nv)
}

#' Assemble MC3 rows: permutation p for each subset's phase shift plus the down-minus-up contrast.
build_phase_shift_permutation <- function(ssi_panel_itt, ssi_panel_down, ssi_panel_up,
                                          n_perm = 2000L, seed = 1L) {
  ps <- permute_phase_shift(ssi_panel_down, ssi_panel_up, n_perm = n_perm, seed = seed)
  data.table::data.table(
    quantity = c(
      "downstream: early-to-late phase shift (treat x SPEI x late), permutation p",
      "upstream placebo: early-to-late phase shift (treat x SPEI x late), permutation p",
      "phase-shift contrast (downstream shift - upstream placebo shift)"),
    value = c(ps$down_shift, ps$up_shift, ps$contrast),
    detail = c(
      sprintf("est %+.3f, permutation p = %.3f (%d perms)", ps$down_shift, ps$down_p, ps$n_perm),
      sprintf("est %+.3f, permutation p = %.3f (%d perms)", ps$up_shift, ps$up_p, ps$n_perm),
      sprintf("est %+.3f, permutation p = %.3f (%d perms); a regulation effect would give contrast < 0",
              ps$contrast, ps$contrast_p, ps$n_perm)))
}
