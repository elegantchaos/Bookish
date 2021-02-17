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
    @Environment(\.editMode) var editMode
    @ObservedObject var list: CDList
    @State var selection: UUID?
    
    var body: some View {
        
        return LazyVStack {
            TextField("Name", text: $list.name)
                .padding()

            TextField("Notes", text: list.binding(forProperty: "notes"))
                .padding()

            if editMode?.wrappedValue == .active {
                FieldEditorView(fields: list.fields)
            }
            
            List(selection: $selection) {
                ForEach(list.sortedBooks) { book in
                    LinkView(BookInList(book, in: list), selection: $selection)
                }
                .onDelete(perform: handleDelete)
            }
            
            Spacer()
        }
        .navigationTitle(list.name)
        .navigationBarItems(
            leading: EditButton(),
            trailing:
                HStack {
                    Button(action: handleAdd) { Image(systemName: "plus") }
                    Button(action: handleDeleteList) { Image(systemName: "ellipsis.circle") }
                }
        )
    }

    func handleDelete(_ items: IndexSet?) {
        if let items = items {
            items.forEach { index in
                let entry = list.sortedBooks[index]
                model.delete(entry)
            }
            model.save()
        }
    }
    
    func handleDeleteList() {
        model.delete(list)
    }
    
    func handleAdd() {
        let book = CDBook(context: context)
        list.add(book)
        model.save()
    }

}
