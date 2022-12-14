//
//  BitmapObject+CoreDataProperties.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-10.
//
//

import Foundation
import CoreData


extension BitmapObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BitmapObject> {
        return NSFetchRequest<BitmapObject>(entityName: "BitmapObject")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var pixels: Data?
    @NSManaged public var width: Int16
    @NSManaged public var zIndex: Int16
    @NSManaged public var lastUpdateDate: Date?
    @NSManaged public var creationDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var palette: Data?
    @NSManaged public var isHidden: Bool

    @NSManaged public var toProject: ProjectObject?

}

extension BitmapObject : Identifiable {

}

extension BitmapObject {
    
    func update(with bitmap: Bitmap) {
        id = bitmap.id
        name = bitmap.name
        width = Int16(bitmap.width)
        zIndex = Int16(bitmap.zIndex)
        isHidden = bitmap.isHidden
        creationDate = bitmap.creationDate
        lastUpdateDate = bitmap.lastUpdateDate
        pixels = try! JSONEncoder().encode(bitmap.pixels)
        // TODO palette
    }
}
