// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import LoggerUI

struct PreferencesView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var sheetController: SheetController
    @EnvironmentObject var statusController: StatusController
    
    @AppStorage("enableRawProperties") var enableRawProperties = false
    
    var body: some View {
        NavigationView {
            List {
                Section("General") {
                    Toggle("Show Raw Properties", isOn: $enableRawProperties)
                    
                    NavigationLink("Logging") {
                        LoggerChannelsView()
                            .listStyle(.plain)
                            .navigationTitle("Log Channels")
                    }
                }

                Section("Danger Zone") {
                    HStack {
                        Spacer()
                        Button("Wipe All Data", role: .destructive, action: handleRemoveAll)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func handleRemoveAll() {
        do {
            try model.removeAllData()
        } catch {
            statusController.notify(error)
        }
        sheetController.dismiss()
        //        exit(0)
    }
}
