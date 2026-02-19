import Foundation

enum AppLanguage: String {
    case uk
    case en

    static func fromSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? ""
        if preferred.lowercased().hasPrefix("uk") { return .uk }
        return .en
    }
}

enum LocalizationManager {
    private static let languageKey = "appLanguage"
    static let languageDidChange = Notification.Name("AppLanguageDidChange")
    private static var cachedBundle: Bundle?

    static func configureIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: languageKey) == nil {
            let system = AppLanguage.fromSystem()
            defaults.set(system.rawValue, forKey: languageKey)
        }
    }

    static var currentLanguage: AppLanguage {
        get {
            let raw = UserDefaults.standard.string(forKey: languageKey)
            return AppLanguage(rawValue: raw ?? "") ?? .en
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            cachedBundle = nil
            NotificationCenter.default.post(name: languageDidChange, object: nil)
        }
    }

    static func text(_ key: String) -> String {
        let bundle = localizedBundle()
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        if value == key, currentLanguage != .en {
            return Bundle.main.localizedString(forKey: key, value: "", table: nil)
        }
        return value
    }

    private static func localizedBundle() -> Bundle {
        if let cachedBundle { return cachedBundle }
        let lang = currentLanguage.rawValue
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            cachedBundle = bundle
            return bundle
        }
        cachedBundle = Bundle.main
        return Bundle.main
    }
}
