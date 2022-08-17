//
//  Project.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-22.
//

import UIKit

struct Project: Identifiable {
    
    var id = UUID()
    
    var name: String = "Unnamed"
    
    /// The width of all the layers
    let width: Int
    
    /// The height of all the layers
    let height: Int
    
    /// All the bitmap layers of a project
    var layers: [Bitmap]

    /// When the project was created
    var creationDate: Date
    
    /// When the project was last updated
    var lastUpdateDate: Date
}

extension Project {
    
    /// Initialize a project from a corresponding project core data object
    init?(object: ProjectObject) {
        guard let id = object.value(forKey: "id") as? UUID,
              let width = object.value(forKey: "width") as? Int,
              let height = object.value(forKey: "height") as? Int,
              let creationDate = object.value(forKey: "creationDate") as? Date,
              let lastUpdateDate = object.value(forKey: "lastUpdateDate") as? Date
        else { return nil }
        
        self.id = id
        self.width = width
        self.height = height
        self.creationDate = creationDate
        self.lastUpdateDate = lastUpdateDate
        
        let layers = object.bitmaps?.allObjects as? [BitmapObject] ?? []
        let converted = layers.compactMap(Bitmap.init)
        
        self.layers = converted
    }
}


//extension Project {
//    
//    init(id: UUID, width: Int, height: Int, layers: [Bitmap], creationDate: Date, lastUpdateDate: Date) {
//        self.id = id
//        self.width = width
//        self.height = height
//        self.layers = layers
//        self.creationDate = creationDate
//        self.lastUpdateDate = lastUpdateDate
//    }
//}

extension Project {
    
    var combinedBitmap: Bitmap? {
        guard layers.count > 0 else { return nil }
        
        var layers = layers.sorted { $0.zIndex < $1.zIndex }
        var first = layers.removeFirst()
        
        for layer in layers {
            for (index, pixel) in layer.pixels.enumerated() {
                if pixel != .clear {
                    first.pixels[index] = pixel
                }
            }
        }
        
        return first
    }
}
