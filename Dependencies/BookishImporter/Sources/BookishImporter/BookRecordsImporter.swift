// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Coercion
import Foundation
import ISBN
import Logger
import SwiftUI
import BookishCore

let bookRecordsImporterChannel = Channel("BookRecordsImporter")

public class BookRecordsImporter: Importer {
    override class public var id: String { return "com.elegantchaos.bookish.importer.records" }

    override open func makeSession(source: Any, delegate: ImportDelegate) -> ImportSession? {
        guard let records = source as? [BookRecord] else { return nil }

        let session = BookRecordsImportSession(importer: self, records: records, delegate: delegate)
        return session
    }
}

public class BookRecordsImportSession: ImportSession {
    public static func == (lhs: BookRecordsImportSession, rhs: BookRecordsImportSession) -> Bool {
        return lhs === rhs
    }
    
    let records: [BookRecord]
    
    init?(importer: Importer, records: [BookRecord], delegate: ImportDelegate) {
        self.records = records
        super.init(importer: importer, delegate: delegate)
    }
    
    override open func run() {
        delegate.session(self, willImportItems: records.count)
        for book in records {
            bookRecordsImporterChannel.log("Imported \(book.title)")
            delegate.session(self, didImport: book)
        }
        delegate.sessionDidFinish(self)
    }
}
