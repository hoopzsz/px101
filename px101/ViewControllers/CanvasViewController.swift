//
//  CanvasViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-10.
//

import UIKit

enum DrawingTool {
    case pencil, line, selection, rectangle, circle, fill
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

final class CanvasViewController: UIViewController {
    
    private let scrollview = UIScrollView()
    private let canvasView = UIView()
    // Layer views
//    private let transparencyView: LayerView
    private let transparencyView = UIImageView()
    private let bitmapView = UIImageView()
    private let previewView = UIImageView()
    private let onionView = UIImageView()
//    private let gesturePreviewView = UIImageView()
//    private let previewView: PreviewLayerView
    private let gridView: StrokeGridView
    private let gestureView: GestureView
    
    private let zoomLabel = UIImageView()

    // Palette
    private let paletteContainerView = UIView(frame: .zero)
    private var paletteViewController: PaletteViewController!
    private var palette: Palette = .default
    private let colorSelectionView = ColorSelectionView(strokeColor: .black, fillColor: .white, frame: .zero)

    // Top buttons
    private var undoButton: UIBarButtonItem!
    private var redoButton: UIBarButtonItem!
    
    // Bottom buttons
    private let buttonStack = UIStackView()
    private let pencilButton = UIButton(type: .system)
    private let lineButton = UIButton(type: .system)
    
    private let selectionButton = UIButton(type: .system)
    
    private let rectangleButton = UIButton(type: .system)
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
            navigationItem.rightBarButtonItems = [extrasButton, redoButton, undoButton]
        }
    }
    
    private var invertGrid = false {
        didSet {
            gridView.strokeColor = gridView.strokeColor == .label ? .systemBackground : .label
            if showGrid == false {
                showGrid = true
                return
            }
            navigationItem.rightBarButtonItems = [extrasButton, redoButton, undoButton]
        }
    }
    
    private var strokeColor: Color = .black
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
    
    init(bitmap: Bitmap) {
        self.bitmap = bitmap
        [transparencyView, bitmapView, previewView, onionView].forEach { bitmapView in
            bitmapView.backgroundColor = .clear
            bitmapView.contentMode = .scaleAspectFit
            bitmapView.layer.magnificationFilter = .nearest
        }
        
        let transparencyBitmap = Bitmap.transparencyIndicator(of: bitmap.width, height: bitmap.height)
        transparencyView.image = UIImage(bitmap: transparencyBitmap)
        
        gridView = StrokeGridView(width: bitmap.width, height: bitmap.height)
        gridView.backgroundColor = .clear
        gestureView = GestureView(width: bitmap.width, height: bitmap.height, frame: .zero)
        
        paletteViewController = PaletteViewController(palette: .default)

        super.init(nibName: nil, bundle: nil)
        self.title = ""
        self.navigationItem.title = ""
        undoButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.backward"), style: .plain, target: self, action: #selector(undoButtonPressed))
        redoButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.forward"), style: .plain, target: self, action: #selector(redoButtonPressed))
        undoButton.isEnabled = false
        redoButton.isEnabled = false
        
        view.addSubview(zoomLabel)
        view.addSubview(colorSelectionView)
        colorSelectionView.clipsToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(scrollview)
        scrollview.delegate = self
        scrollview.alwaysBounceVertical = false
        scrollview.alwaysBounceHorizontal = false
        scrollview.showsVerticalScrollIndicator = true
        scrollview.flashScrollIndicators()

        scrollview.minimumZoomScale = 1.0
        scrollview.maximumZoomScale = CGFloat(bitmap.width / 8)
        
        onionView.alpha = 0.5

        bitmapView.clipsToBounds = false
        
        bitmapView.image = UIImage(bitmap: bitmap)
        view.backgroundColor = .systemBackground

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
        colorSelectionView.delegate = self
        
        addPaletteViewController()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        scrollview.layer.borderWidth = 1
        scrollview.layer.borderColor = UIColor.label.cgColor
    }
    
    override func viewWillLayoutSubviews() {
        colorSelectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        zoomLabel.translatesAutoresizingMaskIntoConstraints = false
        
        var width = layoutGuide.layoutFrame.maxX - layoutGuide.layoutFrame.minX
        var height = width
        let pixelWidth = width / CGFloat(bitmap.width)
        let pixelHeight = width / CGFloat(bitmap.height)
        
        let difference = abs(bitmap.width - bitmap.height)

        if bitmap.width > bitmap.height {
            height = height - (CGFloat(difference) * pixelWidth)
        } else if bitmap.height > bitmap.width {
            width = width - (CGFloat(difference) * pixelHeight)
        }
        
        NSLayoutConstraint.activate([
            scrollview.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: 32),
//            scrollview.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
//            scrollview.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            scrollview.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
//            scrollview.centerYAnchor.constraint(equalTo: layoutGuide.centerYAnchor),

            scrollview.widthAnchor.constraint(equalToConstant: width),

            scrollview.heightAnchor.constraint(equalToConstant: height),
            
            colorSelectionView.widthAnchor.constraint(equalToConstant: 48),
            colorSelectionView.heightAnchor.constraint(equalToConstant: 48),
            colorSelectionView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            colorSelectionView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -8),
            
            paletteContainerView.heightAnchor.constraint(equalToConstant: 48),
            paletteContainerView.leadingAnchor.constraint(equalTo: colorSelectionView.trailingAnchor, constant: 16),
            paletteContainerView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -32),
            paletteContainerView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -8),
            
            buttonStack.heightAnchor.constraint(equalToConstant: 64),
            buttonStack.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 8),
            buttonStack.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -8),
            buttonStack.bottomAnchor.constraint(equalTo: paletteContainerView.topAnchor, constant: -8),
            
            zoomLabel.topAnchor.constraint(equalTo: scrollview.bottomAnchor),
            zoomLabel.trailingAnchor.constraint(equalTo: scrollview.trailingAnchor),
            zoomLabel.heightAnchor.constraint(equalToConstant: 24),
