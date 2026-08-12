# Question 3: function design and documentation

## Source and purpose

`pt_sampler_trunc()` originated in MATH70093 Computational Statistics coursework. It implements Parallel Tempering with lower-truncated normal random-walk proposals for a target supported on `x >= 2`. The original submission is not included; `original/pt_sampler_original.R` is an Assessment 2 extraction that preserves the original algorithm.

## Version map and design changes

The three R files represent successive versions of the same Parallel Tempering case rather than three separate solutions.

| Version | R file | Purpose |
|---|---|---|
| Original coursework | [`original/pt_sampler_original.R`](original/pt_sampler_original.R) | Preserved extraction of the submitted algorithm; used as the Q3 design comparison and Q4 baseline |
| Assessment 2 Stage 1 | [`improved/pt_sampler_improved.R`](improved/pt_sampler_improved.R) | Main Q3 function-design version; adds an explicit interface, documentation, validation and tests, and supplies the first profiled optimisation for Q4 |
| Assessment 2 Stage 2 | [`question_4_profiling/improved_stage2/pt_sampler_stage2.R`](../question_4_profiling/improved_stage2/pt_sampler_stage2.R) | Q4-only performance version; retains the generic sampler and adds the profiler-supported scalar target evaluator |

The original code already separated target evaluation, proposal generation, truncation correction, a single tempered Metropolis-Hastings update and the full sampler. It parameterised iteration count, initial states, proposal scales, temperatures and swap frequency, and returned samples and acceptance rates.

Its main software-design limitations were a hidden global `logf()` dependency, a hard-coded lower bound of 2, minimal validation and no formal function-level API documentation.

| Aspect | Original coursework implementation | Assessment 2 implementation |
|---|---|---|
| Target dependency | Hidden global `logf()` | Explicit `log_target` argument |
| Support bound | Numeric value 2 repeated in helpers | Explicit `lower_bound` argument |
| Decomposition | Proposal, tail, local step and sampler helpers | Same modular decomposition retained |
| Parameterisation | `n`, `x0`, `sigmas`, `temps`, `swap_every` | Original parameters plus target and support |
| Validation | Vector-length `stopifnot()` | Type, finiteness, bounds, ordering and dimension checks |
| Documentation | Contextual comments and report description | Roxygen-style purpose, arguments, return value, details and example |
| Output | Samples, temperatures and acceptance rates | Also returns proposal scales and lower bound |

`improved/pt_sampler_improved.R` adds the explicit interface:

```r
pt_sampler_trunc(log_target, lower_bound, n, x0, sigmas, temps, swap_every)
```

It also adds Roxygen-style documentation, input validation, clearer returned metadata and tests. Performance-specific Stage 2 code is kept in the Question 4 folder so that this directory remains focused on function design.

These design changes and tests were performed after the original coursework. They must not be interpreted as features of the submitted MATH70093 implementation.

## Run tests

From this directory with R and `testthat` installed:

```bash
Rscript tests/run_tests.R
```

| Check | Saved result |
|---|---:|
| Test expectations | 17 passed |
| Smoke-test sample dimensions | 2,000 by 7 |
| Samples finite and within support | Yes |
| Acceptance rates within zero and one | Yes |
| Invalid decreasing temperatures rejected | Yes |
