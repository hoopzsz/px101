//
//  CanvasViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-10.
//

import UIKit

final class CanvasViewController: UIViewController, UINavigationControllerDelegate {
    
    private let scrollview = UIScrollView()
    private let canvasView = UIView()
    
    // Layer views
    private let transparencyView = UIImageView()
    private let bitmapView = UIImageView()
    private let previewView = UIImageView()
    private let onionView = UIImageView()

    private let gridView: StrokeGridView
    private let gestureView: GestureView
    
    private let fileSizeLabel = UIImageView()

    // Palette
    private let paletteContainerView = UIView(frame: .zero)
    private var paletteViewController: PaletteViewController!

    // Top buttons
    private var undoButton: UIBarButtonItem!
    private var redoButton: UIBarButtonItem!
    
    // Bottom buttons
    private let buttonStack = UIStackView()
    private let pencilButton = UIButton(type: .system)
    private let lineButton = UIButton(type: .system)
    
    private let selectionButton = UIButton(type: .system)
    
    private let rectangleButton = UIButton(type: .system)
    private let rectangleFillButton = UIButton(type: .system)

    private let circleButton = UIButton(type: .system)
    private let fillButton = UIButton(type: .system)
    private let gridButton = UIButton(type: .system)
    private let paletteButton = UIButton(type: .system)

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
    
    private var strokeColor: Color = .black
    private var temporaryColorSelection: UIColor? = nil
    
    private var selectedTool: DrawingTool = .pencil {
        didSet {
            updateButtonStates()
        }
    }
    
    private var bitmap: Bitmap {
        didSet {
            bitmapView.image = UIImage(bitmap: bitmap)
        }
    }
    
    private var selectionArea: Bitmap? = nil
    
    init(bitmap: Bitmap) {
        self.bitmap = bitmap
        [transparencyView, bitmapView, previewView, onionView].forEach { bitmapView in
            bitmapView.backgroundColor = .clear
            bitmapView.contentMode = .scaleAspectFit
            bitmapView.layer.magnificationFilter = .nearest
            bitmapView.layer.magnificationFilter = .nearest
        }
        
        fileSizeLabel.contentMode = .center
        fileSizeLabel.backgroundColor = .clear
        fileSizeLabel.layer.magnificationFilter = .nearest
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
                
        let transparencyBitmap = Bitmap.transparencyIndicator(of: bitmap.width, height: bitmap.height)
        transparencyView.image = UIImage(bitmap: transparencyBitmap)
        
        gridView = StrokeGridView(width: bitmap.width, height: bitmap.height)
        gridView.backgroundColor = .clear
        gridView.isUserInteractionEnabled = false
        gestureView = GestureView(width: bitmap.width, height: bitmap.height, frame: .zero)
        var palette = bitmap.palette//.sorted(by: { $1.darkLevel > $0.darkLevel }
        if palette.count == 1, palette[0] == .clear {
            palette = [.black, .gray, .white, .red, .orange, .yellow, .blue, .green, .magenta]
        }
        paletteViewController = PaletteViewController(palette: palette.sorted(by: { $1.darkLevel > $0.darkLevel }))

        super.init(nibName: nil, bundle: nil)
        self.title = ""
        self.navigationItem.title = ""
        undoButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.left.circle"), style: .plain, target: self, action: #selector(undoButtonPressed))
        redoButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.forward.circle"), style: .plain, target: self, action: #selector(redoButtonPressed))
        undoButton.isEnabled = false
        redoButton.isEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.addSubview(transparencyView)
        view.addSubview(scrollview)
        view.addSubview(fileSizeLabel)
        scrollview.delegate = self
        scrollview.showsVerticalScrollIndicator = true
        scrollview.flashScrollIndicators()

        scrollview.minimumZoomScale = 1.0
        scrollview.maximumZoomScale = CGFloat(bitmap.width / 4)
        scrollview.bounces = false
        
        onionView.alpha = 0.5

        bitmapView.clipsToBounds = false
        
        bitmapView.image = UIImage(bitmap: bitmap)

        scrollview.addSubview(canvasView)
        layerViewHeirarchy
            .forEach(canvasView.addSubview)
        
        buttonHeirarchy
            .forEach(buttonStack.addArrangedSubview)
        
        configureButtons()
        
        buttonStack.distribution = .equalCentering
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        gestureView.delegate = self
        
        addPaletteViewController()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        bitmapView.layer.borderWidth = 1
        bitmapView.layer.borderColor = UIColor.label.cgColor
        
        fileSizeLabel.tintColor = .red
        updateSizeLabel()
        
//        self.popoverPresentationController?.sourceView = self.view
    }
    
