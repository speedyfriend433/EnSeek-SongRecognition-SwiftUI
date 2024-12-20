//
//  ContentView.swift
//  EnSeek
//
//  Created by speedy on 2024/12/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioRecognitionManager()
    @State private var isListening = false
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Song Recognition")
                    .font(.largeTitle)
                
                if audioManager.isProcessing {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Listening for music...")
                            .foregroundColor(.gray)
                    }
                }
                
                if let song = audioManager.recognizedSong {
                    SongView(song: song)
                }
                
                if let error = audioManager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Button(action: {
                    if isListening {
                        audioManager.stopListening()
                    } else {
                        audioManager.startListening()
                    }
                    isListening.toggle()
                }) {
                    HStack {
                        Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                        Text(isListening ? "Stop Listening" : "Start Listening")
                    }
                    .font(.title2)
                    .padding()
                    .background(isListening ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button("View History") {
                    showingHistory = true
                }
                .padding()
            }
            .padding()
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
        }
    }
}

struct SongView: View {
    let song: Song
    
    var body: some View {
        VStack(spacing: 10) {
            if let artwork = song.albumArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
            }
            
            Text(song.title)
                .font(.title2)
                .bold()
            
            Text(song.artist)
                .font(.title3)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct HistoryView: View {
    @State private var songs: [Song] = []
    
    var body: some View {
        NavigationView {
            List(songs) { song in
                SongView(song: song)
            }
            .navigationTitle("Song History")
            .navigationBarItems(trailing: Button("Clear") {
                StorageManager.shared.clearHistory()
                songs = []
            })
        }
        .onAppear {
            songs = StorageManager.shared.getSongs()
        }
    }
}

#Preview {
    ContentView()
}
