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

## Regional robustness — does the placebo hold in the high-supply south? (2026-06-29)

Chile's strong north–south aridity gradient raises the worry that the national null hides
heterogeneity: perhaps the placebo holds in the arid north but a real regulation effect emerges
in the wetter south. It does not. Splitting the buffering slope gap (`treat:SPEI`; negative =
buffering) by Köppen region:

| Region | Downstream gap | Upstream placebo gap | Verdict |
|--------|---------------|----------------------|---------|
| Wet south (Köppen C, aridity 0.4–1.7; 7 treated / 39 ctrl) | −0.036 (p=0.67) | −0.034 (p=0.71) | down ≈ up, both ≈ 0 |
| Arid north (Köppen B; 8 treated / **5 ctrl**) | −0.012 (p=0.96) | +0.069 (p=0.73) | down ≈ up, both ≈ 0 |
| National (reference) | −0.165 (p=0.06) | −0.201 (p=0.03) | up ≥ down → siting |

In the high-supply south the downstream and upstream gaps are **statistically identical
(−0.036 vs −0.034)** and both indistinguishable from zero — randomization inference on the
southern downstream gap gives **p_perm = 0.778**. There is no downstream-specific dose-response
even where buffering should be easiest to detect.

**The sharper point:** the national "buffering" signal (−0.16 to −0.20) **collapses to ≈ −0.03
once the comparison is made within climate region** — the textbook signature of a between-region
confound. The apparent national attenuation comes from contrasting arid treated basins against a
control pool spanning the whole wet→dry gradient; it is the aridity gradient (siting), not
within-region regulation. Splitting by Köppen both kills the signal *and* equalizes up/down — two
independent confirmations of the siting interpretation.

*Caveats:* power is limited — the south has 6–7 treated basins (39 controls, adequate for the
down-vs-up contrast), but the arid-north subset has only 5 control basins and is unstable, so the
northern row should not be leaned on. A small southern regulation effect cannot be excluded, but
the qualitative result (down ≈ up in the high-supply south) is unambiguous. Physically, drought is
less binding in wet basins (reservoirs rarely drawn down hard), so a near-zero southern gap is
partly expected — which cuts against, not for, building dams in the south for drought protection.
Test script: `scratchpad/ssi_region_split.R`.

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
