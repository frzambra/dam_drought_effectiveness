# Manuscript figures. Each builds ONE message and is saved via save_fig() in a tar_target.

#' FIGURE: streamflow buffering is SITING, not the reservoir. (a) SPEI->streamflow-drought (SSI)
#' transmission for dammed vs matched control (downstream gauges): dammed look slightly flatter — the
#' apparent buffering. (b) The differential slope treat:spei_c for ITT / downstream / UPSTREAM-PLACEBO:
#' all CIs cross zero (permutation-null) AND the upstream placebo (above-dam, unregulated) is as strong
#' as downstream — so the attenuation is basin siting/aridity, not regulation.
#' @param sf_summary streamflow_summary (subset, treat_spei_c, se, cluster_p, perm_p)
#' @param ssi_panel_down build_ssi_panel(..., "down") — for the slope panel
fig_streamflow <- function(sf_summary, ssi_panel_down) {
  pal <- nw_pal(); labs <- nw_labs(); cfg <- fig_cfg()

  d <- data.table::as.data.table(ssi_panel_down)
  d[, grp := data.table::fifelse(treat == 1L, "treated", "control")]
  brk <- stats::quantile(d$spei, seq(0, 1, 0.1), na.rm = TRUE)
  d[, sbin := cut(spei, unique(brk), include.lowest = TRUE)]
  binned <- d[, .(spei = stats::weighted.mean(spei, w), ssi = stats::weighted.mean(ssi, w)),
              by = .(grp, sbin)][!is.na(sbin)]
  pa <- ggplot2::ggplot(d, ggplot2::aes(spei, ssi, colour = grp)) +
    ggplot2::geom_smooth(ggplot2::aes(weight = w), method = "lm", se = TRUE, linewidth = 0.5) +
    ggplot2::geom_point(data = binned, size = 0.9) +
    ggplot2::scale_colour_manual(values = pal, labels = labs) +
    ggplot2::labs(tag = "a", x = "Meteorological drought  SPEI-12", y = "Streamflow drought  SSI-12") +
    theme_nw()

  s <- data.table::as.data.table(sf_summary)
  s[, `:=`(lo = treat_spei_c - 1.96 * se, hi = treat_spei_c + 1.96 * se)]
  s[, subset := factor(subset, levels = c("upstream placebo", "downstream", "ITT"))]
  s[, placebo := subset == "upstream placebo"]
  pb <- ggplot2::ggplot(s, ggplot2::aes(treat_spei_c, subset)) +
    ggplot2::geom_vline(xintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = lo, xmax = hi), height = 0.16,
                            colour = "grey30", linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(colour = placebo), size = 1.6) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("perm p = %.2f", perm_p)),
                       vjust = -1, size = cfg$font$geom_text_size, colour = "grey30") +
    ggplot2::scale_colour_manual(values = c(`FALSE` = pal[["treated"]], `TRUE` = cfg$palette$neutral),
                                 guide = "none") +
    ggplot2::labs(tag = "b", x = "Dammed × SPEI slope gap (treat:SPEI; <0 = buffering)", y = NULL) +
    theme_nw()

  patchwork::wrap_plots(pa, pb, ncol = 1, heights = c(1, 0.8)) +
    patchwork::plot_annotation(
      title = "Apparent streamflow buffering is siting, not the reservoir",
      subtitle = "Effect is permutation-null and as strong in UPSTREAM (unregulated) gauges",
      theme = theme_nw())
}

#' Extract i(year, treat) event-study coefficients (+95% CI) from a fixest model into a tidy table.
#' The reference year (dropped) is added back as a 0 with NA CI for plotting.
extract_event_study <- function(model, ref_year = 2009L) {
  ct <- as.data.frame(summary(model)$coeftable)
  yr <- as.integer(sub(".*year::([0-9]+).*", "\\1", rownames(ct)))
  d <- data.table::data.table(year = yr, coef = ct[[1]], se = ct[[2]])
  d <- d[!is.na(year)]
  d <- rbind(d, data.table::data.table(year = ref_year, coef = 0, se = NA_real_))
  d[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]
  data.table::setorder(d, year)
  d[]
}

