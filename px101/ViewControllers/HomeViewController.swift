//
//  HomeViewController.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-20.
//

import UIKit

enum GbColor {
    case lightestGreen, lightGreen, darkGreen, darkestGreen
    
    var uiColor: UIColor {
        let color: Color
        switch self {
        case .lightestGreen:
            color = Color(r: 155, g: 188, b: 15)
        case .lightGreen:
            color = Color(r: 139, g: 172, b: 15)
        case .darkGreen:
            color = Color(r: 48, g: 98, b: 48)
        case .darkestGreen:
            color = Color(r: 15, g: 56, b: 15)
        }
        return color.uiColor
    }
}

final class HomeViewController: UIViewController {
    
    let logo = UIImageView()
    let name: [TetrisFont] = [.s, .q, .e, .t, .c, .h]

    let new = UIImageView()
    let newName: [TetrisFont] = [.n, .e, .w, .space, .p, .r, .o, .j, .e, .c, .t]
    let load = UIImageView()
    let loadName: [TetrisFont] = [.l, .o, .a, .d, .space, .p, .r, .o, .j, .e, .c, .t]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        [logo, new, load].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.magnificationFilter = .nearest
            $0.contentMode = .center
            view.addSubview($0)
        }
        
        view.backgroundColor = GbColor.lightestGreen.uiColor
        
//        let px101cases: [Px101Logo] = [.space2, .x, .space2, .dash, .space1, .one, .space2, .zero, .space1, .one]
//        let bitmaps = px101cases.map { $0.bitmap }
//        let stitched = bitmaps.reduce(Px101Logo.p.bitmao) { stitch($0, to: $1) }
//        logo.image = UIImage(bitmap: stitched)?.withTintColor(GbColor.darkGreen.uiColor)
        
        let px101Cases: [Px101Logo] = [.space2, .x, .space2, .dash, .space1, .one, .space2, .zero, .space1, .one]
        let px101 = px101Cases
            .map { $0.bitmap }
            .reduce(Px101Logo.p.bitmap) { stitch($0, to: $1) }
        
//        let testAlpha1: [fiveSeven] = [.b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n,.o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z]
        
//        let testAlpha1: [fiveSeven] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero]
        
        let testAlpha1: [fiveSeven] = [.q, .e, .t, .c, .h]
        
        let bitmaps = testAlpha1.flatMap { [fiveSeven.space.bitmap, $0.bitmap] }
        let stiched = bitmaps.reduce(fiveSeven.s.bitmap) { stitch($0, to: $1) }.scaled(3)
//        logo
        logo.image = UIImage(bitmap: stiched)?.withTintColor(GbColor.darkGreen.uiColor)
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
  
        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: view.frame.width - 32),
            logo.heightAnchor.constraint(equalToConstant: 64),
            
            new.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            new.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 48),
            new.widthAnchor.constraint(equalToConstant: CGFloat(newName.count) * 1.5 * 8),
            new.heightAnchor.constraint(equalToConstant: 24),
            
            load.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            load.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 96),
            load.widthAnchor.constraint(equalToConstant: CGFloat(loadName.count) * 1.5 * 8),
            load.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
}

typealias Animation = [(Int, Bitmap)]

func intsToColor(_ ints: [Int], strokeColor: Color) -> [Color] {
    ints.map {
        $0 == 1 ? strokeColor : .clear
    }
}


func stitch(_ bitmap: Bitmap, to secondBitmap: Bitmap, orientation: Direction = .right) -> Bitmap {

    if bitmap.pixels.isEmpty { return secondBitmap }
    
    var i = 0
    var x = 0
    var y = 0
    
    var px: [Color] = []
    while i < bitmap.pixels.count + secondBitmap.pixels.count {
        
        // Traverse first bitmap
        px.append(bitmap[x, y])

        // Finished bitmap row
        if x == bitmap.width - 1 {
            // Traverse second bitmap row
            x = 0
            while x < secondBitmap.width {
                px.append(secondBitmap[x, y])
                x += 1
                i += 1
            }
            x = 0
            if y < bitmap.height - 1 {
                y += 1
            }
        } else {
            x += 1
        }
        
        i += 1
    }
    
    return Bitmap(width: bitmap.width + secondBitmap.width, pixels: px)
}

