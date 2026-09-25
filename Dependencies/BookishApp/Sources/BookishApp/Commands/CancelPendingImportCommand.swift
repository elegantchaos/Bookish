import Commands
import CommandsUI
import Icons

/// Discards the proposal shown in the Import workflow.
public struct CancelPendingImportCommand<Centre: BookishImportingService.Provider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.import.cancel-pending"

  public init() {}

  public func name(centre _: Centre) -> String { "Cancel" }

  public func icon(centre _: Centre) -> Icon { Icon("xmark") }

  public func help(centre _: Centre) -> String? { "Discard the current import proposal." }

  public func perform(centre: Centre) async throws {
    centre.importingService.cancelPendingImport()
  }
}
