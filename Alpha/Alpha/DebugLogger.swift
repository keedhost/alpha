import Foundation
import Security

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
        NSLog("[Alpha] Debug logging enabled")
        logSigningInfo()
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

    private static func logSigningInfo() {
        var staticCode: SecStaticCode?
        let bundleURL = Bundle.main.bundleURL as CFURL
        let createStatus = SecStaticCodeCreateWithPath(bundleURL, SecCSFlags(), &staticCode)
        guard createStatus == errSecSuccess, let staticCode else {
            log("Code signing: unable to create static code (status=\(createStatus))")
            return
        }
        var info: CFDictionary?
        let infoStatus = SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info)
        guard infoStatus == errSecSuccess, let info = info as? [String: Any] else {
            log("Code signing: no info (status=\(infoStatus))")
            return
        }
        let identifier = info[kSecCodeInfoIdentifier as String] as? String ?? "unknown"
        let teamId = info[kSecCodeInfoTeamIdentifier as String] as? String ?? "none"
        let flags = info[kSecCodeInfoFlags as String] as? UInt64 ?? 0
        log("Code signing: identifier=\(identifier) team=\(teamId) flags=\(flags)")
    }
}
