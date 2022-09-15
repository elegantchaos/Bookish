// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct DeferredTextField: View {
    let label: String
    @Binding var text: String
    
    @State var value: String = ""
    
    var body: some View {
        TextField(label, text: $value, onEditingChanged: handleEditingChanged, onCommit: handleCommit)
            .onAppear(perform: handleAppear)
    }
    
    func handleAppear() {
        value = text
    }

    func handleCommit() {
        text = value
    }
    
    func handleEditingChanged(_ isEditing: Bool) {
        if isEditing {
            value = text
        } else {
            handleCommit()
        }
    }
}