#' Weighted treated-vs-control mean of a panel outcome by year (ebal weights).
#' (NB: did_panel carries a column literally named `outcome`, so reference the target column by
#' name via [[ ]] into a temp to avoid the data.table scoping collision.)
group_year_means <- function(did_panel, ycol = "y") {
  d <- data.table::copy(data.table::as.data.table(did_panel))
  d[, .yv := d[[ycol]]]
  d[, .(m = stats::weighted.mean(.yv, w, na.rm = TRUE)),
    by = .(group = data.table::fifelse(treat == 1L, "treated", "control"), year)][]
}

#' FIGURE: observed irrigated-area DiD — (a) treated vs control area-fraction trajectory (the ~10x
#' siting level gap, parallel evolution), (b) event-study coefficients (flat pre-trends, no
#' post-megadrought divergence). The clean dynamic null at the heart of the H2 result.
#' @param did_panel_area build_did_panel() output for area_frac
#' @param es_area        fit_event_study() model on the area panel
fig_area_did <- function(did_panel_area, es_area, ref_year = 2009L) {
  pal <- nw_pal(); labs <- nw_labs(); cfg <- fig_cfg()

  traj <- group_year_means(did_panel_area, "y")
  pa <- ggplot2::ggplot(traj, ggplot2::aes(year, 100 * m, colour = group)) +
    ggplot2::geom_vline(xintercept = 2010, linetype = "dashed", colour = cfg$palette$neutral,
                        linewidth = 0.3) +
    ggplot2::geom_line(linewidth = 0.5) + ggplot2::geom_point(size = 0.7) +
    ggplot2::scale_colour_manual(values = pal, labels = labs) +
    ggplot2::labs(tag = "a", x = NULL, y = "Cropland area (% of basin)") +
    theme_nw()

  es <- extract_event_study(es_area, ref_year)
  pb <- ggplot2::ggplot(es, ggplot2::aes(year, 100 * coef)) +
    ggplot2::geom_hline(yintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = 2010, linetype = "dashed", colour = cfg$palette$neutral,
                        linewidth = 0.3) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = 100 * ci_lo, ymax = 100 * ci_hi),
                         fill = pal[["treated"]], alpha = cfg$palette$ci_band_alpha) +
    ggplot2::geom_line(colour = pal[["treated"]], linewidth = 0.5) +
    ggplot2::geom_point(colour = pal[["treated"]], size = 0.7) +
    ggplot2::labs(tag = "b", x = NULL,
                  y = "Dammed × year on cropland area\n(pp, ref. 2009)") +
    theme_nw()

  patchwork::wrap_plots(pa, pb, ncol = 1) +
    patchwork::plot_annotation(
      title = "Reservoirs do not alter irrigated-area dynamics",
      theme = theme_nw())
}

