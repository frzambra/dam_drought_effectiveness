# Manuscript figures. Each builds ONE message and is saved via save_fig() in a tar_target.

#' Pick the treated unit best suited to illustrate the upstream/downstream gauge geometry:
#' one with BOTH up- and down-dam gauges, preferring the Mediterranean core (Köppen `prefer`,
#' the study's agricultural setting) and a balanced picture (max min(up, down)), tie-broken toward
#' a compact set (fewest total gauges) then unit_id for determinism.
#' @param kg optional data.table(unit_id, kg_group) to bias the choice toward a climate group
.pick_inset_unit <- function(stations, kg = NULL, prefer = "C") {
  cnt <- data.table::as.data.table(stations)[
    treat == 1L, .(up = sum(regulated == "up"), down = sum(regulated == "down"),
                   tot = .N), by = unit_id][up > 0 & down > 0]
  if (nrow(cnt) == 0L) return(NA_character_)
  cnt[, bal := pmin(up, down)]
  if (!is.null(kg)) {
    cnt <- merge(cnt, data.table::as.data.table(kg)[, .(unit_id, kg_group)], by = "unit_id",
                 all.x = TRUE)
    if (any(cnt$kg_group == prefer, na.rm = TRUE)) cnt <- cnt[kg_group == prefer]
  }
  data.table::setorder(cnt, -bal, tot, unit_id)
  cnt$unit_id[1L]
}

