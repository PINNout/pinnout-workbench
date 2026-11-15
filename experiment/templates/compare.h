// Output comparison for the generated tests. 
#pragma once

#include <stddef.h>
#include <stdint.h>

#include "kernels_compare_utils.h" 

#ifndef F32_ATOL
#define F32_ATOL 1e-5f
#endif
#ifndef F32_RTOL
#define F32_RTOL 1e-4f
#endif

// Print at most this many mismatches per output; the count is always complete.
#define MAX_REPORTED_MISMATCHES 10

typedef enum {
    DT_F16,
    DT_F32
} dtype_t;

// Field order matches the table that testgen.py writes.
typedef struct {
    const void *result;
    const void *expected;
    size_t length;
    dtype_t dtype;
} output_t;

// Reinterpret the 32 bits of an f32 value without breaking aliasing rules.
typedef union {
    uint32_t bits;
    float value;
} f32_bits_t;

static inline float f32_abs(float x)
{
    return x < 0.0f ? -x : x;
}

// NaN or Inf: exponent bits all ones.
static inline int f32_is_invalid(uint32_t bits)
{
    return (bits & 0x7F800000u) == 0x7F800000u;
}

static inline int compare_f32(const uint32_t *res, const uint32_t *exp, size_t len)
{
    int n_mismatch = 0;
    float max_err  = 0.0f;

    for (size_t i = 0; i < len; i++) {
        f32_bits_t r = { .bits = res[i] };
        f32_bits_t e = { .bits = exp[i] };

        if (f32_is_invalid(r.bits) || f32_is_invalid(e.bits)) {
            if (n_mismatch < MAX_REPORTED_MISMATCHES)
                printf("[CV32] Invalid f32 value at idx %d\t-\texpected: %x\t-\tcomputed: %x\n",
                       (int)i, e.bits, r.bits);
            n_mismatch++;
            continue;
        }

        float err = f32_abs(r.value - e.value);
        if (err > max_err)
            max_err = err;

        if (err > F32_ATOL + F32_RTOL * f32_abs(e.value)) {
            if (n_mismatch < MAX_REPORTED_MISMATCHES)
                printf("[CV32] Mismatch at index %d\t-\texpected: %x\t-\tcomputed: %x\n",
                       (int)i, e.bits, r.bits);
            n_mismatch++;
        }
    }

    // The SDK printf has no %f, so the error is printed in units of 1e-6.
    printf("[CV32] f32: %d of %d outside tolerance - max abs error: %u e-6\n",
           n_mismatch, (int)len, (uint32_t)(max_err * 1e6f));

    return n_mismatch;
}

// Number of mismatches for one output. An unknown dtype counts as all wrong.
static inline int compare_output(const output_t *o)
{
    switch (o->dtype) {
    case DT_F16:
        return compare_fp16_bitwise((uintptr_t)o->result, (uintptr_t)o->expected, (int)o->length);
    case DT_F32:
        return compare_f32(o->result, o->expected, o->length);
    }

    printf("[CV32] Unknown dtype %d\n", (int)o->dtype);
    return (int)o->length;
}
