// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct RootActionsMenu: View {
    @EnvironmentObject var model: ModelController

    var body: some View {
        AddRecordButton(container: nil, kind: .list, selection: $model.selection)
        AddRecordButton(container: nil, kind: .group, selection: $model.selection)
        AddBooksButton()
        ImportMenu()
    }
    
    func handleAddGroup() {
        let list: CDRecord = model.add(.group)
        model.selection = list.id
    }

}
