import Foundation

struct DebugLogger {
    private(set) static var isEnabled = false

    static func configureIfNeeded() {
        isEnabled = CommandLine.arguments.contains("--debug")
        guard isEnabled else { return }

        let logURL = logFileURL()
        let logDir = logURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)

        let fd = open(logURL.path, O_WRONLY | O_CREAT | O_APPEND, 0o644)
        if fd != -1 {
            dup2(fd, STDOUT_FILENO)
            dup2(fd, STDERR_FILENO)
            close(fd)
        }

        log("Debug logging enabled")
        log("Arguments: \(CommandLine.arguments.joined(separator: " "))")
    }

    static func log(_ message: String) {
        guard isEnabled else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        fputs("[Alpha] \(ts) \(message)\n", stderr)
    }

    private static func logFileURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library/Logs/Alpha", isDirectory: true)
            .appendingPathComponent("alpha-debug.log")
    }
}
