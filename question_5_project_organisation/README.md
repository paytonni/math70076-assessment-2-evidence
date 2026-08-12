# Question 5: project organisation, collaboration and reproducibility

This public folder contains privacy-safe, retrospective evidence for the DeepRV research project.

DeepRV involved many model variants and computational runs, so its evidence focuses on explicit experiment plans, run records, result authority, reproducibility configuration and experiment provenance.

## Included evidence

- `selected_evidence/deeprv_reproducibility_inventory.md`
- `selected_evidence/public_exclusions.md`
- `representative_64x64_experiment/README.md`
- `representative_64x64_experiment/phase4d_seed4_from_seed0_benchmark_colab.ipynb`
- `representative_64x64_experiment/experiment_config.yaml`
- `representative_64x64_experiment/results_summary.csv`
- `representative_64x64_experiment/figures/posterior_maps_seed4.png`
- `representative_64x64_experiment/environment/README.md`
- `representative_64x64_experiment/environment/phase4d_environment.json`
- `representative_64x64_experiment/environment/full_gp_environment.json`
- `representative_64x64_experiment/provenance.md`

The representative experiment is a completed 64x64, seed-4 workflow with explicit data, NUTS and decoder seeds. Its lightweight public copy retains the notebook, verified configuration, a 26-row result summary, one posterior-map figure and a provenance record.

The recorded environment for this completed run is now included explicitly: Python 3.12.13, JAX 0.8.3, NumPyro 0.21.0, Linux x86_64 and a CUDA device. The notebook also enforced an NVIDIA A100 GPU and set `XLA_PYTHON_CLIENT_PREALLOCATE=false`. The two JSON files preserve the values from the small environment records in the completed result archive; the accompanying README distinguishes recorded versions from packages that were required but not version-captured.

The large result archive, checkpoints and full posterior arrays remain outside GitHub. The notebook is therefore evidence of experiment organisation, parameterisation and recorded runtime context rather than a standalone replacement for the original compute environment.

These files summarise verified local DeepRV artifacts. They do not reproduce private messages, personal identities, large research outputs or unverifiable Git history.
