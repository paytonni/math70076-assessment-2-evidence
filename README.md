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

The root `requirements.txt` separates two purposes. Its active entries install the lightweight public evidence environment used by the Question 1 downloader and tests and for inspecting saved tables and figures. Question 1 tests use the standard `unittest` runner. A second, clearly labelled reference section records the software environment of the representative DeepRV run without asking a normal evidence installation to recreate the GPU workflow.

The completed DeepRV 64 by 64 archive records Linux 6.6.122+ on x86_64 with glibc 2.35, Python 3.12.13, JAX 0.8.3, NumPyro 0.21.0 and JAX device `cuda:0`. The notebook additionally required the JAX GPU backend and an NVIDIA A100, and set `XLA_PYTHON_CLIENT_PREALLOCATE=false`. It checked Flax, Optax, Orbax Checkpoint, ArviZ, SciPy, Matplotlib, `dl4bi` and `dl4bi_sps`, but their exact installed versions were not retained in the completed archive and are therefore not invented here. When imports were missing, the notebook installed `dl4bi[benchmarks,cuda12]` from the project repository and required a runtime restart.

The recorded versions alone are not a complete reproduction environment. A full rerun also needs the archived Phase 4D source package, frozen data and pretrained decoder checkpoints, which are deliberately excluded from this public repository. The experiment configuration, environment records and reproduction boundary are documented under `question_5_project_organisation/representative_64x64_experiment/`.

Question 3/4 require R 4.5.1 for the recorded environment and `testthat` 3.2.3 for the included test suite. Runtime results are machine-specific; the saved benchmark is evidence of the recorded local run rather than a universal performance guarantee.
