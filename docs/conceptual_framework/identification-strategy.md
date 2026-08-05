# Causal Identification Strategy

Designed 2026-06-23 by the `reservoir-causal-analyst` agent, serving hypotheses
[H2 (central)](../hypotheses/H2-induced-demand.md) and
[H1 (mechanism)](../hypotheses/H1-storage-rectifier.md), and answering the threats raised
in [`challenge-findings.md`](../hypotheses/challenge-findings.md).

## Guiding principle

**Never identify off calendar time.** The 2010–present mega-drought is collinear with the
treatment clock, so any effect estimated on *levels* or *years-since-dam* is mostly the
drought, not the dam. The defensible spine is a **forcing-conditioned, dose-response,
dammed-vs-matched-control design that estimates effects on the deficit→impact *response
function*** (the slope of impact on meteorological deficit), not on outcome levels.

## Data facts that reshape the design (verified in the actual files)

- The storage CSV is **comma-delimited** and includes **`max_level_hm3`** (capacity), so
  **percent-of-capacity = `value / max_level_hm3` is computable today** — the cross-reservoir
  normalization the challenger flagged is solved (drop `Rungue`, no capacity).
- **Commissioning is largely left-censored:** ~21/26 reservoirs report from 2005-01; only
  ~5 switch on within the panel (Ralco/Panque ~2006, Convento_Viejo ~2009, Aromos ~2010,
  El_Bato ~2013), several hydropower, and the irrigation switch-ons commission *at
  mega-drought onset*. ⟹ A commissioning event study cannot be the **primary** design;
  it survives only as corroboration.
- The H2 mediator (irrigated area/land cover) and the H1 outcome (NDVI/ET) are **not yet on
  disk**, so the central tests are gated on data acquisition.

## Estimands

- **H2 (mediation):** the **natural indirect effect (NIE)** of storage reliability on net
  basin drought protection operating *through* cumulative irrigated-area/ET expansion, vs.
  the **natural direct effect (NDE)**. H2 ⇔ NIE is the dominant negative component once
  forcing is conditioned out.
- **H1 (tail):** the causal effect of being below the critical storage fraction `s*` on the
  **upper-tail severity** of ecological drought (conditional quantile / exceedance
  probability), dammed vs. matched control, **conditional on meteorological deficit**. A
  *distributional* contrast, not a mean.

## Treatment definition (three layers)

1. **Cross-sectional binary** — dammed vs. undammed basin (for the matched contrast).
2. **Continuous dose** — capacity-per-command-area (hm³/ha; time-invariant ⟹ orthogonal to
   the drought clock — the cleanest lever for breaking T1) and an early-period (2005–2009)
   storage reliability regime (the H2 "perceived risk" treatment).
3. **State/regime** — storage fraction relative to an *estimated* threshold `s*`
   (segmented/changepoint regression), to be tested against the operating rule curve.

## Control / counterfactual

- **Match on the pre-2010 drought-response slope** (SPEI→impact sensitivity, estimable from
  the 1991–2009 index record), not on levels — this is the credible parallel-trends analogue.
- With n≈26 and spatial clustering, prefer **synthetic control / generalized SCM**
  (`tidysynth`, `scpi`, `gsynth`/`augsynth`) with ~19 years of monthly pre-fit and
  **placebo/permutation inference**, over fragile propensity matching. Entropy balancing
  (`WeightIt`) on the pre-period slope as a robustness alternative.
- **SUTVA:** define controls as *not downstream of any reservoir*; exclude an interference
  buffer; test a spatial-spillover term; flag water-market cross-basin reallocation as
  residual contamination.

## Breaking the mega-drought confound — four orthogonal levers

1. **Condition on forcing, estimate the slope.** Outcome = deficit→impact transmission
   coefficient. Exhaustion shifts the *intercept*; induced demand / rectification change the
   *slope and higher moments*.
2. **Within-drought-year cross-sectional dose-response.** Holding the year (forcing) fixed,
   does decay scale with storage slack / capacity-per-command-area? Forcing-orthogonal;
   calendar time cannot mimic it. Implement as deficit × dose with year fixed effects.
3. **Dammed vs. matched-control DiD-in-slopes** — nets out the common shock.
4. **Pre-period / placebo slopes (1991–2009)** — dammed-vs-control gap should be ~0;
   in-time placebo "commissioning" dates should yield null effects.

## H2 mediation (the load-bearing test)

Potential-outcomes mediation (Imai/VanderWeele): mediator model (irrigated area ~ dose +
forcing + covariates) and outcome model (protection ~ dose + mediator + dose×deficit +
forcing), decomposed into NDE/NIE via **Bayesian `brms`** with basin partial pooling
(cross-checked with `mediation`/`CMAverse` + bootstrap).

