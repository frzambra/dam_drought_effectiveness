# Response to Reviewer 3 (2026-07-02, round 2, 8 comments)

Comments 1, 2, 3, and 8 are language and consistency revisions, now applied throughout; comment 4
is answered with a new quantitative translation of the equivalence margin (new Supplementary Table
S16, named pipeline target); comments 5, 6, and 7 are addressed with new Discussion and Results
text. Main text remains at the 3,000-word limit and the abstract at 150 words.

---

**1. Unmeasured historical induced demand.**
Accepted, and the language is revised exactly as recommended. The abstract now reads "reservoirs
mark vulnerability established before our record and added none through the megadrought"; the
Results header is now "Reservoirs mark prior vulnerability; the megadrought added none"; and the
Discussion states the concession explicitly: the 4.6-fold cropland gap could be the equilibrated
legacy of demand induced at construction, before our record, so the null scopes to the megadrought
era rather than ruling out historical induced demand, which would need staggered commissioning to
test. The claim is therefore that reservoirs did not induce additional demand during the recent
megadrought, not that the induced-demand hypothesis is excluded over the dam life cycle.

**2. Overstated conclusion on storage amplitude.**
Accepted and softened at every site. The Results now state that the amplitude interval is wide,
that the data cannot determine whether refill amplitude (the buffering capacity) has degraded, and
that we draw no conclusion about it; what the record shows unambiguously is the decline of both
peak and trough. The Discussion mirrors this ("the amplitude trend is too imprecise to determine
whether buffering capacity has degraded") and rests the falling-supply reading on the powered part
of the record, the level decline, not on the absence of narrowing. The abstract already made no
amplitude claim ("the storage band drifts downward, indicating a falling supply").

**3. ET measurement bias toward the null.**
Accepted; we take the tempering option and make the bias direction explicit. Evapotranspiration has
been removed from the abstract's list of null pathways. The Discussion now states that the orchard-ET
null "may be an artifact of the product and carries no weight on its own," that the demand
conclusion rests on cropland area and the water-rights registry, which do not share the bias, and
that a thermal ET sensitivity (Landsat or ECOSTRESS class) remains future work. Consistent with
this, orchard ET was already excluded from decisive evidence (post-hoc stratum, no claim rests on
it) and the equivalence table shows its MDE (237% of baseline) makes it uninformative as a bound; a
thermal-product subset analysis is beyond the present data holdings but is flagged as the way to
close the gap.

**4. Equivalence margin lacks physical volume context.**
Done quantitatively (new Supplementary Table S16; `equivalence_volume_context` in
`src/R/causal/equivalence.R`, a named `targets` target). Translating the maximal margin
perturbation (0.29 SSI units at the worst observed deficit) through each treated downstream gauge's
within-gauge flow-to-SSI sensitivity gives a median of roughly 58 hm³ over a 12-month season (IQR
16 to 137 hm³ across the 40 gauges), about 11% of mean annual flow (IQR 7 to 14%). The linear
sensitivity is an average rather than dry-tail mapping, so these are upper-end figures. The Methods
now state plainly that a volume of this order is genuinely material for local water management,
which is why the margin is anchored to the operational drought-severity classification rather than
to volumetric negligibility, why the threshold-free MDE is reported alongside, and why the causal
weight of the null rests on the within-basin placebo rather than on the equivalence verdict.

**5. Generalizability across governance regimes.**
Added to the Discussion: the siting lesson (apparent buffering reflecting placement) should hold
wherever dams are placed non-randomly, but the demand-side null is governance-mediated: under
prior-appropriation doctrines, where unused rights risk forfeiture, induced demand may be amplified,
whereas state-managed adaptive allocation can curtail it. The reservoir effect is therefore
presented as governance-mediated rather than universal, which frames how the supply-demand cycle
should be expected to manifest outside Chile's 1981 Code.

**6. Clarification of streamflow decline source.**
Clarified in the Results: the 2.9% per year decline in unregulated control streamflow (3.4% in
dammed basins) is a primary estimate computed from our own gauge panel, and the text now says so
explicitly, citing the regional megadrought assessments whose documented runoff deficits it is
consistent with [garreaud_20102015_2017; AlvarezGarreton2021].

**7. Contextualizing the socio-hydrological debate.**
Added to the Discussion, connected to the mechanisms: within the megadrought scope our nulls refine
rather than refute the supply-demand cycle. The cycle leaves no operational imprint during drought,
which suggests its mechanisms act through siting and construction (where to build, and the demand
that assembles around new supply) rather than through reservoir operation, a distinction the current
theoretical models do not draw and that our design is the first to isolate empirically.

**8. Inconsistent minimum detectable effect bound.**
Fixed. The table values are 45.8% (intent-to-treat) and 58.8% (downstream), so every site now reads
"46 to 59%" (Results twice, Discussion once), and the Supplementary Figure S2 caption uses the same
rounding. No "46 to 58%" instances remain.
