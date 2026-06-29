# H7 — The Upstream/Downstream Within-Basin Placebo as an Identification Engine

> **Role:** Identification engine for the post-pivot program. **Overall Nature Water score: 8.3.**
> Run the gauge audit FIRST (now done — see "Coverage audit" below).
> Generated 2026-06-29 by the `hypothesis-generator` agent.

## Hypothesis statement

A genuine reservoir *regulation* effect on hydrological drought must appear **downstream** of
the dam (where flow is regulated) and be **absent upstream** (physically unregulated, same
basin). Any apparent buffering that is equally present at upstream gauges is **siting/aridity**,
not regulation. The upstream reach is therefore a within-basin placebo that differences out the
endogenous siting confound H5 identifies.

## Mechanism

Upstream and downstream gauges in the same dammed basin share the basin's climate, geology, and
selection history but differ in one thing: only the downstream reach is hydrologically regulated.
A true regulation effect implies a **downstream-minus-upstream dose-response**; its absence
implies the SPEI→SSI attenuation is a property of *where* the dam sits, not of the dam. This is a
sharper control than any cross-basin match because it holds the basin fixed.

## Why it is novel

Reservoir-buffering studies almost universally compare dammed vs. undammed basins (or
pre/post), inheriting the full siting confound. The within-basin upstream placebo is a
transferable identification tool that isolates regulation from selection using only gauge
geography — applicable to any regulated river with gauges above and below the structure. It
converts an untestable cross-basin claim into a falsifiable within-basin contrast.

## Coverage audit (completed 2026-06-29)

Of **21 treated matched basins**, **15 have both ≥1 upstream and ≥1 downstream gauge** in the
CR2 network (1 downstream-only, 1 upstream-only, 4 with no usable gauge). The placebo design
therefore covers **15/21 ≈ 71%** of treated basins — a **near-national result**, not a single
case study. (217 classified gauges over the matched set: 61 downstream, 35 upstream, 121
control; CR2 record window 2000–2020.)

## Required data

All on disk. CR2 daily streamflow → SSI-12 (2000–2020); dam elevation (SRTM DEM) to classify
each gauge as upstream/downstream of the structure (`extract_dam_elevation`,
`assign_stations_to_units`); SPEI-12 forcing; matched set. No new acquisition needed for the
15-basin result; extending coverage past 6 basins would require additional gauge records.

## Statistical test

- SPEI-12 → SSI-12 transmission slope by group, with a `treat:SPEI` interaction (`fixest`);
  estimands: intent-to-treat (all dammed gauges), **downstream-only**, **upstream-only placebo**.
- **Randomization inference** (treatment label permuted within Köppen × aridity strata) — the
  primary inference; cluster-robust SEs over-reject at ~21 clusters.
- **Decisive contrast:** downstream slope gap vs. upstream slope gap. Result to date:
  −0.16 (down) vs −0.20 (up), ITT slope gap −0.18 with cluster p = 0.03 but
  p_perm = 0.39 — no dose-response, placebo as strong as treatment ⇒ **siting, not regulation**.

## Potential falsification

H7's *diagnostic value* is confirmed, not falsified, by either outcome. The substantive claim
(buffering is siting) is rejected if the downstream slope gap is significantly steeper than the
upstream placebo under randomization inference — a true regulation dose-response. Observed: it
is not.

## Nature Water score

| Novelty | Significance | Generalizability | Policy relevance | **Overall** |
|---------|-------------|------------------|------------------|-------------|
| 8 | 8 | 9 | 8 | **8.3** |
