//
//  StorageManager.swift
//  EnSeek
//
//  Created by speedy on 2024/12/20.
//

import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let userDefaults = UserDefaults.standard
    private let songsKey = "recognizedSongs"
    
    func saveSong(_ song: Song) {
        var songs = getSongs()
        songs.insert(song, at: 0) // Add new song at the beginning
        
        if let encoded = try? JSONEncoder().encode(songs) {
            userDefaults.set(encoded, forKey: songsKey)
        }
    }
    
    func getSongs() -> [Song] {
        if let data = userDefaults.data(forKey: songsKey),
           let songs = try? JSONDecoder().decode([Song].self, from: data) {
            return songs
        }
        return []
    }
    
    func clearHistory() {
        userDefaults.removeObject(forKey: songsKey)
    }
}
