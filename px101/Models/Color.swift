//
//  Color.swift
//  px101
//
//  Created by Daniel Hooper on 2021-11-26.
//

import UIKit

struct Color: Codable, Equatable, Hashable {
    var r, g, b: UInt8
    var a: UInt8 = 255
}

extension Color {
    init(uiColor: UIColor) {
        let rgba = uiColor.rgbaSafe
        
        self.r = UInt8(rgba.red * 255)
        self.g = UInt8(rgba.green * 255)
        self.b = UInt8(rgba.blue * 255)
        self.a = UInt8(rgba.alpha * 255)
    }
}

extension Color {
    var hex: String {
        String(format:"%02X", r) + String(format:"%02X", g) + String(format:"%02X", b)
    }
    
    /// For odering the color palette in the canvas
    var darkLevel: Int {
        Int(r) + Int(g) + Int(b)
    }
}

extension UIImage {
    
    convenience init?(bitmap: Bitmap) {
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bytesPerPixel = MemoryLayout<Color>.stride
        let bytesPerRow = bitmap.width * bytesPerPixel

        guard let providerRef = CGDataProvider(data: Data(bytes: bitmap.pixels, count: bitmap.height * bytesPerRow) as CFData) else {
            return nil
        }

        guard let cgImage = CGImage(
            width: bitmap.width,
            height: bitmap.height,
            bitsPerComponent: 8,
            bitsPerPixel: bytesPerPixel * 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }

        self.init(cgImage: cgImage)
    }

}

extension Color {
    
    var uiColor: UIColor {
        UIColor(red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: CGFloat(a) / 255.0)
    }
    
    var cgColor: CGColor {
        uiColor.cgColor
    }
}

extension Color {
    
    static let white = Color(r: 255, g: 255, b: 255, a: 255)
    static let black = Color(r: 0, g: 0, b: 0, a: 255)
    static let gray = Color(r: 128, g: 128, b: 128, a: 255)
    static let clear = Color(r: 0, g: 0, b: 0, a: 0)

    static let red = Color(r: 255, g: 0, b: 0, a: 255)
    static let orange = Color(r: 255, g: 128, b: 0, a: 255)
    static let yellow = Color(r: 255, g: 255, b: 0, a: 255)
    static let yellowGreen = Color(r: 128, g: 255, b: 0, a: 255)
    static let green = Color(r: 0, g: 255, b: 0, a: 255)
    static let blueGreen = Color(r: 0, g: 255, b: 128, a: 255)
    static let skyBlue = Color(r: 0, g: 255, b: 255, a: 255)
    static let lightBlue = Color(r: 0, g: 128, b: 255, a: 255)
    static let blue = Color(r: 0, g: 0, b: 255, a: 255)
    static let purple = Color(r: 128, g: 0, b: 255, a: 255)
    static let pink = Color(r: 255, g: 0, b: 255, a: 255)
    static let magenta = Color(r: 255, g: 0, b: 128, a: 255)
}
