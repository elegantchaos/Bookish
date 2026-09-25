import SwiftUI

/// Offers the active index's configured record creation types.
struct NewRecordToolbar: ToolbarContent {
  /// The types that this index allows users to create.
  let types: [BookishNewRecordType]

  /// The command boundary for the New action.
  @Environment(BookishCommander.self) private var commander

  /// A direct action for one type, or a menu when the index has choices.
  var body: some ToolbarContent {
    if types.count == 1, let type = types.first {
      ToolbarItem {
        commander.button(NewRecordCommand(type: type)) {
          Label("New \(type.menuName)", systemImage: "plus")
        }
      }
    } else if !types.isEmpty {
      ToolbarItem {
        Menu("New", systemImage: "plus") {
          ForEach(types, id: \.self) { type in
            commander.button(NewRecordCommand(type: type))
          }
        }
      }
    }
  }
}
