// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct SearchBar: View {
    @Binding var value: String
    let action: (String) -> ()
    
    @State var isEditing: Bool = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField("Search", text: $value, onEditingChanged: handleEditing, onCommit: handleCommit)
                .padding(7)
                .padding(.horizontal, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 10)
            
            if !value.isEmpty {
                Button(action: handleCancel) { Image(systemName: "xmark.circle.fill") }
                    .foregroundColor(Color(.systemGray2))
                    .padding(.trailing, 16)
                    .animation(.default)
            }
        }
    }
    
    func handleEditing(_ isEditing: Bool) {
        self.isEditing = isEditing
    }
    
    func handleCommit() {
        action(value)
    }
    
    func handleCancel() {
        self.isEditing = false
        self.value = ""
        action(value)
    }
}
