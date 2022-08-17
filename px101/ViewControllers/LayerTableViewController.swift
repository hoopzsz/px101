//
//  LayerViewController.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-10.
//

import UIKit
import CoreData

protocol LayerViewControllerDelegate: AnyObject {
    func didSelect(index: Int)
    func didAddLayer()
}

final class LayerTableViewController: UIViewController {
    
    private var project: Project
    private var selectedLayer: Int
    
    private var fetchedResultsController: NSFetchedResultsController<BitmapObject>!
    private var layerPredicate: NSPredicate? = nil
        
    private let tableView = UITableView()
    
    private let reuseIdentifier = "cell"
        
    let width: Int
    let height: Int
    
    weak var delegate: LayerViewControllerDelegate? = nil

    init(project: Project, selectedLayer: Int) {
        self.project = project
        self.width = project.width
        self.height = project.height
        self.selectedLayer = selectedLayer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle"), style: .plain, target: self, action: #selector(addLayerButtonPressed))

        tableView.register(LayerTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 128
        tableView.dragInteractionEnabled = true
        view.addSubview(tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadData()
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
    
    @objc private func addLayerButtonPressed() {
        let alert = UIAlertController(title: "Add new layer", message: "Enter a name", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textfield in })
        alert.addAction(
            UIAlertAction(title: "Add layer", style: .default) { _ in
                guard let textField =  alert.textFields?.first else { return }
                                
                let newLayer = Bitmap(name: textField.text ?? "Unnamed", width: self.width, zIndex: self.selectedLayer + 1, pixels: (0..<self.width*self.height).map { _ in .clear })
                CoreDataStorage.save(bitmap: newLayer)
                CoreDataStorage.save(bitmap: newLayer.id, with: self.project.id)
                
                var bitmaps = CoreDataStorage.loadAllBitmaps(project: self.project.id).sorted(by: { $0.zIndex < $1.zIndex })
                for (index, bitmap) in bitmaps.enumerated() {
                    bitmaps[index].zIndex = index
                }
                
                bitmaps.forEach {
                    CoreDataStorage.save(bitmap: $0)
                }
                
                self.delegate?.didAddLayer()
//                self.tableView.reloadData()
//                CoreDataStorage.loadAllBitmaps(project: self.project.id).enumerated().forEach { index, bitmap in
//                    bitmap.zIndex = index
//                    CoreDataStorage.save(bitmap: bitmap)
//                }
            })
//                Storage.saveBitmap(newLayer, project: self.project)

//                if let projectObject = self.loadProject(id: self.project.id) , let bitmaps = projectObject.bitmaps?.allObjects as? [BitmapObject] {
//                    bitmaps.sorted(by: { $1.zIndex > $0.zIndex} )
//                        .enumerated()
//                        .forEach { index, object in
////                            print("\(object.id)\nzIndex: \(object.zIndex)\n")
//                            object.zIndex = Int16(index)
////                            print("\(object.id)\nnew zIndex: \(object.zIndex)\n")
//                        }
                
//            } else {
//                    print("no project object")
//                }

        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func updateZIndexes() {
//        let data =
    }
    
    private func loadProject(id: UUID) -> ProjectObject? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext
        
        let request = ProjectObject.fetchRequest()
        let sort = NSSortDescriptor(key: "id", ascending: false)
        request.sortDescriptors = [sort]
        request.predicate = NSPredicate(format: "id = %@", id.uuidString)

        let projectObjects = try? context.fetch(request)
        
        return projectObjects?.first
    }
    
    private func loadBitmaps(fromProject project: ProjectObject) -> [BitmapObject] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let context = appDelegate.persistentContainer.viewContext
        
        let bitmapRequest = BitmapObject.fetchRequest()
        let bitmapSort = NSSortDescriptor(key: "zIndex", ascending: false)
        bitmapRequest.sortDescriptors = [bitmapSort]
        bitmapRequest.predicate = NSPredicate(format: "toProject == %@", project)
        
        let bitmaps = try? context.fetch(bitmapRequest)
        return bitmaps ?? []
    }
    
    private func loadData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let projectRequest = ProjectObject.fetchRequest()
        let projectSort = NSSortDescriptor(key: "id", ascending: false)
        projectRequest.sortDescriptors = [projectSort]
        projectRequest.predicate = NSPredicate(format: "id = %@", project.id.uuidString)

        let projectObjects = try? context.fetch(projectRequest)
        
        guard let projectObject = projectObjects?.first else { return }
        
        let bitmapRequest = BitmapObject.fetchRequest()
        let bitmapSort = NSSortDescriptor(key: "zIndex", ascending: false)
        bitmapRequest.sortDescriptors = [bitmapSort]
//        bitmapRequest.predicate = NSPredicate(format: "toProject == %@", projectObject)

        fetchedResultsController = NSFetchedResultsController(fetchRequest: bitmapRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "zIndex", ascending: false)]
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "toProject == %@", projectObject)

        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("Fetch failed")
        }
    }
}

