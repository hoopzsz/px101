//
//  px101Tests.swift
//  px101Tests
//
//  Created by Daniel Hooper on 2021-11-26.
//

import XCTest
@testable import px101

class px101Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInsert() throws {
        let values = [0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0,]
        
        let insertValue = [1, 1, 1,
                           1, 1, 1]
        
        
        let inserted1 = Bitmap(width: 5, binary: values).insert(newBitmap: Bitmap(width: 3, binary: insertValue), at: 0, y: 0)
        
        let inserted1r = Bitmap(width: 3, binary: [1, 1, 1, 0, 0,
                                                    1, 1, 1, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,])
        
        let inserted2 = Bitmap(width: 5, binary: values).insert(newBitmap: Bitmap(width: 3, binary: insertValue), at: 3, y: 1)

        let inserted2r = Bitmap(width: 3, binary: [0, 0, 0, 0, 0,
                                                    0, 0, 0, 1, 1,
                                                    0, 0, 0, 1, 1,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,])
        
        let inserted3 = Bitmap(width: 5, binary: values).insert(newBitmap: Bitmap(width: 3, binary: insertValue), at: 4, y: 5)

        let inserted3r = Bitmap(width: 3, binary: [0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 1,])
        
        let inserted4 = Bitmap(width: 5, binary: values).insert(newBitmap: Bitmap(width: 3, binary: insertValue), at: -1, y: -1)

        let inserted4r = Bitmap(width: 3, binary: [1, 1, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,
                                                    0, 0, 0, 0, 0,])

        assert(inserted1.pixels == inserted1r.pixels)
        assert(inserted2.pixels == inserted2r.pixels)
        assert(inserted3.pixels == inserted3r.pixels)
        assert(inserted4.pixels == inserted4r.pixels)

    }

    func testBitmapCropping() throws {
        let pixels: [Color] = [.red, .orange, .yellow, .green, .blue, .purple,
                               .red, .orange, .yellow, .green, .blue, .purple,
                               .red, .orange, .yellow, .green, .blue, .purple, //
                               .red, .orange, .yellow, .green, .blue, .purple, //
                               .red, .orange, .yellow, .green, .blue, .purple,
                               .red, .orange, .yellow, .green, .blue, .purple,
                               .red, .orange, .yellow, .green, .blue, .purple]
        
        let bitmap = Bitmap(width: 6, pixels: pixels)

        let croppedTopBy3: [Color] = [.red, .orange, .yellow, .green, .blue, .purple,
                                      .red, .orange, .yellow, .green, .blue, .purple,
                                      .red, .orange, .yellow, .green, .blue, .purple,
                                      .red, .orange, .yellow, .green, .blue, .purple]
        
        let croppedBottomBy4: [Color] = [.red, .orange, .yellow, .green, .blue, .purple,
                                         .red, .orange, .yellow, .green, .blue, .purple,
                                         .red, .orange, .yellow, .green, .blue, .purple]
        
        let croppedLeftBy3: [Color] = [.green, .blue, .purple,
                                       .green, .blue, .purple,
                                       .green, .blue, .purple,
                                       .green, .blue, .purple,
                                       .green, .blue, .purple,
                                       .green, .blue, .purple,
                                       .green, .blue, .purple]
        
        let croppedRightBy3: [Color] = [.red, .orange, .yellow,
                                        .red, .orange, .yellow,
                                        .red, .orange, .yellow,
                                        .red, .orange, .yellow,
                                        .red, .orange, .yellow,
                                        .red, .orange, .yellow,
                                        .red, .orange, .yellow]
        
        let croppedTopAndLeftBy3: [Color] = [.green, .blue, .purple,
                                             .green, .blue, .purple,
                                             .green, .blue, .purple,
                                             .green, .blue, .purple]
        
        let croppedTop = bitmap.cropped(top: 3, bottom: 0, left: 0, right: 0)
        let croppedBottom = bitmap.cropped(top: 0, bottom: 4, left: 0, right: 0)
        let croppedLeft = bitmap.cropped(top: 0, bottom: 0, left: 3, right: 0)
        let croppedRight = bitmap.cropped(right: 3)

        let croppedTopAndLeft = bitmap.cropped(top: 3, left: 3)
        
        for color in croppedRightBy3 {
            print(color)
        }
        print("\n")
        for color in croppedRight.pixels {
            print(color)
        }
        
        assert(croppedTop.pixels == croppedTopBy3)
        assert(croppedBottom.pixels == croppedBottomBy4)
        assert(croppedLeft.pixels == croppedLeftBy3)
        assert(croppedRight.pixels == croppedRightBy3)
        assert(croppedTopAndLeft.pixels == croppedTopAndLeftBy3)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
