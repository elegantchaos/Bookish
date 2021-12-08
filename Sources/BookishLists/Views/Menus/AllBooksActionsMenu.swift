// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct AllBooksActionsMenu: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var sheetController: SheetController
    
    var body: some View {
        AddBooksButton()
        EditButton()
    }
    
    func handleAdd() {
        sheetController.show {
            AddBooksView()
        }
    }

}
