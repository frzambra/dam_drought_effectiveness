# H3 — Spatial Displacement: Reservoirs Export Drought Vulnerability

> **Role:** Robustness / decomposition. Most risky. **Overall Nature Water score: 8.1.**

## Hypothesis statement

Reservoirs do not eliminate drought vulnerability but spatially redistribute it: in-basin
buffering is partially financed by intensified ecological drought immediately downstream of
impoundments and in hydrologically connected adjacent areas, so the watershed-scale
"benefit" is partly an artifact of where the analysis boundary is drawn.

## Mechanism

Storage and consumptive use upstream reduce downstream flow and riparian/floodplain water
supply, especially during dry years when releases are prioritized for committed irrigation
over environmental flows. Vegetation and ET in the downstream/riparian zone therefore
experience deeper drought anomalies than absent the reservoir. The reservoir transfers
deficit across space — a within-system zero-sum (or negative-sum) reallocation that
aggregate basin metrics conceal.

## Why it is novel

Most reservoir-drought work uses lumped basin units and reports net basin effects, masking
internal redistribution. H3 makes the spatial gradient the object of study (upstream-of-dam
vs. immediately-downstream vs. matched control), testing whether buffering is partly an
accounting illusion.

## Required data

MODIS NDVI/EVI and ET at pixel/sub-basin resolution (upstream / downstream / riparian zones
relative to dam location); reservoir polygons (shapefile) for georeferencing;
flow-direction / DEM-derived downstream delineation; SPI/SPEI/EDDI; matched undammed basins.

## Statistical test

- Spatially stratified comparison of vegetation/ET drought anomalies along the
  upstream→downstream gradient, drought vs. non-drought years (mixed-effects with
  distance-to-dam × drought-state interaction).
- Spatial DiD: downstream zones in dammed basins vs. equivalent positions in matched controls.
- Spatial regression discontinuity at the dam location where suitable.
- Decomposition: net basin buffering = in-basin gain − downstream loss (with uncertainty).

## Potential falsification

Rejected if downstream/riparian zones in dammed basins show equal/weaker drought anomalies
than equivalent positions in matched controls, or if no spatial gradient keys to dam
location. If aggregate buffering survives full spatial decomposition, displacement is
falsified.

## Risk note

Lowest-margin hypothesis. Credibility hinges on accurate per-dam downstream/riparian
delineation and on MODIS-resolution ET/NDVI resolving the displacement signal against
confounders (groundwater, tributary inputs, return flows). With 26 heterogeneous reservoirs,
sample size for clean spatial RD may be thin.

## Nature Water score

| Novelty | Significance | Generalizability | Policy relevance | **Overall** |
|---------|-------------|------------------|------------------|-------------|
| 9 | 8 | 7 | 8 | **8.1** |
