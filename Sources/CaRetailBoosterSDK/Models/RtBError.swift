import Foundation

public enum RtBError: Error {
    case notInitialized
    case userInfoNotSet
    case loadFailed(Error)

    public var localizedDescription: String {
        switch self {
        case .notInitialized:
            return "RetailBooster SDK が初期化されていません"
        case .userInfoNotSet:
            return "ユーザー情報が設定されていません。setUserInfo() を呼び出してください"
        case .loadFailed(let error):
            return "広告の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
}

public enum RtBLogLevel {
    case none
    case info
    case debug
}
