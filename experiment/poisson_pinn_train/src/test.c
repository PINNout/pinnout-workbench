// Test harness template. compile.sh replaces poisson_pinn_train and writes the result to
// experiment/poisson_pinn_train/src/test.c. Everything test-specific (the call, the
// arrays, the list of outputs) comes from the generated poisson_pinn_train_data.h.

#include <stdint.h>

#include "eventunit.h"
#include "fsync.h"
#include "performance_utils.h"
#include "tile.h"

#include "poisson_pinn_train_data.h" // run_kernel(), outputs[], NUM_OUTPUTS

static void init(void)
{
    fsync_init();
    eu_init();
    eu_fsync_init(0);
}

static void sync(void)
{
    fsync_sync_global();
    eu_fsync_wait(WFE);
}

int main(void)
{
    uint32_t cycle_start;
    uint32_t cycle_stop;
    int hid = get_hartid();
    int mismatches = 0;

    perf_init();
    init();
    sync();

    // Single-tile test: only tile 0 computes, the others wait at the barriers.
    if (hid == 0) {
        cycle_start = perf_get_cycles();
        run_kernel();
        cycle_stop = perf_get_cycles();
        printf("[CV32 (%d)] Run completed in %d cycles\n", hid, cycle_stop - cycle_start);
    }

    sync();

    if (hid == 0) {
        for (int i = 0; i < NUM_OUTPUTS; i++)
            mismatches += compare_output(&outputs[i]);
        printf("[CV32] Test completed with %d mismatches\n", mismatches);
    }

    sync();
    return mismatches;
}
