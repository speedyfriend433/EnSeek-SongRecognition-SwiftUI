//
//  AudioRecognitionManager.swift
//  EnSeek
//
//  Created by speedy on 2024/12/20.
//

import ShazamKit
import AVFAudio
import UIKit

class AudioRecognitionManager: NSObject, ObservableObject, SHSessionDelegate {
    @Published var recognizedSong: Song?
    @Published var isProcessing = false
    @Published var error: String?
    
    private var session: SHSession?
    private var audioEngine: AVAudioEngine?
    
    override init() {
        super.init()
        setupShazamKit()
    }
    
    private func setupShazamKit() {
        do {

            try AVAudioSession.sharedInstance().setCategory(.record, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            session = SHSession()
            session?.delegate = self
            
            audioEngine = AVAudioEngine()
        } catch {
            self.error = "Setup failed: \(error.localizedDescription)"
        }
    }
    
    func startListening() {
        guard let audioEngine = audioEngine else {
            error = "Audio engine not initialized"
            return
        }
        
        error = nil
        recognizedSong = nil
        isProcessing = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0,
                           bufferSize: 2048,
                           format: recordingFormat) { [weak self] buffer, time in
            self?.session?.matchStreamingBuffer(buffer, at: time)
        }
        
        do {
            try audioEngine.start()
            print("Started listening...")
        } catch {
            handleError(error)
        }
    }
    
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        isProcessing = false
        print("Stopped listening")
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.isProcessing = false
            
            switch error {
            case let shazamError as SHError:
                self.error = "Recognition error: \(shazamError.localizedDescription)"
            case let avError as AVError:
                self.error = "Audio error: \(avError.localizedDescription)"
            default:
                self.error = "An error occurred: \(error.localizedDescription)"
            }
            print("Error occurred: \(error)")
        }
    }
    
    // MARK: - SHSessionDelegate Methods
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        if let mediaItem = match.mediaItems.first {
            let song = Song(
                id: UUID(),
                title: mediaItem.title ?? "Unknown",
                artist: mediaItem.artist ?? "Unknown",
                albumArtworkURL: mediaItem.artworkURL?.absoluteString,
                recognizedDate: Date()
            )
            
            if let artworkURL = mediaItem.artworkURL {
                downloadArtwork(from: artworkURL) { image in
                    DispatchQueue.main.async {
                        var updatedSong = song
                        updatedSong.albumArtwork = image
                        self.recognizedSong = updatedSong
                        self.isProcessing = false
                        self.error = nil
                        StorageManager.shared.saveSong(updatedSong)
                        print("Song recognized: \(song.title) by \(song.artist)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.recognizedSong = song
                    self.isProcessing = false
                    self.error = nil
                    StorageManager.shared.saveSong(song)
                    print("Song recognized (no artwork): \(song.title) by \(song.artist)")
                }
            }
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.handleError(error)
            } else {
                self.error = "No matching song found. Please try again."
                self.isProcessing = false
            }
        }
    }
    
    private func downloadArtwork(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Artwork download error: \(error)")
                completion(nil)
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                print("Could not create image from data")
                completion(nil)
            }
        }.resume()
    }
}
