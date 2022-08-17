//
//  CanvasViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-10.
//

import UIKit

final class CanvasViewController: UIViewController, UINavigationControllerDelegate {
    
    /// A scrollview to enable zooming in an out
    private let scrollview = UIScrollView()
    
    /// The container view for the layers, grid, and gesture view
    private let containerView = UIView()
    
    /// The container view for the layers, grid, and gesture view
    private let layerContainerView = UIView()
    
    /// Displays a checkerboard pattern indiicating empty space
    private let transparencyView = UIImageView()
    
    /// The bitmap layers of a project
    private var layerViews: [UIImageView] = []
    
    /// Shows the results of a gesture interaction befor commiting a change to the artwork
    private let previewView = UIImageView()

    /// A view displayed to the user to allow them to trace another layer or photo
    private let onionView = UIImageView()

    /// A guide for the user to see where they're placing pixels
    private let gridView: StrokeGridView
    
    /// Intercepts drawing gestures to be relayed back to the canvas
    private let gestureView: GestureView
    
    /// The layer currently being manipulated in the canvas
    private var currentLayerView: UIImageView {
        layerViews[layerSelection]
    }
    
    private let fileSizeLabel = UIImageView()

    // Palette
    private let paletteContainerView = UIView(frame: .zero)
    private var paletteViewController: PaletteViewController!

    // Top buttons
    private var undoButton: UIBarButtonItem!
    private var redoButton: UIBarButtonItem!
    
    // Bottom buttons
    private let buttonStack = UIStackView()
    
