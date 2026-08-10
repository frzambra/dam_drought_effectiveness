# How the study works, in plain language

A non technical walkthrough of the methodology behind
*"An upstream placebo shows that reservoir siting explains the apparent drought buffering of seasonal reservoirs in Chile's megadrought."*

Written 2026-08-10. Mirrors `manuscript/paper/methods.qmd`, which carries the formal version and every supplementary table reference.

---

## 1. The question, and why it is hard

The question is simple: **during a long drought, does a reservoir actually protect the river and the farms below it?**

The obstacle is also simple. Reservoirs are not scattered at random. In Chile they were built in the dry, farmed, central and northern basins, precisely where water is scarce and demand is high. So if you compare basins with dams against basins without dams, you are not only comparing "dam" against "no dam". You are also comparing dry against wet, farmed against wild, big rivers against small ones.

Any difference you find could be the dam, or it could be the place. Everything in the methodology exists to separate those two.

We call the two things:

* **Operation**, what the dam does with water once it exists.
* **Siting**, the characteristics of the location that made someone build a dam there in the first place.

The paper estimates operation, holding siting fixed.

---

## 2. The building blocks

**The unit of analysis.** Chile is divided into 467 official sub watersheds (DGA sub cuencas). Each one is a data point. We use sub watersheds rather than whole watersheds because the big dams sit in Chile's largest river basins, and the finer grain gives us more undammed basins of a comparable size to compare against.

**Treated and control.** A sub watershed is *treated* if it contains at least one of the 26 monitored reservoirs. That gives 24 treated basins. Everything else is a potential control.

**Cleaning the controls.** An undammed basin sitting immediately downstream of a reservoir is not really untreated, it receives regulated water. All 45 such basins are removed. That leaves 398 clean controls. We also check the survivors against a national inventory of 1,370 impoundments, so "undammed" does not quietly mean "has a dam we were not monitoring".

**The clock.** The study covers 2005 to 2024, which spans Chile's megadrought that began around 2010.

**One important limitation up front.** 18 of the 24 reservoirs were already built before our data begins. So we cannot watch basins "switch on" and compare before against after, the classic approach. There is almost nothing to watch switching on. The design therefore compares places at the same time, rather than the same place before and after.

---

## 3. The core trick: measure sensitivity, not level

If we compared *levels*, say, how much water flowed in dammed against undammed basins, siting would dominate everything. Dry basins have less water regardless of dams.

So instead of levels we measure a **slope**: how strongly a given basin converts a rainfall deficit into a river deficit.

Concretely, for each basin we take two standardized drought indices:

* **SPEI-12**, the *meteorological* drought signal. Roughly, how dry the last twelve months of weather were relative to normal. This is the "dose" nature delivers. Nobody manages it, which is what makes it a clean input.
* **SSI-12**, the *hydrological* drought signal. The same idea applied to river flow.

Then we regress one on the other. The resulting slope answers: **when the sky takes away one unit of water, how much does the river lose?**

* A steep slope means the drought passes straight through.
* A flat slope means something is absorbing it. That is what buffering looks like.

The reservoir hypothesis then becomes a testable statement: dammed basins should have flatter slopes than comparable undammed basins.

Using slopes rather than levels also solves a second problem. The megadrought hit the arid centre of the country hardest, which is exactly where the dams are. Comparing drought impacts directly would conflate "has a dam" with "got hit harder". Comparing impact *per unit of deficit* removes that.

---

## 4. Comparison one: matched basins

We cannot use all 398 controls as they come, because they are on average wetter, higher, bigger or smaller than the dammed ones.

So we reweight them. The technique is called **entropy balancing**. The intuition: give each control basin a weight so that the weighted pool of controls looks statistically like the group of dammed basins on the characteristics we care about.

Think of building a synthetic comparison country out of the real one, mixed so that its average size, average elevation and climate class match the dammed basins.

What we force to match:

* climate class (exact match, a dammed Mediterranean basin is only ever compared with Mediterranean controls),
* basin area,
* mean elevation.

This works: the imbalance in area and elevation goes essentially to zero. 21 of the 24 dammed basins survive with usable comparisons, against an effective control pool of about 91.

**The one honest compromise.** Aridity itself is the strongest confounder, and we deliberately do *not* force it to match exactly in the main specification. The reason is arithmetic: forcing it collapses the usable control pool from about 91 basins to about 19, and a comparison built on 19 basins is too thin to conclude anything from. Instead, the residual aridity gap is handled by including aridity in the statistical model, and we also report the strict version as a sensitivity check. The strict version agrees, but we treat it as corroboration, not proof, because at that sample size it is fragile.

We also deliberately do **not** match on cropland. Cropland is downstream of the decision to build a dam, so matching on it would erase part of the very thing we are trying to measure.

---

## 5. Comparison two: the upstream placebo, the decisive test

This is the heart of the paper, and it is the part that needs no statistics to understand.

