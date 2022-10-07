// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct RootActionsMenu: View {
    @EnvironmentObject var model: ModelController
    @Binding var selection: String?
    
    var body: some View {
        AddBooksButton(mode: .scan)
        AddBooksButton(mode: .search)
        ImportMenu()
    }
}