enum Px101Logo: CaseIterable {
    case s, p, x, one, zero, dash, space1, space2
    
    var bitmap: Bitmap {
        switch self {
        case .s:
            return Bitmap(width: 12, binary: [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
                                               0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                                               0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                                               0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0])
        case .p:
            return Bitmap(width: 12, binary: [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
                                               0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
                                               1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                               1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                               1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                               1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                               ])
        case .x:
            return Bitmap(width: 12, binary: [1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0,
                                               0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0,
                                               0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0,
                                               0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0,
                                               0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0,
                                               0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1])
        case .one:
            return Bitmap(width: 7, binary: [1, 1, 1, 1, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1, 1])
        case .zero:
            return Bitmap(width: 12, binary: [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
                                               0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                               0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                                               0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0])
        case .dash:
            return Bitmap(width: 6, binary: [0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0])
        case .space1:
            return Bitmap(width: 1, binary: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        
        case .space2:
            return Bitmap(width: 2, binary: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        }
    }
    
}

enum TetrisFont: CaseIterable {

    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, space

    var bitmap: Bitmap {
        switch self {
        case .a:
            return Bitmap(width: 6, binary: [0, 1, 1, 1, 1, 0,
                                              1, 0, 0, 1, 1, 1,
                                              1, 0, 0, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1,
                                              1, 0, 0, 1, 1, 1,
                                              1, 0, 0, 1, 1, 1])
        case .b:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 1, 1, 1, 0])
        case .c:
            return Bitmap(width: 6, binary: [0, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 1, 1,
                                              0, 1, 1, 1, 1, 0])
        case .d:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 0,
                                              1, 0, 0, 1, 1, 1,
                                              1, 0, 0, 1, 1, 1,
                                              1, 0, 0, 1, 1, 1,
                                              1, 0, 0, 1, 1, 1,
                                              1, 1, 1, 1, 1, 0])
        case .e:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 1,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1, 1])
        case .f:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 1,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0])
        case .g:
            return Bitmap(width: 6, binary: [0, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 1, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              0, 1, 1, 1, 1, 1])
        case .h:
            return Bitmap(width: 6, binary: [1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1])
        case .i:
            return Bitmap(width: 6, binary: [0, 1, 1, 1, 1, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 1, 1, 1, 1, 0])
        case .j:
            return Bitmap(width: 6, binary: [0, 0, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 0,
                                              0, 0, 0, 1, 1, 0,
                                              1, 1, 0, 1, 1, 0,
                                              1, 1, 0, 1, 1, 0,
                                              0, 1, 1, 1, 0, 0])
        case .k:
            return Bitmap(width: 6, binary: [1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 1, 1, 0,
                                              1, 1, 1, 0, 0, 0,
                                              1, 1, 1, 0, 0, 0,
                                              1, 1, 0, 1, 1, 0,
                                              1, 1, 0, 0, 1, 1])
        case .l:
            return Bitmap(width: 6, binary: [1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1, 1])
        case .m:
            return Bitmap(width: 6, binary: [1, 0, 0, 0, 1, 1,
                                              1, 1, 0, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1,
                                              1, 0, 1, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1])
        case .n:
            return Bitmap(width: 6, binary: [1, 0, 0, 0, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 1, 0, 1, 1,
                                              1, 0, 1, 1, 1, 1,
                                              1, 0, 0, 1, 1, 1,
                                              1, 0, 0, 0, 1, 1])
        case .o:
            return Bitmap(width: 6, binary: [0, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              0, 1, 1, 1, 1, 0])
        case .p:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 0, 0,
                                              1, 1, 0, 0, 0, 0])
        case .q:
            return Bitmap(width: 6, binary: [0, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 0, 1,
                                              1, 1, 0, 0, 0, 1,
                                              1, 1, 0, 1, 0, 1,
                                              1, 1, 0, 0, 1, 0,
                                              0, 1, 1, 1, 0, 1])
        case .r:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 0, 1,
                                              1, 1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1, 0,
                                              1, 1, 0, 1, 0, 0,
                                              1, 1, 0, 0, 1, 1])
        case .s:
            return Bitmap(width: 6, binary: [0, 1, 1, 1, 1, 0,
                                              1, 1, 0, 0, 0, 0,
                                              0, 1, 1, 1, 1, 0,
                                              0, 0, 0, 1, 1, 1,
                                              1, 1, 0, 1, 1, 1,
                                              0, 1, 1, 1, 1, 0])
        case .t:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 1,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0])
        case .u:
            return Bitmap(width: 6, binary: [1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 1, 1, 1,
                                              0, 1, 1, 1, 1, 0])
        case .v:
            return Bitmap(width: 6, binary: [1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              0, 1, 0, 1, 1, 0,
                                              0, 0, 1, 1, 0, 0])
        case .w:
            return Bitmap(width: 6, binary: [1, 0, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1, 1,
                                              1, 0, 1, 0, 1, 1,
                                              1, 1, 1, 1, 1, 1,
                                              1, 1, 0, 1, 1, 1,
                                              1, 0, 0, 0, 1, 1])
        case .x:
            return Bitmap(width: 6, binary: [1, 0, 0, 0, 1, 1,
                                              0, 1, 0, 1, 1, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 1, 1, 1, 0, 0,
                                              1, 1, 0, 0, 1, 0,
                                              1, 0, 0, 0, 0, 1])
        case .y:
            return Bitmap(width: 6, binary: [1, 1, 0, 0, 1, 1,
                                              1, 1, 0, 0, 1, 1,
                                              0, 1, 1, 1, 1, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0,
                                              0, 0, 1, 1, 0, 0])
        case .z:
            return Bitmap(width: 6, binary: [1, 1, 1, 1, 1, 1,
                                              0, 0, 0, 1, 1, 1,
                                              0, 0, 1, 1, 1, 0,
                                              0, 1, 1, 1, 0, 0,
                                              1, 1, 1, 0, 0, 0,
                                              1, 1, 1, 1, 1, 1])
        case .space:
            return Bitmap(width: 2, binary: [0, 0,
                                              0, 0,
                                              0, 0,
                                              0, 0,
                                              0, 0,
                                              0, 0])
        }
    }
}

