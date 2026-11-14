# This file contains a simple matmul defined in JAX that is exported to
# StableHLO in order for a full-compilation pipeline to be tested on a basic
# workload.

import jax
import jax.numpy as jnp
from jax import jit, random

@jit
def matmul(m1, m2):
    return jnp.dot(m1, m2)

m1 = random.normal(random.key(1), (16,16), dtype=jnp.float16)
m2 = random.normal(random.key(2), (16,16), dtype=jnp.float16)

stablehlo_matmul = (jax.export.export(matmul)(m1, m2)).mlir_module()

with open("matmul_from_jax.mlir", "w") as file:
    file.write(stablehlo_matmul)
