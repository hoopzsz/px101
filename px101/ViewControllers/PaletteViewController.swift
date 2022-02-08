//
//  PaletteViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit

struct PaletteViewModel {
    let name: String
    var colors: [UIColor]
}

//struct Palette: Codable {
//    var colors: [Color]
//}

////extension Palette {
//    static let `default`: [Color] = [
//        .black,
//        .gray,
//        .white,
//        .red,
//        .orange,
//        .yellow,
////        .yellowGreen,
//        .green,
////        .blueGreen,
////        .skyBlue,
//        .lightBlue,
//        .blue,
//        .purple,
////        .pink,
//        .magenta,
//    ]
////}

protocol PaletteDelegate: AnyObject {
    func didSelectColor(_ color: Color)
    func didPressPlusButton()
}

final class PaletteViewController: UIViewController {
    
    let collectionView: UICollectionView
    private let cellIdentifier = "paletteCell"
//    var palette: PaletteViewModel
    var palette: [Color]
    
    private var selection = 0
    private var selectedIndexPath: IndexPath? = nil

    weak var delegate: PaletteDelegate? = nil
    
    init(palette: [Color]) {
        self.palette = palette
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = true

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ColorPaletteCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)

        delegate?.didSelectColor(palette[0])
    }
    
    override func viewWillLayoutSubviews() {
        collectionView.frame = view.frame
    }
}

extension PaletteViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 32, height: 32)
    }
}

extension PaletteViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedIndexPath = selectedIndexPath, let previousSelectionCell = collectionView.cellForItem(at: selectedIndexPath) as? ColorPaletteCollectionViewCell {
            if collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
                previousSelectionCell.animateDeselection()
            }
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? ColorPaletteCollectionViewCell {
            if indexPath.row == palette.count + 1 {
                delegate?.didPressPlusButton()
            } else if indexPath.row == palette.count {
                cell.animateSelection()
                selection = indexPath.row
                selectedIndexPath = indexPath
                delegate?.didSelectColor(.clear)
            } else {
                cell.animateSelection()
                selection = indexPath.row
                selectedIndexPath = indexPath
                delegate?.didSelectColor(palette[selection])
            }
        }
        
        collectionView.setNeedsDisplay()
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.row != palette.count && indexPath.row != palette.count + 1 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(title: "", children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self.palette.remove(at: indexPath.row)
                    collectionView.reloadData()
                }])
            }
        } else {
            return nil
        }
    }
}

extension PaletteViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        palette.count + 2
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ColorPaletteCollectionViewCell else { return }
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.layer.sublayers?.removeAll()
        if indexPath.row == palette.count + 1 { // Add button
            cell.setColor(.clear)
//            cell.backgroundColor = .clear
//            cell.layer.cornerRadius = 14
            cell.layer.borderColor = UIColor.clear.cgColor
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
            imageView.image = UIImage(systemName: "plus.circle.fill")
            imageView.tintColor = .tertiaryLabel
            cell.contentView.addSubview(imageView)
        } else if indexPath.row == palette.count { // Clear color
            cell.setColor(.white)
            let line = CAShapeLayer()
            let linePath = UIBezierPath()
            let bottomLeft = CGPoint(x: 0, y: cell.frame.height)
            let topRight = CGPoint(x: cell.frame.width, y: 0)
            linePath.move(to: bottomLeft)
            linePath.addLine(to: topRight)
            line.path = linePath.cgPath
            line.strokeColor = UIColor.red.cgColor
            line.lineWidth = 3
            line.lineJoin = .round
            cell.contentView.layer.addSublayer(line)
        } else {
            cell.setColor(palette[indexPath.row])
            cell.layer.borderColor = UIColor.label.cgColor
        }
        
        if indexPath == selectedIndexPath {
            cell.animateSelection()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath == selectedIndexPath, let cell = cell as? ColorPaletteCollectionViewCell {
            cell.animateDeselection()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
    }
}

extension UICollectionViewCell {

    func drawClearColorIndicator() {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(.red)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: 0, y: bounds.height))
        context.addLine(to: CGPoint(x: bounds.width, y: 0))
        context.strokePath()
    }
}

final class ColorPaletteCollectionViewCell: UICollectionViewCell {
    
    var isClear = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderWidth = 2
        layer.borderColor = UIColor.label.cgColor
        layer.shadowColor = UIColor.tertiaryLabel.cgColor
        layer.shadowRadius = 3.0
        layer.shadowOffset = CGSize(width: 0, height: 3)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setColor(_ color: Color) {
        if color == .clear {
            isClear = true
            contentView.backgroundColor = .clear
            setNeedsDisplay()
        } else {
            isClear = false
            contentView.backgroundColor = color.uiColor
        }
    }
    
    func animateSelection() {
        UIView.animate(withDuration: 0.2 ) {
            self.center = CGPoint(x: self.center.x, y: self.center.y - 4)
            self.layer.borderColor = UIColor.green.cgColor
            self.layer.shadowOpacity = 0.5

        }
    }
    
    func animateDeselection() {
        UIView.animate(withDuration: 0.2) {
            self.center = CGPoint(x: self.center.x, y: self.center.y + 4)
            self.layer.borderColor = UIColor.label.cgColor
            self.layer.shadowOpacity = 0

        }
    }
}

