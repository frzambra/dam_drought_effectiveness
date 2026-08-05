# Glossary of acronyms and abbreviations

Acronyms used across this project's docs, config, and code, grouped by domain. Scope notes
(units, sign conventions, where it's used here) are added where they matter for interpretation.

---

## Drought, hydrology & vegetation indices

| Acronym | Expansion | Notes (as used here) |
|---|---|---|
| SPI | Standardized Precipitation Index | Meteorological drought; z-score (negative = dry). CHIRPS-derived, timescales 1–36 months. |
| SPEI | Standardized Precipitation-Evapotranspiration Index | Like SPI but on a P−PET water balance; the primary forcing variable (SPEI-12 in the forcing-conditioned ATT). Negative = dry. |
| EDDI | Evaporative Demand Drought Index | Atmospheric evaporative-demand drought; CHIRPS-CHIRTS derived. |
| SSI | Standardized Streamflow Index | Hydrological drought. **Not yet available** — gated on DGA streamflow acquisition. |
| SETI | Standardized Evapotranspiration (AET) anomaly Index | MODIS-derived actual-ET anomaly; water-use response variable. |
| NDVI | Normalized Difference Vegetation Index | Greenness/vigour. |
| EVI | Enhanced Vegetation Index | NDVI alternative, less saturation in dense canopy. |
| zcNDVI | z-score of accumulated NDVI | Standardized NDVI anomaly (6-month accumulation in the data here). |
| NPP | Net Primary Productivity | MOD17A3HGF product. |
| zNPP | z-score of annual NPP | The ecological-outcome anomaly in the matched-set / forcing-conditioned ATT. |
| P | Precipitation | — |
| PET | Potential Evapotranspiration | Atmospheric water demand. |
| AET | Actual Evapotranspiration | Realized ET (water use). |
| ET | Evapotranspiration | Generic; also ET0 = reference ET. **Note:** `ET` is also a Köppen code (see below). |

## Hydroclimate & Earth-observation data products / sensors

| Acronym | Expansion | Notes |
|---|---|---|
| EO | Earth Observation | Remote-sensing data broadly. |
| MODIS | Moderate Resolution Imaging Spectroradiometer | NASA sensor; source of NDVI/EVI/NPP/ET products. |
| MOD17A3HGF | MODIS annual NPP/GPP product | Source of zNPP. |
| MCD12Q1 | MODIS annual land-cover product | IGBP-scheme land cover, ~500 m. |
| IGBP | International Geosphere-Biosphere Programme | Land-cover classification scheme used by MCD12Q1. |
| MapBiomas | (not an acronym) MapBiomas Chile | Annual 30 m land-cover/land-use product (Collection 2). |
| CHIRPS | Climate Hazards Group InfraRed Precipitation with Station data | Precipitation input to SPI/SPEI/aridity. |
| CHIRTS | Climate Hazards Center InfraRed Temperature with Station data | Temperature input (paired as CHIRPS-CHIRTS). |
| ERA5-Land | ECMWF Reanalysis v5, Land component | Reanalysis hydroclimate (candidate source). |
| TerraClimate | (not an acronym) | Monthly climate/water-balance dataset (candidate source). |
| GRACE | Gravity Recovery and Climate Experiment | Terrestrial water-storage anomalies. |
| SMAP | Soil Moisture Active Passive | Satellite soil moisture. |
| SRTM | Shuttle Radar Topography Mission | DEM source (3-arc-sec, ~90 m). |
| DEM | Digital Elevation Model | Terrain covariates (mean elevation, relief). |
| WMO | World Meteorological Organization | "WMO normal" = the 1991–2020 30-year baseline. |
| UNEP | United Nations Environment Programme | Source of the aridity-index classification bands. |

## Statistics & causal inference

| Acronym | Expansion | Notes |
|---|---|---|
| ATT | Average Treatment effect on the Treated | The estimand: effect on dammed subcuencas. |
| DiD | Difference-in-Differences | Incl. "DiD-in-slopes" and commissioning event-study variants. |
| TWFE | Two-Way Fixed Effects | Avoided as primary (staggered-adoption bias). |
| FE | Fixed Effects | — |
| SCM | Synthetic Control Method | Candidate primary counterfactual. |
| GSC | Generalized Synthetic Control | `gsynth`/`augsynth` family. |
| RMSPE | Root Mean Square Prediction Error | Pre-period SCM fit diagnostic. |
| RD | Regression Discontinuity | Candidate spatial design (sample may be thin). |
| DR | Doubly-Robust | Weighting + outcome-regression estimator (`dr_att`). |
| CEM | Coarsened Exact Matching | Robustness matching method. |
| NN | Nearest Neighbour (matching) | 1:k Mahalanobis matching robustness. |
| ESS | Effective Sample Size | Post-weighting control sample (~91 here). |
| SMD | Standardized Mean Difference | Covariate-balance metric (target \|SMD\| < 0.1). |
| HC3 | Heteroskedasticity-Consistent (type 3) | Robust SE estimator. |
| SE | Standard Error | — |
| CI | Confidence Interval | — |
| NIE | Natural Indirect Effect | Mediation (H2 via irrigated-area expansion). |
| NDE | Natural Direct Effect | Mediation complement to NIE. |
| SUTVA | Stable Unit Treatment Value Assumption | Threatened by downstream/water-market spillovers. |
| GPD | Generalized Pareto Distribution | Extreme-value tail model (H1); under-identified per-basin. |
| TAR | Threshold AutoRegressive (model) | Regime-switching storage/vegetation response. |

## Spatial, formats & standards

| Acronym | Expansion | Notes |
|---|---|---|
| CRS | Coordinate Reference System | — |
| EPSG | European Petroleum Survey Group (code) | EPSG:4326 = WGS84 lat/lon; rasters' CRS. |
| SIRGAS | Sistema de Referencia Geocéntrico para las Américas | Native CRS of the DGA shapefiles (reproject to EPSG:4326). |
| GeoTIFF | Georeferenced Tagged Image File Format | Raster file format. |
| CSV | Comma-Separated Values | Reservoir levels table. |
| UTF-8 | Unicode Transformation Format, 8-bit | Encoding of the levels CSV. |
| RGB | Red-Green-Blue | Cosmetic raster palette (key on class ID instead). |
| NA / NaN | Not Available / Not a Number | Missing / nodata values. |
| ID | Identifier | — |

## Chile / institutional

| Acronym | Expansion | Notes |
|---|---|---|
| DGA | Dirección General de Aguas | Chile's water authority; source of watershed boundaries and streamflow. |
| BNA | Banco Nacional de Aguas | DGA's hydrographic division dataset (cuencas/subcuencas). |
| COD_CUEN / COD_SUBC | Código de Cuenca / Subcuenca | BNA watershed / sub-watershed codes. |
| CODEMBAL | Código de Embalse | Reservoir code (shapefile join key to `ID_DGA`). |
| ANOCONTR | Año de Construcción | Reservoir construction year (treatment-timing proxy). |
| USO_EMBAL / RIEGO | Uso del Embalse / Riego | Reservoir use / "irrigation". |
| NOMREG / REGION | Nombre de Región | Administrative region fields. |
| TAMANO | Tamaño | Reservoir size class. |

## Köppen-Geiger climate codes (used as matching strata)

Main groups: **A** tropical, **B** arid, **C** temperate, **D** cold, **E** polar. Subtypes
present over Chile:

| Code | Description |
|---|---|
| BWh / BWk | Arid desert, hot / cold |
| BSh / BSk | Arid steppe, hot / cold |
| Csb | Temperate, dry summer, warm summer (Mediterranean central Chile) |
| Cfb / Cfc | Temperate, no dry season, warm / cold summer |
| Dsc | Cold, dry summer, cold summer |
| ET | Polar tundra (high Andes / high latitude) — **not** evapotranspiration here |
| EF | Polar frost |

## Software / R packages (referenced by name)

`targets`, `renv`, `quarto` (reproducibility); `WeightIt` (entropy balancing), `MatchIt`
(CEM/NN), `cobalt` (balance), `fixest` (FE regressions), `segmented` (changepoint),
`brms`/`marginaleffects` (Bayesian/mediation), `tidysynth`/`scpi`/`gsynth`/`augsynth` (SCM),
`did`/`sunab` (event study), `qgam`/`quantreg` (quantile/tail), `data.table`/`sf`/`terra`/
`exactextractr` (data & spatial).

---

*Maintenance: when a new acronym enters the docs/config/code, add it here. Köppen codes and
data-product names also appear in [`config/data_sources.yml`](../../config/data_sources.yml).*