- **Sequential-ignorability defense:** condition on pre-2010 irrigated-area trend and
  soil/topography; report **sensitivity to an unobserved mediator-outcome confounder**
  (`medsens` ρ\* / E-value) — "the indirect effect survives confounding up to ρ\*".
- **Pre-registered falsifier:** if, after conditioning on cumulative SPEI forcing, the **NIE
  through expansion is indistinguishable from zero** while the forcing term captures the
  protection decline, induced demand is rejected (the buffer eroded from exhaustion, not demand).

## H1 — beating the three impostors (distributional analysis)

Model the full conditional distribution (`qgam`/`quantreg`, distributional `brms`):

- **vs. "buffering simply stops":** test whether *scale/shape* (not just location) change
  across `s*`. Mean shift alone ≠ H1.
- **vs. common meteorological cause:** the dammed-minus-control tail contrast must be
  non-zero *at the same SPEI quantile*.
- **vs. operating-rule threshold:** overlay estimated `s*` on documented rule curves; H1
  survives only if amplification is sharper than the rule-curve cutback or `s*` ≠ a trigger.
- **Honest power:** the severe tail is essentially **one episode (2019–2022)**. Frame as a
  cross-sectional within-super-drought contrast with permutation inference, *not* a
  stationary extreme-value estimate. Use 1998–1999 as weaker additional tail draws.

## Estimators & why not naive TWFE

| Role | Estimator (R) | Key diagnostic |
|------|---------------|----------------|
| Primary counterfactual | SCM / GSC (`tidysynth`, `scpi`, `gsynth`, `augsynth`) | pre-2010 RMSPE; in-space/in-time placebos; leave-one-donor-out |
| Forcing-conditioned dose-response | `fixest::feols`, deficit×dose, year+basin FE | slope-vs-intercept separation; wild-cluster bootstrap (`fwildclusterboot`) |
| Matching alternative | `WeightIt` entropy balancing + `cobalt` | balance on pre-2010 *slope*, not levels |
| H2 mediation | `brms` NIE/NDE + `marginaleffects` | `medsens`/E-value; posterior predictive checks |
| H1 tail | `qgam`/`quantreg`, distributional `brms` | permutation inference; shape-parameter contrast |
| Commissioning event study (secondary) | Callaway–Sant'Anna (`did`), Sun–Abraham (`sunab`) | pre-trend leads — caveat: ~5 events, drought-onset confound |

**Not naive TWFE:** staggered/heterogeneous dynamic effects ⟹ negative weights and
forbidden comparisons (Goodman-Bacon, de Chaisemartin–D'Haultfœuille); the treatment clock
is collinear with the drought; left-censoring leaves no clean within-set control.

## Sequenced plan

- **Phase 0 — data hygiene (now):** parse CSV, compute percent-of-capacity, decide on Rungue,
  build basin-month SPI/SPEI/EDDI via zonal stats (handle the `chir[p|t]s` filename quirk).
- **Phase 1 — T1-breaking foundation (now, data in hand):** propagation lag / best timescale;
  per-reservoir deficit→storage/availability slopes; estimate `s*`; run Lever 2 (dose-response)
  and Lever 4 (1991–2009 placebo). **This is the paper's executable spine.**
- **Phase 2 — gated on watershed boundaries + streamflow:** define basins; SCM matched
  controls; streamflow as a vegetation-independent availability outcome.
- **Phase 3 — gated on MODIS NDVI/EVI + ET:** ecological-drought outcomes; H1 tail analysis.
- **Phase 4 — gated on land-cover/irrigated-area (+ rule curves):** the H2 mediation test;
  H1 operating-policy falsification.

**Highest-value acquisition:** an irrigated-area/land-cover time series — without it the
central hypothesis (H2) cannot be tested.

## Top 3 paper-sinking threats & their checks

1. **Mega-drought collinearity** → within-year dose-response (Lever 2) + 1991–2009 placebo
   slopes (Lever 4). If decay is flat in dose and a pre-period gap exists, the causal claim
   fails — say so.
2. **H1/H2 observational equivalence + endogenous siting** → formal NIE/NDE decomposition
   with the pre-registered NIE=0 falsifier; mediator-outcome sensitivity (ρ\*/E-value); match
   on pre-2010 irrigated-area *trend*.
3. **NDVI/ET attribution + SUTVA cancellation** → disaggregate vegetation by land-cover class
   (measure stress on natural cover, greening on irrigated cover separately; never basin-mean
   NDVI alone); not-downstream control definition + interference buffer + spillover sensitivity.
