#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
source scripts/config.sh

LOG_DIR="$PWD"/logs/verify

test=test_helloworld
failed=0

if ! [ -x magia-sdk/gvsoc/install/bin/gvrun ] || ! [ -x MAGIA/verilator/build/obj_dir/Vmagia_tb ]; then
    echo "Error: Run scripts/setup.sh first"
    exit 1
fi

if ! (cd magia-sdk && make build test="$test" tiles="$tiles" spatz="$spatz"); then
    exit 1
fi

mkdir -p "$LOG_DIR"

N=$((tiles * tiles))

# ----------------------------------------
# Run on GVSoC
# ----------------------------------------
echo "Running on GVSoC..."
if ! (cd magia-sdk && make run test="$test" platform=gvsoc tiles="$tiles" spatz="$spatz" 2>&1 | tee "$LOG_DIR"/gvsoc.log); then
    failed=1
fi

gvsoc_passes=0

if grep -qF "Current kill count is $N. Number of cores to wait is $N." "$LOG_DIR"/gvsoc.log; then
    gvsoc_passes=$((gvsoc_passes + 1))
else
    echo "GVSoC: ERROR | kill count does not match expected result"
    failed=1
fi

count=$(grep -cF "Hello world! 0xc100bac7" "$LOG_DIR"/gvsoc.log || true)
if [ "$count" -eq $N ]; then
    gvsoc_passes=$((gvsoc_passes + 1))
else
    echo "GVSoC : FAILURE | output does not match expected result"
    failed=1
fi

if [ "$gvsoc_passes" -eq 2 ]; then
    printf "\nGVSoC: SUCCESS\n"
fi

# ----------------------------------------
# Run on Verilator
# ----------------------------------------
echo "Running on Verilator..."
if ! (cd magia-sdk && timeout 15m make run test="$test" platform=verilator tiles="$tiles" spatz="$spatz" 2>&1 | tee "$LOG_DIR"/verilator.log); then
    failed=1
fi

verilator_passes=0

count=$(grep -cF "Hello world! 0xc100bac7" "$LOG_DIR"/verilator.log || true)
if [ "$count" -eq $N ]; then
    verilator_passes=$((verilator_passes + 1))
else
    echo "VERILATOR : FAILURE | output does not match expected result"
    failed=1
fi

if magia-sdk/scripts/sim_ret_errors_verilator.sh "$LOG_DIR"/verilator.log; then
    verilator_passes=$((verilator_passes + 1))
else
    echo "VERILATOR: ERROR | SDK checker failed"
    failed=1
fi

if [ "$verilator_passes" -eq 2 ]; then
    printf "\nVERILATOR: SUCCESS\n"
fi

# ----------------------------------------
# Compare Outputs
# ----------------------------------------
if [ "$verilator_passes" -eq 2 ] && [ "$gvsoc_passes" -eq 2 ]; then
    if diff <(grep -o 'Hello world!.*' "$LOG_DIR"/verilator.log | sort) \
	    <(grep -o 'Hello world!.*' "$LOG_DIR"/gvsoc.log | sort); then
	echo "COMPARISON: PASSED"
	
    else
	echo "COMPARISON FAILED"
	failed=1
    fi
fi

if [ "$failed" -ne 1 ]; then
    printf "\n|||   ALL CHECKS PASSED   ||||\n"
fi

exit "$failed"
