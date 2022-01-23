//
//  collatz.metal
//  collatz-metal
//
//  Created by Sebastian Provenzano on 12/17/21.
//

#include <metal_stdlib>

using namespace metal;

kernel void collatz_metal(device int*  num [[buffer(0)]],
                          device atomic_int*  maxlen [[buffer(1)]],
                          //device int* lens [[buffer(2)]],
                          device int *resultArray [[buffer(2)]],
                          uint i [[thread_position_in_grid]])
{
    // compute sequence lengths
    // 2d way
    // int index = i[0] * i[1];
    
    // 1d way
    int index = i;

    if (index < *num) {
        long val = index+1;
        int len = 1;
        while (val != 1) {
            len++;
            if ((val % 2) == 0) {
                val = val / 2;  // even
            } else {
                val = 3 * val + 1;  // odd
            }
        }
        
        // This is for that optional result array
        resultArray[index*2] = len;
        atomic_fetch_max_explicit( maxlen, len, memory_order_relaxed ); // bottleneck
    }
}
