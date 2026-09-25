import Commands
import CommandsUI
import Icons

/// Searches the selected metadata provider for the current query.
public struct LookupBooksCommand<Centre: BookishLookupWorkflowService.Provider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "bookish.lookup.books"

  public init() {}

  public func availability(centre: Centre) -> CommandAvailability {
    centre.lookupWorkflow.canLookupBooks ? .enabled : .disabled
  }

  public func name(centre _: Centre) -> String { "Search" }

  public func icon(centre _: Centre) -> Icon { Icon("magnifyingglass") }

  public func help(centre _: Centre) -> String? { "Search for matching books." }

  public func perform(centre: Centre) async throws {
    await centre.lookupWorkflow.lookupBooks()
  }
}
