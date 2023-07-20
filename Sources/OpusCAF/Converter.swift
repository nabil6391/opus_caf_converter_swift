//
//  File.swift
//  
//
//  Created by hamza on 20/7/23.
//

import Foundation

public enum ConversionError: Error {
    case ErrHeaderReading(String)
}

extension OggReader {
    
    func readHeaders() -> (OggHeader?, Error?) {
        let (segments, pageHeader, err) = parseNextPage()
        
        if err != nil {
            return (nil, err)
        }
        
        guard let pageHeader else {
            return (nil, err)
        }
        
        if String(data: Data(pageHeader.sig), encoding: .utf8) != pageHeaderSignature {
            return (nil, OggReaderError.badIDPageSignature)
        }
        
        if pageHeader.headerType != pageHeaderTypeBeginningOfStream {
            return (nil, OggReaderError.badIDPageType)
        }
        
        var header = OggHeader(
            channelMap: 0,
            channels: 0,
            outputGain: 0,
            preSkip: 0,
            sampleRate: 0,
            version: 0
        )
        
        
        if segments[0].count != idPagePayloadLength {
            return (nil, OggReaderError.badIDPageLength)
        }
        
        if String(data: Data(segments[0][0..<8]), encoding: .utf8) != idPageSignature {
            return (nil, OggReaderError.badIDPagePayloadSignature)
        }
        
        header.version = segments[0][8]
        header.channels = segments[0][9]
        header.preSkip = UInt16(littleEndian: segments[0][10..<12].withUnsafeBytes { $0.load(as: UInt16.self) })
        header.sampleRate = UInt32(littleEndian: segments[0][12..<16].withUnsafeBytes { $0.load(as: UInt32.self) })
        header.outputGain = UInt16(littleEndian: segments[0][16..<18].withUnsafeBytes { $0.load(as: UInt16.self) })
        
        header.channelMap = segments[0][18]
        
        return (header, nil)
    }
    
    func parseNextPage() -> ([[UInt8]], OggPageHeader?, Error?) {
        var h = [UInt8](repeating: 0, count: pageHeaderLen)
        
        guard let stream = self.stream else {
            return ([], nil, OggReaderError.nilStream)
        }
        
        do {
            let n = try stream.readFull(into: &h, maxLength: h.count)
            if n < h.count {
                return ([], nil, OggReaderError.shortPageHeader)
            }
        } catch {
            return ([], nil, OggReaderError.shortPageHeader)
        }
        
        var pageHeader = OggPageHeader(
            granulePosition: 0,
            sig: [],
            version: 0,
            headerType: 0,
            serial: 0,
            index: 0,
            segmentsCount: 0
        )
        
        pageHeader.sig = Array(h[0..<4])
        pageHeader.version = h[4]
        pageHeader.headerType = h[5]
        pageHeader.granulePosition = UInt64(littleEndian: Data(h[6..<14]).withUnsafeBytes { $0.load(as: UInt64.self) })
        pageHeader.serial = UInt32(littleEndian: Data(h[14..<18]).withUnsafeBytes { $0.load(as: UInt32.self) })
        pageHeader.index = UInt32(littleEndian: Data(h[18..<22]).withUnsafeBytes { $0.load(as: UInt32.self) })
        
        pageHeader.segmentsCount = h[26]
        
        var sizeBuffer = [UInt8](repeating: 0, count: Int(pageHeader.segmentsCount))
        stream.read(&sizeBuffer, maxLength: sizeBuffer.count)
        
        var newArr = [Int]()
        var i = 0
        while i < sizeBuffer.count {
            if sizeBuffer[i] == 255 {
                var sum = Int(sizeBuffer[i])
                i += 1
                while i < sizeBuffer.count && sizeBuffer[i] == 255 {
                    sum += Int(sizeBuffer[i])
                    i += 1
                }
                if i < sizeBuffer.count {
                    sum += Int(sizeBuffer[i])
                }
                newArr.append(sum)
            } else {
                newArr.append(Int(sizeBuffer[i]))
            }
            i += 1
        }
        
        var segments = [[UInt8]]()
        
        for s in newArr {
            var segment = [UInt8](repeating: 0, count: s)
            stream.read(&segment, maxLength: segment.count)
            segments.append(segment)
        }
        
        return (segments, pageHeader, nil)
    }
}

