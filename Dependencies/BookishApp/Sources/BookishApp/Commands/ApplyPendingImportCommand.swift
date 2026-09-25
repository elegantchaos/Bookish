import Commands
import CommandsUI
import Icons

/// Applies the choices made in the Import workflow.
public struct ApplyPendingImportCommand<Centre: BookishImportingService.Provider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.import.apply-pending"

  public init() {}

  public func availability(centre: Centre) -> CommandAvailability {
    centre.importingService.canApplyPendingImport ? .enabled : .disabled
  }

  public func name(centre _: Centre) -> String { "Import" }

  public func icon(centre _: Centre) -> Icon { Icon("square.and.arrow.down") }

  public func help(centre _: Centre) -> String? { "Apply the reviewed import choices." }

  public func perform(centre: Centre) async throws {
    await centre.importingService.applyPendingImport()
  }
}
