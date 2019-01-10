// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import BookishCore
import BookishModel
import Ensembles

class SyncedCollection: BookishCollection, CDEPersistentStoreEnsembleDelegate {
  
    var cloudFileSystem: CDECloudKitFileSystem
    var ensemble: CDEPersistentStoreEnsemble!
    
    init(identifier: String) {
        cloudFileSystem = CDECloudKitFileSystem(privateDatabaseForUbiquityContainerIdentifier: identifier, schemaVersion: .version2)
        super.init()
        
    }
    
    func configure(for url: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [String : Any]? = nil) {
        super.configure(for: url)
        let modelURL = BookishModel.modelURL()
        ensemble = CDEPersistentStoreEnsemble(ensembleIdentifier: "DefaultCollection", persistentStore: url, managedObjectModelURL: modelURL, cloudFileSystem: cloudFileSystem)
        ensemble.delegate = self
    }
    
    func sync(_ completion: (() -> Void)?) {
        //        let viewController = self.window?.rootViewController as! ViewController
        //        viewController.activityIndicator?.startAnimating()
        if !ensemble.isLeeched {
            ensemble.leechPersistentStore {
                error in
                //                viewController.activityIndicator?.stopAnimating()
                //                viewController.refresh()
                if error == nil {
                    self.sync(completion) // Trigger first merge
                }
                else {
                    completion?()
                }
            }
        }
        else {
            ensemble.merge {
                error in
                //                viewController.activityIndicator?.stopAnimating()
                //                viewController.refresh()
                completion?()
            }
        }
    }
    
    
    public func load(url: URL, usingSample: Bool = false) {
        configure(for: url, ofType: NSSQLiteStoreType, modelConfiguration: nil)
        if usingSample {
            BookishCollection.setupTestDocument(context: managedObjectContext)
            save()
        }
    }

    func deleteStores(remove: Bool = false) {
        let fm = FileManager.default
        if let coordinator = managedObjectContext.persistentStoreCoordinator {
            for store in coordinator.persistentStores {
                if let url: URL = store.url {
                    do {
                        try coordinator.destroyPersistentStore(at: url, ofType: store.type, options: nil)
                        if remove && fm.fileExists(atPath: url.path) {
                            try? fm.removeItem(at: url)
                        }
                    } catch {
                        print("failed to delete previous database")
                    }
                }
                try? coordinator.remove(store)
            }
        }
    }
    
    public func delete() {
        managedObjectContext.reset()
        managedObjectContext.processPendingChanges()
        deleteStores()
        ensemble.dismantle()
    }
    
//    public func reset() {
//        managedObjectContext.reset()
//        managedObjectContext.processPendingChanges()
//        deleteStores(remove: true)
//        loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//
//        BookishCollection.setupTestDocument(context: managedObjectContext)
//    }
    
    public func save() {
        let context = managedObjectContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    private func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWith notification: Notification) {
        managedObjectContext.performAndWait {
            self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    private func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, globalIdentifiersFor objects: [NSManagedObject]) -> [NSObject] {
        let numberHolders = objects as! [ModelObject]
        return numberHolders.map { $0.uniqueIdentifier }
    }

}