    private let pencilButton         = UIButton(image: DrawingTool.pencil.image, target: self, selector: #selector(toggleTool))
    private let lineButton           = UIButton(image: DrawingTool.line.image, target: self, selector: #selector(toggleTool))
    private let selectionButton      = UIButton(image: DrawingTool.selection.image, target: self, selector: #selector(toggleTool))
    private let rectangleButton      = UIButton(image: DrawingTool.rectangle.image, target: self, selector: #selector(toggleTool))
    private let rectangleFillButton  = UIButton(image: DrawingTool.rectangleFill.image, target: self, selector: #selector(toggleTool))
    private let circleButton         = UIButton(image: DrawingTool.circle.image, target: self, selector: #selector(toggleTool))
    private let fillButton           = UIButton(image: DrawingTool.fill.image, target: self, selector: #selector(toggleTool))

    // State
    private var isSelecting = false
    private var lastDragIndex = 0
    private var dragIndexes: [Int] = []
    private var eyeImage = UIImage(systemName: "eye.slash")
    
    private var onionImage: UIImage? = nil {
        didSet {
            onionView.image = onionImage
        }
    }
    
    private var showGrid = true {
        didSet {
            gridView.isHidden.toggle()
            updateBarButtons()
        }
    }
    
    private var invertGrid = false {
        didSet {
            gridView.strokeColor = gridView.strokeColor == .label ? .systemBackground : .label
            if showGrid == false {
                showGrid = true
                return
            }
            updateBarButtons()
        }
    }
    
    private var layerSelection = 0

    private var strokeColor: Color = .black
    private var temporaryColorSelection: UIColor? = nil
    
    private var selectedTool: DrawingTool = .none
    
    /// The bitmap layer currently being edited
    private var selectedBitmap: Bitmap {
        bitmaps[layerSelection]
    }
    
    private var bitmaps: [Bitmap]
    
    private var project: Project
    
    private var width: Int {
        selectedBitmap.width
    }

    private var height: Int {
        selectedBitmap.height
    }
    
    /// A temporary bitmap that is modified during gestures. When a gesture completes, the bitmap is updated and the preview bitmap is reset
    private var previewBitmap: Bitmap? = nil {
        didSet {
            if let bitmap = previewBitmap {
                currentLayerView.image = UIImage(bitmap: bitmap)
            }
        }
    }
    
    private var selectionArea: Bitmap? = nil
    
    init(project: Project, bitmaps: [Bitmap]) {
        self.project = project
        self.bitmaps = bitmaps.sorted { $0.zIndex < $1.zIndex }
        self.layerSelection = max(0, bitmaps.count - 1)
//        self.selectedBitmap = bitmaps[layerSelection]
        
        let width = Int(project.width)
        let height = Int(project.height)
        
        gridView = StrokeGridView(width: width, height: height)
        gridView.backgroundColor = .clear
        gestureView = GestureView(width: width, height: height, frame: .zero)
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = ""
        self.navigationItem.title = ""
        
        fileSizeLabel.contentMode = .center
        fileSizeLabel.backgroundColor = .clear
        fileSizeLabel.layer.magnificationFilter = .nearest
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
                
        let transparencyBitmap = Bitmap.transparencyIndicator(of: width, height: height)
        transparencyView.image = UIImage(bitmap: transparencyBitmap)
        transparencyView.layer.magnificationFilter = .nearest
        var palette = selectedBitmap.palette.sorted(by: { $1.darkLevel > $0.darkLevel })
        if palette.count == 0 || palette.count == 1 {
            palette = [.black, .gray, .white, .red, .orange, .yellow, .blue, .green, .magenta]
        }
        paletteViewController = PaletteViewController(palette: palette.sorted(by: { $1.darkLevel > $0.darkLevel }))
        
        undoButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.left.circle"), style: .plain, target: self, action: #selector(undoButtonPressed))
        redoButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.forward.circle"), style: .plain, target: self, action: #selector(redoButtonPressed))
        undoButton.isEnabled = false
        redoButton.isEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Applies shared properties for all image views
    private func configureImageView(_ imageView: UIImageView) {
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.magnificationFilter = .nearest
        imageView.layer.borderColor = UIColor.label.cgColor
        imageView.layer.borderWidth = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.addSubview(scrollview)
        view.addSubview(fileSizeLabel)
        view.addSubview(buttonStack)
        scrollview.addSubview(containerView)

        scrollview.delegate = self
        scrollview.minimumZoomScale = 1.0
        scrollview.maximumZoomScale = CGFloat(width / 4)
        scrollview.bounces = false

        onionView.alpha = 0.5

        buttonHeirarchy.enumerated().forEach {
            $0.element.tag = $0.offset
            buttonStack.addArrangedSubview($0.element)
        }
        
        layerViewHeirarchy.forEach {
            containerView.addSubview($0)
        }
                
        buttonStack.distribution = .equalCentering
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        gestureView.delegate = self
        
        addPaletteViewController()
        
        fileSizeLabel.tintColor = .red
        updateSizeLabel()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        updateBarButtons()
    }
    
    override func viewWillLayoutSubviews() {
        scrollview.translatesAutoresizingMaskIntoConstraints = false

        var canvasWidth = layoutGuide.layoutFrame.maxX - layoutGuide.layoutFrame.minX
        var canvasHeight = canvasWidth
        let pixelWidth = canvasWidth / CGFloat(selectedBitmap.width)
        let pixelHeight = canvasHeight / CGFloat(selectedBitmap.height)

        let difference = abs(selectedBitmap.width - selectedBitmap.height)

        if selectedBitmap.width > selectedBitmap.height {
            canvasHeight = canvasHeight - (CGFloat(difference) * pixelWidth)
        } else if selectedBitmap.height > selectedBitmap.width {
            canvasWidth = canvasWidth - (CGFloat(difference) * pixelHeight)
        }

        NSLayoutConstraint.activate([
            buttonStack.heightAnchor.constraint(equalToConstant: 48),
            buttonStack.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor),
            
            paletteContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            paletteContainerView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            paletteContainerView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            paletteContainerView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -4),
            
            scrollview.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            scrollview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollview.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -4),
            
            fileSizeLabel.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: 4),
            fileSizeLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            fileSizeLabel.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        containerView.frame = scrollview.bounds
        
        containerView.subviews.forEach {
            $0.frame = CGRect(x: (view.frame.width - canvasWidth) * 0.5,
                              y: (scrollview.frame.height - canvasHeight) * 0.5,
                              width: canvasWidth,
                              height: canvasHeight)
        }
        
        drawLayerViews()
    }
    
    func drawLayerViews() {
        layerContainerView.subviews.forEach { $0.removeFromSuperview() }
        
//        layerViews = project.layers
//            .sorted(by: { $0.zIndex > $1.zIndex })
//            .map { bitmap in
//                UIImageView(image: UIImage(bitmap: bitmap))
//        }
//
//        layerViews.enumerated().forEach { index, view in
//            view.isHidden = project.layers[index].isHidden
//        }
        
        layerViews = bitmaps
            .sorted(by: { $0.zIndex < $1.zIndex })
            .map { bitmap in
                UIImageView(image: UIImage(bitmap: bitmap))
        }
        
        layerViews.enumerated().forEach { index, view in
            view.isHidden = bitmaps[index].isHidden
        }

        layerViews.forEach(configureImageView)
        
        layerViews.forEach(layerContainerView.addSubview)

        layerContainerView.subviews.forEach {
            $0.frame = layerContainerView.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        didSelectColor(strokeColor)
        drawLayerViews()
    }
    
    private func save() {
        CoreDataStorage.save(bitmap: selectedBitmap)
    }
    
    private func reload() {
        if let project = CoreDataStorage.load(project: project.id) {
            self.project = project
        } else {
            print("failed to load project \(project.id)")
        }
        self.bitmaps = CoreDataStorage.loadAllBitmaps(project: project.id).sorted { $0.zIndex < $1.zIndex }
        for bitmap in bitmaps {
            print("loaded bitmap \(bitmap.id)")
        }
        previewBitmap = selectedBitmap
    }
    
    private func updateBarButtons() {
        navigationItem.rightBarButtonItems = [extrasButton, layerButton, redoButton, undoButton]
    }
    
    private func updateLayerViews() {
        self.layerViews = project.layers.reversed().map {
            UIImageView(image: UIImage(bitmap: $0))
        }
    }
    
    func updateSizeLabel() {
        let stringData = Data(selectedBitmap.svg.utf8)
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .memory
        let string = bcf.string(fromByteCount: Int64(stringData.count))
        let filesizeCases = fiveSeven.stringToCases(string)
            .flatMap { [$0, .space] } + [.space, .k]
        let fileSize = filesizeCases
            .map { $0.bitmap }
            .reduce(.initial) { stitch($0, to: $1) }
        
        fileSizeLabel.image = UIImage(bitmap: fileSize)?.withTintColor(.red)
    }
}

// MARK - Layout
private extension CanvasViewController {

    var layerViewHeirarchy: [UIView] {
        [transparencyView,
         layerContainerView,
         onionView,
         gridView,
         gestureView]
    }
    
    var buttonHeirarchy: [UIButton] {
        [pencilButton,
         lineButton,
         rectangleButton,
         rectangleFillButton,
         circleButton,
         fillButton,
         selectionButton]
    }
        
    var layoutGuide: UILayoutGuide {
        view.layoutMarginsGuide
    }

    func addPaletteViewController() {
        paletteContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paletteContainerView)
        
        paletteViewController.view.frame = paletteContainerView.frame
        paletteViewController.delegate = self
        paletteContainerView.addSubview(paletteViewController.view)
        paletteViewController.view.clipsToBounds = true
        paletteViewController.willMove(toParent: self)
        addChild(paletteViewController)
        paletteViewController.didMove(toParent: self)
    }
}

extension CanvasViewController: PaletteDelegate {
    
    func didSelectColor(_ color: Color) {
        strokeColor = color
    }
    
    func didPressPlusButton() {
        let vc = UIColorPickerViewController()
        vc.delegate = self
        vc.supportsAlpha = false
        navigationController?.present(vc, animated: true)
    }
}

extension CanvasViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        temporaryColorSelection = color
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if let selection = temporaryColorSelection {
            let color = Color(uiColor: selection)
            temporaryColorSelection = nil
        
            if !paletteViewController.palette.contains(color) {
                paletteViewController.palette.append(color)
                paletteViewController.collectionView.reloadData()
            }
        }
    }
}

// Buttons
extension CanvasViewController {
    
    private func exportPng(_ action: UIAction) {
        let image = UIImage(bitmap: selectedBitmap)//.scaled(32))
        if let data = image?.pngData() {
            let activityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = self.view
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.maxX, y: 40, width: 0,height: 0)
            }
            self.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func exportSvg(_ action: UIAction) {
        let stringData = Data(selectedBitmap.svg.utf8)
        let uniqueRandomName = String(UUID().uuidString.suffix(4))
        let svgURL = stringData.toFile(fileName: "\(uniqueRandomName).svg")
        let activityViewController = UIActivityViewController(activityItems: [svgURL], applicationActivities: nil)
      
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.maxX, y: 40, width: 0,height: 0)
        }
        present(activityViewController, animated: true, completion: nil)
    }

//    private func exportCode(_ action: UIAction) {
//        print(bitmap.pixels.map { $0 == .black ? 1 : 0})
//    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    @objc private func toggleTool(_ sender: UIButton) {
        buttonHeirarchy.forEach {
            $0.isSelected = false
        }
        
        switch sender.tag {
        case 0:
            selectedTool = .pencil
            pencilButton.isSelected = true
        case 1:
            selectedTool = .line
            lineButton.isSelected = true
        case 2:
            selectedTool = .rectangle
            rectangleButton.isSelected = true
        case 3:
            selectedTool = .rectangleFill
            rectangleFillButton.isSelected = true
        case 4:
            selectedTool = .circle
            circleButton.isSelected = true
        case 5:
            selectedTool = .fill
            fillButton.isSelected = true
        case 6:
            selectedTool = .selection
            selectionButton.isSelected = true
        default:
            selectedTool = .none
        }
    }
    
    @objc private func gridButtonPressed() {
        eyeImage = eyeImage == UIImage(systemName: "eye.slash") ? UIImage(systemName: "eye") : UIImage(systemName: "eye.slash")
        gridView.isHidden.toggle()
    }
    
    @objc private func undoButtonPressed() {
        if let undoManager = undoManager, undoManager.canUndo {
            undoManager.undo()
            save()
//            Storage.saveBitmap(bitmap, project: project)
            updateSizeLabel()
            layerViews[layerSelection].image = UIImage(bitmap: selectedBitmap)
        }
    }
    
    @objc private func redoButtonPressed() {
        if let undoManager = undoManager, undoManager.canRedo {
            undoManager.redo()
            save()
//            Storage.saveBitmap(bitmap, project: project)
            updateSizeLabel()
            layerViews[layerSelection].image = UIImage(bitmap: selectedBitmap)
        }
    }
}

// Menus
extension CanvasViewController {
    
