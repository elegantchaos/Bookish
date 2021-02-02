// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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

struct ListView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var context
    @State var selection: UUID? = nil
    @ObservedObject var list: CDList

    var body: some View {
        
        return VStack {
            TextField("Name", text: $list.name)
                .padding()

            TextField("Notes", text: list.binding(forProperty: "notes"))
                .padding()

            List(selection: $selection) {
                ForEach(list.sortedBooks) { book in
                    LinkView(book, selection: $selection)
                }
                .onDelete(perform: handleDelete)
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
        book.addToLists(list)
        model.save()
    }
    
}
