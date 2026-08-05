# H5 — Reservoirs as Markers, Not Makers, of Drought Vulnerability

> **Role:** Central narrative (post-pivot program). **Overall Nature Water score: 9.0.**
> Supersedes the H1–H4 program, which collapsed to a convergent null (see
> [`README.md`](README.md) and [`challenge-findings.md`](challenge-findings.md)).
> Generated 2026-06-29 by the `hypothesis-generator` agent from the convergent-null evidence base.

## Hypothesis statement

A basin's drought vulnerability is set at the **siting/selection** stage, not produced by
reservoir operation. Conditional on the pre-dam covariates that govern where reservoirs are
built (aridity, existing irrigated footprint, hydrogeology, elevation), the **operational
treatment effect of the reservoir brackets zero**. Reservoirs *mark* where water-dependent
vulnerability already concentrated; they do not *make* it.

## Mechanism

Reservoir placement is strongly endogenous: dams are built in arid, already-irrigated,
hydrogeologically distinct basins where water demand is high. That selection — not anything
the reservoir subsequently does — is what differentiates dammed basins from the landscape.
Every operational pathway the program tested (drought-signal buffering, induced agricultural
expansion, tail-rectification, refill degradation) returns null once siting is matched out.
The vulnerability signature is therefore a **fixed property of the selected sites**, present
before and stable through the megadrought, rather than a dynamic consequence of regulation.

## Why it is novel

The literature (and water policy) treats reservoirs as active modifiers of drought risk — the
implicit premise behind "build more dams." H5 inverts this: using a national matched design
plus a within-basin placebo (H7), it shows the modifier effect is observationally absent and
that the apparent effect is selection. A **credibly-estimated, multiply-confirmed null is the
finding** — it reframes reservoirs from instruments of resilience to markers of pre-existing,
siting-determined vulnerability. This directly challenges the conventional storage-expansion
policy and is generalizable wherever dam siting is non-random (i.e., everywhere).

## Required data

All on disk. Reservoir storage + capacity (percent-of-capacity, 2005–2026); matched control set
(entropy balancing within Köppen × aridity on log-area + elevation; 21/24 treated retained);
SPEI/SPEI-EDDI forcing; MODIS zNPP / zcNDVI-6 / SETI ecological outcomes; MapBiomas irrigated
area; CR2 streamflow → SSI (2000–2020); DGA watersheds; dam registry (construction year, use,
size). A direct siting-decision model would be *upgraded* (not unblocked) by water-rights /
capital-allocation records.

## Statistical test

- **Doubly-robust matched ATT** of reservoir presence on each outcome (irrigated-area
  expansion, ET buffering, drought-transmission slope) — all bracket zero (see
  `results/tables/table_main_results.csv`).
- **Equivalence testing** (TOST): formally bound the operational effect within a
  pre-specified negligible region rather than merely failing to reject (see
  `results/tables/table_equivalence.csv`).
- **Forcing-conditioned, randomization inference** within Köppen × aridity strata
  (~21 treated clusters; cluster-robust SEs over-reject — `fwildclusterboot` off CRAN, use
  permutation).
- **H7 within-basin placebo** as the decisive selection-vs-effect discriminator (see
  [`H7-upstream-downstream-placebo.md`](H7-upstream-downstream-placebo.md)).

## Potential falsification

Rejected if a defensible operational effect survives siting adjustment — e.g. a
downstream-specific buffering dose-response that the upstream placebo does **not** reproduce,
or an ATT whose equivalence interval excludes zero. To date no such effect has survived.

## Nature Water score

| Novelty | Significance | Generalizability | Policy relevance | **Overall** |
|---------|-------------|------------------|------------------|-------------|
| 9 | 9 | 9 | 10 | **9.0** |
