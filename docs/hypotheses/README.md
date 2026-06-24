# Research Hypotheses — Reservoir Effectiveness & Drought Vulnerability in Chile

Generated 2026-06-23 by the `hypothesis-generator` agent; H1 and H2 subsequently
stress-tested by the `hypothesis-challenger` agent (see
[`challenge-findings.md`](challenge-findings.md)).

## Core question

Do reservoirs reduce drought impacts, or do they primarily **delay** impacts while
increasing long-term vulnerability through expansion of water-dependent land uses?

## Retained hypotheses (all clear the >8 Nature Water bar)

| ID | Short name | Overall | Role |
|----|------------|---------|------|
| [H2](H2-induced-demand.md) | Induced demand erases the buffer | **9.4** | **Central narrative** — most publishable |
| [H1](H1-storage-rectifier.md) | Storage as a drought-signal rectifier | 8.8 | Mechanism — **most transformative** |
| [H4](H4-ecological-lockin.md) | Ecological lock-in (resistance vs. resilience) | 8.3 | Ecological consequence |
| [H3](H3-spatial-displacement.md) | Spatial displacement of vulnerability | 8.1 | Robustness/decomposition — **most risky** |

## Recommended paper arc

1. **H2** establishes the headline socio-hydrological finding (reservoirs trade
   short-term protection for induced-demand vulnerability), quantified at national scale.
2. **H1** supplies the physical mechanism for *why* the eroded buffer fails
   catastrophically rather than gracefully (threshold rectification → tail amplification).
3. **H4** demonstrates the ecological cost (resilience loss), closing the pathway
   *Meteorological → Storage → Demand → Ecology → Vulnerability*.
4. **H3** pre-empts the skeptical reviewer by checking whether the apparent effect is
   spatial accounting.

**Single message:** *Reservoirs in Chile postpone and concentrate drought vulnerability
rather than reducing it.*

## Cross-cutting threats (must be resolved before any causal claim)

- **Endogenous reservoir siting/timing** — dams are built where demand/aridity is high;
  all four hypotheses depend on the matching / synthetic-control / heterogeneity-robust
  DiD design holding.
- **2010–present mega-drought** is collinear with the treatment clock — the single
  largest confound for H1 and H2 (a monotone decline in protection is expected from
  hydrological exhaustion alone).
- **Drought-vs-land-conversion attribution** in NDVI/ET must be settled before H2/H4.
- **n ≈ 26 reservoirs** caps generalizability — frame as "Chile as natural laboratory."

## Data-state caveat (2026-06)

Only reservoir storage (`data/raw/reservoirs/`) is real; all other `data/raw/*` are
empty placeholders. Every test below is **contingent on data acquisition**. The storage
series is a **relative index, not volume** (reservoir-specific ceilings) — it must be
converted to percent-of-capacity before any cross-reservoir or "remaining slack"
computation.

## Next steps

- [ ] Acquire and audit hydroclimate / EO / land-cover / operating-rule datasets.
- [ ] Normalize storage to percent-of-capacity.
- [ ] Hand H2 and H1 to `reservoir-causal-analyst` for identification design.
- [ ] Win the **mediation gate** (H2) and the **counterfactual-overshoot test** (H1)
      before committing either to the manuscript.