#' FIGURE (study area / design): the matched design is geographically and climatically credible.
#' (a) National map of the matched sample: every matched subcuenca filled by long-term aridity
#' (P/PET, the N-S gradient the design conditions on); dammed (treated) basins outlined and marked
#' with their reservoir; matched-control basins carry a centroid dot sized by entropy-balancing
#' weight, so the reader sees which controls actually carry the ATT (effective n << nominal).
#' (b) Inset of one dammed basin resolving the within-basin placebo geometry: the reservoir with
#' its downstream (regulated) gauges below the dam and upstream (unregulated) gauges above it.
#' @param matched_set   fit_matched_set() output ($data: unit_id, treated, w, aridity_mean, kg_group)
#' @param matched_subc  matched_subcuencas sf (unit_id geometry, 4326)
#' @param subc_context  subcuencas_dissolved sf (national context backdrop, 4326)
#' @param points        reservoir points sf (ID_DGA, 4326)
#' @param reservoir_units reservoir->unit table (ID_DGA, unit_id, level)
#' @param stations      streamflow_stations (codigo, unit_id, treat, regulated)
#' @param stations_raw  streamflow_stations_raw (codigo, latitud, longitud) for gauge coordinates
fig_study_area <- function(matched_set, matched_subc, subc_context, points, reservoir_units,
                           stations, stations_raw) {
  pal <- nw_pal(); cfg <- fig_cfg()

  # --- assemble the matched-sample polygons with treatment + weight + aridity ------------------
  md <- data.table::as.data.table(matched_set$data)[
    , .(unit_id, treated, w, aridity_mean, kg_group)]
  g  <- merge(matched_subc[, "unit_id"], md, by = "unit_id")
  g$grp <- ifelse(g$treated == 1L, "Dammed", "Matched control")
  trt   <- g[g$treated == 1L, ]
  ctl   <- g[g$treated == 0L, ]

  # control centroids sized by entropy-balancing weight (effective controls; w==0 are pruned)
  ctl_cent <- sf::st_centroid(sf::st_geometry(ctl))
  ctl_pts  <- sf::st_sf(w = ctl$w, geometry = ctl_cent)[ctl$w > 1e-6, ]

  # effective control sample size (Kish) for the annotation
  wc  <- ctl$w[is.finite(ctl$w)]
  ess <- round(sum(wc)^2 / sum(wc^2))

  # study-area window (focus on the matched sample, not all of Chile)
  bb  <- sf::st_bbox(matched_subc); padx <- 0.4; pady <- 0.6

  # --- inset unit + its dam / up / down gauges -------------------------------------------------
  iu <- .pick_inset_unit(stations, kg = md, prefer = "C")
  inset_ok <- !is.na(iu)
  if (inset_ok) {
    ib   <- matched_subc[matched_subc$unit_id == iu, ]
    iids <- data.table::as.data.table(reservoir_units)[level == "subcuencas" & unit_id == iu, ID_DGA]
    idam <- points[points$ID_DGA %in% iids, ]
    sc <- merge(data.table::as.data.table(stations)[unit_id == iu, .(codigo, regulated)],
                data.table::as.data.table(stations_raw)[, .(codigo, latitud, longitud)],
                by = "codigo")
    sc <- sc[is.finite(latitud) & is.finite(longitud)]
    gz <- sf::st_as_sf(sc, coords = c("longitud", "latitud"), crs = 4326, remove = FALSE)
    gz$Gauge <- ifelse(gz$regulated == "up", "Upstream (unregulated)", "Downstream (regulated)")
  }

  # --- panel a: national map ------------------------------------------------------------------
  gz_pal <- c(`Upstream (unregulated)` = pal[["control"]],
              `Downstream (regulated)` = pal[["treated"]])
  pa <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = subc_context, fill = "grey95", colour = "grey85", linewidth = 0.05) +
    ggplot2::geom_sf(data = ctl, ggplot2::aes(fill = aridity_mean), colour = "grey70",
                     linewidth = 0.06) +
    ggplot2::geom_sf(data = trt, ggplot2::aes(fill = aridity_mean),
                     colour = pal[["treated"]], linewidth = 0.35) +
    ggplot2::geom_sf(data = ctl_pts, ggplot2::aes(size = w), colour = "grey30",
                     alpha = 0.5, shape = 16) +
    ggplot2::geom_sf(data = points[points$ID_DGA %in%
                       data.table::as.data.table(reservoir_units)[
                         level == "subcuencas" & unit_id %in% trt$unit_id, ID_DGA], ],
                     shape = 24, fill = pal[["treated"]], colour = "white",
                     size = 1.3, stroke = 0.2) +
    ggplot2::scale_fill_viridis_c(option = "cividis", name = "Aridity (P/PET)",
                                  trans = "sqrt") +
    ggplot2::scale_size_area(name = "Balancing weight", max_size = 2.6) +
    ggplot2::coord_sf(xlim = c(bb["xmin"] - padx, bb["xmax"] + padx),
                      ylim = c(bb["ymin"] - pady, bb["ymax"] + pady), expand = FALSE) +
    ggplot2::labs(tag = "a", x = NULL, y = NULL,
                  subtitle = sprintf("21 dammed basins; 244 controls (effective n ~ %d)", ess)) +
    theme_nw() +
    ggplot2::theme(legend.position = "right", legend.box = "vertical",
                   legend.title = ggplot2::element_text(size = cfg$font$base_size_pt),
                   plot.subtitle = ggplot2::element_text(size = cfg$font$base_size_pt))

  if (inset_ok) {
    ibb <- sf::st_bbox(ib)
    pa <- pa + ggplot2::annotate("rect", xmin = ibb["xmin"], xmax = ibb["xmax"],
                                 ymin = ibb["ymin"], ymax = ibb["ymax"],
                                 fill = NA, colour = "grey20", linewidth = 0.25)
  }

  if (!inset_ok) {
    return(pa + patchwork::plot_annotation(
      title = "A national matched design across Chile's aridity gradient",
      theme = theme_nw()))
  }

  # --- panel b: within-basin placebo geometry -------------------------------------------------
  pb <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = ib, fill = "grey96", colour = "grey55", linewidth = 0.2) +
    ggplot2::geom_sf(data = gz, ggplot2::aes(colour = Gauge, shape = Gauge), size = 1.5) +
    ggplot2::geom_sf(data = idam, shape = 24, fill = pal[["treated"]], colour = "white",
                     size = 2, stroke = 0.3) +
    ggplot2::scale_colour_manual(values = gz_pal, name = NULL) +
    ggplot2::scale_shape_manual(values = c(`Upstream (unregulated)` = 16,
                                           `Downstream (regulated)` = 15), name = NULL) +
    ggplot2::coord_sf(expand = TRUE) +
    ggplot2::labs(tag = "b", x = NULL, y = NULL,
                  subtitle = sprintf("Placebo geometry (basin %s):\nupstream gauges cannot be regulated", iu)) +
    theme_nw() +
    ggplot2::theme(legend.position = "bottom", legend.direction = "vertical",
                   plot.subtitle = ggplot2::element_text(size = cfg$font$base_size_pt))

  patchwork::wrap_plots(pa, pb, ncol = 2, widths = c(1, 0.85)) +
    patchwork::plot_annotation(
      title = "A national matched design across Chile's aridity gradient",
      subtitle = "Dammed basins sit in the arid centre; weighted controls span the same climate strata",
      theme = theme_nw())
}

