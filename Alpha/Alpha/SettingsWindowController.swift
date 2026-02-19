import AppKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {
    private let loginItemButton = NSButton(checkboxWithTitle: LocalizationManager.text("start_at_login"), target: nil, action: nil)
    private let languageLabel = NSTextField(labelWithString: LocalizationManager.text("language_label"))
    private let languageControl = NSSegmentedControl(labels: ["Українська", "English"], trackingMode: .selectOne, target: nil, action: nil)
    private let displayModeLabel = NSTextField(labelWithString: LocalizationManager.text("display_mode_label"))
    private let displayModeControl = NSSegmentedControl(labels: ["", "", ""], trackingMode: .selectOne, target: nil, action: nil)

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Налаштування"
        window.center()
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true

        let visualEffect = NSVisualEffectView(frame: window.contentView?.bounds ?? .zero)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow

        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 14
        container.translatesAutoresizingMaskIntoConstraints = false

        let languageRow = NSStackView(views: [languageLabel, languageControl])
        languageRow.orientation = .horizontal
        languageRow.alignment = .centerY
        languageRow.spacing = 12

        let displayModeRow = NSStackView(views: [displayModeLabel, displayModeControl])
        displayModeRow.orientation = .horizontal
        displayModeRow.alignment = .centerY
        displayModeRow.spacing = 12

        container.addArrangedSubview(languageRow)
        container.addArrangedSubview(displayModeRow)
        container.addArrangedSubview(loginItemButton)

        visualEffect.addSubview(container)
        window.contentView = visualEffect

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -20),
            container.topAnchor.constraint(equalTo: visualEffect.topAnchor, constant: 24)
        ])

        super.init(window: window)

        loginItemButton.target = self
        loginItemButton.action = #selector(toggleLoginItem)
        languageControl.target = self
        languageControl.action = #selector(changeLanguage)
        displayModeControl.target = self
        displayModeControl.action = #selector(changeDisplayMode)

        updateLoginItemState()
        updateLanguageSegmentTitles()
        syncLanguageSelection()
        updateDisplayModeTitles()
        syncDisplayModeSelection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLoginItemState() {
        let status = SMAppService.mainApp.status
        loginItemButton.state = status == .enabled ? .on : .off
    }

    private func syncLanguageSelection() {
        switch LocalizationManager.currentLanguage {
        case .uk:
            languageControl.selectedSegment = 0
        case .en:
            languageControl.selectedSegment = 1
        }
    }

    func applyLocalization() {
        window?.title = LocalizationManager.text("settings")
        loginItemButton.title = LocalizationManager.text("start_at_login")
        languageLabel.stringValue = LocalizationManager.text("language_label")
        displayModeLabel.stringValue = LocalizationManager.text("display_mode_label")
        updateLanguageSegmentTitles()
        syncLanguageSelection()
        updateDisplayModeTitles()
        syncDisplayModeSelection()
    }

    @objc private func toggleLoginItem() {
        do {
            if loginItemButton.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Не вдалося змінити запуск під час входу"
            alert.runModal()
            updateLoginItemState()
        }
    }

    @objc private func changeLanguage() {
        let selected = languageControl.selectedSegment
        LocalizationManager.currentLanguage = (selected == 0) ? .uk : .en
    }

    @objc private func changeDisplayMode() {
        let selected = displayModeControl.selectedSegment
        let mode: AppDisplayMode
        switch selected {
        case 0:
            mode = .trayOnly
        case 1:
            mode = .dockOnly
        default:
            mode = .both
        }
        UserDefaults.standard.set(mode.rawValue, forKey: Preferences.displayModeKey)
        NotificationCenter.default.post(name: AppNotifications.displayModeDidChange, object: nil)
    }

    private func updateLanguageSegmentTitles() {
        languageControl.setLabel(LocalizationManager.text("language_name_uk"), forSegment: 0)
        languageControl.setLabel(LocalizationManager.text("language_name_en"), forSegment: 1)
    }

    private func updateDisplayModeTitles() {
        displayModeControl.setLabel(LocalizationManager.text("display_mode_tray"), forSegment: 0)
        displayModeControl.setLabel(LocalizationManager.text("display_mode_dock"), forSegment: 1)
        displayModeControl.setLabel(LocalizationManager.text("display_mode_both"), forSegment: 2)
    }

    private func syncDisplayModeSelection() {
        let raw = UserDefaults.standard.string(forKey: Preferences.displayModeKey)
        let mode = AppDisplayMode(rawValue: raw ?? "") ?? AppDisplayMode.defaultValue()
        switch mode {
        case .trayOnly:
            displayModeControl.selectedSegment = 0
        case .dockOnly:
            displayModeControl.selectedSegment = 1
        case .both:
            displayModeControl.selectedSegment = 2
        }
    }
}
