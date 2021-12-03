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

let dictionariesImporterChannel = Channel("DictionariesImporter")

public class DictionariesImporter: Importer {
    override class public var id: String { return "com.elegantchaos.bookish.importer.dictionaries" }

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
    
    override func run() {
        delegate.session(self, willImportItems: dictionaries.count)
        for record in dictionaries {
            if let book = BookRecord(record) {
                dictionariesImporterChannel.log("Imported \(book.title)")
                delegate.session(self, didImport: book)
            } else {
                dictionariesImporterChannel.log("Skipped non-book \(record["title"] ?? record)")
            }
        }
        delegate.sessionDidFinish(self)
    }
}
