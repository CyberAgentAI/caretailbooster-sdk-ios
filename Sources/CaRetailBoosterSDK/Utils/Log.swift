import Foundation
import OSLog

@available(iOS 13.0, *)
enum Log {
    @available(iOS 14.0, *)
    private static let logger = Logger(subsystem: "com.retaiboo.CaRetailBoosterSDK", category: "RetailBooster")

    static func debug(_ message: String, context: String = "") {
        Task { @MainActor in
            guard RetailBooster.logLevel == .debug else { return }
            let prefix = context.isEmpty ? "" : "[\(context)] "
            let msg = "\(prefix)\(message)"

            if #available(iOS 14.0, *) {
                logger.debug("[RetailBooster][DEBUG] \(msg, privacy: .public)")
            } else {
                print("[RetailBooster][DEBUG] \(msg)")
            }
        }
    }

    static func info(_ message: String, context: String = "") {
        Task { @MainActor in
            let logLevel = RetailBooster.logLevel
            guard logLevel == .debug || logLevel == .info else { return }
            let prefix = context.isEmpty ? "" : "[\(context)] "
            let msg = "\(prefix)\(message)"

            if #available(iOS 14.0, *) {
                logger.info("[RetailBooster][INFO] \(msg, privacy: .public)")
            } else {
                print("[RetailBooster][INFO] \(msg)")
            }
        }
    }

    static func error(_ message: String, context: String = "") {
        Task { @MainActor in
            guard RetailBooster.logLevel != .none else { return }
            let prefix = context.isEmpty ? "" : "[\(context)] "
            let msg = "\(prefix)\(message)"

            if #available(iOS 14.0, *) {
                logger.error("[RetailBooster][ERROR] \(msg, privacy: .public)")
            } else {
                print("[RetailBooster][ERROR] \(msg)")
            }
        }
    }
}
