# Figure Review: "Dams mark drought vulnerability rather than buffer it"

**Target journal:** Nature Water
**Reviewer:** nature-water-editor agent
**Date:** 2026-06-30
**Scope:** The four existing figures in `manuscript/paper/results.qmd` plus recommendations for new figures.

Files reviewed: `manuscript.qmd`, `introduction.qmd`, `methods.qmd`, `results.qmd`, `discussion.qmd`, and the four PNGs under `results/figures/` (`fig_area_did.png`, `fig_convergent_null.png`, `fig_streamflow.png`, `fig_storage_band.png`).

---

## Headline judgment on the figure set

The four existing figures are competently made and each carries a single message, which is the right instinct. But as a set they document the result and skip the design. A null paper is bought or rejected on whether the reader trusts the matched counterfactual, and right now there is no figure that shows the study geography, the covariate balance, or the drought forcing. Three of your most persuasive arguments (the matching quality, the siting-confound shrinkage, and the within-region collapse) live only in prose. A skeptical reviewer cannot see the design, so the burden falls entirely on text. That is the binding constraint on the figure package, more than any single panel's flaws.

---

## 1. Figure-by-figure critique

### Fig 1 — fig-area (`fig_area_did.png`): irrigated-area null

**Message:** Clear and correct ("reservoirs mark, not make, irrigated area"). Panel b (event study) is the right causal object; panel a sets up the level gap and parallel trajectories.

**Problems and fixes:**

- **Panel a y-axis starts at 2, not 0.** On a level comparison this visually inflates the control toward a false floor and distorts the 4.6x ratio. Start at 0, or insert an explicit axis break. Honesty on a level claim matters.
- **Panel a has no uncertainty.** You assert "parallel trajectories" but plot two bare point-lines with no ribbon and no N. Add a weighted 95% band (or at least state effective control sample ≈91 and treated 21 on the panel). A reviewer wants the spread behind the means.
- **Pre-trend statistics are not on the figure.** The joint pre-trend Wald p = 0.68 is the whole point of panel b. Annotate it directly on the panel, plus the post-2010 joint p. Do not make the reader hunt the text.
- **Single 2010 dashed line undersells the claim.** You argue "no divergence through the megadrought." Shade the 2010–2024 megadrought span rather than mark one year, so the eye sees the flat coefficients sitting inside the drought.
- Color (orange/teal) is colorblind-safe. Title-as-conclusion is acceptable for this venue.

### Fig 2 — fig-forest (`fig_convergent_null.png`): the convergent null

This is your headline figure and, paradoxically, the weakest of the four.

**Problems and fixes:**

- **The x-axis is mislabeled and the standardization is mixed.** The axis reads "Standardized effect (estimate / SE)," but the text says the DiD rows are standardized by their randomization-inference p-value, not estimate/SE, while the two cross-sectional rows are estimate/SE. Two different metrics share one axis under one label. A statistically sophisticated reviewer will catch this immediately and it undermines trust in the whole figure. Either (a) split into two stacked panels (cross-sectional ATTs in native units; DiD in permutation z), or (b) standardize everything the same way, or at minimum (c) relabel the axis and flag per-row which metric is used.
- **Whole-basin ET is presented as a clean null but it is your one confounded, exclude-it outcome.** In this figure its point sits near +1.6 (visually the row farthest from zero, and pointing toward vulnerability), yet its bar spans zero only because of the permutation standardization, while Table 1 reports its cluster CI excludes zero and labels it "confounded." Figure and table contradict each other to a careful reader. Mark this row explicitly as confounded/excluded (open grey circle, hatching, or a "confounded" tag), or drop it from the forest and footnote it. As drawn, the one row that breaks the "everything brackets zero" visual is the row you have already disowned, so flag it.
- **"H2 predicts > 0" is internal jargon.** No reader knows your hypothesis numbering. Replace with plain language: "Induced-demand vulnerability predicts > 0; operational buffering < 0."
- **The primary inference is missing from the figure.** The paper insists permutation p is primary and that ±1.96 SE bars over-reject, yet the figure shows exactly those ±1.96 bars. Annotate each row with its perm p (you have them in Table 1).
- **Standardized estimate/SE is not interpretable to a policy reader.** Consider expressing each effect as a fraction of its baseline (the same unit as your equivalence bounds), so the forest reads in material terms.
- **Opportunity:** fold the streamflow ITT and downstream rows in here so the entire convergent null (area, ET, streamflow) sits in one forest. Right now streamflow convergence is in a separate figure, diluting the "all bracket zero" punch.

