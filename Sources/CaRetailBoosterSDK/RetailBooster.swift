import Foundation

@available(iOS 13.0, *)
@MainActor
public class RetailBooster {
    private static var config: RetailBoosterConfig?
    private static var isInit: Bool = false
    internal static var logLevel: LogLevel = .none

    public static func initialize(mediaId: String, mode: RunMode) {
        config = RetailBoosterConfig(
            mediaId: mediaId,
            mode: mode
        )
        isInit = true
        Log.info("SDK initialized with mediaId: \(mediaId), mode: \(mode)", context: "RetailBooster")
    }

    public static func setUserInfo(userId: String, crypto: String) {
        config?.userId = userId
        config?.crypto = crypto
        Log.info("User info set for userId: \(userId)", context: "RetailBooster")
    }

    @MainActor
    public static func load<T: Ad>(
        _ ad: T,
        completion: @escaping (Result<Bool, RetailBoosterError>) -> Void
    ) {
        guard isInit else {
            Log.error("Error: SDK not initialized", context: "RetailBooster")
            completion(.failure(.notInitialized))
            return
        }

        guard isUserInfoSet else {
            Log.error("Error: User info not set", context: "RetailBooster")
            completion(.failure(.userInfoNotSet))
            return
        }

        Log.info("Loading ad for tagGroupId: \(ad.tagGroupId)", context: "RetailBooster")

        Task {
            do {
                try await ad.load()

                let hasAd: Bool
                if let viewableAd = ad as? ViewableAd {
                    hasAd = !viewableAd.views.isEmpty
                } else if ad is OverlayAd {
                    hasAd = true
                } else {
                    hasAd = false
                }

                Log.info("Ad loaded successfully. Has ad: \(hasAd)", context: "RetailBooster")

                await MainActor.run {
                    completion(.success(hasAd))
                }
            } catch {
                Log.error("Error loading ad: \(error.localizedDescription)", context: "RetailBooster")

                await MainActor.run {
                    completion(.failure(.loadFailed(error)))
                }
            }
        }
    }

    public static var isInitialized: Bool {
        return isInit
    }

    public static var isUserInfoSet: Bool {
        guard let config = config else { return false }
        return config.userId != nil && config.crypto != nil
    }

    public static func setLogLevel(_ level: LogLevel) {
        logLevel = level

        #if DEBUG
        if level != .none {
            print("[RetailBooster][INFO] Log level set to: \(level)")
        }
        #endif
    }

    internal static var currentConfig: RetailBoosterConfig? {
        return config
    }

    #if DEBUG
    internal static func reset() async {
        await MainActor.run {
            config = nil
            isInit = false
            logLevel = .none
        }
    }
    #endif
}

internal struct RetailBoosterConfig {
    let mediaId: String
    let mode: RunMode
    var userId: String?
    var crypto: String?
}
