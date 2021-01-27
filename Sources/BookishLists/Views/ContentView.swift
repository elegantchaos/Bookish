// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter

enum ListEntryKind {
    case allBooks
    case list(CDList)
    case book(CDBook)
}

struct ListEntry: Identifiable {
    static let allBooksId = UUID()
    
    let kind: ListEntryKind
    
    init() {
        self.kind = .allBooks
    }
    
    init(book: CDBook) {
        self.kind = .book(book)
    }
    
    init(list: CDList) {
        self.kind = .list(list)
    }

    var id: UUID {
        switch self.kind {
            case .allBooks: return ListEntry.allBooksId
            case .book(let book): return book.id
            case .list(let list): return list.id
        }
    }

    var children: [ListEntry]? {
        switch kind {
            case .allBooks: return nil
            case .book: return nil
            case .list(let list):
                guard let books = list.books as? Set<CDBook> else { return nil }
                return books.map({ ListEntry(book: $0)})
        }
    }
}


struct ContentView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var sheetController: SheetController
    @State var importRequested = false

    var body: some View {
        SheetControllerHost {
            VStack {
                NavigationView {
                    RootIndexView()
                        .navigationTitle(model.appName)
                        .navigationBarItems(
                            leading: EditButton(),
                            trailing:
                                Menu() {
                                    Button(action: handleAdd) { Text("New List") }
                                    Menu("Import…") {
                                        Button(action: handleRequestImport) { Text("From Delicious Library") }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                        )
                }
                .navigationBarTitleDisplayMode(.inline)
                .fileImporter(isPresented: $importRequested, allowedContentTypes: [.xml], onCompletion: model.handlePerformImport)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Spacer()
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        if let progress = model.importProgress {
                            ProgressView("Importing", value: progress)
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: handlePreferences) {
                            Label("Preferences", systemImage: "gear")
                        }
                    }
                }
            }
        }
    }
    
    func handleAdd() {
        let _ : CDList = model.add()
    }

    func handleRequestImport() {
        importRequested = true
    }
    

    func handlePreferences() {
        sheetController.show {
            PreferencesView()
        }
    }
}

struct RootIndexView: View {
    @Environment(\.editMode) var editMode
    var body: some View {
            if editMode?.wrappedValue == .active {
                EditableListIndexView()
            } else {
                ListIndexView()
            }
    }
}
