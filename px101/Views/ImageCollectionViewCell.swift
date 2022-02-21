//
//  ImageCollectionViewCell.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-18.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    private let transparencyImageView = UIImageView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFit
        imageView.layer.magnificationFilter = .nearest // Prevents low-res bitmaps from appearing blurry
        imageView.layer.borderWidth = 1
        
        contentView.addSubview(transparencyImageView)
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        transparencyImageView.frame = bounds
    }

    func setBitmap(_ bitmap: Bitmap) {
        transparencyImageView.image = UIImage(bitmap: Bitmap.transparencyIndicator(of: bitmap.width, height: bitmap.height))

        let image = UIImage(bitmap: bitmap)
        imageView.image = image
    }
}