#' FIGURE (balance / design): entropy balancing removed the siting imbalance, and the pruned
#' units are off-support rather than cherry-picked. (a) Love plot: absolute standardized mean
#' difference (|SMD|) between dammed and control basins BEFORE (unweighted) and AFTER weighting,
#' for the two balanced covariates (basin area, elevation) and two untargeted diagnostics
#' (latitude, aridity); the 0.1 line is the conventional balance threshold. Weighting collapses the
#' large siting gaps to ~0 and the residual aridity imbalance is small and explicitly carried by
#' the doubly-robust outcome model. (b) Common support in climate space (elevation × latitude):
#' retained treated basins overlap the weighted-control cloud (dot size = balancing weight), while
#' the three pruned treated basins are high-Andes / cold (Köppen D/E) units with no comparable
#' controls, correctly dropped rather than extrapolated.
#' @param matched_set    fit_matched_set() output ($balance bal.tab, $ess, $data, $dropped)
#' @param match_cov      match_covariates (pre-trim: unit_id, treated, elev_mean, lat, kg_group)
fig_covariate_balance <- function(matched_set, match_cov) {
  pal <- nw_pal(); cfg <- fig_cfg()

  # --- panel a: love plot --------------------------------------------------------------------
  bal <- matched_set$balance$Balance
  lv  <- data.table::data.table(
    var  = rownames(bal),
    un   = abs(bal$Diff.Un),
    adj  = abs(bal$Diff.Adj))
  nice <- c(log_area = "Basin area (log)", elev_mean = "Mean elevation",
            lat = "Latitude", log_aridity = "Aridity (log P/PET)")
  targeted <- c("log_area", "elev_mean")
  lv[, label := nice[var]]
  lv[, kind  := data.table::fifelse(var %in% targeted, "Balanced on", "Diagnostic")]
  data.table::setorder(lv, un)
  lv[, label := factor(label, levels = label)]
  lg <- data.table::melt(lv, id.vars = c("label", "kind"),
                         measure.vars = c("un", "adj"),
                         variable.name = "when", value.name = "smd")
  lg[, when := factor(data.table::fifelse(when == "un", "Unweighted", "Weighted"),
                      levels = c("Unweighted", "Weighted"))]
  ess <- matched_set$ess

  pa <- ggplot2::ggplot(lv) +
    ggplot2::geom_vline(xintercept = 0.1, linetype = "dashed",
                        colour = cfg$palette$zero_line, linewidth = 0.3) +
    ggplot2::geom_segment(ggplot2::aes(y = label, yend = label, x = un, xend = adj),
                          colour = "grey70", linewidth = 0.4) +
    ggplot2::geom_point(data = lg, ggplot2::aes(smd, label, colour = when, shape = kind),
                        size = 1.8) +
    ggplot2::scale_colour_manual(values = c(Unweighted = cfg$palette$neutral,
                                            Weighted = pal[["treated"]]), name = NULL) +
    ggplot2::scale_shape_manual(values = c(`Balanced on` = 16, Diagnostic = 17), name = NULL) +
    ggplot2::annotate("text", x = Inf, y = 0.7, hjust = 1.05, vjust = 0,
                      size = cfg$font$geom_text_size, colour = "grey30",
                      label = sprintf("Effective controls: %d -> %d",
                                      round(ess["Unweighted", "Control"]),
                                      round(ess["Weighted", "Control"]))) +
    ggplot2::labs(tag = "a", x = "Absolute standardized mean difference", y = NULL) +
    theme_nw()

  # --- panel b: climate-stratum common support (elevation within Köppen group) ---------------
  # Matching is exact within Köppen main group, so support is defined WITHIN each stratum: a
  # treated unit is on-support only if its group holds controls in its elevation window. Plotting
  # elevation by group exposes why the three pruned units are off-support — their strata (D/E) hold
  # no controls near their (high-Andes) elevation, whereas the retained B/C strata overlap densely.
  mc  <- data.table::as.data.table(match_cov)[kg_group %in% c("B", "C", "D", "E") &
                                              is.finite(elev_mean)]
  drp <- matched_set$dropped$unit_id
  kglab <- c(B = "B\nArid", C = "C\nTemperate", D = "D\nCold", E = "E\nPolar")
  mc[, kgf := factor(kglab[kg_group], levels = kglab)]
  ctl <- mc[treated == 0L]
  trt_keep <- mc[treated == 1L & !(unit_id %in% drp)]
  trt_drop <- mc[treated == 1L &  unit_id %in% drp]

  pb <- ggplot2::ggplot() +
    ggplot2::geom_jitter(data = ctl, ggplot2::aes(kgf, elev_mean), width = 0.22, height = 0,
                         colour = "grey60", alpha = 0.45, size = 0.5) +
    ggplot2::geom_jitter(data = trt_keep, ggplot2::aes(kgf, elev_mean), width = 0.12, height = 0,
                         colour = pal[["treated"]], size = 1.4) +
    ggplot2::geom_point(data = trt_drop, ggplot2::aes(kgf, elev_mean),
                        colour = "black", shape = 4, size = 2.4, stroke = 0.8) +
    ggplot2::annotate("text", x = 3, y = 4700, hjust = 0.5, vjust = 1,
                      size = cfg$font$geom_text_size, colour = "grey20",
                      label = "× pruned: off-support\n(no controls in stratum)") +
    ggplot2::scale_x_discrete(limits = unname(kglab), drop = FALSE) +
    ggplot2::scale_y_continuous(limits = c(0, 5000)) +
    ggplot2::labs(tag = "b", x = "Köppen main group",
                  y = "Mean elevation (m)",
                  subtitle = "grey, control basins;  orange, retained dammed;  ×, pruned dammed") +
    theme_nw() +
    ggplot2::theme(plot.subtitle = ggplot2::element_text(size = cfg$font$base_size_pt))

  patchwork::wrap_plots(pa, pb, ncol = 1, heights = c(1, 1)) +
    patchwork::plot_annotation(
      title = "Matching removes the siting imbalance on common support",
      subtitle = "Weighting collapses area/elevation gaps to ~0; pruned units are off-support high-Andes basins",
      theme = theme_nw())
}

