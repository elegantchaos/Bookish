// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter

enum ListEntryKind {
    case list(String)
    case book(String)
}

struct ListEntry: Identifiable {
    let kind: ListEntryKind
    let model: Model
    
    init(book: String, model: Model) {
        self.kind = .book(book)
        self.model = model
    }
    
    init(list: String, model: Model) {
        self.kind = .list(list)
        self.model = model
    }

    var id: String {
        switch self.kind {
        case .book(let id): return id
        case .list(let id): return id
        }
    }

    var children: [ListEntry]? {
        switch kind {
            case .book: return nil
            case .list(let id):
                guard let list = model.lists.index[id], list.entries.count > 0 else { return nil }
                return list.entries.map({ ListEntry(book: $0, model: model)})
        }
    }
}


struct ContentView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var sheetController: SheetController
    
    var body: some View {
        SheetControllerHost {
            VStack {
                NavigationView {
                    RootIndexView()
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
                        .navigationTitle(model.appName)
                        .navigationBarItems(
                            leading: EditButton(),
                            trailing:
                                HStack {
                                    Button(action: handleAdd) { Image(systemName: "plus") }
                                }
                        )
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    func handleAdd() {
        let list = BookList(id: UUID().uuidString, name: "Untitled List", entries: [], values: [:])
        model.lists.append(list)
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
                EditableBookListsView()
            } else {
                BookListsView()
            }
    }
}
