# Recorded runtime environment

These two JSON files preserve the keys and values recorded in the completed Phase 4D seed-4 result archive. They are the strongest available evidence for the software environment actually used by this representative experiment.

| Component | Recorded value | Source |
|---|---|---|
| Operating system | Linux 6.6.122+, x86_64, glibc 2.35 | both JSON records |
| Python | 3.12.13, GCC 11.4.0 build | both JSON records |
| JAX | 0.8.3 | Full GP environment record |
| NumPyro | 0.21.0 | Full GP environment record |
| JAX device | `cuda:0` | Full GP environment record |
| Accelerator requirement | NVIDIA A100 | notebook preflight check |
| JAX memory policy | `XLA_PYTHON_CLIENT_PREALLOCATE=false` | Phase 4D record and notebook |

The notebook checked imports for JAX, NumPyro, Flax, Optax, Orbax Checkpoint, ArviZ, SciPy, Matplotlib, `dl4bi` and `dl4bi_sps`. If imports failed, it installed `dl4bi[benchmarks,cuda12]` from the project's Git repository and required a runtime restart. Exact versions of the other imported libraries were not saved in the final archive, so this public record does not invent them or substitute versions from a later local environment.

The accelerator label comes from the executable preflight: the notebook stopped unless JAX reported the GPU backend and at least one device name contained `A100`. The raw JSON records identify the device only as `cuda:0`, so that distinction is retained rather than silently adding fields to the copied files.
