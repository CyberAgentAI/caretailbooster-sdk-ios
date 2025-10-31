import Foundation

public struct RtBRewardCallback {
    public var onMarkSucceeded: (() -> Void)?
    public var onRewardModalClosed: (() -> Void)?

    public init(
        onMarkSucceeded: (() -> Void)? = nil,
        onRewardModalClosed: (() -> Void)? = nil
    ) {
        self.onMarkSucceeded = onMarkSucceeded
        self.onRewardModalClosed = onRewardModalClosed
    }
}

public struct RtBPopupCallback {
    public var onClose: (() -> Void)?
    public var onOuterLink: ((String) -> Void)?
    public var onInnerLink: ((String) -> Void)?

    public init(
        onClose: (() -> Void)? = nil,
        onOuterLink: ((String) -> Void)? = nil,
        onInnerLink: ((String) -> Void)? = nil
    ) {
        self.onClose = onClose
        self.onOuterLink = onOuterLink
        self.onInnerLink = onInnerLink
    }
}
