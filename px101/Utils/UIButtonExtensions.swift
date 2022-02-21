//
//  UIButtonExtensions.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-18.
//

import UIKit

extension UIButton {
    
    convenience init(systemImageName: String, target: Any?, selector: Selector) {
        self.init(type: .system)
        setImage(UIImage(systemName: systemImageName), for: .normal)
        addTarget(target, action: selector, for: .touchUpInside)
    }
    
    convenience init(image: UIImage?, target: Any?, selector: Selector) {
        self.init(type: .system)
        setImage(image, for: .normal)
        addTarget(target, action: selector, for: .touchUpInside)
    }
}

