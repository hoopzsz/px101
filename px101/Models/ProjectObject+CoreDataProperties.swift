//
//  ProjectObject+CoreDataProperties.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-10.
//
//

import Foundation
import CoreData

extension ProjectObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectObject> {
        return NSFetchRequest<ProjectObject>(entityName: "ProjectObject")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var lastUpdateDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var id: UUID?
    @NSManaged public var width: Int16
    @NSManaged public var height: Int16
    @NSManaged public var palette: Data?
    @NSManaged public var bitmaps: NSSet?

}

// MARK: Generated accessors for bitmaps
extension ProjectObject {

    @objc(addBitmapsObject:)
    @NSManaged public func addToBitmaps(_ value: BitmapObject)

    @objc(removeBitmapsObject:)
    @NSManaged public func removeFromBitmaps(_ value: BitmapObject)

    @objc(addBitmaps:)
    @NSManaged public func addToBitmaps(_ values: NSSet)

    @objc(removeBitmaps:)
    @NSManaged public func removeFromBitmaps(_ values: NSSet)

}

extension ProjectObject : Identifiable {

    func setBitmaps(_ bitmaps: [BitmapObject]) {
        self.bitmaps = NSSet(array: bitmaps)
    }
}

extension ProjectObject {
    
    func update(with project: Project) {
        id = project.id
        name = project.name
        width = Int16(project.width)
        height = Int16(project.height)
        creationDate = project.creationDate
        lastUpdateDate = project.lastUpdateDate
        
        // TODO palette
    }
}
