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

struct Palette {
    var colors: [Color]
}

extension Palette {
    static let `default`: Palette = Palette(colors: [
        .black,
        .white,
        .red,
        .orange,
        .yellow,
        .yellowGreen,
        .green,
        .blueGreen,
        .skyBlue,
        .lightBlue,
        .blue,
        .purple,
        .pink,
        .magenta,
        .gray,
        .clear
    ])
}

protocol PaletteDelegate: AnyObject {
    func didSelectColor(_ color: Color)
    func didPressPlusButton()
}

final class PaletteViewController: UIViewController {
    
    let collectionView: UICollectionView
    private let cellIdentifier = "paletteCell"
//    var palette: PaletteViewModel
    var palette: Palette
    
    private var selection = 0
    private var selectedIndexPath: IndexPath? = nil

    weak var delegate: PaletteDelegate? = nil
    
    init(palette: Palette) {
        self.palette = palette
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)

        delegate?.didSelectColor(palette.colors[0])
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
//        if let selectedIndexPath = selectedIndexPath, let previousSelectionCell = collectionView.cellForItem(at: selectedIndexPath) {
//            previousSelectionCell.animateDeselection()
//        }
//
//        if let cell = collectionView.cellForItem(at: indexPath) {
            if indexPath.row == palette.colors.count {
                delegate?.didPressPlusButton()
            } else {
//                cell.animateSelection()
                selection = indexPath.row
                selectedIndexPath = indexPath
                delegate?.didSelectColor(palette.colors[selection])
            }
//        }
        
//        collectionView.setNeedsDisplay()
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.palette.colors.remove(at: indexPath.row)
                collectionView.reloadData()
            }])
        }
    }
}

extension PaletteViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        palette.colors.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.layer.borderColor = UIColor.label.cgColor
        cell.layer.shadowColor = UIColor.tertiaryLabel.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 3)
        cell.layer.borderWidth = 2
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        if indexPath.row == palette.colors.count {
            cell.backgroundColor = .clear
            cell.layer.cornerRadius = 14
            cell.layer.borderColor = UIColor.clear.cgColor
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
            imageView.image = UIImage(systemName: "plus.circle.fill")
            imageView.tintColor = .systemGray
            cell.contentView.addSubview(imageView)
        } else {
            cell.layer.cornerRadius = 0
            cell.backgroundColor = palette.colors[indexPath.row].uiColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
    }
}
