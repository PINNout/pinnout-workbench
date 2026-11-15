# This file contains a 1D Poisson-Dirichlet PINN defined in JAX that is exported
# to StableHLO in order for a full-compilation pipeline to be tested on a
# representative workload.

import jax
import jax.numpy as jnp
from jax import random
from jax import grad, jit
import numpy as np

from testgen import write_data, export_mlir

from pathlib import Path

here = Path(__file__).resolve().parent
out = here / "poisson_pinn_train" / "include" / "poisson_pinn_train_data.h"

def random_layer_params(m, n, key, scale=1e-2):
    w_key, b_key = random.split(key)
    return scale * random.normal(w_key, (n, m)), scale * random.normal(b_key, (n,))

def init_network_params(sizes, key):
    keys = random.split(key, len(sizes))
    return [random_layer_params(m, n, k) for m, n, k in zip(sizes[:-1], sizes[1:], keys)]

def network(params, x):
    activations = x
    for w, b in params[:-1]:
        outputs = jnp.dot(w, activations) + b
        activations = jnp.tanh(outputs)

    final_w, final_b = params[-1]
    return jnp.dot(final_w, activations) + final_b

batched_predict = jax.vmap(network, in_axes=(None,0))

def single_u(params, x):
    return network(params, jnp.array([x]))[0]

def u_xx(params, x):
    first = jax.grad(single_u, argnums=1)
    second = jax.grad(first, argnums=1)
    batched_xx = jax.vmap(second, in_axes=(None, 0))
    flattened_x = x.reshape(-1)
    return batched_xx(params, flattened_x).reshape(len(x),1)

def loss(params, x):
    residual_ms = jnp.mean((-u_xx(params, x) - np.pi ** 2 * jnp.sin(np.pi * x)) ** 2)
    boundaries = jnp.array([[-1.0], [1.0]])
    boundary_loss = jnp.mean(batched_predict(params, boundaries) ** 2)
    return residual_ms + boundary_loss

# the exported function:
@jit
def poisson_pinn_train(params, x):
    lr = 0.01
    gradient = jax.grad(loss)
    grads = gradient(params, x)
    return jax.tree.map(lambda a, b: a-lr*b, params, grads)

if __name__ == "__main__":

    layer_sizes = [1, 50, 50, 50, 1]
    params = init_network_params(layer_sizes, random.key(0))
    x = random.uniform(random.key(1), (16,1), minval=-1, maxval=1)
    
    new_params = poisson_pinn_train(params, x)
    leaves = jax.tree_util.tree_leaves((params, x))
    inputs = {f"in{i}": leaf for i, leaf in enumerate(leaves)}
    out_leaves = jax.tree_util.tree_leaves(new_params)
    outputs = {f"out{i}": leaf for i, leaf in enumerate(out_leaves)}
    write_data("poisson_pinn_train", inputs, outputs, out)
    export_mlir(poisson_pinn_train, [params, x], here / "poisson_pinn_train_from_jax.mlir")