    override func viewWillLayoutSubviews() {
        scrollview.translatesAutoresizingMaskIntoConstraints = false

        var canvasWidth = layoutGuide.layoutFrame.maxX - layoutGuide.layoutFrame.minX
        var canvasHeight = canvasWidth
        let pixelWidth = canvasWidth / CGFloat(bitmap.width)
        let pixelHeight = canvasHeight / CGFloat(bitmap.height)

        let difference = abs(bitmap.width - bitmap.height)

        if bitmap.width > bitmap.height {
            canvasHeight = canvasHeight - (CGFloat(difference) * pixelWidth)
        } else if bitmap.height > bitmap.width {
            canvasWidth = canvasWidth - (CGFloat(difference) * pixelHeight)
        }

        NSLayoutConstraint.activate([
            paletteContainerView.heightAnchor.constraint(equalToConstant: 48),
            paletteContainerView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            paletteContainerView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            paletteContainerView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor),
            
            buttonStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            buttonStack.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            buttonStack.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            buttonStack.bottomAnchor.constraint(equalTo: paletteContainerView.topAnchor, constant: -4),
            
            scrollview.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            scrollview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollview.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -4),
            
            fileSizeLabel.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: 4),
            fileSizeLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            fileSizeLabel.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        canvasView.frame = scrollview.bounds
        
        canvasView.subviews.forEach {
            $0.frame = CGRect(x: (view.frame.width - canvasWidth) * 0.5,
                              y: (scrollview.frame.height - canvasHeight) * 0.5,
                              width: canvasWidth,
                              height: canvasHeight)
        }
        
        updateBarButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        didSelectColor(strokeColor)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        Storage().saveBitmap(bitmap)
    }
    
    private func updateBarButtons() {
        navigationItem.rightBarButtonItems = [layersButton, extrasButton, redoButton, undoButton]
    }
    
    func updateSizeLabel() {
        let stringData = Data(bitmap.svg.utf8)
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
extension CanvasViewController {

    private var layerViewHeirarchy: [UIView] {
        [transparencyView,
         bitmapView,
         onionView,
         previewView,
         gridView,
         gestureView]
    }
    
    private var buttonHeirarchy: [UIButton] {
        [selectionButton,
         pencilButton,
         lineButton,
         rectangleButton,
         rectangleFillButton,
         circleButton,
         fillButton]
    }
        
    private var layoutGuide: UILayoutGuide {
        view.layoutMarginsGuide
    }
}

// Palette
extension CanvasViewController: ColorSelectionDelegate {
    
    private func addPaletteViewController() {
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
    
    func didChangeColors(_ strokeColor: UIColor, _ fillColor: UIColor) {
//        self.strokeColor = Color(uiColor: strokeColor)
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

    private func configureButtons() {
        let pencilImage = UIImage(systemName: "paintbrush.pointed")
        pencilButton.setImage(pencilImage, for: .normal)
        pencilButton.addTarget(self, action: #selector(togglePencil), for: .touchUpInside)
        pencilButton.isSelected = true
        
        let lineImage = UIImage(systemName: "line.diagonal")
        lineButton.setImage(lineImage, for: .normal)
        lineButton.addTarget(self, action: #selector(toggleLine), for: .touchUpInside)

        let selectionImage = UIImage(systemName: "cursorarrow.and.square.on.square.dashed")
        selectionButton.setImage(selectionImage, for: .normal)
        selectionButton.addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
        
        let rectangleButtonImage = UIImage(systemName: "rectangle")
        rectangleButton.setImage(rectangleButtonImage, for: .normal)
        rectangleButton.addTarget(self, action: #selector(toggleRectangle), for: .touchUpInside)

        let rectangleFillButtonImage = UIImage(systemName: "rectangle.inset.fill")
        rectangleFillButton.setImage(rectangleFillButtonImage, for: .normal)
        rectangleFillButton.addTarget(self, action: #selector(toggleRectangleFill), for: .touchUpInside)
        
//        let a = UIAction(title: "", image: UIImage(systemName: "rectangle"), state: selectedTool == .rectangle ? .on : .off) { _ in
//            self.toggleRectangle()
//        }
//
//        let b = UIAction(title: "", image: UIImage(systemName: "rectangle.fill"), state: selectedTool == .rectangle ? .off : .on) { _ in
////            self.toggleRectangle()
//            print("rect fill")
//        }
//        rectangleButton.menu = UIMenu(title: "", options: UIMenu.Options.displayInline, children: [
//            a, b
//        ])
        
//        let interaction = UIContextMenuInteraction(delegate: self)
//        rectangleButton.addInteraction(interaction)
        
//        rectangleButton.context
//        rectangleButton.addTarget(self, action: #selector(toggleRectangleMenu), for: .)

        let circleButtonImage = UIImage(systemName: "circle")
        circleButton.setImage(circleButtonImage, for: .normal)
        circleButton.addTarget(self, action: #selector(toggleCircle), for: .touchUpInside)
        
        let fillButtonImage = UIImage(systemName: "drop")
        fillButton.setImage(fillButtonImage, for: .normal)
        fillButton.addTarget(self, action: #selector(toggleFill), for: .touchUpInside)

    }
    
    private func exportPng(_ action: UIAction) {
        let image = UIImage(bitmap: bitmap)//.scaled(32))
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
        let stringData = Data(bitmap.svg.utf8)
        let uniqueRandomName = String(UUID().uuidString.suffix(4))
        let svgURL = stringData.toFile(fileName: "\(uniqueRandomName).svg")
        let activityViewController = UIActivityViewController(activityItems: [svgURL], applicationActivities: nil)
      
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.maxX, y: 40, width: 0,height: 0)
        }
        present(activityViewController, animated: true, completion: nil)
    }

    private func exportCode(_ action: UIAction) {
        print(bitmap.pixels.map { $0 == .black ? 1 : 0})
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func updateButtonStates() {
        [pencilButton, lineButton, selectionButton, rectangleButton, rectangleFillButton, circleButton, fillButton].forEach {
            $0.isSelected = false
        }

        switch selectedTool {
        case .pencil:
            pencilButton.isSelected = true
        case .line:
            lineButton.isSelected = true
        case .selection:
            selectionButton.isSelected = true
        case .rectangle:
            rectangleButton.isSelected = true
        case .rectangleFill:
            rectangleFillButton.isSelected = true
        case .circle:
            circleButton.isSelected = true
        case .fill:
            fillButton.isSelected = true
        case .none, .move:
            break
        }
        
//        canvasView.isUserInteractionEnabled = selectedTool != .none
    }
    
    @objc private func togglePencil() {
        if selectedTool == .pencil {
            selectedTool = .none
            return
        }
        selectedTool = .pencil
    }
    
    @objc private func toggleLine() {
        if selectedTool == .line {
            selectedTool = .none
            return
        }
        selectedTool = .line
    }
    
    @objc private func toggleSelection() {
        if selectedTool == .selection {
            selectedTool = .none
            return
        }
        selectedTool = .selection
    }
    
    @objc private func toggleRectangle() {
        if selectedTool == .rectangle {
            selectedTool = .none
            return
        }
        selectedTool = .rectangle
    }
    
    @objc private func toggleRectangleFill() {
        if selectedTool == .rectangleFill {
            selectedTool = .none
            return
        }
        selectedTool = .rectangleFill
    }
    
    @objc private func toggleCircle() {
        if selectedTool == .circle {
            selectedTool = .none
            return
        }
        selectedTool = .circle
    }
    
    @objc private func toggleFill() {
        if selectedTool == .fill {
            selectedTool = .none
            return
        }
        selectedTool = .fill
    }
    
    @objc private func gridButtonPressed() {
        eyeImage = eyeImage == UIImage(systemName: "eye.slash") ? UIImage(systemName: "eye") : UIImage(systemName: "eye.slash")
        gridView.isHidden.toggle()
    }
    
    @objc private func undoButtonPressed() {
        if let undoManager = undoManager, undoManager.canUndo {
            undoManager.undo()
            Storage().saveBitmap(bitmap)
            updateSizeLabel()
        }
    }
    
    @objc private func redoButtonPressed() {
        if let undoManager = undoManager, undoManager.canRedo {
            undoManager.redo()
            Storage().saveBitmap(bitmap)
            updateSizeLabel()
        }
    }
}

// Menus
extension CanvasViewController {
    
    private var extrasButton: UIBarButtonItem {
        UIBarButtonItem(title: "Extras", image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: extrasMenu)
    }
    
    private var layersButton: UIBarButtonItem {
//        UIBarButtonItem(title: "Layers", image: UIImage(systemName: "square.stack.3d.up"), primaryAction: nil, menu: extrasMenu)
        UIBarButtonItem(image: UIImage(systemName: "square.stack.3d.up"), style: .plain, target: self, action: #selector(layersButtonPressed))
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
    
    @objc private func layersButtonPressed() {
        let vc = BitmapsCollectionViewController()
        vc.didSelect = { bitmap in
            self.bitmap = bitmap
            vc.dismiss(animated: true)
        }
        navigationController?.present(vc, animated: true)
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
            let currentBitmap = targetSelf.bitmap
            targetSelf.bitmap = oldBitmap
            targetSelf.bitmapDidChange(from: currentBitmap)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.undoButton.isEnabled = self?.undoManager?.canUndo ?? false
            self?.redoButton.isEnabled = self?.undoManager?.canRedo ?? false
        }
    }
    
    func updateLayer(at indexes: [Int]) {
        guard indexes.isNotEmpty else { return }
        let oldBitmap = bitmap
        bitmap.changeColor(strokeColor, at: indexes)
        bitmapDidChange(from: oldBitmap)
        Storage().saveBitmap(bitmap)
    }
    
    func didTap(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .fill:
            indexes = fill(with: strokeColor, at: index, in: bitmap)
        case .none, .move:
            previewView.layer.sublayers?.removeAll()
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
            previewView.layer.sublayers?.removeAll()
            var previewBitmap = Bitmap(width: bitmap.width, pixels: Array(repeating: Color.clear, count: bitmap.pixels.count))
            if let selectionArea = selectionArea {
                let x = (index % bitmap.width) - (selectionArea.width / 2)
                let y = (index / bitmap.width) - (selectionArea.height / 2)
                previewBitmap = previewBitmap.insert(newBitmap: selectionArea, at: x, y: y)
            }
            previewView.image = UIImage(bitmap: previewBitmap)
            return
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: bitmap.width)
        case .circle:
            return
        case .selection:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
            drawSelection(around: indexes, width: bitmap.width)
            lastDragIndex = index
            return
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .rectangleFill:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .pencil:
            dragIndexes = [index]
            indexes = dragIndexes
        case .fill:
            indexes = fill(with: strokeColor, at: index, in: bitmap)
            updateLayer(at: indexes)
            return
        case .none:
//            previewView.layer.sublayers?.removeAll()
            return
        }
        
        previewView.image = UIImage(bitmap: bitmap.withChanges(newColor: strokeColor, at: indexes))
        
        lastDragIndex = index
    }

    func isDragging(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .move:
            var previewBitmap = Bitmap(width: bitmap.width, pixels: Array(repeating: Color.clear, count: bitmap.pixels.count))
            if let selectionArea = selectionArea {
                let x = (index % bitmap.width) - (selectionArea.width / 2)
                let y = (index / bitmap.width) - (selectionArea.height / 2)
                
//                bitmap = bitmap.insert(newBitmap: selectionArea, at: x, y: y)
                previewBitmap = previewBitmap.insert(newBitmap: selectionArea, at: x, y: y)
            }
            previewView.image = UIImage(bitmap: previewBitmap)
            return
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: bitmap.width)
        case .circle:
            indexes = drawCircle(at: gestureView.touchDownIndex, to: index, in: bitmap)
        case .selection:
//            strokeColor = Color(r: 255, g: 255, b: 255, a: 128)
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
            drawSelection(around: indexes, width: bitmap.width)
            lastDragIndex = index
            return
//            let sectionWidth = horizontalDistance(from: gestureView.touchDownIndex, to: index, width: bitmap.width)
//            print(sectionWidth)
//            let section = Bitmap(width: sectionWidth, pixels: indexes.map { bitmap.pixels[$0] })
//            print(section)
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .rectangleFill:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .pencil:
            indexes = lineIndexSet(firstIndex: lastDragIndex, secondIndex: index, arrayWidth: bitmap.width)
            dragIndexes.append(contentsOf: indexes)
        case .fill:
            return
        case .none:
            return
        }
        previewView.image = UIImage(bitmap: bitmap.withChanges(newColor: strokeColor, at: selectedTool == .pencil ? dragIndexes : indexes))
        
        lastDragIndex = index
    }

    func didEndDragging(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .move:
            var previewBitmap = Bitmap(width: bitmap.width, pixels: Array(repeating: Color.clear, count: bitmap.pixels.count))
            if let selectionArea = selectionArea {
                let oldBitmap = bitmap
                
                let x = (index % bitmap.width) - (selectionArea.width / 2)
                let y = (index / bitmap.width) - (selectionArea.height / 2)
                
                bitmap = bitmap.insert(newBitmap: selectionArea, at: x, y: y)
                bitmapDidChange(from: oldBitmap)
                Storage().saveBitmap(bitmap)
            }
            selectedTool = .none
            previewView.image = UIImage()
            return
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: bitmap.width)
        case .circle:
            indexes = drawCircle(at: gestureView.touchDownIndex, to: index, in: bitmap)
        case .selection:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
            lastDragIndex = index
            drawSelection(around: indexes, width: bitmap.width)
            selectedTool = .move
            let selectionWidth = horizontalDistance(from: gestureView.touchDownIndex, to: index, width: bitmap.width)
            selectionArea = Bitmap(width: selectionWidth + 1, pixels: indexes.map { bitmap.pixels[$0] })
//            previewView.image = UIImage(bitmap: selection)
            return
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .rectangleFill:
            indexes = rectangularFillIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .pencil:
            dragIndexes.append(index)
            indexes = dragIndexes
        case .fill:
            return
        case .none:
            return
        }
        lastDragIndex = index
        if selectedTool != .selection {
            updateLayer(at: indexes)
            previewView.image = UIImage()
        }
        updateSizeLabel()
    }
    
    func drawSelection(around indexes: [Int], width: Int) {
//        previewView.layer.removeAllAnimations()
        previewView.layer.sublayers?.removeAll()

        let width = horizontalDistance(from: gestureView.touchDownIndex, to: lastDragIndex, width: bitmap.width) + 1
        let height = verticalDistance(from: gestureView.touchDownIndex, to: lastDragIndex, width: bitmap.width) + 1

        var canvasWidth = layoutGuide.layoutFrame.maxX - layoutGuide.layoutFrame.minX
        var canvasHeight = canvasWidth
        let pixelWidth = canvasWidth / CGFloat(bitmap.width)
        let pixelHeight = canvasHeight / CGFloat(bitmap.height)
        
        let sorted = indexes.sorted()
        let first = sorted.first ?? 0
        let x = CGFloat(first % bitmap.width) * pixelWidth
        let y = CGFloat(first / bitmap.width) * pixelWidth
        
        let layer = CAShapeLayer()
        let bounds = CGRect(x: x, y: y,
                            width: pixelWidth * CGFloat(width),
                            height: pixelWidth * CGFloat(height))
//        layer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 20, height: 20)).cgPath
        layer.path = UIBezierPath(rect: bounds).cgPath
        layer.strokeColor = UIColor.green.cgColor
        layer.fillColor = nil
        layer.lineDashPattern = [8, 6]
        previewView.layer.addSublayer(layer)

//        previewView.image = img
        
        let animation = CABasicAnimation(keyPath: "lineDashPattern")
        animation.fromValue = 0
        animation.toValue = layer.lineDashPattern?.reduce(0) { $0 - $1.intValue } ?? 0
        animation.duration = 1
        animation.repeatCount = .infinity
        DispatchQueue.main.async {
            self.previewView.layer.add(animation, forKey: "line")
        }
    }
}

extension CanvasViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        canvasView
    }
    
//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        scrollView.setZoomScale(zoomScale, animated: true)
//        let zoomScale = CGFloat(ceil(Double(scale) * 4)) / 4
//        print("scale: \(scale)\nnew: \(zoomScale)")
//        scrollView.zoomScale = zoomScale
//        scrollView.setZoomScale(zoomScale, animated: true)
        
//        let offset = scrollView.contentOffset
//
//
//
//        let w = (scrollView.frame.width / CGFloat(bitmap.width)) * scale
//        var x = w * CGFloat(Int(offset.x / w))
//        var y = w * CGFloat(Int(offset.y / w))
//
//        if offset.x - x > (0.5 * w) {
//            x += w
//        }
//        if offset.y - y > (0.5 * w) {
//            y += w
//        }
//        let z = CGPoint(x: x, y: y)
//
//        print("offset: \(offset)\nw: \(w)\n new: \(z)")
//        scrollView.setContentOffset(z, animated: true)
//
//        let cases = "zoom \(zoomScale)x".flatMap { "\($0)" }.flatMap { [fiveSeven.caseForCharacter($0), fiveSeven.space] }
//        let bitmap = cases.map { $0.bitmap }.reduce(fiveSeven.z.bitmap) { stitch($0, to: $1) }
//        zoomLabel.image = UIImage(bitmap: bitmap)
//        zoomLabel.contentMode = .scaleAspectFit
//        scrollView.setZoomScale(sc÷ale, animated: true)
//        print("\n")
//    }
}
/*
<svg id="mouse-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24">
  <rect class="c00" x="11" y="7"/>
 <style>
   rect{width:1px;height:1px;} #mouse-svg{shape-rendering: crispedges;} .c00{fill:#000000}.c01{fill:#B1ADAC}.c02{fill:#D7D7D7}
 </style>
</svg>
*/

extension Bitmap {
    var svg: String {
        let prefix = "<svg id=\"px101\" xmlns=\"http://www.w3.org/2000/svg\" preserveAspectRatio=\"xMinYMin meet\" viewBox=\"0 0 \(width) \(height)\">"
        /// Count the number of times a color occurs. The most populous color is used for the background. Ideally the user selects this color
        
        let uniqueColors = Set(pixels)
        var bgColor: Color = .white // We will overwrite this
        
        var colorOccuranceDictionary: [Color: Int] = [:]
        uniqueColors.forEach {
            colorOccuranceDictionary[$0] = 0
        }
        for pixel in pixels {
            if let value = colorOccuranceDictionary[pixel] {
                colorOccuranceDictionary[pixel] = value + 1
            }
        }

        if let (color, _) = colorOccuranceDictionary.max(by: {$0.1 < $1.1}) {
            bgColor = color
        }
        
        var colorDictionary: [Color: Int] = [:]
        uniqueColors.enumerated().forEach { index, color in
            colorDictionary[color] = index
        }
        let pixelRects = pixels
            .enumerated()
            .filter { $0.element != bgColor }
            .map { index, color in
                "<rect class=\"c\(colorDictionary[color]!)\" x=\"\(index % width)\" y=\"\(index / height)\"/>"
            }
            .joined()
        
        let bgRect = "<polygon points =\"0,0 0,\(width) \(width),\(height) \(width),0\" fill=\"#\(bgColor.hex)\"/>"
        let stylePrefix = "<style>rect{width:1px;height:1px;} #px101{shape-rendering: crispedges;} "

        let colors = colorDictionary.map { color, index in
            ".c\(index){fill:#\(color.hex)}"
        }.joined()
        return prefix + bgRect + pixelRects + stylePrefix + colors + "</style>" + "</svg>"
    }
}

//func svgPrefix(width: Int, height: Int) -> String {
//    "<svg viewBox=\"0 0 \(width) \(height)\" xmlns=\"http://www.w3.org/2000/svg\">"
//}
//
//func svgRects(bitmap: Bitmap) -> [String] {
//    bitmap.pixels.enumerated().map { i, color in
//        let colorString = color == .black ? "" : "fill=\"#\(color.hex)\""
//        return "<path \(colorString) d=\"M\(i % bitmap.width) \(i / bitmap.height)h1.1v1.1H\(i % bitmap.width)z\"/>"
//    }
//}
//
//extension Bitmap {
//    var svg: String {
//        svgPrefix(width: width, height: height) +
//        svgRects(bitmap: self)
//            .joined(separator: "") +
//        "</svg>"
//    }
//}

enum Direction {
    case up, down, left, right
}

/*
func paths(for bitmap: Bitmap) -> String {
    let pixels = bitmap.pixels
    
    var h = 0
    var v = 0
    
    var currentDirection = Direction.right

    var s = "M 0 0"
    for (i, pixel) in pixels.enumerated() {
        let x = i % bitmap.width
        let y = i / bitmap.height
        
        let moveRight = (Direction.right, (i > 0) && pixel == pixels[i + 1])
        let moveDown = (Direction.down, (y < bitmap.height - 1) && pixel == pixels[i + bitmap.width])
        let moveLeft = (Direction.left, (x > 0) && pixel == pixels[i - 1])
        let moveUp = (Direction.up, (y > 1) && pixel == pixels[i - bitmap.width])
        
        let checks: [(Direction, Bool)]
        switch currentDirection {
        case .up:
            checks = [moveLeft, moveUp, moveRight]
        case .down:
            checks = [moveRight, moveDown, moveLeft]
        case .left:
            checks = [moveDown, moveLeft, moveUp]
        case .right:
            checks = [moveUp, moveRight, moveDown]
        }
        
        for (direction, isPossible) in checks {
            
            if direction != currentDirection {
                h = 0
                v = 0
                
                s += " H\(h) V\(v)"
            }
            
            if isPossible {
                switch direction {
                case .up:
                    v -= 1
                case .down:
                    v += 1
                case .left:
                    h -= 1
                case .right:
                    h += 1
                }
                currentDirection = direction
            }
        }
    }
    s += "</svg>"
    return s
}
*/
extension Data {
    /// Data into file
    ///
    /// - Parameters:
    ///   - fileName: the Name of the file you want to write, remember to include extension.
    /// - Returns: Returns the URL where the new file is located in
    func toFile(fileName: String) -> URL? {
        var filePath: URL = URL(fileURLWithPath: NSTemporaryDirectory())
        filePath.appendPathComponent(fileName)

        do {
            try write(to: filePath)
            return filePath
        } catch {
            print("Error writing the file: \(error.localizedDescription)")
        }
        return nil
    }
}

enum DrawingTool {
    case pencil, line, selection, rectangle, rectangleFill, circle, fill, none, move // move is not user selectable, but a selection state
}

//extension DrawingTool {
//    var bitmap: Bitmap {
//        switch self {
//        case .pencil:
//            return Bitmap(width: 24, pattern: [])
//        case .line:
//            return Bitmap(width: 24, pattern: [])
//        case .rectangle:
//            return Bitmap(width: 24, pattern: [])
//        case .circle:
//            return Bitmap(width: 24, pattern: [])
//        case .fill:
//            return Bitmap(width: 24, pattern: [])
//        }
//    }
//}

protocol ColorSelectionDelegate: AnyObject {
    func didChangeColors(_ strokeColor: UIColor, _ fillColor: UIColor)
}
/*

final class ColorSelectionView: UIView {
    
    weak var delegate: ColorSelectionDelegate? = nil
    
    var strokeColor: UIColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var fillColor: UIColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init(strokeColor: UIColor, fillColor: UIColor, frame: CGRect) {
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.label.cgColor)
        context.setFillColor(fillColor.cgColor)
        let strokeRect = CGRect(x: 0, y: 0, width: rect.width * 0.75, height: rect.height * 0.75)
        let fillRect = CGRect(x: rect.width * 0.25, y: rect.width * 0.25, width: rect.width * 0.75, height: rect.height * 0.75)
        
        
        context.setFillColor(fillColor.cgColor)
        context.addRect(fillRect)
        context.drawPath(using: .fillStroke)
        context.setFillColor(strokeColor.cgColor)
        context.addRect(strokeRect)
        context.drawPath(using: .fillStroke)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let oldStroke = strokeColor
        let oldFill = fillColor
        strokeColor = oldFill
        fillColor = oldStroke
        delegate?.didChangeColors(strokeColor, fillColor)
    }
}
*/
