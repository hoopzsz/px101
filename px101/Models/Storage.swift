//
//  Storage.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-21.
//

import UIKit
import CoreData

struct Storage {
    
    static func saveBitmap(_ bitmap: Bitmap, project: Project) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest = BitmapObject.fetchRequest()

        fetchRequest.predicate = NSPredicate(format: "id = %@", bitmap.id.uuidString)
        let results = try? context.fetch(fetchRequest)
        
        let object: BitmapObject
        if results?.count == 0 {
            object = BitmapObject(context: context)
        } else {
            object = results!.first!
        }
        object.id = bitmap.id
        object.width = Int16(bitmap.width)
        object.zIndex = Int16(bitmap.zIndex)
        object.name = bitmap.name
        object.lastUpdateDate = bitmap.lastUpdatedDate
        object.creationDate = bitmap.creationDate
        object.isHidden = bitmap.isHidden
        object.pixels = try! JSONEncoder().encode(bitmap.pixels)

        let projectFetch = ProjectObject.fetchRequest()
        projectFetch.predicate = NSPredicate(format: "id = %@", project.id.uuidString)
        
        object.toProject = try? context.fetch(projectFetch).first

        do {
            try context.save()
        } catch {
            print("Unable to Save Bitmap, \(error)")
        }
    }
}

extension NSFetchRequest {
    
    @objc convenience init(predicate: NSPredicate) {
        self.init()
        self.predicate = predicate
    }
}

extension Storage {
    
    static func loadProject(_ id: UUID) -> ProjectObject? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = ProjectObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", id.uuidString)
        return try? context.fetch(fetchRequest).first
    }
    
    static func saveProject(_ project: Project) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
//        let context = persistentContainer.viewContext
        let fetchRequest = ProjectObject.fetchRequest()

        fetchRequest.predicate = NSPredicate(format: "id = %@", project.id.uuidString)
        let results = try? context.fetch(fetchRequest)
        
        let projectObject: ProjectObject
        if results?.count == 0 {
            projectObject = ProjectObject(context: context)
        } else {
            projectObject = results!.first!
        }
        projectObject.id = project.id
        projectObject.width = Int16(project.width)
        projectObject.height = Int16(project.height)
        projectObject.creationDate = project.creationDate
        projectObject.lastUpdateDate = project.lastUpdateDate

//        let bitmapsFetchRequest = BitmapObject.fetchRequest()
//        bitmapsFetchRequest.predicate = NSPredicate(format: "toProject = %@", projectObject)
//        if let result = try? context.fetch(bitmapsFetchRequest) {
//            projectObject.setBitmaps(result)
//        }

        do {
            try context.save()
        } catch {
            print("Unable to Save Bitmap, \(error)")
        }
    }
}
