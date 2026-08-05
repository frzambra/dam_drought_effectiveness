# Manuscript framing (draft) — the "confound-dissolution" methods paper

**Date:** 2026-06-26 · **Status:** proposed framing for PI review · **Decision pending** (this
vs. acquire a water-availability outcome and aim for a positive socio-hydrology result — see §8).

Distils the 2026-06 results
([forcing-conditioned ATT](../progress_summary/2026-06-26_forcing-conditioned-att.md),
[Catastro orchards](../progress_summary/2026-06-26_catastro-orchards.md),
[matched-controls design](../design/matched-controls.md)) into a defensible paper when the
headline H2 mechanism did **not** survive scrutiny.

---

## 1. One-line thesis

> Widely-reported "reservoirs increase drought vulnerability" signals are largely artefacts of
> two analytical choices — identifying off **calendar-time trends** and off **basin-mean
> greenness** — and a third, **endogenous siting**. We give a three-part diagnostic protocol that
> separates a genuine reservoir effect from these confounds, and show on Chilean reservoirs that a
> strong apparent vulnerability signal **dissolves entirely** once the protocol is applied.

**Working titles**
- *"When reservoir 'vulnerability' is just aridity: a forcing-conditioned, cover-resolved test."*
- *"Three confounds that manufacture reservoir drought-vulnerability signals."*
- *"Don't identify off the drought: a causal-diagnostic protocol for reservoir impact studies."*

## 2. The problem (the gap)

Socio-hydrology and remote-sensing studies routinely infer reservoir impacts on drought by
comparing **outcome trends** (NDVI/NPP/ET decline) in dammed vs. undammed basins, often at the
**basin-mean** grain, over a period dominated by a **single multi-year drought**. In settings like
Chile (2010– megadrought) three things make this fragile, and each pushes the estimate the *same*
(alarming) way:

1. **Mega-drought collinearity.** The drought clock is collinear with the treatment clock, so any
   effect read off *levels* or *calendar trends* is mostly the drought, not the dam.
2. **Baseline-aridity / water-limitation.** Reservoirs sit in arid basins; arid vegetation is
   water-limited and tracks meteorological supply more tightly — a steeper drought response that
   has nothing to do with the dam.
3. **Endogenous siting.** Reservoirs are built in productive-agriculture basins, so cross-sectional
   "more irrigated expansion in dammed basins" can be siting, not a reservoir effect.

The literature rarely tests all three together; doing so is the contribution.

## 3. The contribution — a three-part diagnostic protocol

| # | Diagnostic | Replaces the bad practice | Implementation here |
|---|---|---|---|
| **D1** | **Forcing-conditioning** — estimate the effect on the **deficit→impact response slope** (impact regressed on SPEI), never on calendar-time trends | "outcome declined in dammed basins" | per-basin zNPP~SPEI transmission slope as the matched-ATT outcome |
| **D2** | **Cover disaggregation** — split the slope by **irrigated vs. rain-fed** cover; a real irrigated-demand effect must localise to irrigated land | "basin-mean greenness fell" | MapBiomas strata + **ground-truth Catastro orchard** stratum; aridity² adjustment |
| **D3** | **Siting & timing scrutiny** — left-censoring-aware pre-trends / survival-bias check before any expansion claim | "dammed basins have more irrigated area" | reservoir commissioning years + reconstructed orchard trajectory |

The protocol is general (any reservoir/land-use drought study); Chile is the demonstration.

## 4. The demonstration (results, all established)

**Apparent signal (the trap).** Matched dammed-vs-control ATT on the storage-era **calendar-time
zNPP trend** is significantly negative (−0.024 yr⁻¹) — dammed basins "greening less," the classic
vulnerability read.

**D1 flips it, then D2/D3 dissolve it:**

- **D1 — forcing-conditioning** turns the calendar trend into the deficit→impact slope: ATT
  **+0.33** (dammed basins *more* drought-sensitive). Sign-robust across 10 specifications, **but**
  magnitude 0.11–0.39 and **collapses to 0.11 under nonlinear aridity** — the first warning.
- **D2 — cover disaggregation** locates the effect in **rain-fed/natural** vegetation
  (ATT 0.36, tracks aridity r=−0.53, →0.13 under aridity²), while **ground-truth irrigated
  orchards show a clean null** (ATT 0.06, ns). The "vulnerability" is a water-limitation confound
  on natural cover, **not** the irrigated-demand mechanism it was read as.
- **D3 — siting/timing.** Dammed basins do have ~2–15× more irrigated orchard area (expansion ATT
  significant), but 13/21 reservoirs are commissioned pre-1990 (no pre-treatment period), the
  treated/control orchard ratio *shrinks* 3.3×→1.7× (1990→2024), and survival bias corrupts the
  reconstructed trajectory — so the association is **siting**, not a reservoir effect.

**Net:** a strong, publishable-looking reservoir vulnerability signal exists at face value and
the *irrigated-demand* reading of it survives none of the three diagnostics. That is the paper.

