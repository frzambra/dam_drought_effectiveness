---
name: data-state
description: What data actually exists in the repo vs. placeholders, as of 2026-06. Governs which discriminating tests are feasible now.
metadata:
  type: project
---

As of 2026-06 the repo is freshly scaffolded. ONLY real data: `data/raw/reservoirs/reservoirs_levels_2005-2026.csv` (wide format, semicolon-delimited, DECIMAL COMMA, monthly columns 2005-01 to 2026-04, one row per reservoir, cols: embsalse;ID_DGA;ID_IDE;<months>) and `data/raw/reservoirs/reservoirs_shapefile/Embalse_2026_05_31.shp`.

Storage units appear to be a relative/index scale (small integers, reservoir-specific ceilings e.g. Santa_Juana caps ~166), NOT volumetric Mm3 — verify before cross-reservoir comparison.

All other raw dirs (landcover, watersheds, precipitation, evapotranspiration, drought_indices, vegetation, streamflow, temperature) contain a single empty/placeholder file. `src/`, `targets/`, `config/`, `notebooks/`, `manuscript/` are empty placeholders. CLAUDE.md confirms this.

**Why:** Every discriminating test for the causal hypotheses depends on EO/climate/landcover/streamflow data that has NOT been acquired yet.
**How to apply:** When proposing tests, flag that they are contingent on data acquisition. Do not assume any analysis pipeline runs. The "available data" list in task prompts describes the INTENDED dataset, not what is on disk.
