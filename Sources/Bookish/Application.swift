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
      BookishCommands(
        harness: engine.harness,
        navigation: engine.navigation,
        commander: engine.commander
      )
    }

    #if DEBUG
      WindowGroup("Mutation Debug", id: BookishWindow.mutationDebug.rawValue) {
        BookishMutationDebugView(harness: engine.harness)
          .environment(\.bookishCommandCentre, engine.commander)
      }
    #endif

    #if os(macOS)
      Settings {
        BookishSettingsView()
      }
    #endif
  }
}
