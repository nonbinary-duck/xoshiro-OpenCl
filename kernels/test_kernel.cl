#pragma once
#ifndef CL_360679_KERNELS_TEST_KERNEL
#define CL_360679_KERNELS_TEST_KERNEL 1

#include "kernels/xoshiro256**.cl"


/**
 * @brief A kernel to make a simple noise image
 * 
 * @note Size of outputImage MUST be a multiple of eight
 */
kernel void makeSimpleNoiseImage(global uchar *outputImage)
{
    // Get the position we have in the image
    size_t i = get_global_id(0);

    // Initalise a state based on our position
    ulong4 state = xoshiro256stst_init(i);

    // Then we can set 8 pixels to a random value
    // Pointer casting "represents an unchecked assertion that the address is correctly aligned"
    ((ulong*)outputImage)[i] = xoshiro256stst_next(&state);
}


#endif // End CL_360679_KERNELS_TEST_KERNEL
