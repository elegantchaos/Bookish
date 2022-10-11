// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SheetController
import SwiftUI

struct EditFieldsButton: View {
    @EnvironmentObject var editController: EditController
    
    var body: some View {
        Button(action: handleTapped) {
            Label("edit.fields", systemImage: "rectangle.and.pencil.and.ellipsis")
        }
    }

    
    func handleTapped() {
        editController.toggleEditingFields()
    }
}
