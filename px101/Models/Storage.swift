//
//  Storage.swift
//  px101
//
//  Created by Daniel Hooper on 2022-02-21.
//

import UIKit
import CoreData

protocol _Storage {
    static func save(bitmap: Bitmap)
    static func save(project: Project)
    static func load(bitmap: UUID, sorting: [NSSortDescriptor]?)  -> Bitmap?
    static func load(project: UUID, sorting: [NSSortDescriptor]?) -> Project?
}

struct CoreDataStorage: _Storage {
    
    static func save(bitmap bitmapId: UUID, with projectId: UUID) {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            print("error fetching managed object context")
            return
        }

        let bitmapFetchRequest = BitmapObject.fetchRequest()

        bitmapFetchRequest.predicate = NSPredicate(format: "id = %@", bitmapId.uuidString)
        guard let bitmapObject = try? context.fetch(bitmapFetchRequest).first else {
            print("error fetching Bitmap \(bitmapId)\n")
            return
        }
        
        let projectFetchRequest = ProjectObject.fetchRequest()
        projectFetchRequest.predicate = NSPredicate(format: "id = %@", projectId.uuidString)
        guard let projectObject = try? context.fetch(projectFetchRequest).first else {
            print("error fetching Project \(projectId)\n")
            return
            
        }
        
        bitmapObject.toProject = projectObject
        projectObject.addToBitmaps(bitmapObject)
        
        do {
            try context.save()
        } catch {
            print("Unable to Save adding Bitmap \(bitmapId) to Project \(projectId), \(error)")
        }
        
    }
    
    static func save(bitmap: Bitmap) {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            print("error fetching managed object context")
            return
        }
        
        let request = BitmapObject.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", bitmap.id.uuidString)
        let results = try? context.fetch(request)
        let object = results?.first ?? BitmapObject(context: context)
        object.update(with: bitmap)
        if bitmap.id != object.id {
            print("saving new bitmap object \(object.id?.uuid)")
        }
        do {
            try context.save()
        } catch {
            print("Error saving Bitmap \(bitmap.id), \(error)")
        }
    }
    
    static func save(project: Project) {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            print("error fetching managed object context")
            return
        }
        
        let fetchRequest = ProjectObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", project.id.uuidString)
        let results = try? context.fetch(fetchRequest)
        let object = results?.first ?? ProjectObject(context: context)
        object.update(with: project)
        do {
            try context.save()
        } catch {
            print("Error saving Project \(project.id), \(error)")
        }
    }
    
    static func load(project id: UUID, sorting: [NSSortDescriptor]? = nil) -> Project? {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return nil }
        let request = ProjectObject.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id.uuidString)
        request.sortDescriptors = sorting
         
        do {
            let object = try context.fetch(request).first
            if let object = object, let id = object.id {
                print("loaded project object: \(id.uuidString)\n")
                return Project(object: object)

            } else {
                print("no project found for id: \(id.uuidString)\n")
                return nil
            }
        } catch {
            print("loading project error: \(error)\n")
            return nil
        }
    }
    
    static func load(bitmap id: UUID, sorting: [NSSortDescriptor]? = nil)  -> Bitmap? {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return nil }
        let request = BitmapObject.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id.uuidString)
        request.sortDescriptors = sorting
         
        do {
            let object = try context.fetch(request).first
            if let object = object, let id = object.id {
                print("loaded bitmap object: \(id.uuidString)\n")
                return Bitmap(object: object)
            } else {
                print("no bitmap found for id: \(id.uuidString)\n")
                return nil
            }
        } catch {
            print("loading bitmap error: \(error)\n")
            return nil
        }
    }
    
    static func loadAllBitmaps(project id: UUID, sorting: [NSSortDescriptor]? = nil) -> [Bitmap] {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return [] }
        
        let request = ProjectObject.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id.uuidString)
        request.sortDescriptors = sorting

        do {
            let projectObject = try context.fetch(request).first
            let bitmapObjects = projectObject?.bitmaps?.allObjects as? [BitmapObject]
            return bitmapObjects?.compactMap(Bitmap.init) ?? []
        } catch {
            print("loading objects error: \(error)\n")
            return []
        }
    }
}


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
        object.lastUpdateDate = bitmap.lastUpdateDate
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
