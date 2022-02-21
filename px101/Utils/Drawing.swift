//
//  Drawing.swift
//  PixelPainter
//
//  Created by Daniel Hooper on 2021-11-07.
//

import UIKit

enum GestureDirection {
    case topLeftToBottomRight
    case bottomRightToTopLeft
    case topRightToBottomLeft
    case bottomLeftToTopRight
}

func horizontalDistance(from a: Int, to b: Int, width: Int) -> Int {
    abs(a % width - b % width)
}

func verticalDistance(from a: Int, to b: Int, width: Int) -> Int {
    abs(a / width - b / width)
}

private func direction(from a: Int, to b: Int, width: Int) -> GestureDirection {
    let isTopToBottom = a < b
    let isLeftToRight = a % width < b % width
    
    if isLeftToRight {
        return isTopToBottom ? .topLeftToBottomRight : .bottomLeftToTopRight
    } else {
        return isTopToBottom ? .topRightToBottomLeft : .bottomRightToTopLeft
    }
}

func lineIndexSet(firstIndex: Int, secondIndex: Int, arrayWidth: Int) -> [Int] {
    let point1x = firstIndex % arrayWidth
    let point1y = firstIndex / arrayWidth
    
    let point2x = secondIndex % arrayWidth
    let point2y = secondIndex / arrayWidth
    
    let results = drawLine(x1: point1x, y1: point1y, x2: point2x, y2: point2y)
    
    let converted: [Int] = results.map { $0.0 + (arrayWidth * $0.1) }
    return converted
}

func drawOval(at firstIndex: Int, to secondIndex: Int, in bitmap: Bitmap) -> [Int] {
    let w = bitmap.width
    let x1 = firstIndex % w
    let y1 = firstIndex / w
    let x2 = secondIndex % w
    let y2 = secondIndex / w
    
//    let r = (max(x1, x2) - min(x1, x2)) / 2
    let majR: Int = abs(x2 - x1) / 2 + 1
    let minR: Int = abs(y2 - y1) / 2 + 1
    return ellipse(rx: Double(majR), ry: Double(minR), xc: Double(x1 + majR), yc: Double(y1 + minR), w: w)
}

func drawCircle(at firstIndex: Int, to secondIndex: Int, in bitmap: Bitmap) -> [Int] {

    func makeCoordinates(xCenter: Int, yCenter: Int, x: Int, y: Int) -> [(Int, Int)] {
        [(xCenter + x, yCenter + y),
         (xCenter - x, yCenter + y),
         (xCenter + x, yCenter - y),
         (xCenter - x, yCenter - y),
         (xCenter + y, yCenter + x),
         (xCenter - y, yCenter + x),
         (xCenter + y, yCenter - x),
         (xCenter - y, yCenter - x)]
    }
    
    let firstX = firstIndex % bitmap.width
    let firstY = firstIndex / bitmap.width
    
    let horizontalLength = horizontalDistance(from: firstIndex, to: secondIndex, width: bitmap.width)
    let verticalLength   = verticalDistance(from: firstIndex, to: secondIndex, width: bitmap.width)
    
    let radius = horizontalLength / 2
    
    let xCenter = firstX + (horizontalLength / 2) // ?
    let yCenter = firstY + (verticalLength / 2)// ?
    
    var x = 0
    var y = radius
    var d = 3 - (2 * radius)
    
    var coordinates: [(Int, Int)] = makeCoordinates(xCenter: xCenter, yCenter: yCenter, x: x, y: y)
    
    while (y >= x) {
        x += 1
        if d > 0 {
            y -= 1
            d = d + 4 * (x - y) + 10;
        } else {
            d = d + 4 * x + 6;
        }
        
        coordinates += makeCoordinates(xCenter: xCenter, yCenter: yCenter, x: x, y: y)
    }
    
    let coordinatesAsIndexes = coordinates.map { pair in
//        abs(pair.0 + (pair.1 * bitmap.width))
        pair.0 + (pair.1 * bitmap.width)
    }
    
    return coordinatesAsIndexes
}



func circularIndexSet(initialIndex: Int, currentIndex: Int, arrayWidth: Int) -> [Int] {
    let horizontalLength = horizontalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)
    let verticalLength = verticalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)

    let xCenter = initialIndex + (horizontalLength / 2) // horizontalLength / 2// + initialIndex
    let yCenter = 0

