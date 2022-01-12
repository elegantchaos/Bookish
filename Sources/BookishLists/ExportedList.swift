// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import UniformTypeIdentifiers

class ExportedList: ReferenceFileDocument {
    enum ExportError: Error {
        case noObject
        case noObjectInBackgroundContext
    }
    
    static var readableContentTypes: [UTType] = [.json]
    static var writableContentTypes: [UTType] = [.json]

    var exporter: ExportController!
    var record: CDRecord?

    init(_ record: CDRecord, exporter: ExportController) {
        self.record = record
        self.exporter = exporter
    }

    required init(configuration: ReadConfiguration) throws {
    }
    
    func snapshot(contentType: UTType) throws -> Data {
        guard let id = record?.objectID else { throw ExportError.noObject }

        let context = exporter.model.stack.newBackgroundContext()
        var data: Data!
        try context.performAndWait {
            guard let copy = context.object(with: id) as? CDRecord else { throw ExportError.noObjectInBackgroundContext }
            data = try exporter.export(copy)
        }

        return data
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: snapshot)
    }
}
