#include <stddef.h>
#include <stdint.h>

#include "eventunit.h"
#include "fsync.h"
#include "performance_utils.h"
#include "tile.h"

#include "kernels_compare_utils.h"

#include "matmul.c"
#include "matmul_data.h"

int init_fysnc() {
  fsync_init();
  return 0;
}

int init_event_unit() {
  eu_init();
  eu_fsync_init(0);
  return 0;
}

void sync() {
  fsync_sync_global();
  eu_fsync_wait(WFE);
}

int check_result(const uintptr_t output, const uintptr_t expected_output)
{
  return compare_fp16_bitwise(output, expected_output, 256);
}

int main() {
  uint32_t cycle_start;
  uint32_t cycle_stop;
  int hid;
  int ret;

  uint16_t C[256];

  hid = get_hartid();

  perf_init();

  ret = init_fysnc();
  if (ret) {
    printf("[CV32 (%d)] Fsync initialization failed with errno: %d\n", HID, ret);
    return ret;
  }

  ret = init_event_unit();
  if (ret) {
    printf("[CV32 (%d)] Event Unit initialization failed with errno: %d\n", HID, ret);
    return ret;
  }

  sync();

  cycle_start = perf_get_cycles();
  if (hid == 0)
    matmul((_Float16 (*)[16])A, (_Float16 (*)[16])B, (_Float16 (*)[16])C);
  cycle_stop = perf_get_cycles();

  printf("[CV32 (%d)] Run completed in %d cycles\n", hid,
         cycle_stop - cycle_start);
  sync();

  if (hid == 0) {
    ret = check_result((const uintptr_t) C, (const uintptr_t) C_expected);
    printf("[CV32] Test completed with %d mismatches\n", ret);
  }

  sync();
  return ret;
}
