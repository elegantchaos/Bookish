// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

struct BookListView: View {
    @EnvironmentObject var model: Model
    @State var selection: UUID? = nil
    @Binding var list: BookList
    @State var importing = false
    @State var progress = 0.0
    @State var showProgress = false

    let manager = ImportManager()

    var body: some View {
        VStack {
            TextField("Name", text: $list.name)
                .padding()
            
            HStack {
                Button(action: handleImport) {
                    Text("Import From Delicious")
                }
                
                if showProgress {
                    ProgressView(value: progress)
                }
            }

            List(selection: $selection) {
                ForEach(list.entries, id: \.self) { id in
                    let book = model.binding(forBook: id)
                    ListItemLinkView(for: book)
                }
            }
        }
        .navigationTitle(list.name)
        .navigationBarItems(
            leading: EditButton(),
            trailing:
                HStack {
                    Button(action: handleAdd) { Image(systemName: "plus") }
                }
        )
        .fileImporter(isPresented: $importing, allowedContentTypes: [.xml], onCompletion: handleImporting)
    }
    
    func handleAdd() {
        let book = Book(id: UUID().uuidString, name: "Untitled Book")
        list.entries.append(book.id)
        model.books.append(book)
    }
    
    func handleImport() {
        importing = true
    }
    
    func handleImporting(_ result: Result<URL,Error>) {
        switch result {
            case .success(let url):
                manager.importFrom(url, monitor: self)

            case .failure(let error):
                print(error)
        }
    }
}

extension BookListView: ImportMonitor {
    func session(_ session: ImportSession, willImportItems count: Int) {
        showProgress = true
    }
    
    func session(_ session: ImportSession, willImportItem label: String, index: Int, of count: Int) {
        progress = Double(index) / Double(count)
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        showProgress = false
        if let session = session as? DeliciousLibraryImportSession {
            for importedBook in session.books.values {
                let book = Book(id: importedBook.id, name: importedBook.title)
                onMainQueue {
                    list.entries.append(book.id)
                    model.books.append(book)
                }
            }
        }
    }
    
    func sessionDidFail(_ session: ImportSession) {
        showProgress = false
    }

}
