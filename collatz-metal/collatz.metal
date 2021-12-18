//
//  collatz.metal
//  collatz-metal
//
//  Created by Sebastian Provenzano on 12/17/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void collatz_metal(device int*  num [[buffer(0)]],
                          device int*  maxlen [[buffer(1)]],
                          uint i [[thread_position_in_grid]])
{
    // compute sequence lengths
    int len2 = 0;
    if (i < *num) {
        long val = i+1;
        int len = 1;
        while (val != 1) {
            len++;
            if ((val % 2) == 0) {
                val = val / 2;  // even
            } else {
                val = 3 * val + 1;  // odd
            }
        }
        
        // this mess right here
        threadgroup atomic_int index;
        atomic_store_explicit( &index, *maxlen, memory_order_relaxed );
        // threadgroup_barrier( mem_flags::mem_none ); // do i need this?
        atomic_fetch_max_explicit( &index, len, memory_order_relaxed ); // bad bottleneck
        *maxlen = atomic_load_explicit( &index, memory_order_relaxed);
        
    }
}
