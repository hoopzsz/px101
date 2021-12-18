//
//  GridView.swift
//  px101
//
//  Created by Daniel Hooper on 2021-11-26.
//

import UIKit

class PixelView: UIView {
    
    internal let width: Int
    internal let height: Int
    
    convenience init(width: Int, height: Int) {
        self.init(width: width, height: height, frame: .zero)
    }
    
    init(width: Int, height: Int, frame: CGRect) {
        self.width = width
        self.height = height
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal var pixelWidth: CGFloat {
        frame.width / CGFloat(width)
    }
    
    internal var cellHeight: CGFloat {
        frame.height / CGFloat(height)
    }

    internal func location(forCellIndex i: Int) -> CGPoint {
        CGPoint(x: CGFloat(i % width) * pixelWidth,
                y: CGFloat(i / height) * cellHeight)
    }

    internal func cellIndex(at location: CGPoint) -> Int {
        let x = clamp(location.x, minValue: bounds.minX, maxValue: bounds.maxX - 0.1)
        let y = clamp(location.y, minValue: bounds.minY, maxValue: bounds.maxY - 0.1)
        return Int(x / pixelWidth) + Int(y / cellHeight) * width
    }
    
    internal var isOdd: Bool {
        width % 2 == 0
    }
}

public func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable {
    return min(max(value, minValue), maxValue)
}
