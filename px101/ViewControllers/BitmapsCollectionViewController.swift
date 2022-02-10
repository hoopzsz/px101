//
//  BitmapsCollectionViewController.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-04.
//

import UIKit
import CoreData

final class BitmapsCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate {

    private var collectionView: UICollectionView!
    private let cellIdentifier = "cellIdentifier"
    
    private var fetchedResultsController: NSFetchedResultsController<BitmapObject>!
    private var layerPredicate: NSPredicate? = nil
    
    var didSelect: (Bitmap) -> () = { bitmap in
        
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backButtonTitle = ""
        view.backgroundColor = .systemBackground
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        layout.itemSize = CGSize(width: view.frame.width / 3, height: view.frame.width / 3)


        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        view.addSubview(collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
    }
    
    private func loadData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let request = BitmapObject.fetchRequest()
        let sort = NSSortDescriptor(key: "id", ascending: false)
        request.sortDescriptors = [sort]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        fetchedResultsController.fetchRequest.predicate = layerPredicate

        do {
            try fetchedResultsController.performFetch()
            collectionView.reloadData()
        } catch {
            print("Fetch failed")
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
//            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
//        ])
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        collectionView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        NSLayoutConstraint.activate([
//            collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
//            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
//        ])
//    }
}

extension BitmapsCollectionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchedResultsController.sections![section].numberOfObjects
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImageCollectionViewCell else { return }
        
        let bitmapObj = fetchedResultsController.object(at: indexPath)
        
        if let bitmap = Bitmap(obj: bitmapObj) {
            cell.setBitmap(bitmap)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
    }
}

extension BitmapsCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bitmapObj = fetchedResultsController.sections![indexPath.section].objects![indexPath.row] as! BitmapObject
        if let bitmap = Bitmap(obj: bitmapObj) {
            didSelect(bitmap)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                let context = appDelegate.persistentContainer.viewContext
    
                let layer = self.fetchedResultsController.object(at: indexPath)
                context.delete(layer)
                
                do {
                    try self.fetchedResultsController.performFetch()
                    collectionView.reloadData()
                    try? context.save()
                } catch {
                    print("Fetch failed")
                }
            }])
        }
    }
}
