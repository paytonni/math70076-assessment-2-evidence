# Provenance note

## Selection

The selected source notebook was `experiments/phase4d_seed4_from_seed0_benchmark_colab.ipynb` in the local DeepRV project. It was chosen because:

- it is a 64x64 experiment with explicit data, NUTS and decoder seeds;
- its final result archive records `state: complete` and 26 result rows;
- the final table contains 13 DeepRV, 12 direct inducing-GP and one Full GP row;
- all 26 rows have final diagnostic status `PASS`;
- the notebook and result bundle contain explicit stage gates, completion markers, hashes and resume/status logic.

The similarly relevant `paperlike_64x64_allmodels_optimized_colab.ipynb` is the historical seed-0 baseline, but its working-tree copy was a cloud placeholder during this audit. The Phase 4D seed-4 notebook was locally readable and had a complete, locally readable final archive, so it provides the stronger public evidence chain.

## Source evidence

The following paths are relative to the original DeepRV project and are not published here as large artifacts:

- notebook: `experiments/phase4d_seed4_from_seed0_benchmark_colab.ipynb`;
- completed result archive: `outputs/seed_4_phase4d_complete-001.zip` (approximately 3.2 GiB);
- experiment record: `docs/RUN_INDEX.md`;
- chronological record: `docs/EXPERIMENT_LOG.md`;
- historical seed-0 manifest: `experiments/phase4d_seed0_baseline_manifest.json`.

The completed archive also contains two small environment records used here: `seed_4/seed_4_phase4d_environment.json` records the Phase 4D protocol, platform, Python version, seeds and JAX memory setting; the Full GP `environment.json` records JAX 0.8.3, NumPyro 0.21.0 and device `cuda:0`. The public copies under `environment/` preserve every JSON key and value. The Phase 4D copy is byte-identical to the archived file; the Full GP copy differs only by a final newline added by the text-file editor. The notebook itself supplies the separate evidence that the JAX backend had to be GPU and the accelerator name had to contain `A100`.

The completion marker records seed 4, 26 result rows, state `complete`, completion time `2026-07-28T14:28:50.293830+00:00`, and frozen-data SHA-256 `c26c1d6e1f06ea10900ba508becb2fa12585d9abe34ea268d48c52bbce22b995`.

## Public-copy transformations

- The original notebook was not modified.
- One markdown cell was added at the beginning of the public copy to state the evidence and storage boundary.
- No code cell, parameter, stage flag or path used by the computation was changed.
- The source comments were already concise English; no Chinese or debugging comments required removal.
- `results_summary.csv` retains 11 selected columns from the authoritative 26-row CSV without recalculating values.
- `posterior_maps_seed4.png` was rendered from page 1 of the saved three-page posterior-map PDF at 120 dpi. All three source pages were visually checked before selection.

## Hashes of lightweight public files

| File | SHA-256 |
|---|---|
| Original source notebook | `e6781a5cc2c806752aa17bb5a7e109b2500dce6a2d196791d690f91ed909630c` |
| Public notebook copy | `36d78c105beda4cb13f11aab1b00338fa15fc4cd18a36860581c63202e5087f4` |
| Results summary | `b106d4602446a3d5202692b7047acd82f751cfaef99acb0bea17cbae97d64686` |
| Representative figure | `68c17f68c65b6f96a802655ce6b0c744ac6047ffa1e7958259e0b11d217ce721` |
| Public Phase 4D environment JSON | `497b28cc959062e8115d357297ccd2cd9823575495f07099aaac174c7b8247d4` |
| Public Full GP environment JSON | `cc42ac5e6313145b141e2401595b2218b7a2d84feb8872ae68ef53eca57f05c6` |

## Public file tree

```text
representative_64x64_experiment/
|-- README.md
|-- environment/
|   |-- README.md
|   |-- full_gp_environment.json
|   `-- phase4d_environment.json
|-- experiment_config.yaml
|-- phase4d_seed4_from_seed0_benchmark_colab.ipynb
|-- provenance.md
|-- results_summary.csv
`-- figures/
    `-- posterior_maps_seed4.png
```

## Exclusions

The public folder excludes the 3.2-GiB result archive, checkpoints, full posterior arrays, posterior-predictive arrays, caches, virtual environments, source ZIPs, private communication and machine-specific personal paths. Colab paths retained inside the notebook are part of the original executable workflow and do not identify a local user account. The project-level `pyproject.toml` and `uv.lock` were not used to fill gaps in the archived Colab record because a repository lockfile does not prove the exact packages installed in that completed remote runtime.
