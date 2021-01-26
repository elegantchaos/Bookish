// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

extension Binding where Value == String? {
    func onNone(_ fallback: String) -> Binding<String> {
        return Binding<String>(get: {
            return self.wrappedValue ?? fallback
        }) { value in
            self.wrappedValue = value
        }
    }
}

struct BookListView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var context
    @State var selection: UUID? = nil
    @ObservedObject var list: CDList
    @State var importRequested = false
    @State var importProgress: Double? = nil

    let manager = ImportManager()

    var body: some View {
        
        return VStack {
            TextField("Name", text: $list.name.onNone(""))
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
                ForEach(list.sortedBooks) { book in
                    LinkView(book)
                }
                .onDelete(perform: handleDelete)
            }
        }
        .navigationTitle(list.name ?? "Untitled")
        .navigationBarItems(
            leading: EditButton(),
            trailing:
                HStack {
                    Button(action: handleAdd) { Image(systemName: "plus") }
                }
        )
        .fileImporter(isPresented: $importRequested, allowedContentTypes: [.xml], onCompletion: handlePerformImport)
    }

    func handleDelete(_ items: IndexSet?) {
        if let items = items {
            items.forEach { index in
                let book = list.sortedBooks[index]
                list.removeFromBooks(book)
            }
            model.save()
        }
    }
    
    func handleAdd() {
        let book = CDBook(context: context)
        book.id = UUID()
        book.addToLists(list)
        model.save()
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
                    let book = CDBook(context: context)
                    book.id = UUID(uuidString: importedBook.id)!
                    book.name = importedBook.title
                    list.addToBooks(book)
                }
                model.save()
            }
        }
    }
    
    func sessionDidFail(_ session: ImportSession) {
        importProgress =  nil
    }

}
