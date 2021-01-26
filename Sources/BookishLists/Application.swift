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
    @Environment(\.scenePhase) var scenePhase
    let store: ObjectStore
    let model: Model
    let coreDataStack: CoreDataStack
    
    init() {
        let store = Application.setupStore()
        let model = Model(from: store)
        let coreDataStack = CoreDataStack(containerName: "BookishLists")

        self.store = store
        self.model = model
        self.coreDataStack = coreDataStack
    }
    
    var body: some Scene {
        let sheetController = SheetController()
        return WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(model)
                .environmentObject(sheetController)
                .onReceive(
                    model.objectWillChange.debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                        model.save(to: store)
                })
        }
        .onChange(of: scenePhase) { newScenePhase in
              switch newScenePhase {
              case .active:
                print("App is active")
              case .inactive:
                print("App is inactive")
              case .background:
                try? coreDataStack.viewContext.save()
                print("App is in background")
              @unknown default:
                print("Oh - interesting: I received an unexpected new value.")
              }
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
