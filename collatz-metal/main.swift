//
//  main.swift
//  collatz-metal
//
//  Created by Sebastian Provenzano on 12/17/21.
//
//  It calculates parallel Collatz sequence lengths and prints the maximum length.
//  Please note, online calculators seem to always give a sequence length that is less by 1.
//  I made this one to match the results of the code from my class.

import Foundation
import MetalKit

let num = 1000_000 // set this to whatever you want

collatz(tempNumSeq : num)

//collatz(tempNumSeq : 100_000_000) // This is fine
//collatz(tempNumSeq : 1_000_000_000) // This crashes...

func collatz(tempNumSeq : Int) {
    var numSeq = tempNumSeq
    var maxLen = 0
    let device = MTLCreateSystemDefaultDevice()
    
    // I made an optional result buffer.
    // This is just so you can view the individual sequence lengths, if you want
    var result = [Int].init(repeating: 1, count: numSeq)
    var memory: UnsafeMutableRawPointer? = nil
    let alignment = 0x1000
    let length = MemoryLayout<Int>.stride * numSeq
    let allocationSize = (length + alignment - 1) & (~(alignment - 1))
    posix_memalign(&memory, alignment, allocationSize)
    let resultBuffer = device?.makeBuffer(bytesNoCopy: memory!,
                        length: allocationSize,
                        options: [],
                        deallocator: { (pointer: UnsafeMutableRawPointer, _: Int) in free(pointer)})
    resultBuffer!.contents().bindMemory(to: Int.self, capacity: length)
    
    let commandQueue = device?.makeCommandQueue()
    let GPUFunctionLibrary = device?.makeDefaultLibrary()
    let collatzGPUFunction = GPUFunctionLibrary?.makeFunction(name: "collatz_metal")
    
    var collatzComputePipelineState: MTLComputePipelineState!
    do {
        collatzComputePipelineState = try device?.makeComputePipelineState(function: collatzGPUFunction!)
    } catch {
        print(error)
    }
    
    // Below is the whole reason I have "tempNumSeq" and "numSeq"
    // I get "Cannot pass immutable value as inout argument" if I write "bytes: &<an argument to collatz()>"
    let numBuf = device?.makeBuffer(bytes: &numSeq, length: MemoryLayout<Int>.size, options: .storageModeShared)
    let maxLenBuf = device?.makeBuffer(bytes: &maxLen, length: MemoryLayout<Int>.size, options: .storageModeShared)
    
    let commandBuf = commandQueue?.makeCommandBuffer()
    let commandEncoder = commandBuf?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(collatzComputePipelineState)
    
    commandEncoder?.setBuffer(numBuf, offset: 0, index: 0)
    commandEncoder?.setBuffer(maxLenBuf, offset: 0, index: 1)
    commandEncoder?.setBuffer(resultBuffer, offset: 0, index: 2)
    
    let threadsPerGrid = MTLSize(width: numSeq, height: 1, depth: 1)
    let maxThreadsPerGroup = collatzComputePipelineState.maxTotalThreadsPerThreadgroup 
    let threadsPerThreadGroup = MTLSize(width: maxThreadsPerGroup, height: 1, depth: 1)
    
    commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    commandEncoder?.endEncoding()

    // Start the timer!
    let computeStart = CFAbsoluteTimeGetCurrent()
    // Run GPU code!
    commandBuf?.commit()
    commandBuf?.waitUntilCompleted()
    // Stop the timer!
    let computeEnd = CFAbsoluteTimeGetCurrent()
    let computeElapsed = computeEnd - computeStart
    
    // Optional result storage here
    memmove(&result[0], resultBuffer?.contents(), length)
 
    let maxLenBufPtr = maxLenBuf?.contents().bindMemory(to: Int.self, capacity: 1)

    // You can print the result buffer, if you want. It can be long though!
    // Please be aware that these values are sometimes corrupted. I have no idea why.
    // Just run the program a few times. :D
//    for i in 0...result.count-1 {
//        print(i+1, " : ", result[i])
//    }
    
    print()
    print("compute time is \(String(format: "%.05f", computeElapsed))")
    // Sometimes compute time is n, sometimes it is 2n. It seems to alternate. It's never in between.
    print("number of sequences is", tempNumSeq)
    print("max sequence length is", maxLenBufPtr!.pointee)
    print()
}