#' FIGURE (power / informative null): the null is informative, not blind. (a) EQUIVALENCE/MDE for the
#' two streamflow outcomes (the interpretable outcomes with a meaningful baseline transmission slope):
#' the observed slope gap and its 90% CI against the +-25%-of-baseline negligible region (grey). The
#' CIs exclude large buffering (the minimum detectable effect is ~46-59% of baseline) but exceed the
#' 25% band, so the design rules out large effects without claiming exact equivalence. (b) POSITIVE
#' CONTROL: a known buffering slope injected into treated gauges is recovered one-to-one by the
#' estimator (points on the dashed expected-recovery line), and randomization inference detects it
#' (filled) once it exceeds the MDE, so the estimator would see a real effect if one existed.
#' @param equivalence_table build_equivalence_table() output (observed, ci90_lo/hi, delta, mde_pct_of_baseline)
#' @param positive_control  ssi_positive_control() output (beta_injected, recovered, p_perm, detected)
fig_informative_null <- function(equivalence_table, positive_control) {
  pal <- nw_pal(); cfg <- fig_cfg()

  # panel a: equivalence / MDE on the streamflow outcomes
  eq <- data.table::as.data.table(equivalence_table)[outcome %like% "streamflow"]
  eq[, lab := factor(c("Streamflow (ITT)", "Streamflow (downstream)")[
        match(outcome, c("streamflow SSI (ITT)", "streamflow SSI (downstream)"))])]
  pa <- ggplot2::ggplot(eq, ggplot2::aes(y = lab)) +
    ggplot2::geom_segment(ggplot2::aes(x = -delta, xend = delta, yend = lab),
                          linewidth = 4, colour = "grey86") +          # negligible region
    ggplot2::geom_vline(xintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = ci90_lo, xmax = ci90_hi), height = 0.12,
                            colour = "grey25", linewidth = 0.5) +
    ggplot2::geom_point(ggplot2::aes(x = observed), colour = pal[["treated"]], size = 1.9) +
    ggplot2::geom_text(ggplot2::aes(x = observed, label = sprintf("MDE %.0f%% of baseline",
                                                                 mde_pct_of_baseline)),
                       vjust = -1.1, size = cfg$font$geom_text_size, colour = "grey30") +
    ggplot2::labs(tag = "a", x = "SPEI to SSI slope gap (90% CI; grey = +/-25%-baseline negligible)",
                  y = NULL) +
    theme_nw()

  # panel b: positive-control recovery curve
  pc <- data.table::as.data.table(positive_control)
  offset <- pc[beta_injected == 0, recovered]                  # recovered at zero injection
  pb <- ggplot2::ggplot(pc, ggplot2::aes(beta_injected, recovered)) +
    ggplot2::geom_abline(slope = 1, intercept = offset, linetype = "dashed",
                         colour = cfg$palette$neutral, linewidth = 0.3) +
    ggplot2::geom_line(colour = "grey60", linewidth = 0.3) +
    ggplot2::geom_point(ggplot2::aes(shape = detected, fill = detected),
                        colour = pal[["treated"]], size = 2, stroke = 0.5) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("p[perm]==%.3f", p_perm)), parse = TRUE,
                       hjust = -0.15, vjust = 0.4, size = cfg$font$geom_text_size, colour = "grey30") +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 21, `TRUE` = 21),
                                labels = c("not detected", "detected (p<0.05)"), name = NULL) +
    ggplot2::scale_fill_manual(values = c(`FALSE` = "white", `TRUE` = pal[["treated"]]),
                               labels = c("not detected", "detected (p<0.05)"), name = NULL) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.06, 0.42))) +
    ggplot2::labs(tag = "b", x = "Injected buffering slope (treat:SPEI)",
                  y = "Recovered slope gap") +
    theme_nw()

  patchwork::wrap_plots(pa, pb, ncol = 1, heights = c(0.6, 1)) +
    patchwork::plot_annotation(
      title = "The null is informative: large effects excluded, injected effects recovered",
      subtitle = "Rules out buffering beyond ~half the baseline slope; recovers a real one 1:1 (detected at |beta| >= 0.30)",
      theme = theme_nw())
}

