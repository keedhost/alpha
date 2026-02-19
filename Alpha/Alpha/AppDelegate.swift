import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    override init() {
        super.init()
        DebugLogger.configureIfNeeded()
        DebugLogger.log("AppDelegate init")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLogger.log("applicationDidFinishLaunching")
        LocalizationManager.configureIfNeeded()
        configureDefaultsIfNeeded()

        if isAnotherInstanceRunning() {
            DebugLogger.log("Another instance detected, showing alert and terminating")
            showAlreadyRunningAlert()
            NSApp.terminate(nil)
            return
        }

        statusBarController = StatusBarController()
        DebugLogger.log("StatusBarController initialized")
        applyDisplayMode()
        NotificationCenter.default.addObserver(self, selector: #selector(displayModeDidChange), name: AppNotifications.displayModeDidChange, object: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        DebugLogger.log("Dock icon clicked")
        statusBarController?.openSettingsFromDock()
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    private func isAnotherInstanceRunning() -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else { return false }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        return apps.count > 1
    }

    private func showAlreadyRunningAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = LocalizationManager.text("already_running_title")
        alert.informativeText = LocalizationManager.text("already_running_body")
        alert.addButton(withTitle: LocalizationManager.text("ok_button"))
        alert.runModal()
    }

    private func configureDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: Preferences.displayModeKey) == nil {
            defaults.set(AppDisplayMode.defaultValue().rawValue, forKey: Preferences.displayModeKey)
        }
        if defaults.object(forKey: Preferences.autocorrectEnabledKey) == nil {
            defaults.set(true, forKey: Preferences.autocorrectEnabledKey)
        }
    }

    @objc private func displayModeDidChange() {
        applyDisplayMode()
    }

    private func applyDisplayMode() {
        let mode = currentDisplayMode()
        switch mode {
        case .trayOnly:
            NSApp.setActivationPolicy(.accessory)
            statusBarController?.setStatusItemVisible(true)
        case .dockOnly:
            NSApp.setActivationPolicy(.regular)
            statusBarController?.setStatusItemVisible(false)
        case .both:
            NSApp.setActivationPolicy(.regular)
            statusBarController?.setStatusItemVisible(true)
        }
    }

    private func currentDisplayMode() -> AppDisplayMode {
        let raw = UserDefaults.standard.string(forKey: Preferences.displayModeKey)
        return AppDisplayMode(rawValue: raw ?? "") ?? AppDisplayMode.defaultValue()
    }
}
