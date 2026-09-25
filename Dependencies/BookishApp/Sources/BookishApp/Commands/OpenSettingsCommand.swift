import Commands
import CommandsUI
import Icons

/// Opens the application settings sheet on iOS.
public struct OpenSettingsCommand<Centre: BookishSettingsPresentationProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "bookish.settings.open"

  public init() {}

  public func name(centre _: Centre) -> String { "Settings" }

  public func icon(centre _: Centre) -> Icon { Icon("gearshape") }

  public func help(centre _: Centre) -> String? { "Open Bookish settings." }

  public func perform(centre: Centre) async throws {
    centre.settingsPresentation.openSettings()
  }
}