#' FIGURE (forcing): the treatment-relevant exposure is the sustained post-2010 megadrought, shared
#' by treated and control basins (which is why year fixed effects absorb the common shock and the
#' estimand is the differential deficit->impact SLOPE, not a calendar-time contrast). (a) National
#' mean SPEI-12 across the matched basins, 2000-2024, with the drought (negative) excursion filled
#' and the megadrought era shaded; the deficit is sustained and deep (the 2019/2021 hyperdrought
#' winters marked), giving the forcing real dynamic range. (b) Dammed vs weighted-control mean
#' SPEI-12: both co-move through the same megadrought (a common dose), with dammed basins running
#' slightly drier (a siting offset), which is why the estimand is the slope rather than the level.
#' @param spei12_monthly extract_unit_index_monthly() SPEI-12 (unit_id, date, year, month, value)
#' @param matched_set    fit_matched_set() output ($data: unit_id, treated, w)
fig_drought_forcing <- function(spei12_monthly, matched_set) {
  pal <- nw_pal(); labs <- nw_labs(); cfg <- fig_cfg()
  d <- data.table::as.data.table(spei12_monthly)
  md <- data.table::as.data.table(matched_set$data)[, .(unit_id, treated, w)]
  d <- merge(d, md, by = "unit_id")                          # matched units only

  mega0 <- as.Date("2010-01-01"); xmax <- max(d$date)
  hyper <- as.Date(c("2019-07-01", "2021-07-01"))
  mega_rect <- function() ggplot2::annotate("rect", xmin = mega0, xmax = xmax,
                                             ymin = -Inf, ymax = Inf, fill = "grey85", alpha = 0.5)

  # panel a: national mean SPEI-12 with drought excursion filled
  nat <- d[, .(spei = mean(value, na.rm = TRUE)), by = date]
  nat[, dry := pmin(spei, 0)]
  pa <- ggplot2::ggplot(nat, ggplot2::aes(date, spei)) +
    mega_rect() +
    ggplot2::geom_hline(yintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.3) +
    ggplot2::geom_hline(yintercept = -1, linetype = "dotted", colour = cfg$palette$neutral,
                        linewidth = 0.3) +
    ggplot2::geom_area(ggplot2::aes(y = dry), fill = pal[["treated"]], alpha = 0.35) +
    ggplot2::geom_line(linewidth = 0.4, colour = "grey20") +
    ggplot2::geom_vline(xintercept = hyper, linetype = "dashed",
                        colour = cfg$palette$neutral, linewidth = 0.3) +
    ggplot2::annotate("text", x = mega0, y = 2.4, hjust = -0.03, vjust = 1,
                      size = cfg$font$geom_text_size, colour = "grey30", label = "megadrought") +
    ggplot2::annotate("text", x = hyper, y = -2.6, hjust = c(1.05, 1.05), vjust = 0,
                      size = cfg$font$geom_text_size, colour = "grey30",
                      label = c("2019", "2021")) +
    ggplot2::scale_x_date(date_breaks = "5 years", date_labels = "%Y") +
    ggplot2::labs(tag = "a", x = NULL, y = "SPEI-12 (national mean)") +
    theme_nw()

  # panel b: dammed vs weighted-control mean SPEI-12 (shared exposure)
  grp <- d[, .(spei = stats::weighted.mean(value, w, na.rm = TRUE)),
           by = .(date, group = data.table::fifelse(treated == 1L, "treated", "control"))]
  pb <- ggplot2::ggplot(grp, ggplot2::aes(date, spei, colour = group)) +
    mega_rect() +
    ggplot2::geom_hline(yintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.3) +
    ggplot2::geom_line(linewidth = 0.4) +
    ggplot2::scale_colour_manual(values = pal, labels = labs) +
    ggplot2::scale_x_date(date_breaks = "5 years", date_labels = "%Y") +
    ggplot2::labs(tag = "b", x = NULL, y = "SPEI-12 (weighted mean)") +
    theme_nw()

  patchwork::wrap_plots(pa, pb, ncol = 1, heights = c(1, 0.85)) +
    patchwork::plot_annotation(
      title = "A sustained megadrought forcing, shared by dammed and control basins",
      subtitle = "Both track the same shock (dammed run slightly drier, a siting offset), so the estimand is the slope, not levels",
      theme = theme_nw())
}