//    let leftIndex = currentIndex % arrayWidth > initialIndex % arrayWidth ? initialIndex : currentIndex
    var indexes = circleBres(xCenter: xCenter, yCenter: yCenter, radius: max(verticalLength, horizontalLength) / 2 + 1, arrayWidth: arrayWidth)
    
    return indexes
//    return indexes.map {
//        $0 + (leftIndex % arrayWidth) + ((leftIndex % arrayWidth) * arrayWidth)
//    }
}

func rectangularIndexSet(initialIndex: Int, currentIndex: Int, arrayWidth: Int) -> [Int] {
    let horizontalLength = horizontalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)
    let verticalLength = verticalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)
    
    let row = Array(initialIndex...(initialIndex + horizontalLength))
    let column = stride(from: initialIndex, to: initialIndex + (verticalLength * arrayWidth), by: arrayWidth)
    let rectangle = Array(Set(row + column + row.map { $0 + (arrayWidth * verticalLength) } + column.map { $0 + horizontalLength }))
    
    let direction = direction(from: initialIndex, to: currentIndex, width: arrayWidth)
    
    switch direction {
    case .topLeftToBottomRight:
        return rectangle
    case .topRightToBottomLeft:
        return rectangle.map { $0 - horizontalLength }
    case .bottomLeftToTopRight:
        return rectangle.map { $0 - (arrayWidth * verticalLength) }
    case .bottomRightToTopLeft:
        return rectangle.map { $0 - horizontalLength - (arrayWidth * verticalLength) }
    }
}

func rectangularFillIndexSet(initialIndex: Int, currentIndex: Int, arrayWidth: Int) -> [Int] {
    let horizontalLength = horizontalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)
    let verticalLength = verticalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)
    
    let row = Array(initialIndex...(initialIndex + horizontalLength))
    // Copy row by the vertical length
    var rectangle: [Int] = []
    for i in 0...verticalLength {
        rectangle.append(contentsOf: row.map { $0 + (arrayWidth * i) })
    }
    let direction = direction(from: initialIndex, to: currentIndex, width: arrayWidth)
    
    switch direction {
    case .topLeftToBottomRight:
        return rectangle
    case .topRightToBottomLeft:
        return rectangle.map { $0 - horizontalLength }
    case .bottomLeftToTopRight:
        return rectangle.map { $0 - (arrayWidth * verticalLength) }
    case .bottomRightToTopLeft:
        return rectangle.map { $0 - horizontalLength - (arrayWidth * verticalLength) }
    }
}

func _circleBres(xCenter: Int, yCenter: Int, x: Int, y: Int) -> [(Int, Int)] {
    [(xCenter + x, yCenter + y),
     (xCenter - x, yCenter + y),
     (xCenter + x, yCenter - y),
     (xCenter - x, yCenter - y),
     (xCenter + y, yCenter + x),
     (xCenter - y, yCenter + x),
     (xCenter + y, yCenter - x),
     (xCenter - y, yCenter - x)]
}

func circleBres(xCenter: Int, yCenter: Int, radius: Int, arrayWidth: Int) -> [Int] {
    var x = 0
    var y = radius
    var d = 3 - (2 * radius)
    var indexes: [(Int, Int)] = []
    indexes += _circleBres(xCenter: xCenter, yCenter: yCenter, x: x, y: y)
    while (y >= x) {
        x += 1
        if d > 0 {
            y -= 1
            d = d + 4 * (x - y) + 10;
        } else {
            d = d + 4 * x + 6;
        }
        indexes += _circleBres(xCenter: xCenter, yCenter: yCenter, x: x, y: y)
    }
    return indexes.map { pair in
        pair.0 + (pair.1 * arrayWidth)
    }.map { abs($0) }
}

func drawLine(x1: Int, y1: Int, x2: Int, y2: Int) -> [(Int, Int)] {
    var x, y, dx, dy, dx1, dy1, px, py, xe, ye: Int
    dx = x2 - x1
    dy = y2 - y1
    
    dx1 = abs(dx)
    dy1 = abs(dy)
    px = 2 * dy1 - dx1
    py = 2 * dx1 - dy1
    
    var results: [(Int, Int)] = []
    
    // Line is x-axis dominant
    if dy1 <= dx1 {       
        if dx >= 0 {  // Line is drawn left to right
            x = x1
            y = y1
            xe = x2
        } else {
            x = x2
            y = y2
            xe = x1
        }
        results.append((x, y))

        while x < xe {
            x += 1
            if px < 0 {
                px = px + 2 * dy1
            } else {
                if (dx < 0 && dy < 0) || (dx > 0 && dy > 0) {
                    y += 1
                } else {
                    y -= 1
                }
                px = px + 2 * (dy1 - dx1)
            }
            results.append((x, y))
        }
    } else { // Line is y-axis dominant
        if dy >= 0 {
            x = x1
            y = y1
            ye = y2
        } else { // Line is drawn top to bottom
            x = x2
            y = y2
            ye = y1
        }
        results.append((x, y))
        while y < ye {
            y += 1
            if py <= 0 {
                py = py + 2 * dx1
            } else {
                if ((dx < 0 && dy < 0) || (dx > 0 && dy > 0)) {
                    x += 1
                } else {
                    x -= 1
                }
                py = py + 2 * (dx1 - dy1)
            }
            results.append((x, y))
        }
    }
    return results
}

