import AppKit
import Carbon
import NaturalLanguage

final class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = false
    private var isSynthesizing = false

    private var currentWord: String = ""
    private var currentWordLanguage: String?

    func syncState(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func startMonitoringIfPossible() {
        DebugLogger.log("startMonitoringIfPossible")
        guard isAccessibilityTrusted() else {
            DebugLogger.log("Accessibility not trusted, prompting")
            promptForAccessibilityPermission()
            return
        }
        if eventTap != nil { return }

        let mask = (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
            return monitor.handleEvent(proxy: proxy, type: type, event: event)
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: userInfo
        )

        guard let eventTap else {
            DebugLogger.log("Failed to create event tap")
            return
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        DebugLogger.log("Event tap enabled")
    }

    func stopMonitoring() {
        DebugLogger.log("stopMonitoring")
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
        currentWord = ""
        currentWordLanguage = nil
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard isEnabled else { return Unmanaged.passUnretained(event) }
        if isSynthesizing { return Unmanaged.passUnretained(event) }
        if event.getIntegerValueField(.eventSourceUserData) == 1 { return Unmanaged.passUnretained(event) }
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let flags = event.flags
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            return Unmanaged.passUnretained(event)
        }

        guard let character = event.unicodeString else { return Unmanaged.passUnretained(event) }

        if character == "\u{7F}" || character == "\u{8}" {
            if !currentWord.isEmpty {
                currentWord.removeLast()
            }
            return Unmanaged.passUnretained(event)
        }

        if character.isWordCharacter {
            currentWord.append(character)
            if currentWordLanguage == nil {
                currentWordLanguage = currentInputLanguage()
            }
        } else {
            evaluateAndReplaceIfNeeded()
            currentWord = ""
            currentWordLanguage = nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func evaluateAndReplaceIfNeeded() {
        guard !currentWord.isEmpty else { return }

        let inputLanguage = currentWordLanguage ?? currentInputLanguage()
        if inputLanguage == "en" {
            let mapped = KeyboardMapping.mapLatinToUkrainian(currentWord)
            guard mapped != currentWord else { return }
            if isLikelyLanguage(mapped, language: .ukrainian) {
                replaceCurrentWord(with: mapped)
            }
        } else if inputLanguage == "uk" {
            let mapped = KeyboardMapping.mapUkrainianToLatin(currentWord)
            guard mapped != currentWord else { return }
            if isLikelyLanguage(mapped, language: .english) {
                replaceCurrentWord(with: mapped)
            }
        }
    }

    private func replaceCurrentWord(with replacement: String) {
        isSynthesizing = true
        defer { isSynthesizing = false }

        NSSound.beep()
        postBackspaces(count: currentWord.count)
        postText(replacement)
    }

    private func isLikelyLanguage(_ text: String, language: NLLanguage) -> Bool {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 2)
        let confidence = hypotheses[language] ?? 0
        return confidence >= 0.6
    }

    private func currentInputLanguage() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else { return nil }
        if let languages = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) {
            let unmanaged = Unmanaged<CFArray>.fromOpaque(languages)
            let array = unmanaged.takeUnretainedValue() as [AnyObject]
            if let first = array.first as? String {
                return String(first.prefix(2))
            }
        }
        if let id = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            let unmanaged = Unmanaged<CFString>.fromOpaque(id)
            let value = unmanaged.takeUnretainedValue() as String
            if value.contains("Ukrainian") { return "uk" }
            if value.contains("English") { return "en" }
        }
        return nil
    }

    private func postBackspaces(count: Int) {
        guard count > 0 else { return }
        for _ in 0..<count {
            if let backspaceDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x33, keyDown: true),
               let backspaceUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x33, keyDown: false) {
                backspaceDown.setIntegerValueField(.eventSourceUserData, value: 1)
                backspaceUp.setIntegerValueField(.eventSourceUserData, value: 1)
                backspaceDown.post(tap: .cghidEventTap)
                backspaceUp.post(tap: .cghidEventTap)
            }
        }
    }

    private func postText(_ text: String) {
        for scalar in text.unicodeScalars {
            let value = scalar.value
            var chars: [UniChar] = [UniChar(value)]
            let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &chars)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &chars)
            down?.setIntegerValueField(.eventSourceUserData, value: 1)
            up?.setIntegerValueField(.eventSourceUserData, value: 1)
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }

    private func isAccessibilityTrusted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func promptForAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        let alert = NSAlert()
        alert.messageText = LocalizationManager.text("accessibility_title")
        alert.informativeText = LocalizationManager.text("accessibility_body")
        alert.addButton(withTitle: LocalizationManager.text("open_settings_button"))
        alert.addButton(withTitle: LocalizationManager.text("later_button"))
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

private extension CGEvent {
    var unicodeString: String? {
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 8)
        self.keyboardGetUnicodeString(maxStringLength: 8, actualStringLength: &length, unicodeString: &buffer)
        guard length > 0 else { return nil }
        return String(utf16CodeUnits: buffer, count: length)
    }
}

private extension String {
    var isWordCharacter: Bool {
        guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else { return false }
        if CharacterSet.letters.contains(scalar) { return true }
        if scalar == "'" || scalar == "’" { return true }
        return false
    }
}
