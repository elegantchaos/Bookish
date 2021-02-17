// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct FieldKindMenu: View {
    @ObservedObject var field: ListField

    var label: some View {
        HStack {
            Text(field.kind.label)
            Image(systemName: "chevron.up.chevron.down")
        }
    }
    
    var body: some View {

        Menu {
        Picker("", selection: $field.kind) {
            ForEach(ListField.Kind.allCases, id: \.self) { kind in
                Text(kind.label)
            }
        }
        .pickerStyle(InlinePickerStyle())
        } label: {
            label
        }
        
//        Menu {
//            ForEach(ListField.Kind.allCases, id: \.self) { kind in
//                Button(action: { handleSetKind(to: kind) }) {
//                    Text(kind.label)
//                }
//            }
//        } label: {
//            HStack {
//                Text(field.kind.label)
//                Image(systemName: "arrowtriangle.down")
//            }
//        }
    }

    func handleSetKind(to kind: ListField.Kind) {
        field.kind = kind
    }
}
