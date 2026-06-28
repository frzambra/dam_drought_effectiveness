---
name: streamflow-ssi-test-design
description: Decisive design for the H1 reservoir drought-buffering test on STREAMFLOW (SSI) — most direct availability outcome; CR2 daily caudal
metadata:
  type: project
---

The streamflow buffering test. Streamflow is the DIRECT reservoir-effect outcome (reservoirs literally regulate flow); best remaining shot at a real positive after vegetation/ET tests all collapsed to siting+aridity. See [[project-data-constraints]], [[h1-test-design]].

**Data:** `data/raw/streamflow/cr2_qflxDaily_2020/` — wide CSV, col per station (zero-padded `codigo_estacion` e.g. `01201005`), 15 metadata rows (latitud, longitud, altura, codigo_sub_cuenca, fin_observaciones, cantidad_observaciones...) then daily rows keyed by date, value = caudal m3/s, -9999 = missing. Record ENDS 2020-03 → analysis window ~2000–2020; megadrought 2010–2020 covered, NOT 2020–2024. Stations file `..._stations.txt` is long format with same metadata + lat/lon + subcuenca. 430 usable gauges (ends ≥2010, ≥10yr); matched units: 17/21 treated + 60 control subcuencas have ≥1 gauge, 217 gauges in matched units (2–11/treated unit).

**SSI build (decided):**
- Daily → MONTHLY MEAN flow (require ≥ ~20 valid days/month else NA). Then SSI-12 = 12-mo trailing-sum/mean of monthly flow, standardized, to MATCH SPEI-12 accumulation. Also SSI-3 for short-memory triangulation.
- Standardization: per-CALENDAR-MONTH (remove seasonality), nonparametric — empirical CDF via Weibull/Gringorten plotting position → qnorm (normal-quantile transform). Robust to skew/intermittency, no distribution fit to fail GoF. (Gamma/log-logistic fragile with zeros; avoid.) Equivalent to `SCI` empirical or manual. Min 15 yr per gauge per calendar month for stable ECDF; gauges with <10yr dropped.
- Zeros/intermittent: NQT handles ties; if a gauge is intermittent (>10–15% zero months) FLAG and run robustness without it. Central-Chile snowmelt regimes are perennial mostly, OK.
- SSI computed PER GAUGE, then aggregated to subcuenca-month (see below).

**Gauge→unit & up/down-dam (decided):**
- No routed network. PRIMARY = intent-to-treat: ALL gauges in a dammed subcuenca = treated. This ATTENUATES toward null (upstream/natural-inflow gauges dilute the regulated signal) → conservative; a positive here is strong.
- DOWNSTREAM refinement (confirmatory, expect LARGER effect): gauge is "downstream" if gauge elevation < dam elevation AND same subcuenca (cheap proxy using `altura` + dam point elev). Optionally gauge latitude downstream-ward. Run as separate spec; if buffering real, downstream effect > ITT effect (dose-response in the RIGHT direction = key corroboration).
- Multiple gauges/unit: compute SSI per gauge, aggregate to subcuenca-month by MEAN of SSI (already standardized/comparable). Drainage-area-weighted mean as robustness. Do NOT pool raw m3/s across gauges (area mismatch).

**Primary estimand & model (decided):**
- Forcing-interacted DiD slope, MONTHLY grain: `feols(SSI ~ treat:SPEI_c + SPEI_c | unit + month_of_year + year, weights=~w)` where SPEI_c = SPEI-12 (lagged, see below), unit=subcuenca, year FE absorb common megadrought shock (NEVER identify off calendar time), month_of_year FE residual seasonality.
- Estimand = differential SPEI→SSI SLOPE. H1 buffering ⇒ treated SSI LESS sensitive to met deficit ⇒ **NEGATIVE `treat:SPEI_c`** (when SPEI low/drought, treated SSI held up relative to control). Sign convention: SPEI & SSI both negative=dry, so baseline `SPEI_c` coef POSITIVE; buffering REDUCES the slope → negative interaction.
- Storage: keep PRIMARY a pure dammed-vs-control contrast (storage treated-only, breaks the contrast). Storage enters only the WITHIN-treated dose-response robustness (does buffering scale with storage_fraction? expected if real).
- Propagation lag SPEI→SSI: ESTIMATE it (don't assume). Cross-correlate SPEI-12 vs SSI-12 per unit, take median peak lag (expect 0–3 mo for SSI-12; reservoirs may LENGTHEN it in treated — lag elongation is itself buffering evidence). Use chosen lag in main model; report sensitivity over lags 0–6.

**Inference (decided):** Permutation of treatment label within kg_group × aridity-tercile strata (~17 treated clusters; matches [[h1-test-design]] scheme), 5000+ reps, test stat = `treat:SPEI_c` coef. Cluster-robust SEs over-reject at this N. SSI autocorrelation: cluster at subcuenca; for permutation, permute WHOLE-UNIT labels (block structure preserved automatically since label is unit-level). Report wild-cluster as secondary only.

**Streamflow-specific confounds & fixes:**
- Gauges sited near dams for operations (selection) → ITT + downstream refinement; control via matched controls + unit FE.
- Abstraction/diversion unrelated to storage (canals, irrigation intakes) → confounds "regulation"; flag gauges with known intakes; interpret as net managed-flow effect not pure reservoir.
- Drainage-area mismatch → SSI standardization removes scale; never pool raw m3/s.
- Up/down misclassification → ITT attenuates (conservative); downstream spec is the deconfounded version.
- Non-stationary rating curves / record-end 2020 → fixed window, drop short records.

**Decision criteria:**
- CONFIRM buffering: `treat:SPEI_c` significantly NEGATIVE (permutation p<0.05) in ITT; LARGER negative in downstream-only; baseline SPEI_c positive; survives lag sensitivity; within-treated dose-response with storage same sign.
- NULL/FALSIFY: interaction ~0 or positive; downstream ≈ ITT (no dose-response in space); collapses when conditioning on aridity tercile / siting covariates (signal = siting not regulation).
- MOST DECISIVE FALSIFIER/PLACEBO: UPSTREAM-ONLY gauges in dammed subcuencas should show NO buffering (they are above the dam = unregulated). If "buffering" appears upstream too, it's siting/aridity, not the reservoir. This is the cleanest within-design placebo streamflow uniquely affords (vegetation couldn't).

**Honest prior:** More optimistic than veg/ET. Reservoirs DO mechanically regulate flow, and the SPEI→SSI slope test is the right instrument, BUT: ITT attenuation + only 17 treated units + 2020 cutoff (misses deep megadrought tail) + abstraction noise make detection hard. Expect a DETECTABLE negative interaction in DOWNSTREAM-only, weak/marginal in ITT. Convincing result = negative interaction that (1) strengthens upstream→downstream, (2) scales with storage within-treated, (3) vanishes in upstream placebo, (4) survives permutation. If downstream also collapses to aridity, the whole reservoir-buffering thesis is in serious trouble and the paper pivots to "delay/vulnerability not buffering."
