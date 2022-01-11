// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct ListActionsMenu: View {
    @ObservedObject var list: CDRecord
    @Binding var selection: String?

    var body: some View {
        if list.canAddLists {
            AddRecordButton(container: list, kind: .list, selection: $selection)
        }
        
        if list.canAddGroups {
            AddRecordButton(container: list, kind: .group, selection: $selection)
        }

        if list.canAddLinks {
            AddLinkMenu(mode: .item)
        }

        RemoveLinkMenu(mode: .item)

        if list.canDelete {
            DeleteContainerButton()
        }
        
        EditButton()
    }
}
