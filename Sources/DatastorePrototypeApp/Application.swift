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
      DatastorePrototypeCommands(harness: engine.harness)
    }
  }
}
