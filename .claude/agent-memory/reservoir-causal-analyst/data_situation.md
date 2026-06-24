---
name: data-situation
description: Which datasets are real and usable vs blocked/missing for the Chile reservoir project (as of 2026-06)
metadata:
  type: project
---

Verified 2026-06-23 by inspecting files directly.

**REAL / usable now:**
- Reservoir storage: data/raw/reservoirs/reservoirs_levels_2005-2026.csv. Semicolon claimed but file is actually COMMA-delimited, wide, 26 reservoirs (27 rows incl header), monthly 2005-01..2026-04. Columns: embsalse, ID_DGA, ID_IDE, max_level_hm3, then one col per month. Values are a RELATIVE INDEX, NOT volume — must divide by max_level_hm3 (which IS present, in hm3) to get percent-of-capacity before any cross-reservoir comparison or "slack" calc. Rungue has blank capacity. Many trailing empty columns past 2026-04. Late-period values look noisy/zig-zag (possible sub-monthly artifacts) — inspect before use.
- Reservoir polygons: data/raw/reservoirs/reservoirs_shapefile/Embalse_2026_05_31.shp.
- Drought indices: SPI, SPEI, EDDI; monthly GeoTIFF; timescales 1/3/6/12/24/36 mo; baseline 1991-2026; span 1991-01..2026-05/06. Root: /media/francisco/Respaldo_frzambra/data/drought/CHIRPS-CHIRTS/1991-2026/ . Registered in config/data_sources.yml. Filename quirk: literal prefix "chir[p|t]s" contains regex metachars — match on the index token, not a glob of the prefix. CHIRPS ET0 (1981-2026) and aridity index exist under parent dir, not registered by default.
- Usable overlap of storage + indices = 2005-01 onward.

**BLOCKED / missing (placeholders only) — name these as gating dependencies:**
- Watershed boundaries (needed to define basin units and zonal stats).
- MODIS NDVI/EVI vegetation (the H1 ecological-drought outcome AND the H2 mediator greening signal).
- Land-cover / irrigated-area maps (the H2 MEDIATOR — without this the central mediation test cannot run).
- Reservoir capacity beyond max_level_hm3, and operating rule curves (needed to argue s* is emergent vs a policy rule, the key H1 falsification).
- Streamflow (regulated + ideally naturalized) — needed for a clean propagation/buffering outcome independent of vegetation attribution.
