//
//  Blake2b.swift
//  Polarwing
//
//  Created on 2025-11-24.
//  BLAKE2b implementation for Sui address generation
//

import Foundation

struct Blake2b {
    // BLAKE2b initialization vectors
    private static let iv: [UInt64] = [
        0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
        0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
        0x510e527fade682d1, 0x9b05688c2b3e6c1f,
        0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
    ]
    
    // BLAKE2b sigma permutations
    private static let sigma: [[Int]] = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
        [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
        [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
        [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
        [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
        [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
        [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
        [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
        [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0]
    ]
    
    /// Compute BLAKE2b hash
    /// - Parameters:
    ///   - data: Input data to hash
    ///   - outputLength: Desired output length in bytes (1-64)
    /// - Returns: Hash bytes
    static func hash(data: Data, outputLength: Int = 32) -> Data {
        assert(outputLength > 0 && outputLength <= 64, "Output length must be between 1 and 64")
        
        // Initialize state vector
        var h = iv
        h[0] ^= 0x01010000 ^ UInt64(outputLength)
        
        var t: [UInt64] = [0, 0] // Bytes compressed
        let f: [UInt64] = [0, 0] // Finalization flags
        
        // Process full blocks
        let blockSize = 128
        var offset = 0
        
        while offset + blockSize <= data.count {
            let block = data.subdata(in: offset..<offset + blockSize)
            t[0] = t[0] &+ UInt64(blockSize)
            if t[0] < UInt64(blockSize) {
                t[1] = t[1] &+ 1
            }
            compress(&h, block: block, t: t, f: [0, 0])
            offset += blockSize
        }
        
        // Process final block
        let remaining = data.count - offset
        var finalBlock = Data(count: blockSize)
        if remaining > 0 {
            finalBlock.replaceSubrange(0..<remaining, with: data.subdata(in: offset..<data.count))
        }
        
        t[0] = t[0] &+ UInt64(remaining)
        if t[0] < UInt64(remaining) {
            t[1] = t[1] &+ 1
        }
        
        compress(&h, block: finalBlock, t: t, f: [0xFFFFFFFFFFFFFFFF, 0])
        
        // Extract output bytes
        var result = Data()
        for i in 0..<outputLength {
            let wordIndex = i / 8
            let byteIndex = i % 8
            let byte = UInt8((h[wordIndex] >> (byteIndex * 8)) & 0xFF)
            result.append(byte)
        }
        
        return result
    }
    
    private static func compress(_ h: inout [UInt64], block: Data, t: [UInt64], f: [UInt64]) {
        var v = [UInt64](repeating: 0, count: 16)
        
        // Initialize working variables
        for i in 0..<8 {
            v[i] = h[i]
            v[i + 8] = iv[i]
        }
        
        v[12] ^= t[0]
        v[13] ^= t[1]
        v[14] ^= f[0]
        v[15] ^= f[1]
        
        // Parse message block
        var m = [UInt64](repeating: 0, count: 16)
        for i in 0..<16 {
            let offset = i * 8
            m[i] = block.withUnsafeBytes { ptr in
                guard offset + 8 <= ptr.count else { return 0 }
                return ptr.load(fromByteOffset: offset, as: UInt64.self)
            }
        }
        
        // 12 rounds
        for round in 0..<12 {
            let s = sigma[round % 10]
            
            // Mix columns
            g(&v, 0, 4, 8, 12, m[s[0]], m[s[1]])
            g(&v, 1, 5, 9, 13, m[s[2]], m[s[3]])
            g(&v, 2, 6, 10, 14, m[s[4]], m[s[5]])
            g(&v, 3, 7, 11, 15, m[s[6]], m[s[7]])
            
            // Mix diagonals
            g(&v, 0, 5, 10, 15, m[s[8]], m[s[9]])
            g(&v, 1, 6, 11, 12, m[s[10]], m[s[11]])
            g(&v, 2, 7, 8, 13, m[s[12]], m[s[13]])
            g(&v, 3, 4, 9, 14, m[s[14]], m[s[15]])
        }
        
        // Update state
        for i in 0..<8 {
            h[i] ^= v[i] ^ v[i + 8]
        }
    }
    
    private static func g(_ v: inout [UInt64], _ a: Int, _ b: Int, _ c: Int, _ d: Int, _ x: UInt64, _ y: UInt64) {
        v[a] = v[a] &+ v[b] &+ x
        v[d] = rotr(v[d] ^ v[a], 32)
        v[c] = v[c] &+ v[d]
        v[b] = rotr(v[b] ^ v[c], 24)
        v[a] = v[a] &+ v[b] &+ y
        v[d] = rotr(v[d] ^ v[a], 16)
        v[c] = v[c] &+ v[d]
        v[b] = rotr(v[b] ^ v[c], 63)
    }
    
    private static func rotr(_ value: UInt64, _ n: Int) -> UInt64 {
        return (value >> n) | (value << (64 - n))
    }
}