/*
 def flood(im, p, color):
    oldCol = im.getpixel(p)
    if oldCol == color: return
    A = Queue()
    im.putpixel(p, color)
    A.enqueue(p)
    while not A.is_empty():
        q = A.dequeue()
        for r in neighbors(im, q):
            if im.getpixel(r) == oldCol:
                im.putpixel(r, color)
                A.enqueue(r)
 */

/*
 var fillStack = [];
 function fillMatrix2(matrix, row, col)
 {
     fillStack.push([row, col]);

     while(fillStack.length > 0)
     {
         var [row, col] = fillStack.pop();

         if (!validCoordinates(matrix, row, col))
             continue;

         if (matrix[row][col] == 1)
             continue;

         matrix[row][col] = 1;

         fillStack.push([row + 1, col]);
         fillStack.push([row - 1, col]);
         fillStack.push([row, col + 1]);
         fillStack.push([row, col - 1]);
     }
 }
 */

//func fill(at i: Int, width: Int, newColor: Color, data: [Color]) -> [Int] {
//    let oldColor = data[i]
//
//    guard oldColor != newColor else { return }
//
//    var indexes = [i]
//
////    func validCoordinates(matrix, row, col) {
////        return (row >= 0 && row < matrix.length && col >= 0 && col < matrix[row].length);
////    }
//
//    func _fill() {
//        var i = indexes.removeLast()
//
//        guard i >= 0 && i < data.count else { continue }
//
//        indexes.append(<#T##newElement: Int##Int#>)
//    }
//}
//
////
//func floodFill(at index: Int, width: Int, newColor: Color, data: [Color]) -> [Int] {
//    let oldColor = data[index] // the color the user selected, to be replaced by the new color
//    var data = data // make a copy that we will begin modifying
//
//    guard newColor != oldColor else { return [] }
//
//    var indexes = [index]
//
//    while !indexes.isEmpty {
//        data[index]
//    }
//}

extension Bitmap {
    
    func floodFill(x: Int, y: Int, newColor: Color) {
        
    }
}

func floodFill(index: Int, arrayWidth: Int, newColor: Color, oldColor: Color, data: [Color]) -> [Int] {
    var results: [Int] = []
    var data = data
    
    func floodFillRecursively(_ i: Int, oldColor: Color, newColor: Color) {
        guard i >= 0 && i < data.count else { return }

        if data[i] == oldColor {
            data[i] = newColor
            results.append(i)
            if i % (arrayWidth) != 0 {
                floodFillRecursively(i - 1, oldColor: oldColor, newColor: newColor)
            }
            if i % arrayWidth != arrayWidth - 1 {
                floodFillRecursively(i + 1, oldColor: oldColor, newColor: newColor)
            }
//            if i / arrayWidth > 0 {
                floodFillRecursively(i - arrayWidth, oldColor: oldColor, newColor: newColor)
//            }
//            if i < (data.count - arrayWidth) {
                floodFillRecursively(i + arrayWidth, oldColor: oldColor, newColor: newColor)
//            }
        }
    }
    
    floodFillRecursively(index, oldColor: oldColor, newColor: newColor)
    return results
}

