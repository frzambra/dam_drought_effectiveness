| estimator | rung | slope_gap | se | outcome | perm_p | placebo |
|---|---|---|---|---|---|---|
| naive (no match, no FE) |    1 | -0.197 | 0.09 | Streamflow SSI (SPEI->SSI slope) |   NA | FALSE |
| unit+time FE (unweighted) |    2 | -0.165 | 0.0753 | Streamflow SSI (SPEI->SSI slope) |   NA | FALSE |
| design (ebal + FE) |    3 | -0.183 | 0.0827 | Streamflow SSI (SPEI->SSI slope) | 0.388 | FALSE |
| design + within region |    4 | -0.0503 | 0.0695 | Streamflow SSI (SPEI->SSI slope) |   NA | FALSE |
| naive (no match, no FE) |    1 | 0.000823 | 0.00302 | Irrigated area (DiD) |   NA | FALSE |
| unit+time FE (unweighted) |    2 | 0.00171 | 0.00223 | Irrigated area (DiD) |   NA | FALSE |
| design (ebal + FE) |    3 | 0.000749 | 0.00214 | Irrigated area (DiD) | 0.913 | FALSE |
| design + within region |    4 | 0.000819 | 0.00216 | Irrigated area (DiD) |   NA | FALSE |
| naive (no match, no FE) |    1 | -0.0171 | 0.0128 | Orchard ET (DiD) |   NA | FALSE |
| unit+time FE (unweighted) |    2 | -0.015 | 0.0128 | Orchard ET (DiD) |   NA | FALSE |
| design (ebal + FE) |    3 | -0.0196 | 0.0129 | Orchard ET (DiD) | 0.243 | FALSE |
| design + within region |    4 | -0.02 | 0.0122 | Orchard ET (DiD) |   NA | FALSE |
| upstream placebo (unregulated) |    5 | -0.201 | 0.0904 | Streamflow SSI (SPEI->SSI slope) | 0.483 |  TRUE |
