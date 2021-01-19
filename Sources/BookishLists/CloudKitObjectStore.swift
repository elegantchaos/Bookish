// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CloudKit
import Foundation
import ObjectStore

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

//    func file(forId id: String) -> File {
//        return root.file(id)
//    }
    
    public func load<T>(_ type: T.Type, withIds ids: [String], completion: @escaping ([T], [String : Error]) -> ()) where T : Decodable {
        var loaded: [T] = []
        var errors: [String:Error] = [:]
        
        func store(_ error: Error, for id: String) {
            errors[id] = error
            completeIfDone()
        }
        
        func store(_ object: T) {
            loaded.append(object)
            completeIfDone()
        }
        
        func completeIfDone() {
            if loaded.count + errors.count == ids.count {
                completion(loaded, errors)
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
    
    public func save<T>(_ objects: [T], withIds ids: [String], completion: ([String : Error]) -> ()) where T : Encodable {
        assert(objects.count == ids.count)
        
        var records: [CKRecord] = []
        for (object, id) in zip(objects, ids) {
            do {
                let data = try coder.encodeObject(object)
                let record = CKRecord(recordType: "Object", recordID: CKRecord.ID(recordName: id))
                record.setValuesForKeys([
                    "data": data
                ])
                records.append(record)
            } catch {
                print(error)
            }
        }
        
        let operation = CKModifyRecordsOperation()
        operation.recordsToSave = records
        operation.savePolicy = .changedKeys
        operation.completionBlock = {
            
        }
        database.add(operation)
    }

    public func remove(objectsWithIds ids: [String], completion: ([String : Error]) -> ()) {
        
    }
}