extension LayerTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bitmapObj = fetchedResultsController.sections![indexPath.section].objects![indexPath.row] as! BitmapObject
        if let bitmap = Bitmap(object: bitmapObj) {
            delegate?.didSelect(index: bitmap.zIndex)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
}

extension LayerTableViewController: UITableViewDataSource {
    
//    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
//            UIMenu(title: "", children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
//                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//                let context = appDelegate.persistentContainer.viewContext
//
//                let layer = self.fetchedResultsController.object(at: indexPath)
//                context.delete(layer)
//
//                do {
//                    try self.fetchedResultsController.performFetch()
//                    tableView.reloadData()
//                    try? context.save()
//                } catch {
//                    print("Fetch failed")
//                }
//
//                self.delegate?.didAddLayer() // rename this. reloading the canvas
//            }])
//        }
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections![section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? LayerTableViewCell else { return }
        let bitmapObject = fetchedResultsController.object(at: indexPath)
        if let bitmap = Bitmap(object: bitmapObject) {
            cell.setBitmap(bitmap: bitmap)
            cell.delegate = self
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    }
}

extension LayerTableViewController: LayerTableViewCellDelegate {
    
    func hideButtonPressed(_ id: UUID) {
//        guard let object = fetchedResultsController.fetchedObjects?.first(where: { $0.id == id }) else {
//            print("did not fetch bitmap object on button press")
//            return
            
//        }
        
        if var bitmap = CoreDataStorage.load(bitmap: id) {
            bitmap.isHidden.toggle()
            CoreDataStorage.save(bitmap: bitmap)
            self.delegate?.didAddLayer() // rename this. just reloading data
        }
        
        

//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//        let context = appDelegate.persistentContainer.viewContext
//        try? context.save()
    }
}

protocol LayerTableViewCellDelegate: AnyObject {
    func hideButtonPressed(_ id: UUID)
}

final class LayerTableViewCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let transparencyImageView = UIImageView()
    private let bitmapImageView = UIImageView()
    private let hideButton = UIButton()
    
    private var isLayerHidden = false
    
    weak var delegate: LayerTableViewCellDelegate? = nil
    
    private var bitmapId: UUID? = nil
//    private let isHiddenCheckbox = UIButton()
//    private let hiddenImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        
        hideButton.setImage(UIImage(systemName: "eye")?.withTintColor(.label), for: .normal)
        hideButton.addTarget(self, action: #selector(hideButtonPressed), for: .touchUpInside)
        
        bitmapImageView.contentMode = .scaleAspectFill
        bitmapImageView.layer.magnificationFilter = .nearest
        transparencyImageView.layer.magnificationFilter = .nearest
        
        customSubviews
            .forEach(contentView.addSubview)
        
        customSubviews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let x: CGFloat = 72
        NSLayoutConstraint.activate([
            hideButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            hideButton.widthAnchor.constraint(equalToConstant: 32),
            hideButton.heightAnchor.constraint(equalToConstant: 32),

            bitmapImageView.leadingAnchor.constraint(equalTo: hideButton.trailingAnchor, constant: 8),
            bitmapImageView.widthAnchor.constraint(equalToConstant: x),
            bitmapImageView.heightAnchor.constraint(equalToConstant: x),
            
            transparencyImageView.leadingAnchor.constraint(equalTo: hideButton.trailingAnchor, constant: 8),
            transparencyImageView.widthAnchor.constraint(equalToConstant: x),
            transparencyImageView.heightAnchor.constraint(equalToConstant: x),
            
            nameLabel.leadingAnchor.constraint(equalTo: bitmapImageView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -8)] +
                                    centerYConstraints
        )
    }
    
