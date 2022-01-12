// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import SwiftUI

class CoreDataStack {
    
    private let undoManager: UndoManager
    private let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    var coordinator: NSPersistentStoreCoordinator { persistentContainer.persistentStoreCoordinator }
    
    class func makeContainer(name: String) -> NSPersistentContainer {
        let container = NSPersistentCloudKitContainer(name: name)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print(error.localizedDescription)
            }
            print(storeDescription)
        })
        return container
    }
    
    init(containerName: String, undoManager: UndoManager) {
        let container = Self.makeContainer(name: containerName)
        self.undoManager = undoManager
        self.persistentContainer = container
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = undoManager
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            print("###\(#function): Failed to pin viewContext to the current generation: \(error)")
        }
    }
    
    func onBackground(do work: @escaping (NSManagedObjectContext) -> ()) {
        persistentContainer.performBackgroundTask(work)
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    func removeAllData() throws {
        let context = viewContext
        let entityNames = persistentContainer.managedObjectModel.entities.map({ $0.name!})
        for entity in entityNames {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try coordinator.execute(deleteRequest, with: context)
        }

        context.refreshAllObjects()
        try context.save()
    }
}