func readOpusData(ogg: OggReader) -> ([UInt8], [UInt64], Int) {
    var audioData = [UInt8]()
    var frame_size = 0
    var trailing_data = [UInt64]()
    
    while true {
        let (segments, header, err) = ogg.parseNextPage()
        
        if let err = err as? OggReaderError {
            if err == .nilStream || err == .shortPageHeader {
                break
            }
        } else if let segmentPrefix = segments.first?.prefix(8), let segmentString = String(bytes: segmentPrefix, encoding: .utf8), segmentString == "OpusTags" {
            continue
        }
        
        if err != nil {
            fatalError("Unexpected error: \(err!.localizedDescription).")
        }
        
        for segment in segments {
            trailing_data.append(UInt64(segment.count))
            audioData += segment
        }
        
        if header?.index == 2 {
            let tmpPacket = segments[0]
            if !tmpPacket.isEmpty {
                let tmptoc = Int(tmpPacket[0] & 255)
                let tocConfig = tmptoc >> 3
                
                switch tocConfig {
                case ..<12:
                    frame_size = 960 * (tocConfig & 3 + 1)
                case ..<16:
                    frame_size = 480 << (tocConfig & 1)
                default:
                    frame_size = 120 << (tocConfig & 3)
                }
            }
        }
    }
    
    return (audioData, trailing_data, frame_size)
}


func calculatePacketTableLength(trailing_data: [UInt64]) -> Int {
    var packetTableLength = 24
    
    for i in 0..<trailing_data.count {
        let value = UInt32(trailing_data[i])
        var numBytes = 0
        if (value & 0x7f) == value {
            numBytes = 1
        } else if (value & 0x3fff) == value {
            numBytes = 2
        } else if (value & 0x1fffff) == value {
            numBytes = 3
        } else if (value & 0x0fffffff) == value {
            numBytes = 4
        } else {
            numBytes = 5
        }
        packetTableLength += numBytes
    }
    return packetTableLength
}

func buildCafFile(header: OggHeader, audioData: [UInt8], trailing_data: [UInt64], frame_size: Int) throws -> CafFile {
    let len_audio = audioData.count
    let packets = trailing_data.count
    let frames = frame_size * packets
    
    let packetTableLength = calculatePacketTableLength(trailing_data: trailing_data)
    
    var cf = CafFile(fileHeader: FileHeader(fileType: FourByteString("caff"), fileVersion: 1, fileFlags: 0), chunks: [])
    // Rest of your code
    
    let c = Chunk(header: ChunkHeader(chunkType: ChunkTypes.audioDescription, chunkSize: 32), contents: AudioFormat(sampleRate: 48000, formatID: FourByteString("opus"), formatFlags: 0x00000000, bytesPerPacket: 0, framesPerPacket: UInt32(frame_size), channelsPerPacket: UInt32(header.channels), bitsPerChannel: 0 ))
    
    cf.chunks.append(c)
    
    let channelLayoutTag: UInt32 = (header.channels == 2) ? 6619138 : 6553601 // Stereo : Mono
    
    let c1 = Chunk(header: ChunkHeader(chunkType:  ChunkTypes.channelLayout, chunkSize: 12), contents: ChannelLayout(channelLayoutTag: channelLayoutTag, channelBitmap: 0x0, numberChannelDescriptions: 0, channels: []))
    
    cf.chunks.append(c1)
    
    let c2 = Chunk(
        header: ChunkHeader(chunkType: ChunkTypes.information, chunkSize: 26),
        contents: CAFStringsChunk(
            numEntries: 1,
            strings: [
                Information(key: "encoder", value: "Lavf59.27.100")
            ]
        )
    )
    
    cf.chunks.append(c2)
    
    let c3 = Chunk(header: ChunkHeader(chunkType:  ChunkTypes.audioData, chunkSize: Int64(len_audio + 4)), contents: AudioData(editCount: 0, data: audioData))
    
    cf.chunks.append(c3)
    
    let c4 = Chunk(header: ChunkHeader(chunkType:  ChunkTypes.packetTable, chunkSize: Int64(packetTableLength)), contents: PacketTable(header: PacketTableHeader(numberPackets: Int64(packets), numberValidFrames: Int64(frames), primingFrames: 0, remainderFrames: 0), entries: trailing_data))
    
    cf.chunks.append(c4)
    
    return cf
}

func convertOpusToCaf(inputFile: String, outputPath: String) -> ConversionError? {
    let ogg = OggReader(filePath: inputFile)
    
    let (headerOrNil, err) = ogg.readHeaders()
    
    if let err = err {
        return .ErrHeaderReading(err.localizedDescription)
    }
    
    guard let unwrappedHeader = headerOrNil else {
        return .ErrHeaderReading("header is nil?")
    }
    
    
    let (audioData, trailing_data, frame_size) = readOpusData(ogg: ogg)
    do {
        let cf = try buildCafFile(header: unwrappedHeader, audioData: audioData, trailing_data: trailing_data, frame_size: frame_size)
        let  encodedData =  cf.encode()
        
        let fileManager = FileManager.default
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Create the file if it doesn't exist
        if !fileManager.fileExists(atPath: outputPath) {
            fileManager.createFile(atPath: outputPath, contents: nil, attributes: nil)
        }
        
        do {
            try encodedData.write(to: outputURL)
            print("Encoded data has been successfully written to the file.")
        } catch {
            print("Error while writing encoded data to the file: \(error)")
        }
        
        print("Success")
    } catch {
        print("An error occurred: \(error)")
    }
    
    return nil
}
