// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SheetController
import SwiftUI

struct ScannerView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("scanner goes here")
                    .padding()
                Spacer()
            }
            .navigationBarItems(
                trailing: SheetDismissButton()
            )
        }
    }
}
