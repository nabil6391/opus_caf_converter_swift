import Foundation

public struct OpusCAF {
    // public init() {}
    
    public static func ConvertOpusToCaf(inputFile: String, outputPath: String) -> ConversionError? {
        return convertOpusToCaf(inputFile: inputFile, outputPath: outputPath)
    }
}

