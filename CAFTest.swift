////
////  CAFTest.swift
////  Swift Converter
////
////  Created by Fairoze Hassan on 13/07/2023.
////
//
//import XCTest
//
//final class CAFTest: XCTestCase {
//
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testExample() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        // Any test you write for XCTest can be annotated as throws and async.
//        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
//        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
//    }
//
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//
//    func testBasicCafEncodingDecoding() {
//        let path = "out_ffmpeg.caf"
//        guard let contents = FileManager.default.contents(atPath: path) else {
//            XCTFail("Failed to read file")
//            return
//        }
//        guard !contents.isEmpty else {
//            XCTFail("Testing with empty file")
//            return
//        }
//
//        guard let f = FileData(contents) else {
//            XCTFail("Failed to decode contents")
//            return
//        }
//
//        guard let output = f.encode() else {
//            XCTFail("Failed to encode contents")
//            return
//        }
//
//        XCTAssertEqual(output.count, contents.count,
//                       "contents of input differ when decoding and reencoding, before: \(contents.count) after: \(output.count)")
//
//        for i in 0..<contents.count {
//            if output[i] != contents[i] {
//                XCTFail("contents of input differ when decoding and reencoding starting at offset \(i)")
//                break
//            }
//        }
//    }
//
//    func testConversion() {
//        let inputFile = "samples/sample4.opus"
//        let outputFile = "samples/sample4.caf"
//        XCTAssertNoThrow(try convertOpusToCaf(inputFile: inputFile, outputFile: outputFile))
//    }
//
//    func testCompareCafFFMpeg() {
//        // specify the input and output files
//        let inputFile = "samples/sample4.opus"
//        let outputFileFFmpeg = "out_ffmpeg.caf"
//        let outputFileCode = "out_code.caf"
//
//        // run the ffmpeg command to convert the audio file
//        let process = Process()
//        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ffmpeg")
//        process.arguments = ["-i", inputFile, "-c:a", "copy", outputFileFFmpeg]
//
//        do {
//            try process.run()
//            process.waitUntilExit()
//        } catch {
//            XCTFail("Failed to run ffmpeg: \(error)")
//            return
//        }
//
//        XCTAssertNoThrow(try convertOpusToCaf(inputFile: inputFile, outputFile: outputFileCode))
//
//        guard let contents1 = FileManager.default.contents(atPath: outputFileFFmpeg),
//              let contents2 = FileManager.default.contents(atPath: outputFileCode) else {
//            XCTFail("Failed to read output files")
//            return
//        }
//
//        XCTAssertEqual(contents1.count, contents2.count, "contents of input differ when decoding and reencoding, before: \(contents1.count) after: \(contents2.count)")
//
//        for i in 0..<contents1.count {
//            if contents1[i] != contents2[i] {
//                XCTFail("contents of input differ when decoding and reencoding starting at offset \(i) \(contents1[i]) \(contents2[i])")
//                break
//            }
//        }
//    }
//
//    func testCompareCaf() {
//        guard let contents1 = FileManager.default.contents(atPath: "samples/output.caf"),
//              let contents2 = FileManager.default.contents(atPath: "file.caf") else {
//            XCTFail("Failed to read caf files")
//            return
//        }
//
//        XCTAssertEqual(contents1.count, contents2.count, "contents of input differ when decoding and reencoding, before: \(contents1.count) after: \(contents2.count)")
//
//        for i in 0..<contents1.count {
//            if contents1[i] != contents2[i] {
//                XCTFail("contents of input differ when decoding and reencoding starting at offset \(i) \(contents1[i]) \(contents2[i])")
//                break
//            }
//        }
//    }
//
//
//}
