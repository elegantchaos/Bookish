// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct FieldsView: View {
    @EnvironmentObject var appearance: AppearanceController
    @Environment(\.editMode) var editMode
    
    let record: CDRecord
    let fields: FieldList
    
    var body: some View {
        let isEditing = editMode.isEditing
        VStack(spacing: 8.0) {
            ForEach(fields.fields) { field in
                if isEditing {
                    EditableFieldView(record: record, field: field)
                } else {
                    FieldView(record: record, field: field)
                }
            }
        }
    }
}

extension Binding where Value == EditMode {
    var isEditing: Bool {
        return wrappedValue.isEditing
    }
}

extension Optional where Wrapped == Binding<EditMode> {
    var isEditing: Bool {
        self?.wrappedValue.isEditing ?? false
    }
}
