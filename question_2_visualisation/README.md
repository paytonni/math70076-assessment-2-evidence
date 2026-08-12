# Question 2: data wrangling, visualisation and communication

## Source and purpose

This folder contains the existing DeepRV figure used in the assessment. It compares Seed 0 posterior predictive mean counts on a 64 by 64 spatial grid with a Full Gaussian Process reference and displays selected cell-wise absolute differences.

The intended audience was supervisors and statistically trained readers familiar with Gaussian processes and Bayesian spatial modelling. The visual argument is that DeepRV can retain much of the Full GP posterior spatial structure while the difference maps reveal local, teacher-dependent approximation error.

## Included evidence

- `fig06_grid64_posterior_maps.py`: panel selection, shared-scale and difference-map logic.
- `figure_common.py`: archive loading, identity checks and posterior summarisation.
- `figure/fig06_grid64_posterior_maps.png`: final figure used in the response body.

The helper reads posterior predictive `obs`, averages over its first axis and reshapes the result to 64 by 64. Prediction panels apply `log1p` only for display and use one common scale. Difference maps are computed from untransformed posterior mean counts relative to Full GP and use a separate common scale starting at zero.

## Reproduce with the original archives

The large source archives are not included. Set `DL4BI_EVIDENCE_ROOT` to a local DeepRV checkout that contains the expected `outputs/oliver_64x64_uniform_obs50_seed0_seed1_unit_zips` directory, then run:

```bash
export DL4BI_EVIDENCE_ROOT=/path/to/dl4bi
python fig06_grid64_posterior_maps.py
```

The script checks that all three archives use the same coordinates, count data and observation mask and that 2,048 of 4,096 grid cells are observed. The figure is one-seed evidence. Panel a is a simulated latent field; panels c to i are count-scale posterior summaries after a display transformation, so they are not directly numerically interchangeable.
