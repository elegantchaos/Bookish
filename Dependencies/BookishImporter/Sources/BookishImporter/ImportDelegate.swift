// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public protocol ImportDelegate {
    func chooseFile(for importer: Importer, completion: @escaping (URL) -> Void)
    func session(_ session: ImportSession, willImportItems count: Int)
    func session(_ session: ImportSession, didImport book: ImportedBook)
    func sessionDidFinish(_ session: ImportSession)
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
