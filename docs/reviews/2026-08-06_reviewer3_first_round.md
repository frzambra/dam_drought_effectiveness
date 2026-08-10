# Fatal Flaws

1. Downstream extraction masking

The within-basin placebo design assumes that upstream and downstream reaches are comparable except for the presence of the dam. However, downstream valleys typically have much higher agricultural development and water extraction than steep upstream headwaters. During droughts, intensified downstream water extraction would steepen the downstream streamflow transmission slope (amplifying the hydrological drought). This extraction-induced steepening could counteract and mask any operational buffering (flattening) provided by the reservoir, leading to a false-negative null contrast (D ≈ 0). The authors should discuss this potential masking effect or attempt to control for downstream extraction volumes to rule out this alternative explanation.

# Reviewer Comments

1. Inconsistent reservoir counts in paired-gauge analysis

The paper contains an internal contradiction regarding the number of basins/reservoirs used in the paired-gauge (upstream vs. downstream) analysis. In Section 3.5, the text states that only 15 of the 21 treated matched basins have both an upstream and a downstream gauge, meaning any paired comparison is limited to at most 15 basins. However, in Section 4.3, when splitting the paired-gauge analysis by reservoir capacity, the text states that the analysis is performed on 'the seven carryover reservoirs' and 'the ten seasonal reservoirs', which sum to 17 reservoirs. It is mathematically impossible to have 17 reservoirs in a paired-gauge comparison if only 15 basins have both gauges.

2. Regulated flow circularity

The carryover ratio is operationalized as reservoir storage capacity divided by the mean annual downstream flow. However, downstream flow is a regulated variable that is directly affected by reservoir operations, consumption, and diversions. In basins with high water consumption or direct diversions from the reservoir, the downstream flow will be artificially low, which inflates the carryover ratio and may misclassify seasonal reservoirs as carryover-capable. To resolve this circularity, the authors should operationalize the carryover ratio using the mean annual reservoir inflow or reconstructed unregulated streamflow.

3. Sub-watershed scale SPEI

The meteorological forcing (SPEI-12) is operationalized at the sub-watershed scale rather than being aggregated over the specific upslope contributing area (catchment) of each individual streamflow gauge. In mountainous regions like the Chilean Andes, meteorological variables (precipitation, temperature, and snowpack) exhibit strong elevation gradients. Using a single sub-watershed-average SPEI-12 for both the high-elevation upstream gauge and the lower-elevation downstream gauge introduces exposure misclassification. The authors should construct catchment-specific meteorological forcing by routing CHIRPS and CHIRTS data over the upslope contributing area of each gauge to ensure the transmission slopes are accurately estimated.