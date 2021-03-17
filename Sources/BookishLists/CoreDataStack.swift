// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import SwiftUI

class CoreDataStack {
    
    private let containerName: String
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
    
    init(containerName: String) {
        self.containerName = containerName
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try persistentContainer.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
        }
    }
    
    func onBackground(do work: @escaping (NSManagedObjectContext, @escaping ()->()) -> ()) {
        let mainContext = viewContext
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            var watcher = NotificationCenter.default
                .publisher(for: .NSManagedObjectContextDidSave, object: context)
                .sink { notification in
                    mainContext.mergeChanges(fromContextDidSave: notification)
                }
            
            work(context) {
                do {
                    try context.save()
                } catch {
                    print("Failed to save changes to background context")
                }
            }
        }
    }
}
