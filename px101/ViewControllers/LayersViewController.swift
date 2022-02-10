//
//  LayersViewController.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-10.
//
/*
import UIKit

final class LayersViewController: UIViewController {
    
    private let tableView = UITableView()
    
    private var layers: [Bitmap] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }
}

extension LayersViewController: UITableViewDelegate {
    
}

extension LayersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        layers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    }
}

final class LayerCollectionViewCell: UICollectionViewCell {
    
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
*/
