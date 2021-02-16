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

enum FieldType: String {
    case string
    case integer
    case real
}

struct ListView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var context
    @ObservedObject var list: CDList
    @State var selection: UUID?
    
    var body: some View {
        
        return VStack {
            TextField("Name", text: $list.name)
                .padding()

            TextField("Notes", text: list.binding(forProperty: "notes"))
                .padding()

            Button(action: handleAddField) {
                Image(systemName: "plus.circle")
            }
            
            List() {
                let keys = Array(list.fields.keys)
                ForEach(keys, id: \.self) { key in
                    Text(key)
                }
            }
            
            List(selection: $selection) {
                ForEach(list.sortedEntries) { book in
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
                    Button(action: handleDeleteList) { Image(systemName: "ellipsis.circle") }
                }
        )
    }

    func handleDelete(_ items: IndexSet?) {
        if let items = items {
            items.forEach { index in
                let entry = list.sortedEntries[index]
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

    func handleAddField() {
        list.addField()
    }
}