#' FIGURE (identification): the apparent buffering is a between-region siting confound. A ladder of
#' increasingly stringent estimators for the dammed-vs-control transmission-slope gap: (1) naive
#' pooled, (2) +unit & time fixed effects, (3) the design estimator (entropy-balance weights + FE),
#' (4) design + within-climate-region. For streamflow the "buffering" slope SURVIVES matching and
#' fixed effects (rungs 1-3 stay near -0.18) yet collapses toward zero once compared within climate
#' region (rung 4), and is just as strong at unregulated UPSTREAM gauges (placebo): the signature of
#' an aridity-gradient confound, not regulation. The DiD proxy outcomes carry no signal to remove.
#' @param ladder build_siting_ladder() output (outcome, estimator, rung, slope_gap, se, perm_p, placebo)
fig_decomposition_ladder <- function(ladder) {
  pal <- nw_pal(); cfg <- fig_cfg()
  d <- data.table::as.data.table(ladder)
  d[, `:=`(lo = slope_gap - 1.96 * se, hi = slope_gap + 1.96 * se)]
  # y order: naive (top) down the ladder to within-region, then the placebo (bottom). ggplot draws
  # the first factor level at the bottom, so reverse the reading order.
  lev <- c("naive (no match, no FE)", "unit+time FE (unweighted)", "design (ebal + FE)",
           "design + within region", "upstream placebo (unregulated)")
  d[, estimator := factor(estimator, levels = rev(lev))]
  d[, outcome := factor(outcome, levels = c("Streamflow SSI (SPEI->SSI slope)",
                                            "Irrigated area (DiD)", "Orchard ET (DiD)"))]
  seg <- d[placebo == FALSE]                                  # connect the ladder, not the placebo

  ggplot2::ggplot(d, ggplot2::aes(slope_gap, estimator)) +
    ggplot2::geom_vline(xintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.4) +
    ggplot2::geom_path(data = seg, ggplot2::aes(group = outcome), colour = "grey70",
                       linewidth = 0.3, orientation = "y") +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = lo, xmax = hi, colour = placebo),
                            height = 0.14, linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(colour = placebo, shape = placebo), size = 1.6) +
    ggplot2::geom_text(data = d[!is.na(perm_p) & placebo == FALSE],
                       ggplot2::aes(label = sprintf("p[perm] == %.2f", perm_p)), parse = TRUE,
                       vjust = -0.9, hjust = 0.5, size = cfg$font$geom_text_size, colour = "grey30") +
    ggplot2::geom_text(data = d[!is.na(perm_p) & placebo == TRUE],
                       ggplot2::aes(label = sprintf("p[perm] == %.2f", perm_p)), parse = TRUE,
                       vjust = 1.9, hjust = 0.5, size = cfg$font$geom_text_size, colour = "grey30") +
    ggplot2::scale_colour_manual(values = c(`FALSE` = pal[["treated"]], `TRUE` = cfg$palette$neutral),
                                 guide = "none") +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 17), guide = "none") +
    ggplot2::facet_wrap(~outcome, ncol = 1, scales = "free") +
    ggplot2::labs(x = "Dammed × SPEI slope gap  (<0 = apparent buffering)", y = NULL,
                  title = "Apparent buffering is a between-region siting confound",
                  subtitle = "Survives matching and fixed effects; collapses only within climate region") +
    theme_nw() +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0),
                   plot.subtitle = ggplot2::element_text(hjust = 0, size = cfg$font$base_size_pt),
                   strip.text = ggplot2::element_text(size = cfg$font$base_size_pt, face = "bold"),
                   panel.spacing = ggplot2::unit(3, "mm"))
}

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
    ggplot2::annotate("rect", xmin = -Inf, xmax = -1, ymin = -Inf, ymax = Inf,
                      fill = "grey85", alpha = 0.5) +
    ggplot2::annotate("text", x = -1, y = Inf, hjust = 1.05, vjust = 1.4,
                      size = cfg$font$geom_text_size, colour = "grey30", label = "drought (SPEI < -1)") +
    ggplot2::geom_smooth(ggplot2::aes(weight = w), method = "lm", se = TRUE, linewidth = 0.5) +
    ggplot2::geom_point(data = binned, size = 0.9) +
    ggplot2::scale_colour_manual(values = pal, labels = labs) +
    ggplot2::labs(tag = "a", x = "Meteorological drought  SPEI-12", y = "Streamflow drought  SSI-12",
                  subtitle = "Downstream gauges; points are decile-binned weighted means") +
    theme_nw() +
    ggplot2::theme(plot.subtitle = ggplot2::element_text(size = cfg$font$base_size_pt))

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

#' Weighted treated-vs-control mean (and its weighted SE) of a panel outcome by year (ebal weights).
#' SE is the standard error of the weighted mean across units (weighted variance / effective n), so
#' panel-a trajectories can carry an honest uncertainty band rather than bare point-lines.
#' (NB: did_panel carries a column literally named `outcome`, so reference the target column by
#' name via [[ ]] into a temp to avoid the data.table scoping collision.)
group_year_means <- function(did_panel, ycol = "y") {
  d <- data.table::copy(data.table::as.data.table(did_panel))
  d[, .yv := d[[ycol]]]
  d[is.finite(.yv), {
      mm   <- stats::weighted.mean(.yv, w)
      v    <- sum(w * (.yv - mm)^2) / sum(w)          # weighted variance across units
      neff <- sum(w)^2 / sum(w^2)                     # Kish effective n
      .(m = mm, se = sqrt(v / neff))
    }, by = .(group = data.table::fifelse(treat == 1L, "treated", "control"), year)][]
}

#' Clustered differential pre/post-trend slope test (treat:year) on a DiD panel window — a robust
#' one-degree-of-freedom parallel-trends diagnostic. The full joint event-study Wald is rank-deficient
#' and over-rejects at ~21 treated clusters, so this linear-trend test is the defensible summary.
.diff_trend_p <- function(panel) {
  m <- fixest::feols(y ~ treat:year | unit_id + year, data = panel, weights = ~w, cluster = ~unit_id)
  ct <- as.data.frame(summary(m)$coeftable)
  ct[grepl("treat:year", rownames(ct)), 4][1]
}

