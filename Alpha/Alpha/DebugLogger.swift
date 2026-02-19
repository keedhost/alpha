import Foundation

struct DebugLogger {
    private(set) static var isEnabled = false
    private static var logFileHandle: FileHandle?
    private static var configured = false

    static func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        isEnabled = CommandLine.arguments.contains("--debug")
        guard isEnabled else { return }

        let logURL = logFileURL()
        do {
            if !FileManager.default.fileExists(atPath: logURL.path) {
                FileManager.default.createFile(atPath: logURL.path, contents: nil)
            }
            logFileHandle = try FileHandle(forWritingTo: logURL)
            logFileHandle?.seekToEndOfFile()
        } catch {
            logFileHandle = nil
        }

        log("Debug logging enabled")
        log("Arguments: \(CommandLine.arguments.joined(separator: " "))")
    }

    static func log(_ message: String) {
        guard isEnabled else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[Alpha] \(ts) \(message)\n"
        if let data = line.data(using: .utf8) {
            logFileHandle?.write(data)
            try? logFileHandle?.synchronize()
        }
        fputs(line, stderr)
    }

    private static func logFileURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("alpha-debug.log")
    }
}