Take a single dammed basin. Put one river gauge **below** the dam and one **above** it.

* The gauge below sees regulated water. Whatever the dam does, it does it here.
* The gauge above sees water the dam has never touched. Same climate, same geology, same mountains, same history of why someone chose to build here.

So the upstream gauge is a **placebo**: it carries all of the siting, and none of the operation.

Now compute the SPEI to SSI slope at both, and take the difference:

```
D = (slope below the dam) - (slope above the dam)
```

The logic is airtight in its structure:

* If the dam is genuinely buffering drought, the flattening must appear **only below it**. D should be clearly negative.
* If the flattening appears **equally above the dam**, then the flattening was never the dam. It is a property of the place. D is about zero.

Of the 21 matched dammed basins, 17 have a usable downstream gauge and 15 have both, forming the paired contrast.

**The result:** the slopes are essentially identical above and below, D is about +0.04, and it is statistically indistinguishable from zero. The apparent buffering is the location.

---

## 6. How we test whether a number is real

With only about 21 dammed basins, standard statistical formulas are unreliable, they tend to declare things significant when they are not. So the primary test is a **permutation test** (also called randomization inference), which is intuitive:

1. Take the real data and compute the effect.
2. Now *lie* to the computer. Randomly relabel which basins are "dammed", keeping the count the same and shuffling only within similar climate and aridity groups.
3. Recompute the effect on the fake labels.
4. Repeat at least 999 times.

This builds a picture of how big an effect looks *purely by chance* when the dam label means nothing. If the real effect sits comfortably inside that cloud of fake effects, it is not evidence of anything. If it sits far outside, it is real.

For the water rights outcomes, neighbouring basins turned out to be statistically dependent on each other, which the basin level shuffle would not respect. There we shuffle whole watershed blocks instead, and that spatially valid version is the one we believe.

---

## 7. How we make a null result mean something

Most of the headline findings are **nulls**, no detected effect. A null is easy to produce badly, just use a weak test. So we do three things to make ours credible.

**Bound the effect.** Rather than say "we found nothing", we say how large an effect we could have ruled out. For streamflow, the design excludes buffering larger than about 46 to 59 percent of baseline transmission. Below that we cannot see. So the honest statement is *no large operational buffering*, not *no buffering at all*. A 30 to 40 percent reduction remains compatible with the data.

**Equivalence testing.** We declare a result equivalent to zero only when its confidence interval lies inside a pre stated negligible range, set at 25 percent of baseline, anchored in the fact that operational drought categories are about half a standardized unit wide.

**A positive control.** We inject a fake buffering effect of known size into the data and check the machinery finds it. It does, recovering the injected effect one for one, and detecting it once it exceeds the threshold above. So when the pipeline reports nothing, it is because there was nothing large enough to see, not because the pipeline is blind.

---

## 8. The confound ladder

To show exactly *where* the apparent buffering dies, we run the same analysis four times, each with one more control added:

1. **Naive.** Just compare dammed against undammed slopes. This is what a conventional study would report, and it shows apparent buffering of about -0.18.
2. **Add basin and year fixed effects.** Still there.
3. **Add the matching and weighting.** Still there.
4. **Let each climate region have its own baseline drought transmission.** It collapses to about -0.05, indistinguishable from zero.

The step from 3 to 4 is the between region aridity confound. The remainder at step 4 is the most we can attribute to actual regulation. This ladder is what turns "we found a null" into "here is the specific mistake that produces the positive finding others report".

---

## 9. Everything we tried to break it with

A large part of the work is checking that the null is not an artifact. Each of these is a supplementary table.

**Is the placebo comparison fair?** Upstream gauges are higher up and drain smaller areas. We measured both gradients among undammed control gauges, and re fit the placebo net of them. Importantly, the elevation gradient works *against* our finding, it would make upstream look more buffered on its own, so correcting for it does not rescue the buffering hypothesis.

**Are the gauges labelled correctly?** Three independent checks: cross checking against the official hydrographic naming, dropping gauges within 100 m of a dam, and validating against routed river network topology (HydroRIVERS) so that "upstream" really means the same channel and not a parallel tributary.

**Is an upstream gauge secretly below another dam?** This would be real regulation misread as siting. We screened all 35 upstream gauges at three levels of strictness against the national dam inventory. The placebo survives all three, and the direction is diagnostic: removing flagged gauges makes the upstream slope *steeper in the buffered direction*, the opposite of what hidden regulation would do.

**Could irrigation downstream be masking a real buffer?** Downstream reaches carry about 2.5 times more cropland. We tested whether local cropland predicts the slope at all. It does not, and the implied bias is about two orders of magnitude too small to hide the effect.

**Is it snowmelt?** Chile's central rivers are snow fed. Tested four ways, including a low snow subsample and a snow year interaction. Excluded.

**Is it groundwater?** If dammed basins simply pumped instead, that would hide a surface effect. 213 DGA well hydrographs show no differential drawdown.

