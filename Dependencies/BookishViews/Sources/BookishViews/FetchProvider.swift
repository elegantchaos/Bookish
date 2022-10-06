// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

protocol FetchProvider {
    static var kind: RecordKind { get }
}

extension FetchProvider {
    static func request() -> NSFetchRequest<CDRecord> {
        let request = CDRecord.fetchRequest(
            predicate: NSPredicate(format: "kindCode == \(kind.rawValue)"),
            sort: [NSSortDescriptor(key: "name", ascending: true)]
        )
        return request
    }
}

class BookFetchProvider: FetchProvider {
    static var kind: RecordKind { .book }
}

class PersonFetchProvider: FetchProvider {
    static var kind: RecordKind { .person }
}

class PublisherFetchProvider: FetchProvider {
    static var kind: RecordKind { .publisher }
}

class SeriesFetchProvider: FetchProvider {
    static var kind: RecordKind { .series }
}
