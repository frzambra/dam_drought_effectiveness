# Publication theme + palette (Nature Water family), driven by config/figure_settings.yml.

#' Load figure settings.
fig_cfg <- function() load_config("figure_settings")

#' Minimal publication ggplot theme.
theme_nw <- function(base_size = NULL) {
  cfg <- fig_cfg()
  b <- if (is.null(base_size)) cfg$font$base_size_pt else base_size
  ggplot2::theme_minimal(base_size = b, base_family = cfg$font$family) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(linewidth = 0.2, colour = "grey90"),
      axis.line  = ggplot2::element_line(linewidth = 0.3, colour = "grey20"),
      axis.ticks = ggplot2::element_line(linewidth = 0.3, colour = "grey20"),
      plot.title    = ggplot2::element_text(size = cfg$font$title_size_pt, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = b, colour = "grey30"),
      plot.tag      = ggplot2::element_text(size = cfg$font$title_size_pt, face = "bold"),
      legend.position = "top", legend.title = ggplot2::element_blank(),
      legend.key.size = ggplot2::unit(3, "mm"),
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      strip.text = ggplot2::element_text(face = "bold"))
}

#' Treated/control colour + label vectors.
nw_pal  <- function() { cfg <- fig_cfg(); c(treated = cfg$palette$treated, control = cfg$palette$control) }
nw_labs <- function() { cfg <- fig_cfg(); c(treated = cfg$labels$treated, control = cfg$labels$control) }

#' Save a ggplot to results/figures/ in all configured formats at a Nature column width.
#' @return character vector of written paths (for tar_target(format = "file"))
save_fig <- function(plot, name, width = c("single", "onehalf", "double"), height_mm = 80) {
  cfg <- fig_cfg(); width <- match.arg(width)
  w <- cfg$device[[paste0("width_", width, "_mm")]]
  dir <- project_path("results/figures"); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  paths <- vapply(cfg$device$formats, function(fmt) {
    p <- file.path(dir, paste0(name, ".", fmt))
    ggplot2::ggsave(p, plot, width = w, height = height_mm, units = "mm",
                    dpi = cfg$device$dpi, device = fmt)
    p
  }, character(1))
  unname(paths)
}
