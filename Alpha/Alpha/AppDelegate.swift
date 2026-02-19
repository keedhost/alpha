import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LocalizationManager.configureIfNeeded()

        if isAnotherInstanceRunning() {
            showAlreadyRunningAlert()
            NSApp.terminate(nil)
            return
        }

        statusBarController = StatusBarController()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
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
}
