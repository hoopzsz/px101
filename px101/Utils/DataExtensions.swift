//
//  DataExtensions.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-18.
//

import Foundation

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
