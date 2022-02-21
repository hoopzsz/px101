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
    
    private let pencilButton = UIButton(image: UIImage(systemName: "paintbrush.pointed"), target: self, selector: #selector(toggleTool))
    private let lineButton = UIButton(image: UIImage(systemName: "line.diagonal"), target: self, selector: #selector(toggleTool))
    private let selectionButton = UIButton(image: UIImage(systemName: "cursorarrow.and.square.on.square.dashed"), target: self, selector: #selector(toggleTool))
    private let rectangleButton = UIButton(image: UIImage(systemName: "rectangle"), target: self, selector: #selector(toggleTool))
    private let rectangleFillButton = UIButton(image: UIImage(systemName: "rectangle.inset.fill"), target: self, selector: #selector(toggleTool))
    private let circleButton = UIButton(image: UIImage(systemName: "circle"), target: self, selector: #selector(toggleTool))
    private let fillButton = UIButton(image: UIImage(systemName: "drop"), target: self, selector: #selector(toggleTool))

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
    
    private var selectedTool: DrawingTool = .none
    
    private var bitmap: Bitmap {
        didSet {
            bitmapView.image = UIImage(bitmap: bitmap)
        }
    }
    
    private var selectionArea: Bitmap? = nil
    
    init(bitmap: Bitmap) {
        self.bitmap = bitmap
        [transparencyView, bitmapView, previewView, onionView].forEach { view in
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
            view.contentMode = .scaleAspectFit
            view.layer.magnificationFilter = .nearest
            view.layer.magnificationFilter = .nearest
            view.layer.borderColor = UIColor.label.cgColor
            view.layer.borderWidth = 1
        }
        
        fileSizeLabel.contentMode = .center
        fileSizeLabel.backgroundColor = .clear
        fileSizeLabel.layer.magnificationFilter = .nearest
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
                
        let transparencyBitmap = Bitmap.transparencyIndicator(of: bitmap.width, height: bitmap.height)
        transparencyView.image = UIImage(bitmap: transparencyBitmap)
        
        gridView = StrokeGridView(width: bitmap.width, height: bitmap.height)
        gridView.backgroundColor = .clear
//        gridView.isUserInteractionEnabled = false
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
        view.addSubview(buttonStack)

        scrollview.delegate = self
        scrollview.minimumZoomScale = 1.0
        scrollview.maximumZoomScale = CGFloat(bitmap.width / 4)
        scrollview.bounces = false
        scrollview.addSubview(canvasView)

        onionView.alpha = 0.5

        bitmapView.clipsToBounds = false
        bitmapView.image = UIImage(bitmap: bitmap)

        layerViewHeirarchy
            .forEach(canvasView.addSubview)
        
//        buttonHeirarchy
//            .forEach(buttonStack.addArrangedSubview)
        
        buttonHeirarchy.enumerated().forEach {
            $0.element.tag = $0.offset
            buttonStack.addArrangedSubview($0.element)
        }
                
        buttonStack.distribution = .equalCentering
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        gestureView.delegate = self
        
        addPaletteViewController()
        
        fileSizeLabel.tintColor = .red
        updateSizeLabel()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
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
        navigationItem.rightBarButtonItems = [extrasButton, layerButton, redoButton, undoButton]
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
        [pencilButton,
         lineButton,
         rectangleButton,
         rectangleFillButton,
         circleButton,
         fillButton,
         selectionButton]
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
//        paletteViewController.didsel
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
    
    private var layerButton: UIBarButtonItem {
//        UIBarButtonItem(title: "Layers", image: UIImage(systemName: "square.stack.3d.up"), primaryAction: nil, menu: extrasMenu)
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
//        let heirarchy = [transparencyView, bitmapView, gridView]
//        heirarchy.enumerated().forEach { index, view in
//            view.transform = CGAffineTransform(a: 1 , b: -0.2, c: 0, d: 1, tx: -16 + (CGFloat(index) * 16), ty: -16 + (CGFloat(index) * 16))
//        }
        
        let vc = BitmapsCollectionViewController()
        vc.didSelect = { bitmap in
            self.bitmap = bitmap
            vc.dismiss(animated: true)
        }
        
        let layerLetters: [fiveSeven] = [.l, .a, .y, .e, .r, .s]
        let titleImage = layerLetters
            .flatMap { [fiveSeven.space.bitmap, $0.bitmap] } // Interleave characters with spaces
            .reduce(.initial) { stitch($0, to: $1) } // Assemble from left to right
            .scaled(2)
        
        let imageView = UIImageView(image: UIImage(bitmap: titleImage)?.withTintColor(UIColor.label))
        imageView.contentMode = .center
        vc.navigationItem.titleView = imageView
        navigationController?.pushViewController(vc, animated: true)
//        vc.navig
//        let nav = UINavigationController(rootViewController: vc)
        
//        navigationController?.present(nav, animated: true)
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
            indexes = drawOval(at: gestureView.touchDownIndex, to: index, in: bitmap)
//            indexes = drawCircle(at: gestureView.touchDownIndex, to: index, in: bitmap)
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
            indexes = drawOval(at: gestureView.touchDownIndex, to: index, in: bitmap)
//            indexes = drawCircle(at: gestureView.touchDownIndex, to: index, in: bitmap)
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
        layer.path = UIBezierPath(rect: bounds).cgPath
        layer.strokeColor = UIColor.green.cgColor
        layer.fillColor = nil
        layer.lineDashPattern = [8, 6]
        previewView.layer.addSublayer(layer)
        
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
}

enum Direction {
    case up, down, left, right
}

enum DrawingTool {
    case pencil, line, selection, rectangle, rectangleFill, circle, fill, none, move // move is not user selectable, but a selection state
}
