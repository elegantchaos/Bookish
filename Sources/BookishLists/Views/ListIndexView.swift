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
    @ObservedObject var list: CDRecord
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
            
            let items: [CDRecord] = list.sortedContents
            List(selection: $selection) {
                ForEach(items) { item in
                    if include(item) {
                        if isEditing {
                            RecordLabel(record: item)
                        } else {
                            RecordLink(item, in: list, selection: $selection)
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
    
    func include(_ item: CDRecord) -> Bool {
        filter.isEmpty || item.name.contains(filter)
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
