// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import SwiftUI

class CoreDataStack {
    
    private let containerName: String
    let undoManager: UndoManager
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    var coordinator: NSPersistentStoreCoordinator { persistentContainer.persistentStoreCoordinator }

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentCloudKitContainer(name: containerName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print(error.localizedDescription)
            }
            print(storeDescription)
        })
        return container
    }()
    
    init(containerName: String, undoManager: UndoManager) {
        self.containerName = containerName
        self.undoManager = undoManager
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.undoManager = undoManager
        do {
            try persistentContainer.viewContext.setQueryGenerationFrom(.current)
        } catch {
            print("###\(#function): Failed to pin viewContext to the current generation: \(error)")
        }
    }
    
    func onBackground(do work: @escaping (NSManagedObjectContext) -> ()) {
        persistentContainer.performBackgroundTask(work)
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
