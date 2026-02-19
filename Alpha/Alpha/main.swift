import AppKit

DebugLogger.configureIfNeeded()
DebugLogger.log("main.swift start")
DebugLogger.log("Bundle id: \(Bundle.main.bundleIdentifier ?? "nil")")
DebugLogger.log("Executable: \(Bundle.main.executableURL?.path ?? "nil")")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
