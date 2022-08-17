//
//  ColorSelectionView.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-18.
//

import UIKit

//protocol ColorSelectionDelegate: AnyObject {
//    func didChangeColors(_ strokeColor: UIColor, _ fillColor: UIColor)
//}
/*
final class ColorSelectionView: UIView {
    
    weak var delegate: ColorSelectionDelegate? = nil
    
    var strokeColor: UIColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var fillColor: UIColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init(strokeColor: UIColor, fillColor: UIColor, frame: CGRect) {
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.label.cgColor)
        context.setFillColor(fillColor.cgColor)
        let strokeRect = CGRect(x: 0, y: 0, width: rect.width * 0.75, height: rect.height * 0.75)
        let fillRect = CGRect(x: rect.width * 0.25, y: rect.width * 0.25, width: rect.width * 0.75, height: rect.height * 0.75)
        
        
        context.setFillColor(fillColor.cgColor)
        context.addRect(fillRect)
        context.drawPath(using: .fillStroke)
        context.setFillColor(strokeColor.cgColor)
        context.addRect(strokeRect)
        context.drawPath(using: .fillStroke)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let oldStroke = strokeColor
        let oldFill = fillColor
        strokeColor = oldFill
        fillColor = oldStroke
        delegate?.didChangeColors(strokeColor, fillColor)
    }
}
*/
