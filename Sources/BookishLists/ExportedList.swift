// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import UniformTypeIdentifiers

class ExportedList: ReferenceFileDocument {
    static let bookishType = UTType("com.elegantchaos.bookish")!
    enum ExportError: Error {
        case noObject
        case noObjectInBackgroundContext
    }
    
    struct Snapshot {
        let name: String
        let data: Data
    }
    
    static var readableContentTypes: [UTType] = [bookishType, .json]
    static var writableContentTypes: [UTType] = [bookishType]

    var exporter: ExportController!
    var record: CDRecord?

    init(_ record: CDRecord, exporter: ExportController) {
        self.record = record
        self.exporter = exporter
    }

    required init(configuration: ReadConfiguration) throws {
    }
    
    func snapshot(contentType: UTType) throws -> Snapshot {
        guard let id = record?.objectID else { throw ExportError.noObject }

        let context = exporter.model.stack.newBackgroundContext()
        var data: Data!
        var name: String = "Bookish Export"

        try context.performAndWait {
            guard let copy = context.object(with: id) as? CDRecord else { throw ExportError.noObjectInBackgroundContext }
            data = try exporter.export(copy)
            name = copy.name
        }

        return Snapshot(name: name, data: data)
    }
    
    func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let wrapper = FileWrapper(regularFileWithContents: snapshot.data)
        wrapper.filename = snapshot.name

        return wrapper
    }
}
