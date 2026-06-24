# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Repository status (2026-06):** This is a freshly scaffolded research repo. The only real data present is reservoir storage (`data/raw/reservoirs/`); `src/`, `targets/`, `config/`, `notebooks/`, and `manuscript/` are empty placeholders. The commands and architecture below describe the *intended* workflow defined by the toolchain choices — implement them as the project grows rather than assuming they already run.

## Project Identity

Project: Reservoir Effectiveness and Drought Vulnerability in Chile

Target Journal:
Nature Water

Secondary Targets:

* Water Resources Research
* Nature Communications
* Environmental Research Letters
* Hydrology and Earth System Sciences
* Journal of Hydrology

Principal Investigator:

Francisco Zambrano Bigiarini

Research Domains:

* Drought
* Hydrology
* Socio-hydrology
* Remote Sensing
* Climate Change Adaptation
* Water Resources
* Agricultural Water Management

---

# Core Scientific Question

Do reservoirs reduce drought impacts, or do they primarily delay impacts while increasing long-term vulnerability through expansion of water-dependent land uses?

The objective is NOT to evaluate engineering performance of reservoirs.

The objective is to understand how reservoirs modify drought propagation and socio-hydrological feedbacks.

---

# Main Hypothesis

Reservoirs provide short-term buffering against meteorological drought but may increase long-term vulnerability through induced demand and expansion of irrigated agriculture.

Expected pathway:

Meteorological Drought
→ Hydrological Drought
→ Reservoir Storage Dynamics
→ Water Availability
→ Agricultural Expansion
→ Ecological Response
→ Long-term Vulnerability

---

# Study Area

Chile

Period:

2005-present

Spatial Unit:

Watersheds

Treatment:

Watersheds containing major reservoirs.

Control:

Matched watersheds without reservoirs.

---

# Scientific Philosophy

Always prioritize:

1. Causal inference over correlation.
2. Mechanistic understanding over descriptive statistics.
3. Generalizable findings over local case studies.
4. Novelty over incremental improvements.
5. Scientific rigor over positive results.

The goal is to produce a paper that can influence international understanding of reservoir impacts under climate change.

---

# Programming Languages

Primary Language: R

Secondary Language: Python

Preferred allocation:

R:

* data analysis
* statistics
* causal inference
* visualization
* manuscript tables
* reproducible workflows

Python:

* geospatial preprocessing
* machine learning
* Earth Engine exports
* large raster operations
* deep learning if needed

Never rewrite a stable R workflow in Python without a clear advantage.

Favor R whenever both languages are equally suitable.

---

# Preferred R Ecosystem

Data:

* data.table
* dplyr
* tidyr
* arrow

Spatial:

* sf
* terra
* exactextractr
* stars

Hydrology:

* hydroGOF
* lfstat
* SPEI
* zoo

Statistics:

* fixest
* MatchIt
* WeightIt
* cobalt
* marginaleffects
* brms
* mgcv

Visualization:

* ggplot2
* patchwork
* cowplot
* ggtext

Reproducibility:

* targets
* renv
* quarto

---

# Preferred Python Ecosystem

* xarray
* rioxarray
* geopandas
* rasterio
* numpy
* pandas
* scikit-learn
* pytorch
* earthengine-api

Python should primarily support remote sensing workflows.

---

# Expected Data Sources

Hydroclimate:

* CHIRPS
* ERA5-Land
* TerraClimate

Drought:

* SPI
* SPEI
* EDDI

Vegetation:

* MODIS NDVI
* MODIS EVI

Water Use:

* ET products
* Irrigated area maps

Land Cover:

* Landsat
* Sentinel
* Dynamic World
* National datasets

Reservoirs:

* Reservoir storage records
* Reservoir capacity
* Reservoir operating information

---

# Priority Analyses

## Tier 1

Reservoir buffering effects.

Questions:

* Do reservoirs delay drought propagation?
* Do reservoirs reduce drought intensity?
* How much buffering occurs?

Methods:

* lag analysis
* cross-correlation
* transfer entropy
* event-based analysis

---

## Tier 2

Demand expansion.

Questions:

* Did reservoirs facilitate agricultural expansion?
* Did reservoirs increase vegetation water consumption?
* Did irrigated areas expand faster in dammed basins?

Methods:

* land-cover trajectories
* ET trends
* irrigation mapping

---

## Tier 3

Causal inference.

Questions:

* What is the treatment effect of reservoirs?

Methods:

* propensity score matching
* difference-in-differences
* synthetic controls
* Bayesian causal models

Always seek a defensible counterfactual.

---

# Novelty Filter

Before proposing any analysis, ask:

1. Has this been done before?
2. Would a Nature Water reviewer consider it novel?
3. Does it improve causal understanding?
4. Does it challenge conventional assumptions?
5. Can it influence water policy?

If at least three answers are not "yes", redesign the analysis.

---

# Figure Standards

All figures must be publication quality.

Target style:

* Nature Water
* Nature Communications
* Science

Avoid:

* unnecessary 3D graphics
* rainbow color scales
* cluttered panels
* excessive text

Every figure should communicate one key message.

---

# Writing Standards

Write as a Nature-family journal author.

Avoid:

* descriptive narratives
* excessive methodological detail in Results
* unsupported claims

Prioritize:

* concise arguments
* strong quantitative evidence
* uncertainty communication
* mechanistic interpretation

Every result should answer:

"So what?"

---

# Reviewer Simulation

For every major result:

Generate:

1. Reviewer criticism.
2. Alternative explanations.
3. Robustness tests.
4. Additional analyses needed.

