//
//  GestureView.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit

protocol GestureViewDelegate: AnyObject {
    func didTap(at index: Int)
    func didBeginDragging(at index: Int)
    func isDragging(at index: Int)
    func didEndDragging(at index: Int)
}

/// Handles touch events for drawing and manipulating pictures
final class GestureView: PixelView {
    
    var touchDownIndex = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var touchCurrentIndex = 0
    var touchUpIndex = 0
    
    var rects: [CGRect] = []
    
    weak var delegate: GestureViewDelegate? = nil
    
    convenience init(width: Int, height: Int) {
        self.init(width: width, height: height, frame: .zero)
    }

    override init(width: Int, height: Int, frame: CGRect) {
        super.init(width: width, height: height, frame: frame)
        addGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addGestures() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(drag))
        gesture.minimumPressDuration = 0.01
        addGestureRecognizer(gesture)
    }
    
    @objc func drag(_ gesture: UIGestureRecognizer) {
        let location = gesture.location(in: self)
        let index = cellIndex(at: location)
        
        switch gesture.state {
        case .began:
            touchDownIndex = index
            touchCurrentIndex = index
            delegate?.didBeginDragging(at: index)
        case .changed:
            touchCurrentIndex = index
            delegate?.isDragging(at: index)
        case .ended:
            touchUpIndex = index
            touchCurrentIndex = index
            delegate?.didEndDragging(at: index)
        default:
            break
        }
    }
}

extension CGColor {
    
    static var red: CGColor {
        UIColor.red.cgColor
    }
    
    static var clear: CGColor {
        UIColor.clear.cgColor
    }
}
