// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Combine
import Files
import ObjectStore
import SwiftUI

@main
struct Application: App {
    let store: FileObjectStore<JSONObjectCoder>
    let model: Model
    
    init() {
        let store = Application.setupStore()
        let model = Model(from: store)
        
        self.store = store
        self.model = model
    }
    
    var body: some Scene {

        return WindowGroup {
            ContentView()
                .environmentObject(model)
                .onReceive(
                    model.objectWillChange.debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                        model.save(to: store)
                })
        }
    }
    
    static func setupStore() -> FileObjectStore<JSONObjectCoder> {
        let folder = FileManager.default.locations.documents.folder("com.elegantchaos.bookish.lists") // TODO: move to application support?
        let store = FileObjectStore(root: folder, coder: JSONObjectCoder())
        return store
    }
}
