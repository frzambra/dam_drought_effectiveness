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
