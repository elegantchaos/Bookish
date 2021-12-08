// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SheetController
import SwiftUI

struct AddBooksButton: View {
    @EnvironmentObject var sheetController: SheetController

    var body: some View {
        Button(action: handleScan) { Text("Add Books…") }
    }

    func handleScan() {
        sheetController.show {
            AddBooksView()
        }
    }
}
