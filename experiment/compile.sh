#!/usr/bin/env bash
path="experiment/matmul/include" 
# lower JAX to C
stablehlo-opt experiment/matmul_from_jax.mlir \
	      --stablehlo-legalize-to-linalg \
	      --one-shot-bufferize="bufferize-function-boundaries function-boundary-type-conversion=identity-layout-map" \
	      --buffer-results-to-out-params="modify-public-functions \
hoist-static-allocs"   --convert-linalg-to-loops   --convert-to-emitc | \
    mlir-translate --mlir-to-cpp > $path/matmul.c

sed -i 's/void main(/void matmul(/' $path/matmul.c # hacky fix - replace with proper pass later

python3 experiment/generate_header.py 

# compile with gcc
# riscv64-unknown-elf-gcc \
    #     -march=rv32imc_xcvalu_xcvbi_xcvmac_xcvsimd_xcvelw_zfinx_zhinxmin \
    #     -mabi=ilp32 -x c -include stddef.h -c $path/matmul.c \
    #     -o experiment/matmul.o
