# DeepRV reproducibility inventory

Status: retrospective Assessment 2 inventory derived from locally inspected project files.

## Verified organisation

- Research plan, append-only experiment log, run index and research notes.
- Staged experiment scripts and notebooks across grid sides 8, 16, 32, 64 and 128.
- Evidence registries separating selected, superseded, incomplete and unresolved runs.
- Stored settings, seeds, output paths, checkpoints, completion markers and checksums.
- Dependency specification and lockfile, environment reports, tests and pre-commit configuration.
- Zulip-update assets and a group-meeting changelog for supervisor communication.
- Git configuration showing an upstream project and a personal fork. The complete history was unavailable during the audit, so no commit or branch-history claim is made.

## Storage limitation

The output store was approximately 33 GiB and contained overlapping output roots, historical archives and active checkpoint trees. Moving files merely to improve appearance could have damaged provenance or recovery. A future layout should keep code and small configuration under Git, place immutable large artifacts in managed external storage, and link them through one experiment registry containing hashes, environments and result status.

