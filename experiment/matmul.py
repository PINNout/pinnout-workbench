# This file contains a simple matmul defined in JAX that is exported to
# StableHLO in order for a full-compilation pipeline to be tested on a basic
# workload.
from testgen import write_data, export_mlir

import jax
import jax.numpy as jnp
from jax import jit, random

from pathlib import Path

here = Path(__file__).resolve().parent
out = here / "matmul" / "include" / "matmul_data.h"


# the exported function:
@jit
def matmul(m1, m2):
    return jnp.dot(m1, m2)

if __name__ == "__main__":
    m1 = random.normal(random.key(1), (16,16), dtype=jnp.float16)
    m2 = random.normal(random.key(2), (16,16), dtype=jnp.float16)
    C = matmul(m1, m2)

    inputs = {"A": m1, "B": m2}

    write_data("matmul", inputs, {"C": C}, out)
    export_mlir(matmul, list(inputs.values()), here / "matmul_from_jax.mlir")
