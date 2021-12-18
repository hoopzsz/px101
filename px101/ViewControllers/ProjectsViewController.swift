//
//  ProjectsViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit
import CoreData

struct Storage {
    
    func fetchBitmaps() -> [Bitmap] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = BitmapObject.fetchRequest()
        
        do {
            let objects = try managedContext.fetch(fetchRequest)
            let bitmaps: [Bitmap] = objects.compactMap { object in
                guard
                      let id = object.value(forKeyPath: "id") as? UUID,
                      let width = object.value(forKeyPath: "width") as? Int,
                      let pixelData = object.value(forKeyPath: "pixels") as? Data
                else {
                    print("!!!")
                    return nil
                }
//                let pixels = pixelData.compactMap { Color.color(data: $0) }
                return Bitmap(id: id, width: width, data: pixelData)
            }
            return bitmaps
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }
    
    func saveBitmap(_ bitmap: Bitmap) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = BitmapObject.fetchRequest()

        fetchRequest.predicate = NSPredicate(format: "id = %@", bitmap.id.uuidString)
//
        let results = try? context.fetch(fetchRequest)
        
        let object: BitmapObject
        if results?.count == 0 {
            object = BitmapObject(context: context)
        } else {
            object = results!.first!
        }
//
        object.id = bitmap.id
        object.width = Int16(bitmap.width)
        object.pixels = try! JSONEncoder().encode(bitmap.pixels)

        do {
            try context.save()
        } catch {
            print("Unable to Save Bitmap, \(error)")
        }
    }
}

final class ProjectsViewController: UIViewController, NSFetchedResultsControllerDelegate {

    private var collectionView: UICollectionView!
    private let cellIdentifier = "cellIdentifier"
    
    private var fetchedResultsController: NSFetchedResultsController<BitmapObject>!
    private var layerPredicate: NSPredicate? = nil
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = UIColor(red: 100.0/255.0, green: 112.0/255.0, blue: 90.0/255.0, alpha: 1.0)
//        view.backgroundColor = .gray
        navigationItem.backButtonTitle = ""
        view.backgroundColor = .tertiarySystemBackground
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        view.addSubview(collectionView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(addArtworkButtonPressed))
        let px101Cases: [Px101Logo] = [.space2, .x, .space2, .dash, .space1, .one, .space2, .zero, .space1, .one]
        let px101 = px101Cases
            .map { $0.bitmap }
            .reduce(Px101Logo.p.bitmap) { stitch($0, to: $1) }
//            .scaled(2)
        
        let imageView = UIImageView(image: UIImage(bitmap: px101)?.withTintColor(.tertiaryLabel))
        imageView.contentMode = .center
        navigationItem.titleView = imageView
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
    
    @objc private func addArtworkButtonPressed() {
        let vc = NewProjectViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ProjectsViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchedResultsController.sections![section].numberOfObjects
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImageCollectionViewCell else { return }
        
        let bitmapObj = fetchedResultsController.object(at: indexPath)
        
        if let bitmap = Bitmap(obj: bitmapObj) {
            cell.setBitmap(bitmap)
        }
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.label.cgColor
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
    }
}

extension ProjectsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bitmapObj = fetchedResultsController.sections![indexPath.section].objects![indexPath.row] as! BitmapObject
        let bitmap = Bitmap(obj: bitmapObj)
        let viewController = CanvasViewController(bitmap: bitmap!)
        navigationController?.pushViewController(viewController, animated: true)
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

extension ProjectsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 96, height: 96)
    }
}

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

extension UIView {

    func addShadow(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
    }
}