#' FIGURE: the binding constraint is INFLOW, not storage. (a) Cross-reservoir annual storage band —
#' peak and trough percent-of-capacity (mean line, IQR ribbon) — drifts DOWN over 2005-2024 with
#' roughly parallel trend lines: the whole band shifts while the seasonal amplitude stays flat.
#' (b) Per-year trend slope of peak / trough / amplitude (reservoir FE, clustered): peak and trough
#' both decline, amplitude ~ 0 — a supply-side level decline, not a refill/buffer degradation.
#' @param band_annual storage_band_annual() output (fraction-of-capacity)
#' @param band_trends fit_storage_band_trends() output
fig_storage_band <- function(band_annual, band_trends) {
  pal <- nw_pal(); cfg <- fig_cfg()
  b <- data.table::as.data.table(band_annual)
  by <- b[, .(peak_m   = mean(peak),
              peak_lo  = stats::quantile(peak, 0.25),  peak_hi  = stats::quantile(peak, 0.75),
              trough_m = mean(trough),
              trough_lo = stats::quantile(trough, 0.25), trough_hi = stats::quantile(trough, 0.75)),
          by = year]

  pa <- ggplot2::ggplot(by, ggplot2::aes(year)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = 100 * peak_lo,   ymax = 100 * peak_hi),
                         fill = pal[["treated"]], alpha = cfg$palette$ci_band_alpha) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = 100 * trough_lo, ymax = 100 * trough_hi),
                         fill = pal[["control"]], alpha = cfg$palette$ci_band_alpha) +
    ggplot2::geom_smooth(ggplot2::aes(y = 100 * peak_m),   method = "lm", se = FALSE,
                         colour = pal[["treated"]], linewidth = 0.5) +
    ggplot2::geom_smooth(ggplot2::aes(y = 100 * trough_m), method = "lm", se = FALSE,
                         colour = pal[["control"]], linewidth = 0.5) +
    ggplot2::geom_point(ggplot2::aes(y = 100 * peak_m),   colour = pal[["treated"]], size = 0.7) +
    ggplot2::geom_point(ggplot2::aes(y = 100 * trough_m), colour = pal[["control"]], size = 0.7) +
    ggplot2::annotate("text", x = max(by$year), y = 100 * by[year == max(year), peak_m],
                      label = "peak", hjust = 1, vjust = -0.7,
                      size = cfg$font$geom_text_size, colour = pal[["treated"]]) +
    ggplot2::annotate("text", x = max(by$year), y = 100 * by[year == max(year), trough_m],
                      label = "trough", hjust = 1, vjust = 1.4,
                      size = cfg$font$geom_text_size, colour = pal[["control"]]) +
    ggplot2::labs(tag = "a", x = NULL, y = "Storage (% of capacity)") +
    theme_nw()

  tr <- data.table::as.data.table(band_trends)
  tr[, component := factor(component, levels = c("amplitude", "trough", "peak"))]
  pb <- ggplot2::ggplot(tr, ggplot2::aes(100 * slope, component)) +
    ggplot2::geom_vline(xintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = 100 * ci_lo, xmax = 100 * ci_hi), height = 0.16,
                            colour = "grey30", linewidth = 0.4) +
    ggplot2::geom_point(colour = pal[["treated"]], size = 1.6) +
    ggplot2::labs(tag = "b", x = "Trend (% of capacity per year)", y = NULL) +
    theme_nw()

  patchwork::wrap_plots(pa, pb, ncol = 1, heights = c(1, 0.55)) +
    patchwork::plot_annotation(
      title = "The binding constraint is inflow, not storage",
      subtitle = "Whole storage band shifts down; seasonal amplitude unchanged (buffer intact)",
      theme = theme_nw())
}

#' FIGURE: convergent null — forest plot on a STANDARDIZED axis (estimate / SE, "standard errors
#' from the null") so heterogeneous estimands (ha km^-2, log-ET slope, DiD slope-gaps) are
#' comparable. The +-1.96 guides mark conventional significance; every estimate sits inside them.
#' @param results_table build_main_results_table() output (needs estimate, se, group, outcome)
fig_convergent_null <- function(results_table) {
  pal <- nw_pal(); cfg <- fig_cfg()
  d <- data.table::as.data.table(results_table)[is.finite(z)]
  d[, label := paste0(outcome, "  (", sub(" .*", "", group), ")")]
  d[, label := factor(label, levels = rev(label))]
  ggplot2::ggplot(d, ggplot2::aes(z, label)) +
    ggplot2::geom_vline(xintercept = c(-1.96, 1.96), linetype = "dotted",
                        colour = cfg$palette$neutral, linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = z - 1.96, xmax = z + 1.96), height = 0.16,
                            colour = "grey25", linewidth = 0.4) +
    ggplot2::geom_point(colour = pal[["treated"]], size = 1.4) +
    ggplot2::labs(x = "Standardized effect (estimate / SE)", y = NULL,
                  title = "No reservoir-driven vulnerability",
                  subtitle = "H2 predicts > 0; all CIs span zero (dotted = ±1.96)") +
    theme_nw() +
    ggplot2::theme(legend.position = "none", plot.title = ggplot2::element_text(hjust = 0),
                   plot.subtitle = ggplot2::element_text(hjust = 0))
}