//            zoomLabel.widthAnchor.constraint(equalToConstant: width),

        ])

        canvasView.frame = scrollview.bounds
        canvasView.subviews.forEach {
            $0.frame = canvasView.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Storage().saveBitmap(bitmap)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

// MARK - Layout
extension CanvasViewController {

    private var layerViewHeirarchy: [UIView] {
        [transparencyView,
         onionView,
         bitmapView,
         previewView,
         gridView,
         gestureView]
    }
    
    private var buttonHeirarchy: [UIButton] {
        [pencilButton,
         lineButton,
//         selectionButton,
         rectangleButton,
//         circleButton,
         fillButton]
    }
        
    private var layoutGuide: UILayoutGuide {
        view.layoutMarginsGuide
    }
    
    func layerViewContraints(_ view: UIView) -> [NSLayoutConstraint] {
        [view.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: 16),
         view.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
         view.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
         view.heightAnchor.constraint(equalTo: layoutGuide.widthAnchor)]
    }
}

// Palette
extension CanvasViewController: ColorSelectionDelegate {
    
    private func addPaletteViewController() {
        paletteContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paletteContainerView)
        
        paletteViewController.view.frame = paletteContainerView.bounds
        paletteViewController.delegate = self
        paletteContainerView.addSubview(paletteViewController.view)
        paletteViewController.view.clipsToBounds = true
        paletteViewController.willMove(toParent: self)
        addChild(paletteViewController)
        paletteViewController.didMove(toParent: self)
    }
    
    func didChangeColors(_ strokeColor: UIColor, _ fillColor: UIColor) {
        self.strokeColor = Color(uiColor: strokeColor)
//        self.fillColor = fillColor
    }
}

extension CanvasViewController: PaletteDelegate {
    
    func didSelectColor(_ color: Color) {
        strokeColor = color//.uiColor
        colorSelectionView.strokeColor = UIColor(red: CGFloat(color.r)/255.0, green: CGFloat(color.g)/255.0, blue: CGFloat(color.b)/255.0, alpha: CGFloat(color.a)/255.0)
    }
    
