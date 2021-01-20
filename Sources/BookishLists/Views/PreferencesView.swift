// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import LoggerUI

struct PreferencesView: View {
    @EnvironmentObject var sheetController: SheetController
    
    var body: some View {
        NavigationView {
            LoggerChannelsView()
                .padding()
                .navigationTitle("Log Channels")
                .navigationBarItems(trailing:
                    Button(action: sheetController.dismiss) {
                        Text("Done")
                    })
        }
    }
}
