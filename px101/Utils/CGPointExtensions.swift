//
//  CGPointExtensions.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit

extension CGPoint {
    
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func += (left: inout CGPoint, right: CGPoint) {
      left = left + right
    }
}
