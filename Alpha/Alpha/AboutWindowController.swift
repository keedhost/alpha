import AppKit

final class AboutWindowController: NSWindowController {
    private let nameLabel = NSTextField(labelWithString: LocalizationManager.text("app_name"))
    private let versionLabel = NSTextField(labelWithString: "")
    private let authorLabel = NSTextField(labelWithString: LocalizationManager.text("author_label"))
    private let yearLabel = NSTextField(labelWithString: "")
    private let licenseButton = NSButton(title: LocalizationManager.text("license_label"), target: nil, action: nil)
    private let siteButton = NSButton(title: LocalizationManager.text("project_site_label"), target: nil, action: nil)
    private let privacyLabel = NSTextField(wrappingLabelWithString: LocalizationManager.text("privacy_notice"))
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Про програму"
        window.center()
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true

        let visualEffect = NSVisualEffectView(frame: window.contentView?.bounds ?? .zero)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        privacyLabel.maximumNumberOfLines = 0
        licenseButton.bezelStyle = .inline
        siteButton.bezelStyle = .inline

        licenseButton.target = self
        licenseButton.action = #selector(openLicense)
        siteButton.target = self
        siteButton.action = #selector(openProjectSite)

        applyLocalization()

        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(versionLabel)
        stack.addArrangedSubview(authorLabel)
        stack.addArrangedSubview(yearLabel)
        stack.addArrangedSubview(licenseButton)
        stack.addArrangedSubview(siteButton)
        stack.addArrangedSubview(privacyLabel)

        visualEffect.addSubview(stack)
        window.contentView = visualEffect

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: visualEffect.topAnchor, constant: 24)
        ])

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyLocalization() {
        window?.title = LocalizationManager.text("about")
        nameLabel.stringValue = LocalizationManager.text("app_name")
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        versionLabel.stringValue = "\(LocalizationManager.text("version_label")): \(version)"
        authorLabel.stringValue = LocalizationManager.text("author_label")
        let yearText = AboutWindowController.yearRangeText()
        yearLabel.stringValue = "\(LocalizationManager.text("year_prefix")) \(yearText)"
        licenseButton.title = LocalizationManager.text("license_label")
        siteButton.title = LocalizationManager.text("project_site_label")
        privacyLabel.stringValue = LocalizationManager.text("privacy_notice")
    }

    private static func yearRangeText() -> String {
        let startYear = 2026
        let currentYear = Calendar.current.component(.year, from: Date())
        if currentYear == startYear { return "\(startYear)" }
        return "\(startYear)–\(currentYear)"
    }

    @objc private func openLicense() {
        if let url = URL(string: "https://www.gnu.org/licenses/gpl-3.0.html") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openProjectSite() {
        if let url = URL(string: "https://github.com/keedhost/alpha") {
            NSWorkspace.shared.open(url)
        }
    }
}
