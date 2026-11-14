#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
source scripts/config.sh

LOG_DIR="$PWD"/logs/verify

failed=0
test_name=${1:?usage: $(basename "$0") <test-name>}

if ! [ -x magia-sdk/gvsoc/install/bin/gvrun ] || ! [ -x MAGIA/verilator/build/obj_dir/Vmagia_tb ]; then
    echo "Error: Run scripts/setup.sh first"
    exit 1
fi

if ! (cd magia-sdk && make build test="$test_name" tiles="$tiles" spatz="$spatz"); then
    exit 1
fi

mkdir -p "$LOG_DIR"

N=$((tiles * tiles))

# ----------------------------------------
# Run on GVSoC
# ----------------------------------------
echo "Running on GVSoC..."
if ! (cd magia-sdk && make run test="$test_name" platform=gvsoc tiles="$tiles" spatz="$spatz" 2>&1 | tee "$LOG_DIR"/gvsoc.log); then
    failed=1
fi

gvsoc_passes=0

if grep -qF "Current kill count is $N. Number of cores to wait is $N." "$LOG_DIR"/gvsoc.log; then
    gvsoc_passes=$((gvsoc_passes + 1))
else
    echo "GVSoC: ERROR | kill count does not match expected result"
    failed=1
fi

if [ "$gvsoc_passes" -eq 1 ]; then
    printf "\nGVSoC: SUCCESS\n"
fi