    private var extrasButton: UIBarButtonItem {
        UIBarButtonItem(title: "Extras", image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: extrasMenu)
    }
    
    private var layerButton: UIBarButtonItem {
        UIBarButtonItem(image: UIImage(systemName: "square.stack.3d.up"), style: .plain, target: self, action: #selector(layerButtonPressed))
    }
    
    private var layerButton2: UIButton {
        UIButton(image: UIImage(systemName: "square.stack.3d.up"), target: self, selector: #selector(layerButtonPressed))
    }
            
    private var extrasMenu: UIMenu {
        UIMenu(title: "", children: [gridMenu, previewMenu, exportMenu])
    }
    
    private var gridMenu: UIMenu {
        UIMenu(title: "Grid Settings", image: UIImage(systemName: "grid"/*"squareshape.split.3x3"*/), options: .displayInline, children: [showGridAction, invertGridAction])
    }
    
    private var showGridAction: UIAction {
        UIAction(title: "Show grid", image: UIImage(systemName: "eye"), state: showGrid ? .on : .off) { _ in
            self.showGrid.toggle()
        }
    }
    
    private var invertGridAction: UIAction {
        UIAction(title: "Invert grid", image: UIImage(systemName: invertGrid ? "circle.lefthalf.fill" : "circle.righthalf.fill"), state: invertGrid ? .on : .off) { _ in
            self.invertGrid.toggle()
        }
    }

    private var previewMenu: UIMenu {
        let importDrawing = UIAction(title: "Import drawing", image: UIImage(systemName: "square.on.circle"), handler: { _ in
            let vc = BitmapsCollectionViewController()
            vc.didSelect = { bitmap in
                self.onionImage = UIImage(bitmap: bitmap)
                vc.dismiss(animated: true, completion: nil)
                self.updateBarButtons()
            }
            self.present(vc, animated: true)
        })
        let importPhoto = UIAction(title: "Import photo", image: UIImage(systemName: "photo.on.rectangle"), handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                self.present(imagePicker, animated: true)
            } else {
                print("???")
            }
        })
        let removeOnion = UIAction(title: "Remove preview layer", image: UIImage(systemName: "trash"), handler: { _ in
            self.onionView.image = nil
            self.updateBarButtons()
        })
        let actions = onionView.image == nil ? [importDrawing, importPhoto] : [removeOnion]
        return UIMenu(title: "Preview Layer", image: UIImage(systemName: "rectangle.dashed.and.paperclip"), options: .displayInline, children: actions)
    }
    