**Two precision caveats (hypothesis-challenger, 2026-06-26; the residual one now resolved):**
- A **0.127 natural-cover residual survives aridity²** (CI excludes 0). The hypothesis-challenger
  flagged it might be a genuine reservoir effect on natural/riparian vegetation. **The pre-2010
  PLACEBO settles it: the gap is present — and larger — *before* the megadrought (0.483 pre vs
  0.408 during), so it is a pre-existing, drought-independent confound, NOT a reservoir effect.**
  Safe framing: "the irrigated-demand vulnerability signal dissolves; the residual is a fixed
  baseline-aridity difference, confirmed by a pre-period placebo." Avoid the bare "dissolves
  entirely" — say "is fully attributable to aridity + pre-existing differences."
- The **irrigated null is not positive evidence of absence** — irrigation-decoupling predicts that
  null whether or not H2 is true. Cite it as "no detectable effect where one was predicted," not
  "proof of no effect." **The ET-buffering follow-up (MOD16 500 m, `att_et_buffering`) resolves the
  grain worry and sharpens the reading:** irrigated orchard ET is nearly insensitive to drought in
  *both* dammed and control basins (strong buffering), but the dammed-vs-control buffering ATT is
  null — **reservoirs add no detectable ET buffering beyond what irrigated agriculture already gets
  from other water sources.** So the irrigated null is now backed at adequate resolution, not just
  a grain artefact. (Earlier "need 30 m ET" was wrong — that was the SETI *product's* 5.5 km, not a
  fundamental ET-resolution limit; native MOD16 at 500 m suffices for an aggregated orchard signal.)

## 5. Proposed structure

- **Abstract** — the trap, the protocol, the dissolution, the general lesson.
- **Intro** — reservoirs & drought in socio-hydrology; the three confounds; why Chile is the
  cleanest natural experiment to expose them.
- **Methods** — matched/weighted controls (entropy balancing within Köppen); D1 forcing-conditioned
  response slope; D2 cover strata incl. the Catastro ground-truth irrigated layer; D3 commissioning
  + survival-bias diagnostics; doubly-robust estimation; the robustness battery.
- **Results** — the four-step narrative of §4 (apparent signal → D1 → D2 → D3), one figure each.
- **Discussion** — what a *credible* reservoir effect would require; implications for the dozens of
  basin-mean trend studies; the resilience-vs-postponed-vulnerability question remains open and
  needs a water-availability outcome (NPP is blind to it).

**Key figures (each one message)**
1. The trap: calendar-trend ATT (negative) vs forcing-conditioned ATT (positive) — same data.
2. Robustness ladder: forcing-conditioned ATT across 10 specs; the aridity² collapse.
3. The dissolution: ATT by cover stratum (natural vs ground-truth orchard) ± aridity².
4. Siting: treated/control orchard-area ratio over time + the left-censoring of commissioning.

## 6. Target journal — honest positioning

A rigorous **null/cautionary methods** paper is a weaker fit for **Nature Water** (which favours
positive mechanistic advances) than for venues that reward methodological correction:

- **Best fit:** *Water Resources Research*, *Hydrology and Earth System Sciences*, *Environmental
  Research Letters*, *Geophysical Research Letters* (methods + cautionary demonstration).
- **Nature Water / Nature Communications** become realistic **only** if paired with a positive
  result — i.e., add the water-availability outcome (§8) so the paper both *debunks* the spurious
  ecological signal **and** *establishes* a real (or real-null) availability effect.

Recommendation: draft for WRR/ERL now; hold Nature-family for the combined paper if the streamflow
outcome lands.

## 7. Reviewer simulation (anticipate Reviewer #2)

- **"A null result isn't novel."** → The novelty is the *protocol* + showing a *specific, strong,
  intuitive* signal is spurious for *diagnosable* reasons that generalise — not "we found nothing."
  Frame as confound-dissolution, not absence of evidence.
- **"zNPP is too coarse to see irrigated orchards (≈1 km)."** → Acknowledged and turned into a
  result: even the ground-truth orchard mask gives a null, and the natural-cover effect is large —
  the grain limit cannot manufacture the *natural*-cover signal, which is the one we attribute to
  aridity. Still, state it as a limitation and motivate finer ET/streamflow outcomes.
- **"Your expansion ATT *is* the H2 effect."** → D3 shows it is siting-confounded and
  left-censored; we explicitly *decline* the causal claim. That restraint is the point.
- **"Entropy balancing on few covariates."** → Report the robustness battery (CEM/NN, aridity²,
  timescale/lag); the conclusion is invariant.
- **"Survival bias in the cadastre."** → Used only for a *relative* treated-vs-control diagnostic
  and explicitly flagged as disqualifying for timing inference — we do not over-reach.

## 8. The decision this framing forces

Two coherent paths:

- **(A) Methods/cautionary paper now** (this framing) — WRR/ERL, self-contained on data in hand.
- **(B) Hold for the positive companion** — acquire DGA streamflow → a water-availability /
  hydrological-drought outcome (SSI), test whether reservoirs buffer *availability* (where NPP is
  blind), and publish debunk + finding together for a Nature-family venue.

Both rest on the same completed analysis. (A) ships sooner and is low-risk; (B) is higher-ceiling
but gated on data acquisition. **Open question for the PI.**

---

*Once a path is chosen, populate `manuscript/paper/{introduction,methods,results,discussion}.qmd`
from §5 and wire Figures 1–4 from the existing targets (`dr_att`, `dr_att_forcing`,
`dr_att_forcing_robustness`, `dr_att_forcing_orchard`, `expansion_pretrends`).*
