//
//  main.swift
//  collatz-metal
//
//  Created by Sebastian Provenzano on 12/17/21.
//

import Foundation
import MetalKit

collatz(tempNumSeq : 10000000) // set this to whatever you want

func collatz(tempNumSeq : Int) {
    var numSeq = tempNumSeq
    var maxLen = 0
    let threadWidth = numSeq
    
    let device = MTLCreateSystemDefaultDevice()
    
    print()
    
    let commandQueue = device?.makeCommandQueue()
    let GPUFunctionLibrary = device?.makeDefaultLibrary()
    let collatzGPUFunction = GPUFunctionLibrary?.makeFunction(name: "collatz_metal")
    
    var collatzComputePipelineState: MTLComputePipelineState!
    do {
        collatzComputePipelineState = try device?.makeComputePipelineState(function: collatzGPUFunction!)
    } catch {
        print(error)
    }
    
    let numBuf = device?.makeBuffer(bytes: &numSeq, length: MemoryLayout<Int>.size, options: .storageModeShared)
    let maxLenBuf = device?.makeBuffer(bytes: &maxLen, length: MemoryLayout<Int>.size, options: .storageModeShared)
    
    let commandBuf = commandQueue?.makeCommandBuffer()
    
    let commandEncoder = commandBuf?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(collatzComputePipelineState)
    
    commandEncoder?.setBuffer(numBuf, offset: 0, index: 0)
    commandEncoder?.setBuffer(maxLenBuf, offset: 0, index: 1)
    
    let threadsPerGrid = MTLSize(width: threadWidth, height: 1, depth: 1)
    let maxThreadsPerGroup = collatzComputePipelineState.maxTotalThreadsPerThreadgroup
    let threadsPerThreadGroup = MTLSize(width: maxThreadsPerGroup, height: 1, depth: 1)
    
    commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    
    commandEncoder?.endEncoding()
    
    let computeStart = CFAbsoluteTimeGetCurrent()
    commandBuf?.commit()
    commandBuf?.waitUntilCompleted()
    let computeEnd = CFAbsoluteTimeGetCurrent() //
    
    let maxLenBufPtr = maxLenBuf?.contents().bindMemory(to: Int.self, capacity: 1)

    let computeElapsed = computeEnd - computeStart
    
    print("num is ", tempNumSeq)
    print("max sequence length is", maxLenBufPtr!.pointee)
    print("threadWidth is ", threadWidth)
    print("compute time is \(String(format: "%.05f", computeElapsed))")

}

