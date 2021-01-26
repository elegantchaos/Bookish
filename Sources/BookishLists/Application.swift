// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CloudKit
import Combine
import Files
import Logger
import ObjectStore
import SwiftUI
import SheetController

@main
struct Application: App {
    let store: ObjectStore
    let model: Model
    
    init() {
        let store = Application.setupStore()
        let model = Model(from: store)
        
        self.store = store
        self.model = model
    }
    
    var body: some Scene {
        let sheetController = SheetController()
        return WindowGroup {
            let coreDataStack = CoreDataStack(containerName: "BookishLists")
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(model)
                .environmentObject(sheetController)
                .onReceive(
                    model.objectWillChange.debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                        model.save(to: store)
                })
        }
    }
    
    static func setupStore() -> ObjectStore {
//        let folder = FileManager.default.locations.documents.folder("com.elegantchaos.bookish.lists") // TODO: move to application support?
//        let store = FileObjectStore(root: folder, coder: JSONObjectCoder())
        let container = CKContainer(identifier: "iCloud.com.elegantchaos.Bookish.Lists")
        let store = CloudKitObjectStore(container: container, coder: JSONObjectCoder())
        return store
    }
}
