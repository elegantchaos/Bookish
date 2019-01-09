// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import BookishModel
import Ensembles

@objc class BookishSynchroniser: NSObject, CDEPersistentStoreEnsembleDelegate {
  
    var managedObjectContext: NSManagedObjectContext
    var cloudFileSystem: CDECloudKitFileSystem
    var ensemble: CDEPersistentStoreEnsemble!
    
    init(context: NSManagedObjectContext, storeURL: URL) {
        managedObjectContext = context
        
        // Setup Ensemble
        let modelURL = BookishModel.modelURL()
        cloudFileSystem = CDECloudKitFileSystem(privateDatabaseForUbiquityContainerIdentifier: "blah", schemaVersion: .version2)
        ensemble = CDEPersistentStoreEnsemble(ensembleIdentifier: "NumberStore", persistentStore: storeURL, managedObjectModelURL: modelURL, cloudFileSystem: cloudFileSystem)
        super.init()
        
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
