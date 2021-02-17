// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import Localization

struct FieldEditorView: View {
    @ObservedObject var fields: FieldList

    var body: some View {
        List() {
            ForEach(fields.fields, id: \.self) { field in
                FieldEditorFieldView(field: field)
            }
            .onMove(perform: fields.moveFields)
            .onDelete(perform: fields.deleteFields)
        }

        Button(action: fields.newField) {
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
    @ObservedObject var field: Field
    @State var key = ""
    
    var body: some View {
        HStack {
            TextField("name", text: $key, onEditingChanged: handleEditingChanged, onCommit: handleCommit)
                .onAppear(perform: handleAppear)
            
            Button(action: { print("blah") }) {
                FieldKindMenu(field: field)
            }
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