func _circ(bitmap: Bitmap, centerX: Int, centerY: Int, radius: Int, color: Color) -> Bitmap {
 
    var bitmap = bitmap
    
    var d = (5 - radius * 4) / 4
    var x = 0
    var y = radius
    
    while x <= y {
        if centerX + x >= 0, centerX + x <= bitmap.width - 1, centerY + y >= 0, centerY + y <= bitmap.height - 1 {
            bitmap[centerX + x, centerY + y] = color
        }
        if centerX + x >= 0, centerX + x <= bitmap.width - 1, centerY - y >= 0, centerY - y <= bitmap.height - 1 {
            bitmap[centerX + x, centerY - y] = color
        }
        if centerX - x >= 0, centerX - x <= bitmap.width - 1, centerY + y >= 0, centerY + y <= bitmap.height - 1 {
            bitmap[centerX - x, centerY + y] = color
        }
        
        if centerX - x >= 0, centerX - x <= bitmap.width - 1 && centerY - y >= 0 && centerY - y <= bitmap.height - 1 {
            bitmap[centerX - x, centerY - y] = color;
        }
        if centerX + y >= 0 && centerX + y <= bitmap.width - 1 && centerY + x >= 0 && centerY + x <= bitmap.height - 1 {
            bitmap[centerX + y, centerY + x] = color
        }
        if centerX + y >= 0 && centerX + y <= bitmap.width - 1 && centerY - x >= 0 && centerY - x <= bitmap.height - 1 {
            bitmap[centerX + y, centerY - x] = color
        }
        if centerX - y >= 0 && centerX - y <= bitmap.width - 1 && centerY + x >= 0 && centerY + x <= bitmap.height - 1 {
            bitmap[centerX - y, centerY + x] = color
        }
        if centerX - y >= 0 && centerX - y <= bitmap.width - 1 && centerY - x >= 0 && centerY - x <= bitmap.height - 1 {
            bitmap[centerX - y, centerY - x] = color
        }
        
        if d < 0 {
            d += 2 * x + 1
        } else {
            d += 2 * (x - y) + 1
            y -= 1
        }
        
        x += 1
    }
    
    return bitmap
}

func fill(with newColor: Color, at index: Int, in bitmap: Bitmap) -> [Int] {
    
    var copy = bitmap

    let oldColor = bitmap.pixels[index]
    
    if oldColor == newColor { return [] } // Exit early
    
    func isValid(_ i: Int) -> Bool {
        i >= 0 && i < copy.pixels.count && copy.pixels[i] == oldColor
    }
    
    var indexQueue: [Int] = [index]

    var allIndexes: Set<Int> = [index]
    
    while indexQueue.isNotEmpty {
        let index = indexQueue.removeLast()
        copy.pixels[index] = newColor
        
        let above = index + bitmap.width
        let below = index - bitmap.width
        let right = index + 1
        let left  = index - 1
        
        if isValid(above) {
            indexQueue.append(above)
            allIndexes.insert(above)
        }
        if isValid(below) {
            indexQueue.append(below)
            allIndexes.insert(below)
        }
        if isValid(left) {
            // Don't go past left edge
            if left % bitmap.width < index % bitmap.width {
                indexQueue.append(left)
                allIndexes.insert(left)
            }
        }
        if isValid(right) {
            // Don't go past right edge
            if right % bitmap.width > index % bitmap.width {
                indexQueue.append(right)
                allIndexes.insert(right)
            }
        }
    }
        
    return allIndexes.shuffled()
}

extension Collection {
    
    var isNotEmpty: Bool {
        !isEmpty
    }
}

typealias Point = (Int, Int)

//private func circlePoints(centerX cx: Int, centerY cy: Int, x: Int, y: Int) -> [Point] {
//    var points: [Point] = []
//    if x == 0 {
//        points = [(cx, cy + y),
//                  (cx, cy - y),
//                  (cx + y, cy),
//                  (cx - y, cy)]
//    } else if x == y {
//        points = [(cx + x, cy + y),
//                  (cx - x, cy + y),
//                  (cx + x, cy - y),
//                  (cx - x, cy - y)]
//    } else if x < y {
//        points = [(cx + x, cy + y),
//                  (cx - x, cy + y),
//                  (cx + x, cy - y),
//                  (cx - x, cy - y),
//                  (cx + y, cy + x),
//                  (cx - y, cy + x)
//                  (cx + y, cy - x)
//                  (cx - y, cy - x)]
//    }
//    return points
//}

//func circle(centerX: Int, centerY: Int, radius: Int) {
//
//    let x = 0
//    let y = radius
//    let p = (5 - radius * 4) / 4
//
//    var points = circlePoints(centerX: centerX, centerY: centerY, x: x, y: y)
//
//    while (x < y) {
//        x += 1
//        if (p < 0) {
//            p += 2 * x + 1
//        } else {
//            y -= 1
//            p += 2 * (x - y) + 1
//        }
//        points.append(contentsOf: circlePoints(centerX: centerX, centerY: centerY, x: x, y: y))
//    }
//    return points.map {
//
//    }
//}

