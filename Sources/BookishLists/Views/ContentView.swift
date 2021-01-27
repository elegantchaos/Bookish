// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter

enum ListEntryKind {
    case list(CDList)
    case book(CDBook)
}

struct ListEntry: Identifiable {
    let kind: ListEntryKind
    
    init(book: CDBook) {
        self.kind = .book(book)
    }
    
    init(list: CDList) {
        self.kind = .list(list)
    }

    var id: UUID {
        switch self.kind {
            case .book(let book): return book.id
            case .list(let list): return list.id
        }
    }

    var children: [ListEntry]? {
        switch kind {
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
    @State var showMenu = false
    
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
                                        Button(action: handleImport) { Text("From Delicious Library") }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                        )
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Spacer()
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
        let list = CDList(context: managedObjectContext)
        model.save()
    }

    func handleImport() {
        
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
