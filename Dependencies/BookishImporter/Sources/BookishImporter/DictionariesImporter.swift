// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Coercion
import Foundation
import ISBN
import Logger
import SwiftUI

let dictionariesImporterChannel = Channel("DictionariesImporter")

public class DictionariesImporter: Importer {
    override class public var identifier: String { return "com.elegantchaos.bookish.importer.dictionaries" }

    override func makeSession(importing dictionaries: [[String:Any]], delegate: ImportDelegate) -> DictionariesImportSession? {
        let session = DictionariesImportSession(importer: self, dictionaries: dictionaries, delegate: delegate)
        return session
    }
}

public class DictionariesImportSession: ImportSession {
    public static func == (lhs: DictionariesImportSession, rhs: DictionariesImportSession) -> Bool {
        return lhs === rhs
    }
    
    let dictionaries: [[String:Any]]
    
    init?(importer: Importer, dictionaries: [[String:Any]], delegate: ImportDelegate) {
        self.dictionaries = dictionaries
        super.init(importer: importer, delegate: delegate)
    }
    
    func validate(_ record: [String:Any]) -> ImportedBook? {
        guard let title = record[asString: .titleKey] else { return nil }
        guard let id = record[asString: "id"] else { return nil }

        // TODO: process images
        
        return ImportedBook(id: id, title: title, images: [], properties: record)
    }

    override func run() {
        delegate.session(self, willImportItems: dictionaries.count)
        for record in dictionaries {
            if let book = self.validate(record) {
                dictionariesImporterChannel.log("Imported \(book.title)")
                delegate.session(self, didImport: book)
            } else {
                dictionariesImporterChannel.log("Skipped non-book \(record["title"] ?? record)")
            }
        }
        delegate.sessionDidFinish(self)
    }
}