    func setBitmap(bitmap: Bitmap) {
        bitmapId = bitmap.id
        isLayerHidden = bitmap.isHidden
        transparencyImageView.image = UIImage(bitmap: Bitmap.transparencyIndicator(of: bitmap.width, height: bitmap.height))
        bitmapImageView.image = UIImage(bitmap: bitmap)
        nameLabel.textColor = .label
        nameLabel.text = bitmap.name
        let imageName = isLayerHidden ? "eye.slash" : "eye"
        hideButton.setImage(UIImage(systemName: imageName)?.withTintColor(.label), for: .normal)
    }
    
    private var centerYConstraints: [NSLayoutConstraint] {
        customSubviews.map {
            $0.centerYAnchor.constraint(equalTo: guide.centerYAnchor)
        }
    }
    
    private var customSubviews: [UIView] {
        [hideButton, transparencyImageView, nameLabel, bitmapImageView]
    }
    
    private var guide: UILayoutGuide {
        contentView.layoutMarginsGuide
    }
    
    @objc private func hideButtonPressed() {
        guard let bitmapId = bitmapId else { return }
        delegate?.hideButtonPressed(bitmapId)
        isLayerHidden.toggle()
        let imageName = isLayerHidden ? "eye.slash" : "eye"
        hideButton.setImage(UIImage(systemName: imageName)?.withTintColor(.label), for: .normal)
    }
}

extension LayerTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        default:
            break
        }
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        default:
            break
        }
    }
     
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        tableView.endUpdates()

    }
}

final class LayerViewController: UIViewController {
    
    private let project: Project
    private var bitmaps: [Bitmap]
    private let selection: Int
        
    private let tableView = UITableView()
    private let reuseIdentifier = "cell"
    
    private var width: Int {
        project.width
    }
    private var height: Int {
        project.height
    }
        
    init(project: Project, bitmaps: [Bitmap], selection: Int) {
        self.project = project
        self.bitmaps = bitmaps
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle"), style: .plain, target: self, action: #selector(addLayerButtonPressed))

        tableView.register(LayerTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 128
        tableView.dragInteractionEnabled = true
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
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
    
    @objc private func addLayerButtonPressed() {
        let alert = UIAlertController(title: "Add new layer", message: "Enter a name", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textfield in })
        alert.addAction(
            UIAlertAction(title: "Add layer", style: .default) { _ in
                guard let textField =  alert.textFields?.first else { return }
                                
                let newLayer = Bitmap(name: textField.text ?? "Unnamed", width: self.width, zIndex: 1, pixels: (0..<self.width*self.height).map { _ in .clear })
//                bitmaps.insert(newLayer)
//                CoreDataStorage.save(bitmap: newLayer)
                CoreDataStorage.save(bitmap: newLayer.id, with: self.project.id)
                
//                var bitmaps = CoreDataStorage.loadAllBitmaps(project: self.project.id).sorted(by: { $0.zIndex < $1.zIndex })
//                for (index, bitmap) in bitmaps.enumerated() {
//                    bitmaps[index].zIndex = index
//                }
                
//                bitmaps.forEach {
//                    CoreDataStorage.save(bitmap: $0)
//                }
                
//                self.delegate?.didAddLayer()
                self.tableView.reloadData()
//                CoreDataStorage.loadAllBitmaps(project: self.project.id).enumerated().forEach { index, bitmap in
//                    bitmap.zIndex = index
//                    CoreDataStorage.save(bitmap: bitmap)
//                }
            })
    }
}

extension LayerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
}

extension LayerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bitmaps.count
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? LayerTableViewCell else { return }
        let bitmap = bitmaps[indexPath.row]
        cell.setBitmap(bitmap: bitmap)
        cell.delegate = self
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    }
    
    //    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    //        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
    //            UIMenu(title: "", children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
    //                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    //                let context = appDelegate.persistentContainer.viewContext
    //
    //                let layer = self.fetchedResultsController.object(at: indexPath)
    //                context.delete(layer)
    //
    //                do {
    //                    try self.fetchedResultsController.performFetch()
    //                    tableView.reloadData()
    //                    try? context.save()
    //                } catch {
    //                    print("Fetch failed")
    //                }
    //
    //                self.delegate?.didAddLayer() // rename this. reloading the canvas
    //            }])
    //        }
    //    }
}

extension LayerViewController: LayerTableViewCellDelegate {
    
    func hideButtonPressed(_ id: UUID) {
        
    }
}

