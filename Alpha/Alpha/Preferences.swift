import Foundation

enum Preferences {
    static let autocorrectEnabledKey = "autocorrectEnabled"
    static let displayModeKey = "displayMode"
}

enum AppDisplayMode: String {
    case trayOnly
    case dockOnly
    case both

    static func defaultValue() -> AppDisplayMode {
        return .both
    }
}

enum AppNotifications {
    static let displayModeDidChange = Notification.Name("AppDisplayModeDidChange")
}
