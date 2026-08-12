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

## Evidence boundaries

The repository deliberately excludes:

- assessment instruction PDFs and the final assessment PDF;
- the original MATH70093 submission PDF and R Markdown;
- private Teams or Zulip messages and files containing other students' identities;
- API credentials, environment files and tokens;
- absolute personal paths, virtual environments and caches;
- large raw API downloads, DeepRV posterior archives, checkpoints and full sampler RDS objects;
- copied `.git` directories or claims about Git history that could not be verified.

The London Air source data are public, but only a concise saved-run summary is included. DeepRV raw posterior archives are too large for this evidence repository; the plotting code and final figure remain inspectable, while exact reproduction requires the original archives through the documented environment variable.

## Reproduction overview

Python dependencies are listed in `requirements.txt`. Question 1 tests use the standard `unittest` runner. Question 3/4 require R 4.5.1 for the recorded environment and `testthat` 3.2.3 for the included test suite. Runtime results are machine-specific; the saved benchmark is evidence of the recorded local run rather than a universal performance guarantee.
