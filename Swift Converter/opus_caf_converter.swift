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

// Opus Decoding
let pageHeaderTypeBeginningOfStream: UInt8 = 0x02
let pageHeaderSignature: String = "OggS"
let idPageSignature: String = "OpusHead"

let pageHeaderLen: Int = 27
let idPagePayloadLength: Int = 19

enum OggReaderError: Error {
    case nilStream
    case badIDPageSignature
    case badIDPageType
    case badIDPageLength
    case badIDPagePayloadSignature
    case shortPageHeader
}

// OggReader is used to read Ogg files and return page payloads
class OggReader {
    var stream: InputStream?
       
       init(filePath: String) {
           self.stream = InputStream(fileAtPath: filePath)
           self.stream?.open()
       }
       
       deinit {
           self.stream?.close()
       }
       
}

// OggHeader is the metadata from the first two pages
// in the file (ID and Comment)
struct OggHeader {
    var channelMap: UInt8
    var channels: UInt8
    var outputGain: UInt16
    var preSkip: UInt16
    var sampleRate: UInt32
    var version: UInt8
}

// OggPageHeader is the metadata for a Page
// Pages are the fundamental unit of multiplexing in an Ogg stream
struct OggPageHeader {
    var granulePosition: UInt64
    var sig: [UInt8]
    var version: UInt8
    var headerType: UInt8
    var serial: UInt32
    var index: UInt32
    var segmentsCount: UInt8
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

extension OggReader {

    func readHeaders() -> (OggHeader?, Error?)? {
        let (segments, pageHeader, err) = parseNextPage()
        if err != nil {
            return (nil, err)
        }
        
        guard let pageHeader else {
            return (nil, err)
        }

        var header = OggHeader(channelMap: 0, channels: 0, outputGain: 0, preSkip: 0, sampleRate: 0, version: 0)
        if String(data: Data(pageHeader.sig), encoding: .utf8) != pageHeaderSignature {
            return (nil, OggReaderError.badIDPageSignature)
        }

        if pageHeader.headerType != pageHeaderTypeBeginningOfStream {
            return (nil, OggReaderError.badIDPageType)
        }

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
        
        guard let n = try? stream.readFull(into: &h, maxLength: h.count) else {
                return ([], nil, OggReaderError.shortPageHeader)
            }
        
        if n < h.count {
            return ([], nil, OggReaderError.shortPageHeader)
        }

        var pageHeader = OggPageHeader(granulePosition: 0, sig: [], version: 0, headerType: 0, serial: 0, index: 0, segmentsCount: 0)
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

    var cf = try CafFile(fileHeader: FileHeader(fileType: FourByteString("caff"), fileVersion: 1, fileFlags: 0), chunks: [])
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

func convertOpusToCaf(inputFile: String, outputPath: String) {
    let ogg = OggReader(filePath: inputFile)
    guard let (header, err) = ogg.readHeaders(), let unwrappedHeader = header else { return }
           
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

}