    func didPressPlusButton() {
        let vc = UIColorPickerViewController()
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
}

extension CanvasViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
//        print(color.rgbaSafe)
//        let color = Color(r: UInt8(color.rgbaSafe.red), g: UInt8(color.rgbaSafe.green), b: UInt8(color.rgbaSafe.blue), a: UInt8(color.rgbaSafe.alpha))
        let color = Color(uiColor: color)
        if continuously == false, !paletteViewController.palette.colors.contains(color) {
            paletteViewController.palette.colors.append(color)
            paletteViewController.collectionView.reloadData()
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

        let selectionImage = UIImage(systemName: "rectangle.dashed")
        selectionButton.setImage(selectionImage, for: .normal)
        selectionButton.addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
        
        let rectangleButtonImage = UIImage(systemName: "rectangle")
        rectangleButton.setImage(rectangleButtonImage, for: .normal)
        rectangleButton.addTarget(self, action: #selector(toggleRectangle), for: .touchUpInside)

        let circleButtonImage = UIImage(systemName: "circle")
        circleButton.setImage(circleButtonImage, for: .normal)
        circleButton.addTarget(self, action: #selector(toggleCircle), for: .touchUpInside)
        
        let fillButtonImage = UIImage(systemName: "drop")
        fillButton.setImage(fillButtonImage, for: .normal)
        fillButton.addTarget(self, action: #selector(toggleFill), for: .touchUpInside)

        navigationItem.rightBarButtonItems = [extrasButton, redoButton, undoButton]
    }
    
    private func exportPng(_ action: UIAction) {
        let image = UIImage(bitmap: bitmap.scaled(16))
        if let data = image?.pngData() {
            let activityController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            self.present(activityController, animated: true, completion: nil)
        }
    }

    private func exportSvg(_ action: UIAction) {
        let text = bitmapToSvg(bitmap)
        print("\n\(text)\n")
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
    }

    private func exportCode(_ action: UIAction) {
        print(bitmap.pixels)
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func updateButtonStates() {
        [pencilButton, lineButton, selectionButton, rectangleButton, circleButton, fillButton].forEach {
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
        case .circle:
            circleButton.isSelected = true
        case .fill:
            fillButton.isSelected = true
        }
    }
    
    @objc private func togglePencil() {
        selectedTool = .pencil
    }
    
    @objc private func toggleLine() {
        selectedTool = .line
    }
    
    @objc private func toggleSelection() {
        selectedTool = .selection
    }
    
    @objc private func toggleRectangle() {
        selectedTool = .rectangle
    }
    
    @objc private func toggleCircle() {
        selectedTool = .circle
    }
    
    @objc private func toggleFill() {
        selectedTool = .fill
    }
    
    @objc private func gridButtonPressed() {
        eyeImage = eyeImage == UIImage(systemName: "eye.slash") ? UIImage(systemName: "eye") : UIImage(systemName: "eye.slash")
        gridView.isHidden.toggle()
    }
    
    @objc private func undoButtonPressed() {
        if let undoManager = undoManager, undoManager.canUndo {
            undoManager.undo()
        }
    }
    
    @objc private func redoButtonPressed() {
        if let undoManager = undoManager, undoManager.canRedo {
            undoManager.redo()
        }
    }
}

// Menus
extension CanvasViewController {
    
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
    
    private var gridMenu: UIMenu {
        UIMenu(title: "Grid Settings", image: UIImage(systemName: "grid"/*"squareshape.split.3x3"*/), options: .displayInline, children: [showGridAction, invertGridAction])
    }
    
    private var previewMenu: UIMenu {
        UIMenu(title: "Preview Layer", image: UIImage(systemName: "rectangle.dashed.and.paperclip"), options: .displayInline, children: [
            UIAction(title: "Add image", image: UIImage(systemName: "photo.on.rectangle"), handler: { _ in }),
            UIAction(title: "Add drawing", image: UIImage(systemName: "squareshape.split.3x3"), handler: { _ in
                // Test
                self.onionImage = self.onionImage == nil ? UIImage(named: "px101") : nil
            })

       ])
    }
    
    private var exportMenu: UIMenu {
        UIMenu(title: "Export", image: UIImage(systemName: "arrow.up.doc.on.clipboard"), children: [
           UIAction(title: ".png", image: UIImage(systemName: "photo"), handler: exportPng),
           UIAction(title: ".svg",  image: UIImage(systemName: "square.on.circle"), handler: exportSvg),
           //UIAction(title: ".swift",  image: UIImage(systemName: "square.on.circle"), handler: exportCode),
       ])
    }
    
    private var extrasMenu: UIMenu {
        UIMenu(title: "", children: [gridMenu, previewMenu, exportMenu])
    }
    
    private var extrasButton: UIBarButtonItem {
        UIBarButtonItem(title: "Extras", image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: extrasMenu)
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
        let oldBitmap = bitmap
        bitmap.changeColor(strokeColor, at: indexes)
        bitmapDidChange(from: oldBitmap)
    }
    
    func didTap(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .fill:
            indexes = floodFill(index: index, arrayWidth: bitmap.width, newColor: strokeColor, oldColor: bitmap.pixels[index], data: bitmap.pixels)
        default:
            indexes = [index]
        }
        updateLayer(at: indexes)
    }

    func didBeginDragging(at index: Int) {
        var strokeColor = strokeColor

        let indexes: [Int]
        switch selectedTool {
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: bitmap.width)
        case .circle:
            indexes = circularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .selection:
            isSelecting.toggle()
            strokeColor = Color(r: 255, g: 200, b: 200, a: 127)
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .pencil:
            dragIndexes = [index]
            indexes = dragIndexes
        case .fill:
            indexes = floodFill(index: index, arrayWidth: bitmap.width, newColor: strokeColor, oldColor: bitmap.pixels[index], data: bitmap.pixels)
            updateLayer(at: indexes)
            return
        }
        
        previewView.image = UIImage(bitmap: bitmap.withChanges(newColor: strokeColor, at: indexes))
        
        lastDragIndex = index
    }

    func isDragging(at index: Int) {
        let indexes: [Int]
        switch selectedTool {
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: bitmap.width)
        case .circle:
            indexes = circularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .selection:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .pencil:
            indexes = lineIndexSet(firstIndex: lastDragIndex, secondIndex: index, arrayWidth: bitmap.width)
            dragIndexes.append(contentsOf: indexes)
        case .fill:
            return
        }
        previewView.image = UIImage(bitmap: bitmap.withChanges(newColor: strokeColor, at: selectedTool == .pencil ? dragIndexes : indexes))
        
        lastDragIndex = index
    }

    func didEndDragging(at index: Int) {
//        var strokeColor = strokeColor

        let indexes: [Int]
        switch selectedTool {
        case .line:
            indexes = lineIndexSet(firstIndex: gestureView.touchDownIndex, secondIndex: index, arrayWidth: bitmap.width)
        case .circle:
            indexes = circularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .selection:
//            strokeColor = Color(r: 255, g: 200, b: 200, a: 127)
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .rectangle:
            indexes = rectangularIndexSet(initialIndex: gestureView.touchDownIndex, currentIndex: index, arrayWidth: bitmap.width)
        case .pencil:
            dragIndexes.append(index)
            indexes = dragIndexes
        case .fill:
            return
        }
        if selectedTool != .selection {
            updateLayer(at: indexes)
        }
        lastDragIndex = index
        previewView.image = UIImage()
    }
}

extension CanvasViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        canvasView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {

//        scrollView.setZoomScale(zoomScale, animated: true)
        let zoomScale = CGFloat(ceil(Double(scale) * 4)) / 4
//        print("scale: \(scale)\nnew: \(zoomScale)")
        scrollView.zoomScale = zoomScale
//        scrollView.setZoomScale(zoomScale, animated: true)
        

        
        let offset = scrollView.contentOffset
        let w = (scrollView.frame.width / CGFloat(bitmap.width)) * scale
        var x = w * CGFloat(Int(offset.x / w))
        var y = w * CGFloat(Int(offset.y / w))
        