#' FIGURE: observed irrigated-area DiD — (a) treated vs control area-fraction trajectory (the ~10x
#' siting level gap, parallel evolution), (b) event-study coefficients (flat pre-trends, no
#' post-megadrought divergence). The clean dynamic null at the heart of the H2 result.
#' @param did_panel_area build_did_panel() output for area_frac
#' @param es_area        fit_event_study() model on the area panel
fig_area_did <- function(did_panel_area, es_area, ref_year = 2009L) {
  pal <- nw_pal(); labs <- nw_labs(); cfg <- fig_cfg()
  d <- data.table::as.data.table(did_panel_area)
  xmax <- max(d$year)
  nt <- data.table::uniqueN(d[treat == 1L, unit_id]); nc <- data.table::uniqueN(d[treat == 0L, unit_id])
  mega <- function() ggplot2::annotate("rect", xmin = 2010, xmax = xmax, ymin = -Inf, ymax = Inf,
                                       fill = "grey85", alpha = 0.5)

  # panel a: weighted mean trajectory with an honest 95% band, y-axis anchored at 0
  traj <- group_year_means(did_panel_area, "y")
  pa <- ggplot2::ggplot(traj, ggplot2::aes(year, 100 * m, colour = group, fill = group)) +
    mega() +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = 100 * (m - 1.96 * se), ymax = 100 * (m + 1.96 * se)),
                         colour = NA, alpha = cfg$palette$ci_band_alpha) +
    ggplot2::geom_line(linewidth = 0.5) + ggplot2::geom_point(size = 0.7) +
    ggplot2::scale_colour_manual(values = pal, labels = labs) +
    ggplot2::scale_fill_manual(values = pal, labels = labs) +
    ggplot2::scale_y_continuous(limits = c(0, NA)) +
    ggplot2::annotate("text", x = 2010, y = Inf, hjust = -0.05, vjust = 1.4,
                      size = cfg$font$geom_text_size, colour = "grey30", label = "megadrought") +
    ggplot2::labs(tag = "a", x = NULL, y = "Cropland area (% of basin)",
                  subtitle = sprintf("%d dammed vs %d matched-control basins", nt, nc)) +
    theme_nw() +
    ggplot2::theme(plot.subtitle = ggplot2::element_text(size = cfg$font$base_size_pt))

  # panel b: dynamic event study with the robust pre/post differential-trend tests annotated
  pre_p  <- tryCatch(.diff_trend_p(d[year <= ref_year]), error = function(e) NA_real_)
  post_p <- tryCatch(.diff_trend_p(d[year >  ref_year]), error = function(e) NA_real_)
  es <- extract_event_study(es_area, ref_year)
  pb <- ggplot2::ggplot(es, ggplot2::aes(year, 100 * coef)) +
    mega() +
    ggplot2::geom_hline(yintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.3) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = 100 * ci_lo, ymax = 100 * ci_hi),
                         fill = pal[["treated"]], alpha = cfg$palette$ci_band_alpha) +
    ggplot2::geom_line(colour = pal[["treated"]], linewidth = 0.5) +
    ggplot2::geom_point(colour = pal[["treated"]], size = 0.7) +
    ggplot2::annotate("text", x = -Inf, y = Inf, hjust = -0.05, vjust = 1.3,
                      size = cfg$font$geom_text_size, colour = "grey30",
                      label = sprintf("differential trend: pre p = %.2f, post p = %.2f", pre_p, post_p)) +
    ggplot2::labs(tag = "b", x = NULL,
                  y = "Dammed × year on cropland area\n(pp, ref. 2009)") +
    theme_nw()

  patchwork::wrap_plots(pa, pb, ncol = 1) +
    patchwork::plot_annotation(
      title = "Reservoirs do not alter irrigated-area dynamics",
      theme = theme_nw())
}

#' FIGURE: storage declines while refill amplitude holds. (a) Cross-reservoir annual storage band —
#' realized MEDIAN peak and trough percent-of-capacity (robust to a few reservoirs whose storage
#' exceeds nominal capacity) with IQR ribbons — drifts DOWN over 2005-2024, while the peak-trough
#' amplitude (grey) holds roughly constant: the whole band shifts rather than narrows. (b) Per-year
#' trend slope of peak / trough / amplitude (reservoir FE, clustered): peak and trough both decline
#' while amplitude is indistinguishable from zero (a supply-side level decline, not refill loss). The
#' central lines are the realized medians, not linear fits; the net trend is quantified in (b).
#' @param band_annual storage_band_annual() output (fraction-of-capacity)
#' @param band_trends fit_storage_band_trends() output
fig_storage_band <- function(band_annual, band_trends) {
  pal <- nw_pal(); cfg <- fig_cfg()
  b <- data.table::as.data.table(band_annual)
  q <- function(x, p) stats::quantile(x, p, names = FALSE, na.rm = TRUE)
  by <- b[, .(peak_m = stats::median(peak), peak_lo = q(peak, .25), peak_hi = q(peak, .75),
              trough_m = stats::median(trough), trough_lo = q(trough, .25), trough_hi = q(trough, .75),
              amp_m = stats::median(amplitude)), by = year]
  data.table::setorder(by, year); yl <- max(by$year)

  pa <- ggplot2::ggplot(by, ggplot2::aes(year)) +
    ggplot2::geom_hline(yintercept = 100, linetype = "dotted", colour = cfg$palette$neutral,
                        linewidth = 0.3) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = 100 * peak_lo,   ymax = 100 * peak_hi),
                         fill = pal[["treated"]], alpha = cfg$palette$ci_band_alpha) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = 100 * trough_lo, ymax = 100 * trough_hi),
                         fill = pal[["control"]], alpha = cfg$palette$ci_band_alpha) +
    ggplot2::geom_line(ggplot2::aes(y = 100 * peak_m),   colour = pal[["treated"]], linewidth = 0.5) +
    ggplot2::geom_line(ggplot2::aes(y = 100 * trough_m), colour = pal[["control"]], linewidth = 0.5) +
    ggplot2::geom_line(ggplot2::aes(y = 100 * amp_m), colour = "grey45", linewidth = 0.5,
                       linetype = "longdash") +
    ggplot2::annotate("text", x = yl, y = 100 * by[year == yl, peak_m], label = "peak",
                      hjust = 1, vjust = -0.7, size = cfg$font$geom_text_size, colour = pal[["treated"]]) +
    ggplot2::annotate("text", x = yl, y = 100 * by[year == yl, trough_m], label = "trough",
                      hjust = 1, vjust = 1.5, size = cfg$font$geom_text_size, colour = pal[["control"]]) +
    ggplot2::annotate("text", x = yl, y = 100 * by[year == yl, amp_m], label = "amplitude",
                      hjust = 1, vjust = -0.7, size = cfg$font$geom_text_size, colour = "grey45") +
    ggplot2::annotate("text", x = min(by$year), y = 100, label = "capacity", hjust = 0, vjust = -0.5,
                      size = cfg$font$geom_text_size, colour = cfg$palette$neutral) +
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
      title = "Storage declines while seasonal refill amplitude holds",
      subtitle = "The whole band drifts down; peak-trough amplitude is statistically unchanged",
      theme = theme_nw())
}