    private var exportMenu: UIMenu {
        UIMenu(title: "Export", image: UIImage(systemName: "arrow.up.doc.on.clipboard"), children: [
           UIAction(title: ".png", image: UIImage(systemName: "photo"), handler: exportPng),
           UIAction(title: ".svg",  image: UIImage(systemName: "square.on.circle"), handler: exportSvg),
       ])
    }
    
    @objc private func layerButtonPressed() {
//        let vc = LayerTableViewController(project: project, selectedLayer: layerSelection)
        //        vc.delegate = self
        let vc = LayerViewController(project: project, bitmaps: bitmaps, selection: layerSelection)

        
        let layerLetters: [fiveSeven] = [.l, .a, .y, .e, .r, .s]
        let titleImage = layerLetters
            .flatMap { [fiveSeven.space.bitmap, $0.bitmap] } // Interleave characters with spaces
            .reduce(.initial) { stitch($0, to: $1) } // Assemble from left to right
            .scaled(2)
        
        let imageView = UIImageView(image: UIImage(bitmap: titleImage)?.withTintColor(UIColor.label))
        imageView.contentMode = .center
        imageView.layer.magnificationFilter = .nearest
        vc.navigationItem.titleView = imageView
//        navigationController?.pushViewController(vc, animated: true)
        let nav = UINavigationController(rootViewController: vc)
        navigationController?.present(nav, animated: true)
    }
}

extension CanvasViewController: LayerViewControllerDelegate {