        if offset.x - x > (0.5 * w) {
            x += w
        }
        if offset.y - y > (0.5 * w) {
            y += w
        }
        let z = CGPoint(x: x, y: y)
        
        print("offset: \(offset)\nw: \(w)\n new: \(z)")
        scrollView.setContentOffset(z, animated: true)
//
//        let cases = "zoom \(zoomScale)x".flatMap { "\($0)" }.flatMap { [fiveSeven.caseForCharacter($0), fiveSeven.space] }
//        let bitmap = cases.map { $0.bitmap }.reduce(fiveSeven.z.bitmap) { stitch($0, to: $1) }
//        zoomLabel.image = UIImage(bitmap: bitmap)
//        zoomLabel.contentMode = .scaleAspectFit
//        scrollView.setZoomScale(sc÷ale, animated: true)
        print("\n")
    }
}

func bitmapToSvg(_ bitmap: Bitmap) -> String {
    let width = bitmap.width
    let height = bitmap.height
    let rectStrings: [String] = bitmap.pixels.enumerated().map { index, color in
        let x = index % bitmap.width
        let y = index / bitmap.height
        return "<rect fill=\"rgb(\(color.r),\(color.g),\(color.b))\" height=\"1px\" opacity=\"\(Float(color.a / 255))\" width=\"1px\" x=\"\(x)px\" y=\"\(y)px\"/>"
    }
    
    let beginning =
    """
      <svg viewBox=\"0 0 \(bitmap.width) \(bitmap.height)\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\">
      <rect width=\"\(bitmap.width)\" height=\"\(bitmap.height)\" fill=\"#000100\"/>
    """

    
    let end = "</svg>"
    
    return ([beginning] + rectStrings + [end]).joined(separator: "")
}

enum Direction {
    case up, down, left, right
}

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

/*<path fill-rule="evenodd" clip-rule="evenodd"
 d="M 21 6 H23 V7 H24 V8 H25 V9 H26 V10 V11 H27 V12 V13V14V15H26V16V17V18V19H25V20H24V21H23V22H22V21V20H21V21V22H20V23H19V22V21V20V19H18V18V17H17V16V15H16V14V13V12V11H17V10H18V9H20V8V7H21V6Z" fill="#E8213D"/>
*/
/*
 Pixels to SVG pseudo-code
 
 Goal: Draw fillable path representing a group of pixels
 
 To define a shape we:
 
 Start at 0,0
 
 If pixel to right is colour matched,
    move right 1
 Else check downwards
 If downwards pixel is colour matched,
    move down 1
 Else if pixel to left is colour matched,
    move left 1
 Else if pixel above is match
    move up 1
 
 
 
 */
