//
//  File.swift
//  
//
//  Created by hamza on 20/7/23.
//

import Foundation

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