    func didAddLayer() {
        reload()
        drawLayerViews()
    }

    func didSelect(index: Int) {
        layerSelection = index
        reload()
        drawLayerViews()
    }
}

extension CanvasViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }

        onionView.image = image
        onionView.layer.magnificationFilter = .nearest
        picker.dismiss(animated: true)
        self.updateBarButtons()
    }
}

// MARK - Gestures
extension CanvasViewController: GestureViewDelegate {
    
    func bitmapDidChange(from oldBitmap: Bitmap) {
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            let currentBitmap = targetSelf.selectedBitmap
            targetSelf.bitmaps[self.layerSelection] = oldBitmap
            targetSelf.bitmapDidChange(from: currentBitmap)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.undoButton.isEnabled = self?.undoManager?.canUndo ?? false
            self?.redoButton.isEnabled = self?.undoManager?.canRedo ?? false
        }
    }
    
    func updateLayer(at indexes: [Int]) {
        guard let previewBitmap = previewBitmap, indexes.isNotEmpty else { return }
//        let oldBitmap = bitmap
        let oldBitmap = selectedBitmap
        bitmaps[layerSelection] = previewBitmap
        layerViews[layerSelection].image = UIImage(bitmap: selectedBitmap)
        bitmapDidChange(from: oldBitmap)
        Storage.saveBitmap(selectedBitmap, project: project)
    }
    
    func didTap(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .fill:
            indexes = fill(with: strokeColor, at: index, in: selectedBitmap)
        case .none, .move:
//            previewView.layer.sublayers?.removeAll()
            return
        default:
            indexes = [index]
        }
        if indexes.isNotEmpty {
            updateLayer(at: indexes)
        }
    }

    func didBeginDragging(at index: Int) {
        let strokeColor = strokeColor

        let indexes: [Int]
        switch selectedTool {
        case .move:
//            previewView.layer.sublayers?.removeAll()
            var previewBitmap = Bitmap(width: selectedBitmap.width, pixels: Array(repeating: Color.clear, count: selectedBitmap.pixels.count))
            if let selectionArea = selectionArea {
                let x = (index % width) - (selectionArea.width / 2)
                let y = (index / width) - (selectionArea.height / 2)
                previewBitmap = previewBitmap.insert(newBitmap: selectionArea, at: x, y: y)
            }
//            previewView.image = UIImage(bitmap: previewBitmap)
            // TODO
            return
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: selectedBitmap.width)
        case .circle:
            return
        case .selection:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
            drawSelection(around: indexes, width: width)
            lastDragIndex = index
            return
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
        case .rectangleFill:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
        case .pencil:
            dragIndexes = [index]
            indexes = dragIndexes
        case .fill:
            indexes = fill(with: strokeColor, at: index, in: selectedBitmap)
            previewBitmap = selectedBitmap.withChanges(newColor: strokeColor, at: indexes)
            updateLayer(at: indexes)
            return
        case .none:
//            previewView.layer.sublayers?.removeAll()
            return
        }
    
        previewBitmap = selectedBitmap.withChanges(newColor: strokeColor, at: selectedTool == .pencil ? dragIndexes : indexes)
        lastDragIndex = index
    }

    func isDragging(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .move:
            var previewBitmap = Bitmap(width: selectedBitmap.width, pixels: Array(repeating: Color.clear, count: selectedBitmap.pixels.count))
            if let selectionArea = selectionArea {
                let x = (index % selectedBitmap.width) - (selectionArea.width / 2)
                let y = (index / selectedBitmap.width) - (selectionArea.height / 2)
                
//                bitmap = bitmap.insert(newBitmap: selectionArea, at: x, y: y)
                previewBitmap = previewBitmap.insert(newBitmap: selectionArea, at: x, y: y)
            }
//            previewView.image = UIImage(bitmap: previewBitmap)
            return
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: selectedBitmap.width)
        case .circle:
            indexes = drawOval(at: gestureView.touchDownIndex, to: index, in: selectedBitmap)
        case .selection:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
            drawSelection(around: indexes, width: selectedBitmap.width)
            lastDragIndex = index
            return
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
        case .rectangleFill:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
        case .pencil:
            indexes = lineIndexSet(firstIndex: lastDragIndex, secondIndex: index, arrayWidth: selectedBitmap.width)
            dragIndexes.append(contentsOf: indexes)
        case .fill:
            return
        case .none:
            return
        }

        previewBitmap = selectedBitmap.withChanges(newColor: strokeColor, at: selectedTool == .pencil ? dragIndexes : indexes)
        lastDragIndex = index
    }

    func didEndDragging(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .move:
//            var previewBitmap = Bitmap(width: bitmap.width, pixels: Array(repeating: Color.clear, count: bitmap.pixels.count))
            if let selectionArea = selectionArea {
                let oldBitmap = selectedBitmap
                
                let x = (index % selectedBitmap.width) - (selectionArea.width / 2)
                let y = (index / selectedBitmap.width) - (selectionArea.height / 2)
                
//                selectedBitmap = selectedBitmap.insert(newBitmap: selectionArea, at: x, y: y)
                bitmaps[layerSelection] = selectedBitmap.insert(newBitmap: selectionArea, at: x, y: y)
                bitmapDidChange(from: oldBitmap)
                save()
//                Storage.saveBitmap(selectedBitmap, project: project)
            }
            selectedTool = .none
//            previewView.image = UIImage()
            // TODO
            return
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: selectedBitmap.width)
        case .circle:
            indexes = drawOval(at: gestureView.touchDownIndex, to: index, in: selectedBitmap)
        case .selection:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
            lastDragIndex = index
            drawSelection(around: indexes, width: selectedBitmap.width)
            selectedTool = .move
            let selectionWidth = horizontalDistance(from: gestureView.touchDownIndex, to: index, width: selectedBitmap.width)
            selectionArea = Bitmap(width: selectionWidth + 1, zIndex: 0, pixels: indexes.map { selectedBitmap.pixels[$0] })
