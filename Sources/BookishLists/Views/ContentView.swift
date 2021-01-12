// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct ListEntry: Identifiable {
    let listID: String?
    let bookID: String?
    let model: Model
    
    init(book: String, model: Model) {
        self.listID = nil
        self.bookID = book
        self.model = model
    }
    
    init(list: String, model: Model) {
        self.listID = list
        self.bookID = nil
        self.model = model
    }

    var id: String {
        listID ?? bookID ?? ""
    }

    var listBinding: Binding<BookList>? {
        guard let id = listID else { return nil }
        return model.binding(forBookList: id)
    }

    var bookBinding: Binding<Book>? {
        guard let id = bookID else { return nil }
        return model.binding(forBook: id)
    }

    var children: [ListEntry]? {
        guard let id = listID, let list = model.lists.index[id] else { return nil }
        
        return list.entries.map({ ListEntry(book: $0, model: model)})
    }
}


struct ContentView: View {
    @EnvironmentObject var model: Model

    @State var selection: UUID? = nil
    
    var body: some View {
        // TODO: generic system for listing possible entry types and identifying the corresponding views
        NavigationView {
            VStack {
                let entries = model.lists.order.map({ ListEntry(list: $0, model: model) })
                List(entries, children: \.children) { entry in
                    if let binding = entry.listBinding {
                        LinkView(binding: binding)
                    } else if let binding = entry.bookBinding {
                        NavigationLink(destination: BookView(book: binding)) {
                            Text(binding.wrappedValue.name)
                        }
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
    
    func handleAdd() {
        let list = BookList(id: UUID().uuidString, name: "Untitled List", entries: [], values: [:])
        model.lists.append(list)
    }
}
