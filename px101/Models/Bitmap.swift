//
//  Bitmap.swift
//  px101
//
//  Created by Daniel Hooper on 2021-11-26.
//

import UIKit
//
//protocol ColoringDelegate: AnyObject {
//    var drawingColor: UIColor { get }
//}
//
//extension ColoringDelegate {
//    func didSelectView(_ view: UIView) {
//        view.backgroundColor = drawingColor
//    }
//}

struct Bitmap: Codable, Identifiable {
    
    var id = UUID()
    
    var name = "Unnamed"
    var creationDate = Date()
    var lastUpdatedDate = Date()
    
    let width: Int
    
    var zIndex: Int
    
    var pixels: [Color]
    
    var palette: [Color] = []
    
    var isHidden = false
    
    var height: Int {
        pixels.count / width
    }
    
    
    var data: Data {
        Data(bytes: pixels, count: height * width * MemoryLayout<Color>.stride)
    }
    
    init?(object: BitmapObject) {
        guard let id = object.value(forKey: "id") as? UUID,
              let width = object.value(forKey: "width") as? Int,
              let zIndex = object.value(forKey: "zIndex") as? Int,

              let data = object.value(forKey: "pixels") as? Data,
              let name = object.value(forKey: "name") as? String,
              let creationDate = object.value(forKey: "creationDate") as? Date,
              let lastUpdatedDate = object.value(forKey: "lastUpdateDate") as? Date,
              let isHidden = object.value(forKey: "isHidden") as? Bool
        else { return nil }
        
        self.id = id
        self.width = width
        self.zIndex = zIndex
        self.name = name
        self.isHidden = isHidden
        self.creationDate = creationDate
        self.lastUpdatedDate = lastUpdatedDate
        self.pixels = try! JSONDecoder().decode([Color].self, from: data)
        self.palette = Array(Set(pixels))
    }

    init(id: UUID = UUID(), name: String = "Unnamed", width: Int, zIndex: Int = 0, creationDate: Date = Date(), lastUpdatedDate: Date = Date(), pixels: [Color]) {
        self.id = id
        self.width = width
        self.name = name
        self.pixels = pixels
        self.zIndex = 0
        self.palette = Array(Set(pixels))
    }
    
    init(width: Int, binary: [Int], stroke: Color = .white, fill: Color = .clear) {
        self.width = width
        self.zIndex = 0
        self.pixels = binary.map { $0 == 1 ? stroke : fill }
        self.palette = Array(Set(pixels))
    }

    subscript(x: Int, y: Int) -> Color {
        get { pixels[y * width + x] }
        set { pixels[y * width + x] = newValue }
    }
}

extension Bitmap {
    
    func insert(newBitmap: Bitmap, at x: Int, y: Int) -> Bitmap {
        var copy = self

        let top = y < 0 ? abs(y) : 0
        let bottom = newBitmap.height + y > height ? newBitmap.height + y - height : 0
        let left = x < 0 ? abs(x) : 0
        let right = newBitmap.width + x > width ? newBitmap.width + x - width : 0
        let cropped = newBitmap.cropped(top: top, bottom: bottom, left: left, right: right)

        let originalX = x < 0 ? 0 : x
        var x = originalX
        var y = y < 0 ? 0 : y
        
        let xBreak = x + cropped.width - 1
        for pixel in cropped.pixels {
            copy[x, y] = pixel

            if x == xBreak {
                x = originalX
                y += 1
            } else {
               x += 1
            }
        }

        return copy
    }
    
    func cropped(top: Int = 0, bottom: Int = 0, left: Int = 0, right: Int = 0) -> Bitmap {
        var copy = self
        if top == 0 && bottom == 0 && left == 0 && right == 0 { return copy }
        
        var t = 0
        var b = 0
        var l = 0
        var r = 0
        
        var height = height
        while t < top {
            let row = 0..<width
            row.forEach { _ in copy.pixels.removeFirst() }
            t += 1
            height -= 1
        }
        
        while b < bottom {
            let row = 0..<width
            row.forEach { _ in copy.pixels.removeLast() }
            b += 1
            height -= 1
        }

        var width = width
        
        while l < left {
            let stride = stride(from: 0, to: width * height, by: width)
            for (i, e) in stride.enumerated() {
                copy.pixels.remove(at: e - i)
            }
            width -= 1
            l += 1
        }
        
        while r < right {
            let stride = stride(from: width - 1, to: width * height, by: width)
            for (i, e) in stride.enumerated() {
                copy.pixels.remove(at: e - i)
            }
            width -= 1
            r += 1
        }

        return Bitmap(id: copy.id, width: width, pixels: copy.pixels)
    }
    
