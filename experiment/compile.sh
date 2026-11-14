#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)"

function_name=${1:?usage: $(basename "$0") <function_name>}
path="experiment/$function_name/include"

mkdir -p "$path"

# lower JAX to C
{
    if grep -q malloc "$path/$function_name.c"; then
	printf '#include <stdlib.h>\n'
    fi
    printf '#include <stddef.h>\n#include <math.h>\n\n'
    stablehlo-opt "experiment/${function_name}_from_jax.mlir" \
        --stablehlo-legalize-to-linalg \
        --one-shot-bufferize="bufferize-function-boundaries buffer-alignment=0 function-boundary-type-conversion=identity-layout-map" \
        --buffer-results-to-out-params="modify-public-functions hoist-static-allocs" \
        --convert-linalg-to-loops \
        --fold-memref-alias-ops \
        --affine-expand-index-ops \
        --lower-affine \
        --canonicalize \
        --convert-math-to-emitc="language-target=c99" \
        --convert-to-emitc \
    | mlir-translate --mlir-to-cpp
} > "$path/$function_name.c"

sed -i "s/void main(/void $function_name(/" "$path/$function_name.c" # hacky fix - replace with proper pass later

# compile with gcc
# riscv64-unknown-elf-gcc \
#     -march=rv32imc_xcvalu_xcvbi_xcvmac_xcvsimd_xcvelw_zfinx_zhinxmin \
#     -mabi=ilp32 \
#     -c "$path/$function_name.c" \
#     -o "experiment/$function_name.o"
