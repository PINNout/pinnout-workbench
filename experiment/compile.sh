#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)"

function_name=${1:?usage: $(basename "$0") <function_name>}
path="experiment/$function_name/"

mkdir -p "$path/src"
mkdir -p "$path/include"

# lower JAX to C
tmp=$(mktemp)
{
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
} > "$tmp"

{
    if grep -q malloc "$tmp"; then
        printf '#include <stdlib.h>\n'
    fi
    printf '#include <stddef.h>\n#include <math.h>\n\n'
    cat "$tmp"
} > "$path/src/$function_name.c"
rm "$tmp"

sed -i "s/void main(/void $function_name(/" "$path/src/$function_name.c" # hacky fix - replace with proper pass later

# Declaration header for the generated function: its first line, with " {" -> ";"
{
    printf '#pragma once\n#include <stddef.h>\n\n'
    grep -m1 "^void ${function_name}(" "$path/src/$function_name.c" | sed 's/ {$/;/'
} > "$path/include/$function_name.h"

sed "s/@NAME@/$function_name/g" "experiment/templates/CMakeLists.txt.in" > "$path/CMakeLists.txt"

sed "s/@NAME@/$function_name/g" "experiment/templates/test.c.in" > "$path/src/test.c"

grep -qx "add_subdirectory($function_name)" experiment/CMakeLists.txt \
  || echo "add_subdirectory($function_name)" >> experiment/CMakeLists.txt

# compile with gcc
# riscv64-unknown-elf-gcc \
#     -march=rv32imc_xcvalu_xcvbi_xcvmac_xcvsimd_xcvelw_zfinx_zhinxmin \
#     -mabi=ilp32 \
#     -c "$path/$function_name.c" \
#     -o "experiment/$function_name.o"
