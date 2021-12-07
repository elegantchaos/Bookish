// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct BookActionsMenu: View {
    @EnvironmentObject var model: Model
    @ObservedObject var book: CDRecord
    let deleteCallback: () -> ()
    
    var body: some View {
        Button(action: deleteCallback) { Label("Delete", systemImage: "trash") }
        EditButton()
    }
}