/*
 
 
 
 private final void circlePoints(int cx, int cy, int x, int y, int pix)
     {
         int act = Color.red.getRGB();
         
         if (x == 0) {
             raster.setPixel(act, cx, cy + y);
             raster.setPixel(pix, cx, cy - y);
             raster.setPixel(pix, cx + y, cy);
             raster.setPixel(pix, cx - y, cy);
         } else
         if (x == y) {
             raster.setPixel(act, cx + x, cy + y);
             raster.setPixel(pix, cx - x, cy + y);
             raster.setPixel(pix, cx + x, cy - y);
             raster.setPixel(pix, cx - x, cy - y);
         } else
         if (x < y) {
             raster.setPixel(act, cx + x, cy + y);
             raster.setPixel(pix, cx - x, cy + y);
             raster.setPixel(pix, cx + x, cy - y);
             raster.setPixel(pix, cx - x, cy - y);
             raster.setPixel(pix, cx + y, cy + x);
             raster.setPixel(pix, cx - y, cy + x);
             raster.setPixel(pix, cx + y, cy - x);
             raster.setPixel(pix, cx - y, cy - x);
         }
     }

     public void circleMidpoint(int xCenter, int yCenter, int radius, Color c)
     {
         int pix = c.getRGB();
         int x = 0;
         int y = radius;
         int p = (5 - radius*4)/4;

         circlePoints(xCenter, yCenter, x, y, pix);
         while (x < y) {
             x++;
             if (p < 0) {
                 p += 2*x+1;
             } else {
                 y--;
                 p += 2*(x-y)+1;
             }
             circlePoints(xCenter, yCenter, x, y, pix);
         }
     }
 */


/*
func midpointEllipse(majorRadius: Int, minorRadius: Int, centerX: Int, centerY: Int) -> [Point] {
    
    func makePoints(x: Int, xc: Int, y: Int, yc: Int) -> [(Int, Int)] {
        [(x + xc, y + yc),
         (-x + xc, y + yc),
         (x + xc, -y + yc),
         (-x + xc, -y + yc)]
    }
    
    var dx, dy, d1, d2, x, y: Double
    x = 0
    y = Double(minorRadius)
    var ry = minorRadius
    var rx = majorRadius
    
    // Initial decision parameter of region 1
    d1 = (ry * ry) - (rx * rx * ry) + (0.25 * rx * rx)
    dx = 2 * ry * ry * x
    dy = 2 * rx * rx * y

    var points: [Point]
    // For region 1
    while (dx < dy) {
        
        // make points
        points.append(contentsOf: makePoints(x: x, xc: centerX, y: y, yc: centerY))
        
        if (d1 < 0) {
            x += 1
            dx = dx + (2 * ry * ry)
            d1 = d1 + dx + (ry * ry)
        }
        else {
            x += 1
            y -= 1
            dx = dx + (2 * ry * ry);
            dy = dy - (2 * rx * rx);
            d1 = d1 + dx - dy + (ry * ry)
        }
    }
    
    // Decision parameter of region 2
    d2 = ((ry * ry) * ((x + 0.5) * (x + 0.5))) +
        ((rx * rx) * ((y - 1) * (y - 1))) -
        (rx * rx * ry * ry)

    // Plotting points of region 2
    while (y >= 0) {
        
        points.append(contentsOf: makePoints(x: x, xc: centerX, y: y, yc: centerY))

        if (d2 > 0) {
            y -= 1
            dy = dy - (2 * rx * rx)
            d2 = d2 + (rx * rx) - dy
        } else {
            y -= 1
            x += 1
            dx = dx + (2 * ry * ry)
            dy = dy - (2 * rx * rx)
            d2 = d2 + dx - dy + (rx * rx)
        }
    }
    
    return points
}
*/

