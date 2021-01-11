// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Combine
import SwiftUI

@main
struct BookishListsApp: App {
    static let store = NSUbiquitousKeyValueStore.default
    let model = Model(from: store)
    
    var body: some Scene {

        return WindowGroup {
            ContentView()
                .environmentObject(model)
                .onReceive(
                    model.objectWillChange.debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                        model.save(to: BookishListsApp.store)
                })
        }
    }
}
