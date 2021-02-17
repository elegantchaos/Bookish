// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct FieldKindMenu: View {
    @ObservedObject var field: Field
    
    var body: some View {
        Menu {
            Picker("", selection: $field.kind) {
                ForEach(Field.Kind.allCases, id: \.self) { kind in
                    Text(kind.label)
                }
            }
            .pickerStyle(InlinePickerStyle())
        } label: {
            HStack {
                Text(field.kind.label)
                Image(systemName: "chevron.up.chevron.down")
            }
        }
    }
    
    func handleSetKind(to kind: Field.Kind) {
        field.kind = kind
    }
}
