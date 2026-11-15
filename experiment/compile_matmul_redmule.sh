#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)"
path="experiment/matmul_redmule/"


stablehlo-opt "experiment/matmul_redmule_from_jax.mlir" \
        --stablehlo-legalize-to-linalg \
        --one-shot-bufferize="bufferize-function-boundaries buffer-alignment=0 function-boundary-type-conversion=identity-layout-map" \
        --buffer-results-to-out-params="modify-public-functions hoist-static-allocs" \
        --convert-linalg-to-std \
        --fold-memref-alias-ops \
        --affine-expand-index-ops \
        --lower-affine \
        --canonicalize \
        --convert-math-to-emitc="language-target=c99" \
        --convert-to-emitc \
    | mlir-translate --mlir-to-cpp
