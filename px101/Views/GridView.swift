//
//  StrokeGridView.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit

enum GridSize {
    case small, medium, large
}

final class StrokeGridView: PixelView {
    
    var strokeColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var gridSize: GridSize = .small {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard width > 1 && height > 1 else { return }
        
        context.setStrokeColor(strokeColor.withAlphaComponent(0.5).cgColor)
        
        let wSize = rect.width / CGFloat(width)
//        let hSize = rect.width / CGFloat(height)

        let widthQuarterMark = width/4
        let widthHalf = width/2
        
        let heightQuarterMark = height/4
        let heightHalf = height/2
        
        (0...width).forEach {
            switch gridSize {
            case .small:
                break
            case .medium:
                if $0 % 2 != 0 { return }
            case .large:
                if $0 % 4 != 0 { return }
            }
            
            let x = wSize * CGFloat($0)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
            
            if $0 % widthHalf == 0 {
                context.setLineWidth(1.0)
            } else if $0 % widthQuarterMark == 0 {
                context.setLineWidth(0.5)
            } else {
                context.setLineWidth(0.25)
            }
            
            context.strokePath()
        }
        
        (0...height).forEach {
            switch gridSize {
            case .small:
                break
            case .medium:
                if $0 % 2 != 0 { return }
            case .large:
                if $0 % 4 != 0 { return }
            }
            
            let y = wSize * CGFloat($0)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
            
            if $0 % heightHalf == 0 {
                context.setLineWidth(1.0)
            } else if $0 % heightQuarterMark == 0 {
                context.setLineWidth(0.5)
            } else {
                context.setLineWidth(0.25)
            }
            
            context.strokePath()
        }
    }
}
