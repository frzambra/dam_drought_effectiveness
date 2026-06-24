# H2 — The Reservoir Effect: Induced Demand Erases the Buffer (Maladaptive Equilibrium)

> **Role:** Central narrative / most publishable. **Overall Nature Water score: 9.4.**
> Adversarial review: [`challenge-findings.md`](challenge-findings.md#h2).

## Hypothesis statement

A reservoir's drought-buffering capacity is endogenously consumed by the agricultural
expansion it enables, such that the **net** drought protection of a basin declines toward
zero (or below) within roughly a decade of sustained water availability — a measurable,
national-scale "reservoir effect."

## Mechanism

Reliable storage lowers the perceived risk of irrigation, driving expansion of
irrigated/water-dependent land cover and rising consumptive ET. Demand ratchets up to
track the new supply (induced demand). The buffer that once absorbed deficits is now
committed to a larger irrigated footprint, so the marginal basin has no slack when the
next severe drought arrives. Protection is lost not to hydrology but to behavioral
adaptation — the system relaxes to a higher-demand, lower-resilience equilibrium.

## Why it is novel

The "reservoir effect" (Di Baldassarre et al.) is largely theoretical / case-study based.
H2 makes it quantitatively measurable at national scale by linking storage-era onset to
land-cover/ET trajectories and then showing the buffer's decay using observed drought
outcomes. The contribution is an empirical demand-erosion rate and a test of whether
buffering capacity has a measurable half-life.

## Required data

Land-cover change / irrigated-area maps (Dynamic World, Landsat/Sentinel, national
datasets); MODIS ET and NDVI/EVI; reservoir storage and capacity; SPEI/EDDI; matched
controls; reservoir commissioning/operating information.

## Statistical test

- Irrigated-area and ET trends, dammed vs. matched undammed (trajectory analysis;
  Theil–Sen / Mann–Kendall).
- Difference-in-differences (`fixest`) of drought-outcome sensitivity on
  time-since-storage-availability — does the dammed advantage shrink over time?
- **Mediation:** does cumulative irrigated-area expansion statistically mediate the
  decline in buffering? (the load-bearing test — use `brms`).
- Heterogeneity-robust estimators (Callaway–Sant'Anna / Sun–Abraham), **not** vanilla TWFE.

## Potential falsification

Rejected if dammed basins retain stable/growing buffering over time, if irrigated
area/ET do not expand faster than controls, or if expansion does not mediate the decline.
**Most decisive falsifier:** drought sensitivity worsens over time *but* the indirect
(mediated) effect through irrigated-area/ET expansion is ≈ 0 while the direct effect
dominates → the buffer erodes for hydrological/operational reasons, not behavioral ones.

## Nature Water score

| Novelty | Significance | Generalizability | Policy relevance | **Overall** |
|---------|-------------|------------------|------------------|-------------|
| 9 | 10 | 9 | 10 | **9.4** |
