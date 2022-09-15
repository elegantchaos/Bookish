// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import UniformTypeIdentifiers

public class FilePickerController: ObservableObject {
    @Published var importRequested = false
    @Published var exportRequested = false
    @Published var exportDocument: BookishInterchangeDocument?
    @Published var importContentTypes: [UTType] = []
    @Published var exportContentType: UTType = .json
    @Published private var importCompletion: ((_ result: Result<URL,Error>) -> ())?
    @Published private var exportCompletion: ((_ result: Result<URL,Error>) -> ())?

    public init() {
    }

    func chooseFileToImport(completion: @escaping (_ result: Result<URL,Error>) -> ()) {
        importCompletion = completion
        importRequested = true
    }

    func chooseLocationToExport(_ document: BookishInterchangeDocument, completion: @escaping (_ result: Result<URL,Error>) -> ()) {
        exportDocument = document
        exportCompletion = completion
        exportRequested = true
    }

    func handlePerformImport(_ result: Result<URL,Error>) {
        importCompletion?(result)
        importCompletion = nil
    }

    func handlePerformExport(_ result: Result<URL,Error>) {
        exportCompletion?(result)
        exportCompletion = nil
    }

}