func ellipse(rx: Double, ry: Double, xc: Double, yc: Double, w: Int) -> [Int] {
    var dx, dy, d1, d2, x, y: Double
    x = 0
    y = ry

    // Initial decision parameter of region 1
    d1 = (ry * ry) - (rx * rx * ry) +
                (0.25 * rx * rx)
    dx = 2 * ry * ry * x
    dy = 2 * rx * rx * y

    var points: [(Double, Double)] = []
    
    // For region 1
    while dx < dy {
        

        points.append(contentsOf: [(x + xc, y + yc),
                                   (-x + xc, y + yc),
                                   (x + xc, -y + yc),
                                   (-x + xc, -y + yc)])

        // Checking and updating value of
        // decision parameter based on algorithm
        if (d1 < 0) {
            x += 1
            dx = dx + (2 * ry * ry)
            d1 = d1 + dx + (ry * ry)
        }
        else {
            x += 1
            y -= 1
            dx = dx + (2 * ry * ry)
            dy = dy - (2 * rx * rx)
            d1 = d1 + dx - dy + (ry * ry)
        }
    }

    // Decision parameter of region 2
    d2 = ((ry * ry) * ((x + 0.5) * (x + 0.5))) +
        ((rx * rx) * ((y - 1) * (y - 1))) -
        (rx * rx * ry * ry)

    // Plotting points of region 2
    while y >= 0 {

        points.append(contentsOf: [(x + xc, y + yc),
                                   (-x + xc, y + yc),
                                   (x + xc, -y + yc),
                                   (-x + xc, -y + yc)])

        // Checking and updating parameter
        // value based on algorithm
        if (d2 > 0)
        {
            y -= 1
            dy = dy - (2 * rx * rx);
            d2 = d2 + (rx * rx) - dy;
        }
        else
        {
            y -= 1
            x += 1
            dx = dx + (2 * ry * ry)
            dy = dy - (2 * rx * rx)
            d2 = d2 + dx - dy + (rx * rx)
        }
    }
    return points.map { Int($0) + (Int($1) * w) }
//    return points.map { $0 + ($1 * 16) } // 16 = width. change this
}

/*
// Javascript program for implementing
// Mid-Point Ellipse Drawing Algorithm
function midptellipse(rx, ry, xc, yc)
{
    var dx, dy, d1, d2, x, y;
    x = 0;
    y = ry;

    // Initial decision parameter of region 1
    d1 = (ry * ry) - (rx * rx * ry) +
                (0.25 * rx * rx);
    dx = 2 * ry * ry * x;
    dy = 2 * rx * rx * y;

    // For region 1
    while (dx < dy)
    {
        
        // Print points based on 4-way symmetry
        document.write("(" + (x + xc).toFixed(5) +
                    " , " + (y + yc).toFixed(5) +
                    ")" + "<br>");
        document.write("(" + (-x + xc).toFixed(5) +
                    " , " + (y + yc).toFixed(5) +
                    ")" + "<br>");
        document.write("(" + (x + xc).toFixed(5) +
                    " , " + (-y + yc).toFixed(5) +
                    ")" + "<br>");
        document.write("(" + (-x + xc).toFixed(5) +
                    " , " + (-y + yc).toFixed(5) +
                    ")" + "<br>");

        // Checking and updating value of
        // decision parameter based on algorithm
        if (d1 < 0)
        {
            x++;
            dx = dx + (2 * ry * ry);
            d1 = d1 + dx + (ry * ry);
        }
        else
        {
            x++;
            y--;
            dx = dx + (2 * ry * ry);
            dy = dy - (2 * rx * rx);
            d1 = d1 + dx - dy + (ry * ry);
        }
    }

    // Decision parameter of region 2
    d2 = ((ry * ry) * ((x + 0.5) * (x + 0.5))) +
        ((rx * rx) * ((y - 1) * (y - 1))) -
        (rx * rx * ry * ry);

    // Plotting points of region 2
    while (y >= 0)
    {

        // Print points based on 4-way symmetry
        document.write("(" + (x + xc).toFixed(5) +
                    " , " + (y + yc).toFixed(5) +
                    " )" + "<br>");
        document.write("(" + (-x + xc).toFixed(5) +
                    " , " + (y + yc).toFixed(5) +
                    ")" + "<br>");
        document.write("(" + (x + xc).toFixed(5) +
                    " , " + (-y + yc).toFixed(5) +
                    ")" + "<br>");
        document.write("(" + (-x + xc).toFixed(5) +
                    " , " + (-y + yc).toFixed(5) +
                    ")" + "<br>");

        // Checking and updating parameter
        // value based on algorithm
        if (d2 > 0)
        {
            y--;
            dy = dy - (2 * rx * rx);
            d2 = d2 + (rx * rx) - dy;
        }
        else
        {
            y--;
            x++;
            dx = dx + (2 * ry * ry);
            dy = dy - (2 * rx * rx);
            d2 = d2 + dx - dy + (rx * rx);
        }
    }
}

// To draw a ellipse of major and
// minor radius 15, 10 centered at (50, 50)
midptellipse(10, 15, 50, 50);

// This code is contributed by akshitsaxenaa09

*/
