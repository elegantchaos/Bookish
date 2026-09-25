import Commands
import CommandsUI
import Icons

/// Closes the application settings sheet on iOS.
public struct CloseSettingsCommand<Centre: BookishSettingsPresentationService.Provider>:
  CommandWithUI
{
  public typealias ResultType = Void

  public let id = "bookish.settings.close"

  public init() {}

  public func name(centre _: Centre) -> String { "Done" }

  public func icon(centre _: Centre) -> Icon { Icon("checkmark") }

  public func perform(centre: Centre) async throws {
    centre.settingsPresentationService.closeSettings()
  }
}
