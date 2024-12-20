//
//  SignatureGenerator.swift
//  EnSeek
//
//  Created by speedy on 2024/12/20.
//

import ShazamKit
import AVFoundation

class SignatureGenerator {
    static func generateSignature(for audioURL: URL) throws -> (Data, SHMediaItem) {
        let generator = SHSignatureGenerator()
        let audioFile = try AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat
        let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                    frameCapacity: AVAudioFrameCount(audioFile.length))!
        
        try audioFile.read(into: buffer)
        try generator.append(buffer, at: nil)
        
        let signature = try generator.signature()
        let mediaItem = SHMediaItem(
            properties: [
                .title: audioURL.deletingPathExtension().lastPathComponent,
                .artist: "Local Reference"
            ]
        )
        
        return (signature.dataRepresentation, mediaItem)
    }
    
    static func saveSignature(for audioURL: URL, to destinationURL: URL) throws {
        let (signatureData, _) = try generateSignature(for: audioURL)
        try signatureData.write(to: destinationURL)
    }
}
