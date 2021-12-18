//
//  ShapeTools.swift
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

private func horizontalDistance(from a: Int, to b: Int, width: Int) -> Int {
    abs(a % width - b % width)
}

private func verticalDistance(from a: Int, to b: Int, width: Int) -> Int {
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

func circularIndexSet(initialIndex: Int, currentIndex: Int, arrayWidth: Int) -> [Int] {
    let horizontalLength = horizontalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)
    let verticalLength = verticalDistance(from: initialIndex, to: currentIndex, width: arrayWidth)

    let xCenter = horizontalLength / 2
    let yCenter = verticalLength / 2

    let leftIndex = currentIndex % arrayWidth > initialIndex % arrayWidth ? initialIndex : currentIndex
    let indexes = circleBres(xCenter: xCenter, yCenter: yCenter, radius: horizontalLength, arrayWidth: arrayWidth)
    return indexes.map {
        $0 + (leftIndex % arrayWidth) + ((leftIndex % arrayWidth) * arrayWidth)
    }
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
                if ((dx < 0 && dy<0) || (dx > 0 && dy > 0)) {
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

