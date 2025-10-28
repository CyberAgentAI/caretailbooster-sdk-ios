import Foundation

@available(iOS 13.0, *)
@MainActor
public class RetailBooster {
    private static var config: RetailBoosterConfig?
    private static var isInit: Bool = false
    private static var logLevel: LogLevel = .none

    public static func initialize(mediaId: String, mode: RunMode) {
        config = RetailBoosterConfig(
            mediaId: mediaId,
            mode: mode
        )
        isInit = true

        #if DEBUG
        if logLevel != .none {
            print("[RetailBooster] SDK initialized with mediaId: \(mediaId), mode: \(mode)")
        }
        #endif
    }

    public static func setUserInfo(userId: String, crypto: String) {
        config?.userId = userId
        config?.crypto = crypto

        #if DEBUG
        if logLevel != .none {
            print("[RetailBooster] User info set for userId: \(userId)")
        }
        #endif
    }

    @MainActor
    public static func load<T: Ad>(
        _ ad: T,
        completion: @escaping (Result<Bool, RetailBoosterError>) -> Void
    ) {
        guard isInit else {
            #if DEBUG
            if logLevel != .none {
                print("[RetailBooster] Error: SDK not initialized")
            }
            #endif
            completion(.failure(.notInitialized))
            return
        }

        guard isUserInfoSet else {
            #if DEBUG
            if logLevel != .none {
                print("[RetailBooster] Error: User info not set")
            }
            #endif
            completion(.failure(.userInfoNotSet))
            return
        }

        #if DEBUG
        if logLevel != .none {
            print("[RetailBooster] Loading ad for tagGroupId: \(ad.tagGroupId)")
        }
        #endif

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

                #if DEBUG
                if logLevel != .none {
                    print("[RetailBooster] Ad loaded successfully. Has ad: \(hasAd)")
                }
                #endif

                await MainActor.run {
                    completion(.success(hasAd))
                }
            } catch {
                #if DEBUG
                if logLevel != .none {
                    print("[RetailBooster] Error loading ad: \(error.localizedDescription)")
                }
                #endif

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
        print("[RetailBooster] Log level set to: \(level)")
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
