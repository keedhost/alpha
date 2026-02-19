import AppKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {
    private let loginItemButton = NSButton(checkboxWithTitle: LocalizationManager.text("start_at_login"), target: nil, action: nil)
    private let languageLabel = NSTextField(labelWithString: LocalizationManager.text("language_label"))
    private let languageControl = NSSegmentedControl(labels: ["Українська", "English"], trackingMode: .selectOne, target: nil, action: nil)

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 180),
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

        container.addArrangedSubview(languageRow)
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

        updateLoginItemState()
        updateLanguageSegmentTitles()
        syncLanguageSelection()
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
        updateLanguageSegmentTitles()
        syncLanguageSelection()
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

    private func updateLanguageSegmentTitles() {
        languageControl.setLabel(LocalizationManager.text("language_name_uk"), forSegment: 0)
        languageControl.setLabel(LocalizationManager.text("language_name_en"), forSegment: 1)
    }
}
