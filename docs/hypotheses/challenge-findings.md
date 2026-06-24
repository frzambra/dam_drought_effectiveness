# Adversarial Challenge Findings — H1 & H2

Produced 2026-06-23 by the `hypothesis-challenger` agent. Each hypothesis was stress-tested
for confounders, reverse causation, and observationally-equivalent alternative mechanisms.

> **Shared data-reality caveat:** Only reservoir storage is real on disk; all other
> `data/raw/*` are empty placeholders. Storage is a **relative index, not volume** (e.g.
> Santa_Juana 6–166, Lautaro 0–26) — cross-reservoir pooling and any "remaining slack"
> computation are invalid until converted to percent-of-capacity. Every test below is
> contingent on data acquisition.

---

## H2 — Induced demand erases the buffer {#h2}

**Verdict:** The descriptive pattern (net protection declines over time in dammed Chilean
basins) is probably real (~65–75%). The specific **induced-demand mechanism** is currently
**unidentified** (~30–40%). Promising, but **not yet defensible** as a Nature Water anchor.

### Strongest threats
| # | Threat | Why it bites |
|---|--------|--------------|
| T1 | **Mega-drought collinear with treatment clock** | A monotone decline in protection is exactly what progressive *hydrological exhaustion* produces with zero induced demand. The make-or-break confound. |
| T2 | Endogenous placement/timing | Dams sited where irrigation already existed/was planned → observed expansion is the *reason* for the dam, not its consequence. Matching on levels ≠ matching on trends. |
| T3 | NDVI/ET attribution is sign-confounded | Drought lowers NDVI/ET; irrigation raises it — they cancel in basin aggregates. |
| T4 | SUTVA violations | Upstream effects on controls; water-market reallocation across basins; spatial clustering of treated basins. |
| T5 | Measurement/structural artifacts | Relative-index storage; MODIS saturation in arid cover; "net protection" is a researcher degree of freedom inviting specification search. |
| T6 | Regression-to-mean + drought-triggered construction | Dams funded after scarcity → artificial early "buffer" that later "normalizes." |
| T7 | TWFE forbidden comparisons | Naïve two-way FE can flip sign via bad weighting under staggered adoption. |

### Alternative mechanisms (reproduce "buffer erodes" without induced demand)
- **A1 Pure hydrological exhaustion** — supply collapsed, demand flat/declining.
- **A2 Reverse causation / endogenous siting** — expansion pre-dates the dam.
- **A3 Regional drought intensification as common cause.**
- **A4 Measurement-artifact erosion** (classifier drift, index scale).
- **A5 Operational/institutional reallocation** — no land-use change at all.
- **A6 Regression to the mean + drought-triggered construction.**

### Most decisive falsifier
Drought sensitivity worsens over time **but** the mediated (indirect) effect through
irrigated-area/ET expansion ≈ 0 while the direct effect dominates → induced demand is
falsified; the buffer eroded for hydrological/operational reasons. The data *can* produce
this (MODIS ET + irrigated-area maps + `brms` mediation) — once acquired.

### Must nail down before anchoring the paper
1. Acquire the data (currently untestable).
2. Convert storage to volume/percent-of-capacity.
3. **Win the mediation gate** (erosion flows *through* expansion, near-zero direct effect).
4. **Separate the two clocks** — condition on local SPEI/EDDI, exploit calendar-staggered
   commissioning, use heterogeneity-robust estimators (never plain TWFE).
5. Show a **post-commissioning slope break** in expansion (rules out reverse causation).
6. Pre-register the definition of "net protection."

> If the mediation gate fails, the honest paper becomes: *"reservoirs delay rather than
> prevent drought impacts via hydrological exhaustion, not induced demand"* — still interesting.

---

## H1 — Storage as a drought-signal rectifier {#h1}

**Verdict:** Confidence the novel mechanism (C2: active tail amplification beyond
loss-of-buffering) is both true **and identifiable from the available data: low (~15–25%)**.
The physics is plausible; the problem is identification and power. **Not yet defensible** as
a mechanism section as framed.

### Strongest threats
| # | Threat | Why it bites |
|---|--------|--------------|
| T1 | **Mega-drought = one shared shock** | Nearly all severe-tail mass across 26 basins comes from *one* correlated episode → not 26 independent tails. Hierarchical pooling does **not** rescue power. |
| T2 | Per-basin GPD under-identified | Few independent exceedances → huge CIs on shape parameter ξ; won't survive episode-level bootstrap. |
| T3 | Regime-switching overfits noise | ~252 autocorrelated months; models *will* find a threshold with a CI spanning most of the storage range. |
| T4 | **Threshold = operating policy** | A detected `s*` is the expected signature of a rule curve / dead storage → confirms policy, not emergent rectification. Deepest conceptual threat. |
| T5 | "Amplification" vs. "buffering stops" not distinguished | Empty-storage floor unmasks the raw meteorological tail without any *added* tail mass. |
| T6 | Storage–meteorology collinearity | Below `s*`, storage and SPEI are nearly collinear → vegetation collapse may be the direct effect of the same deficit. |
| T7 | Selection on variance | Heavier tails may be a pre-existing basin property, not dam-caused. |
| T8 | Measurement error / shoreline artifact | Emptying reservoir exposes bare soil → NDVI drop mechanically correlated with low storage (circular). |

### Alternative mechanisms
- **A1 Buffering simply ceases at empty storage** (mechanical floor — unmasking, not amplification).
- **A2 Induced demand (= H2)** — larger committed footprint collapses; observationally near-identical.
- **A3 Operating-policy artifact** — `s*` = rule-curve breakpoint.
- **A4 Common meteorological cause** — storage→vegetation is a back-door path through climate.
- **A5 EO shoreline artifact** — circular measurement.
- **A6 Heteroskedastic forcing / selection on variance.**

### Most decisive falsifier (counterfactual-overshoot test)
Build the meteorology-only predicted ecological-drought distribution (fit on controls); test
whether dammed-basin severe-tail outcomes **exceed** it specifically below `s*`. H1 requires
strict overshoot; A1/A4 predict convergence. **Power reality check: per-basin almost
certainly not (one episode); weak at best pooled.** The realistic ceiling is a *single
pooled tail contrast over the mega-drought* — a case study dressed as a 26-unit comparison.

### Must nail down before a mechanism section
1. Acquire data — **especially operating rules / rule curves** (else C1/C2 ≡ policy).
2. Define a defensible cross-basin storage-fraction (current data is a relative index).
3. Pass the **counterfactual-overshoot test** (H1's only unique falsifiable content).
4. Show the threshold is **physical, not policy**, and survives **episode-level bootstrap**.
5. Run mediation vs. H2, shoreline-mask, and meteorology-partialling robustness checks.

> Honest publishable form: a **pooled** claim explicitly framed as evidence from the 2010+
> mega-drought (one event), with the per-basin GPD/regime-switching apparatus presented as
> descriptive only — never as 26-unit inferential evidence.

---

## Implication for the paper

Both H1 and H2 are threatened by the **same two confounds** — the mega-drought clock and
endogenous siting — and H1's mechanism is **observationally near-equivalent to H2**. Before
either anchors the manuscript, the `reservoir-causal-analyst` agent should design the
identification strategy that separates: (a) behavioral induced demand, (b) hydrological
exhaustion, (c) operating policy, and (d) common meteorological cause.
