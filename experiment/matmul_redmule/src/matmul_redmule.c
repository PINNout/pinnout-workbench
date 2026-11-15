#include <stddef.h>
#include <stdint.h>
#include "tile.h"
#include "idma.h"
#include "redmule.h"
#include "eventunit.h"

void matmul_redmule(_Float16 A[16][16], _Float16 B[16][16],
                    _Float16 C[16][16]) {
  uint32_t l1_tile_base = get_l1_base(get_hartid());
  uint32_t l1_A = l1_tile_base;
  uint32_t l1_B = l1_tile_base + 512;
  uint32_t l1_C = l1_tile_base + 1024;

  idma_memcpy_1d(0, (uint32_t)A, l1_A, 512);
  eu_idma_wait_a2o(WFE);

  idma_memcpy_1d(0, (uint32_t)B, l1_B, 512);
  eu_idma_wait_a2o(WFE);

  idma_memcpy_1d(0, (uint32_t)C, l1_C, 512);
  eu_idma_wait_a2o(WFE);

  redmule_gemm(l1_A, l1_B, l1_C, 16, 16, 16);
  eu_redmule_wait(WFE);

  idma_memcpy_1d(1, (uint32_t)C, l1_C, 512);
  eu_idma_wait_o2a(WFE);
}

