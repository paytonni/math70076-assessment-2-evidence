# Representative DeepRV 64x64 experiment

This folder contains a lightweight public record of one completed DeepRV experiment. The selected notebook is the Phase 4D seed-4 A100 benchmark on a 64x64 spatial grid. It compares a Full GP reference, 13 DeepRV variants and 12 direct inducing-GP variants using one frozen synthetic dataset.

## Statistical and computational setting

The data come from a Poisson log-Gaussian process on 4,096 spatial locations with a Matern-1/2 covariance, true lengthscale 30 and a uniform 50% observation mask. Data seed 4 and NUTS seed 4 are separated from decoder seed 0. The DeepRV variants use an exact teacher or bilinear, cubic, DTC and FITC teachers on 8x8, 16x16 and 32x32 inducing grids.

The Phase 4D run reused decoder checkpoints selected at training step 200,000; it did not retrain the decoders. Posterior inference used two NUTS chains. The initial budget was 500 warm-up iterations plus 2,000 retained draws per chain. Models that failed the initial diagnostic gate were rerun independently with 1,000 warm-up iterations plus 4,000 retained draws per chain. The completed result archive records 26 result rows and all 26 pass the final diagnostic checks.

## Files

- `phase4d_seed4_from_seed0_benchmark_colab.ipynb` is the public evidence copy of the Colab launcher. The original code and parameters are retained; only a short provenance note was added.
- `experiment_config.yaml` collects settings verified from the notebook, saved configurations, completion marker and project records.
- `results_summary.csv` contains selected columns from the authoritative 26-row result table. Values were copied, not recomputed.
- `figures/posterior_maps_seed4.png` is the first page of the saved posterior-map output, showing the latent truth, Full GP, Exact DeepRV and selected inducing-teacher reconstructions.
- `provenance.md` records the source files, transformations, checks and exclusions.

The version-controlled notebook intentionally has no embedded execution output. The completed Colab workflow stored outputs in a separate result archive, so this public package preserves that boundary rather than inserting reconstructed notebook outputs.

## Organisation and reproducibility

The workflow separates configuration, source code, frozen data, checkpoints, inference outputs, diagnostics, figures and completion markers. Grid size, data seed, NUTS seed, decoder seed and model variant are explicit experiment identifiers. The frozen dataset has its own SHA-256 digest, while per-model manifests record checkpoint and posterior-artifact hashes.

Git records changes to the lightweight notebook, configuration, summaries and provenance notes. Large run artifacts remain in external storage and are linked conceptually through stable experiment identifiers, completion markers and hashes. This makes code and configuration changes reviewable without placing multi-gigabyte checkpoints or posterior arrays in the repository.

This Assessment 2 evidence repository is a retrospective public snapshot. It is not presented as the complete Git history of the original DeepRV research project.

## Reproduction boundary

The notebook is not standalone: a full rerun requires the archived Phase 4D source package, pretrained decoder checkpoints, the frozen data array and an A100-compatible environment. Those large or environment-specific dependencies are deliberately excluded. The public files are sufficient to inspect the experiment design, parameterisation, result structure and provenance, but not to reproduce the multi-gigabyte computation without the external artifacts.
