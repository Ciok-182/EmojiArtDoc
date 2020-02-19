//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Jorge Encinas on 16/01/20.
//  Copyright © 2020 Jorge Encinas. All rights reserved.
//

import Foundation


struct EmojiArt: Codable {
    var url: URL?
    var imageData: Data?
    var emojis = [EmojiInfo]()
    
    struct EmojiInfo : Codable {
        let x: Int
        let y: Int
        let text: String
        let size: Int
    }
    
    var json: Data?{
        return try? JSONEncoder().encode(self)
    }
    
    init(url: URL, emojis: [EmojiInfo]) {
        //print("Creando EmojiArt con: \(url)")
        self.url = url
        self.emojis = emojis
    }
    
    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(EmojiArt.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
    
    init(imageData: Data, emojis: [EmojiInfo]) {
        //print("Creando EmojiArt con: \(url)")
        self.imageData = imageData
        self.emojis = emojis
    }
    
}
