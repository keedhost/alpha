import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private let autocorrectItem: NSMenuItem
    private let languageItem: NSMenuItem
    private let displayModeItem: NSMenuItem
    private let settingsItem: NSMenuItem
    private let aboutItem: NSMenuItem
    private let quitItem: NSMenuItem

    private let keyboardMonitor = KeyboardMonitor()
    private var settingsWindowController: SettingsWindowController?
    private var aboutWindowController: AboutWindowController?

    private var isAutocorrectEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Preferences.autocorrectEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Preferences.autocorrectEnabledKey) }
    }

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        autocorrectItem = NSMenuItem()
        languageItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        displayModeItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        settingsItem = NSMenuItem(title: LocalizationManager.text("settings"), action: #selector(openSettings), keyEquivalent: ",")
        aboutItem = NSMenuItem(title: LocalizationManager.text("about"), action: #selector(openAbout), keyEquivalent: "")
        quitItem = NSMenuItem(title: LocalizationManager.text("quit"), action: #selector(quit), keyEquivalent: "q")

        super.init()

        if let button = statusItem.button {
            button.title = "Α"
            button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        }

        autocorrectItem.target = self
        settingsItem.target = self
        aboutItem.target = self
        quitItem.target = self

        menu.addItem(autocorrectItem)
        menu.addItem(.separator())
        menu.addItem(languageItem)
        menu.addItem(displayModeItem)
        menu.addItem(.separator())
        menu.addItem(settingsItem)
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.isVisible = true
        languageItem.isEnabled = false
        displayModeItem.isEnabled = false

        updateAutocorrectTitle()
        updateLanguageTitle()
        updateDisplayModeTitle()
        updateAutocorrectState()

        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: LocalizationManager.languageDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(displayModeDidChange), name: AppNotifications.displayModeDidChange, object: nil)
    }

    private func updateAutocorrectTitle() {
        autocorrectItem.title = isAutocorrectEnabled ? LocalizationManager.text("autocorrect_on") : LocalizationManager.text("autocorrect_off")
        autocorrectItem.action = #selector(toggleAutocorrect)
        autocorrectItem.keyEquivalent = ""
    }

    private func updateLanguageTitle() {
        let languageName = LocalizationManager.currentLanguage == .uk
            ? LocalizationManager.text("language_name_uk")
            : LocalizationManager.text("language_name_en")
        languageItem.title = String(format: LocalizationManager.text("language_status"), languageName)
    }

    private func updateDisplayModeTitle() {
        let raw = UserDefaults.standard.string(forKey: Preferences.displayModeKey)
        let mode = AppDisplayMode(rawValue: raw ?? "") ?? AppDisplayMode.defaultValue()
        let modeName: String
        switch mode {
        case .trayOnly:
            modeName = LocalizationManager.text("display_mode_tray")
        case .dockOnly:
            modeName = LocalizationManager.text("display_mode_dock")
        case .both:
            modeName = LocalizationManager.text("display_mode_both")
        }
        displayModeItem.title = String(format: LocalizationManager.text("display_mode_status"), modeName)
    }

    private func updateAutocorrectState() {
        keyboardMonitor.syncState(isEnabled: isAutocorrectEnabled)
        if isAutocorrectEnabled {
            keyboardMonitor.startMonitoringIfPossible()
        } else {
            keyboardMonitor.stopMonitoring()
        }
    }

    @objc private func toggleAutocorrect() {
        isAutocorrectEnabled.toggle()
        updateAutocorrectTitle()
        updateAutocorrectState()
    }

    @objc private func openSettings() {
        DebugLogger.log("Open settings window")
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openSettingsFromDock() {
        openSettings()
    }

    @objc private func openAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        aboutWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func languageDidChange() {
        settingsItem.title = LocalizationManager.text("settings")
        aboutItem.title = LocalizationManager.text("about")
        quitItem.title = LocalizationManager.text("quit")
        updateAutocorrectTitle()
        updateLanguageTitle()
        updateDisplayModeTitle()
        settingsWindowController?.applyLocalization()
        aboutWindowController?.applyLocalization()
    }

    @objc private func displayModeDidChange() {
        updateDisplayModeTitle()
    }

    @objc private func quit() {
        keyboardMonitor.stopMonitoring()
        NSApp.terminate(nil)
    }

    func setStatusItemVisible(_ isVisible: Bool) {
        statusItem.isVisible = isVisible
    }
}