enum fiveSeven: CaseIterable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, space, period, zero, one, two, three, four, five, six, seven, eight, nine, magnifyingGlass
    
    var bitmap: Bitmap {
        switch self {
        case .a:
            return Bitmap(width: 5, binary: [0, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1])
        case .b:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 0])
        case .c:
            return Bitmap(width: 5, binary: [0, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 1,
                                              0, 1, 1, 1, 0])
        case .d:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 0])
        case .e:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1])
        case .f:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0])
        case .g:
            return Bitmap(width: 5, binary: [0, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1,
                                              0, 1, 1, 1, 0])
        case .h:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1])
        case .i:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              1, 1, 1, 1, 1])
        case .j:
            return Bitmap(width: 5, binary: [0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              0, 1, 1, 1, 0])
        case .k:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 1, 0,
                                              1, 0, 1, 0, 0,
                                              1, 1, 0, 0, 0,
                                              1, 0, 1, 0, 0,
                                              1, 0, 0, 1, 0,
                                              1, 0, 0, 0, 1])
        case .l:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1])
        case .m:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 1, 0, 1, 1,
                                              1, 0, 1, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1])
        case .n:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 1, 0, 0, 1,
                                              1, 0, 1, 0, 1,
                                              1, 0, 0, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1])
        case .o:
            return Bitmap(width: 5, binary: [0, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              0, 1, 1, 1, 0])
        case .p:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0])
        case .q:
            return Bitmap(width: 5, binary: [0, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 1, 0, 1,
                                              1, 0, 0, 1, 0,
                                              0, 1, 1, 0, 1])
        case .r:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 0,
                                              1, 0, 0, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1])
        case .s:
            return Bitmap(width: 5, binary: [0, 1, 1, 1, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              0, 1, 1, 1, 0,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              1, 1, 1, 1, 0])
        case .t:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0])
        case .u:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              0, 1, 1, 1, 0])
        case .v:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              0, 1, 0, 1, 0,
                                              0, 1, 0, 1, 0,
                                              0, 0, 1, 0, 0])
        case .w:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 1, 0, 1,
                                              1, 0, 1, 0, 1,
                                              0, 1, 0, 1, 0])
        case .x:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              0, 1, 0, 1, 0,
                                              0, 0, 1, 0, 0,
                                              0, 1, 0, 1, 0,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1])
        case .y:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              0, 1, 1, 1, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0])
        case .z:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 1, 0,
                                              0, 0, 1, 0, 0,
                                              0, 1, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1])
        case .space:
            return Bitmap(width: 3, binary: [0, 0, 0,
                                              0, 0, 0,
                                              0, 0, 0,
                                              0, 0, 0,
                                              0, 0, 0,
                                              0, 0, 0,
                                              0, 0, 0])
        case .zero:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 1, 1,
                                              1, 0, 1, 0, 1,
                                              1, 1, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1])
        case .one:
            return Bitmap(width: 5, binary: [1, 1, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              1, 1, 1, 1, 1])
        case .two:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1])
        case .three:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1])
        case .four:
            return Bitmap(width: 5, binary: [1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1])
        case .five:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1])
        case .six:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 0,
                                              1, 0, 0, 0, 0,
                                              1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1])
        case .seven:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 1, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0,
                                              0, 0, 1, 0, 0])
        case .eight:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1])
        case .nine:
            return Bitmap(width: 5, binary: [1, 1, 1, 1, 1,
                                              1, 0, 0, 0, 1,
                                              1, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1,
                                              0, 0, 0, 0, 1,
                                              0, 0, 0, 0, 1,
                                              1, 1, 1, 1, 1])
        case .period:
            return Bitmap(width: 1, binary: [0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1])
        
        case .magnifyingGlass:
            return Bitmap(width: 5, binary: [0, 0, 0, 0, 0,
                                              0, 1, 1, 0, 0,
                                              1, 0, 0, 1, 0,
                                              1, 0, 0, 1, 0,
                                              0, 1, 1, 0, 0,
                                              0, 0, 0, 1, 0,
                                              0, 0, 0, 0, 1])
        }
    }
    
    static func caseForCharacter(_ c: String) -> fiveSeven {
        switch c {
        case "a": return .a
        case "b": return .b
        case "c": return .c
        case "d": return .d
        case "e": return .e
        case "f": return .f
        case "g": return .g
        case "h": return .h
        case "i": return .i
        case "j": return .j
        case "k": return .k
        case "l": return .l
        case "m": return .m
        case "n": return .n
        case "o": return .o
        case "p": return .p
        case "q": return .q
        case "r": return .r
        case "s": return .s
        case "t": return .t
        case "u": return .u
        case "v": return .v
        case "w": return .w
        case "x": return .x
        case "y": return .y
        case "z": return .z
        case " ": return .space
        case "0": return .zero
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case ".": return .period
        case "magnifyingGlass": return .magnifyingGlass
        default: return .zero
        }
    }
}

struct Tools {
    
    static var pencil: Bitmap {
        Bitmap(width: 32, pixels: [])
    }
}
