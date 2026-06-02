import DatastorePrototypeApp
import SwiftUI

@main
struct DatastorePrototypeApplication: App {
  @State private var harness = DatastorePrototypeHarness()

  var body: some Scene {
    WindowGroup {
      DatastorePrototypeHarnessView(harness: harness)
    }
    .commands {
      DatastorePrototypeCommands(harness: harness)
    }
  }
}
