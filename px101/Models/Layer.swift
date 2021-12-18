//
//  Bitmap.swift
//  px101
//
//  Created by Daniel Hooper on 2021-11-26.
//

import UIKit

protocol ColoringDelegate: AnyObject {
    var drawingColor: UIColor { get }
}

extension ColoringDelegate {
    func didSelectView(_ view: UIView) {
        view.backgroundColor = drawingColor
    }
}

struct Bitmap: Codable, Identifiable {
    
    var id = UUID()
    
    let width: Int
    var pixels: [Color]
    
    var height: Int {
        pixels.count / width
    }
    
    var data: Data {
        Data(bytes: pixels, count: height * width * MemoryLayout<Color>.stride)
    }
    
    var json: Data? {
        try? JSONEncoder().encode(pixels)
    }
    
    init?(obj: BitmapObject) {
        guard let id = obj.value(forKey: "id") as? UUID,
              let width = obj.value(forKey: "width") as? Int,
              let data = obj.value(forKey: "pixels") as? Data
        else { return nil }
        
        self.id = id
        self.width = width
        self.pixels = try! JSONDecoder().decode([Color].self, from: data)
    }
    
    init(id: UUID, width: Int, data: Data) {
        self.id = id
        self.width = width
        self.pixels = try! JSONDecoder().decode([Color].self, from: data)
    }
    
    init(id: UUID, width: Int, pixels: [Color]) {
        self.id = id
        self.width = width
        self.pixels = pixels
    }
    
    init(width: Int, pixels: [Color]) {
        self.width = width
        self.pixels = pixels
    }
    
    init(width: Int, height: Int, color: Color) {
        self.width = width
        pixels = Array(repeating: color, count: width * height)
    }
    
    init(width: Int, pattern: [Int], stroke: Color = .white, fill: Color = .clear) {
        self.width = width
        self.pixels = pattern.map { $0 == 1 ? stroke : fill }
    }

    subscript(x: Int, y: Int) -> Color {
        get { pixels[y * width + x] }
        set { pixels[y * width + x] = newValue }
    }
    
    func insert(newBitmap: Bitmap, at x: Int, y: Int) -> Bitmap {
//        let bitmapWidth = bitmap.width + x > width ? bitmap.width - x : bitmap.width
        var copy = self

        let top = y < 0 ? abs(y) : 0
        let bottom = newBitmap.height + y > height ? newBitmap.height + y - height : 0
        let left = x < 0 ? abs(x) : 0
        let right = newBitmap.width + x > width ? newBitmap.width + x - width : 0
        let cropped = newBitmap.cropped(top: top, bottom: bottom, left: left, right: right)

        print(cropped)
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
//        self.height = height
//        self.width = width
        return Bitmap(id: copy.id, width: width, pixels: copy.pixels)
    }
}

extension Bitmap {
    
    func prettyPrint() {
        pixels.enumerated().forEach { index, element in
            
            if index % width == 0 {
                print("\n")
            }
            print(element)
        }
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
        let isEven = width % 2 == 0
        let width = width * 3
        let height = height * 3
//        let width = min(isEven ? 16 : 15, width * 3)
//        let height = min(isEven ? 16: 15, height * 3)
        
        let white = Color(r: 255, g: 255, b: 255, a: 255)
        let gray = Color(r: 200, g: 200, b: 200, a: 255)
        
        let pixelCount = width * height
        
        let pixels: [Color] = (0...(pixelCount)).map { i in
            if isEven && (i / width) % 2 == 0 {
                return i % 2 == 0 ? gray : white
            }
            
            return i % 2 == 0 ? white : gray
        }
        
        return Bitmap(width: width, pixels: pixels)
    }
}

extension Bitmap {

    func updatedColors(with newColor: Color, at indexes: [Int]) -> [Color] {
        var new = pixels
        for index in indexes {
            new[index] = newColor
        }
        return new
    }
    
    func withChanges(newColor: Color, at indexes: [Int]) -> Bitmap {
         Bitmap(width: self.width, pixels: updatedColors(with: newColor, at: indexes))
    }
}

extension Bitmap {
    
    mutating func changeColor(_ color: Color, at indexes: [Int]) {
        indexes.forEach { i in
            pixels[i] = color
        }
    }
}