### Fig 3 — fig-streamflow (`fig_streamflow.png`): the upstream placebo

Your strongest and most original figure. The within-basin upstream placebo is the causal core of the paper and the figure does it justice.

**Problems and fixes:**

- **Panel a: what is each dot?** Basin-bin means? Gauge-year? The caption does not say and with ~15–21 basins the cloud's meaning is load-bearing. State it.
- **Panel a is not labeled as downstream-only inside the panel.** Add a "downstream gauges" annotation so the panel stands alone.
- **The drought region is where the message lives but is not cued.** The two fits cross near SPEI ≈ +0.5; buffering shows only on the dry (left) side. Add a faint shade or reference for SPEI < −1 so the reader's eye lands where the apparent attenuation appears.
- **The single most persuasive number in the paper is not plotted anywhere.** The slope gap collapses from −0.16/−0.20 nationally to ≈ −0.03 within climate region (south: downstream −0.036 vs upstream −0.034). That is the textbook between-region confound signature and it is invisible in every figure. Add a panel c: national vs within-region slope gap, and the by-region up/down breakdown. This converts a prose assertion into a figure a reviewer can verify at a glance.
- Panel b encoding is good: grey for the placebo, red for treated, perm p annotated, zero reference present. Keep it.

### Fig 4 — fig-storage (`fig_storage_band.png`): storage decline

**Message:** "band shifts down, amplitude holds." Correct, but the figure works against itself.

**Problems and fixes:**

- **Panel a is cluttered by overlapping IQR ribbons.** The peak and trough IQR bands overlap into muddy grey zones in the middle years, and the "amplitude unchanged" claim is not legible from the ribbons (they wander and overlap); only the two trend lines carry it. Plot amplitude (peak minus trough) as its own series, ideally a third panel or inset, so "drops without narrowing" is directly visible rather than inferred.
- **A 2005 peak point sits above 100% of capacity (~125%).** Storage exceeding nominal capacity will draw a reviewer flag (normalization error, or flood/spill storage). Explain, cap, or annotate it.
- **Linear trend on a visibly non-stationary, recovering series.** Storage dips through 2013–2015 then partly recovers 2016–2019. A straight line on that is exactly what Reviewer 2 attacks. The caption flags "descriptive," but consider noting the linear slope is a net-decline summary, or overlay the realized series more prominently.
- **Title overclaims for a control-free trend.** "The binding constraint is inflow, not storage" is a causal-sounding headline on a descriptive, no-control, no-naturalized-inflow series. Soften to something like "Storage declines while seasonal refill amplitude holds." Let the Discussion carry the inflow interpretation.
- **Panel b: amplitude CI is wide (≈ −1.1 to +1.0).** "Unchanged" here means "not distinguishable from zero," i.e. underpowered, not proven flat. Make sure the caption says so (it currently implies stability).

---

## 2. Does the figure set tell the paper's story?

Partly. The result chain (area null, estimator convergence, streamflow placebo, storage) is covered. The design chain is not, and for a null paper that is the more important half. Specific gaps where a reader cannot follow or cannot trust:

- **No geography.** Nowhere can the reader see where the 21 treated basins and ~91 effective controls sit, the north-south aridity gradient that does all the confounding work, or the upstream/downstream gauge positions that the placebo rests on. This is the largest single gap.
- **No balance evidence.** Entropy balancing within Köppen strata is the entire identification, with vivid numbers (log area SMD 1.18→0, elevation 0.37→0, aridity 0.43→0.17, ESS 9→91). None of it is plotted. A reviewer asked to believe a null on the strength of matching needs a love plot.
- **No forcing.** SPEI-12 is the dose and the 2010 megadrought (with 2019/2021 hyperdrought winters) is the exposure, yet no figure shows the forcing time series. The reader cannot see the treatment-relevant signal the design conditions on.
- **The siting-confound shrinkage is described, not shown.** The naive → fixed-effects → design-estimator ladder is the cleanest single picture of "selection, not regulation," and it is absent.

---

## 3. Ranked new figures

Ordered by leverage on causal credibility (which is where a null paper is won). Notes on main text vs Extended Data, and which can fold into existing figures.

