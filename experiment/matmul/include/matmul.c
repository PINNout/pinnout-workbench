#include <stddef.h>
#include <math.h>

void matmul(_Float16 v1[16][16], _Float16 v2[16][16], _Float16 v3[16][16]) {
  _Float16 v4 = 0.0e+00f16;
  size_t v5 = 0;
  size_t v6 = 16;
  size_t v7 = 1;
  for (size_t i8 = v5; i8 < v6; i8 += v7) {
    for (size_t j9 = v5; j9 < v6; j9 += v7) {
      v3[i8][j9] = v4;
    }
  }
  for (size_t i10 = v5; i10 < v6; i10 += v7) {
    for (size_t j11 = v5; j11 < v6; j11 += v7) {
      for (size_t k12 = v5; k12 < v6; k12 += v7) {
        _Float16 v13 = v1[i10][k12];
        _Float16 v14 = v2[k12][j11];
        _Float16 v15 = v3[i10][j11];
        _Float16 v16 = v13 * v14;
        _Float16 v17 = v15 + v16;
        v3[i10][j11] = v17;
      }
    }
  }
  return;
}

