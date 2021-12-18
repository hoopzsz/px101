//
//  UIColorExtensions.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit

extension UIColor {
    
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
    
    var rgbaSafe: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red < 0 ? 0 : red, green < 0 ? 0 : green, blue < 0 ? 0 : blue, alpha < 0 ? 0 : alpha)
    }
}
