# H6 — Damming Changes *What Drought Means* (Conditional-Dependence Regime Shift)

> **Role:** Mechanistic upside — **demoted to discussion-only.** **Overall Nature Water score: 7.8 (below the >8 bar).**
> Generated 2026-06-29 by the `hypothesis-generator` agent; demoted 2026-06-29 after the
> storage-recovery dynamics were shown stationary (see
> [`H8-evaporating-buffer-RETIRED`](#status) note in [`README.md`](README.md)).

## Hypothesis statement

Reservoirs do not change the *magnitude* of drought impact (hence the null mean/ATT/DiD
estimates) but change its **conditional dependence structure**: in dammed basins the
meteorological-forcing→outcome coupling (SPEI→ET/vegetation) weakens while a storage→outcome
coupling appears. Damming alters *what variable drought is "about,"* not how severe it is on
average.

## Mechanism

Where flow is regulated, near-term ecological/agricultural water availability is governed by
release decisions and storage state rather than directly by recent meteorology. The
SPEI→outcome elasticity should therefore fall and a storage→outcome elasticity should rise,
relative to unregulated basins — a regime shift in the dependence structure that mean-based
estimators (which average over states) are blind to, explaining the convergent null.

## Why it is novel

It reframes "no effect" as "no *mean* effect but a structural recomposition of dependence,"
a higher-order claim than buffering. If true, it explains *why* every magnitude estimator
returned null and reorients reservoir-impact science from levels to dependence structure.

## Why it is demoted (honest status)

Two load-bearing problems:
1. **Empirical:** the storage→outcome limb requires storage dynamics to be informative beyond
   forcing. The H8 refill test showed storage-recovery is **stationary** — refill efficiency
   does not change over time and within-year amplitude is flat — weakening the premise that a
   storage-governed regime is operationally distinct from a forcing-governed one here.
2. **Data:** the unique, non-collapsible content ("availability rebinds to *allocation*") needs
   **reservoir release / operating-rule data, which is missing** (only a ΔS drawdown proxy is on
   disk). Without it, H6 collapses into H5 whenever the upstream placebo (H7) erases the
   apparent decoupling.

It is retained as a **discussion-section idea and a future-data target**, not a testable spine
hypothesis.

## Required data

On disk: SPEI, storage %, MODIS outcomes, matched set, CR2 SSI. **Missing (gating):** reservoir
release / operating rules; only ΔS drawdown proxy available.

## Statistical test (if release data were obtained)

State-dependent / interaction models contrasting SPEI→outcome and storage→outcome elasticities
in dammed vs. matched-control basins; copula or conditional-dependence estimators rather than
conditional-mean regression; the H7 upstream placebo to confirm any decoupling is regulation,
not siting.

## Potential falsification

Rejected (as a distinct mechanism) if the SPEI→outcome elasticity is statistically
indistinguishable between dammed and control basins, or if any apparent decoupling is equally
present upstream of the dam (H7 placebo) — i.e. it reduces to H5.

## Nature Water score

| Novelty | Significance | Generalizability | Policy relevance | **Overall** |
|---------|-------------|------------------|------------------|-------------|
| 9 | 7 | 7 | 7 | **7.8** |
