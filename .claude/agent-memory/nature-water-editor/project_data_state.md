---
name: project-data-state
description: What data is actually on disk as of 2026-06 — supersedes the stale "only reservoir storage" README caveat
metadata:
  type: project
---

As of 2026-06-24, the docs/hypotheses/README "only reservoir storage is real" caveat is STALE. Actually on disk (PI-verified):

1. Reservoir storage: 26 monitored reservoirs, monthly 2005-01 to 2026-04, with capacity (hm3) -> percent-of-capacity comparable across reservoirs. National dam POINT registry shapefile (1370 dams) with ANOCONTR (construction yr), USO_EMBAL (use, e.g. RIEGO=irrigation), size, region. ~21 of 26 monitored predate 2005 panel -> only ~5 commission within panel.
2. Drought indices (CHIRPS-CHIRTS): monthly GeoTIFF, Chile, 1991-2026, timescales 1/3/6/12/24/36: SPI, SPEI, EDDI.
3. MODIS ecological-drought: zNPP (annual 2000-2025), zcNDVI-6 (monthly 2000-2025), SETI (standardized actual ET anomaly, monthly, timescales 1-36, 2000-2024).
4. Land cover: MapBiomas Chile Col.2, 30m annual 1999-2024 (agri/pasture/silviculture). MODIS MCD12Q1 IGBP 500m annual 2001-2024 as coarse cross-check.

**MISSING and gating:**
- Watershed boundaries NOT delineated. Only spatial unit is the dam POINT (interim) — this is a mechanistic error (reservoir buffers downstream command area, not the point). HIGHEST-PRIORITY acquisition. Suggested fast start: HydroSHEDS/HydroBASINS or DGA cuencas.
- No streamflow/gauge data -> no SSI -> hydrological-drought link in the pathway is unmeasured. Acquire DGA discharge (2nd priority; strengthens but does not gate the first analysis).
- Reservoir operating rules / rule curves not in hand — needed before H1 manuscript (to argue s* is physical not policy), not before first analysis.
