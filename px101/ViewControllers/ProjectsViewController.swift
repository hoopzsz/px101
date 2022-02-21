//
//  ProjectsViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit
import CoreData
//
//struct Project: Codable {
//    var id = UUID()
//    let name: String
//    let creationDate: Date
//    let lastEditedDate: Date
//}

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
        let results = try? context.fetch(fetchRequest)
        
        let object: BitmapObject
        if results?.count == 0 {
            object = BitmapObject(context: context)
        } else {
            object = results!.first!
        }
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
    
    private let containerView = UIView()
    private let collectionView = BitmapsCollectionViewController()
    
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
        
        view.addSubview(containerView)
        containerView.frame = view.frame
        addCollectionView()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle"), style: .plain, target: self, action: #selector(addArtworkButtonPressed))
        
        let px101Cases: [Px101Logo] = [.p, .space2, .x, .space2, .dash, .space1, .one, .space2, .zero, .space1, .one]
        let px101 = px101Cases
            .map { $0.bitmap }
            .reduce(.initial) { stitch($0, to: $1) }
            .scaled(2)
        
        let imageView = UIImageView(image: UIImage(bitmap: px101)?.withTintColor(.label))
        imageView.contentMode = .center
        imageView.layer.magnificationFilter = .linear
        navigationItem.titleView = imageView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.view.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingAnchor = view.frame.size.width > view.frame.size.height ? view.layoutMarginsGuide.leadingAnchor : view.leadingAnchor
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        containerView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        collectionView.view.frame = containerView.frame
        
        let leadingAnchor = size.width > size.height ? view.layoutMarginsGuide.leadingAnchor : view.leadingAnchor
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            containerView.topAnchor.constraint(equalTo: view.topAnchor),
//            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    @objc private func addArtworkButtonPressed() {
        let vc = NewProjectViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func addCollectionView() {
//        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        collectionView.view.frame = containerView.frame
//        paletteViewController.delegate = self
        containerView.addSubview(collectionView.view)
//        paletteViewController.view.clipsToBounds = true
        collectionView.willMove(toParent: self)
        addChild(collectionView)
        collectionView.didMove(toParent: self)
        
        collectionView.didSelect = { bitmap in
            let viewController = CanvasViewController(bitmap: bitmap)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}


//
//extension UIView {
//
//    func addShadow(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) {
//        layer.shadowColor = color.cgColor
//        layer.shadowOpacity = opacity
//        layer.shadowRadius = radius
//        layer.shadowOffset = offset
//    }
//}
