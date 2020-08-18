//
//  Business.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/15/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import Foundation
//import RxSwift


protocol Chunkable {
    var index: Int { get set }
}

protocol TextChunkable: Chunkable {
    var text: String { get set }
}

protocol PhotoChunkable: Chunkable {
    var photo: Data { get set }
}
// structs

class Memory {
    let date: Date
    private(set) var index: Int
    private(set) var texts: Array<TextChunk>
    private(set) var photos: Array<PhotoChunk>

    private var total: Int {
        texts.count + photos.count
    }
    
    init(date: Date, index: Int, texts: Array<TextChunk>, photos: Array<PhotoChunk>) {
        self.date = date
        self.index = index
        self.texts = texts
        self.photos = photos
    }
    
    func insertTextChunk(_ text: String) {
        texts.append(TextChunk(text: text, index: index))
        index += 1
    }
    
    func insertPhoto(_ photo: Data) {
        photos.append(PhotoChunk(photo: photo, index: index))
        index += 1
    }
    
    var sortedChunks: Array<Chunkable> {
        (texts + photos).sorted { (t1, t2) -> Bool in
            t1.index < t2.index
        }
    }
}

class TextChunk: TextChunkable {
    var text: String
    var index: Int
    
    init(text: String, index: Int) {
        self.text = text
        self.index = index
    }
}

class PhotoChunk: PhotoChunkable {
    var photo: Data
    var index: Int
    
    init(photo: Data, index: Int) {
        self.photo = photo
        self.index = index
    }
}

