//
//  File.swift
//  
//
//  Created by hamza on 20/7/23.
//

import Foundation

struct FourByteString: Equatable {
    let bytes: (UInt8, UInt8, UInt8, UInt8)
    
    init(_ string: String) {
        guard string.count == 4 else {
            self.bytes =  (0,0,0,0)
            return
        }
        
        let stringBytes = Array(string.utf8)
        guard stringBytes.count == 4 else {
            self.bytes =  (0,0,0,0)
            return
        }
        
        self.bytes = (stringBytes[0], stringBytes[1], stringBytes[2], stringBytes[3])
    }
    
    static func ==(lhs: FourByteString, rhs: FourByteString) -> Bool {
        return lhs.bytes == rhs.bytes
    }
    
    func encode() -> Data {
        var data = Data()
        data.append(bytes.0)
        data.append(bytes.1)
        data.append(bytes.2)
        data.append(bytes.3)
        return data
    }
}

struct ChunkTypes {
    static let audioDescription = FourByteString("desc")
    static let channelLayout = FourByteString("chan")
    static let information = FourByteString("info")
    static let audioData = FourByteString("data")
    static let packetTable = FourByteString("pakt")
    static let midi = FourByteString("midi")
}

struct CafFile {
    var fileHeader: FileHeader
    var chunks: [Chunk]
    
    func encode() -> Data {
        var data = Data()
        
        data.append(fileHeader.encode())
        for chunk in chunks {
            data.append(chunk.encode())
        }
        return data
    }
}

struct ChunkHeader {
    var chunkType: FourByteString
    var chunkSize: Int64
    
    func encode() -> Data {
        var data = Data()
        let chunkTypeData = chunkType.encode()
        data.append(chunkTypeData)
        let chunkSizeData = withUnsafeBytes(of: chunkSize.bigEndian, Array.init)
        data.append(contentsOf: chunkSizeData)
        return data
    }
    
    static func decode(data: inout Data) -> ChunkHeader? {
        guard data.count >= 12 else {
            return nil // Not enough data
        }
        
        let chunkTypeData = data.subdata(in: 0..<4)
        let chunkTypeString = String(data: chunkTypeData, encoding: .utf8)
        
        let chunkType = FourByteString(chunkTypeString ?? "")
        
        let chunkSizeData = data.subdata(in: 4..<12)
        let chunkSize = chunkSizeData.withUnsafeBytes {
            $0.load(as: Int64.self)
        }.bigEndian
        
        data.removeFirst(12) // Adjust the data
        
        return ChunkHeader(chunkType: chunkType, chunkSize: chunkSize)
    }
}

struct ChannelDescription {
    var channelLabel: UInt32
    var channelFlags: UInt32
    var coordinates: (Float, Float, Float)
    
    func encode() -> Data {
        var result = Data()
        result.writeUInt32(channelLabel)
        result.writeUInt32(channelFlags)
        result.writeFloat(coordinates.0)
        result.writeFloat(coordinates.1)
        result.writeFloat(coordinates.2)
        return result
    }
    
}

struct UnknownContents {
    var data: Data
    
    func encode() -> Data {
        return data // No encoding needed as the data is already in the required format
    }
}

typealias Midi = Data


struct Information {
    var key: String
    var value: String
    
    
    func encode() -> Data {
        var data = Data()
        data.writeString(key)
        data.writeString(value)
        return data
    }
}

struct PacketTableHeader {
    var numberPackets: Int64
    var numberValidFrames: Int64
    var primingFrames: Int32
    var remainderFrames: Int32
}

class CAFStringsChunk {
    var numEntries: UInt32
    var strings: [Information]
    
    init(numEntries: UInt32, strings: [Information]) {
        self.numEntries = numEntries
        self.strings = strings
    }
    
    func encode() -> Data {
        var data = Data()
        data.writeUInt32(numEntries)
        for string in strings {
            data.append(string.encode())
        }
        return data
    }
    
}

class PacketTable {
    var header: PacketTableHeader
    var entries: [UInt64]
    
    init(header: PacketTableHeader, entries: [UInt64]) {
        self.header = header
        self.entries = entries
    }
    
    func encode() -> Data {
        var data = Data()
        data.writeInt64(header.numberPackets)
        data.writeInt64(header.numberValidFrames)
        data.writeInt32(header.primingFrames)
        data.writeInt32(header.remainderFrames)
        
        for item in entries {
            data.encodeInt(item)
        }
        return data
    }
    
}

class ChannelLayout {
    var channelLayoutTag: UInt32
    var channelBitmap: UInt32
    var numberChannelDescriptions: UInt32
    var channels: [ChannelDescription]
    
