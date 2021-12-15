// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

protocol FetchProvider {
    static var kind: CDRecord.Kind { get }
}

extension FetchProvider {
    static func request() -> NSFetchRequest<CDRecord> {
        let request: NSFetchRequest<CDRecord> = CDRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.predicate = NSPredicate(format: "kindCode == \(kind.rawValue)")
        return request
    }
}

class BookFetchProvider: FetchProvider {
    static var kind: CDRecord.Kind { .book }
}

class PersonFetchProvider: FetchProvider {
    static var kind: CDRecord.Kind { .person }
}

class PublisherFetchProvider: FetchProvider {
    static var kind: CDRecord.Kind { .publisher }
}

class SeriesFetchProvider: FetchProvider {
    static var kind: CDRecord.Kind { .series }
}
