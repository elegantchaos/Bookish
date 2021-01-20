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
        
        var recordIDs: [CKRecord.ID] = []
        for id in ids {
            recordIDs.append(CKRecord.ID(recordName: id))
        }
        
        let fetch = CKFetchRecordsOperation()
        fetch.recordIDs = recordIDs
        fetch.fetchRecordsCompletionBlock = { records, error in
            // TODO: batch up the loading
            var loaded: [T] = []
            var errors: [String:Error] = [:]
            
            if let records = records {
                for record in records {
                    let id = record.key.recordName
                    if let data = record.value["data"] as? Data {
                        do {
                            let decoded = try coder.decodeObject(type, from: data)
                            loaded.append(decoded)
                        } catch {
                            errors[id] = error
                        }
                    } else {
                        errors[id] = StoreError.couldntDecodeData
                    }
                }
            }
            
            if let error = (error as (NSError?)), error.code == CKError.Code.partialFailure.rawValue, let partialErrors = error.userInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID : Error] {
                for error in partialErrors {
                    let id = error.key.recordName
                    errors[id] = error.value
                }
            }
            
            DispatchQueue.main.async {
                completion(loaded, errors)
            }
        }
        database.add(fetch)
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
        
        var totalDone = 0
        save(records: records, batchSize: records.count) { done in
            cloudKitStoreChannel.log("Saved \(done) records.")
            totalDone += done
            if totalDone == ids.count {
                cloudKitStoreChannel.log(errors.count == 0 ? "Saving done for \(ids)" : "Saving produced errors: \(errors)")
                completion(errors)
            }
        }
    }

    public func remove(objectsWithIds ids: [String], completion: ([String : Error]) -> ()) {
        
    }
    
    
    public func save(records: [CKRecord], batchSize: Int, completion: @escaping (Int) -> ()) {
        cloudKitStoreChannel.log("Saving \(records.count) records in batches of \(batchSize).")
        var remaining = records
        while remaining.count > 0 {
            let count = min(batchSize, remaining.count)
            let batch = Array(remaining[0 ..< count])
            remaining.removeFirst(count)

            cloudKitStoreChannel.log("Saving batch of \(count).")
            let operation = CKModifyRecordsOperation()
            operation.recordsToSave = batch
            operation.savePolicy = .allKeys
            operation.queuePriority = .high
            operation.modifyRecordsCompletionBlock = { _, _, error in
                if let error = (error as (NSError?)), error.code == CKError.Code.limitExceeded.rawValue {
                    let newBatchSize = batchSize / 2
                    cloudKitStoreChannel.log("Retrying with batchSize of \(newBatchSize)")
                    save(records: batch, batchSize: newBatchSize, completion: completion)
                } else {
                    completion(count)
                }
            }
            database.add(operation)
        }
    }
}