#' FIGURE: convergent null — forest plot on ONE honest axis, the effect in its own standard errors
#' (estimate / SE), applied UNIFORMLY to every row so the metric no longer differs by row. Estimates
#' are grouped into the two inference regimes (cross-sectional matched ATTs vs forcing-interacted DiD
#' slope-gaps); the DiD rows carry their randomization-inference p (the design's valid inference,
#' since the +-1.96 SE guides over-reject at ~21 clusters). Whole-basin ET is drawn as an OPEN symbol
#' and labelled confounded/excluded: on this honest axis it sits well outside +-1.96 (its cluster CI
#' excludes zero, matching Table 1), but its event-study pre-trends fail, so it is not interpretable.
#' Every interpretable estimate brackets zero.
#' @param results_table build_main_results_table() output (estimate, se, p, group, outcome)
fig_convergent_null <- function(results_table) {
  pal <- nw_pal(); cfg <- fig_cfg()
  d <- data.table::as.data.table(results_table)[is.finite(estimate) & is.finite(se) & se > 0]
  d[, z := estimate / se]                                    # uniform Wald z across ALL rows
  d[, conf := outcome == "Whole-basin ET"]                   # confounded / excluded (see Table 1)
  d[, gfac := factor(group, levels = c("Cross-sectional matched ATT",
                                        "Forcing-interacted DiD (slope-gap)"))]
  data.table::setorder(d, gfac, z)
  d[, label := factor(outcome, levels = unique(outcome))]

  ggplot2::ggplot(d, ggplot2::aes(z, label)) +
    ggplot2::geom_vline(xintercept = c(-1.96, 1.96), linetype = "dotted",
                        colour = cfg$palette$neutral, linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = 0, colour = cfg$palette$zero_line, linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = z - 1.96, xmax = z + 1.96, linetype = conf),
                            height = 0.16, colour = "grey30", linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(shape = conf, fill = conf), colour = pal[["treated"]],
                        size = 1.6, stroke = 0.5) +
    ggplot2::geom_text(data = d[!is.na(p)],
                       ggplot2::aes(label = sprintf("p[perm] == %.2f", p)), parse = TRUE,
                       vjust = -1, size = cfg$font$geom_text_size, colour = "grey30") +
    ggplot2::geom_text(data = d[conf == TRUE], ggplot2::aes(label = "confounded (excluded)"),
                       vjust = 2.2, size = cfg$font$geom_text_size, colour = "grey30") +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 21, `TRUE` = 21), guide = "none") +
    ggplot2::scale_fill_manual(values = c(`FALSE` = pal[["treated"]], `TRUE` = "white"),
                               guide = "none") +
    ggplot2::scale_linetype_manual(values = c(`FALSE` = "solid", `TRUE` = "22"), guide = "none") +
    ggplot2::facet_wrap(~gfac, ncol = 1, scales = "free_y", strip.position = "top") +
    ggplot2::coord_cartesian(xlim = c(-4, 7)) +
    ggplot2::labs(x = "Effect in standard errors  (estimate / SE)", y = NULL,
                  title = "Operational reservoir effect brackets zero",
                  subtitle = "Positive = vulnerability; negative = buffering") +
    theme_nw() +
    ggplot2::theme(legend.position = "none", plot.title = ggplot2::element_text(hjust = 0),
                   plot.subtitle = ggplot2::element_text(hjust = 0, size = cfg$font$base_size_pt),
                   strip.text = ggplot2::element_text(size = cfg$font$base_size_pt, face = "bold"),
                   strip.background = ggplot2::element_blank(),
                   panel.spacing = ggplot2::unit(4, "mm"))
}
