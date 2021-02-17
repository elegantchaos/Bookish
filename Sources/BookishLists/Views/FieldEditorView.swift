// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct FieldEditorView: View {
    @ObservedObject var list: CDList

    var body: some View {
        List() {
            ForEach(list.fields, id: \.self) { field in
                FieldEditorFieldView(field: field)
            }
            .onMove(perform: list.moveFields)
            .onDelete(perform: list.deleteFields)
        }

        Button(action: list.newField) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("New Field")
                    .padding(.leading)
            }
        }

    }
}

struct FieldEditorFieldView: View {
    @ObservedObject var field: ListField
    @State var key = ""
    
    var body: some View {
        HStack {
            TextField("name", text: $key, onEditingChanged: handleEditingChanged, onCommit: handleCommit)
                .onAppear(perform: handleAppear)
            
            Picker(selection: $field.kind, label: Text("Kind")) {
                ForEach(ListField.Kind.allCases, id: \.self) { kind in
                    Text(kind.rawValue)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    func handleAppear() {
        key = field.key
    }
    
    func handleEditingChanged(_ isEditing: Bool) {
        if !isEditing {
            saveChanges()
        }
    }
    
    func handleCommit() {
        saveChanges()
    }
    
    func saveChanges() {
        if key != field.key {
            field.key = key
        }
    }
}
