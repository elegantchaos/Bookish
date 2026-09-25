import Commands
import CommandsUI
import Icons

/// Creates and selects a standard catalogue record.
public struct NewRecordCommand<Centre: BookishRecordCreationService.Provider>: CommandWithUI {
  public typealias ResultType = Void

  /// The kind to create.
  public let type: BookishNewRecordType

  /// The stable command identifier for this kind.
  public var id: String { "bookish.new.\(type.rawValue)" }

  /// Creates a command for one standard record type.
  public init(type: BookishNewRecordType) {
    self.type = type
  }

  /// Disables creation when no suitable index is available.
  public func availability(centre: Centre) -> CommandAvailability {
    centre.recordCreationService.canCreate(type) ? .enabled : .disabled
  }

  /// The New menu and toolbar label.
  public func name(centre _: Centre) -> String { "New \(type.menuName)" }

  /// The icon identifying the created type.
  public func icon(centre _: Centre) -> Icon { Icon(type.systemImage) }

  /// Describes the creation action.
  public func help(centre _: Centre) -> String? { "Create a \(type.menuName.lowercased()) record." }

  /// Creates the record and reveals it in the browser.
  public func perform(centre: Centre) async throws {
    try await centre.recordCreationService.create(type)
  }
}
