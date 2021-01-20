// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ObjectStore

extension IndexedList {
    static func load(from store: ObjectStore, idKey id: String, completion: @escaping (Result<Self,Error>) -> ()) where Value.ID == String {
        indexedListChannel.log("Loading index for \(id)")
        store.load([String].self, withId: id) { result in
            switch result {
                case let .failure(error):
                    completion(.failure(error))

                case let .success(ids):
                    indexedListChannel.log("Loading objects \(ids) for \(id)")
                    store.load(Value.self, withIds: ids) { objects, errors in
                        indexedListChannel.log("Loaded objects \(ids) for \(id)")
                        var index: [Value.ID:Value] = [:]
                        for object in objects {
                            index[object.id] = object
                        }
                        completion(.success(Self(order: ids, index: index)))
                    }
            }
        }
    }
    
    func save(to store: ObjectStore, idKey id: String, completion: @escaping (Bool) -> ()) where Value.ID == String {
        store.save(order, withId: id) { result in
            switch result {
                case .failure:
                    completion(false)
                    
                case .success:
                    store.save(Array(index.values)) { results in
                        completion(results.count == 0)
                    }
            }
        }
    }
}
