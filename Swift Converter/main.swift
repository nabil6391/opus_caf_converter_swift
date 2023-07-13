//
//  main.swift
//  Swift Converter
//
//  Created by Fairoze Hassan on 12/07/2023.
//

import Foundation

let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let url = URL(fileURLWithPath: CommandLine.arguments[0], relativeTo: currentDirectoryURL)
print("script at: " + url.path)

let path = "/Users/fairoze/AndroidStudioProjects/opis/caf/caf/samples"
let fileUrl = path + "/sample4.opus"

let fileManager = FileManager.default

if fileManager.fileExists(atPath: fileUrl) {
    // File exists
    print("File exists.")
} else {
    // File doesn't exist
    print("File not found.")
}

let outputFile = path + "/1sample4.caf"

convertOpusToCaf(inputFile: fileUrl, outputPath: outputFile)


//print("Hello, World!")



