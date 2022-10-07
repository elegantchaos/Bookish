// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SheetController
import SwiftUI

struct AddBooksButton: View {
    @EnvironmentObject var sheetController: SheetController
    let mode: AddBooksView.Mode
    
    var body: some View {
        Button(action: handleScan) {
            Label("\(mode.label)…", systemImage: mode.iconName)
        }
    }

    
    func handleScan() {
        sheetController.show {
            AddBooksView(mode: mode)
        }
    }
}
