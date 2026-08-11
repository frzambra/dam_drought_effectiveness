# Carryover-capacity context (2026-07-03 round 6, comment 5): are the treated reservoirs physically
# capable of multi-year storage, or is the 12-month null a deterministic consequence of
# seasonal-only design? Two facts from the project's own data: capacity relative to mean annual
# downstream flow (a carryover ratio; >= ~0.5 implies substantial interannual storage), and the
# pre-2010 annual trough (reservoirs were NOT emptied seasonally, so storage persisted across
# years and carryover buffering was physically available). Feeds Supplementary Table S54.

#' @return data.table(quantity, value, detail)
build_carryover_check <- function(levels_long, reservoir_units, streamflow_monthly,
                                  stations_units, storage_band) {
  cap <- unique(data.table::as.data.table(levels_long)[is.finite(max_level_hm3),
                                                       .(ID_DGA, max_level_hm3)])
  ru <- data.table::as.data.table(reservoir_units)[level == "subcuencas", .(ID_DGA, unit_id)]
  su <- data.table::as.data.table(stations_units)[treat == 1L & regulated == "down",
                                                  .(codigo, unit_id)]
  q  <- merge(data.table::as.data.table(streamflow_monthly), su, by = "codigo")
  qu <- q[, .(q_ms = mean(q_mon, na.rm = TRUE)), by = unit_id]
  qu[, flow_hm3 := q_ms * 31.536]
  d <- merge(merge(cap, ru, by = "ID_DGA"), qu, by = "unit_id")
  d[, ratio := max_level_hm3 / flow_hm3]
  tr <- data.table::as.data.table(storage_band)[year < 2010, mean(trough)]
  qt <- function(x, p) stats::quantile(x, p, names = FALSE)
  data.table::data.table(
    quantity = c("reservoir capacity / mean annual downstream flow (median ratio)",
                 "reservoirs with carryover ratio >= 0.5",
                 "pre-2010 mean annual storage trough (fraction of capacity)"),
    value  = c(round(stats::median(d$ratio), 2), sum(d$ratio >= 0.5), round(tr, 2)),
    detail = c(sprintf("IQR [%.2f, %.2f]; n = %d reservoirs with a gauged downstream unit; downstream flow is regulated, so ratios are approximate",
                       qt(d$ratio, .25), qt(d$ratio, .75), nrow(d)),
               sprintf("of %d; %d have ratio >= 1 (storage exceeding a full year of flow)",
                       nrow(d), sum(d$ratio >= 1)),
               "seasonal drawdown does not empty the reservoirs; storage persists across years, so carryover buffering was physically available"))
}
