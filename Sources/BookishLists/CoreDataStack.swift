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
}
