# An upstream placebo shows that reservoir siting explains the apparent drought buffering of seasonal reservoirs in Chile's megadrought

Data and code archive for the manuscript testing whether reservoirs buffer
drought in Chile or whether the apparent buffering is a siting confound. We
treat reservoir presence as a basin level intervention during Chile's
megadrought and separate siting from operation with an upstream and
downstream streamflow placebo, then match dry dammed basins to similar
undammed ones. The seasonal reservoirs that dominate the fleet show no
measurable buffer against multi year drought once siting is accounted for.
Only the carryover capable reservoirs, those holding at least half a year of
downstream flow, show a downstream specific buffering signal that the
seasonal majority does not. Prepared for submission to Water Resources
Research.

## Repository structure

- `src/R/` -- reusable R functions, organized by analysis stage (data
  ingestion, preprocessing, drought indices, reservoirs, matching, causal
  inference, statistics, visualization).
- `targets/` -- the `targets` pipeline (`_targets.R`) that chains every
  analysis step from raw inputs to figures and tables. Every result in the
  manuscript corresponds to a named pipeline target.
- `config/` -- study parameters (period, watersheds, reservoirs, variables,
  figure settings, external data source registry) read by the pipeline
  rather than hard-coded.
- `data/raw/reservoirs/` -- the reservoir storage and capacity records
  (`reservoirs_levels_2005-2026.csv`) and reservoir polygons
  (`reservoirs_shapefile/`) that anchor the treatment/control design. Other
  `data/` subfolders are placeholders for third-party inputs that are not
  redistributed here (see Data availability below).
- `results/tables/` and `results/figures/` -- every result table and figure
  produced by the pipeline.
- `manuscript/paper/` -- the Quarto manuscript sources
  (`manuscript.qmd` and per-section `.qmd` files) and the rendered PDF.
- `manuscript/supplementary/` -- supplementary material.
- `manuscript/submission/` -- the journal cover letter.

## Reproducing the analysis

```bash
# R environment
Rscript -e 'renv::restore()'   # installs pinned package versions from renv.lock

# Run the full pipeline
Rscript -e 'targets::tar_make()'

# Render the manuscript
quarto render manuscript/paper/manuscript.qmd
```

`targets::tar_visnetwork()` shows the full dependency graph. Reproducing
targets that depend on third-party raster inputs (CHIRPS/CHIRTS, MODIS,
MapBiomas, CR2 streamflow, ERA5-Land, SRTM) requires downloading those
inputs separately (see below); they are not included in this archive due to
their size.

## Data availability

The reservoir storage records, the derived result tables, and matched-set
metadata are included in this repository. The third-party input datasets
are publicly available from their providers as cited in the manuscript:
CHIRPS/CHIRTS (SPEI-12 forcing and baseline aridity), MODIS MOD16
(evapotranspiration), MapBiomas Chile (land cover), the CR2 network
(streamflow), ERA5-Land (snow water equivalent), SRTM (elevation), and the
DGA reservoir, watershed, water-rights, and well-hydrograph registries.
`config/data_sources.yml` documents the format and structure of each source
as used by the pipeline.

## Citation

If you use this code or data, please cite the archived version on Zenodo
(DOI: https://doi.org/10.5281/zenodo.21052149) and the associated manuscript.

## License

This work is licensed under a
[Creative Commons Attribution 4.0 International License](LICENSE)
(CC BY 4.0).

## Contact

Francisco Zambrano Bigiarini ([ORCID 0000-0001-6896-8534](https://orcid.org/0000-0001-6896-8534))
