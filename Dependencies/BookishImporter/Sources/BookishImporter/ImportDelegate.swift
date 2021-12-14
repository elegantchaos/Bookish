// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import Foundation

public protocol ImportDelegate {
    func chooseFile(for importer: Importer, completion: @escaping (URL) -> Void)
    
    /// Report that an import session is starting, and how many items are going to be processed.
    func session(_ session: ImportSession, willImportItems count: Int)
    
    /// Report an imported book
    /// The id of the imported book may be random, but if the importer
    /// is run twice for the same input data, ideally the book should be
    /// given the same id each time. This will allow clients to potentially
    /// update an existing record rather than creating a new one.
    /// The source of the imported book will be set to the importer's id.
    func session(_ session: ImportSession, didImport book: BookRecord)

    /// Report that the session finished.
    func sessionDidFinish(_ session: ImportSession)
    
    /// Report that something went wrong.
    func sessionDidFail(_ session: ImportSession)

    func noImporter()
}

public extension ImportDelegate {
    func chooseFile(for importer: Importer, completion: @escaping (URL) -> Void) { }
    func noImporter() { }
//    func session(_ session: ImportSession, willImportItems count: Int) { }
//    func session(_ session: ImportSession, didImport item: Any, label: String, index: Int, of count: Int) { }
//    func sessionDidFinish(_ session: ImportSession) { }
//    func sessionDidFail(_ session: ImportSession) { }
}
