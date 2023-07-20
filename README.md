# OpusCAF

### Install

- File > Add Packages > Enter Url: https://github.com/nabil6391/opus_caf_converter_swift
- Select your desired branch

### Example Usage

```swift
import OpusCAF

let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

let inputFile = Bundle.main.path(forResource: "sample", ofType: "opus")!
let outputFile = docDir.appendingPathComponent("sample.caf")

OpusCAF.ConvertOpusToCaf(inputFile: inputFile, outputPath: outputFile.path)
```
