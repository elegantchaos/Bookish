import DatastorePrototypeApp
import SwiftUI

@main
struct DatastorePrototypeApplication: App {
  @State private var engine: DatastorePrototypeEngine

  init() {
    let engine = DatastorePrototypeEngine()
    engine.start()
    self.engine = engine
  }

  var body: some Scene {
    WindowGroup {
      engine.rootContent()
    }
    .commands {
      DatastorePrototypeCommands(harness: engine.harness, navigation: engine.navigation)
    }

    #if DEBUG
      WindowGroup("Mutation Debug", id: DatastorePrototypeWindow.mutationDebug.rawValue) {
        DatastorePrototypeMutationDebugView(harness: engine.harness)
      }
    #endif
  }
}