Assume Reviewer #2 is skeptical and statistically sophisticated.

---

# Success Criteria

The project succeeds if it produces evidence capable of answering:

"Do reservoirs create resilience or merely postpone vulnerability during prolonged drought?"

All analyses should contribute directly to answering this question.

---

# Repository Architecture

The repo separates **code** (`src/`), **orchestration** (`targets/`), **inputs** (`data/`, `config/`), **outputs** (`results/`, `manuscript/`), and **reasoning** (`docs/`, `agents/`, `workflows/`).

- `src/R/` and `src/python/` hold reusable functions only, organized by analysis stage (`data_ingestion`, `preprocessing`, `drought`, `reservoirs`, `vegetation`, `landuse`, `matching`, `causal`, `statistics`, `visualization`, `utils`). The R/Python split mirrors the language-allocation rules above: R drives analysis/stats/causal/figures; Python handles Earth Engine exports, large rasters, and ML.
- `targets/` is the execution backbone. `_targets.R` defines the dependency graph; `targets/functions/` and `targets/pipelines/` hold the pipeline glue that calls into `src/`. **The targets pipeline — not scripts run by hand — is the source of truth for what produced any result.** Nothing in `results/` should exist without a corresponding target.
- `config/*.yml` is the single source of truth for study parameters — `study_period.yml`, `variables.yml`, `watersheds.yml`, `reservoirs.yml`, `figure_settings.yml`. Read these rather than hard-coding dates, basin IDs, or reservoir lists in functions.
- `data/` flows one direction: `raw/` (immutable inputs, never write here) → `interim/` (intermediate) → `processed/` (analysis-ready) → `metadata/`. `data/raw/` subfolders map to the data sources listed above.
- `notebooks/` is for exploration and is *not* part of the reproducible path; promote validated logic into `src/` + `targets/`. `archive/` and `notebooks/archived/` hold deprecated work — do not revive without reason.
- `manuscript/paper/` is a Quarto project (`manuscript.qmd` plus per-section `.qmd` files and `references.bib`); figures/tables flow from `results/` into `manuscript/`.

# Data Conventions

The reservoir storage file (`data/raw/reservoirs/reservoirs_levels_2005-2026.csv`):

- **Comma-delimited, UTF-8.** Standard `read.csv`/`fread` defaults work.
- **Wide layout** — one row per reservoir (26 total), keyed by `embsalse`, `ID_DGA`, `ID_IDE`, plus a **`max_level_hm3`** capacity column (4th), then one storage column per month from `2005-01-01` to `2026-04-01`. Pivot to long format before time-series work.
- **Storage and capacity share units (hm³)**, so percent-of-capacity = `value / max_level_hm3` is directly computable — this is the cross-reservoir-comparable quantity; raw levels are not comparable across reservoirs. `Rungue` has a blank `max_level_hm3` (no capacity → drop or impute).
- The header has a long run of **trailing empty columns** (padding commas); drop the all-`NA` columns after reading.
- Most commissioning dates are **left-censored**: ~21 of 26 reservoirs report from 2005-01 (built before the panel); only ~5 switch on within it. A staggered-adoption event study on commissioning therefore has very few events — see `docs/hypotheses/` for the causal-design implications.

`data/raw/reservoirs/reservoirs_shapefile/Embalse_2026_05_31.shp` holds the reservoir polygons (join to the level table via the reservoir IDs). Reservoir levels and watershed boundaries are the spatial backbone for the treatment/control matching.

Drought indices (SPI/SPEI/EDDI) live on an external drive, registered in `config/data_sources.yml` — note the `chir[p|t]s` filename quirk documented there (literal brackets are glob metacharacters).

# Toolchain & Commands

Reproducibility stack: **renv** (R packages) + **targets** (R pipeline) + **Quarto** (manuscript) + **conda/pip** (Python).

```bash
# R environment (run inside R, from repo root)
renv::restore()            # install pinned R packages from renv.lock
renv::snapshot()           # record new R deps after adding a package

# Pipeline (R)
targets::tar_make()        # build everything that is out of date
targets::tar_make(name)    # build/refresh a single target (the "run one test" equivalent)
targets::tar_visnetwork()  # inspect the dependency graph and stale targets
targets::tar_read(name)    # load a built target's value into the session

# Manuscript
quarto render manuscript/paper/manuscript.qmd

# Python environment (geospatial / EO / ML)
conda env create -f environment.yml     # or: pip install -r requirements.txt
```

There is no test suite or linter configured yet; if adding one, document it here.

# Specialized Subagents

Seven domain agents live in `.claude/agents/` and encode the project's review standards. Prefer delegating to the matching agent over reasoning solo on these tasks:

- `drought-propagation-analyst` — standardized indices (SPI/SPEI/SSI), propagation lags, reservoir buffering/attenuation (Tier 1 analyses).
- `reservoir-causal-analyst` — framing reservoirs as a treatment; DiD, matching, synthetic controls, identification threats (Tier 3).
- `eo-drought-landuse-analyst` — Earth observation, vegetation/drought indices, attributing change to drought vs. land-use conversion (Tier 2).
- `statistical-skeptic` — stress-testing any quantitative claim for fallacies, confounders, power, multiple comparisons.
- `hypothesis-challenger` — generating alternative causal mechanisms and disconfirming evidence before committing to a conclusion.
- `nature-water-reviewer` / `nature-water-editor` — peer-review-grade critique against Nature Water novelty, causal-rigor, and policy-relevance standards.

`workflows/*.md` describe the multi-stage pipelines these agents participate in (data → analysis → manuscript → publication).
