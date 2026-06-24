# Config + path helpers. The project root is resolved once; everything else is relative.

#' Absolute path from the project root.
#' @param ... path components, e.g. project_path("data", "raw")
project_path <- function(...) {
  root <- Sys.getenv("DDV_ROOT", unset = here_root())
  normalizePath(file.path(root, ...), mustWork = FALSE)
}

# Best-effort project-root detection (works whether run from root or targets/).
here_root <- function() {
  if (requireNamespace("here", quietly = TRUE)) return(here::here())
  wd <- getwd()
  if (basename(wd) == "targets") return(dirname(wd))
  wd
}

#' Load a YAML config file from config/ by stem name (no extension).
#' @param name e.g. "study_period", "variables", "data_sources", "reservoirs"
load_config <- function(name) {
  path <- project_path("config", paste0(name, ".yml"))
  if (!file.exists(path)) stop("Config not found: ", path)
  yaml::read_yaml(path)
}

#' Resolve a repo-relative path stored in config (e.g. data_sources reservoir paths)
#' against the project root. Absolute paths (external drives) are returned unchanged.
resolve_path <- function(p) {
  if (grepl("^(/|[A-Za-z]:)", p)) return(p)   # already absolute
  project_path(p)
}
