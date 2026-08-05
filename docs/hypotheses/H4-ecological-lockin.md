# H4 — Ecological Lock-in: Buffering Trades Resistance for Lost Resilience

> **Role:** Ecological consequence. **Overall Nature Water score: 8.3.**

## Hypothesis statement

Reservoir buffering suppresses the vegetation system's exposure to mild-drought "training,"
reducing its recovery capacity (resilience) so that, conditional on a severe drought of
equal meteorological magnitude, dammed-basin vegetation recovers more slowly and shows more
persistent post-drought anomalies than matched undammed-basin vegetation.

## Mechanism

Repeated mild droughts in unbuffered systems select for and maintain drought-tolerant
vegetation and conservative water-use strategies. Buffering removes this stressor, allowing
establishment of higher-water-demand, less drought-adapted vegetation. When a drought
finally exceeds the buffer, this vegetation lacks the physiological/structural acclimation
to recover quickly — a loss of ecological resilience masked by years of apparent stability
(maladaptation / ecological lock-in). Resistance is bought at the price of resilience.

## Why it is novel

Resilience theory (slowing recovery rates, rising autocorrelation as early-warning signals)
has rarely been applied to reservoir-mediated ecosystems at scale. H4 connects
critical-slowing-down / recovery-rate metrics from EO time series to a socio-hydrological
cause, testing resilience-vs-resistance as a measurable trade-off rather than a metaphor.

## Required data

Long MODIS NDVI/EVI time series (recovery-rate and autocorrelation/variance metrics); ET;
SPI/SPEI/EDDI to define equal-magnitude drought events; reservoir storage/capacity; matched
controls.

## Statistical test

- Event-based recovery analysis: for matched-severity drought events, estimate post-trough
  recovery rate (return time to baseline NDVI/EVI), dammed vs. control (survival/recovery-time
  models, mixed effects).
- Resilience early-warning indicators: trends in lag-1 autocorrelation and variance of
  detrended vegetation series, dammed vs. control.
- Couple to storage state to confirm the buffering → recovery-loss pathway.
- Control for land-cover composition to separate species/strategy turnover from physiology
  (this is what distinguishes H4 from H2).

## Potential falsification

Rejected if dammed-basin vegetation recovers as fast as / faster than matched controls
after equal-magnitude droughts, or if resilience indicators do not differ. If recovery
differences are fully explained by land-cover change rather than buffering history, the
lock-in mechanism (as distinct from H2) is falsified.

## Nature Water score

| Novelty | Significance | Generalizability | Policy relevance | **Overall** |
|---------|-------------|------------------|------------------|-------------|
| 9 | 8 | 8 | 8 | **8.3** |
