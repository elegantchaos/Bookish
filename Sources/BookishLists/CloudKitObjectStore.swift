// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CloudKit
import Foundation
import Logger
import ObjectStore

let cloudKitStoreChannel = Channel("CloudKitStore")

public struct CloudKitObjectStore<CoderType>: ObjectStore where CoderType: ObjectCoder {
    let container: CKContainer
    let database: CKDatabase
    let coder: CoderType

    enum StoreError: Error {
        case couldntDecodeData
    }
    
    public init(container: CKContainer, coder: CoderType) {
        self.container = container
        self.database = container.privateCloudDatabase
        self.coder = coder
    }
    
    public func load<T>(_ type: T.Type, withIds ids: [String], completion: @escaping ([T], [String : Error]) -> ()) where T : Decodable {
        guard ids.count > 0 else {
            completion([], [:])
            return
        }
        
        cloudKitStoreChannel.log("Loading \(ids)")

        var loaded: [T] = []
        var errors: [String:Error] = [:]
        
        func store(_ error: Error, for id: String) {
            cloudKitStoreChannel.log("Load failed for \(id): \(error)")
            errors[id] = error
            completeIfDone()
        }
        
        func store(_ object: T) {
            cloudKitStoreChannel.log("Loaded \(object)")
            loaded.append(object)
            completeIfDone()
        }
        
        func completeIfDone() {
            if loaded.count + errors.count == ids.count {
                cloudKitStoreChannel.log(errors.count == 0 ? "Finished load of \(ids)." : "Finished load with errors: \(errors)")
                DispatchQueue.main.async {
                    completion(loaded, errors)
                }
            }
        }
        
        for id in ids {
            database.fetch(withRecordID: CKRecord.ID(recordName: id)) { record, error in
                if let error = error {
                    store(error, for: id)
                } else if let record = record, let data = record["data"] as? Data {
                    do {
                        let decoded = try coder.decodeObject(type, from: data)
                        store(decoded)
                    } catch {
                        store(error, for: id)
                    }
                } else {
                    store(StoreError.couldntDecodeData, for: id)
                }
            }
        }
    }
    
    public func save<T>(_ objects: [T], withIds ids: [String], completion: @escaping ([String : Error]) -> ()) where T : Encodable {
        assert(objects.count == ids.count)
        guard objects.count > 0 else {
            completion([:])
            return
        }
        
        cloudKitStoreChannel.log("Saving \(ids)")
        
        var records: [CKRecord] = []
        var errors: [String:Error] = [:]
        
        for (object, id) in zip(objects, ids) {
            do {
                let data = try coder.encodeObject(object)
                let record = CKRecord(recordType: "Object", recordID: CKRecord.ID(recordName: id))
                record.setValuesForKeys([
                    "data": data
                ])
                records.append(record)
            } catch {
                errors[id] = error
                cloudKitStoreChannel.log(error)
            }
        }
        
        let operation = CKModifyRecordsOperation()
        operation.recordsToSave = records
        operation.savePolicy = .allKeys
        operation.completionBlock = {
            cloudKitStoreChannel.log(errors.count == 0 ? "Saving done for \(ids)" : "Saving produced errors: \(errors)")
            completion(errors)
        }
        database.add(operation)
    }

    public func remove(objectsWithIds ids: [String], completion: ([String : Error]) -> ()) {
        
    }
}
