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

struct ListIndexView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var context
    @Environment(\.editMode) var editMode
    @ObservedObject var list: CDList
    @State var selection: String?
    @State var filter: String = ""
    
    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        return VStack {
            TextField("Notes", text: list.binding(forProperty: "notes"))
                .padding()

            if isEditing {
                FieldEditorView(fields: list.fields)
            }
            
            List(selection: $selection) {
                ForEach(list.sortedBooks) { book in
                    if filter.isEmpty || book.name.contains(filter) {
                        if isEditing {
                            LabelView(BookInList(book, in: list))
                        } else {
                            LinkView(BookInList(book, in: list), selection: $selection)
                        }
                    }
                }
                .onDelete(perform: handleDelete)

                ForEach(list.sortedLists) { list in
                    if filter.isEmpty || list.name.contains(filter) {
                    if isEditing {
                        LabelView(list)
                    } else {
                        OLinkView(list, selection: $selection)
                    }
                    }
                }
                .onDelete(perform: handleDelete)

            }
            .listStyle(.plain)
            .searchable(text: $filter)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                DeferredTextField(label: "Name", text: $list.name)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                ListActionsMenuButton(list: list)
            }
        }
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
    
}