### 1. Study-area and treatment/control map (new main-text Fig 1)
- **One message:** the matched design is geographically and climatically credible.
- **Plots:** Chile basin map, treated basins (21) vs effective controls (weighted by entropy-balancing weight, e.g. dot size), aridity (P/PET) as the background gradient, Köppen strata boundaries; inset zoom of 1–2 basins showing upstream vs downstream gauge positions relative to the dam.
- **Data:** subcuenca polygons, reservoir points, CR2 gauges with up/down classification, P/PET raster, Köppen.
- **Why persuasive:** a reviewer can immediately see that treated basins cluster in the arid center and that controls span the gradient, which is precisely the confound you claim to handle. It also makes the upstream placebo physically concrete. Without this, "matched national design" is an assertion.

### 2. Covariate balance love plot + common support (new main-text or Extended Data)
- **One message:** matching removed the siting imbalance on size and elevation, and the residual aridity imbalance is small and explicitly carried by the doubly-robust adjustment.
- **Plots:** (a) love plot of absolute SMD before vs after weighting for log area, elevation, aridity, latitude, with the 0.1 threshold marked; (b) propensity or covariate-distribution overlap (treated vs weighted controls) to show common support and the three pruned high-Andes units.
- **Data:** matched-set metadata (already on disk per the data-availability statement).
- **Why persuasive:** this is the standard, expected diagnostic for any matched causal claim. Its absence is conspicuous. It also lets you show honestly that aridity stays at SMD ≈0.17, which strengthens credibility rather than hiding it.

### 3. Siting-confound decomposition ladder (new; or panel added to Fig 2 or 3)
- **One message:** the apparent buffering is selection; it shrinks toward zero as you add fixed effects and balancing weights.
- **Plots:** a small forest or waterfall of the slope gap at three rungs, naive pooled → unit+time FE → design (ebal + FE), for streamflow and for the proxy outcomes, with perm p at each rung.
- **Data:** you already fit this ladder (Methods, "siting-confound decomposition").
- **Why persuasive:** this is the rhetorical heart of the paper rendered as one picture. Paired with the upstream placebo it closes the "selection not regulation" argument visually. Currently it exists only as two numbers in the Sensitivity section (+0.33 → +0.11).

### 4. Drought-forcing time series (Extended Data, or panel on the map figure)
- **One message:** the treatment-relevant exposure is the sustained post-2010 megadrought, common to treated and control basins (which is why year fixed effects can absorb it and identification rests on the slope).
- **Plots:** SPEI-12 national and by climate region 2005–2024, megadrought and 2019/2021 hyperdrought winters shaded; optionally treated vs control mean SPEI to show shared exposure.
- **Data:** CHIRPS/CHIRTS SPEI-12 already computed.
- **Why persuasive:** it justifies the forcing-conditioned estimand and shows the dose has real range (without which the slope is unidentified). It also visually motivates why a calendar-time DiD would be confounded.

### 5. Within-region / by-region collapse (fold in as Fig 3 panel c)
- **One message:** splitting by climate region kills the signal and equalizes upstream/downstream, the confound signature.
- **Plots:** slope gap national vs within-region, and the south up/down pair (−0.036 vs −0.034) with perm p.
- **Why persuasive:** see Fig 3 critique above. This is arguably your most diagnostic single result and it is currently unplotted.

### 6. Power / informative-null panel (Extended Data; fold positive control + equivalence)
- **One message:** the null is informative, not blind, the estimator recovers an injected effect and the design excludes large buffering.
- **Plots:** (a) observed slope gap with its TOST 90% interval against the ±25%-of-baseline negligible region, per outcome; (b) injected-effect recovery curve from the positive control (recovered vs injected, with perm-p detection threshold).
- **Why persuasive:** converts "we failed to reject" into "we can rule out effects larger than X and we verified we could see one," which is exactly the standard a Nature Water reviewer applies to a null. Currently buried in Tables 2–3.

### Main-text budget suggestion
Nature Water allows ~4–6 display items. Promote the map (1) and balance (2) into the design half of the paper, keep the streamflow placebo (3) with the new within-region panel as the causal centerpiece, retain area and a repaired/merged convergent-null forest (with streamflow rows folded in and whole-basin ET flagged), and move storage, forcing, power, and the decomposition ladder to Extended Data if space binds. The decomposition ladder is the one Extended Data item to fight hardest to keep visible, because it is the visual that most directly earns the word "mark" in the title.

---

## Single highest-leverage action

This null paper currently shows its results but not its design. Adding a study-area map and a covariate-balance love plot, plus plotting the siting-confound decomposition ladder and the within-region collapse you already computed, will do more for acceptance than any tweak to the four existing panels. The most urgent fix within the current set is the convergent-null forest (Fig 2), where the mixed standardization metric and the unflagged confounded ET row are genuine credibility liabilities a sophisticated reviewer will catch.
