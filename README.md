# MATH70076 Assessment 2 supporting evidence

This public repository contains selected, privacy-safe evidence for five reflective responses in MATH70076 Data Science Assessment 2. It was assembled after the underlying projects specifically for the assessment. It is not presented as the historical repository used for the MATH70093 coursework or the DeepRV research project.

## Contents

- `question_1_data_acquisition`: London Air Quality Network API downloader, tests and a saved-run summary.
- `question_2_visualisation`: the existing DeepRV 64 by 64 posterior-comparison plotting script, helper and final PNG.
- `question_3_function_design`: the copied coursework implementation and the separately labelled Assessment 2 redesign, Stage 2 target specialisation and tests.
- `question_4_profiling`: saved `Rprof()` evidence, the same-batch five-run benchmark, validation outputs and figures.
- `question_5_project_organisation`: retrospective, privacy-safe evidence for the DeepRV organisation and reproducibility case.
- `report`: an appendix-to-repository map and disclosure boundary.

Each question directory explains what was original, what was added during Assessment 2, and what can be reproduced from the public files.

## Reproduction overview

The root `requirements.txt` describes only the lightweight public evidence environment: the Question 1 downloader and tests, and the Python packages used to inspect saved tables and figures. Question 1 tests use the standard `unittest` runner.

The representative DeepRV computation has a separate environment boundary. Its verified configuration records Linux x86_64, Python 3.12.13 and an NVIDIA A100 GPU. The saved notebook checks JAX, NumPyro, Flax, Optax, Orbax, ArviZ, SciPy, Matplotlib, `dl4bi` and `dl4bi_sps`, and installs `dl4bi[benchmarks,cuda12]` from the recorded project fork when needed. These GPU dependencies are deliberately not added to the root requirements because a full rerun also needs the archived source package, frozen data and pretrained decoder checkpoints that are not published here. See `question_5_project_organisation/representative_64x64_experiment/experiment_config.yaml` and its README for the confirmed settings and reproduction boundary.

Question 3/4 require R 4.5.1 for the recorded environment and `testthat` 3.2.3 for the included test suite. Runtime results are machine-specific; the saved benchmark is evidence of the recorded local run rather than a universal performance guarantee.