//            previewView.image = UIImage(bitmap: selection)
            return
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
        case .rectangleFill:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: selectedBitmap.width)
        case .pencil:
            dragIndexes.append(index)
            indexes = dragIndexes
        case .fill:
            return
        case .none:
            return
        }
        lastDragIndex = index
//        bitmap = previewBitmap.withChanges(newColor: strokeColor, at: indexes)
//        currentLayerView.image = UIImage(bitmap: bitmap)
        
        previewBitmap = selectedBitmap.withChanges(newColor: strokeColor, at: selectedTool == .pencil ? dragIndexes : indexes)

//        previewBitmap = nil
        if selectedTool != .selection {
            updateLayer(at: indexes)
            previewBitmap = nil
//            previewView.image = UIImage()
        }
        updateSizeLabel()
    }
    
    func drawSelection(around indexes: [Int], width: Int) {
//        previewView.layer.removeAllAnimations()
        // TODO
//        previewView.layer.sublayers?.removeAll()

        let width = horizontalDistance(from: gestureView.touchDownIndex, to: lastDragIndex, width: selectedBitmap.width) + 1
        let height = verticalDistance(from: gestureView.touchDownIndex, to: lastDragIndex, width: selectedBitmap.width) + 1

        var canvasWidth = layoutGuide.layoutFrame.maxX - layoutGuide.layoutFrame.minX
        var canvasHeight = canvasWidth
        let pixelWidth = canvasWidth / CGFloat(selectedBitmap.width)
        let pixelHeight = canvasHeight / CGFloat(selectedBitmap.height)
        
        let sorted = indexes.sorted()
        let first = sorted.first ?? 0
        let x = CGFloat(first % selectedBitmap.width) * pixelWidth
        let y = CGFloat(first / selectedBitmap.width) * pixelWidth
        
        let layer = CAShapeLayer()
        let bounds = CGRect(x: x, y: y,
                            width: pixelWidth * CGFloat(width),
                            height: pixelWidth * CGFloat(height))
        layer.path = UIBezierPath(rect: bounds).cgPath
        layer.strokeColor = UIColor.green.cgColor
        layer.fillColor = nil
        layer.lineDashPattern = [8, 6]
//        previewView.layer.addSublayer(layer)
        
        let animation = CABasicAnimation(keyPath: "lineDashPattern")
        animation.fromValue = 0
        animation.toValue = layer.lineDashPattern?.reduce(0) { $0 - $1.intValue } ?? 0
        animation.duration = 1
        animation.repeatCount = .infinity
        DispatchQueue.main.async {
//            self.previewView.layer.add(animation, forKey: "line")
        }
    }
}

extension CanvasViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        containerView
    }
}

enum Direction {
    case up, down, left, right
}

enum DrawingTool {
    case pencil, line, selection, rectangle, rectangleFill, circle, fill, none, move // move is not user selectable, but a selection state
}

extension DrawingTool {
    
    var image: UIImage? {
        let systemName: String
        switch self {
        case .pencil:
            systemName = "paintbrush.pointed"
        case .line:
            systemName = "line.diagonal"
        case .selection:
            systemName = "cursorarrow.and.square.on.square.dashed"
        case .rectangle:
            systemName = "rectangle"
        case .rectangleFill:
            systemName = "rectangle.inset.fill"
        case .circle:
            systemName = "circle"
        case .fill:
            systemName = "drop"
        case .none:
            systemName = "cursor"
        case .move:
            systemName = "cursor"
        }
        return UIImage(systemName: systemName)
    }
}
