# H1 — Storage as a Drought-Signal Rectifier (Attenuation-then-Amplification)

> **Role:** Mechanism section / most transformative. **Overall Nature Water score: 8.8.**
> Adversarial review: [`challenge-findings.md`](challenge-findings.md#h1).

## Hypothesis statement

Reservoirs do not merely attenuate drought signals; they act as nonlinear **rectifiers**
that compress short, moderate droughts but, beyond a storage-depletion threshold, abruptly
transmit an amplified and lagged drought signal to the vegetation/ET system — producing a
**heavier-tailed** distribution of severe ecological drought in dammed basins than in
matched undammed basins.

## Mechanism

While storage is above a critical fraction of capacity, releases decouple downstream water
availability from meteorological deficits (attenuation). Once cumulative inflow deficit
drains storage past a threshold, releases collapse toward inflow and the *backlog* of
suppressed deficit is released at once. The buffer converts many small shocks into rare,
large ones — a variance-shifting (not variance-reducing) operation. Vegetation established
under the buffered regime then experiences a shock larger than it would under natural
variability. This is a regime-switching, threshold-nonlinear response, not a linear lag.

## Three separable claims

- **C1** — a threshold `s*` exists in the storage→ecological-drought transfer function.
- **C2** — the mechanism is *variance redistribution into the tail*, not mere loss of
  buffering (the novel, fragile claim).
- **C3** — this yields heavier tails in dammed vs. matched control basins.

## Why it is novel

Existing propagation literature treats reservoirs as low-pass filters that smooth and delay
drought (linear attenuation). H1 asserts the filter is nonlinear and **state-dependent**,
and that its long-run effect on the *tail* of the ecological-drought distribution can be
adverse. Reframing buffering as variance redistribution rather than reduction is the
conceptual contribution.

## Required data

Reservoir storage (monthly) and capacity (for fractional storage / depletion thresholds);
SPI/SPEI/EDDI per basin; MODIS NDVI/EVI and ET as ecological-drought outcomes; watershed
boundaries; matched undammed controls. **Reservoir operating rules / rule curves** are
needed to show the threshold is physical, not policy.

## Statistical test

- Per-basin TAR / Markov-switching regressions of downstream vegetation-drought anomaly on
  meteorological index, with storage fraction as the threshold variable.
- Compare conditional variance and tail behavior (quantile regression τ=0.05/0.95; GPD fit
  to severity exceedances) dammed vs. matched controls.
- Hierarchical Bayesian model (`brms`) pooling 26 reservoirs with basin random effects to
  estimate the threshold and its uncertainty. Estimand: difference in the **upper-tail**
  severity, not the mean.

## Potential falsification

Rejected if dammed basins show equal/lower conditional variance and lighter (or equal)
tails across the storage-depletion threshold, with no identifiable threshold.
**Most decisive falsifier (counterfactual-overshoot test):** if, below `s*`, dammed-basin
ecological-drought severity does *not* exceed the meteorology-only counterfactual (and does
not exceed matched controls beyond what their forcing predicts), H1 collapses to "buffering
simply stops" or "common meteorological cause" — the rectifier claim dies.

## Nature Water score

| Novelty | Significance | Generalizability | Policy relevance | **Overall** |
|---------|-------------|------------------|------------------|-------------|
| 9 | 9 | 8 | 9 | **8.8** |
