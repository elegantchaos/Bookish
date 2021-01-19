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
    @State var importRequested = false
    @State var importProgress: Double? = nil

    let manager = ImportManager()

    var body: some View {
        VStack {
            TextField("Name", text: $list.name)
                .padding()
            
            HStack {
                Button(action: handleRequestImport) {
                    Text("Import From Delicious")
                }
                
                if let progress = importProgress {
                    ProgressView(value: progress) {
                        Text("Blah")
                    }
                }
            }

            List(selection: $selection) {
                ForEach(list.entries, id: \.self) { id in
                    let book = model.binding(forBook: id)
                    ListItemLinkView(for: book)
                }
                .onDelete(perform: handleDelete)
                .onMove(perform: handleMove)
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
        .fileImporter(isPresented: $importRequested, allowedContentTypes: [.xml], onCompletion: handlePerformImport)
    }

    func handleMove(fromOffsets from: IndexSet, toOffset to: Int) {
        var modified = list.entries
        modified.move(fromOffsets: from, toOffset: to)
        list.entries = modified
    }
    
    func handleDelete(_ items: IndexSet?) {
        if let items = items {
            list.entries.remove(atOffsets: items)
        }
    }
    
    func handleAdd() {
        let book = Book(id: UUID().uuidString, name: "Untitled Book")
        list.entries.append(book.id)
        model.books.append(book)
    }
    
    func handleRequestImport() {
        importRequested = true
    }
    
    func handlePerformImport(_ result: Result<URL,Error>) {
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
        importProgress = 0.0
    }
    
    func session(_ session: ImportSession, willImportItem label: String, index: Int, of count: Int) {
        importProgress = Double(index) / Double(count)
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        importProgress = nil
        if let session = session as? DeliciousLibraryImportSession {
            onMainQueue {
                for importedBook in session.books.values {
//                let importedBook = session.books.randomElement()!.value
                    let book = Book(id: importedBook.id, name: importedBook.title)
                    list.entries.append(book.id)
                    model.books.append(book)
                }
            }
        }
    }
    
    func sessionDidFail(_ session: ImportSession) {
        importProgress =  nil
    }

}
