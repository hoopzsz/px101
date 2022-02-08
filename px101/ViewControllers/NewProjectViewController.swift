//
//  NewProjectViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit

final class NewProjectViewController: UIViewController {
            
    private let nameRow = UIView()
    private let nameLabel = UILabel()
    private let nameField = UITextField()
    
    private let widthLabel = UILabel()
    private let widthField = UITextField()
    private var widthStepper = UIStepper()
    
    private let heightLabel = UILabel()
    private let heightField = UITextField()
    private let heightStepper = UIStepper()

    private let widthHStack = UIStackView()
    private let heightHStack = UIStackView()
    
    private let startButton = UIButton()
    private let startButtonBackground = UIView(frame: .zero)

    private let cancelButton = UIButton()
    private let cancelButtonBackground = UIView(frame: .zero)
    
    let seperator = UIView()
    
    private let minimumValue = 4.0
    private let maximumValue = 256.0
    
    private var width = 16.0 {
        didSet {
            widthField.text = "\(Int(width))"
        }
    }
    private var height = 16.0 {
        didSet {
            heightField.text = "\(Int(height))"
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        title = ""
        navigationItem.title = ""
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(widthLabel)
        view.addSubview(heightLabel)
        
        widthField.text = "\(Int(width))"
        heightField.text = "\(Int(height))"
        
        [widthHStack, heightHStack].forEach {
            $0.axis = .horizontal
            $0.alignment = .leading
            $0.distribution = UIStackView.Distribution.equalSpacing
            view.addSubview($0)
        }
        
        [widthField, widthStepper]
            .forEach(widthHStack.addArrangedSubview)

        [heightField, heightStepper]
            .forEach(heightHStack.addArrangedSubview)
        
        widthHStack.clipsToBounds = true
        heightHStack.clipsToBounds = true
        
        
        [nameField, widthField, heightField].forEach {
            $0.borderStyle = .roundedRect
        }
        
        widthField.tag = 0
        heightField.tag = 1
        [widthField, heightField].forEach {
            $0.delegate = self
            $0.keyboardType = .numberPad
        }
        
        widthLabel.text = "Width"
        heightLabel.text = "Height"
        
        widthStepper.value = width
        widthStepper.tag = 0
        
        heightStepper.value = height
        heightStepper.tag = 1

        [widthStepper, heightStepper].forEach {
            $0.stepValue = 1.0
            $0.minimumValue = minimumValue
            $0.maximumValue = maximumValue
            $0.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createButtonPressed))
        
        let newProjecLetters: [fiveSeven] = [.n, .e, .w, .space, .p, .r, .o, .j, .e, .c, .t]
        let newProjectImage = newProjecLetters
            .flatMap { [fiveSeven.space.bitmap, $0.bitmap] } // Interleave characters with spaces
            .reduce(.initial) { stitch($0, to: $1) } // Assemble from left to right
            .scaled(2)
        
        let imageView = UIImageView(image: UIImage(bitmap: newProjectImage)?.withTintColor(UIColor.label))
        imageView.contentMode = .center
        navigationItem.titleView = imageView
    }
    
    override func viewWillLayoutSubviews() {
        view.subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    
        let guide = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
//            segmentedControl.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
//            segmentedControl.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
//            segmentedControl.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
//
//            nameLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//            nameLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
//            nameLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
//
//            nameField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//            nameField.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
//            nameField.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            widthLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            widthLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            widthLabel.trailingAnchor.constraint(equalTo: guide.centerXAnchor, constant: -8),

            widthHStack.topAnchor.constraint(equalTo: widthLabel.bottomAnchor, constant: 8),
            widthHStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            widthHStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            
            heightLabel.topAnchor.constraint(equalTo: widthHStack.bottomAnchor, constant: 16),
            heightLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            heightLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            
            heightHStack.topAnchor.constraint(equalTo: heightLabel.bottomAnchor, constant: 8),
            heightHStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            heightHStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ])
    }
    
    @objc private func stepperValueChanged(_ sender: UIStepper) {

        // Width stepper
        if sender.tag == 0 {
            width = sender.value
        }
        // Height stepper
        else {
            height = sender.value
        }
    }
    
    @objc private func createButtonPressed(_ sender: UIBarButtonItem) {
        heightField.resignFirstResponder()
        widthField.resignFirstResponder()
//        let randomColor = UIColor(red: CGFloat(Int.random(in: 0...255))/255,
//                                  green: CGFloat(Int.random(in: 0...255))/255,
//                                  blue: CGFloat(Int.random(in: 0...255))/255,
//                                  alpha: 1)
//        let randomColor = Color(r: UInt8.random(in: 0...255),
//                                g: UInt8.random(in: 0...255),
//                                b: UInt8.random(in: 0...255),
//                                a: 255)
        let randomColor = Color.clear
//                    let colors = (i..<i*8*8).map { _ in
//                        UIColor(red: CGFloat(Int.random(in: 0...255))/255,
//                                                  green: CGFloat(Int.random(in: 0...255))/255,
//                                                  blue: CGFloat(Int.random(in: 0...255))/255,
//                                                  alpha: 1)
//                    }
//        let colors = (1...(Int(width) * Int(height))).map { _ in randomColor }
        let colors = Array(repeating: randomColor, count: Int(width * height))
        let bitmap = Bitmap(width: Int(width), pixels: colors)
        let viewController = CanvasViewController(bitmap: bitmap)
        Storage().saveBitmap(bitmap)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension NewProjectViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        
        if textField.tag == 0 {
            width = max(minimumValue, min(Double(text) ?? 16, maximumValue))
        } else {
            height = max(minimumValue, min(Double(text) ?? 16, maximumValue))
        }
    }
}

extension NewProjectViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController.isKind(of: CanvasViewController.self) {
            viewController.navigationItem.title = ""

            navigationController.viewControllers.remove(at: navigationController.viewControllers.count - 2)
        }
    }
}
