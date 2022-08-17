//
//  ProjectsViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit
import CoreData

final class ProjectViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    private let containerView = UIView()
    private let collectionView = ProjectCollectionViewController()
    
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
        imageView.layer.magnificationFilter = .nearest
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
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
////        containerView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
////        collectionView.view.frame = containerView.frame
//
//        let leadingAnchor = size.width > size.height ? view.layoutMarginsGuide.leadingAnchor : view.leadingAnchor
//        NSLayoutConstraint.activate([
//            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
////            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////            containerView.topAnchor.constraint(equalTo: view.topAnchor),
////            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//    }
    
    @objc private func addArtworkButtonPressed() {
        let vc = NewProjectViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func addCollectionView() {
        view.addSubview(containerView)
        
        collectionView.view.frame = containerView.frame
        containerView.addSubview(collectionView.view)
        collectionView.willMove(toParent: self)
        addChild(collectionView)
        collectionView.didMove(toParent: self)
        
        collectionView.didSelect = { projectObject in
            if let id = projectObject.id, let project = CoreDataStorage.load(project: id) {
                let bitmaps = CoreDataStorage.loadAllBitmaps(project: id)
                let viewController = CanvasViewController(project: project, bitmaps: bitmaps)
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
}

final class ProjectCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate {

    private var collectionView: UICollectionView!
    private let cellIdentifier = "cellIdentifier"
    
    private var fetchedResultsController: NSFetchedResultsController<ProjectObject>!
    private var layerPredicate: NSPredicate? = nil
    
    var didSelect: (ProjectObject) -> () = { project in

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
//        let context = persistentContainer.viewContext
        let request = ProjectObject.fetchRequest()
        let sort = NSSortDescriptor(key: "lastUpdateDate", ascending: false)
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
}

extension ProjectCollectionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchedResultsController.sections![section].numberOfObjects
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImageCollectionViewCell else { return }
        
        let projectObj = fetchedResultsController.object(at: indexPath)
        if let project = Project(object: projectObj), let bitmap = project.combinedBitmap {
            cell.setBitmap(bitmap)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
    }
}

extension ProjectCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let projectpObj = fetchedResultsController.sections![indexPath.section].objects![indexPath.row] as! ProjectObject
//        if let project = Project(object: projectpObj) {
            didSelect(projectpObj)
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                let context = appDelegate.persistentContainer.viewContext
//                let context = persistentContainer.viewContext

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
