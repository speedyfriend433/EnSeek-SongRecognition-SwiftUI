//
//  SongModel.swift
//  EnSeek
//
//  Created by speedy on 2024/12/20.
//

import Foundation
import UIKit

struct Song: Identifiable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let albumArtworkURL: String?
    let recognizedDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, artist, albumArtworkURL, recognizedDate
    }
    
    var albumArtwork: UIImage? = nil
}