**Is it an index artifact?** Re run on raw log flow instead of the standardized index, and re standardized on a longer 1990 to 2020 baseline. Unchanged.

**Is missing data doing it?** Gaps are never imputed, they shrink the sample instead. Missingness is drought selective (34 percent of drought months fail the quality rules against 14 percent otherwise), but it is nearly identical upstream and downstream, so it thins every slope equally rather than creating the contrast.

**Is the effect only in extreme drought, or only early on?** Tested with a curved (quadratic) drought term, a drought months only refit, and an early against late megadrought split. Nothing.

---

## 10. The other pathways

Beyond streamflow the paper tests the socio hydrological side of the hypothesis, that reservoirs create long term vulnerability by encouraging demand to grow.

* **Cropland.** Annual cropland area from MapBiomas satellite maps. Dammed basins hold about 4.5 times more cropland, but the trajectories run parallel: an event study finds no divergence before 2010 and none detected after. So the cropland gap is a siting signature, something that was already there, not something the drought era dams created.
* **Water rights.** New consumptive rights granted by the state, from the DGA registry. These *appear* to accrue faster in dammed basins, and this is exactly the trap the design is built to catch: the apparent effect disappears under permutation inference, because arid basins have denser rights activity anyway. Honest caveat, in administratively closed basins water changes hands through private transfers that never enter the registry, so this measure cannot see market reallocation.
* **Evapotranspiration.** Attempted and then **excluded**, not counted as a null. The MODIS MOD16 product is known to underestimate evapotranspiration over irrigated land, which biases the test toward finding nothing. Reporting that as a null would be dishonest, so it sits in the supplement flagged as uninformative.

---

## 11. The one place we do find an effect

Pooling all reservoirs hides a split by size. Divide the fleet by the **carryover ratio**, the reservoir's capacity expressed as a fraction of a year of river flow:

* **Seasonal reservoirs** (below half a year of storage) fill and empty within one year. They physically cannot bridge a multi year drought. They show no downstream specific effect.
* **Carryover reservoirs** (at least half a year) can hold water from one year to the next. These seven basins do show a downstream specific buffering signal, D = -0.23.

This is reported honestly as **exploratory**. It was prompted by a reviewer, it is a subgroup of seven basins inside a large robustness battery, and no multiplicity correction is applied. Its *direction* survives leaving any single basin out and survives redefining the ratio; its *statistical significance* survives neither cleanly. So it is a candidate mechanism, not a confirmed exception.

The takeaway is mechanistic and it makes physical sense: the ability to store water *across years* is what buffers a multi year drought, and most of Chile's fleet cannot do it.

---

## 12. The descriptive part: what is left to store

Finally, and separately from all the causal machinery, we simply track how full the reservoirs are. For each year we take the peak and the trough of stored water, as a percentage of capacity so that reservoirs of vastly different sizes are comparable.

Both fall over 2005 to 2024. The pattern is not a smooth drift: the peak **steps down** at the 2010 onset of the megadrought and then stays at a lower level, while the trough, the carryover floor that would bridge a second and third dry year, **keeps eroding**. Peak storage fell from 87 percent of capacity before 2010 to 67 percent after, and the trough from 40 percent to 25 percent.

Because there are only about 22 to 26 reservoirs, we confirm every one of these trends with a wild cluster bootstrap rather than trusting standard errors.

This section is explicitly **descriptive**, there is no control group for it, and we say so. We also state the three competing explanations we cannot fully separate: falling inflows, changed management, and sedimentation silting up the storage. Three features favour the supply side reading (the peak fall is a step rather than a gradual accumulation, the seasonal amplitude does not narrow, and the decline co moves with an independent fall in unregulated control streamflow), but resurveyed bathymetry is flagged as the direct test we cannot run.

---

## 13. The argument in five sentences

1. Dams sit in dry, farmed basins, so a raw comparison measures the place, not the dam.
2. Compare how strongly a rainfall deficit turns into a river deficit, not how much water there is.
3. Compare each dammed basin against reweighted lookalike undammed basins, and, more decisively, against the unregulated river above its own dam.
4. Buffering appears just as strongly above the dams as below them, and it disappears entirely once climate regions carry their own baseline, so for the seasonal majority of the fleet the apparent buffer is siting.
5. The exception is the handful of reservoirs large enough to hold water across years, which suggests that carryover capacity, not reservoir count, is what buffers a long drought.

**Policy consequence:** with less water available to store each year, building more small seasonal reservoirs is supply blind. Adaptation has to move toward managing demand.

---

## 14. Reproducing it

Everything runs through a `targets` pipeline, so each number in the paper traces to a named target rather than to a script someone ran by hand.

```r
targets::tar_make()          # build everything out of date
targets::tar_visnetwork()    # see the dependency graph
targets::tar_read(name)      # pull one result into the session
```

Outputs land in `results/tables/` and `results/figures/`, and the manuscript reads them from there.
