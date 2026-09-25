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
    WindowGroup(id: BookishWindow.main.rawValue) {
      engine.rootContent()
    }
    .restorationBehavior(.automatic)
    .commands {
      BookishCommands(engine: engine)
    }

    #if DEBUG
      WindowGroup("Mutation Debug", id: BookishWindow.mutationDebug.rawValue) {
        BookishMutationDebugView()
          .modifier(engine.runningInjector)
      }
    #endif

    #if os(macOS)
      Settings {
        BookishSettingsView()
          .modifier(engine.runningInjector)
      }
    #endif
  }
}
