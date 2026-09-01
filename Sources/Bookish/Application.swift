import BookishApp
import SwiftUI

@main
struct BookishApplication: App {
  @State private var engine: BookishEngine

  init() {
    let engine = BookishEngine()
    engine.start()
    self.engine = engine
  }

  var body: some Scene {
    WindowGroup {
      engine.rootContent()
    }
    .commands {
      BookishCommands(harness: engine.harness, navigation: engine.navigation)
    }

    #if DEBUG
      WindowGroup("Mutation Debug", id: BookishWindow.mutationDebug.rawValue) {
        BookishMutationDebugView(harness: engine.harness)
      }
    #endif
  }
}
