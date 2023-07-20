//
//  ContentView.swift
//  OpusCAFiOSExample
//
//  Created by hamza on 20/7/23.
//

import SwiftUI
import OpusCAF
import AVFoundation

var player: AVAudioPlayer?

struct ContentView: View {
    @State var lblInfo = ""
    @State var lblOutUrl: URL?
    
    var body: some View {
        VStack {
            Text(lblInfo)
            Text(lblOutUrl?.path ?? "Not converted")
            
            Button("Convert OPUS to CAF") {
                convertOpusToCaf()
            }
            
            Button("play caf") {
                play()
            }
        }
        .padding()
    }
    
    func convertOpusToCaf() {
        let file = Bundle.main.path(forResource: "sample", ofType: "opus")!
        let outFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sample.caf")
        
        lblOutUrl = nil
        
        if let err = OpusCAF.ConvertOpusToCaf(inputFile: file, outputPath: outFile.path) {
            lblInfo = "Error converting: " + err.localizedDescription
        } else {
            lblInfo = "Successfully Converted"
            lblOutUrl = outFile
        }
    }
    
    func play() {
        guard let url = lblOutUrl else {
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            lblInfo = "Error playing: " + error.localizedDescription
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
