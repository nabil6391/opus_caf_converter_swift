//
//  File.swift
//  
//
//  Created by hamza on 20/7/23.
//

import Foundation

extension Data {
    func readUInt32(at offset: Int) -> UInt32? {
        guard offset + 4 <= count else { return nil }
        let value = withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
        return UInt32(bigEndian: value)
    }
    
    func readUInt64(at offset: Int) -> UInt64? {
        guard offset + 8 <= count else { return nil }
        let value = withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self) }
        return UInt64(bigEndian: value)
    }
    
    mutating func writeInt16(_ value: Int16) {
        var value = value.bigEndian
        
        withUnsafePointer(to: &value) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    
    mutating func writeUInt32(_ value: UInt32) {
        var value = value.bigEndian
        withUnsafePointer(to: &value) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    mutating func writeInt32(_ value: Int32) {
        var value = value.bigEndian
        withUnsafePointer(to: &value) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    mutating func writeInt64(_ value: Int64) {
        var value = value.bigEndian
        withUnsafePointer(to: &value) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    
    mutating func writeUInt64(_ value: UInt64) {
        var value = value.bigEndian
        withUnsafePointer(to: &value) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    
    mutating func writeFloat(_ value: Float) {
        var value = value.bitPattern.bigEndian
        withUnsafePointer(to: &value) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    
    mutating func writeFloat64(_ value: Float64) {
        var value = value.bitPattern.bigEndian
        withUnsafePointer(to: &value) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    
    func readString(at index: inout Int) throws -> String {
        var bytes: [UInt8] = []
        while index < self.count {
            let byte = self[index]
            index += 1
            bytes.append(byte)
            if byte == 0 {
                break
            }
        }
        guard let string = String(bytes: bytes, encoding: .utf8) else {
            throw NSError(domain: "readString", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 string"])
        }
        return string
    }
    
    mutating func writeString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
            self.append(0)
        }
    }
    
    mutating func encodeInt(_ value: UInt64) {
        var byts: [UInt8] = []
        var cur = value
        while true {
            let val: UInt8 = UInt8(cur & 127)
            cur = cur >> 7
            byts.append(val)
            if cur == 0 {
                break
            }
        }
        for i in (0..<byts.count).reversed() {
            var val = byts[i]
            if i > 0 {
                val = val | 0x80
            }
            self.append(val)
        }
    }
    
    func decodeInt(at index: inout Int) throws -> UInt64 {
        var result: UInt64 = 0
        for _ in 0..<8 {
            guard index < self.count else {
                throw NSError(domain: "decodeInt", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected end of data"])
            }
            let byte = self[index]
            index += 1
            result = (result << 7) | UInt64(byte & 127)
            if byte & 128 == 0 {
                return result
            }
        }
        return result
    }
    
    mutating func writeFourByteString(_ data: Data) {
        self.append(data)
    }
}

extension InputStream {
    func readFull(into buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        var totalBytesRead = 0
        
        while totalBytesRead < maxLength {
            let bytesRead = self.read(buffer, maxLength: maxLength - totalBytesRead)
            
            if bytesRead < 0 {
                throw self.streamError ?? NSError(domain: "NSStreamErrorDomain", code: Int(errno), userInfo: nil)
            }
            
            if bytesRead == 0 {
                if totalBytesRead == 0 {
                    throw NSError(domain: "NSStreamErrorDomain", code: Int(EOF), userInfo: nil)
                } else {
                    throw NSError(domain: "NSPOSIXErrorDomain", code: Int(EOF), userInfo: nil)
                }
            }
            
            totalBytesRead += bytesRead
        }
        
        return totalBytesRead
    }
}
