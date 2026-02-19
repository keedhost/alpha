import AppKit

DebugLogger.configureIfNeeded()
DebugLogger.log("main.swift start")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
