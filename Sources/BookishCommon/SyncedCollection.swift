// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import BookishCore
import BookishModel
import Ensembles

class SyncedCollection: CollectionContainer, CDEPersistentStoreEnsembleDelegate {
  
    var cloudFileSystem: CDECloudKitFileSystem
    var ensemble: CDEPersistentStoreEnsemble?
    
    init(url: URL? = nil, name explicitName: String? = nil, identifier: String, mode: PopulateMode, shouldSync: Bool = true, callback: LoadedCallback? = nil) {
        let name = explicitName ?? UserDefaults.standard.string(forKey: "Collection") ?? "Default2"
        cloudFileSystem = CDECloudKitFileSystem(privateDatabaseForUbiquityContainerIdentifier: identifier, schemaVersion: .version2)
        super.init(name: name, url: url, mode: mode) { (collection, error) in
            if let error = error {
                fatalError("failed to load \(error)")
            }
            
            if shouldSync, let collection = collection as? SyncedCollection {
                collection.setupEnsemble()
                collection.setupListeners()
            }
            
            callback?(collection, error)
        }
    }

    func setupEnsemble() {
        CDESetCurrentLoggingLevel(CDELoggingLevel.warning.rawValue)

        if let url = persistentStoreDescriptions[0].url {
            let name = url.lastPathComponent
            let ensemble = CDEPersistentStoreEnsemble(ensembleIdentifier: name, persistentStore: url, managedObjectModelURL: BookishModel.modelURL(), cloudFileSystem: cloudFileSystem)
            ensemble.delegate = self
            self.ensemble = ensemble
        }
    }

    func setupListeners() {
        // Listen for local saves, and trigger merges
        NotificationCenter.default.addObserver(self, selector:#selector(SyncedCollection.localSaveOccurred(_:)), name:NSNotification.Name.CDEMonitoredManagedObjectContextDidSave, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(SyncedCollection.cloudDataDidDownload(_:)), name:NSNotification.Name.CDEICloudFileSystemDidDownloadFiles, object:nil)
    }
    
    func sync(_ completion: (() -> Void)? = nil) {
        guard let ensemble = ensemble else {
            completion?()
            return
        }

        if !ensemble.isLeeched {
            ensemble.leechPersistentStore { error in
                if error == nil {
                    self.sync(completion) // Trigger first merge
                }
                else {
                    completion?()
                }
            }
        }
        else {
            ensemble.merge { error in
                completion?()
            }
        }
    }

    override public func delete(remove: Bool = false) {
        ensemble?.dismantle()
        
        super.delete(remove: remove)
    }
    

    @objc private func localSaveOccurred(_ notif: Notification) {
        self.sync()
    }
    
    @objc private func cloudDataDidDownload(_ notif: Notification) {
        self.sync()
    }
    
    @objc public func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWith notification: Notification) {
        managedObjectContext.performAndWait {
            self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    @objc public func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, globalIdentifiersFor objects: [NSManagedObject]) -> [NSObject] {
        let numberHolders = objects as! [ModelObject]
        let identifiers = numberHolders.map { $0.uniqueIdentifier }
        return identifiers
    }

}
