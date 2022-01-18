//
//  BookishInterchangeImporter.swift
//  BookishLists
//
//  Created by Sam Deane on 18/01/2022.
//

import BookishCore
import BookishImporter
import Logger
import UniformTypeIdentifiers
import SwiftUI

let bookRecordsImporterChannel = Channel("BookishInterchangeImporter")

public class BookishInterchangeImporter: Importer {
    override class public var id: String { return "com.elegantchaos.bookish.importer.interchange" }

    public override var fileTypes: [UTType]? {
        return [BookishInterchangeDocument.bookishType]
    }
    
    override open func makeSession(source: Any, delegate: ImportDelegate) -> ImportSession? {
        guard let url = source as? URL, url.pathExtension == "bookish" else { return nil }
        let session = BookRecordsImportSession(importer: self, url: url, delegate: delegate)
        return session
    }
}

public class BookRecordsImportSession: ImportSession {
    public static func == (lhs: BookRecordsImportSession, rhs: BookRecordsImportSession) -> Bool {
        return lhs === rhs
    }
    
    let url: URL
    
    public init?(importer: Importer, url: URL, delegate: ImportDelegate) {
        self.url = url
        super.init(importer: importer, delegate: delegate)
    }
    
    override open func run() {
        let records: [BookRecord] = []
        delegate.session(self, willImportItems: records.count)
        for book in records {
            bookRecordsImporterChannel.log("Imported \(book.title)")
            delegate.session(self, didImport: book)
        }
        delegate.sessionDidFinish(self)
    }
}
