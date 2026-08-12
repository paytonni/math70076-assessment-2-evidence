# Stage 2 scalar-target optimisation summary

## Material Passport

- Origin Skill: experiment-agent
- Origin Mode: run + validate
- Origin Date: 2026-08-11
- Verification Status: VERIFIED
- Version Label: stage2_scalar_target_v1

## Scope

Stage 2 retained the Stage 1 generic `pt_sampler_trunc(log_target, lower_bound, ...)` interface, documentation, input validation, current log-target cache, direct log upper-tail calculation, return structure and complete Parallel Tempering configuration. The only new performance change was a coursework-specific scalar target evaluator for the scalar-heavy MCMC inner loop.

## Correctness gates

- Fixed target points checked: 13.
- Random target points checked: 1000.
- Maximum absolute log-density difference: 0.
- Non-finite mismatches: 0.
- Support handling correct: yes.
- Full Stage 2 sample dimensions: 100000 by 7.
- All samples finite and at or above 2: yes.
- Maximum RW acceptance-rate difference from Stage 1: 0.
- Maximum swap acceptance-rate difference from Stage 1: 0.
- Cold-chain mean difference: 0.
- Cold-chain SD difference: 0.
- Complete samples elementwise identical in this run: yes.

Exact sample equality is observed evidence for seed 1 and this implementation; it is not a universal requirement for statistically equivalent MCMC implementations.

## Unprofiled benchmark

The headline comparison reran all three versions five times in alternating order under the complete coursework configuration.

- Baseline median: 10.429 seconds.
- Stage 1 median: 6.939 seconds.
- Stage 2 median: 5.880 seconds.
- Stage 2 vs Stage 1: 1.180x speed-up and 15.26% runtime reduction.
- Stage 2 vs baseline: 1.774x speed-up and 43.62% runtime reduction.

The preserved earlier three-run benchmark remains 10.375 seconds for baseline and 7.115 seconds for Stage 1. These older values were not overwritten. Stage 2 effect sizes use the new contemporaneous five-run comparison.

## Rprof evidence

- Stage 1 target evaluation: 1.170 sampled seconds, 42.03% total time.
- Stage 2 target evaluation: 0.132 sampled seconds, 6.53% total time.
- Target-evaluation sampled time reduction: 88.72%.
- Stage 1 `pmax`: 0.826 seconds and 29.67% total time.
- Stage 2 `pmax`: 0.000 seconds and 0.00% total time; it did not appear in the Stage 2 Rprof sample.
- Stage 1 local step: 2.298 seconds and 82.54% total time.
- Stage 2 local step: 1.213 seconds and 60.02% total time.
- Stage 2 direct log-tail remains 0.345 seconds and 17.07% total time.

Rprof percentages and sampled seconds are sampling estimates. The tail calculation occupies a larger share after target optimisation because the total run is shorter; this does not by itself mean the tail became slower.

## Memory evidence

- Stage 1 Rprof cumulative allocation: 7324.9 MiB.
- Stage 2 Rprof cumulative allocation: 5761.1 MiB.
- Reduction vs Stage 1: 21.35%.
- Stage 2 sample matrix: 5.341 MiB, unchanged from Stage 1.

Rprof cumulative allocation is not peak resident RAM. The retained sample matrix is unchanged because all 100,000 by 7 samples are still stored.

## Interpretation and trade-offs

The experiment supports the hypothesis that a vector-capable target introduced avoidable overhead in scalar MCMC calls. The Stage 2 evaluator removes allocation, indexing, `any()` and `pmax()` from each target call while leaving the generic sampler interface intact. The trade-off is an additional coursework-specific target implementation that must be validated against the public vector reference and maintained alongside it.

The improvement is large enough to report, but it should be presented as a measured, target-specific micro-optimisation rather than a universal claim that scalar R code is always faster than vectorised R code.

## Rcpp decision

Rcpp is not recommended for this Assessment 2 case. The complete Stage 2 run is already about six seconds on this machine, while Rcpp would add a compiled dependency, toolchain requirements, debugging and maintenance burden, portability costs and additional RNG/reproducibility considerations. That trade-off is disproportionate unless this sampler must be run many more times or at much larger scale.

## Final decision

**KEEP STAGE2 IN FINAL ANSWER**