    func scaled(_ scale: Int) -> Bitmap {
        let width = width * scale

        var pixels = pixels.flatMap {
            Array(repeating: $0, count: scale)
        }
  
        
        var rows: [[Color]] = []
        
        var i = 0
        
        while i < height {
            rows.append( Array(pixels[(i * width)..<(i * width + width)]) )
            i += 1
        }
        
        pixels = rows.map {
            Array(repeating: $0, count: scale)
        }.flatMap { $0 }.flatMap { $0 }

        

        return Bitmap(id: id, width: width, pixels: pixels)
    }
}

extension Bitmap {
    
    static func transparencyIndicator(of width: Int, height: Int) -> Bitmap {
//        let isEven = width % 2 == 0
        let width = width * 2
        let height = height * 2
        
        let white = Color.white
        let gray = Color(r: 222, g: 222, b: 222)
        
        let pixelCount = width * height
        
        let pixels: [Color] = (0...(pixelCount)).map { i in
            if (i / width) % 2 == 0 {
                return i % 2 == 0 ? white : gray
            }
            return i % 2 == 0 ? gray : white
        }
        
        return Bitmap(width: width, pixels: pixels)
    }
}

extension Bitmap {

    func updatedColors(with newColor: Color, at indexes: [Int]) -> [Color] {
        var new = pixels
        let validIndexes = indexes.filter { $0 >= 0 && $0 < pixels.count }
        for index in validIndexes {
            new[index] = newColor
        }
        
        return new
    }
    
    func withChanges(newColor: Color, at indexes: [Int]) -> Bitmap {
        Bitmap(id: id,
               name: name,
               width: width,
               creationDate: creationDate,
               lastUpdatedDate: lastUpdatedDate,
               pixels: updatedColors(with: newColor, at: indexes))
    }
}

extension Bitmap {
    
    mutating func changeColor(_ color: Color, at indexes: [Int]) {
        let validIndexes = indexes.filter { $0 >= 0 && $0 < pixels.count }
        validIndexes.forEach { i in
            pixels[i] = color
        }
    }
}

extension Bitmap {
    /// Improves the readibility of assembling together multiple bitmaps into textual repressentations
    static var initial: Bitmap {
        Bitmap(width: 0, pixels: [])
    }
}

extension Bitmap {
    
    var svg: String {
        let prefix = "<svg id=\"px101\" xmlns=\"http://www.w3.org/2000/svg\" preserveAspectRatio=\"xMinYMin meet\" viewBox=\"0 0 \(width) \(height)\">"
        
        let uniqueColors = Set(pixels)
        var bgColor: Color = .white
        
        var colorOccuranceDictionary: [Color: Int] = [:]
        uniqueColors.forEach {
            colorOccuranceDictionary[$0] = 0
        }
        for pixel in pixels {
            if let value = colorOccuranceDictionary[pixel] {
                colorOccuranceDictionary[pixel] = value + 1
            }
        }

        if let (color, _) = colorOccuranceDictionary.max(by: {$0.1 < $1.1}) {
            bgColor = color
        }
        
        var colorDictionary: [Color: Int] = [:]
        uniqueColors.enumerated().forEach { index, color in
            colorDictionary[color] = index
        }
        let pixelRects = pixels
            .enumerated()
            .filter { $0.element != bgColor }
            .map { index, color in
                "<rect class=\"c\(colorDictionary[color]!)\" x=\"\(index % width)\" y=\"\(index / height)\"/>"
            }
            .joined()
        
        let bgRect = "<polygon points =\"0,0 0,\(width) \(width),\(height) \(width),0\" fill=\"#\(bgColor.hex)\"/>"
        let stylePrefix = "<style>rect{width:1px;height:1px;} #px101{shape-rendering: crispedges;} "

        let colors = colorDictionary.map { color, index in
            ".c\(index){fill:#\(color.hex)}"
        }.joined()
        return prefix + bgRect + pixelRects + stylePrefix + colors + "</style>" + "</svg>"
    }
}