    init(channelLayoutTag: UInt32, channelBitmap: UInt32, numberChannelDescriptions: UInt32, channels: [ChannelDescription]) {
        self.channelLayoutTag = channelLayoutTag
        self.channelBitmap = channelBitmap
        self.numberChannelDescriptions = numberChannelDescriptions
        self.channels = channels
    }
    
    func encode() -> Data {
        var data = Data()
        data.writeUInt32(channelLayoutTag)
        data.writeUInt32(channelBitmap)
        data.writeUInt32(numberChannelDescriptions)
        for channel in channels {
            data.append(channel.encode())
        }
        return data
    }
}

class AudioData {
    var editCount: UInt32
    var data: [UInt8]
    
    init(editCount: UInt32, data: [UInt8]) {
        self.editCount = editCount
        self.data = data
    }
    
    func encode() -> Data {
        var result = Data()
        result.writeUInt32(editCount)
        result.append(contentsOf: data)
        return result
    }
}


class AudioFormat {
    var sampleRate: Float64
    var formatID: FourByteString
    var formatFlags: UInt32
    var bytesPerPacket: UInt32
    var framesPerPacket: UInt32
    var channelsPerPacket: UInt32
    var bitsPerChannel: UInt32
    
    init(sampleRate: Float64, formatID: FourByteString, formatFlags: UInt32, bytesPerPacket: UInt32, framesPerPacket: UInt32, channelsPerPacket: UInt32, bitsPerChannel: UInt32) {
        self.sampleRate = sampleRate
        self.formatID = formatID
        self.formatFlags = formatFlags
        self.bytesPerPacket = bytesPerPacket
        self.framesPerPacket = framesPerPacket
        self.channelsPerPacket = channelsPerPacket
        self.bitsPerChannel = bitsPerChannel
    }
    
    func encode() -> Data {
        var data = Data()
        data.writeFloat64(sampleRate)
        data.writeFourByteString(formatID.encode())
        data.writeUInt32(formatFlags)
        data.writeUInt32(bytesPerPacket)
        data.writeUInt32(framesPerPacket)
        data.writeUInt32(channelsPerPacket)
        data.writeUInt32(bitsPerChannel)
        
        return data
    }
}

enum ChunkType: String {
    case chunkTypeAudioDescription
    case chunkTypeChannelLayout
    case chunkTypeInformation
    case chunkTypeAudioData
    case chunkTypePacketTable
    case chunkTypeMidi
}

class Chunk {
    var header: ChunkHeader
    var contents: AnyObject?
    
    init(header: ChunkHeader, contents: AnyObject?) {
        self.header = header
        self.contents = contents
    }
    
    func encode() -> Data {
        var data = Data()
        data.append(header.encode())
        switch header.chunkType {
        case ChunkTypes.audioDescription:
            let audioFormat = contents as! AudioFormat
            data.append(audioFormat.encode())
        case ChunkTypes.channelLayout:
            let channelLayout = contents as! ChannelLayout
            data.append(channelLayout.encode())
        case ChunkTypes.information:
            let cafStringsChunk = contents as! CAFStringsChunk
            data.append(cafStringsChunk.encode())
        case ChunkTypes.audioData:
            let dataX = contents as! AudioData
            data.append(dataX.encode())
        case ChunkTypes.packetTable:
            let packetTable = contents as! PacketTable
            data.append(packetTable.encode())
        case ChunkTypes.midi:
            let midi = contents as! Midi
            data.append(midi)
        default:
            let unknownContents = contents as! UnknownContents
            data.append(unknownContents.encode())
        }
        return data
    }
}


struct FileHeader {
    var fileType: FourByteString
    var fileVersion: Int16
    var fileFlags: Int16
    
    mutating func decode(_ reader: Data) throws {
        var readerData = reader // Create a mutable copy of the input data
        let buffer = UnsafeRawBufferPointer(start: readerData.withUnsafeMutableBytes { $0.baseAddress }, count: readerData.count)
        
        let fileTypeValue = buffer.load(fromByteOffset: 0, as: FourByteString.self)
        
        if fileTypeValue != FourByteString("caff") {
            throw NSError(domain: "InvalidHeaderError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid caff header"])
        }
        fileType = fileTypeValue
        
        fileVersion = buffer.load(fromByteOffset: MemoryLayout<FourByteString>.size, as: Int16.self)
        fileFlags = buffer.load(fromByteOffset: MemoryLayout<FourByteString>.size + MemoryLayout<Int16>.size, as: Int16.self)
    }
    
    func encode() -> Data {
        var writer = Data()
        writer.writeFourByteString(fileType.encode())
        writer.writeInt16(fileVersion)
        writer.writeInt16(fileFlags)
        return writer
    }
}
